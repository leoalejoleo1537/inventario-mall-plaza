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

const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";
const PAGE_SIZE = 500;
const BUFFER_MIN = 120;        // relee las últimas 2 h por si una venta cerró tarde (idempotente)
const PRIMERA_CORRIDA_H = 24;  // en la primera corrida, mira las últimas 24 h
const CONCURRENCIA = 20;       // ítems procesados en paralelo por tanda

const isoFudo = (d: Date) => d.toISOString().replace(/\.\d{3}Z$/, "Z");

Deno.serve(async (req) => {
  try {
    const sede = (new URL(req.url).searchParams.get("sede") ?? "plaza").toLowerCase();
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
    const tareas: Array<{ saleId: string; itemId: string; prodId: string | null; prodNom: string | null; cant: number; tipo: string }> = [];
    let ventasVistas = 0;
    let maxCreatedAt = cursor ? cursor.getTime() : 0;

    for (let page = 1; ; page++) {
      const params = new URLSearchParams();
      params.set("filter[saleState]", "in.(CLOSED)");
      params.set("filter[createdAt]", `and(gte.${isoFudo(desde)},lte.${isoFudo(ahora)})`);
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
        })
      ));
      for (const r of res) {
        if (r.error) errores++;
        else { procesados++; movimientos += Array.isArray(r.data) ? r.data.length : 0; }
      }
    }

    // 4) avanzar el cursor (solo hacia adelante)
    if (maxCreatedAt > (cursor ? cursor.getTime() : 0)) {
      await supabase.from("fudo_sync").upsert(
        { sede, ultima_venta_at: new Date(maxCreatedAt).toISOString(), updated_at: new Date().toISOString() },
        { onConflict: "sede" },
      );
    }

    return json({
      ok: true, sede, modo,
      ventana: { desde: isoFudo(desde), hasta: isoFudo(ahora) },
      ventas_leidas: ventasVistas,
      items_procesados: procesados,
      movimientos_generados: movimientos,
      errores,
    });
  } catch (e) {
    return json({ error: "Error inesperado.", detalle: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), { status, headers: { "Content-Type": "application/json" } });
}
