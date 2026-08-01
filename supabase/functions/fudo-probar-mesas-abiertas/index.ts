// ================================================================
// Edge Function: fudo-probar-mesas-abiertas   —   PRUEBA AISLADA
//
// ⚠️ SOLO LECTURA. Hace únicamente peticiones GET a Fudo. No escribe en
// Fudo, no escribe en Supabase, no descuenta nada, no toca el stock.
//
// PARA QUÉ: hoy el inventario descuenta cuando la mesa se CIERRA. Eso hace
// que al contar de noche, con mesas todavía abiertas, la app muestre más de
// lo que hay en el estante — y si alguien "corrige" ese número, el descuento
// que viene en camino lo baja de nuevo y queda el doble descontado.
//
// La pregunta que esta función viene a contestar es una sola:
//   ¿Fudo nos deja ver lo que hay en las mesas ABIERTAS, con sus productos?
//
// Si la respuesta es sí, se puede mostrar "hay 2 en mesa" en la app y hacer
// que el conteo manual cuadre solo. Si es no, hay que ir por otro camino.
//
// ESTA FUNCIÓN ES TEMPORAL. Cuando terminemos de decidir, se borra.
//
// Cómo se llama:  POST { sede: "plaza" }   ó   ?sede=plaza
// ================================================================

const VERSION = "2026-07-31";
const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";
const HORAS = 24;                 // ventana que se mira hacia atrás

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

