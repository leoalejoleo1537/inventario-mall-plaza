-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO, en orden, y mirar cada
--             resultado antes de seguir al siguiente.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  arregla las recetas de Angamos, que están descontando del
--             stock de la BODEGA en vez del de Angamos.
--             El bloque 1 NO toca nada: es la vista previa.
--  QUÉ VER:   el bloque 4 tiene que dar CERO. Ahí está terminado.
-- ================================================================
--
-- ⚠️ LO PRIMERO, PORQUE IMPORTA: las recetas de Angamos NO están borradas.
-- Están las 171, activas, con sus 215 renglones. Lo que pasa es que apuntan
-- a productos de la bodega, y la pantalla de Angamos solo sabe mostrar
-- productos de Angamos — por eso se ven vacías.
--
-- LA IMAGEN: es como una receta de cocina que dice "saca la harina del
-- estante 3", pero el estante 3 es el de la bodega central, no el del local.
-- La receta está escrita y completa; lo que está mal es a qué estante manda.
--
-- LO QUE SÍ ES UN PROBLEMA DE VERDAD: entre el 5 y el 8 de agosto, 228
-- ventas de Angamos bajaron 254 unidades del stock de la BODEGA. Esto lo
-- corta.
--
-- ESTE ARCHIVO NO BORRA NINGUNA RECETA. Las repunta.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — VISTA PREVIA. No cambia nada.
--
-- Una fila por renglón de receta que hoy apunta a bodega, y qué haría.
--
-- La búsqueda del gemelo va en escalera, y por eso encuentra más que el
-- informe anterior (que comparaba letra por letra):
--   1. mismo nombre en Angamos, ignorando tildes y mayúsculas
--      -> por eso "Azucar blanca" ahora sí encuentra "Azúcar Blanca"
--   2. el mismo nombre + " Vitrina"      <- lo que decidió Jhon
--   3. el mismo nombre + " Congelador"   <- solo si no hay vitrina
--   4. no existe -> hay que crearlo (bloque 2)
--
-- QUÉ VER: la columna "que_haria". Y sobre todo las que digan CREAR, que
-- son productos nuevos en el inventario de Angamos.
-- ================================================================
with norm as (
  select id, sede, producto, rubro, stock_actual, stock_min, stock_max, perecedero,
         translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                   'áéíóúüñ', 'aeiouun') as clave
  from public.productos
  where activo = 'SÍ'
),
malas as (
  select ri.id as item_id, ri.receta_id, r.fudo_product_nombre,
         b.id as id_bodega, b.producto as en_bodega, b.clave, b.rubro as rubro_bodega
  from public.receta_items ri
  join public.recetas r on r.id = ri.receta_id
  join norm b           on b.id = ri.producto_id
  where r.sede = 'angamos' and r.activo and b.sede = 'bodega'
),
elegido as (
  select m.*,
         (select a.id from norm a where a.sede='angamos' and a.clave = m.clave limit 1)                  as ex,
         (select a.id from norm a where a.sede='angamos' and a.clave = m.clave || ' vitrina' limit 1)    as vit,
         (select a.id from norm a where a.sede='angamos' and a.clave = m.clave || ' congelador' limit 1) as cong
  from malas m
)
select fudo_product_nombre       as se_vende_en_fudo,
       en_bodega                 as apunta_hoy_a,
       id_bodega,
       coalesce(ex, vit, cong)   as pasaria_a_id,
       (select producto from public.productos p where p.id = coalesce(ex, vit, cong)) as pasaria_a,
       case when ex   is not null then 'repuntar · mismo nombre'
            when vit  is not null then 'repuntar · a la VITRINA'
            when cong is not null then 'repuntar · solo hay congelador'
            else '➕ CREAR el producto en Angamos' end as que_haria,
       case when coalesce(ex,vit,cong) is null
             and not exists (select 1 from norm a where a.sede='angamos' and a.rubro = rubro_bodega)
            then '⚠️ la sección "' || coalesce(rubro_bodega,'(sin sección)') || '" no existe en Angamos'
       end as ojo
from elegido
order by (coalesce(ex, vit, cong) is null) desc, en_bodega, se_vende_en_fudo;


-- ================================================================
-- BLOQUE 2 — CREAR LOS QUE FALTAN, y preparar el deshacer
--
-- Dos cosas chicas:
--   · una tabla de respaldo VACÍA, para poder volver atrás después
--   · los productos que faltan en Angamos, copiados de bodega con
--     STOCK 0 para que el personal los cuente
--
-- Se puede correr dos veces sin duplicar nada.
-- ================================================================
create table if not exists public.receta_items_respaldo_20260809 (
  item_id       bigint primary key,
  producto_id_antes bigint not null,
  guardado_at   timestamptz not null default now()
);

