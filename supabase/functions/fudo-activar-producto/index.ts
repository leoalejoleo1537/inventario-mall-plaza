// ================================================================
// Edge Function: fudo-activar-producto
//
// Enciende o apaga un producto del INVENTARIO y arrastra a Fudo lo que
// corresponda, en un solo gesto.
//
// PARA QUÉ (Jhon, 2026-08-17): "quiero que desde la app podamos activar o
// desactivar productos; al estar desactivado debe desaparecer no solo de
// Fudo sino de la app, y al ser habilitado debe aparecer nuevamente".
//
// Es el problema que Adriana arrastra hace cuatro años: un catálogo de
// Fudo lleno de cosas que ya no se venden y que ella no puede limpiar,
// porque Fudo se niega a borrar lo que alguna vez se vendió (§8).
// Desactivar es la respuesta que el propio Fudo tiene prevista — es la
// casilla "Activo" de su formulario.
//
// QUÉ APAGA EN FUDO, y esta es la decisión que importa:
//
//   NO apaga "el producto de Fudo que se llama igual". Apaga los que
//   quedarían IMPOSIBLES DE HACER. Un producto de Fudo se apaga si algún
//   insumo de su receta quedó apagado, porque ya no se puede preparar; y
//   se vuelve a encender cuando TODOS sus insumos están activos otra vez.
//
//   Sin esa regla, apagar "Brownie Vitrina" apagaría el Brownie de Fudo
//   aunque el del congelador siguiera lleno — y el mesón dejaría de poder
//   vender algo que está ahí.
//
// SE PUEDE DESHACER, al revés que crear: volver a encenderlo devuelve las
// dos cosas. Por eso este camino no lleva la advertencia dura que lleva
// `fudo-crear-producto`.
//
// Cómo se llama:
//   POST { sede, producto_id, activo }        activo: true | false
// ================================================================

