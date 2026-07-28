// ================================================================
// Edge Function: fudo-probar-escritura
//
// PROTOTIPO AISLADO. Su único trabajo es responder UNA pregunta:
// ¿la API de Fudo deja modificar el stock de un producto?
//
// No toca el inventario, no toca recetas, no toca la app. Trabaja
// sobre UN producto de Fudo que tú eliges, y lo DEJA COMO ESTABA.
//
// Qué hace, en orden:
//   1. Lee el stock actual del producto en Fudo.
//   2. Le manda el MISMO número. Si esto pasa, el endpoint acepta
//      escritura y nada cambió.
//   3. Le manda ese número +1 y vuelve a leer, para comprobar que
//      de verdad cambió (un "200 OK" que ignora el dato no sirve).
//   4. Lo devuelve a su valor original y lo verifica.
//
// Si el paso 3 funciona pero el 4 falla, lo dice CLARAMENTE y te
// deja el número que hay que corregir a mano. No se calla nada.
//
// Como no sabemos qué formato espera Fudo, prueba varias formas y
// se queda con la primera que funcione. Ese es justamente el dato
// que queremos descubrir.
//
// Cómo se llama:
//   POST .../fudo-probar-escritura
//   { "sede": "plaza", "fudo_product_id": "1234" }
//   con el header Authorization: Bearer <token de tu sesión>
//
// Secrets necesarios (Supabase → Edge Functions → Secrets):
//   FUDO_PLAZA_APIKEY / FUDO_PLAZA_APISECRET   (ya existen)
//   FUDO_STOCK_ADMINS = correos separados por coma, los ÚNICOS que
//                       pueden llamar a esto. Ej: jhon@ejemplo.com
// ================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/* Las formas en que un API puede esperar el cambio. Se prueban en
   orden y se para en la primera que funcione: cada intento escribe,
   así que no se sigue probando después de un éxito. */
