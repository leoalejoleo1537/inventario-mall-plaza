// ================================================================
// Edge Function: fudo-sync-ventas
//
// Lee las ventas CERRADAS de Fudo de UNA sede y las pasa por el motor
// public.fudo_procesar_item(). Respeta el modo de la sede:
//   * 'prueba' -> solo registra en la bitácora (no toca stock)
//   * 'real'   -> descuenta el stock
// Es idempotente: aunque relea una venta, nunca descuenta dos veces.
//
// Cómo se llama:  .../fudo-sync-ventas?sede=plaza
//
// Secrets (los mismos del sync de productos):
//   FUDO_PLAZA_APIKEY / FUDO_PLAZA_APISECRET   (y por cada sede)
// ================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/* Versión de ESTE archivo, que viaja en cada respuesta.
   Las Edge Functions se despliegan copiando y pegando en el panel de Supabase,
   así que el .ts del repo no prueba qué está corriendo en producción. Con esto
   se puede preguntar sin entrar al panel: si la respuesta trae una versión
   vieja, es que el pegado nunca se hizo. Subirla al cambiar el archivo. */
const VERSION = "2026-07-31";

const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";
const PAGE_SIZE = 500;
// Fudo filtra por createdAt = cuándo se ABRIÓ la mesa, no cuándo se cerró.
// Una mesa abierta a las 15:00 y cerrada a las 18:00 tiene createdAt de 3 h
// antes: con una ventana corta quedaba FUERA y no se descontaba nunca.
// 8 h cubre la jornada completa. Releer de más no cuesta: es idempotente.
const BUFFER_MIN = 480;
const PRIMERA_CORRIDA_H = 24;  // en la primera corrida, mira las últimas 24 h
const CONCURRENCIA = 20;       // ítems procesados en paralelo por tanda

