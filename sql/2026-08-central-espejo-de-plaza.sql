-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        5 bloques. UNO POR UNO. El 1 es solo mirar.
--  TARDA:     instantáneo
--  QUÉ HACE:  hace que bodega tenga TODOS los productos de Mall Plaza, ya
--             enlazados. No borra nada. No toca Mall Plaza ni Angamos.
--  QUÉ VER:   el bloque 1 primero. Si la fila de arriba dice DETENTE, pará.
-- ================================================================
--
-- LA IDEA ES TUYA Y ES LA CORRECTA: en vez de emparejar dos catálogos que
-- nunca fueron pensados para calzar, que bodega **copie** el de Plaza. Así el
-- enlace no se adivina: nace hecho, porque el producto de bodega ES el de
-- Plaza copiado con su mismo nombre.
--
-- LAS DOS COSAS QUE CAMBIAN RESPECTO A LO QUE PROPUSISTE, y las dos son para
-- no perder nada:
--
-- 1. NO se borra el catálogo de bodega. Se AGREGA lo que falta. Borrar se
--    llevaría con él los 300 enlaces ya escritos (la tabla los borra en
--    cascada) y los productos que solo existen en bodega — los bultos, la
--    quinoa, el cacao en polvo, el bidón de 20 litros. Esos no están en Plaza
--    y desaparecerían.
--
-- 2. Los "Vitrina" NO se copian. Si un producto tiene doble estante en Plaza,
--    se copia SOLO el del congelador — tu regla, convertida en estructura en
--    vez de en una decisión que alguien pueda equivocar.
--
-- QUÉ PASA CON EL TÉ Y LAS TORTAS: se resuelven solos. Están en Plaza, así que
-- se copian y quedan enlazados. No hay que crearlos a mano.
--
-- LO QUE SÍ VA A QUEDAR: algún producto viejo de bodega repetido con otro
-- nombre (`LECHE COCO` de bodega junto al `Leche de coco` copiado). El bloque 2
-- evita la mayoría enlazando el que ya existe cuando el nombre calza entero.
-- Los que queden son productos sueltos sin enlace: no estorban al reparto y se
-- apagan cuando el equipo depure. Están listados en el bloque 5.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — MIRAR ANTES DE TOCAR
--
-- QUÉ VER, en este orden:
--   fila 1: si dice DETENTE, Adriana ya contó y hay que hablarlo antes.
--   fila 2: cuántos productos de Plaza quedarían enlazados al final (la meta
--           es 100%).
--   fila 3: cuántos se van a ENLAZAR con un producto que bodega ya tiene.
--   fila 4: cuántos se van a CREAR nuevos en bodega.
-- ================================================================
with plaza as (
  -- los productos de Plaza que bodega tiene que poder mandar.
  -- Se salta el lado NO congelador de un par con doble estante: si existe
  -- "X Congelador", el otro "X" no se copia (tu regla del 12 de agosto).
  select p.*
  from public.productos p
  where p.sede='plaza' and p.activo='SÍ'
    and not exists (
      select 1 from public.productos c
       where c.sede='plaza' and c.activo='SÍ' and c.id <> p.id
         and c.producto ilike '% congelador'
         and public.clave_nombre(regexp_replace(c.producto,'\s+(vitrina|congelador)$','','i'))
           = public.clave_nombre(regexp_replace(p.producto,'\s+(vitrina|congelador)$','','i'))
         and p.producto not ilike '% congelador')
),
faltan as (
  select pz.* from plaza pz
  where not exists (select 1 from public.producto_enlace e
                     where e.sede='plaza' and e.producto_sede_id = pz.id)
),
-- "calza entero": las mismas palabras, sin relleno ni sufijo de estante
pal as (
  select id, sede, producto,
         array(select w from unnest(string_to_array(
                 regexp_replace(public.clave_nombre(
                   regexp_replace(producto,'\s+(vitrina|congelador)$','','i')),
                   '[^a-z0-9 ]','','g'),' ')) as w
                where w <> '' and w not in ('de','del','la','el','los','las','con','para','y','a','en')) as ws
  from public.productos where activo='SÍ' and sede in ('central','plaza')
),
reusar as (
  select f.id as plaza_id,
         (select b.id from pal b
           join pal pf on pf.id = f.id
          where b.sede='central' and b.ws = pf.ws and cardinality(b.ws) > 0
            and not exists (select 1 from public.producto_enlace e
                             where e.producto_bodega_id = b.id and e.sede='plaza')
          order by b.id limit 1) as bodega_id
  from faltan f
)
select 1 as n, 'Adriana ya contó bodega' as dato,
       case when (select count(*) from public.productos
                   where sede='central' and activo='SÍ' and coalesce(stock_actual,0) > 0) > 0
            then '⚠ DETENTE — hay stock contado, avísame antes de seguir'
            else 'no, está en 0 · se puede seguir' end as valor
union all
select 2, 'Productos de Plaza que bodega debe poder mandar',
       (select count(*) from plaza)::text
union all
select 3, 'De esos, ya enlazados hoy',
       (select count(*) from plaza pz where exists (
          select 1 from public.producto_enlace e
           where e.sede='plaza' and e.producto_sede_id = pz.id))::text
union all
select 4, 'Se ENLAZARÁN con uno que bodega ya tiene',
       (select count(*) from reusar where bodega_id is not null)::text
union all
select 5, 'Se CREARÁN nuevos en bodega',
       (select count(*) from reusar where bodega_id is null)::text
order by 1;


