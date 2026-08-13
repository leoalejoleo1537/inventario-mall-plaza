-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Uno por uno. El 1 es solo mirar.
--  TARDA:     instantáneo
--  QUÉ HACE:  lo mismo que se hizo con Plaza, ahora con Angamos. No borra
--             nada. No toca Angamos ni Plaza.
--  QUÉ VER:   el bloque 3 tiene que decir sin_origen = 0.
-- ================================================================
--
-- POR QUÉ AHORA ES MÁS FÁCIL: bodega ya habla el idioma de Plaza. Y Plaza y
-- Angamos se parecen mucho más entre sí que cualquiera de los dos con los
-- nombres viejos de la bodega. Los 20 tés de Angamos se llaman casi igual que
-- los de Plaza, que ya están en bodega — así que se van a enganchar solos.
--
-- LA REGLA DEL CONGELADOR SE APLICA SOLA, sin cambiarle nada al script: solo
-- se salta el lado no-congelador cuando EXISTE un congelador con el mismo
-- nombre base. Plaza tiene esos dobles; Angamos no tiene ninguno. Así que en
-- Angamos entra lo que hay, incluidos los "Vitrina", que allá son el único
-- lugar donde vive el producto.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — MIRAR ANTES DE TOCAR
--
-- QUÉ VER:
--   fila 2: cuántos productos de Angamos bodega debe poder mandar.
--   fila 4: cuántos se enganchan con algo que bodega YA tiene (acá está el
--           premio de haber copiado Plaza primero).
--   fila 5: cuántos hay que crear. Son los que solo existen en Angamos.
-- ================================================================
with ang as (
  select p.* from public.productos p
  where p.sede='angamos' and p.activo='SÍ'
    and not exists (
      select 1 from public.productos c
       where c.sede='angamos' and c.activo='SÍ' and c.id <> p.id
         and c.producto ilike '% congelador'
         and public.clave_nombre(regexp_replace(c.producto,'\s+(vitrina|congelador)$','','i'))
           = public.clave_nombre(regexp_replace(p.producto,'\s+(vitrina|congelador)$','','i'))
         and p.producto not ilike '% congelador')
),
faltan as (
  select a.* from ang a
  where not exists (select 1 from public.producto_enlace e
                     where e.sede='angamos' and e.producto_sede_id = a.id)
),
pal as (
  select id, sede, producto,
         array(select w from unnest(string_to_array(
                 regexp_replace(public.clave_nombre(
                   regexp_replace(producto,'\s+(vitrina|congelador)$','','i')),
                   '[^a-z0-9 ]','','g'),' ')) as w
                where w <> '' and w not in ('de','del','la','el','los','las','con','para','y','a','en')) as ws
  from public.productos where activo='SÍ' and sede in ('central','angamos')
),
reusar as (
  select f.id as ang_id,
         (select b.id from pal b join pal pf on pf.id = f.id
           where b.sede='central' and b.ws = pf.ws and cardinality(b.ws) > 0
             and not exists (select 1 from public.producto_enlace e
                              where e.producto_bodega_id = b.id and e.sede='angamos')
           order by b.id limit 1) as bodega_id
  from faltan f
)
select 1 as n, 'Productos de Angamos que bodega debe poder mandar' as dato,
       (select count(*) from ang)::text as valor
union all
select 2, 'De esos, ya enlazados hoy',
       (select count(*) from ang a where exists (select 1 from public.producto_enlace e
          where e.sede='angamos' and e.producto_sede_id = a.id))::text
union all
select 3, 'Se ENGANCHARÁN con uno que bodega ya tiene',
       (select count(*) from reusar where bodega_id is not null)::text
union all
select 4, 'Se CREARÁN nuevos (solo existen en Angamos)',
       (select count(*) from reusar where bodega_id is null)::text
order by 1;


