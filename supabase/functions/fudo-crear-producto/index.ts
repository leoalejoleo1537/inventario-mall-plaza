// ================================================================
// Edge Function: fudo-crear-producto
//
// Crea un producto en el catálogo de Fudo y le deja la receta hecha,
// apuntando al producto del inventario que acaba de nacer en la sede.
//
// PARA QUÉ (Jhon, 2026-08-17): "este producto debería crearse también en
// Fudo, generando con su nacimiento todos los enlaces y recetas".
//
// Hoy, crear un producto en bodega y que se venda en el local son dos
// trabajos separados con horas o días entre medio, y en ese hueco el
// producto existe en el inventario y no se puede vender — o se vende y no
// descuenta nada, que es peor.
//
// ⚠️ ESTO ES IRREVERSIBLE, y por eso lleva candado y no se hace solo.
// Está medido (§8): la API de Fudo deja CREAR y DESACTIVAR, pero **no
// deja BORRAR**. Un producto creado por error se queda ahí para siempre,
// apagado. Es exactamente el problema que Adriana arrastra hace cuatro
// años, así que este camino no puede ser cómodo por accidente:
//   · lo pide una persona, marcando una casilla que nace apagada
//   · exige sesión y permiso, al revés que el empuje de stock
//   · si el nombre ya existe en Fudo, NO crea otro: usa el que hay
//
// EL PRECIO ES OBLIGATORIO, y no es burocracia: Fudo acepta crear con
// precio 0, y un producto en 0 se vende gratis en el mesón. Un campo de
// más acá evita una venta regalada allá.
//
// Cómo se llama:
//   POST { sede, producto_id, nombre, precio }
//
// producto_id es el del INVENTARIO de esa sede — el que ya creó
// `crear_producto_enlazado`. Es a quien va a apuntar la receta.
// ================================================================