-- ================================================================
-- BLOQUE 2 — ENLAZAR LO QUE BODEGA YA TIENE
--
-- Los que se llaman igual palabra por palabra: no se crea nada, solo se
-- engancha. Así `LECHE COCO` de bodega queda como origen del `Leche de coco`
-- de Plaza, y no aparece un duplicado.
-- ================================================================
with plaza as (
  select p.* from public.productos p
  where p.sede='plaza' and p.activo='SÍ'
    and not exists (select 1 from public.productos c
       where c.sede='plaza' and c.activo='SÍ' and c.id <> p.id
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
  from public.productos where activo='SÍ' and sede in ('central','plaza')
)
insert into public.producto_enlace (producto_bodega_id, sede, producto_sede_id, factor, creado_por)
select b.id, 'plaza', pz.id, 1, 'espejo de Plaza'
from plaza pz
join pal pf on pf.id = pz.id
join pal b  on b.sede='central' and b.ws = pf.ws and cardinality(b.ws) > 0
where not exists (select 1 from public.producto_enlace e
                   where e.sede='plaza' and e.producto_sede_id = pz.id)
  and not exists (select 1 from public.producto_enlace e
                   where e.sede='plaza' and e.producto_bodega_id = b.id)
on conflict do nothing;


-- ================================================================
-- BLOQUE 3 — CREAR EN BODEGA LO QUE FALTA, YA ENLAZADO
--
-- Copia el nombre y la sección de Plaza. El stock nace en 0 y el mínimo y el
-- máximo quedan vacíos a propósito: los de Plaza son de su repisa, no de
-- bodega, y los pone Adriana cuando cuente.
--
-- Se puede correr dos veces sin duplicar.
-- ================================================================
with plaza as (
  select p.* from public.productos p
  where p.sede='plaza' and p.activo='SÍ'
    and not exists (select 1 from public.productos c
       where c.sede='plaza' and c.activo='SÍ' and c.id <> p.id
         and c.producto ilike '% congelador'
         and public.clave_nombre(regexp_replace(c.producto,'\s+(vitrina|congelador)$','','i'))
           = public.clave_nombre(regexp_replace(p.producto,'\s+(vitrina|congelador)$','','i'))
         and p.producto not ilike '% congelador')
),
faltan as (
  select pz.* from plaza pz
  where not exists (select 1 from public.producto_enlace e
                     where e.sede='plaza' and e.producto_sede_id = pz.id)
),
nuevos as (
  insert into public.productos
    (sede, producto, rubro, stock_actual, stock_min, stock_max, activo, perecedero, tipo)
  select 'central', f.producto, f.rubro, 0, null, null, 'SÍ',
         coalesce(f.perecedero,false), f.tipo
  from faltan f
  -- la comprobación de existencia NO filtra por activo: si alguien lo apagó en
  -- bodega a propósito, no se revive (regla 0.6.3)
  where not exists (select 1 from public.productos c
                     where c.sede='central'
                       and public.clave_nombre(c.producto) = public.clave_nombre(f.producto))
  returning id, producto
)
insert into public.producto_enlace (producto_bodega_id, sede, producto_sede_id, factor, creado_por)
select n.id, 'plaza', f.id, 1, 'espejo de Plaza'
from nuevos n
join faltan f on public.clave_nombre(f.producto) = public.clave_nombre(n.producto)
on conflict do nothing;


-- ================================================================
-- BLOQUE 4 — COMPROBACIÓN
--
-- QUÉ VER: `sin_origen` en 0. Ese 0 significa que bodega ya puede mandar
-- cualquier cosa que Plaza tenga, y sabe de cuál de sus productos descontar.
-- ================================================================
with plaza as (
  select p.* from public.productos p
  where p.sede='plaza' and p.activo='SÍ'
    and not exists (select 1 from public.productos c
       where c.sede='plaza' and c.activo='SÍ' and c.id <> p.id
         and c.producto ilike '% congelador'
         and public.clave_nombre(regexp_replace(c.producto,'\s+(vitrina|congelador)$','','i'))
           = public.clave_nombre(regexp_replace(p.producto,'\s+(vitrina|congelador)$','','i'))
         and p.producto not ilike '% congelador')
)
select (select count(*) from plaza)                                     as debe_poder_mandar,
       (select count(*) from plaza pz where exists (
          select 1 from public.producto_enlace e
           where e.sede='plaza' and e.producto_sede_id = pz.id))         as con_origen,
       (select count(*) from plaza pz where not exists (
          select 1 from public.producto_enlace e
           where e.sede='plaza' and e.producto_sede_id = pz.id))         as sin_origen,
       (select count(*) from public.productos where sede='central' and activo='SÍ') as productos_en_bodega;


-- ================================================================
-- BLOQUE 5 — LO QUE QUEDA PARA DESPUÉS (solo mirar)
--
-- Dos listas para el siguiente paso, ninguna urgente:
--   a) productos viejos de bodega que quedaron sin enlace a Plaza. Son los
--      candidatos a apagar cuando el equipo depure, o los que solo existen en
--      bodega de verdad (bultos, granel).
--   b) cuánto falta para Angamos, que es el paso siguiente y ahora es UNA sola
--      sede en vez de dos.
-- ================================================================
select 'bodega sin enlace a Plaza' as lista,
       coalesce(rubro,'(sin sección)') as seccion,
       count(*) as cuantos,
       string_agg(producto, ' · ' order by producto) as cuales
from public.productos b
where b.sede='central' and b.activo='SÍ'
  and not exists (select 1 from public.producto_enlace e
                   where e.producto_bodega_id=b.id and e.sede='plaza')
group by 1,2
union all
select 'Angamos sin origen en bodega',
       coalesce(rubro,'(sin sección)'),
       count(*),
       string_agg(producto, ' · ' order by producto)
from public.productos s
where s.sede='angamos' and s.activo='SÍ'
  and not exists (select 1 from public.producto_enlace e
                   where e.sede='angamos' and e.producto_sede_id=s.id)
group by 1,2
order by 1, 3 desc;
