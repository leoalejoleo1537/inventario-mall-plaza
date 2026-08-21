// ================================================================
// Edge Function: fudo-empujar-stock
//
// Manda a Fudo el stock disponible calculado desde el inventario.
// El cálculo NO vive acá: lo hace public.fudo_stock_calculado() en la
// base, igual que el motor de descuento. Esta función solo habla con
// Fudo y deja constancia de lo que hizo.
//
// Cómo se llama:
//   POST { sede, modo, producto_id?, fudo_product_id?, incluir_ceros? }
//
//   modo: "simular"  -> NO toca Fudo. Devuelve exactamente lo que haría.
//         "aplicar"  -> escribe de verdad.
//   producto_id      -> id de un producto del INVENTARIO. Empuja los
//                       productos de Fudo cuya receta lo usa (un
//                       selladito puede estar en dos combos).
//   fudo_product_id  -> empuja uno puntual de Fudo.
//   sin ninguno      -> todos los que se pueden actualizar.
//   incluir_ceros    -> por defecto FALSE. Los que quedarían en 0
//                       teniendo stock en Fudo se saltan, porque una
//                       receta mal armada ahí no descuadra un número:
//                       hace que Fudo deje de vender algo que sí está
//                       en la vitrina. Para mandarlos hay que pedirlo.
//   incluir_nuevos   -> por defecto FALSE. Los productos que en Fudo
//                       tienen el stock en null NUNCA se han controlado
//                       por stock: hoy se venden sin límite. Ponerles un
//                       número los empieza a bloquear al llegar a 0, y
//                       eso es un cambio de comportamiento en el mesón.
//                       Se deja para una tanda aparte, avisada.
//
// SIEMPRE manda el número ABSOLUTO, nunca una diferencia. Fudo
// descuenta su propio stock al vender, así que mandar "+3" restaría
// dos veces; mandando el total, cada envío corrige la deriva solo.
//
// Quién puede: solo los correos con puede_fudo en public.app_permisos.
// Para agregar o quitar gente se edita esa tabla —está explicado dentro
// de sql/2026-07-permisos-y-deshacer.sql—, NO este archivo.
//
// Secrets necesarios:
//   FUDO_<SEDE>_APIKEY / FUDO_<SEDE>_APISECRET
// ================================================================

// Se devuelve en cada respuesta para poder saber qué versión está
// desplegada sin entrar al panel (§8, prevención).
const VERSION = "2026-08-21d";
const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";

/* ---------------- EL TOKEN DE FUDO, GUARDADO ----------------

   Cada llamada a esta función empezaba pidiéndole un token a Fudo. Para el
   empuje general da lo mismo —un viaje entre ciento cincuenta— pero para
   empujar UN producto es la mitad del tiempo total: dos viajes a Fudo
   cuando el trabajo real es uno.

   El token se guarda en la propia función y se reusa cinco minutos. No es
   un caché de datos —eso sería peligroso, porque el stock cambia— es un
   caché de la LLAVE, que no cambia. Y si Fudo lo rechaza igual (401/403),
   se pide uno nuevo y se reintenta una vez: guardar una llave vencida no
   puede convertirse en un empuje que no ocurre.                          */
let tokenGuardado: { token: string; vence: number; sede: string } | null = null;
const TOKEN_DURA_MS = 5 * 60_000;