insert into public.productos (sede, producto, rubro, stock_actual, stock_min, stock_max, activo, perecedero)
select distinct 'angamos', b.producto, b.rubro, 0, b.stock_min, b.stock_max, 'SÍ', b.perecedero
from public.productos b
where b.sede = 'bodega' and b.activo = 'SÍ'
  and b.id in (
    select ri.producto_id
    from public.receta_items ri
    join public.recetas r on r.id = ri.receta_id
    where r.sede = 'angamos' and r.activo
  )
  and not exists (
    select 1 from public.productos a
     where a.sede = 'angamos' and a.activo = 'SÍ'
       and translate(lower(regexp_replace(trim(coalesce(a.producto,'')), '\s+',' ','g')),'áéíóúüñ','aeiouun')
        in (
          translate(lower(regexp_replace(trim(coalesce(b.producto,'')), '\s+',' ','g')),'áéíóúüñ','aeiouun'),
          translate(lower(regexp_replace(trim(coalesce(b.producto,'')), '\s+',' ','g')),'áéíóúüñ','aeiouun') || ' vitrina',
          translate(lower(regexp_replace(trim(coalesce(b.producto,'')), '\s+',' ','g')),'áéíóúüñ','aeiouun') || ' congelador'
        ));

-- comprobación: qué se creó recién
select id, producto, rubro, stock_actual
from public.productos
where sede = 'angamos' and activo = 'SÍ' and coalesce(stock_actual,0) = 0
order by id desc limit 30;


-- ================================================================
-- BLOQUE 3 — REPUNTAR (acá sí cambia)
--
-- Guarda primero a dónde apuntaba cada renglón, y recién después lo mueve.
-- Solo toca renglones que apunten a BODEGA — lo que ya arreglaste a mano
-- (las pizzas) no se toca.
-- ================================================================
insert into public.receta_items_respaldo_20260809 (item_id, producto_id_antes)
select ri.id, ri.producto_id
from public.receta_items ri
join public.recetas   r on r.id = ri.receta_id
join public.productos b on b.id = ri.producto_id
where r.sede = 'angamos' and r.activo and b.sede = 'bodega'
on conflict (item_id) do nothing;

update public.receta_items ri
   set producto_id = destino.nuevo
from (
  select ri2.id as item_id,
         coalesce(
           (select a.id from public.productos a
             where a.sede='angamos' and a.activo='SÍ'
               and translate(lower(regexp_replace(trim(coalesce(a.producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun')
                 = translate(lower(regexp_replace(trim(coalesce(b.producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun')
             limit 1),
           (select a.id from public.productos a
             where a.sede='angamos' and a.activo='SÍ'
               and translate(lower(regexp_replace(trim(coalesce(a.producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun')
                 = translate(lower(regexp_replace(trim(coalesce(b.producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun') || ' vitrina'
             limit 1),
           (select a.id from public.productos a
             where a.sede='angamos' and a.activo='SÍ'
               and translate(lower(regexp_replace(trim(coalesce(a.producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun')
                 = translate(lower(regexp_replace(trim(coalesce(b.producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun') || ' congelador'
             limit 1)
         ) as nuevo
  from public.receta_items ri2
  join public.recetas   r on r.id = ri2.receta_id
  join public.productos b on b.id = ri2.producto_id
  where r.sede = 'angamos' and r.activo and b.sede = 'bodega'
) as destino
where ri.id = destino.item_id
  and destino.nuevo is not null
  -- si la receta ya tiene ese insumo, no se puede repuntar (choca con la
  -- regla de un insumo por receta). Esas quedan y salen en el bloque 4.
  and not exists (select 1 from public.receta_items x
                   where x.receta_id = ri.receta_id and x.producto_id = destino.nuevo);


-- ================================================================
-- BLOQUE 4 — LA COMPROBACIÓN. Tiene que dar CERO.
--
-- Si "siguen_apuntando_a_bodega" no es 0, mándame la segunda consulta:
-- son casos que hay que mirar de a uno, no un fallo del arreglo.
-- ================================================================
select count(*) as siguen_apuntando_a_bodega
from public.receta_items ri
join public.recetas   r on r.id = ri.receta_id
join public.productos b on b.id = ri.producto_id
where r.sede = 'angamos' and r.activo and b.sede = 'bodega';

select r.fudo_product_nombre as se_vende_en_fudo, b.id as sigue_en_bodega, b.producto
from public.receta_items ri
join public.recetas   r on r.id = ri.receta_id
join public.productos b on b.id = ri.producto_id
where r.sede = 'angamos' and r.activo and b.sede = 'bodega'
order by b.producto;


-- ================================================================
-- SI HAY QUE VOLVER ATRÁS (no correr salvo que haga falta)
--
-- update public.receta_items ri
--    set producto_id = s.producto_id_antes
-- from public.receta_items_respaldo_20260809 s
-- where ri.id = s.item_id;
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-repuntar-recetas.sql', 'Jhon', 'lo corrió Jhon',
        'Repunta las recetas de Angamos que apuntaban a productos de bodega: 228 ventas habían descontado 254 unidades de la sede equivocada entre el 5 y el 8 de agosto')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
