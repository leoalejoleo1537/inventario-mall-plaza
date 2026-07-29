// ================================================================
// Edge Function: fudo-deshacer-stock
//
// Devuelve a Fudo los valores que tenía ANTES del último empuje.
// Solo el último: deshacer uno de hace tres días, con ventas de por
// medio, restauraría números que ya no significan nada.
//
// Cómo se llama:
//   POST { sede, modo }
//     modo: "simular"  -> NO toca Fudo. Devuelve qué devolvería.
//           "aplicar"  -> escribe de verdad.
//
// Quién puede: solo los correos con puede_fudo en public.app_permisos.
// Se comprueba acá, en el servidor. Que la app esconda el botón es
// comodidad; el candado está en esta función.
//
// Secrets necesarios:
//   FUDO_<SEDE>_APIKEY / FUDO_<SEDE>_APISECRET
// ================================================================

const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Fila = {
  lote: string; cuando: string; quien: string | null;
  fudo_product_id: string; producto_fudo: string;
  stock_ahora: number; volveria_a: number | null;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const SB_URL = Deno.env.get("SUPABASE_URL");
    const SB_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
                ?? Deno.env.get("SUPABASE_SECRET_KEY");
    if (!SB_URL || !SB_KEY) return json({ error: "Falta la configuración de Supabase." }, 500);

    // ---------- Quién es, y si puede ----------
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!jwt) return json({ error: "Falta la sesión. Entra a la app antes de deshacer." }, 401);

    const uRes = await fetch(`${SB_URL}/auth/v1/user`, {
      headers: { "Authorization": `Bearer ${jwt}`, "apikey": SB_KEY },
    });
    const uTxt = await uRes.text();
    let correo: string | null = null;
    try { correo = (JSON.parse(uTxt)?.email ?? "").toLowerCase() || null; } catch { /* no-JSON */ }
    if (!uRes.ok || !correo) {
      return json({ error: "Tu sesión caducó. Sal y vuelve a entrar a la app." }, 401);
    }

    const pRes = await fetch(
      `${SB_URL}/rest/v1/app_permisos?correo=eq.${encodeURIComponent(correo)}&select=puede_fudo`,
      { headers: { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}` } });
    const permisos = pRes.ok ? await pRes.json() : [];
    if (!permisos?.[0]?.puede_fudo) {
      return json({ error: "Esta cuenta no puede tocar el stock de Fudo." }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const sede = String(body?.sede ?? "plaza").toLowerCase();
    const modo = body?.modo === "aplicar" ? "aplicar" : "simular";

    // ---------- Qué habría que devolver ----------
    const cRes = await fetch(`${SB_URL}/rest/v1/rpc/fudo_ultimo_empuje`, {
      method: "POST",
      headers: { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({ p_sede: sede }),
    });
    if (!cRes.ok) {
      return json({ error: "No se pudo leer el último empuje.", detalle: (await cRes.text()).slice(0, 300) }, 500);
    }
    const filas: Fila[] = await cRes.json();
    if (!filas.length) {
      return json({ sede, modo, hay_algo_que_deshacer: false,
                    mensaje: "No hay ningún empuje que deshacer." });
    }

    /* Un producto sin valor anterior nunca lo tuvo: Fudo lo tenía en null
       antes de que lo empujáramos. Devolverlo a 0 sería inventar un dato y
       dejaría de venderse. Se salta y se dice. */
    const sinPrevio = filas.filter((f) => f.volveria_a === null);
    const porHacer  = filas.filter((f) => f.volveria_a !== null);

    const cabecera = {
      sede, modo, quien: correo,
      empuje_del: filas[0].cuando,
      lo_hizo: filas[0].quien,
      se_devolverian: porHacer.length,
      saltados_sin_valor_anterior: sinPrevio.length,
    };

    if (modo === "simular") {
      return json({
        ...cabecera,
        hay_algo_que_deshacer: true,
        cambios: porHacer.map((f) => ({
          producto: f.producto_fudo, de: f.stock_ahora, a: f.volveria_a,
        })),
        sin_valor_anterior: sinPrevio.map((f) => ({
          producto: f.producto_fudo,
          motivo: "Fudo no le llevaba stock antes de este empuje; volver a 0 lo dejaría sin vender.",
        })),
      });
    }

    // ---------- Aplicar ----------
    if (!porHacer.length) return json({ ...cabecera, ok: true, cambios: [] });

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

    // el deshacer también queda en la bitácora, con su propio lote:
    // si algo sale mal, se ve que hubo una vuelta atrás y qué hizo
    const lote = crypto.randomUUID();
    const hechos: unknown[] = [], fallados: unknown[] = [], bitacora: unknown[] = [];

    for (const f of porHacer) {
      const valor = Number(f.volveria_a);
      let ok = false, detalle = "", confirmado: number | null = null;
      try {
        const r = await fetch(`${API_BASE}/products/${f.fudo_product_id}`, {
          method: "PATCH",
          headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json",
                     "Content-Type": "application/json" },
          body: JSON.stringify({
            data: { type: "Product", id: f.fudo_product_id, attributes: { stock: valor } },
          }),
        });
        const txt = await r.text();
        if (r.ok) {
          // se comprueba releyendo lo que Fudo devuelve, no se confía en el 200
          try { confirmado = JSON.parse(txt)?.data?.attributes?.stock ?? null; } catch { /* no-JSON */ }
          ok = confirmado === null || Number(confirmado) === valor;
          if (!ok) detalle = `Fudo respondió OK pero quedó en ${confirmado}, no en ${valor}.`;
        } else {
          detalle = `Fudo rechazó el cambio (${r.status}): ${txt.slice(0, 200)}`;
        }
      } catch (e) {
        detalle = `No se pudo contactar a Fudo: ${String(e)}`;
      }

      const fila = { producto: f.producto_fudo, de: f.stock_ahora, a: valor,
                     ...(ok ? {} : { error: detalle }) };
      (ok ? hechos : fallados).push(fila);
      bitacora.push({
        sede, lote, fudo_product_id: f.fudo_product_id, producto_fudo: f.producto_fudo,
        stock_anterior: f.stock_ahora, stock_enviado: valor, ok,
        detalle: detalle || `deshacer del empuje de ${f.cuando}`, quien: correo,
      });
    }

    if (bitacora.length) {
      await fetch(`${SB_URL}/rest/v1/fudo_stock_push`, {
        method: "POST",
        headers: { "apikey": SB_KEY, "Authorization": `Bearer ${SB_KEY}`,
                   "Content-Type": "application/json", "Prefer": "return=minimal" },
        body: JSON.stringify(bitacora),
      }).catch(() => { /* que un fallo de bitácora no oculte el resultado */ });
    }

    return json({
      ...cabecera,
      ok: fallados.length === 0,
      devueltos: hechos.length,
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
