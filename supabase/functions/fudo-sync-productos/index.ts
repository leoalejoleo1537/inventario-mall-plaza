// ================================================================
// Edge Function: fudo-sync-productos
//
// Trae la lista de productos de Fudo de UNA sede y la guarda en la
// tabla public.fudo_productos. Es SOLO LECTURA de Fudo: no toca
// ventas ni stock. Se puede correr las veces que quieras.
//
// Cómo se llama:   .../fudo-sync-productos?sede=plaza
//
// Secrets necesarios (Supabase → Edge Functions → Secrets):
//   FUDO_PLAZA_APIKEY     y  FUDO_PLAZA_APISECRET
//   FUDO_ANGAMOS_APIKEY   y  FUDO_ANGAMOS_APISECRET   (cuando toque)
// (SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los inyecta Supabase solo.)
// ================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";
const PAGE_SIZE = 500; // máximo permitido por Fudo

Deno.serve(async (req) => {
  try {
    // sede desde la URL (?sede=plaza). Por defecto: plaza.
    const sede = (new URL(req.url).searchParams.get("sede") ?? "plaza").toLowerCase();
    const KEY = `FUDO_${sede.toUpperCase()}_APIKEY`;
    const SECRET = `FUDO_${sede.toUpperCase()}_APISECRET`;

    const apiKey = Deno.env.get(KEY);
    const apiSecret = Deno.env.get(SECRET);
    if (!apiKey || !apiSecret) {
      return json({ error: `Faltan credenciales de Fudo para la sede "${sede}". Configura ${KEY} y ${SECRET} en los Secrets.` }, 400);
    }

    // 1) Autenticación → token (dura 24 h)
    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) {
      return json({ error: `Fudo rechazó la autenticación (${authRes.status}).`, detalle: await authRes.text() }, 502);
    }
    const auth = await authRes.json();
    if (!auth?.token) return json({ error: "Fudo no devolvió un token." }, 502);

    // 2) Traer productos, página por página, hasta que venga una página incompleta
    const productos: any[] = [];
    for (let page = 1; ; page++) {
      const res = await fetch(`${API_BASE}/products?page[size]=${PAGE_SIZE}&page[number]=${page}`, {
        headers: { "Authorization": `Bearer ${auth.token}`, "Accept": "application/json" },
      });
      if (!res.ok) {
        return json({ error: `Error al leer productos de Fudo (${res.status}).`, detalle: await res.text() }, 502);
      }
      const data = (await res.json())?.data ?? [];
      productos.push(...data);
      if (data.length < PAGE_SIZE) break; // última página
    }

    // 3) Guardar en Supabase (con la llave de servicio, salta RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const filas = productos.map((p) => ({
      sede,
      fudo_product_id: String(p.id),
      nombre: p.attributes?.name ?? null,
      code: p.attributes?.code ?? null,
      precio: p.attributes?.price ?? null,
      categoria_id: p.relationships?.productCategory?.data?.id ?? null,
      activo: p.attributes?.active ?? null,
      raw: p.attributes ?? {},
      synced_at: new Date().toISOString(),
    }));

    if (filas.length) {
      const { error } = await supabase
        .from("fudo_productos")
        .upsert(filas, { onConflict: "sede,fudo_product_id" });
      if (error) return json({ error: "Error al guardar en Supabase.", detalle: error.message }, 500);
    }

    return json({ ok: true, sede, productos_sincronizados: filas.length });
  } catch (e) {
    return json({ error: "Error inesperado.", detalle: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