-- ================================================================
-- BLOQUE 2 — ENGANCHAR Y CREAR
--
-- Son dos órdenes seguidas: primero engancha lo que bodega ya tiene, después
-- crea lo que falta y lo engancha. Ninguna devuelve tabla — es normal que no
-- salga nada. Se puede correr dos veces sin duplicar.
-- ================================================================
with ang as (
  select p.* from public.productos p
  where p.sede='angamos' and p.activo='SÍ'
    and not exists (select 1 from public.productos c
       where c.sede='angamos' and c.activo='SÍ' and c.id <> p.id
         and c.producto ilike '% congelador'
         and public.clave_nombre(regexp_replace(c.producto,'\s+(vitrina|congelador)$','','i'))
           = public.clave_nombre(regexp_replace(p.producto,'\s+(vitrina|congelador)$','','i'))
         and p.producto not ilike '% congelador')
),
pal as (
  select id, sede, producto,
         array(select w from unnest(string_to_array(
                 regexp_replace(public.clave_nombre(
                   regexp_replace(producto,'\s+(vitrina|congelador)$','','i')),
                   '[^a-z0-9 ]','','g'),' ')) as w
                where w <> '' and w not in ('de','del','la','el','los','las','con','para','y','a','en')) as ws
  from public.productos where activo='SÍ' and sede in ('central','angamos')
)
insert into public.producto_enlace (producto_bodega_id, sede, producto_sede_id, factor, creado_por)
select b.id, 'angamos', a.id, 1, 'espejo de Angamos'
from ang a
join pal pf on pf.id = a.id
join pal b  on b.sede='central' and b.ws = pf.ws and cardinality(b.ws) > 0
where not exists (select 1 from public.producto_enlace e
                   where e.sede='angamos' and e.producto_sede_id = a.id)
  and not exists (select 1 from public.producto_enlace e
                   where e.sede='angamos' and e.producto_bodega_id = b.id)
on conflict do nothing;

with ang as (
  select p.* from public.productos p
  where p.sede='angamos' and p.activo='SÍ'
    and not exists (select 1 from public.productos c
       where c.sede='angamos' and c.activo='SÍ' and c.id <> p.id
         and c.producto ilike '% congelador'
         and public.clave_nombre(regexp_replace(c.producto,'\s+(vitrina|congelador)$','','i'))
           = public.clave_nombre(regexp_replace(p.producto,'\s+(vitrina|congelador)$','','i'))
         and p.producto not ilike '% congelador')
),
faltan as (
  select a.* from ang a
  where not exists (select 1 from public.producto_enlace e
                     where e.sede='angamos' and e.producto_sede_id = a.id)
),
nuevos as (
  insert into public.productos
    (sede, producto, rubro, stock_actual, stock_min, stock_max, activo, perecedero, tipo)
  select 'central', f.producto, f.rubro, 0, null, null, 'SÍ',
         coalesce(f.perecedero,false), f.tipo
  from faltan f
  -- no filtra por activo a propósito: lo que se apagó en bodega no se revive
  where not exists (select 1 from public.productos c
                     where c.sede='central'
                       and public.clave_nombre(c.producto) = public.clave_nombre(f.producto))
  returning id, producto
)
insert into public.producto_enlace (producto_bodega_id, sede, producto_sede_id, factor, creado_por)
select n.id, 'angamos', f.id, 1, 'espejo de Angamos'
from nuevos n
join faltan f on public.clave_nombre(f.producto) = public.clave_nombre(n.producto)
on conflict do nothing;


-- ================================================================
-- BLOQUE 3 — COMPROBACIÓN DE LAS DOS SEDES
--
-- QUÉ VER: `sin_origen` en 0 para las dos. Ese cero significa que bodega ya
-- puede mandar cualquier cosa que cualquiera de los dos locales tenga, y sabe
-- de cuál de sus productos descontar. Ahí termina el problema de los ID.
-- ================================================================
with mandables as (
  select p.sede, p.id
  from public.productos p
  where p.sede in ('plaza','angamos') and p.activo='SÍ'
    and not exists (select 1 from public.productos c
       where c.sede=p.sede and c.activo='SÍ' and c.id <> p.id
         and c.producto ilike '% congelador'
         and public.clave_nombre(regexp_replace(c.producto,'\s+(vitrina|congelador)$','','i'))
           = public.clave_nombre(regexp_replace(p.producto,'\s+(vitrina|congelador)$','','i'))
         and p.producto not ilike '% congelador')
)
select m.sede,
       count(*)                                                     as debe_poder_mandar,
       count(*) filter (where exists (select 1 from public.producto_enlace e
                          where e.sede=m.sede and e.producto_sede_id=m.id)) as con_origen,
       count(*) filter (where not exists (select 1 from public.producto_enlace e
                          where e.sede=m.sede and e.producto_sede_id=m.id)) as sin_origen,
       (select count(*) from public.productos
         where sede='central' and activo='SÍ')                       as productos_en_bodega
from mandables m
group by m.sede
order by m.sede;