const VERSION = "2026-08-18";
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
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!jwt) return json({ error: "Entra con tu cuenta para activar o desactivar productos." }, 401);
    const uRes = await fetch(`${SB_URL}/auth/v1/user`, {
      headers: { "Authorization": `Bearer ${jwt}`, "apikey": SB_KEY },
    });
    let correo: string | null = null;
    try { correo = ((await uRes.json())?.email ?? "").toLowerCase() || null; } catch { /* no-JSON */ }
    if (!uRes.ok || !correo) return json({ error: "Tu sesión caducó. Sal y vuelve a entrar." }, 401);
    const pRes = await fetch(
      `${SB_URL}/rest/v1/app_permisos?correo=eq.${encodeURIComponent(correo)}&select=puede_fudo,puede_ajustes`,
      { headers: cab });
    const permisos = pRes.ok ? await pRes.json() : [];
    if (!permisos?.[0]?.puede_ajustes && !permisos?.[0]?.puede_fudo) {
      return json({ error: "Esta cuenta no puede activar ni desactivar productos." }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const sede = String(body?.sede ?? "").toLowerCase();
    const productoId = Number(body?.producto_id);
    const activo = body?.activo === true;
    if (!sede || !productoId) return json({ error: "Faltan la sede y el producto." }, 400);

    // ---------- 1) el inventario ----------
    const uRes2 = await fetch(
      `${SB_URL}/rest/v1/productos?id=eq.${productoId}&select=id,producto,sede`, {
        method: "PATCH",
        headers: { ...cab, "Content-Type": "application/json", "Prefer": "return=representation" },
        body: JSON.stringify({ activo: activo ? "SÍ" : "NO", updated_at: new Date().toISOString() }),
      });
    if (!uRes2.ok) {
      return json({ error: "No se pudo cambiar el producto en el inventario.",
                    detalle: (await uRes2.text()).slice(0, 300) }, 500);
    }
    const tocado = (await uRes2.json())?.[0];
    if (!tocado) return json({ error: "Ese producto ya no existe." }, 404);

    // ---------- 2) qué productos de Fudo dependen de él ----------
    const rRes = await fetch(
      `${SB_URL}/rest/v1/recetas?sede=eq.${encodeURIComponent(sede)}&activo=eq.true`
      + `&select=id,fudo_product_id,fudo_product_nombre,receta_items(producto_id)`,
      { headers: cab });
    const recetas = rRes.ok ? await rRes.json() : [];
    const candidatas = (recetas ?? []).filter((r: any) =>
      (r.receta_items ?? []).some((i: any) => Number(i.producto_id) === productoId));

    if (!candidatas.length) {
      return json({ version: VERSION, ok: true, sede, activo,
                    producto: tocado.producto, en_fudo: [],
                    sin_efecto_en_fudo: "ningún producto de Fudo usa este insumo" });
    }

    // Para decidir hay que saber cuáles de TODOS los insumos de esas
    // recetas están activos. Se piden de una vez: una consulta por receta
    // sería lento y, con señal floja, la mitad se quedaría sin respuesta.
    const ids = [...new Set(candidatas.flatMap((r: any) =>
      (r.receta_items ?? []).map((i: any) => Number(i.producto_id))))];
    const pRes2 = await fetch(
      `${SB_URL}/rest/v1/productos?id=in.(${ids.join(",")})&select=id,activo`, { headers: cab });
    const estados: Record<number, boolean> = {};
    for (const p of (pRes2.ok ? await pRes2.json() : [])) estados[Number(p.id)] = p.activo === "SÍ";

    // Un producto de Fudo se apaga si YA NO SE PUEDE HACER, y se enciende
    // cuando vuelve a poder hacerse. No es "se llama igual": es si sus
    // ingredientes están.
    const objetivos = candidatas.map((r: any) => {
      const suyos = (r.receta_items ?? []).map((i: any) => Number(i.producto_id));
      const sePuedeHacer = suyos.every((id: number) => estados[id] !== false);
      return { r, sePuedeHacer };
    }).filter((x: any) => x.sePuedeHacer === activo);

    if (!objetivos.length) {
      return json({ version: VERSION, ok: true, sede, activo,
                    producto: tocado.producto, en_fudo: [],
                    sin_efecto_en_fudo: activo
                      ? "sus productos de Fudo siguen con otro insumo apagado"
                      : "sus productos de Fudo ya estaban apagados por otro insumo" });
    }

    // ---------- 3) Fudo ----------
    const apiKey = Deno.env.get(`FUDO_${sede.toUpperCase()}_APIKEY`);
    const apiSecret = Deno.env.get(`FUDO_${sede.toUpperCase()}_APISECRET`);
    if (!apiKey || !apiSecret) {
      return json({ version: VERSION, ok: true, sede, activo, producto: tocado.producto,
                    en_fudo: [], aviso: `El inventario cambió, pero faltan credenciales de Fudo para "${sede}".` });
    }
    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) {
      return json({ version: VERSION, ok: false, sede, activo, producto: tocado.producto,
                    error: `El inventario cambió, pero Fudo rechazó la autenticación (${authRes.status}).` }, 502);
    }
    const token = (await authRes.json())?.token;
    const H = { "Authorization": `Bearer ${token}`, "Accept": "application/json",
                "Content-Type": "application/json" };

    const hechos: unknown[] = [], fallados: unknown[] = [];
    for (const { r } of objetivos) {
      const fpid = String(r.fudo_product_id);
      try {
        const pr = await fetch(`${API_BASE}/products/${fpid}`, {
          method: "PATCH", headers: H,
          body: JSON.stringify({ data: { type: "Product", id: fpid, attributes: { active: activo } } }),
        });
        const txt = await pr.text();
        if (!pr.ok) throw new Error(`Fudo lo rechazó (${pr.status}): ${txt.slice(0, 120)}`);
        hechos.push(r.fudo_product_nombre ?? fpid);
      } catch (e) {
        fallados.push({ producto: r.fudo_product_nombre ?? fpid,
                        error: String(e instanceof Error ? e.message : e) });
      }
    }

    return json({
      version: VERSION, ok: fallados.length === 0,
      sede, activo, producto: tocado.producto, quien: correo,
      en_fudo: hechos, con_error: fallados,
    }, fallados.length ? 502 : 200);
  } catch (e) {
    return json({ error: "Error inesperado.", detalle: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), {
    status, headers: { "Content-Type": "application/json", ...CORS },
  });
}