const VERSION = "2026-08-17";
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

    // ---------- el candado ----------
    // Acá SÍ se exige sesión y permiso, al revés que el empuje de stock.
    // La diferencia no es de gusto: el empuje se corrige solo en la
    // corrida siguiente, y esto no se puede deshacer nunca.
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!jwt) return json({ error: "Entra con tu cuenta para crear productos en Fudo." }, 401);
    const uRes = await fetch(`${SB_URL}/auth/v1/user`, {
      headers: { "Authorization": `Bearer ${jwt}`, "apikey": SB_KEY },
    });
    let correo: string | null = null;
    try { correo = ((await uRes.json())?.email ?? "").toLowerCase() || null; } catch { /* no-JSON */ }
    if (!uRes.ok || !correo) return json({ error: "Tu sesión caducó. Sal y vuelve a entrar." }, 401);
    const pRes = await fetch(
      `${SB_URL}/rest/v1/app_permisos?correo=eq.${encodeURIComponent(correo)}&select=puede_fudo`, { headers: cab });
    const permisos = pRes.ok ? await pRes.json() : [];
    if (!permisos?.[0]?.puede_fudo) {
      return json({ error: "Esta cuenta no puede crear productos en Fudo." }, 403);
    }

    // ---------- qué se pidió ----------
    const body = await req.json().catch(() => ({}));
    const sede = String(body?.sede ?? "").toLowerCase();
    const productoId = Number(body?.producto_id);
    const nombre = String(body?.nombre ?? "").trim();
    const precio = Number(body?.precio);
    if (!sede || !productoId || !nombre) {
      return json({ error: "Faltan datos: sede, producto del inventario y nombre." }, 400);
    }
    if (!Number.isFinite(precio) || precio <= 0) {
      return json({ error: "Falta el precio. Un producto en 0 se vendería gratis." }, 400);
    }

    const apiKey = Deno.env.get(`FUDO_${sede.toUpperCase()}_APIKEY`);
    const apiSecret = Deno.env.get(`FUDO_${sede.toUpperCase()}_APISECRET`);
    if (!apiKey || !apiSecret) return json({ error: `Faltan credenciales de Fudo para "${sede}".` }, 400);

    // ---------- ¿ya existe uno con ese nombre? ----------
    // Nunca crear sin buscar primero (regla 0.1.3). Acá pesa el doble
    // porque un duplicado en Fudo no se puede borrar. Se busca en el
    // espejo local del catálogo, comparando sin tildes ni mayúsculas.
    const eRes = await fetch(
      `${SB_URL}/rest/v1/fudo_productos?sede=eq.${encodeURIComponent(sede)}&select=fudo_product_id,nombre`,
      { headers: cab });
    const espejo = eRes.ok ? await eRes.json() : [];
    const limpio = (s: unknown) => String(s ?? "").toLowerCase()
      .normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/\s+/g, " ").trim();
    const yaEsta = (espejo ?? []).find((f: any) => limpio(f.nombre) === limpio(nombre));

    // ---------- Fudo ----------
    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) return json({ error: `Fudo rechazó la autenticación (${authRes.status}).` }, 502);
    const token = (await authRes.json())?.token;
    if (!token) return json({ error: "Fudo no devolvió un token." }, 502);
    const H = { "Authorization": `Bearer ${token}`, "Accept": "application/json" };

    let fudoId: string | null = yaEsta ? String(yaEsta.fudo_product_id) : null;
    let creado = false;

    if (!fudoId) {
      // El cuerpo es el que se midió en la prueba de catálogo y devolvió
      // 201. `active` NO va acá: en el alta Fudo lo rechaza por esquema.
      const cRes = await fetch(`${API_BASE}/products`, {
        method: "POST",
        headers: { ...H, "Content-Type": "application/json" },
        body: JSON.stringify({ data: { type: "Product", attributes: { name: nombre, price: precio } } }),
      });
      const txt = await cRes.text();
      if (!cRes.ok) {
        return json({ error: `Fudo no aceptó crear el producto (${cRes.status}).`,
                      detalle: txt.slice(0, 300) }, 502);
      }
      try { fudoId = String(JSON.parse(txt)?.data?.id ?? ""); } catch { /* no-JSON */ }
      if (!fudoId) return json({ error: "Fudo creó el producto pero no dijo su id.", detalle: txt.slice(0, 300) }, 502);
      creado = true;

      // El espejo local se actualiza acá mismo. Si se dejara para la
      // próxima sincronización, entre medio el producto existiría en Fudo
      // y no en nuestra copia — y una segunda creación no lo encontraría
      // y haría un duplicado imborrable.
      await fetch(`${SB_URL}/rest/v1/fudo_productos?on_conflict=sede,fudo_product_id`, {
        method: "POST",
        headers: { ...cab, "Content-Type": "application/json", "Prefer": "resolution=merge-duplicates,return=minimal" },
        body: JSON.stringify([{ sede, fudo_product_id: fudoId, nombre, precio, activo: true }]),
      }).catch(() => { /* que un fallo del espejo no oculte el resultado */ });
    }

    // ---------- la receta ----------
    // Un producto de Fudo sin receta no descuenta nada: se vendería sin
    // tocar el inventario, que es la mitad del trabajo sin hacer.
    const rRes = await fetch(`${SB_URL}/rest/v1/recetas?on_conflict=sede,fudo_product_id`, {
      method: "POST",
      headers: { ...cab, "Content-Type": "application/json",
                 "Prefer": "resolution=merge-duplicates,return=representation" },
      body: JSON.stringify([{ sede, fudo_product_id: fudoId, fudo_product_nombre: nombre, activo: true }]),
    });
    const recetaTxt = await rRes.text();
    if (!rRes.ok) {
      return json({ ok: false, fudo_product_id: fudoId, creado,
                    error: "El producto quedó en Fudo, pero no se pudo crear su receta.",
                    detalle: recetaTxt.slice(0, 300) }, 502);
    }
    let recetaId: number | null = null;
    try { recetaId = JSON.parse(recetaTxt)?.[0]?.id ?? null; } catch { /* no-JSON */ }

    if (recetaId) {
      await fetch(`${SB_URL}/rest/v1/receta_items?on_conflict=receta_id,producto_id`, {
        method: "POST",
        headers: { ...cab, "Content-Type": "application/json",
                   "Prefer": "resolution=merge-duplicates,return=minimal" },
        body: JSON.stringify([{ receta_id: recetaId, producto_id: productoId, cantidad: 1 }]),
      });
    }

    return json({
      version: VERSION, ok: true, sede, nombre,
      fudo_product_id: fudoId,
      creado_en_fudo: creado,
      ya_existia: !creado,
      receta_id: recetaId,
      quien: correo,
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
