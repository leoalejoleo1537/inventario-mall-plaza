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
//
// SIEMPRE manda el número ABSOLUTO, nunca una diferencia. Fudo
// descuenta su propio stock al vender, así que mandar "+3" restaría
// dos veces; mandando el total, cada envío corrige la deriva solo.
//
// Secrets necesarios:
//   FUDO_<SEDE>_APIKEY / FUDO_<SEDE>_APISECRET
//   FUDO_STOCK_ADMINS  -> correos autorizados, separados por coma
// ================================================================

const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Fila = {
  fudo_product_id: string; producto_fudo: string;
  stock_en_fudo: number | null; stock_calculado: number;
  insumo_que_limita: string; insumos: string;
  ignorados: string | null;   // envases, que no limitan la venta
  deja_en_cero: boolean;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const SB_URL = Deno.env.get("SUPABASE_URL");
    const SB_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
                ?? Deno.env.get("SUPABASE_SECRET_KEY");
    if (!SB_URL || !SB_KEY) return json({ error: "Falta la configuración de Supabase en el entorno." }, 500);

    // ---------- El candado: contra la sesión real, en el servidor ----------
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!jwt) return json({ error: "Falta la sesión. Entra a la app antes de actualizar Fudo." }, 401);

    const uRes = await fetch(`${SB_URL}/auth/v1/user`, {
      headers: { "Authorization": `Bearer ${jwt}`, "apikey": SB_KEY },
    });
    const uTxt = await uRes.text();
    let correo: string | null = null;
    try { correo = (JSON.parse(uTxt)?.email ?? "").toLowerCase() || null; } catch { /* no-JSON */ }
    if (!uRes.ok || !correo) {
      return json({
        error: "Tu sesión caducó. Sal y vuelve a entrar a la app.",
        diagnostico: { status_de_auth: uRes.status, respuesta: uTxt.slice(0, 200) },
      }, 401);
    }
    const permitidos = (Deno.env.get("FUDO_STOCK_ADMINS") ?? "")
      .split(",").map((x) => x.trim().toLowerCase()).filter(Boolean);
    if (!permitidos.length) return json({ error: "Falta configurar FUDO_STOCK_ADMINS." }, 500);
    if (!permitidos.includes(correo)) {
      return json({ error: "Esta cuenta no puede actualizar el stock de Fudo." }, 403);
    }

    // ---------- Qué se pidió ----------
    const body = await req.json().catch(() => ({}));
    const sede = String(body?.sede ?? "plaza").toLowerCase();
    const modo = body?.modo === "aplicar" ? "aplicar" : "simular";
    const productoId = body?.producto_id != null ? Number(body.producto_id) : null;
    const unoDeFudo = body?.fudo_product_id ? String(body.fudo_product_id) : null;
    const incluirCeros = body?.incluir_ceros === true;

    // ---------- El cálculo lo hace la base ----------
    const cRes = await fetch(`${SB_URL}/rest/v1/rpc/fudo_stock_calculado`, {
      method: "POST",
      headers: { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({ p_sede: sede, p_producto_id: productoId }),
    });
    if (!cRes.ok) {
      return json({ error: "No se pudo calcular el stock.", detalle: (await cRes.text()).slice(0, 300) }, 500);
    }
    let filas: Fila[] = await cRes.json();
    if (unoDeFudo) filas = filas.filter((f) => f.fudo_product_id === unoDeFudo);

    // Los que ya están iguales no se tocan: menos llamadas y menos ruido.
    const yaIguales = filas.filter((f) => Number(f.stock_en_fudo) === Number(f.stock_calculado));
    const enCero = filas.filter((f) => f.deja_en_cero);
    let porHacer = filas.filter((f) => Number(f.stock_en_fudo) !== Number(f.stock_calculado));
    if (!incluirCeros) porHacer = porHacer.filter((f) => !f.deja_en_cero);

    const resumen = {
      sede, modo, quien: correo,
      se_actualizarian: porHacer.length,
      ya_estaban_iguales: yaIguales.length,
      saltados_por_quedar_en_cero: incluirCeros ? 0 : enCero.length,
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
        })),
        quedarian_en_cero: enCero.map((f) => ({
          producto: f.producto_fudo, tiene_en_fudo: f.stock_en_fudo,
          limita: f.insumo_que_limita, receta: f.insumos,
        })),
      });
    }

    // ---------- Aplicar ----------
    if (!porHacer.length) return json({ ...resumen, ok: true, cambios: [] });

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

    const hechos: unknown[] = [], fallados: unknown[] = [], bitacora: unknown[] = [];
    for (const f of porHacer) {
      const valor = Number(f.stock_calculado);
      let ok = false, detalle = "", confirmado: number | null = null;
      try {
        // Formato confirmado con la prueba aislada: JSON:API, PATCH.
        const r = await fetch(`${API_BASE}/products/${f.fudo_product_id}`, {
          method: "PATCH",
          headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json", "Content-Type": "application/json" },
          body: JSON.stringify({
            data: { type: "Product", id: f.fudo_product_id, attributes: { stock: valor } },
          }),
        });
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
        detalle = `No se pudo contactar a Fudo: ${String(e)}`;
      }

      const fila = { producto: f.producto_fudo, de: f.stock_en_fudo, a: valor, ...(ok ? {} : { error: detalle }) };
      (ok ? hechos : fallados).push(fila);
      bitacora.push({
        sede, fudo_product_id: f.fudo_product_id, producto_fudo: f.producto_fudo,
        stock_anterior: f.stock_en_fudo, stock_enviado: valor, ok, detalle: detalle || null, quien: correo,
      });
    }

    // Bitácora: sin esto, un empuje equivocado no deja rastro.
    if (bitacora.length) {
      await fetch(`${SB_URL}/rest/v1/fudo_stock_push`, {
        method: "POST",
        headers: { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}`,
                   "Content-Type": "application/json", "Prefer": "return=minimal" },
        body: JSON.stringify(bitacora),
      }).catch(() => { /* que un fallo de bitácora no oculte el resultado */ });
    }

    return json({
      ...resumen,
      ok: fallados.length === 0,
      actualizados: hechos.length,
      con_error: fallados.length,
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
