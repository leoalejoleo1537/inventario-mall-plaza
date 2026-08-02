-- ================================================================
-- TERCERA PASADA DEL EMPAREJADOR (sede plaza) — 2026-07-25 · v2
--
-- v2: el mapa se reconstruyó contra los nombres REALES de la base.
-- La v1 apuntaba a un inventario que ya no existe: tras la
-- reestructuración, los productos se desdoblaron en
-- "X Congelador" / "X Vitrina" y los nombres viejos quedaron
-- en activo='NO'.
--
-- ⚠️ CORRER ANTES: 2026-07-limpieza-y-fix-recetas.sql
--
-- ---------------------------------------------------------------
-- DOS REGLAS QUE MANDAN
--
-- 1) Si el inventario cuenta el ENVASE y la venta consume una
--    FRACCIÓN, ese insumo NO se descuenta.
--    (el milkshake lleva ~4 galletas, pero se cuentan paquetes de 8-9)
--
-- 2) La venta sale de la VITRINA, no del congelador. Por eso todas
--    las recetas apuntan a la versión "Vitrina" cuando existe.
--    El paso congelador -> vitrina es reposición interna.
--
-- Fuera por regla 1: helados, palta, mantequilla, chantilly,
--   salsas, syrups, marshmallow, galletas Oreo, miel.
-- Fuera por decisión: café, té, jugos, leches, zumos, pre/post
--   entreno. Las pulpas están en inventario pero sin descuento.
-- ---------------------------------------------------------------
--
-- Seguridad: no toca recetas que ya tienen insumos; se puede correr
-- varias veces sin duplicar; si un nombre no calza ABORTA y dice
-- exactamente cuáles faltan.
-- ================================================================

drop table if exists _mapa3;
create temporary table _mapa3(fudo_nombre text, inv_nombre text, cantidad numeric default 1);

insert into _mapa3(fudo_nombre, inv_nombre) values

-- ================================================================
-- BLOQUE 1 — Pizzas peperoni
-- (En Fudo el producto sí se llama 'PizzaPeperoni Pedidos Ya',
--  todo junto. El typo estaba en la lista .md, no en el SQL viejo.
--  Lo que faltaba de verdad era la versión de local.)
-- ================================================================
('PIZZA PEPPERONI','Pizza pepperoni'),
('PizzaPeperoni Pedidos Ya','Pizza pepperoni'),
('Pizza Capresse','Pizza Capresse'),

-- ================================================================
-- BLOQUE 2 — Variantes y typos (productos contables por unidad)
-- ================================================================
('Brownie-solo','Brownie Vitrina'),
('Galleton Chocolate Chips','Galleton Chips'),
('Galleton de avena con pasas','Galleton Avena con Pasas vitrina'),
('Galletones Red Velvet','Galleton Red Velvet vitrina'),
('Muffin caramelo','Muffin caramelo Vitrina'),

-- ================================================================
-- BLOQUE 2b — Productos que ya existían en el inventario y no
-- estaban mapeados (los "nuevos" de la lista de Jhon)
-- ================================================================
('Donas de chocolate','Donas chocolate'),
('Galletas New York','Galletas New York'),
('Cinnamon Roll Vegano','Cinnamon roll vegano'),
('Coca cola Zero mini','Cocacola mini zero'),
('Dona Pistacho Dubai','Dona Pistacho Dubai Vitrina'),
('Galleton vainilla chips','Galleton Vainilla Chips vitrina'),
('Muffin de chocolate','Muffin de chocolate Vitrina'),
('Agua Bosqua con gas','Agua con gas premium Bosque'),
('Agua Bosqua sin gas','Agua sin gas premium Bosque'),

