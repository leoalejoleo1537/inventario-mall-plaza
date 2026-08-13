-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Uno por uno.
--  TARDA:     instantáneo
--  QUÉ HACE:  solo MIRA. Propone los gemelos que la primera pasada no
--             encontró, con una regla más suelta. NO escribe ni un par.
--  QUÉ VER:   pégame los tres. El 1 es el que hay que revisar con ojo.
-- ================================================================
--
-- POR QUÉ EXISTE: la primera pasada emparejó solo lo que se llamaba EXACTO
-- igual, y dejó 73 productos de Angamos y 87 de Plaza sin origen en bodega.
-- Al mirarlos resultó que la mayoría NO son cosas que bodega no manda: son
-- insumos de verdad, escritos distinto a los dos lados.
--
--   LECHE COCO        (bodega)  vs  Leche de coco     (local)
--   Sesamo semillas   (bodega)  vs  Sesamo            (local)
--   Cocacola light    (bodega)  vs  Coca cola light   (local)
--
-- LA REGLA NUEVA, en una frase: **todas las palabras de un nombre están en el
-- otro.** "Sesamo" cabe dentro de "Sesamo semillas", así que se proponen.
-- "Mezcla leche de oro" y "Mezcla leche dorada" NO: comparten palabras pero
-- ninguna cabe entera en la otra, así que esa la decide una persona.
--
-- Se ignoran las palabras de relleno (de, del, la, el, con, para) y los
-- sufijos Vitrina / Congelador, porque el estante no cambia qué es el
-- producto.
--
-- ⚠️ SIGUE SIENDO UNA PROPUESTA. Nada se escribe hasta que la revises. La
-- lección del `Croissant manjar` propuesto para el `Croissant Jamon Queso`
-- —insumo de once recetas— es que una regla más suelta acierta más y también
-- se equivoca más.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LAS PROPUESTAS, PARA REVISAR
--
-- QUÉ VER: recorré la columna `regla`. Las que dicen "calza entero" son casi
-- seguras. Las que dicen "una cabe en la otra" son las que hay que mirar de
-- verdad. Y si `otros_candidatos` trae algo, ese par NO se escribe: significa
-- que hay más de una posibilidad y la eliges tú.
--
-- ⚠️ Para los pares vitrina/congelador se propone EL DEL CONGELADOR, por tu
-- regla del 12 de agosto: lo que viene de bodega entra al congelador.
-- ================================================================
with pal as (
  -- las palabras de cada nombre, sin estante y sin relleno
  select id, sede, producto, rubro,
         array(
           select w from unnest(
             string_to_array(
               regexp_replace(
                 public.clave_nombre(regexp_replace(producto,'\s+(vitrina|congelador)$','','i')),
                 '[^a-z0-9 ]', '', 'g'),
               ' ')) as w
            where w <> '' and w not in ('de','del','la','el','los','las','con','para','y','a','en')
         ) as ws,
         (producto ~* '\s+congelador$') as es_cong
  from public.productos
  where activo='SÍ' and sede in ('central','plaza','angamos')
),
b as (select * from pal where sede='central'),
s as (select * from pal where sede in ('plaza','angamos')),
libres_s as (
  select s.* from s
  where not exists (select 1 from public.producto_enlace e
                     where e.sede=s.sede and e.producto_sede_id=s.id)
),
libres_b as (
  select b.* from b
  where (select count(*) from public.producto_enlace e
          where e.producto_bodega_id=b.id) < 2
),
cruce as (
  select l.sede, l.id as sede_id, l.producto as en_el_local, l.rubro as sec_local, l.es_cong,
         x.id as bodega_id, x.producto as en_bodega,
         case when l.ws = x.ws then 'calza entero' else 'una cabe en la otra' end as regla
  from libres_s l
  join libres_b x
    on cardinality(l.ws) > 0 and cardinality(x.ws) > 0
   and (l.ws <@ x.ws or x.ws <@ l.ws)
   -- un enlace de bodega por sede: si ese de bodega ya tiene gemelo acá, fuera
   and not exists (select 1 from public.producto_enlace e
                    where e.producto_bodega_id = x.id and e.sede = l.sede)
),
-- si el mismo producto de bodega calza con la vitrina Y con el congelador,
-- se queda el del congelador (tu regla). Los demás empates quedan a la vista.
mejor as (
  select c.*,
         row_number() over (partition by c.sede, c.bodega_id
                            order by c.es_cong desc, c.regla, c.en_el_local) as puesto,
         count(*)     over (partition by c.sede, c.bodega_id) as cuantos_locales,
         count(*)     over (partition by c.sede, c.sede_id)   as cuantas_bodegas
  from cruce c
)
select sede, en_bodega, bodega_id, en_el_local, sede_id, sec_local, regla,
       case when cuantas_bodegas > 1 then '⚠ ' || (cuantas_bodegas-1) || ' opción(es) más en bodega'
            when cuantos_locales  > 1 and not es_cong then '⚠ también calza con otro del local'
            else '' end as otros_candidatos
