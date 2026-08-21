// ================================================================
// Edge Function: fudo-sumar-stock
//
// SUMA a Fudo lo que acaba de llegar en un reparto. No manda el total
// del inventario: lee lo que Fudo tiene AHORA y le suma la cantidad
// recibida.
//
// POR QUÉ NO SE MANDA EL TOTAL DEL INVENTARIO — y es la razón de que
// esta función exista aparte de `fudo-empujar-stock`:
//
//   El inventario va con retraso respecto a la realidad. Puede haber 3
//   cachitos en la vitrina y 1 en una mesa abierta: el inventario dice 4
//   porque esa venta todavía no se cerró, pero en el estante hay 3.
//   Si mandáramos ese 4 a Fudo, estaríamos empujando el retraso al
//   sistema que decide qué se puede vender.
//
//   Llegaron 2 y Fudo tenía 3  ->  Fudo queda en 5. Da lo mismo lo que
//   diga el inventario. Fudo lleva su propia cuenta y la va bajando al
//   vender; lo único que le falta saber es que entró mercadería nueva.
//
// SIGUE SIENDO UN VALOR ABSOLUTO. La regla del proyecto —nunca mandar
// una diferencia— se respeta: la resta la hace Fudo al vender, y acá se
// manda `actual + recibido`, un número entero, no un "+2".
//
// QUÉ PRODUCTOS DE FUDO SE TOCAN, y esto es una decisión:
//   Solo aquellos cuya receta usa ESTE insumo y NINGÚN otro, con
//   cantidad 1. O sea, los 1:1 — el cachito que se vende como cachito.
//   Un combo que además lleva un café NO se toca: cuántos combos se
//   pueden vender depende también del café, y eso lo calcula bien la
//   otra función (`fudo_stock_calculado`, con su min()). Sumarle 2 a un
//   combo porque llegaron 2 sándwiches diría que se pueden vender 2 más
//   sin mirar la bebida.
//
// EL GEMELO DEL OTRO MUEBLE (2026-08-14) — por qué esto no busca solo
// la ficha exacta:
//
//   Los Cannolis de Mall Plaza llegaron en un reparto, se aceptaron, y
//   Fudo no cambió. La causa: el reparto entra al CONGELADOR y la
//   receta descuenta de la VITRINA. Son dos fichas distintas, así que
//   la búsqueda por id exacto no encontraba a quién avisarle, devolvía
//   "sumados 0" y el aviso de la pantalla se iba solo.
//
//   Fudo ya piensa en el PAR: desde el 2026-07-29 el cálculo del botón
//   rojo suma vitrina + congelador por nombre base. Este camino no lo
//   hacía, y por eso los dos no daban lo mismo.
//
//   La regla que se aplica acá: **primero la ficha exacta; solo si esa
//   no tiene receta 1:1 se busca en sus gemelas del mismo nombre base**.
//   Así todo lo que ya funcionaba sigue igual —no se toca— y lo único
//   que cambia es el hueco: el producto que vive en dos muebles.
//
// Cómo se llama:
//   POST { sede, producto_id, cantidad, reparto_item_id? }
//
// Quién puede: CUALQUIERA. Ver la nota larga adentro (2026-08-21).
// ================================================================