const isoFudo = (d: Date) => d.toISOString().replace(/\.\d{3}Z$/, "Z");

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    // sede desde ?sede=plaza (dashboard) o desde el cuerpo JSON (botón de la app)
    const url = new URL(req.url);
    const qsSede = url.searchParams.get("sede");
    let bodySede: string | null = null, bodyOrigen: string | null = null;
    if (req.method === "POST") {
      const b = await req.json().catch(() => ({}));
      bodySede = b?.sede ?? null;
      bodyOrigen = b?.origen ?? null;
    }
    const sede = (qsSede ?? bodySede ?? "plaza").toLowerCase();
    // Quién disparó esta corrida. El cron manda ?origen=cron; el botón de la
    // app manda "boton". Sirve para saber si la sync automática sigue viva.
    const origen = (url.searchParams.get("origen") ?? bodyOrigen ?? "boton").toLowerCase();
    const KEY = `FUDO_${sede.toUpperCase()}_APIKEY`;
    const SECRET = `FUDO_${sede.toUpperCase()}_APISECRET`;
    const apiKey = Deno.env.get(KEY), apiSecret = Deno.env.get(SECRET);
    if (!apiKey || !apiSecret) return json({ error: `Faltan ${KEY} / ${SECRET} en Secrets.` }, 400);

    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    // 0) estado de la sede (modo + cursor)
    const { data: sync } = await supabase.from("fudo_sync").select("*").eq("sede", sede).maybeSingle();
    const modo = sync?.modo ?? "prueba";
    const cursor = sync?.ultima_venta_at ? new Date(sync.ultima_venta_at) : null;

    const ahora = new Date();
    const desde = cursor
      ? new Date(cursor.getTime() - BUFFER_MIN * 60000)
      : new Date(ahora.getTime() - PRIMERA_CORRIDA_H * 3600000);

    // 1) autenticación
    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) return json({ error: `Fudo rechazó la autenticación (${authRes.status}).`, detalle: await authRes.text() }, 502);
    const token = (await authRes.json())?.token;
    if (!token) return json({ error: "Fudo no devolvió token." }, 502);

    // 2) traer ventas CERRADAS de la ventana, con sus ítems y productos
    const tareas: Array<{ saleId: string; itemId: string; prodId: string | null; prodNom: string | null; cant: number; tipo: string; ventaAt: string | null }> = [];
    let ventasVistas = 0;
    let maxCreatedAt = cursor ? cursor.getTime() : 0;

    for (let page = 1; ; page++) {
      const params = new URLSearchParams();
      params.set("filter[saleState]", "in.(CLOSED)");
      // El tope superior se corre una hora hacia adelante: si el reloj de Fudo
      // va levemente adelantado respecto al nuestro, una venta recién cerrada
      // quedaba justo afuera del filtro y aparecía recién en la sync siguiente.
      const tope = new Date(ahora.getTime() + 60 * 60000);
      params.set("filter[createdAt]", `and(gte.${isoFudo(desde)},lte.${isoFudo(tope)})`);
      params.set("include", "items.product");
      params.set("sort", "createdAt");
      params.set("page[size]", String(PAGE_SIZE));
      params.set("page[number]", String(page));

      const res = await fetch(`${API_BASE}/sales?${params.toString()}`, {
        headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json" },
      });
      if (!res.ok) return json({ error: `Error al leer ventas de Fudo (${res.status}).`, detalle: await res.text() }, 502);
      const body = await res.json();
      const ventas = body.data ?? [];

      // mapas de los recursos incluidos (ítems y productos)
      const itemsById: Record<string, any> = {};
      const prodsById: Record<string, any> = {};
      for (const inc of (body.included ?? [])) {
        if (inc.type === "Item") itemsById[inc.id] = inc;
        else if (inc.type === "Product") prodsById[inc.id] = inc;
      }

      for (const venta of ventas) {
        ventasVistas++;
        const tipo = (venta.attributes?.saleType ?? "EAT-IN");
        const created = venta.attributes?.createdAt ? new Date(venta.attributes.createdAt).getTime() : 0;
        if (created > maxCreatedAt) maxCreatedAt = created;

        for (const ref of (venta.relationships?.items?.data ?? [])) {
          const item = itemsById[ref.id];
          if (!item) continue;
          if (item.attributes?.canceled === true) continue;   // ítem anulado: no descuenta
          const cant = Number(item.attributes?.quantity ?? 0);
          if (!cant) continue;
          const prodRef = item.relationships?.product?.data;
          const prod = prodRef ? prodsById[prodRef.id] : null;
          tareas.push({
            saleId: String(venta.id),
            itemId: String(item.id),
            prodId: prodRef ? String(prodRef.id) : null,
            prodNom: prod?.attributes?.name ?? null,
            cant,
            tipo,
            ventaAt: venta.attributes?.createdAt ?? null,   // cuándo se vendió DE VERDAD
          });
        }
      }

      if (ventas.length < PAGE_SIZE) break; // última página
    }

    // 3) pasar cada ítem por el motor (en tandas para no saturar)
    let procesados = 0, movimientos = 0, errores = 0;
    for (let i = 0; i < tareas.length; i += CONCURRENCIA) {
      const tanda = tareas.slice(i, i + CONCURRENCIA);
      const res = await Promise.all(tanda.map((t) =>
        supabase.rpc("fudo_procesar_item", {
          p_sede: sede,
          p_fudo_sale_id: t.saleId,
          p_fudo_item_id: t.itemId,
          p_fudo_product_id: t.prodId,
          p_fudo_product_nombre: t.prodNom,
          p_cantidad: t.cant,
          p_sale_type: t.tipo,
          p_venta_at: t.ventaAt,
        })
      ));
      for (const r of res) {
        if (r.error) errores++;
        else { procesados++; movimientos += Array.isArray(r.data) ? r.data.length : 0; }
      }
    }

    // 4) avanzar el cursor (solo hacia adelante) y DEJAR DICHO CÓMO FUE
    //
    // Lo segundo importa tanto como lo primero: hasta el 2026-07-31 el
    // resultado de cada corrida solo existía en esta respuesta, o sea que
    // únicamente lo veía quien había apretado ⟳. Con el cron encendido no
    // hay nadie apretando nada, así que un motor caído no tendría testigo.
    // Ahora queda escrito en la base y la pantalla lo puede leer sola.
    const intentos = procesados + errores;
    const resultado = errores === 0
      ? "ok"
      : (movimientos === 0 || errores >= intentos * 0.10) ? "falla" : "parcial";

    const fila: Record<string, unknown> = {
      sede,
      updated_at: new Date().toISOString(),
      ultima_corrida_at: new Date().toISOString(),
      ultima_corrida_por: origen,
      ultimo_resultado: resultado,
      ultimos_items: intentos,
      ultimos_errores: errores,
      ultimos_movimientos: movimientos,
    };
    if (maxCreatedAt > (cursor ? cursor.getTime() : 0)) {
      fila.ultima_venta_at = new Date(maxCreatedAt).toISOString();
    }
    // Que un fallo al anotar no tape el resultado: el descuento ya ocurrió.
    const { error: errAnotar } = await supabase.from("fudo_sync")
      .upsert(fila, { onConflict: "sede" });

    return json({
      ok: true, sede, modo,
      version: VERSION,
      ventana: { desde: isoFudo(desde), hasta: isoFudo(ahora) },
      ventas_leidas: ventasVistas,
      items_procesados: procesados,
      movimientos_generados: movimientos,
      errores,
      resultado,
      ...(errAnotar ? { aviso: "No se pudo dejar constancia de esta corrida: " + errAnotar.message } : {}),
    });
  } catch (e) {
    return json({ error: "Error inesperado.", detalle: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), { status, headers: { "Content-Type": "application/json", ...CORS } });
}
