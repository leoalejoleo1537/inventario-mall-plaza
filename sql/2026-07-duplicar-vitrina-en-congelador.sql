-- ================================================================
-- Duplica en la sección CONGELADOR (stock 0) los productos de
-- vitrina que también se guardan en el freezer (julio 2026).
-- Aplica a plaza y angamos. La copia hereda mínimo, máximo y
-- perecedero del producto original; el original no se toca.
-- Se puede correr varias veces sin crear copias repetidas.
-- ================================================================
insert into public.productos(producto, rubro, stock_actual, stock_min, stock_max, activo, origen, notas, sede, perecedero)
select p.producto, 'Congelador', 0, p.stock_min, p.stock_max, 'SÍ', 'APP', '', p.sede, p.perecedero
from public.productos p
where p.sede in ('plaza','angamos') and p.activo='SÍ' and p.rubro <> 'Congelador'
  and translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
    'volcan de chocolate','donas frambuesa','donas nutella','donas oreo',
    'muffin relleno arandano','muffin vainilla chips','muffin amapola','muffin de zanahoria','mini muffin',
    'macarrons','brownie','waffles','galleton red velvet','galleton pasas','galleton chips')
  and not exists (
    select 1 from public.productos c
    where c.sede=p.sede and c.rubro='Congelador'
      and translate(lower(regexp_replace(trim(c.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
        = translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
  );

-- Comprobación: qué quedó duplicado en Congelador
select sede, producto, stock_actual
from public.productos
where rubro='Congelador' and activo='SÍ'
  and translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
    'volcan de chocolate','donas frambuesa','donas nutella','donas oreo',
    'muffin relleno arandano','muffin vainilla chips','muffin amapola','muffin de zanahoria','mini muffin',
    'macarrons','brownie','waffles','galleton red velvet','galleton pasas','galleton chips')
order by sede, producto;