const VERSION = "2026-08-21";
const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const SB_URL = Deno.env.get("SUPABASE_URL");
    const SB_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
                ?? Deno.env.get("SUPABASE_SECRET_KEY");
    if (!SB_URL || !SB_KEY) return json({ error: "Falta la configuración de Supabase." }, 500);
    const cab = { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}` };

    // ---------- QUIÉN LO HIZO, no quién puede ----------
    //
    // DECISIÓN DE JHON, 2026-08-21, desde el local y con el problema en la
    // mano: "llega el reparto, lo van a aceptar, se aumenta en el
    // inventario, pero no se sube a Fudo, y eso está causando muchos
    // errores. Necesito que todos puedan actualizar el Fudo."
    //
    // Es la misma apertura que ya se le hizo al botón ⟳ el 15 de agosto, y
    // acá el argumento es todavía más fuerte:
    //
    //   Este camino NO decide nada. Alguien abrió una caja, contó lo que
    //   llegó y lo aceptó en la app; el inventario YA subió. Esto solo le
    //   cuenta a Fudo algo que pasó en el mesón hace un segundo. Un permiso
    //   no evita que el pan llegue: solo evita que Fudo se entere.
    //
    //   Y el que acepta el reparto es el jefe de turno, no jefatura. Pedirle
    //   que avise y espere es exactamente cómo se produjo este problema: el
    //   inventario quedaba bien y Fudo mal, sin que nadie se enterara hasta
    //   que faltaba stock para vender.
    //
    // LO QUE SIGUE CON LLAVE: deshacer un empuje (`fudo-deshacer-stock`).
    // Ese revierte a un estado anterior y puede pisar el trabajo de otro.
    //
    // La sesión se sigue LEYENDO cuando existe, para que la bitácora diga
    // quién fue. Ya no decide si puede: decide cómo firma.
    let correo: string | null = null;
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (jwt) {
      const uRes = await fetch(`${SB_URL}/auth/v1/user`, {
        headers: { "Authorization": `Bearer ${jwt}`, "apikey": SB_KEY },
      });
      try { correo = ((await uRes.json())?.email ?? "").toLowerCase() || null; } catch { /* no-JSON */ }
    }
    // Que no se sepa el nombre no es motivo para dejar Fudo desactualizado.
    if (!correo) correo = "equipo (sin sesión)";

    // ---------- qué se pidió ----------
    const body = await req.json().catch(() => ({}));
    const sede = String(body?.sede ?? "plaza").toLowerCase();
    const productoId = Number(body?.producto_id);
    const cantidad = Number(body?.cantidad);
    const itemId = body?.reparto_item_id != null ? Number(body.reparto_item_id) : null;
    if (!productoId || !Number.isFinite(cantidad) || cantidad <= 0) {
      return json({ version: VERSION, ok: true, sin_efecto: "no llegó cantidad que sumar" });
    }

    // ---------- a qué productos de Fudo les toca ----------
    // Se piden las recetas de la sede con sus líneas, y se dejan solo las
    // que tienen UNA línea, que sea este insumo, con cantidad 1.
    const rRes = await fetch(
      `${SB_URL}/rest/v1/recetas?sede=eq.${encodeURIComponent(sede)}&activo=eq.true`
      + `&select=id,fudo_product_id,fudo_product_nombre,receta_items(producto_id,cantidad)`,
      { headers: cab });
    if (!rRes.ok) return json({ error: "No se pudieron leer las recetas.", detalle: (await rRes.text()).slice(0, 200) }, 500);
    const recetas = await rRes.json();

    // La ficha exacta primero; las gemelas solo si esa no tiene receta 1:1.
    // Las gemelas necesitan los nombres de la sede, y eso es una lectura más:
    // se pide únicamente cuando hace falta.
    let elegido = elegirObjetivos(recetas, productoId, []);
    if (!elegido.objetivos.length) {
      const pRes3 = await fetch(
        `${SB_URL}/rest/v1/productos?sede=eq.${encodeURIComponent(sede)}&select=id,producto`,
        { headers: cab });
      const productos = pRes3.ok ? await pRes3.json() : [];
      elegido = elegirObjetivos(recetas, productoId, productos);
    }
    const objetivos = elegido.objetivos;
    const porGemelo = elegido.porGemelo;

    if (!objetivos.length) {
      return json({
        version: VERSION, ok: true, sumados: 0,
        sin_efecto: "ese producto no es el único insumo de ninguna receta, así que Fudo no lleva su cuenta por separado",
      });
    }

    // ---------- Fudo ----------
    const apiKey = Deno.env.get(`FUDO_${sede.toUpperCase()}_APIKEY`);
    const apiSecret = Deno.env.get(`FUDO_${sede.toUpperCase()}_APISECRET`);
    if (!apiKey || !apiSecret) return json({ error: `Faltan credenciales de Fudo para "${sede}".` }, 400);

    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) return json({ error: `Fudo rechazó la autenticación (${authRes.status}).` }, 502);
    const token = (await authRes.json())?.token;
    if (!token) return json({ error: "Fudo no devolvió un token." }, 502);
    const conFudo = { "Authorization": `Bearer ${token}`, "Accept": "application/json" };

    const lote = crypto.randomUUID();
    const hechos: unknown[] = [], fallados: unknown[] = [], bitacora: unknown[] = [];

    for (const r of objetivos) {
      const fpid = String(r.fudo_product_id);
      let anterior: number | null = null, enviado: number | null = null;
      let ok = false, detalle = "";
      try {
        // 1) Cuánto tiene Fudo AHORA. Este es el paso que hace que no se
        //    empuje el retraso del inventario.
        const gRes = await fetch(`${API_BASE}/products/${fpid}`, { headers: conFudo });
        if (!gRes.ok) throw new Error(`no se pudo leer el producto en Fudo (${gRes.status})`);
        anterior = (await gRes.json())?.data?.attributes?.stock ?? null;

        if (anterior === null) {
          // Fudo nunca le ha llevado stock: se vende sin límite. Ponerle un
          // número lo empezaría a bloquear al llegar a 0, y eso es un cambio
          // de comportamiento en el mesón que nadie pidió acá.
          detalle = "Fudo no le lleva stock a este producto: se deja como está.";
          bitacora.push({ sede, lote, fudo_product_id: fpid, producto_fudo: r.fudo_product_nombre,
                          stock_anterior: null, stock_enviado: null, ok: true,
                          detalle, quien: correo });
          hechos.push({ producto: r.fudo_product_nombre, sin_cambio: detalle });
          continue;
        }

        enviado = Number(anterior) + cantidad;

        // 2) Se manda el TOTAL nuevo, no la diferencia.
        const pRes2 = await fetch(`${API_BASE}/products/${fpid}`, {
          method: "PATCH",
          headers: { ...conFudo, "Content-Type": "application/json" },
          body: JSON.stringify({ data: { type: "Product", id: fpid, attributes: { stock: enviado } } }),
        });
        const txt = await pRes2.text();
        if (!pRes2.ok) throw new Error(`Fudo rechazó el cambio (${pRes2.status}): ${txt.slice(0, 150)}`);

        // 3) Se comprueba releyendo lo que Fudo devuelve, no el 200.
        let confirmado: number | null = null;
        try { confirmado = JSON.parse(txt)?.data?.attributes?.stock ?? null; } catch { /* no-JSON */ }
        ok = confirmado === null || Number(confirmado) === enviado;
        if (!ok) detalle = `Fudo respondió OK pero quedó en ${confirmado}, no en ${enviado}.`;
      } catch (e) {
        detalle = String(e instanceof Error ? e.message : e);
      }

      const fila = { producto: r.fudo_product_nombre, de: anterior, a: enviado,
                     ...(ok ? {} : { error: detalle }) };
      (ok ? hechos : fallados).push(fila);
      bitacora.push({
        sede, lote, fudo_product_id: fpid, producto_fudo: r.fudo_product_nombre,
        stock_anterior: anterior, stock_enviado: enviado, ok,
        detalle: detalle || `+${cantidad} por reparto${itemId ? ` (línea ${itemId})` : ""}`
                 + (porGemelo ? ` · la receta vive en "${porGemelo}"` : ""),
        quien: correo,
      });
    }

    // Bitácora: sin esto un envío equivocado no deja rastro ni se puede deshacer.
    if (bitacora.length) {
      await fetch(`${SB_URL}/rest/v1/fudo_stock_push`, {
        method: "POST",
        headers: { ...cab, "Content-Type": "application/json", "Prefer": "return=minimal" },
        body: JSON.stringify(bitacora),
      }).catch(() => { /* que un fallo de bitácora no oculte el resultado */ });
    }

    return json({
      version: VERSION, ok: fallados.length === 0,
      sede, quien: correo, sumado: cantidad,
      ...(porGemelo ? { por_gemelo: porGemelo } : {}),
      actualizados: hechos.length, con_error: fallados.length,
      cambios: hechos, errores: fallados,
    });
  } catch (e) {
    return json({ error: "Error inesperado.", detalle: String(e) }, 500);
  }
});

/* ================================================================
   A QUÉ PRODUCTOS DE FUDO HAY QUE AVISARLES

   Está afuera del manejador y sin llamadas a la red a propósito: es la
   única decisión con criterio que toma esta función, y así se puede
   probar sola (mismo motivo que `permisosDeLaSede()` en la app).

   Devuelve además `porGemelo` — el nombre de la otra ficha— cuando el
   acierto vino por ahí, para que quede escrito en la bitácora y nadie
   tenga que adivinar por qué se tocó ese producto de Fudo.
   ================================================================ */
export function elegirObjetivos(recetas: any[], productoId: number, productos: any[]) {
  const unaSolaLinea = (recetas ?? []).filter((r: any) => {
    const its = r?.receta_items ?? [];
    return its.length === 1 && Number(its[0].cantidad) === 1;
  });
  const porFicha = (id: number) =>
    unaSolaLinea.filter((r: any) => Number(r.receta_items[0].producto_id) === id);

  // 1) La ficha exacta. Es el camino de siempre y manda.
  const exactas = porFicha(productoId);
  if (exactas.length) return { objetivos: exactas, porGemelo: null as string | null };

  // 2) Solo si esa no tiene receta 1:1: sus gemelas del mismo nombre base.
  //    (El caso Cannoli: entra al congelador, la receta vive en la vitrina.)
  const yo = (productos ?? []).find((p: any) => Number(p.id) === productoId);
  if (!yo) return { objetivos: [], porGemelo: null as string | null };
  const miBase = base(yo.producto);
  if (!miBase) return { objetivos: [], porGemelo: null as string | null };

  for (const p of productos ?? []) {
    if (Number(p.id) === productoId) continue;
    if (base(p.producto) !== miBase) continue;
    const enc = porFicha(Number(p.id));
    if (enc.length) return { objetivos: enc, porGemelo: String(p.producto) };
  }
  return { objetivos: [], porGemelo: null as string | null };
}

/* Nombre base — MISMO criterio que baseNombre() en la app y que
   base_nombre() en la base. Los tres tienen que decir lo mismo: si acá se
   agregara una regla de más (por ejemplo entender "Vitrina de dulces"),
   este camino emparejaría cosas que el motor de descuento no empareja, y
   ese desacuerdo es exactamente el bug de los macarrons. Si algún día se
   amplía, se amplían los tres juntos. */
function base(s: unknown): string {
  return String(s ?? "")
    .toLowerCase()
    .normalize("NFD").replace(/[̀-ͯ]/g, "")
    .replace(/\s+/g, " ").trim()
    .replace(/\s+(vitrina|congelador)$/, "");
}

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), {
    status, headers: { "Content-Type": "application/json", ...CORS },
  });
}
