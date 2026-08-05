-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  cierra la tanda de recetas de Angamos. El 1 y el 2
--             ESCRIBEN, el 3 solo mira.
--  QUÉ VER:   el bloque 3 deja el número final y explica de dónde sale.
-- ================================================================
--
-- LAS TRES COSAS QUE FALTABAN:
--   1. Las 2 recetas que no se crearon (Torta Matilda Pedidos Ya y
--      Media Luna Manjar). Los productos SÍ existen en Fudo — el
--      problema era mío: comparé el nombre letra por letra y en Fudo
--      tiene un espacio de más que no se ve en pantalla. Acá se compara
--      sin espacios sobrantes ni tildes, y calza.
--   2. Sacar la receta del Muffin Amapola, que ya no se vende.
--   3. Entender por qué quedaron 83 y no 79.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — CREAR LAS 2 QUE FALTARON
--
-- Son 4 sentencias. Copiar TODO el bloque y apretar Run una vez.
-- ================================================================
drop table if exists public.angamos_mapa_recetas;
create table public.angamos_mapa_recetas(
  clave_fudo text primary key,
  nombre_inv text not null
);

insert into public.angamos_mapa_recetas values
 ('torta matilda pedidos ya','Trozo torta Matilda'),
 ('media luna manjar','Medialuna manjar');

insert into public.recetas (sede, fudo_product_id, fudo_product_nombre, activo)
select 'angamos', f.fudo_product_id, f.nombre, true
from public.fudo_productos f
join public.angamos_mapa_recetas m
  on m.clave_fudo = lower(translate(regexp_replace(trim(f.nombre),'\s+',' ','g'),
                          'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun'))
where f.sede='angamos' and f.activo
on conflict (sede, fudo_product_id) do nothing;

insert into public.receta_items (receta_id, producto_id, cantidad, aplica)
select r.id, p.id, 1, 'siempre'
from public.recetas r
join public.fudo_productos f
  on f.sede='angamos' and f.fudo_product_id = r.fudo_product_id
join public.angamos_mapa_recetas m
  on m.clave_fudo = lower(translate(regexp_replace(trim(f.nombre),'\s+',' ','g'),
                          'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun'))
join public.productos p
  on p.sede='angamos' and p.activo='SÍ' and p.producto = m.nombre_inv
where r.sede='angamos' and r.activo
on conflict (receta_id, producto_id) do nothing;

drop table if exists public.angamos_mapa_recetas;


-- ================================================================
-- BLOQUE 2 — SACAR LA RECETA DEL MUFFIN AMAPOLA
--
-- Jhon confirmó el 2026-08-05: ya no se vende en Angamos y borró el
-- producto del inventario. Si la receta se queda, apunta a algo que ya
-- no existe — es exactamente el problema que Mall Plaza arrastra con
-- su Muffin Amapola (§6.0), y no tiene sentido exportarlo.
--
-- QUÉ VER: devuelve la receta borrada. Si no devuelve nada, es que ya
-- no estaba, y también está bien.
-- ================================================================
delete from public.receta_items
 where receta_id in (
   select id from public.recetas
    where sede='angamos' and fudo_product_nombre ilike '%amapola%');

delete from public.recetas
 where sede='angamos' and fudo_product_nombre ilike '%amapola%'
returning fudo_product_nombre as receta_borrada;


-- ================================================================
-- BLOQUE 3 — EL NÚMERO FINAL, Y DE DÓNDE SALE
--
-- Son 2 consultas.
--
-- La primera es el recuento: "sin_insumo" tiene que dar 0.
--
-- La segunda explica el sobrante. Si devuelve filas, son productos que
-- en el Fudo de Angamos están cargados DOS VECES con el mismo nombre.
-- Eso no es un error nuestro: cada uno es un producto distinto para
-- Fudo, los dos se venden, y los dos tienen que descontar lo mismo.
-- Si devuelve "No rows returned", el sobrante es otra cosa y hay que
-- avisar.
-- ================================================================
select count(*)                                        as recetas_en_angamos,
       count(*) filter (where ri.receta_id is not null) as con_insumo,
       count(*) filter (where ri.receta_id is null)     as sin_insumo,
       case when count(*) filter (where ri.receta_id is null) = 0
            then '✅ todas descuentan algo'
            else '🔴 hay recetas que apuntan al vacío — avisar' end as veredicto
from public.recetas r
left join (select distinct receta_id from public.receta_items) ri on ri.receta_id = r.id
where r.sede='angamos' and r.activo;

select f.nombre                        as nombre_repetido_en_fudo,
       count(*)                        as cuantas_veces,
       string_agg(f.fudo_product_id, '  ·  ' order by f.fudo_product_id) as ids_en_fudo
from public.fudo_productos f
join public.recetas r
  on r.sede='angamos' and r.activo and r.fudo_product_id = f.fudo_product_id
where f.sede='angamos' and f.activo
group by f.nombre
having count(*) > 1
order by f.nombre;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-recetas-cierre.sql', 'Jhon', 'lo corrió Jhon',
        'Cerró la tanda: creó las 2 recetas que fallaron por un espacio en el nombre y sacó la del Muffin Amapola')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
