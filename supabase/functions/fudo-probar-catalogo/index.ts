// ================================================================
// Edge Function: fudo-probar-catalogo   —   PRUEBA AISLADA
//
// LA PREGUNTA QUE VIENE A CONTESTAR:
//   ¿Se pueden BORRAR productos del catálogo de Fudo desde la API?
//   Adriana lleva 4 años sin poder limpiar el catálogo porque la
//   pantalla de Fudo no la deja. Si la API sí deja, eso cambia todo.
//
// POR QUÉ NO PRUEBA CON UN PRODUCTO DE VERDAD:
//   Porque si borrar funciona, ese producto se perdió — y si además
//   crear NO funciona, no hay forma de devolverlo. Así que la prueba
//   crea un producto de mentira y lo borra a él. Con eso se aprenden
//   las dos cosas sin tocar nada que le importe a nadie.
//
//   Es la misma lección de la impresora y del primer empuje a Fudo:
//   un prototipo aislado antes de prometer nada (§7).
//
// QUÉ HACE, EN ORDEN:
//   1. Lee un producto real que exista, solo para copiarle la forma
//      (qué campos trae, a qué categoría pertenece). NO lo toca.
//   2. Intenta CREAR "ZZZ PRUEBA CLAUDE - ignorar".
//   3. Si se creó, intenta DESACTIVARLO. Y lo vuelve a activar.
//   4. Si se creó, intenta BORRARLO.
//   5. Comprueba releyendo si de verdad desapareció.
//
// QUÉ DEJA:
//   Nada, si borrar funciona.
//   Si crear funciona pero borrar no: queda "ZZZ PRUEBA CLAUDE",
//   desactivado, al final de la lista. Se avisa en la respuesta.
//
// Cómo se llama:  POST { sede: "angamos" }
//   modelo: nombre de un producto existente del que copiar la forma.
//           Por omisión toma el primero que encuentre.
//
// ESTA FUNCIÓN ES TEMPORAL: cuando decidamos, se borra.
// ================================================================