const isoFudo = (d: Date) => d.toISOString().replace(/\.\d{3}Z$/, "Z");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const url = new URL(req.url);
    let bodySede: string | null = null;
    if (req.method === "POST") bodySede = (await req.json().catch(() => ({})))?.sede ?? null;
    const sede = (url.searchParams.get("sede") ?? bodySede ?? "plaza").toLowerCase();

    const apiKey = Deno.env.get(`FUDO_${sede.toUpperCase()}_APIKEY`);
    const apiSecret = Deno.env.get(`FUDO_${sede.toUpperCase()}_APISECRET`);
    if (!apiKey || !apiSecret) return json({ error: `Faltan las credenciales de Fudo para "${sede}".` }, 400);

    // ---------- autenticación ----------
    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) return json({ error: `Fudo rechazó la autenticación (${authRes.status}).` }, 502);
    const token = (await authRes.json())?.token;
    if (!token) return json({ error: "Fudo no devolvió token." }, 502);

    const pedir = async (params: URLSearchParams) => {
      const r = await fetch(`${API_BASE}/sales?${params.toString()}`, {
        headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json" },
      });
      const txt = await r.text();
      let body: any = null;
      try { body = JSON.parse(txt); } catch { /* no-JSON */ }
      return { ok: r.ok, status: r.status, body, txt };
    };

    const desde = new Date(Date.now() - HORAS * 3600000);
    const hasta = new Date(Date.now() + 3600000);
    const ventana = `and(gte.${isoFudo(desde)},lte.${isoFudo(hasta)})`;

    // ================================================================
    // PRUEBA 1 — ¿qué estados de venta existen de verdad?
    //
    // Se pide SIN filtrar por estado. Lo que devuelva nos dice cómo se
    // llama en Fudo una mesa abierta, en vez de adivinar el nombre.
    // ================================================================
    const p1 = new URLSearchParams();
    p1.set("filter[createdAt]", ventana);
    p1.set("include", "items.product");
    p1.set("sort", "-createdAt");
    p1.set("page[size]", "200");
    p1.set("page[number]", "1");
    const r1 = await pedir(p1);
    if (!r1.ok) {
      return json({
        version: VERSION, sede,
        veredicto: "❌ Fudo no aceptó la consulta sin filtro de estado.",
        detalle: `HTTP ${r1.status}: ${r1.txt.slice(0, 300)}`,
        que_significa: "No se pudo ni empezar. Puede ser un permiso de la cuenta de Fudo.",
      }, 200);
    }

    const ventas = r1.body?.data ?? [];
    const estados: Record<string, number> = {};
    for (const v of ventas) {
      const e = String(v.attributes?.saleState ?? "(sin estado)");
      estados[e] = (estados[e] ?? 0) + 1;
    }
    const otros = Object.keys(estados).filter((e) => e !== "CLOSED" && e !== "(sin estado)");

    // ---------- ¿las abiertas traen sus productos? ----------
    const itemsById: Record<string, any> = {};
    const prodsById: Record<string, any> = {};
    for (const inc of (r1.body?.included ?? [])) {
      if (inc.type === "Item") itemsById[inc.id] = inc;
      else if (inc.type === "Product") prodsById[inc.id] = inc;
    }

    const abiertas = ventas.filter((v: any) => String(v.attributes?.saleState) !== "CLOSED");
    const ejemplos: unknown[] = [];
    let conProductos = 0, itemsTotales = 0;

    for (const v of abiertas) {
      const refs = v.relationships?.items?.data ?? [];
      const productos: unknown[] = [];
      for (const ref of refs) {
        const it = itemsById[ref.id];
        if (!it) continue;
        const cancelado = it.attributes?.canceled === true;
        const cant = Number(it.attributes?.quantity ?? 0);
        const pRef = it.relationships?.product?.data;
        const prod = pRef ? prodsById[pRef.id] : null;
        if (!cancelado && cant) itemsTotales += cant;
        productos.push({
          producto: prod?.attributes?.name ?? "(no vino el nombre)",
          cantidad: cant,
          ...(cancelado ? { anulado: true } : {}),
        });
      }
      if (productos.length) conProductos++;
      if (ejemplos.length < 5) {
        ejemplos.push({
          estado: v.attributes?.saleState,
          abierta_desde: v.attributes?.createdAt,
          tipo: v.attributes?.saleType,
          productos,
        });
      }
    }

    // ================================================================
    // PRUEBA 2 — ¿se puede FILTRAR por mesas abiertas?
    //
    // Importante para el futuro: si se puede filtrar, la consulta trae
    // solo lo abierto y es liviana. Si no, habría que traer todo y
    // separar acá, que funciona pero pesa más.
    // ================================================================
    let filtro: Record<string, unknown> = { probado: false };
    if (otros.length) {
      const p2 = new URLSearchParams();
      p2.set("filter[saleState]", `in.(${otros.join(",")})`);
      p2.set("filter[createdAt]", ventana);
      p2.set("include", "items.product");
      p2.set("page[size]", "50");
      const r2 = await pedir(p2);
      filtro = {
        probado: true,
        consulta: `filter[saleState]=in.(${otros.join(",")})`,
        funciona: r2.ok,
        devolvio: r2.ok ? (r2.body?.data?.length ?? 0) : null,
        ...(r2.ok ? {} : { error: `HTTP ${r2.status}: ${r2.txt.slice(0, 200)}` }),
      };
    }

    // ================================================================
    // VEREDICTO
    // ================================================================
    const sePuede = otros.length > 0 && conProductos > 0;
    const soloEstados = otros.length > 0 && conProductos === 0;

    return json({
      version: VERSION,
      sede,
      ventana_mirada: `últimas ${HORAS} horas`,
      ventas_vistas: ventas.length,

      veredicto: sePuede
        ? "✅ SÍ SE PUEDE. Fudo devuelve las mesas abiertas con sus productos."
        : soloEstados
          ? "🟡 A MEDIAS. Se ven las mesas abiertas, pero no vinieron sus productos."
          : ventas.length === 0
            ? "🔍 SIN DATOS. No hubo ventas en las últimas 24 h — correr esto en horario de local."
            : "❌ NO SE VE NINGUNA MESA ABIERTA en esta ventana. Probar de nuevo con mesas abiertas de verdad.",

      estados_que_devolvio_fudo: estados,
      como_se_llama_una_mesa_abierta: otros.length ? otros : "(no apareció ninguna ahora)",
      mesas_abiertas_ahora: abiertas.length,
      mesas_abiertas_con_productos: conProductos,
      unidades_en_mesa: itemsTotales,
      se_puede_filtrar_por_estado: filtro,
      ejemplos_de_lo_que_hay_en_mesa: ejemplos,

      que_significa: sePuede
        ? "Se puede mostrar en la app cuánto hay 'en mesa' y hacer que el conteo manual cuadre solo, sin descontar por mesas abiertas (así una mesa anulada no rompe nada)."
        : soloEstados
          ? "Sabemos CUÁNTAS mesas hay abiertas pero no qué tienen. Alcanza para avisar 'hay 3 mesas abiertas, conviene contar después', que ya evita el doble descuento."
          : "Hay que repetir la prueba con mesas abiertas de verdad, en horario de local, antes de descartar nada.",

      recordatorio: "Esta función es SOLO LECTURA y es temporal: cuando decidamos, se borra.",
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
