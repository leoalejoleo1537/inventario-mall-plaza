-- ================================================================
-- REVISIÓN PREVIA — qué pasaría si empujáramos el stock a Fudo HOY
--
-- Con el recetario nuevo, este archivo responde la única pregunta que
-- importa antes de conectar nada: ¿el número que calculamos es el
-- correcto, o hay recetas que dejarían a Fudo sin vender algo que sí
-- está en la vitrina?
--
-- TODO ES DE SOLO LECTURA. No modifica nada, ni acá ni en Fudo.
--
-- Correr después de apretar ⟳ en la app, para que el espejo de
-- productos de Fudo esté al día.
-- ================================================================


-- ================================================================
-- 1) EL SEMÁFORO — el resumen en cuatro números
-- ================================================================
with calc as (
  select r.fudo_product_id,
         min(floor(coalesce(p.stock_actual,0) / nullif(ri.cantidad,0))) as disponible
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos p     on p.id = ri.producto_id
  where r.sede='plaza' and r.activo and coalesce(ri.cantidad,0) > 0
  group by r.fudo_product_id
),
fp as (
  select fudo_product_id, nombre, activo,
         coalesce((raw->>'stockControl')::boolean,false) as control,
         (raw->>'stock')::numeric                        as stock_fudo
  from public.fudo_productos where sede='plaza'
)
select 'productos con receta'                        as grupo, count(*) as n from calc
union all
select 'listos para empujar (activos + control on)', count(*)
  from calc c join fp on fp.fudo_product_id=c.fudo_product_id
  where fp.activo and fp.control
union all
select '⚠ quedarían en 0 teniendo stock en Fudo',    count(*)
  from calc c join fp on fp.fudo_product_id=c.fudo_product_id
  where fp.activo and fp.control and c.disponible = 0 and coalesce(fp.stock_fudo,0) > 0
union all
select 'sin receta (seguirán a mano en Fudo)',       count(*)
  from fp where activo and control
    and fudo_product_id not in (select fudo_product_id from calc);


-- ================================================================
-- 2) LA LISTA QUE HAY QUE MIRAR ANTES DE APRETAR NADA
--
-- Productos que Fudo dejaría de vender. Cada fila de acá es una venta
-- potencialmente perdida si la receta está mal. Revisar UNA POR UNA:
-- si el insumo que limita no tiene nada que ver con el producto, la
-- receta está cruzada y hay que arreglarla ANTES de empujar.
-- ================================================================
with ins as (
  select r.fudo_product_id, p.producto as insumo, coalesce(p.stock_actual,0) as stock,
         ri.cantidad, floor(coalesce(p.stock_actual,0)/nullif(ri.cantidad,0)) as alcanza
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos p     on p.id = ri.producto_id
  where r.sede='plaza' and r.activo and coalesce(ri.cantidad,0) > 0
)
select fp.nombre                                   as producto_fudo,
       (fp.raw->>'stock')::numeric                 as tiene_en_fudo,
       min(i.alcanza)                              as pasaria_a,
       (array_agg(i.insumo order by i.alcanza))[1] as insumo_que_limita,
       string_agg(i.insumo||' ('||i.stock||')', ' · ' order by i.alcanza) as receta_completa
from ins i
join public.fudo_productos fp
  on fp.sede='plaza' and fp.fudo_product_id = i.fudo_product_id
where fp.activo and coalesce((fp.raw->>'stockControl')::boolean,false)
group by fp.nombre, fp.raw
having min(i.alcanza) = 0 and coalesce((fp.raw->>'stock')::numeric,0) > 0
order by (fp.raw->>'stock')::numeric desc;


-- ================================================================
-- 3) RECETAS SOSPECHOSAS — el nombre no se parece a ningún insumo
--
-- Atrapa los cruces tipo "Cheesecake maracuyá descuenta T. Cheesecake
-- Mora". Compara la primera palabra larga del producto de Fudo contra
-- los nombres de sus insumos. NO es prueba de error — es una lista
-- para mirar con criterio. Un combo legítimo puede salir acá.
-- ================================================================
with base as (
  select r.id as receta_id, fp.nombre as producto_fudo,
         lower(translate(fp.nombre,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as n_fudo,
         string_agg(lower(translate(p.producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')), ' ') as n_insumos,
         string_agg(p.producto, ' · ') as insumos
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos p     on p.id = ri.producto_id
  join public.fudo_productos fp
    on fp.sede = r.sede and fp.fudo_product_id = r.fudo_product_id
  where r.sede='plaza' and r.activo and fp.activo and coalesce(ri.cantidad,0) > 0
  group by r.id, fp.nombre
),
palabra as (
  select *, (regexp_match(n_fudo, '([a-z]{5,})'))[1] as clave from base
)
select producto_fudo, clave as palabra_buscada, insumos
from palabra
where clave is not null and position(clave in n_insumos) = 0
order by producto_fudo;


-- ================================================================
-- 4) COMBOS que descuentan un solo insumo
--
-- El nombre dice "X + Y" pero la receta gasta una sola cosa. A veces
-- es correcto (la bebida se controla y el sándwich no), a veces falta
-- un insumo. Mirar y decidir — no corregir a ciegas.
-- ================================================================
select fp.nombre as producto_fudo,
       count(ri.id) as insumos_en_la_receta,
       string_agg(p.producto, ' · ') as receta
from public.recetas r
join public.fudo_productos fp
  on fp.sede = r.sede and fp.fudo_product_id = r.fudo_product_id
left join public.receta_items ri on ri.receta_id = r.id and coalesce(ri.cantidad,0) > 0
left join public.productos p     on p.id = ri.producto_id
where r.sede='plaza' and r.activo and fp.activo
  and fp.nombre ~* '(\+| y |combo|promo|kit|dúo|duo|menu|menú|desayuno|brunch|kids)'
group by fp.nombre
having count(ri.id) <= 1
order by fp.nombre;