-- ================================================================
-- BLOQUE 3 — Combos sandwich + bebida (2 insumos cada uno)
-- Nombres reales: las cocacolas y fantas llevan prefijo "Unidad",
-- los sprites no. El selladito es 'Sandwich Selladito'.
-- ================================================================
-- Apaltado
('Apaltado + Cocacola normal','Sandwich Apaltado'),
('Apaltado + Cocacola normal','Unidad coca cola normal'),
('Apaltado + Fanta normal','Sandwich Apaltado'),
('Apaltado + Fanta normal','Unidad fanta'),
('Apaltado + Fanta zero','Sandwich Apaltado'),
('Apaltado + Fanta zero','Unidad fanta zero'),
('Apaltado + Sprite normal','Sandwich Apaltado'),
('Apaltado + Sprite normal','Sprite normal'),
('Apaltado + Sprite zero','Sandwich Apaltado'),
('Apaltado + Sprite zero','Sprite zero'),
-- Azapa
('Azapa + Cocacola normal','Sandwich Azapa'),
('Azapa + Cocacola normal','Unidad coca cola normal'),
('Azapa + Cocacola zero','Sandwich Azapa'),
('Azapa + Cocacola zero','Unidad coca cola zero'),
('Azapa + Fanta normal','Sandwich Azapa'),
('Azapa + Fanta normal','Unidad fanta'),
('Azapa + Fanta zero','Sandwich Azapa'),
('Azapa + Fanta zero','Unidad fanta zero'),
('Azapa + Sprite normal','Sandwich Azapa'),
('Azapa + Sprite normal','Sprite normal'),
('Azapa + Sprite zero','Sandwich Azapa'),
('Azapa + Sprite zero','Sprite zero'),
-- Champiñón
('Champiñon + Cocacola normal','Sandwich Champiñón'),
('Champiñon + Cocacola normal','Unidad coca cola normal'),
('Champiñon + Cocacola zero','Sandwich Champiñón'),
('Champiñon + Cocacola zero','Unidad coca cola zero'),
('Champiñon + Fanta normal','Sandwich Champiñón'),
('Champiñon + Fanta normal','Unidad fanta'),
('Champiñon + Fanta zero','Sandwich Champiñón'),
('Champiñon + Fanta zero','Unidad fanta zero'),
('Champiñon + Sprite normal','Sandwich Champiñón'),
('Champiñon + Sprite normal','Sprite normal'),
('Champiñon + Sprite zero','Sandwich Champiñón'),
('Champiñon + Sprite zero','Sprite zero'),
-- Croissant jamón queso
('Croissant JQ + Cocacola normal','Croissant Jamon Queso'),
('Croissant JQ + Cocacola normal','Unidad coca cola normal'),
('Croissant JQ + Cocacola zero','Croissant Jamon Queso'),
('Croissant JQ + Cocacola zero','Unidad coca cola zero'),
('Croissant JQ + Fanta normal','Croissant Jamon Queso'),
('Croissant JQ + Fanta normal','Unidad fanta'),
('Croissant JQ + Fanta zero','Croissant Jamon Queso'),
('Croissant JQ + Fanta zero','Unidad fanta zero'),
('Croissant JQ + Sprite normal','Croissant Jamon Queso'),
('Croissant JQ + Sprite normal','Sprite normal'),
('Croissant JQ + Sprite zero','Croissant Jamon Queso'),
('Croissant JQ + Sprite zero','Sprite zero'),
-- Jamón serrano
('Jamon Serrano + Cocacola normal','Sandwich Serrano'),
('Jamon Serrano + Cocacola normal','Unidad coca cola normal'),
('Jamon Serrano + Cocacola zero','Sandwich Serrano'),
('Jamon Serrano + Cocacola zero','Unidad coca cola zero'),
('Jamon Serrano + Fanta normal','Sandwich Serrano'),
('Jamon Serrano + Fanta normal','Unidad fanta'),
('Jamon Serrano + Fanta zero','Sandwich Serrano'),
('Jamon Serrano + Fanta zero','Unidad fanta zero'),
('Jamon Serrano + Sprite normal','Sandwich Serrano'),
('Jamon Serrano + Sprite normal','Sprite normal'),
('Jamon Serrano + Sprite zero','Sandwich Serrano'),
('Jamon Serrano + Sprite zero','Sprite zero'),
-- Mechada / plateada
('Mechada + Cocacola normal','Sandwich Mechada'),
('Mechada + Cocacola normal','Unidad coca cola normal'),
('Mechada + Cocacola zero','Sandwich Mechada'),
('Mechada + Cocacola zero','Unidad coca cola zero'),
('Mechada + Fanta normal','Sandwich Mechada'),
('Mechada + Fanta normal','Unidad fanta'),
('Mechada + Fanta zero','Sandwich Mechada'),
('Mechada + Fanta zero','Unidad fanta zero'),
('Mechada + Sprite normal','Sandwich Mechada'),
('Mechada + Sprite normal','Sprite normal'),
('Mechada + Sprite zero','Sandwich Mechada'),
('Mechada + Sprite zero','Sprite zero'),
-- Selladito
('Selladito + Sprite zero','Sandwich Selladito'),
('Selladito + Sprite zero','Sprite zero'),

-- Combos "+ Café": el café no se cuantifica, descuentan solo el sólido
('Champiñon + Cafe','Sandwich Champiñón'),
('Croissant JQ + Cafe','Croissant Jamon Queso'),
('Jamon Serrano + Cafe','Sandwich Serrano'),
('Mechada + Cafe','Sandwich Mechada'),
('JAMON QUESO+CAFE','Croissant Jamon Queso'),

-- ================================================================
-- BLOQUE 4 — Compuestos: solo la parte contable
-- ================================================================
('Brownie con helado','Brownie Vitrina'),            -- helado fuera
('Waffle Milshake','Waffles vitrina'),               -- helado fuera
('Milksahe Donut Oreo','Donas oreo vitrina'),        -- helado fuera
('Milkshake Donut Pink','Donas frambuesa Vitrina'),  -- helado fuera
('Tostadas solas','Pan masa madre'),
('tostadas masa madre mantequilla','Pan masa madre'),-- mantequilla fuera
('Tostadas Palta','Pan masa madre');                 -- palta fuera

-- NO incluidos a propósito:
--   'Milkshake Oreo' -> galletas por paquete + helado por balde
--   'Agua con limón' -> falta confirmar si sale de botella o de jarra
--   'Copa de helado' -> 3 bolas, no se cuantifica


