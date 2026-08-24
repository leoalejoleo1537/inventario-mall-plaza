--  DÓNDE VA:  Supabase -> SQL Editor -> New query
--  ES:        3 bloques, uno por uno. Ninguno lleva $$
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. No escribe, no borra, no toca stock.
--  QUÉ VER:   el bloque 1 te da el tamaño del problema por fecha; el
--             bloque 2 te dice, producto por producto de bodega, cuánto
--             habría que bajarle y a cuánto quedaría; el bloque 3 son los
--             que no se pueden corregir solos porque no tienen enlace.
-- ================================================================

-- ================================================================
-- POR QUÉ PASÓ ESTO, en una frase: `repartos.origen` dice "Bodega" por
-- defecto en TODA fila nueva, la haya armado quien la haya armado. Ese
-- campo no prueba nada. Lo único que de verdad decide si bodega baja es
-- si la LÍNEA (`reparto_items`) trae `producto_bodega_id` — y eso solo
-- lo pone la pantalla Bodega -> Enviar. Cuando Adriana armó el reparto
-- desde adentro de Plaza o Angamos (la pantalla vieja, "Reparto"), la fila
-- también dice origen "Bodega" pero la línea nace SIN ese número. El local
-- sumó de verdad; bodega nunca se enteró.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL TAMAÑO DEL PROBLEMA, por semana
-- ================================================================
select
  date_trunc('week', ri.resuelto_at)::date as semana,
  r.sede,
  count(*)                                  as lineas_sin_bajar,
  sum(ri.cantidad_recibida)                 as unidades_sin_bajar,
  count(*) filter (where pe.id is null)     as sin_enlace_no_se_puede_arreglar_solo
from public.reparto_items ri
join public.repartos r on r.id = ri.reparto_id
left join public.producto_enlace pe
  on pe.sede = r.sede and pe.producto_sede_id = ri.producto_id
where r.sede in ('plaza','angamos')
  and ri.estado = 'recibido'
  and coalesce(ri.cantidad_recibida,0) > 0
  and ri.producto_bodega_id is null
  and ri.producto_origen_id is null
group by 1,2
order by 1 desc, 2;


-- ================================================================
-- BLOQUE 2 — CUÁNTO HABRÍA QUE BAJARLE A CADA PRODUCTO DE BODEGA
--            (solo los que SÍ tienen enlace, o sea se pueden arreglar solos)
-- ================================================================
select
  b.id                              as bodega_id,
  b.producto                        as producto_de_bodega,
  b.stock_actual                    as bodega_tiene_hoy,
  sum(ri.cantidad_recibida)         as se_le_deberia_bajar,
  greatest(0, b.stock_actual - sum(ri.cantidad_recibida)) as quedaria_en,
  case when b.stock_actual < sum(ri.cantidad_recibida)
       then '⚠ bodega no alcanza — quedaría en 0, no en negativo, y sobra '
            || (sum(ri.cantidad_recibida) - b.stock_actual)::text
       else 'alcanza' end           as aviso,
  min(ri.resuelto_at)::date         as desde,
  max(ri.resuelto_at)::date         as hasta,
  count(*)                          as cuantas_lineas
from public.reparto_items ri
join public.repartos r on r.id = ri.reparto_id
join public.producto_enlace pe
  on pe.sede = r.sede and pe.producto_sede_id = ri.producto_id
join public.productos b on b.id = pe.producto_bodega_id
where r.sede in ('plaza','angamos')
  and ri.estado = 'recibido'
  and coalesce(ri.cantidad_recibida,0) > 0
  and ri.producto_bodega_id is null
  and ri.producto_origen_id is null
group by b.id, b.producto, b.stock_actual
order by se_le_deberia_bajar desc;


-- ================================================================
-- BLOQUE 3 — LOS QUE NO SE PUEDEN ARREGLAR SOLOS (sin enlace hoy)
--            Si estos productos SÍ vienen de bodega, primero hay que
--            enlazarlos en Bodega -> Enlaces; después se vuelven a mirar.
-- ================================================================
select
  r.sede,
  p.producto            as producto_del_local,
  p.rubro,
  ri.cantidad_recibida,
  ri.resuelto_at::date  as fecha,
  ri.resuelto_por        as quien_confirmo
from public.reparto_items ri
join public.repartos r on r.id = ri.reparto_id
join public.productos p on p.id = ri.producto_id
left join public.producto_enlace pe
  on pe.sede = r.sede and pe.producto_sede_id = ri.producto_id
where r.sede in ('plaza','angamos')
  and ri.estado = 'recibido'
  and coalesce(ri.cantidad_recibida,0) > 0
  and ri.producto_bodega_id is null
  and ri.producto_origen_id is null
  and pe.id is null
order by r.sede, p.producto, ri.resuelto_at desc;