async function tokenDeFudo(sede: string, apiKey: string, apiSecret: string, forzar = false) {
  if (!forzar && tokenGuardado && tokenGuardado.sede === sede && Date.now() < tokenGuardado.vence) {
    return { token: tokenGuardado.token, error: null as string | null };
  }
  const r = await fetch(AUTH_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Accept": "application/json" },
    body: JSON.stringify({ apiKey, apiSecret }),
  });
  if (!r.ok) return { token: null, error: `Fudo rechazó la autenticación (${r.status}).` };
  const token = (await r.json())?.token;
  if (!token) return { token: null, error: "Fudo no devolvió un token." };
  tokenGuardado = { token, vence: Date.now() + TOKEN_DURA_MS, sede };
  return { token, error: null as string | null };
}

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-sistema-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Fila = {
  fudo_product_id: string; producto_fudo: string;
  stock_en_fudo: number | null; stock_calculado: number;
  insumo_que_limita: string; insumos: string;
  ignorados: string | null;   // envases, que no limitan la venta
  sumados: string | null;     // pares vitrina+congelador que se sumaron
  deja_en_cero: boolean;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const SB_URL = Deno.env.get("SUPABASE_URL");
    const SB_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
                ?? Deno.env.get("SUPABASE_SECRET_KEY");
    if (!SB_URL || !SB_KEY) return json({ error: "Falta la configuración de Supabase en el entorno." }, 500);

    // ---------- QUIÉN LO HIZO, no quién puede ----------
    //
    // DECISIÓN DE JHON, 2026-08-15: "necesito que todos puedan actualizar
    // con ese botón el stock de Fudo, todos, no solo jefatura."
    //
    // Esto abre el único candado que quedaba en pie (§6.1 dejaba a
    // propósito con llave lo que toca un sistema externo). Vale escribir
    // por qué es defendible, porque no es evidente:
    //
    //   Este empuje **no inventa nada**. Manda el stock que el inventario
    //   ya calculó, y es exactamente lo que la tarea automática hace sola
    //   cada 15 minutos sin que nadie apriete nada. Un botón que adelanta
    //   algo que igual va a pasar no puede producir un estado nuevo. Lo
    //   único que cambia es el momento.
    //
    //   Y el motivo operativo es más fuerte: los que ven que a Fudo le
    //   falta stock son los del mesón, no jefatura. Pedirles que avisen y
    //   esperen es cómo nacieron los "Jhon, el reparto no actualiza Fudo".
    //
    // LO QUE SIGUE CON LLAVE: deshacer un empuje (`fudo-deshacer-stock`).
    // Ese sí revierte a un estado anterior y puede pisar el trabajo de
    // otro. Adelantar algo que va a pasar solo es distinto de deshacerlo.
    //
    // La sesión se sigue LEYENDO cuando existe, para que la bitácora diga
    // quién fue. Ya no decide si puede: decide cómo firma.
    const SISTEMA_TOKEN = Deno.env.get("SISTEMA_TOKEN");
    const tokenRecibido = req.headers.get("x-sistema-token") ?? "";
    const esSistema = !!SISTEMA_TOKEN && tokenRecibido === SISTEMA_TOKEN;

    let correo: string | null = esSistema ? "sistema (automático)" : null;

    if (!esSistema) {
      const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
      if (jwt) {
        const uRes = await fetch(`${SB_URL}/auth/v1/user`, {
          headers: { "Authorization": `Bearer ${jwt}`, "apikey": SB_KEY },
        });
        try { correo = ((await uRes.json())?.email ?? "").toLowerCase() || null; } catch { /* no-JSON */ }
      }
      // Sin sesión el empuje se hace igual, y queda firmado como equipo.
      // Que no se sepa el nombre no es motivo para dejar Fudo desactualizado.
      if (!correo) correo = "equipo (sin sesión)";
    }

    // ---------- Qué se pidió ----------
    const body = await req.json().catch(() => ({}));
    const sede = String(body?.sede ?? "plaza").toLowerCase();
    /* `probar` (2026-08-21) no empuja nada: le toma el pulso a Fudo. Nació
       del turno en que el botón devolvía 504 y no había forma de saber si
       el problema era Fudo o nuestro. Es la pregunta más barata que existe
       y no la teníamos. */
    const modo = body?.modo === "aplicar" ? "aplicar"
               : body?.modo === "probar"  ? "probar" : "simular";
    const productoId = body?.producto_id != null ? Number(body.producto_id) : null;
    const unoDeFudo = body?.fudo_product_id ? String(body.fudo_product_id) : null;
    const incluirCeros = body?.incluir_ceros === true;
    const incluirNuevos = body?.incluir_nuevos === true;

    // ---------- DÓNDE SE VA EL TIEMPO ----------
    // Jhon, 2026-08-21: "se está demorando mucho... no sé qué cambió".
    // Mientras la respuesta no diga en qué se fue el tiempo, la única
    // manera de contestar eso es adivinar. Ahora lo dice.
    const t = { calculo: 0, auth: 0, fudo: 0, total: 0 };
    const arranqueTodo = Date.now();

    // ---------- El cálculo lo hace la base ----------
    const tCalculo = Date.now();
    const cRes = await fetch(`${SB_URL}/rest/v1/rpc/fudo_stock_calculado`, {
      method: "POST",
      headers: { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({ p_sede: sede, p_producto_id: productoId }),
    });
    if (!cRes.ok) {
      return json({ error: "No se pudo calcular el stock.", detalle: (await cRes.text()).slice(0, 300) }, 500);
    }
    let filas: Fila[] = await cRes.json();
    t.calculo = Date.now() - tCalculo;
    if (unoDeFudo) filas = filas.filter((f) => f.fudo_product_id === unoDeFudo);

    // Los que ya están iguales no se tocan: menos llamadas y menos ruido.
    const yaIguales = filas.filter((f) => Number(f.stock_en_fudo) === Number(f.stock_calculado));
    const enCero = filas.filter((f) => f.deja_en_cero);
    // Fudo nunca les ha llevado stock: hoy se venden sin límite
    const nuevos = filas.filter((f) => f.stock_en_fudo === null);
    let porHacer = filas.filter((f) => Number(f.stock_en_fudo) !== Number(f.stock_calculado));
    if (!incluirCeros)  porHacer = porHacer.filter((f) => !f.deja_en_cero);
    if (!incluirNuevos) porHacer = porHacer.filter((f) => f.stock_en_fudo !== null);

    const resumen = {
      version: VERSION, sede, modo, quien: correo,
      se_actualizarian: porHacer.length,
      ya_estaban_iguales: yaIguales.length,
      saltados_por_quedar_en_cero: incluirCeros ? 0 : enCero.length,
      saltados_por_ser_nuevos: incluirNuevos ? 0 : nuevos.length,
    };

    // ---------- Simular: no toca Fudo ----------
    if (modo === "simular") {
      return json({
        ...resumen,
        aviso: enCero.length && !incluirCeros
          ? `${enCero.length} producto(s) quedarían en 0 y Fudo dejaría de venderlos. `
          + "No se mandan salvo que se pida expresamente. Revisa que su receta esté bien."
          : undefined,
        cambios: porHacer.map((f) => ({
          producto: f.producto_fudo, de: f.stock_en_fudo, a: f.stock_calculado,
          limita: f.insumo_que_limita,
          ...(f.ignorados ? { envases_ignorados: f.ignorados } : {}),
          ...(f.sumados ? { suma_vitrina_y_congelador: f.sumados } : {}),
        })),
        quedarian_en_cero: enCero.map((f) => ({
          producto: f.producto_fudo, tiene_en_fudo: f.stock_en_fudo,
          limita: f.insumo_que_limita, receta: f.insumos,
        })),
        empezarian_a_controlarse: nuevos.map((f) => ({
          producto: f.producto_fudo, quedaria_en: f.stock_calculado,
          limita: f.insumo_que_limita,
        })),
      });
    }

    // ---------- Aplicar ----------
    // `probar` sigue de largo aunque no haya nada que empujar: justamente
    // sirve para cuando uno no sabe si hay algo o si algo está roto.
    if (!porHacer.length && modo !== "probar") return json({ ...resumen, ok: true, cambios: [] });

    const apiKey = Deno.env.get(`FUDO_${sede.toUpperCase()}_APIKEY`);
    const apiSecret = Deno.env.get(`FUDO_${sede.toUpperCase()}_APISECRET`);
    if (!apiKey || !apiSecret) return json({ error: `Faltan credenciales de Fudo para "${sede}".` }, 400);

    const tAuth = Date.now();
    const auth = await tokenDeFudo(sede, apiKey, apiSecret);
    t.auth = Date.now() - tAuth;
    if (!auth.token) return json({ error: auth.error }, 502);
    let token = auth.token;

    // un código por envío: es lo que después permite deshacer "el último"
    const lote = crypto.randomUUID();
    const hechos: unknown[] = [], fallados: unknown[] = [], bitacora: unknown[] = [];
    let reintentos = 0;   // cuántos tropiezos pasajeros de Fudo hubo que repetir

    // ---------- EL PRESUPUESTO DE TIEMPO (2026-08-21) ----------
    //
    // Esta función le manda a Fudo UN producto por vez, en fila. Mientras
    // el botón ⟳ empujaba unos pocos, se notaba. Desde el 15 de agosto
    // empuja TODO —así se pidió— o sea ~230 productos por corrida. A un
    // segundo cada uno, eso pasa de los cuatro minutos, y la plataforma
    // corta la función a medio camino: la app recibe un 504 y ni siquiera
    // se entera de lo que sí alcanzó a hacer.
    //
    // Peor todavía: la bitácora se escribía RECIÉN AL FINAL, así que al
    // cortarse no quedaba rastro de los productos que sí se actualizaron.
    // Trabajo hecho, cero registro. Es la falla silenciosa de §0.5 con
    // pasos extra: no solo no avisa, además borra la evidencia.
    //
    // Dos arreglos, y el orden importa:
    //   1. se para a los 60 s y devuelve lo hecho + cuántos quedaron;
    //   2. la bitácora se guarda EN EL CAMINO, de a tandas.
    //
    // Que se pueda cortar no rompe nada, y eso es por cómo está diseñado
    // desde el principio: se manda el valor ABSOLUTO y se saltan los que
    // ya están iguales. Así la corrida siguiente sigue exactamente donde
    // quedó esta. Cortar acá es una pausa, no una pérdida.
    // Se puede mover desde Secrets sin volver a desplegar, y es lo que
    // permite probar el corte sin esperar un minuto de verdad.
    const TOPE_MS = Number(Deno.env.get("EMPUJE_TOPE_MS") ?? 60_000);
    const arranque = Date.now();
    let pendientes = 0;

    // Guardar la bitácora de a tandas, para que un corte no la borre.
    const guardarBitacora = async (filas: unknown[]) => {
      if (!filas.length) return;
      await fetch(`${SB_URL}/rest/v1/fudo_stock_push`, {
        method: "POST",
        headers: { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}`,
                   "Content-Type": "application/json", "Prefer": "return=minimal" },
        body: JSON.stringify(filas),
      }).catch(() => { /* que un fallo de bitácora no oculte el resultado */ });
    };

    // ---------- DE A CINCO, NO DE A UNO ----------
    //
    // El presupuesto de tiempo de arriba evita el 504, pero solo. Con ~150
    // productos y uno por vez, la corrida se corta a la mitad y hay que
    // apretar ⟳ tres o cuatro veces. Eso no sirve en el mesón: el botón
    // tiene que hacer el trabajo, no la mitad del trabajo.
    //
    // Cinco a la vez y no veinte, a propósito: no sabemos qué tolera la API
    // de Fudo, y quedarse sin saberlo con la entrega encima es una mala
    // apuesta. Cinco baja una corrida de ~150 segundos a ~30 y sigue siendo
    // un ritmo educado. El presupuesto de tiempo se queda igual, como red.
    const EN_PARALELO = 5;
    const cola = porHacer.slice();

    /* ---------------- CADA LLAMADA TIENE SU PROPIO RELOJ ----------------

       Este es el agujero que quedaba abierto después del 504 del 21 de
       agosto, y es el que de verdad explica cómo un día normal tumba el
       sistema entero.

       El presupuesto de tiempo se mira ENTRE producto y producto. Si una
       llamada a Fudo se queda colgada —no lenta: colgada, sin contestar ni
       cortar— ese obrero se queda ahí para siempre y el presupuesto nunca
       vuelve a mirarse, porque el `await` no vuelve. Con cinco obreros
       bastan cinco llamadas colgadas para que la función entera se quede
       esperando hasta que la plataforma la mate. Y ahí volvemos al 504.

       Es exactamente la misma falla que tenía la app con la ventana de
       "Actualizando…", una capa más abajo. La lección se repite: **todo lo
       que sale de nuestra máquina lleva reloj**. Si no, alguien de afuera
       decide cuánto dura lo nuestro.

       15 segundos es de sobra: un PATCH normal tarda menos de uno.        */
    const TOPE_LLAMADA_MS = Number(Deno.env.get("EMPUJE_TOPE_LLAMADA_MS") ?? 15_000);

    const conReloj = async (hacer: (señal: AbortSignal) => Promise<Response>) => {
      const corte = new AbortController();
      const reloj = setTimeout(() => corte.abort(), TOPE_LLAMADA_MS);
      try { return await hacer(corte.signal); }
      finally { clearTimeout(reloj); }
    };

    const mandar = (f: Fila, valor: number) =>
      conReloj((señal) => fetch(`${API_BASE}/products/${f.fudo_product_id}`, {
        method: "PATCH",
        signal: señal,
        headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json", "Content-Type": "application/json" },
        body: JSON.stringify({
          data: { type: "Product", id: f.fudo_product_id, attributes: { stock: valor } },
        }),
      }));

    // ---------- TOMARLE EL PULSO A FUDO ----------
    //
    // Autenticarse y leer UN producto, con cronómetro. Con eso alcanza para
    // contestar la pregunta que el 21 de agosto costó medio día: ¿está
    // lento Fudo, o estamos lentos nosotros?
    //
    // Y de yapa, la respuesta PREDICE el 504 en vez de esperarlo: si un
    // viaje tarda 1,2 s y hay 150 productos por mandar, la corrida se va a
    // pasar del presupuesto. Eso se puede decir ANTES de que pase.
    if (modo === "probar") {
      const tLee = Date.now();
      let estado = 0, detalle = "";
      try {
        const r = await conReloj((señal) =>
          fetch(`${API_BASE}/products?page[size]=1`, {
            signal: señal,
            headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json" },
          }));
        estado = r.status;
        const txt = await r.text();
        if (!r.ok) detalle = txt.slice(0, 200);
      } catch (e) {
        detalle = (e instanceof Error && e.name === "AbortError")
          ? `Fudo no contestó en ${Math.round(TOPE_LLAMADA_MS / 1000)} s.`
          : String(e);
      }
      const lee = Date.now() - tLee;
      // Cuánto tardaría la corrida completa a este ritmo, de a EN_PARALELO.
      const estimado = estado === 200
        ? Math.round((porHacer.length / EN_PARALELO) * lee / 1000) : null;
      return json({
        version: VERSION, sede, modo: "probar", ok: estado === 200,
        fudo_responde: estado === 200,
        estado, detalle: detalle || null,
        auth_ms: t.auth, lectura_ms: lee, calculo_ms: t.calculo,
        por_empujar: porHacer.length,
        estimado_segundos: estimado,
        // La conclusión ya masticada: quien mira esto está apurado.
        veredicto: estado !== 200
          ? "Fudo no está contestando."
          : lee > 2000 ? "Fudo contesta, pero muy lento."
          : estimado !== null && estimado > 55 ? "Fudo contesta bien, pero hay demasiado por mandar para una sola pasada."
          : "Todo en orden.",
      });
    }

    /* Un 429 o un 502 casi siempre son pasajeros: Fudo pidiendo aire. Antes
       ese producto se daba por perdido hasta la corrida siguiente, o sea que
       su stock quedaba mal por quince minutos por un tropiezo de un segundo.
       Se reintenta una vez, esperando un poco. Un 400 NO se reintenta: si el
       dato está mal, repetirlo lo deja igual de mal. */
    const PASAJEROS = new Set([408, 429, 500, 502, 503, 504]);

    const unProducto = async (f: Fila) => {
      const valor = Number(f.stock_calculado);
      let ok = false, detalle = "", confirmado: number | null = null;
      try {
        // Formato confirmado con la prueba aislada: JSON:API, PATCH.
        let r = await mandar(f, valor);
        /* La llave guardada puede haber vencido. Se pide una nueva y se
           reintenta UNA vez: reusar el token no puede convertirse en un
           empuje que no ocurre. */
        if (r.status === 401 || r.status === 403) {
          const nuevo = await tokenDeFudo(sede, apiKey, apiSecret, true);
          if (nuevo.token) { token = nuevo.token; r = await mandar(f, valor); }
        }
        if (PASAJEROS.has(r.status)) {
          await new Promise((s) => setTimeout(s, 700));
          r = await mandar(f, valor);
          reintentos++;
        }
        const txt = await r.text();
        if (r.ok) {
          // Fudo devuelve el producto actualizado: se comprueba en vez de confiar.
          try { confirmado = JSON.parse(txt)?.data?.attributes?.stock ?? null; } catch { /* no-JSON */ }
          ok = confirmado === null || Number(confirmado) === valor;
          if (!ok) detalle = `Fudo respondió OK pero quedó en ${confirmado}, no en ${valor}.`;
        } else {
          detalle = `Fudo rechazó el cambio (${r.status}): ${txt.slice(0, 200)}`;
        }
      } catch (e) {
        /* Un corte por reloj se dice con esas palabras. "AbortError" no le
           explica nada a nadie; "no contestó en 15 s" sí. */
        detalle = (e instanceof Error && e.name === "AbortError")
          ? `Fudo no contestó en ${Math.round(TOPE_LLAMADA_MS / 1000)} s.`
          : `No se pudo contactar a Fudo: ${String(e)}`;
      }

      const fila = { producto: f.producto_fudo, de: f.stock_en_fudo, a: valor, ...(ok ? {} : { error: detalle }) };
      (ok ? hechos : fallados).push(fila);
      bitacora.push({
        sede, lote, fudo_product_id: f.fudo_product_id, producto_fudo: f.producto_fudo,
        stock_anterior: f.stock_en_fudo, stock_enviado: valor, ok, detalle: detalle || null, quien: correo,
      });
    };

    /* Cinco obreros sacando de la misma pila. Cada uno toma el siguiente
       cuando termina el suyo, así ninguno se queda esperando al más lento —
       que es lo que pasaría partiendo la lista en cinco pedazos fijos. */
    const obrero = async () => {
      for (;;) {
        if (Date.now() - arranque > TOPE_MS) break;   // se acabó el tiempo
        const f = cola.shift();
        if (!f) break;
        await unProducto(f);
        // De a 25: si la plataforma corta la función, lo ya hecho está escrito.
        if (bitacora.length >= 25) await guardarBitacora(bitacora.splice(0, bitacora.length));
      }
    };
    const tFudo = Date.now();
    await Promise.all(Array.from({ length: Math.min(EN_PARALELO, cola.length) }, obrero));
    t.fudo = Date.now() - tFudo;
    pendientes = cola.length;

    // Lo que quedó suelto de la última tanda.
    await guardarBitacora(bitacora);

    return json({
      ...resumen,
      ok: fallados.length === 0,
      actualizados: hechos.length,
      con_error: fallados.length,
      // Cuántos quedaron para la próxima corrida. La app lo dice en pantalla:
      // "quedan 90" es información; quedarse callado es lo que hacía el 504.
      pendientes,
      /* En qué se fue el tiempo, en milisegundos. `por_producto` es el
         que contesta la pregunta de verdad: si son 80 ms, el que tarda es
         Fudo y no hay nada que optimizar de este lado; si son 900, hay que
         ver si acepta que le mandemos más de a cinco. */
      tiempos: {
        ...t,
        total: Date.now() - arranqueTodo,
        por_producto: hechos.length + fallados.length
          ? Math.round(t.fudo / (hechos.length + fallados.length)) : null,
        en_paralelo: EN_PARALELO,
        reintentos,
      },
      cambios: hechos,
      errores: fallados,
    });
  } catch (e) {
    return json({ error: "Error inesperado.", detalle: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), {
    status, headers: { "Content-Type": "application/json", ...CORS },
  });
}