from mejor
where puesto = 1
order by sede, en_bodega;


-- ================================================================
-- BLOQUE 2 — LOS QUE SIGUEN SIN PROPUESTA
--
-- Ni exacto ni por palabras. Acá es donde hay que decidir a mano — o darse
-- cuenta de que bodega no los manda y listo.
--
-- QUÉ VER: si el Té aparece entero acá, decime si bodega manda cajas de té a
-- los locales o si el té lo compra cada local por su cuenta. Son 20 productos
-- y la respuesta cambia si hay que emparejarlos o no.
-- ================================================================
with pal as (
  select id, sede, producto, rubro,
         array(
           select w from unnest(
             string_to_array(
               regexp_replace(
                 public.clave_nombre(regexp_replace(producto,'\s+(vitrina|congelador)$','','i')),
                 '[^a-z0-9 ]', '', 'g'),
               ' ')) as w
            where w <> '' and w not in ('de','del','la','el','los','las','con','para','y','a','en')
         ) as ws
  from public.productos
  where activo='SÍ' and sede in ('central','plaza','angamos')
),
b as (select * from pal where sede='central'),
s as (select * from pal where sede in ('plaza','angamos'))
select s.sede,
       coalesce(s.rubro,'(sin sección)') as seccion,
       count(*) as cuantos,
       string_agg(s.producto, ' · ' order by s.producto) as cuales
from s
where not exists (select 1 from public.producto_enlace e
                   where e.sede=s.sede and e.producto_sede_id=s.id)
  and not exists (select 1 from b
                   where cardinality(b.ws)>0 and cardinality(s.ws)>0
                     and (s.ws <@ b.ws or b.ws <@ s.ws))
group by s.sede, coalesce(s.rubro,'(sin sección)')
order by s.sede, count(*) desc;


-- ================================================================
-- BLOQUE 3 — EL RESUMEN, PARA SABER SI VALE LA PENA
--
-- QUÉ VER: cuántos quedarían emparejados si aceptás las propuestas del
-- bloque 1, y cuántos seguirían sin origen.
-- ================================================================
with pal as (
  select id, sede,
         array(
           select w from unnest(
             string_to_array(
               regexp_replace(
                 public.clave_nombre(regexp_replace(producto,'\s+(vitrina|congelador)$','','i')),
                 '[^a-z0-9 ]', '', 'g'),
               ' ')) as w
            where w <> '' and w not in ('de','del','la','el','los','las','con','para','y','a','en')
         ) as ws
  from public.productos where activo='SÍ' and sede in ('central','plaza','angamos')
),
b as (select * from pal where sede='central'),
s as (select * from pal where sede in ('plaza','angamos')),
libres as (
  select s.* from s where not exists (
    select 1 from public.producto_enlace e where e.sede=s.sede and e.producto_sede_id=s.id)
)
select l.sede,
       count(*) as sin_origen_hoy,
       count(*) filter (where exists (
         select 1 from b where cardinality(b.ws)>0 and cardinality(l.ws)>0
                           and (l.ws <@ b.ws or b.ws <@ l.ws))) as con_propuesta,
       count(*) filter (where not exists (
         select 1 from b where cardinality(b.ws)>0 and cardinality(l.ws)>0
                           and (l.ws <@ b.ws or b.ws <@ l.ws))) as seguirian_sin_origen
from libres l
group by l.sede
order by l.sede;
