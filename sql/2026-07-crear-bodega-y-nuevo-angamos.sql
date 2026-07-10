-- ================================================================
-- Reorganización de sedes (julio 2026)
--
-- Situación: lo que hoy se usa como "Parque Angamos" en realidad se
-- ocupó como BODEGA. Hay que:
--   1) Renombrar la sede "angamos" actual  ->  "bodega"  (conserva su data)
--   2) Crear un inventario "angamos" NUEVO copiando el catálogo de
--      Mall Plaza (producto, rubro, mínimos y máximos). El stock actual
--      arranca en 0 para que el equipo lo cuente.
--
-- IMPORTANTE: correr los pasos EN ESTE ORDEN.
-- ================================================================

-- ---------- PASO 1: renombrar angamos -> bodega ----------
update public.productos       set sede = 'bodega' where sede = 'angamos';
update public.historial       set sede = 'bodega' where sede = 'angamos';
update public.fudo_pendientes set sede = 'bodega' where sede = 'angamos';

-- ---------- PASO 2: crear el nuevo "angamos" copiando Mall Plaza ----------
-- Copia el catálogo completo de plaza. Stock actual = 0.
insert into public.productos
  (producto, rubro, stock_actual, stock_min, stock_max, activo, origen, notas, sede, perecedero)
select
  producto, rubro, 0, stock_min, stock_max, activo, origen, notas, 'angamos', perecedero
from public.productos
where sede = 'plaza';

-- Comprobación (opcional): cuántos productos quedó en cada sede
-- select sede, count(*) from public.productos group by sede order by sede;
