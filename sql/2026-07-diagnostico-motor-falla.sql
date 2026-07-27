-- ================================================================
-- DIAGNÓSTICO — la sync lee 9 ventas y genera 0 descuentos
--
-- La Edge Function se traga el error de cada venta (las cuenta como
-- "errores" pero responde ok), así que el mensaje real nunca llega a la
-- pantalla. Estos bloques llaman al motor a mano para VERLO.
--
-- Los bloques 2 y 3 usan begin/rollback: ejecutan el motor de verdad y
-- después deshacen todo. No queda ninguna fila ni se mueve ningún stock.
--
-- Cómo correrlo: Supabase -> SQL Editor. Correr UN BLOQUE A LA VEZ y
-- mandar lo que salga (el resultado o el mensaje de error en rojo).
-- ================================================================


-- ================================================================
-- BLOQUE 1 — el estado, todo en una sola fila
-- ================================================================
select
  (select modo            from public.fudo_sync where sede='plaza')            as modo,
  (select ultima_venta_at from public.fudo_sync where sede='plaza')            as cursor_hasta,
  (select updated_at      from public.fudo_sync where sede='plaza')            as sync_corrio,
  (select max(created_at) from public.fudo_movimientos where sede='plaza')     as ultimo_movimiento,
  now()                                                                        as ahora,
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='fudo_procesar_item')               as versiones_del_motor;


-- ================================================================
-- BLOQUE 2 — ¿falla el simple registro de la venta?
-- Usa un producto de Fudo que no existe, así que solo escribe la
-- bitácora y NO toca stock. Si esto revienta, el problema está en el
-- INSERT a fudo_movimientos.
-- ================================================================
begin;
select * from public.fudo_procesar_item(
  'plaza', 'DIAG-VENTA-1', 'DIAG-ITEM-1', '__no_existe__',
  'PRUEBA DE DIAGNOSTICO', 1, 'EAT-IN', now()
);
rollback;


-- ================================================================
-- BLOQUE 3 — ¿falla el descuento?
-- Toma la primera receta activa de la sede y la procesa de verdad.
-- Si el BLOQUE 2 funcionó y este falla, el problema está en el
-- descuento (descontar_lotes / descontar_con_reposicion).
-- ================================================================
begin;
select * from public.fudo_procesar_item(
  'plaza', 'DIAG-VENTA-2', 'DIAG-ITEM-2',
  (select r.fudo_product_id from public.recetas r
    join public.receta_items ri on ri.receta_id = r.id
   where r.sede='plaza' and r.activo limit 1),
  'PRUEBA CON RECETA', 1, 'EAT-IN', now()
);
rollback;


-- ================================================================
-- BLOQUE 4 — las firmas del motor instaladas
-- Debe salir UNA sola. Si salen dos, hay una versión vieja conviviendo.
-- ================================================================
select p.oid::regprocedure as firma,
       pg_get_function_identity_arguments(p.oid) as argumentos
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='fudo_procesar_item';
