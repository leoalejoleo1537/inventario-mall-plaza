-- ================================================================
-- DIAGNÓSTICO — el resumen de sándwiches no cuadra con la realidad
--
-- SOLO LECTURA: no crea, no borra, no modifica nada. Se puede correr
-- las veces que quieras.
--
-- Por qué: en la pantalla del 26/07 aparecían productos con una fecha que
-- dice "1 vence 28/07" pero con stock 0 (Champiñón, Serrano), y una fecha
-- con cantidad 0 (Selladito). El stock de un producto con fechas TIENE que
-- ser la suma de sus fechas — si no cuadra, el resumen que se le manda a
-- Adriana miente. Esto muestra dónde está el descuadre.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Manda los 3 resultados.
-- ================================================================

-- ---------- BLOQUE 1: stock del producto vs. suma de sus fechas ----------
-- La columna "descuadre" es la que importa: debe ser 0 en todas las filas.
select p.id,
       p.producto,
       p.stock_actual                                   as stock_guardado,
       coalesce(sum(l.cantidad), 0)                     as suma_de_fechas,
       p.stock_actual - coalesce(sum(l.cantidad), 0)    as descuadre,
       count(l.id)                                      as cuantas_fechas,
       count(l.id) filter (where l.cantidad <= 0)       as fechas_en_cero
from public.productos p
left join public.producto_lotes l on l.producto_id = p.id
where p.sede = 'plaza'
  and p.activo = 'SÍ'
  and p.rubro = 'Sándwiches'
group by p.id, p.producto, p.stock_actual
order by abs(p.stock_actual - coalesce(sum(l.cantidad), 0)) desc, p.producto;

-- ---------- BLOQUE 2: el detalle de cada fecha ----------
select p.producto, l.id as lote_id, l.cantidad, l.vencimiento, l.updated_at
from public.producto_lotes l
join public.productos p on p.id = l.producto_id
where p.sede = 'plaza' and p.activo = 'SÍ' and p.rubro = 'Sándwiches'
order by p.producto, l.vencimiento;

-- ---------- BLOQUE 3: ¿las fechas viajan en vivo entre dispositivos? ----------
-- Si esto sale VACÍO, los cambios de fecha NO se avisan a los otros
-- teléfonos: cada uno sigue mostrando lo que cargó al abrir la app, hasta
-- que se refresque a mano. Explicaría ver números viejos en pantalla.
select tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
  and tablename in ('productos','producto_lotes');