const VERSION = "2026-08-06";
const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";
const NOMBRE_PRUEBA = "ZZZ PRUEBA CLAUDE - ignorar";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const url = new URL(req.url);
    let bodySede: string | null = null, modelo: string | null = null;
    if (req.method === "POST") {
      const b = await req.json().catch(() => ({}));
      bodySede = b?.sede ?? null;
      modelo = b?.modelo ?? null;
    }
    const sede = (url.searchParams.get("sede") ?? bodySede ?? "angamos").toLowerCase();

    const apiKey = Deno.env.get(`FUDO_${sede.toUpperCase()}_APIKEY`);
    const apiSecret = Deno.env.get(`FUDO_${sede.toUpperCase()}_APISECRET`);
    if (!apiKey || !apiSecret) return json({ error: `Faltan las credenciales de Fudo para "${sede}".` }, 400);

    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) return json({ error: `Fudo rechazó la autenticación (${authRes.status}).` }, 502);
    const token = (await authRes.json())?.token;
    if (!token) return json({ error: "Fudo no devolvió token." }, 502);
    const H = { "Authorization": `Bearer ${token}`, "Accept": "application/json" };
    const HJ = { ...H, "Content-Type": "application/json" };

    const pasos: Record<string, unknown>[] = [];
    const anota = (que: string, r: { ok: boolean; status: number; txt: string }, extra = {}) =>
      pasos.push({ paso: que, funciona: r.ok, http: r.status,
                   respuesta: r.txt.slice(0, 300), ...extra });

    const pedir = async (ruta: string, init?: RequestInit) => {
      const r = await fetch(`${API_BASE}${ruta}`, init);
      const txt = await r.text();
      return { ok: r.ok, status: r.status, txt };
    };

    // ---------- 1) Copiar la forma de un producto que ya existe ----------
    const lista = await pedir(`/products?page[size]=50&page[number]=1`, { headers: H });
    if (!lista.ok) return json({ version: VERSION, sede, error: "No se pudo leer el catálogo.", detalle: lista.txt.slice(0, 300) }, 502);
    const datos = JSON.parse(lista.txt)?.data ?? [];
    const base = modelo
      ? datos.find((d: any) => String(d.attributes?.name ?? "").toLowerCase() === modelo.toLowerCase())
      : datos[0];
    if (!base) return json({ version: VERSION, sede, error: `No encontré el producto "${modelo}" para copiarle la forma.` }, 404);

    const categoria = base.relationships?.productCategory?.data?.id ?? null;
    pasos.push({
      paso: "leer un producto de ejemplo",
      funciona: true,
      producto: base.attributes?.name,
      campos_que_trae: Object.keys(base.attributes ?? {}),
      categoria_id: categoria,
    });

    // ---------- 2) CREAR ----------
    const cuerpoNuevo: Record<string, unknown> = {
      data: {
        type: "Product",
        attributes: { name: NOMBRE_PRUEBA, price: 1, active: true },
        ...(categoria ? { relationships: { productCategory: { data: { type: "ProductCategory", id: categoria } } } } : {}),
      },
    };
    const crear = await pedir(`/products`, { method: "POST", headers: HJ, body: JSON.stringify(cuerpoNuevo) });
    anota("CREAR un producto nuevo", crear);

    let idPrueba: string | null = null;
    try { idPrueba = JSON.parse(crear.txt)?.data?.id ?? null; } catch { /* no-JSON */ }

    // ---------- 3) DESACTIVAR y volver a activar ----------
    let desactivar: { ok: boolean; status: number; txt: string } | null = null;
    if (idPrueba) {
      desactivar = await pedir(`/products/${idPrueba}`, {
        method: "PATCH", headers: HJ,
        body: JSON.stringify({ data: { type: "Product", id: idPrueba, attributes: { active: false } } }),
      });
      anota("DESACTIVAR (sin borrar)", desactivar);
    }

    // ---------- 4) BORRAR ----------
    let borrar: { ok: boolean; status: number; txt: string } | null = null;
    let seguiaAhi: boolean | null = null;
    if (idPrueba) {
      borrar = await pedir(`/products/${idPrueba}`, { method: "DELETE", headers: H });
      anota("BORRAR de verdad", borrar);

      // 5) La comprobación que importa: releer. Un 200 no prueba nada.
      const rele = await pedir(`/products/${idPrueba}`, { headers: H });
      seguiaAhi = rele.ok;
      pasos.push({ paso: "releer para comprobar", funciona: !rele.ok,
                   http: rele.status,
                   resultado: rele.ok ? "SIGUE EXISTIENDO" : "ya no está" });
    }

    // ---------- veredicto ----------
    const sePuedeCrear = !!idPrueba;
    const sePuedeDesactivar = !!desactivar?.ok;
    const sePuedeBorrar = !!borrar?.ok && seguiaAhi === false;

    const veredicto = sePuedeBorrar
      ? "✅ SÍ SE PUEDE BORRAR. La limpieza definitiva del catálogo es posible."
      : sePuedeDesactivar
        ? "🟡 NO se puede borrar, pero SÍ desactivar. El producto deja de venderse y no ensucia, pero sigue en la lista."
        : sePuedeCrear
          ? "🟠 Se puede crear pero ni borrar ni desactivar."
          : "❌ La API no deja tocar el catálogo. Solo leerlo y cambiarle el stock.";

    const queHacer = sePuedeBorrar
      ? "Se puede construir la limpieza de verdad. Va con vista previa, registro y respaldo de lo borrado — un producto borrado por error no se recupera de otra forma."
      : sePuedeDesactivar
        ? "Desactivar resuelve el problema de fondo: el duplicado deja de aparecer para vender. No es 'borrar', pero para Adriana el efecto en el mesón es el mismo."
        : "Habría que hacerlo desde la pantalla de Fudo, o preguntarle a Fudo si la cuenta tiene permisos de escritura de catálogo.";

    return json({
      version: VERSION, sede,
      veredicto,
      se_puede_crear: sePuedeCrear,
      se_puede_desactivar: sePuedeDesactivar,
      se_puede_borrar: sePuedeBorrar,
      que_hacer: queHacer,
      ...(sePuedeCrear && !sePuedeBorrar
        ? { ojo: `Quedó el producto "${NOMBRE_PRUEBA}" en el catálogo${sePuedeDesactivar ? ", desactivado" : ""}. Hay que sacarlo a mano desde Fudo.` }
        : {}),
      detalle_paso_a_paso: pasos,
      recordatorio: "Esta función es una prueba aislada y es temporal: cuando decidamos, se borra. NO tocó ningún producto real.",
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
