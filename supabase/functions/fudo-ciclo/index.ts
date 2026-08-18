// ================================================================
// Edge Function: fudo-ciclo
//
// EL CICLO COMPLETO, EN ORDEN: primero baja de Fudo lo que se vendió y
// lo descuenta del inventario; recién después le manda a Fudo el stock
// entero. Uno solo, y siempre en ese orden.
//
// POR QUÉ EXISTE — y esto es la decisión de fondo, no un detalle
// técnico (Jhon, 2026-08-15):
//
//   "no podemos ir parchando estos fallos de 'no se subió los cannolis'
//    luego probamos y si funciona... necesito que cada tantos minutos se
//    empuje todo a Fudo."
//
//   Hasta hoy Fudo se enteraba de lo que entraba al inventario por
//   avisos sueltos: uno por cada línea de reparto confirmada. Cada aviso
//   es una oportunidad de fallar, y cuando falla no se nota — el número
//   de Fudo simplemente se queda viejo y nadie tiene motivo para
//   sospechar. Ya pasó con los cannolis y con los panes.
//
//   Un empuje entero cada tantos minutos **no necesita acertar todas las
//   veces**: manda el total, así que la corrida siguiente corrige sola
//   lo que la anterior no hizo. Se cambia "no puede fallar nunca" por
//   "se arregla solo", que es lo mismo que ya hicimos con el stock
//   negativo: no acordarse, sino un CHECK en la base.
//
// POR QUÉ EL ORDEN NO ES NEGOCIABLE. El empuje manda el stock que dice
// el inventario. Si se empujara ANTES de leer las ventas, se le mandaría
// a Fudo un número que todavía no descontó lo vendido — y Fudo volvería
// a subir el stock de algo que ya se vendió. Leer primero, escribir
// después. Por eso las dos cosas viven en la misma función y se esperan
// una a la otra: dos tareas agendadas por separado no garantizan el
// orden.
//
// SÍ MANDA LOS CEROS — y esto es una corrección de la primera versión
// (2026-08-15, mismo día, después de probarlo Jhon).
//
//   Al principio los dejé fuera con este argumento: esto corre solo, sin
//   nadie mirando, y poner un 0 por una receta mal armada haría que el
//   mesón no pueda vender algo que sí está en la vitrina.
//
//   El argumento no era falso, pero el efecto era absurdo: **el sistema
//   solo sabía sumar.** Subía cuando llegaba un reparto y no bajaba nunca
//   cuando algo se acababa. Jhon lo destapó en dos minutos poniendo un
//   serrano en 1 y borrándolo: Fudo se quedó en 1.
//
//   Y ese es justo el problema que Adriana tiene hace años — Fudo
//   vendiendo lo que ya no hay. Un inventario que solo suma no es un
//   inventario.
//
//   El riesgo que se acepta a cambio, dicho sin adornos: si una receta
//   está mal armada, su producto va a quedar en 0 en Fudo y el mesón no
//   lo va a poder vender hasta arreglarla. Se ve venir con una consulta
//   (`deja_en_cero` en fudo_stock_calculado) y se arregla arreglando la
//   receta, que es donde está el error de verdad.
//
// QUÉ SIGUE SIN MANDAR:
//   · Los que Fudo nunca controló (stock en null): hoy se venden sin
//     límite, y ponerles un número los empezaría a bloquear al llegar a
//     0. Eso es un cambio de comportamiento en el mesón que nadie pidió,
//     y es una tanda aparte y avisada.
//   · No toca recetas, ni productos, ni el catálogo.
//
// Cómo se llama:
//   POST { sede }                            <- la app, con la sesión
//   POST { sede } + header x-sistema-token   <- el reloj
//
// Las dos llaves se pasan tal cual a las funciones de abajo: el candado
// sigue viviendo donde vivía, en `fudo-empujar-stock`. Acá no se
// comprueba ningún permiso, justamente para no tener dos candados que
// puedan decir cosas distintas.
// ================================================================

