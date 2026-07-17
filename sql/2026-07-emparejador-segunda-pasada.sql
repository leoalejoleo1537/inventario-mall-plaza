-- ================================================================
-- SEGUNDA PASADA DEL EMPAREJADOR (sede plaza) — julio 2026
--
-- Mapeo hecho a mano: productos de Fudo cuyo nombre NO calza exacto
-- con el inventario pero son el mismo producto (typos, variantes,
-- versiones "Pedidos Ya"). Crea recetas 1-a-1 (aplica 'siempre').
--
-- Mismas reglas de seguridad de la primera pasada:
--   * no toca recetas que ya tienen insumos
--   * en duplicados de inventario prefiere el que NO es Congelador
--   * se puede correr varias veces sin duplicar
--
-- ⚠️ Al final hay un bloque "DUDOSAS": mapeos probables pero no
--    seguros. Revísalos; si alguno no corresponde, borra su línea
--    ANTES de correr, o borra la receta después desde la app.
-- ================================================================

drop table if exists _mapa;
create temporary table _mapa(fudo_nombre text, inv_nombre text);
insert into _mapa values
-- ---- bebidas embotelladas ----
('Bebida Coca cola light','Cocacola light'),
('Bebida Coca cola normal','Cocacola normal'),
('Bebida Coca cola zero','Cocacola zero'),
('Bebida Fanta normal','Fanta'),
('Bebida Fanta zero','Fanta zero'),
('Bebida ginger ale','Ginger ale'),
('Bebida Sprite normal','Sprite normal'),
('Bebida Sprite zero','Sprite zero'),
('Coca cola mini normal','Cocacola mini coca'),
('Sprite mini','Cocacola mini sprite'),
-- ---- pastelería / vitrina ----
('Alfajor artesanal Pedidos Ya','Alfajor artesanal'),
('Alfajor manjar con coco','Alfajor manjar coco'),
('Cannoli chips chocolate','Cannolis Chips Chocolate'),
('Cannoli de pistacho','Cannolis Pistacho'),
('Cheesecake frambuesa','T. Cheesecake Fram.'),
('Cinnamon Roll Pedidos Ya','Cinnamon rolls'),
('Rollo Canela Pedidosb Ya','Cinnamon rolls'),
('Dona relleno frambuesa','Donas frambuesa'),
('Donas de oreo','Donas oreo'),
('Donas rellena de nutella','Donas nutella'),
('Hojarasca Pedidos Ya','Trozo torta hojarasca'),
('Kuchen de manzana','T. Kutchen manzana'),
('Kuchen Manzana Pedidos Ya','T. Kutchen manzana'),
('Macarones variedades Pedidos Ya','Macarrons'),
('Macarons sabores','Macarrons'),
('Medialuna dulce membrillo','Medialuna membrillo'),
('Medialunas manjar','Medialuna manjar'),
('Medialunas tradicionales(sin relleno)','Medialuna tradicional'),
('Muffin arándanos','Muffin relleno arandano'),
('Muffin Vainilla chips chocolate','Muffin vainilla chips'),
('Muffin zanahoria Pedidos Ya','Muffin de zanahoria'),
('Pie de Limón Pedidos Ya','Pie de limón'),
('Pie de plátano manjar','Pie de plátano'),
('Pie de Plátano Pedidos Ya','Pie de plátano'),
('Tiramisu','Trozo de Tiramisu'),
('Tiramisu Pedidos Ya','Trozo de Tiramisu'),
('Torta amor','Trozo torta amor'),
('Torta amor Pedidos Ya','Trozo torta amor'),
('Torta de matilda','Trozo torta Matilda'),
('Torta de tres leches','Trozo torta tres leches'),
('Torta tres leches Pedidos Ya','Trozo torta tres leches'),
('Torta de zanahoria','Trozo torta de zanahoria'),
('Torta de zanahoria Pedidos Ya','Trozo torta de zanahoria'),
('Torta hojarasca manjar','Trozo torta hojarasca'),
('Volcan Chocolate solo','Volcan de chocolate'),
('Waffle solo','Waffles'),
('Waffle con helado','Waffles'),                 -- helado no contable: descuenta solo el waffle
('Waffle con helado y frutillas','Waffles'),     -- idem
('Llamita KIDS','Llamita kids'),
-- ---- sandwiches / salado ----
('Sandwich Apaltado Nuevo','Sandwich Apaltado'),
('Sandwich Azapa Nuevo','Sandwich Azapa'),
('Sandwich Champiñon Nuevo','Sandwich Champiñon'),
('Sandwich Croissant Jamon Queso Nuevo','Croissant jamon queso'),
('Crossaint jamon y queso Pedidos Ya','Croissant jamon queso'),
('Sandwich Jamon Serrano Nuevo','Sandwich Serrano'),
('Sandwich Jamón Serrano Pedidos Ya','Sandwich Serrano'),
('Selladitos del desierto','Selladitos jamon queso'),
('PIZZA 4 QUESOS','Pizza de 4 quesos'),
('Pizza 4 Quesos Pedidos Ya','Pizza de 4 quesos'),
('PIZZA CAHMPIÑON','Pizza Champiñon'),
('Pizza Hawaiana Pedidos Ya','Pizza Hawaiana'),
('PIZZA SERRANO','Pizza de serrano'),
('Pizza Serrano Pedidos Ya','Pizza de serrano'),
('PizzaPeperoni Pedidos Ya','Pizza peperoni'),
-- ---- otros ----
('Cafe en grano 250gr Pedidos Ya','Café grano 250 gr'),
('Pulpa de frambuesa','Pulpa frambuesa'),
('Pulpa de piña','Pulpa piña'),
('TE CHAI HOJA','Te chai hoja'),
('Te perla del norte','Té Hoja Perla Norte'),
('Té Sendero del Té','Té Sendero del Te'),
('Te Verdes Matices','Té Verde s Matices'),
-- ---- DUDOSAS: revisa y borra la línea si no corresponde ----
('Cheesecake maracuyá','T. Cheesecake Mara'),          -- ¿"Mara" = maracuyá?
('Media luna mantequilla','Medialuna tradicional'),    -- ¿es la tradicional?
('Sandwich Plateada Luco','Sandwich Mechada'),         -- ¿plateada = mechada?
('Sandwich plateada luco Pedidos Ya','Sandwich Mechada'),
('Sandwich capresse azapa Pedidos Ya','Sandwich Azapa'),
('Sandwich pollo apaltado Pedidos Ya','Sandwich Apaltado'),
('Té dilmah variedades','Té Dilmah'),
('Te Manzanilla Tetera','Té Manzanilla');

-- ---------- crear recetas ----------
with pares as (
  select distinct on (fp.fudo_product_id)
         fp.fudo_product_id, fp.nombre as fudo_nombre, p.id as producto_id
  from _mapa m
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
insert into public.recetas(sede, fudo_product_id, fudo_product_nombre)
select 'plaza', fudo_product_id, fudo_nombre from pares
on conflict (sede, fudo_product_id) do nothing;

-- ---------- crear sus insumos (1 unidad, siempre) ----------
with pares as (
  select distinct on (fp.fudo_product_id)
         fp.fudo_product_id, p.id as producto_id
  from _mapa m
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

-- ---------- comprobación ----------
select count(*) as recetas_en_plaza from public.recetas where sede='plaza';

select fp.nombre as sigue_sin_receta, fp.code
from public.fudo_productos fp
where fp.sede='plaza' and fp.activo=true
  and not exists (select 1 from public.recetas r
                  where r.sede='plaza' and r.fudo_product_id=fp.fudo_product_id)
order by fp.nombre;