-- ================================================================
-- FRENO DE SEGURIDAD
-- Si algún nombre no existe, aborta TODO y los lista por nombre.
-- (Un combo creado a medias no se autocompleta al re-correr: la
--  regla "no pisar recetas con insumos" lo daría por hecho.)
-- ================================================================
do $$
declare
  v_inv  text;
  v_fudo text;
begin
  select string_agg(distinct m.inv_nombre, ' | ' order by m.inv_nombre) into v_inv
  from _mapa3 m
  where not exists (
    select 1 from public.productos p
    where p.sede='plaza' and p.activo='SÍ'
      and translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
        = translate(lower(regexp_replace(trim(m.inv_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu'));

  select string_agg(distinct m.fudo_nombre, ' | ' order by m.fudo_nombre) into v_fudo
  from _mapa3 m
  where not exists (
    select 1 from public.fudo_productos fp
    where fp.sede='plaza' and fp.activo=true
      and translate(lower(regexp_replace(trim(fp.nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
        = translate(lower(regexp_replace(trim(m.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu'));

  if v_inv is not null or v_fudo is not null then
    raise exception E'ABORTADO. No se creó ninguna receta.\n\nSIN MATCH EN INVENTARIO: %\n\nSIN MATCH EN FUDO: %',
      coalesce(v_inv,'(ninguno)'), coalesce(v_fudo,'(ninguno)');
  end if;
end $$;


-- ================================================================
-- CREAR RECETAS
-- ================================================================
with pares as (
  select distinct fp.fudo_product_id, fp.nombre as fudo_nombre
  from _mapa3 m
  join public.fudo_productos fp
    on fp.sede='plaza' and fp.activo=true
   and translate(lower(regexp_replace(trim(fp.nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
     = translate(lower(regexp_replace(trim(m.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
)
insert into public.recetas(sede, fudo_product_id, fudo_product_nombre)
select 'plaza', fudo_product_id, fudo_nombre from pares
on conflict (sede, fudo_product_id) do nothing;


-- ================================================================
-- CREAR SUS INSUMOS
-- El distinct on incluye el nombre de inventario para que los
-- combos conserven sus 2 insumos.
-- ================================================================
with pares as (
  select distinct on (fp.fudo_product_id, m.inv_nombre)
         fp.fudo_product_id, p.id as producto_id, m.cantidad
  from _mapa3 m
  join public.fudo_productos fp
    on fp.sede='plaza' and fp.activo=true
   and translate(lower(regexp_replace(trim(fp.nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
     = translate(lower(regexp_replace(trim(m.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
  join public.productos p
    on p.sede='plaza' and p.activo='SÍ'
   and translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
     = translate(lower(regexp_replace(trim(m.inv_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
  order by fp.fudo_product_id, m.inv_nombre, (p.rubro='Congelador') asc, p.id
)
insert into public.receta_items(receta_id, producto_id, cantidad, aplica)
select r.id, pa.producto_id, coalesce(pa.cantidad,1), 'siempre'
from pares pa
join public.recetas r on r.sede='plaza' and r.fudo_product_id = pa.fudo_product_id
-- No pisar recetas que ya tienen insumos. El SELECT ve el estado
-- previo al INSERT, así que los 2 insumos de un combo entran juntos.
where not exists (select 1 from public.receta_items ri where ri.receta_id = r.id)
on conflict (receta_id, producto_id) do nothing;


-- ================================================================
-- COMPROBACIÓN — correr una consulta a la vez
-- ================================================================

-- a) ¿Alguna receta quedó con menos insumos de los esperados?
--    DEBE SALIR VACÍO.
select r.fudo_product_nombre, esperado.n_esperados, count(ri.id) as n_insertados
from (select fudo_nombre, count(*) as n_esperados from _mapa3 group by fudo_nombre) esperado
join public.fudo_productos fp
  on fp.sede='plaza' and fp.activo=true
 and translate(lower(regexp_replace(trim(fp.nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
   = translate(lower(regexp_replace(trim(esperado.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
join public.recetas r on r.sede='plaza' and r.fudo_product_id = fp.fudo_product_id
left join public.receta_items ri on ri.receta_id = r.id
group by r.fudo_product_nombre, esperado.n_esperados
having count(ri.id) <> esperado.n_esperados
order by 1;

-- b) Resumen de cobertura
select
  (select count(*) from public.recetas where sede='plaza') as recetas,
  (select count(*) from public.fudo_productos
    where sede='plaza' and activo=true)                    as productos_fudo_activos;

-- c) ⚠️ REVISAR: recetas que descuentan del CONGELADOR en vez de la
--    vitrina. La venta sale de la vitrina; si descuenta del
--    congelador, el stock de vitrina nunca baja. Estas hay que
--    mirarlas una a una (algunas son correctas: el pan y las pizzas
--    solo viven en congelador).
select r.fudo_product_nombre as producto_fudo, p.producto as descuenta_de
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
join public.productos    p  on p.id = ri.producto_id
where r.sede='plaza' and p.rubro='Congelador'
order by 1;