const VERSION = "2026-08-18";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-sistema-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const t0 = Date.now();
  try {
    const SB_URL = Deno.env.get("SUPABASE_URL");
    const SB_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
                ?? Deno.env.get("SUPABASE_SECRET_KEY");
    if (!SB_URL || !SB_KEY) return json({ error: "Falta la configuración de Supabase." }, 500);

    const body = await req.json().catch(() => ({}));
    const url = new URL(req.url);
    const sede = String(url.searchParams.get("sede") ?? body?.sede ?? "plaza").toLowerCase();
    const origen = String(url.searchParams.get("origen") ?? body?.origen ?? "ciclo").toLowerCase();

    // QUIÉN FIRMA EL EMPUJE, y por qué se decide acá:
    //
    //  · origen 'cron'  -> lo disparó el reloj. No hay persona detrás, así
    //    que se usa el token de sistema, que vive en los secrets de esta
    //    función y NUNCA sale de acá — la tarea agendada no lo conoce.
    //  · cualquier otro -> lo apretó alguien. Se pasa su sesión tal cual y
    //    `fudo-empujar-stock` comprueba su permiso como siempre y firma la
    //    bitácora con su correo. Si no puede, contesta 403, que es lo
    //    correcto.
    //
    // Así el candado sigue viviendo en un solo lugar y el historial sigue
    // diciendo quién hizo qué en vez de "sistema" para todo.
    const cabPaso: Record<string, string> = {
      "Content-Type": "application/json",
      "Authorization": req.headers.get("Authorization") ?? `Bearer ${SB_KEY}`,
    };
    const SISTEMA_TOKEN = Deno.env.get("SISTEMA_TOKEN");
    if (origen === "cron") {
      if (!SISTEMA_TOKEN) {
        return json({
          version: VERSION, ok: false, sede,
          error: "Falta el secret SISTEMA_TOKEN, así que el ciclo automático no puede empujar.",
          que_hacer: "Supabase -> Edge Functions -> Secrets -> crear SISTEMA_TOKEN con cualquier texto largo.",
        }, 500);
      }
      cabPaso["x-sistema-token"] = SISTEMA_TOKEN;
    }

    const fn = (nombre: string, qs = "") => `${SB_URL}/functions/v1/${nombre}${qs}`;

    // ---------- ¿está encendido para esta sede? ----------
    // El interruptor vive en la base, no en el cron: la tarea agendada
    // sigue llamando y es ESTA función la que decide no hacer nada. Así
    // apagarlo desde Ajustes es una fila, y no hay que tocar el cron —
    // que es justo lo que Jhon no puede hacer solo.
    //
    // Si la tabla no existe todavía, se sigue como siempre. Un ajuste que
    // falta nunca puede apagar algo que ya funcionaba.
    try {
      const aRes = await fetch(
        `${SB_URL}/rest/v1/ajustes?clave=eq.ciclo_fudo&sede=eq.${encodeURIComponent(sede)}&select=valor`,
        { headers: { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}` } });
      if (aRes.ok) {
        const fila = (await aRes.json())?.[0];
        if (fila && fila.valor === false) {
          return json({ version: VERSION, ok: true, sede, apagado: true,
                        motivo: "El empuje automático está apagado para esta sede en Ajustes." });
        }
      }
    } catch { /* sin respuesta se sigue: apagar por accidente sería peor */ }

    // ---------- PASO 1 · leer las ventas y descontar ----------
    let ventas: any = null, errorVentas: string | null = null;
    try {
      const r = await fetch(fn("fudo-sync-ventas",
        `?sede=${encodeURIComponent(sede)}&origen=${encodeURIComponent(origen)}`), {
        method: "POST", headers: cabPaso, body: JSON.stringify({ sede, origen }),
      });
      const txt = await r.text();
      try { ventas = JSON.parse(txt); } catch { ventas = { crudo: txt.slice(0, 300) }; }
      if (!r.ok) errorVentas = `la lectura de ventas respondió ${r.status}`;
    } catch (e) {
      errorVentas = String(e instanceof Error ? e.message : e);
    }

    // ⚠️ Si leer las ventas falló, NO se empuja. Empujar con el
    // inventario sin descontar le devolvería a Fudo stock ya vendido, que
    // es exactamente el error que este orden viene a evitar. Se prefiere
    // no hacer nada y que la corrida siguiente lo arregle.
    if (errorVentas) {
      return json({
        version: VERSION, ok: false, sede, paso_que_fallo: "ventas",
        error: "No se pudieron leer las ventas, así que no se empujó nada.",
        detalle: errorVentas, ventas,
        segundos: Math.round((Date.now() - t0) / 1000),
      }, 502);
    }

    // ---------- PASO 2 · empujar el inventario entero ----------
    let empuje: any = null, errorEmpuje: string | null = null, statusEmpuje = 0;
    try {
      const r = await fetch(fn("fudo-empujar-stock"), {
        method: "POST", headers: cabPaso,
        // incluir_ceros: sin esto el sistema solo sabe sumar. Ver arriba.
        body: JSON.stringify({ sede, modo: "aplicar", incluir_ceros: true }),
      });
      statusEmpuje = r.status;
      const txt = await r.text();
      try { empuje = JSON.parse(txt); } catch { empuje = { crudo: txt.slice(0, 300) }; }
      if (!r.ok) errorEmpuje = empuje?.error ?? `el empuje respondió ${r.status}`;
    } catch (e) {
      errorEmpuje = String(e instanceof Error ? e.message : e);
    }

    return json({
      version: VERSION,
      ok: !errorEmpuje,
      sede, origen,
      segundos: Math.round((Date.now() - t0) / 1000),
      ventas: {
        leidas: ventas?.ventas_leidas ?? null,
        descuentos: ventas?.movimientos_generados ?? null,
        errores: ventas?.errores ?? null,
        modo: ventas?.modo ?? null,
      },
      empuje: errorEmpuje ? { error: errorEmpuje, status: statusEmpuje } : {
        actualizados: empuje?.actualizados ?? 0,
        ya_estaban_iguales: empuje?.ya_estaban_iguales ?? 0,
        con_error: empuje?.con_error ?? 0,
        saltados_por_quedar_en_cero: empuje?.saltados_por_quedar_en_cero ?? 0,
        saltados_por_ser_nuevos: empuje?.saltados_por_ser_nuevos ?? 0,
        quien: empuje?.quien ?? null,
      },
      ...(errorEmpuje ? { error: "Se leyeron las ventas, pero el empuje falló." } : {}),
    }, errorEmpuje ? 502 : 200);
  } catch (e) {
    return json({ version: VERSION, error: "Error inesperado.", detalle: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), {
    status, headers: { "Content-Type": "application/json", ...CORS },
  });
}