const FORMAS = [
  { nombre: "JSON:API (data.attributes)", metodo: "PATCH",
    cuerpo: (id: string, s: number) => ({ data: { type: "Product", id, attributes: { stock: s } } }) },
  { nombre: "JSON:API sin type",          metodo: "PATCH",
    cuerpo: (id: string, s: number) => ({ data: { id, attributes: { stock: s } } }) },
  { nombre: "plano",                      metodo: "PATCH",
    cuerpo: (_id: string, s: number) => ({ stock: s }) },
  { nombre: "plano con PUT",              metodo: "PUT",
    cuerpo: (_id: string, s: number) => ({ stock: s }) },
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const pasos: unknown[] = [];
  const anota = (paso: string, detalle: unknown) => { pasos.push({ paso, ...(detalle as object) }); };

  try {
    // ---------- 1) EL CANDADO: solo un correo autorizado puede entrar ----------
    // Se verifica contra Supabase Auth, en el servidor. No es una
    // contraseña escrita en el navegador: eso cualquiera puede leerlo.
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!jwt) return json({ error: "Falta la sesión. Entra a la app antes de probar." }, 401);

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    const correo = userData?.user?.email?.toLowerCase() ?? null;
    if (userErr || !correo) return json({ error: "Sesión no válida." }, 401);

    const permitidos = (Deno.env.get("FUDO_STOCK_ADMINS") ?? "")
      .split(",").map((x) => x.trim().toLowerCase()).filter(Boolean);
    if (!permitidos.length) {
      return json({ error: "Falta configurar FUDO_STOCK_ADMINS en los Secrets. Sin eso no se permite escribir en Fudo." }, 500);
    }
    if (!permitidos.includes(correo)) {
      return json({ error: "Esta cuenta no tiene permiso para escribir en Fudo." }, 403);
    }

    // ---------- 2) Qué producto vamos a tocar ----------
    const body = await req.json().catch(() => ({}));
    const sede = String(body?.sede ?? "plaza").toLowerCase();
    const productId = body?.fudo_product_id ? String(body.fudo_product_id) : null;
    if (!productId) return json({ error: "Falta fudo_product_id: hay que decir sobre qué producto probar." }, 400);

    const apiKey = Deno.env.get(`FUDO_${sede.toUpperCase()}_APIKEY`);
    const apiSecret = Deno.env.get(`FUDO_${sede.toUpperCase()}_APISECRET`);
    if (!apiKey || !apiSecret) return json({ error: `Faltan credenciales de Fudo para "${sede}".` }, 400);

    // ---------- 3) Token de Fudo ----------
    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) return json({ error: `Fudo rechazó la autenticación (${authRes.status}).`, detalle: await authRes.text() }, 502);
    const token = (await authRes.json())?.token;
    if (!token) return json({ error: "Fudo no devolvió un token." }, 502);

    const cab = { "Authorization": `Bearer ${token}`, "Accept": "application/json" };
    const leerStock = async () => {
      const r = await fetch(`${API_BASE}/products/${productId}`, { headers: cab });
      const t = await r.text();
      let js: any = null; try { js = JSON.parse(t); } catch { /* respuesta no-JSON */ }
      return { ok: r.ok, status: r.status, stock: js?.data?.attributes?.stock ?? null,
               nombre: js?.data?.attributes?.name ?? null, crudo: r.ok ? undefined : t.slice(0, 400) };
    };

    // ---------- 4) Leer el estado de partida ----------
    const antes = await leerStock();
    if (!antes.ok) return json({ error: `No se pudo leer el producto ${productId} (${antes.status}).`, detalle: antes.crudo }, 502);
    if (antes.stock === null) {
      return json({
        veredicto: "SIN STOCK QUE PROBAR",
        explicacion: `"${antes.nombre}" no trae valor de stock. Elige un producto que sí lo tenga.`,
      });
    }
    const original = Number(antes.stock);
    anota("leer estado inicial", { producto: antes.nombre, stock: original });

    // ---------- 5) Buscar la forma que Fudo acepta ----------
    const escribir = async (forma: typeof FORMAS[number], valor: number) => {
      const r = await fetch(`${API_BASE}/products/${productId}`, {
        method: forma.metodo,
        headers: { ...cab, "Content-Type": "application/json" },
        body: JSON.stringify(forma.cuerpo(productId, valor)),
      });
      return { ok: r.ok, status: r.status, respuesta: (await r.text()).slice(0, 400) };
    };

    let forma: typeof FORMAS[number] | null = null;
    for (const f of FORMAS) {
      // se manda el MISMO número: si pasa, nada cambió
      const r = await escribir(f, original);
      anota(`probar forma "${f.nombre}" (${f.metodo})`, { acepta: r.ok, status: r.status, respuesta: r.respuesta });
      if (r.ok) { forma = f; break; }
    }
    if (!forma) {
      return json({
        veredicto: "FUDO NO DEJA ESCRIBIR EL STOCK",
        explicacion: "Ninguna de las formas probadas fue aceptada. El producto quedó intacto. "
                   + "Con esto hay que preguntarle al soporte de Fudo por el endpoint correcto, "
                   + "o descartar el empuje automático.",
        producto: antes.nombre, stock: original, pasos,
      });
    }

    // ---------- 6) ¿De verdad cambia? Un 200 que ignora el dato no sirve ----------
    const prueba = original + 1;
    const wr = await escribir(forma, prueba);
    anota("escribir stock+1", { enviado: prueba, acepta: wr.ok, status: wr.status });
    const despues = await leerStock();
    anota("releer", { stock_leido: despues.stock });
    const cambioDeVerdad = Number(despues.stock) === prueba;

    // ---------- 7) Dejarlo COMO ESTABA ----------
    const rest = await escribir(forma, original);
    const final = await leerStock();
    const restaurado = Number(final.stock) === original;
    anota("restaurar", { enviado: original, acepta: rest.ok, stock_final: final.stock, restaurado });

    if (!restaurado) {
      return json({
        veredicto: "⚠️ HAY QUE CORREGIR A MANO",
        explicacion: `El producto "${antes.nombre}" quedó en ${final.stock} y debería estar en ${original}. `
                   + "Corrígelo en el panel de Fudo.",
        forma_que_funciona: forma.nombre, metodo: forma.metodo, pasos,
      }, 500);
    }

    return json({
      veredicto: cambioDeVerdad ? "SÍ SE PUEDE ESCRIBIR" : "ACEPTA LA LLAMADA PERO NO CAMBIA EL DATO",
      explicacion: cambioDeVerdad
        ? "Fudo aceptó el cambio y el número cambió de verdad. El producto quedó como estaba."
        : "Fudo respondió OK pero el stock no se movió. Puede que el campo sea de solo lectura "
        + "o que dependa de otra cosa (por ejemplo, que stockControl esté encendido).",
      forma_que_funciona: forma.nombre,
      metodo: forma.metodo,
      producto: antes.nombre,
      stock_original: original,
      quedo_como_estaba: restaurado,
      pasos,
    });
  } catch (e) {
    return json({ error: "Error inesperado.", detalle: String(e), pasos }, 500);
  }
});

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), {
    status, headers: { "Content-Type": "application/json", ...CORS },
  });
}
