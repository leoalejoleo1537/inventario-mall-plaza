-- ================================================================
-- PRODUCTOS NUEVOS EN EL INVENTARIO (sede plaza) — 2026-07-25
--
-- Se venden en Fudo pero no existían en el inventario, así que no
-- había a qué apuntar la receta. Lista revisada por Jhon: se dejaron
-- fuera los que ya no se venden.
--
-- El script hace DOS cosas:
--   1) crea los productos en el inventario (stock 0, para que las
--      jefas lo ajusten en el próximo conteo)
--   2) les crea la receta 1-a-1, salvo los que no se cuantifican
--
-- ⚠️ ANTES DE CORRER: apretar "↻ Productos de Fudo" en la vista
--    Recetas de la app. Si `fudo_productos` está desactualizado, los
--    productos se crean igual pero sus recetas no.
--
-- Seguro de re-correr: no duplica nada.
-- ================================================================

-- ---------------- 1) Crear los productos ----------------
-- Vitrina de tortas
insert into public.productos (producto, rubro, stock_actual, stock_min, stock_max, activo, origen, notas, sede)
select v.producto, 'Vitrina de tortas', 0, null, null, 'SÍ', 'FUDO-2026-07-25', '', 'plaza'
from (values
  ('Donas chocolate'),
  ('Dona pistacho Dubai'),
  ('Galletas New York'),
  ('Galleton vainilla chips'),
  ('Muffin de chocolate'),
  ('Cinnamon roll vegano')
) as v(producto)
where not exists (
  select 1 from public.productos p
  where p.sede='plaza'
    and translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
      = translate(lower(regexp_replace(trim(v.producto),'\s+',' ','g')),'áéíóúñü','aeiounu'));

-- Vitrina de bebidas
insert into public.productos (producto, rubro, stock_actual, stock_min, stock_max, activo, origen, notas, sede)
select v.producto, 'Vitrina de bebidas', 0, null, null, 'SÍ', 'FUDO-2026-07-25', '', 'plaza'
from (values
  ('Agua Bosqua con gas'),
  ('Agua Bosqua sin gas'),
  ('Cocacola mini zero')
) as v(producto)
where not exists (
  select 1 from public.productos p
  where p.sede='plaza'
    and translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
      = translate(lower(regexp_replace(trim(v.producto),'\s+',' ','g')),'áéíóúñü','aeiounu'));

-- Mueble de mezclas — se cuenta por frasco, así que NO va a descontar.
-- Se crea solo para que aparezca en el conteo físico.
insert into public.productos (producto, rubro, stock_actual, stock_min, stock_max, activo, origen, notas, sede)
select 'Miel', 'Mueble de mezclas', 0, null, null, 'SÍ', 'FUDO-2026-07-25', 'No descuenta: se cuenta por frasco', 'plaza'
where not exists (
  select 1 from public.productos p
  where p.sede='plaza' and lower(trim(p.producto))='miel');


-- ---------------- 2) Crear sus recetas ----------------
-- Solo los que se cuentan por unidad. 'Miel' queda fuera a propósito.
drop table if exists _mapa4;
create temporary table _mapa4(fudo_nombre text, inv_nombre text);
insert into _mapa4 values
('Donas de chocolate',    'Donas chocolate'),
('Dona Pistacho Dubai',   'Dona pistacho Dubai'),
('Galletas New York',     'Galletas New York'),
('Galleton vainilla chips','Galleton vainilla chips'),
('Muffin de chocolate',   'Muffin de chocolate'),
('Cinnamon Roll Vegano',  'Cinnamon roll vegano'),
('Agua Bosqua con gas',   'Agua Bosqua con gas'),
('Agua Bosqua sin gas',   'Agua Bosqua sin gas'),
('Coca cola Zero mini',   'Cocacola mini zero');

-- ¿Alguno no está en Fudo? (si sale algo: correr la sync de productos)
select distinct m.fudo_nombre as fudo_no_encontrado
from _mapa4 m
where not exists (
  select 1 from public.fudo_productos fp
  where fp.sede='plaza' and fp.activo=true
    and translate(lower(regexp_replace(trim(fp.nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
      = translate(lower(regexp_replace(trim(m.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu'))
order by 1;

-- recetas
with pares as (
  select distinct fp.fudo_product_id, fp.nombre as fudo_nombre
  from _mapa4 m
  join public.fudo_productos fp
    on fp.sede='plaza' and fp.activo=true
   and translate(lower(regexp_replace(trim(fp.nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
     = translate(lower(regexp_replace(trim(m.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
)
insert into public.recetas(sede, fudo_product_id, fudo_product_nombre)
select 'plaza', fudo_product_id, fudo_nombre from pares
on conflict (sede, fudo_product_id) do nothing;

-- insumos (1 unidad, siempre)
with pares as (
  select distinct on (fp.fudo_product_id)
         fp.fudo_product_id, p.id as producto_id
  from _mapa4 m
  join public.fudo_productos fp
    on fp.sede='plaza' and fp.activo=true
   and translate(lower(regexp_replace(trim(fp.nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
     = translate(lower(regexp_replace(trim(m.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
  join public.productos p
    on p.sede='plaza' and p.activo='SÍ'
   and translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
     = translate(lower(regexp_replace(trim(m.inv_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
  order by fp.fudo_product_id, (p.rubro='Congelador') asc, p.id
)
insert into public.receta_items(receta_id, producto_id, cantidad, aplica)
select r.id, pa.producto_id, 1, 'siempre'
from pares pa
join public.recetas r on r.sede='plaza' and r.fudo_product_id = pa.fudo_product_id
where not exists (select 1 from public.receta_items ri where ri.receta_id = r.id)
on conflict (receta_id, producto_id) do nothing;


-- ---------------- 3) Comprobación ----------------
-- Los 10 productos nuevos, con su stock:
select producto, rubro, stock_actual
from public.productos
where sede='plaza' and origen='FUDO-2026-07-25'
order by rubro, producto;

-- ¿Cuáles quedaron con receta? (deberían ser 9; 'Miel' no lleva)
select r.fudo_product_nombre, p.producto as descuenta
from public.recetas r
join public.receta_items ri on ri.receta_id=r.id
join public.productos p on p.id=ri.producto_id
where r.sede='plaza' and p.origen='FUDO-2026-07-25'
order by 1;
