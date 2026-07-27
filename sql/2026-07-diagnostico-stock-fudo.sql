-- ================================================================
-- DIAGNÓSTICO — ¿a cuántos productos de Fudo se les puede empujar stock?
--
-- Fudo SÍ guarda campos de stock por producto (stock, stockControl,
-- minStock, ignoreAvailability). Esto mide, con los datos que ya están
-- en la base, cuál es el alcance REAL de un botón "actualizar en Fudo":
-- cuántos productos lo tienen activado, cuántos de esos tienen receta,
-- y por lo tanto a cuántos podríamos calcularles un número.
--
-- TODO ESTE ARCHIVO ES DE SOLO LECTURA. No modifica nada, ni acá ni en
-- Fudo. Son cinco consultas; se pueden correr todas de una vez.
--
-- Antes de correrlo conviene apretar ⟳ en la app, para que el espejo
-- fudo_productos esté al día (la sync de catálogo no es en tiempo real).
-- ================================================================


-- ================================================================
-- 1) ¿Cuántos productos de Fudo tienen el control de stock ENCENDIDO?
--
-- stockControl es un interruptor por producto dentro de Fudo. Si está
-- apagado, Fudo no lleva stock de ese producto y mandarle un número
-- probablemente no haga nada visible. Esta es la primera frontera real
-- del alcance.
-- ================================================================
select
  coalesce((raw->>'stockControl')::boolean, false) as control_de_stock,
  count(*)                                          as productos
from public.fudo_productos
where sede = 'plaza'
group by 1
order by productos desc;


-- ================================================================
-- 2) Los que YA tienen el control encendido, con su stock actual en Fudo
--
-- Sirve para dos cosas: ver si los números de Fudo están vivos o
-- quedaron congelados hace meses, y reconocer qué tipo de productos
-- son (¿los combos? ¿los sándwiches? ¿otra cosa?).
-- ================================================================
select
  nombre,
  (raw->>'stock')::numeric              as stock_en_fudo,
  (raw->>'minStock')::numeric           as min_en_fudo,
  (raw->>'ignoreAvailability')::boolean as vende_igual_sin_stock,
  activo,
  synced_at
from public.fudo_productos
where sede = 'plaza'
  and coalesce((raw->>'stockControl')::boolean, false)
order by nombre;


-- ================================================================
-- 3) EL NÚMERO QUE IMPORTA — cuántos podríamos actualizar de verdad
--
-- Un producto se puede actualizar solo si se cumplen las tres cosas:
--   a) existe en Fudo
--   b) tiene receta en nuestro sistema (si no, no hay con qué calcular)
--   c) Fudo le lleva el stock (stockControl encendido)
--
-- Si la última fila sale muy baja, el botón sirve para menos productos
-- de los que parece — y conviene saberlo ANTES de construirlo.
-- ================================================================
with fp as (
  select fudo_product_id, nombre,
         coalesce((raw->>'stockControl')::boolean, false) as control
  from public.fudo_productos
  where sede = 'plaza'
),
rec as (
  select distinct r.fudo_product_id
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  where r.sede = 'plaza' and r.activo
)
select 'productos en Fudo'                        as grupo, count(*) as n from fp
union all
select 'con control de stock encendido',          count(*) from fp where control
union all
select 'con receta en nuestro sistema',           count(*) from fp
  where fudo_product_id in (select fudo_product_id from rec)
union all
select 'AMBAS COSAS (se podrían actualizar)',     count(*) from fp
  where control and fudo_product_id in (select fudo_product_id from rec);


-- ================================================================
-- 4) Cuánto se podría vender de cada uno, con el stock de hoy
--
-- Es la fórmula espejo del motor de descuento: en vez de restar
-- insumos por cada venta, calcula cuántas ventas más aguanta el stock
-- que queda. Para cada receta, el mínimo entre sus insumos manda —
-- si el juguete alcanza para 5 combos, da igual que el muffin alcance
-- para 30: solo se pueden armar 5.
--
-- Se ignoran los insumos con cantidad 0 en la receta (no limitan) y
-- se usa 'siempre'/'llevar'/'servir' completo, sin distinguir, porque
-- para stockear se mira el caso general.
--
-- ESTA CONSULTA NO ESCRIBE NADA. Es exactamente el número que el
-- futuro botón propondría mandar a Fudo.
-- ================================================================
with ins as (
  select r.fudo_product_id,
         fp.nombre                                as producto_fudo,
         p.producto                               as insumo,
         p.stock_actual,
         ri.cantidad                              as gasta_por_unidad,
         floor(coalesce(p.stock_actual,0) / nullif(ri.cantidad,0)) as alcanza_para
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos p     on p.id = ri.producto_id
  left join public.fudo_productos fp
         on fp.sede = r.sede and fp.fudo_product_id = r.fudo_product_id
  where r.sede = 'plaza' and r.activo and coalesce(ri.cantidad,0) > 0
)
select
  producto_fudo,
  min(alcanza_para)                                     as se_puede_vender,
  -- qué insumo es el que manda (el que primero se acaba)
  (array_agg(insumo order by alcanza_para))[1]          as insumo_que_limita,
  count(*)                                              as insumos_en_la_receta,
  string_agg(insumo || ' (' || coalesce(stock_actual,0) || ')', ' · '
             order by alcanza_para)                     as detalle
from ins
group by producto_fudo
order by se_puede_vender, producto_fudo;


-- ================================================================
-- 5) Los combos, que son el caso que motivó todo esto
--
-- "Llamita KIDS" en Fudo es UN producto; en el inventario son tres
-- cosas distintas. Esto muestra las recetas de más de un insumo, que
-- son justamente las que nadie puede calcular de cabeza.
-- ================================================================
with ins as (
  select r.fudo_product_id, fp.nombre as producto_fudo, p.producto as insumo,
         coalesce(p.stock_actual,0) as stock, ri.cantidad,
         floor(coalesce(p.stock_actual,0) / nullif(ri.cantidad,0)) as alcanza_para
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos p     on p.id = ri.producto_id
  left join public.fudo_productos fp
         on fp.sede = r.sede and fp.fudo_product_id = r.fudo_product_id
  where r.sede = 'plaza' and r.activo and coalesce(ri.cantidad,0) > 0
)
select producto_fudo,
       min(alcanza_para) as se_puede_armar,
       string_agg(insumo || ': ' || stock || ' en stock, gasta ' || cantidad
                  || ' → alcanza para ' || alcanza_para, E'\n' order by alcanza_para) as desglose
from ins
group by producto_fudo
having count(*) > 1
order by se_puede_armar;
