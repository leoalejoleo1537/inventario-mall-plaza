-- ================================================================
-- DIAGNÓSTICO DE NOMBRES — 2026-07-25 (v2)
--
-- SOLO LECTURA. No crea, no borra, no modifica nada.
--
-- Devuelve UNA SOLA TABLA, porque el SQL Editor de Supabase solo
-- muestra el resultado del último SELECT cuando se corren varios.
--
-- Columnas:
--   donde     -> INVENTARIO o FUDO (dónde no se encontró el nombre)
--   buscado   -> el nombre que usa el mapa de la tercera pasada
--   parecidos -> lo que sí existe en la base, con [rubro/activo]
--
-- Con esa tercera columna se corrigen los nombres del mapa.
-- ================================================================

drop table if exists _chk;
create temporary table _chk(inv_nombre text);
insert into _chk values
('Pizza peperoni'),
('Brownie'),
('Galleton Chips'),
('Galleton de avena con pasas'),
('Galleton Red Velvet'),
('Sandwich Apaltado'),
('Sandwich Azapa'),
('Sandwich Champiñon'),
('Sandwich Serrano'),
('Sandwich Mechada'),
('Croissant jamon queso'),
('Selladitos jamon queso'),
('Cocacola normal'),
('Cocacola zero'),
('Fanta'),
('Fanta zero'),
('Sprite normal'),
('Sprite zero'),
('Donas oreo'),
('Donas frambuesa'),
('Waffles'),
('Pan masa madre');

drop table if exists _chkf;
create temporary table _chkf(fudo_nombre text);
insert into _chkf values
('Pizza Peperoni Pedidos Ya'),
('PIZZA PEPPERONI'),
('Brownie-solo'),
('Galleton Chocolate Chips'),
('Galleton de avena con pasas'),
('Galletones Red Velvet'),
('Apaltado + Cocacola normal'),
('Apaltado + Fanta normal'),
('Apaltado + Fanta zero'),
('Apaltado + Sprite normal'),
('Apaltado + Sprite zero'),
('Azapa + Cocacola normal'),
('Azapa + Cocacola zero'),
('Azapa + Fanta normal'),
('Azapa + Fanta zero'),
('Azapa + Sprite normal'),
('Azapa + Sprite zero'),
('Champiñon + Cocacola normal'),
('Champiñon + Cocacola zero'),
('Champiñon + Fanta normal'),
('Champiñon + Fanta zero'),
('Champiñon + Sprite normal'),
('Champiñon + Sprite zero'),
('Croissant JQ + Cocacola normal'),
('Croissant JQ + Cocacola zero'),
('Croissant JQ + Fanta normal'),
('Croissant JQ + Fanta zero'),
('Croissant JQ + Sprite normal'),
('Croissant JQ + Sprite zero'),
('Jamon Serrano + Cocacola normal'),
('Jamon Serrano + Cocacola zero'),
('Jamon Serrano + Fanta normal'),
('Jamon Serrano + Fanta zero'),
('Jamon Serrano + Sprite normal'),
('Jamon Serrano + Sprite zero'),
('Mechada + Cocacola normal'),
('Mechada + Cocacola zero'),
('Mechada + Fanta normal'),
('Mechada + Fanta zero'),
('Mechada + Sprite normal'),
('Mechada + Sprite zero'),
('Selladito + Sprite zero'),
('Champiñon + Cafe'),
('Croissant JQ + Cafe'),
('Jamon Serrano + Cafe'),
('Mechada + Cafe'),
('JAMON QUESO+CAFE'),
('Brownie con helado'),
('Waffle Milshake'),
('Milksahe Donut Oreo'),
('Milkshake Donut Pink'),
('Tostadas solas'),
('tostadas masa madre mantequilla'),
('Tostadas Palta');


-- ================================================================
-- LA CONSULTA (una sola tabla de resultados)
-- ================================================================
select 'INVENTARIO' as donde,
       c.inv_nombre as buscado,
       coalesce((
         select string_agg(p.producto || ' [' || coalesce(p.rubro,'sin rubro')
                           || ' / activo=' || coalesce(p.activo,'null') || ']', '   ·   ' order by p.producto)
         from public.productos p
         where p.sede='plaza'
           and translate(lower(p.producto),'áéíóúñü','aeiounu')
               like '%' || translate(lower(split_part(trim(c.inv_nombre),' ',1)),'áéíóúñü','aeiounu') || '%'
       ), '(nada parecido)') as parecidos_en_la_base
from _chk c
where not exists (
  select 1 from public.productos p
  where p.sede='plaza' and p.activo='SÍ'
    and translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
      = translate(lower(regexp_replace(trim(c.inv_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu'))

union all

select 'FUDO',
       c.fudo_nombre,
       coalesce((
         select string_agg(fp.nombre || ' [activo=' || fp.activo || ']', '   ·   ' order by fp.nombre)
         from public.fudo_productos fp
         where fp.sede='plaza'
           and translate(lower(fp.nombre),'áéíóúñü','aeiounu')
               like '%' || translate(lower(split_part(trim(c.fudo_nombre),' ',1)),'áéíóúñü','aeiounu') || '%'
       ), '(nada parecido)')
from _chkf c
where not exists (
  select 1 from public.fudo_productos fp
  where fp.sede='plaza' and fp.activo=true
    and translate(lower(regexp_replace(trim(fp.nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
      = translate(lower(regexp_replace(trim(c.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu'))

order by 1, 2;
