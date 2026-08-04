-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  compara los DOS catálogos de Fudo (Plaza y Angamos) y
--             mide cuántas recetas se podrían trasladar solas.
--             NO ESCRIBE NADA.
--  QUÉ VER:   el bloque 1 da el porcentaje. Ese número decide si
--             seguimos con el traslado automático o no.
-- ================================================================
--
-- ⚠️ CORRER SOLO DESPUÉS de haber traído el catálogo de Fudo Angamos
-- (elegir Parque Angamos en la app y apretar ⟳). Si no, va a decir 0%
-- porque no hay con qué comparar.
--
-- POR QUÉ ESTE PASO EXISTE, y es el que más puede doler si falta:
-- trasladar una receta de Plaza a Angamos necesita DOS saltos por nombre
--
--    salto 1:  Fudo plaza "Cappuccino"  ->  Fudo angamos "Cappuccino"
--    salto 2:  insumo plaza "Leche"     ->  insumo angamos "Leche"
--
-- El plan original solo cuidaba el segundo. El primero es igual de
-- frágil: son dos cuentas de Fudo distintas, cargadas por gente
-- distinta. Y hay evidencia dura de que los nombres no son confiables —
-- dentro del propio Plaza convivían "T. Cheesecake Maracuya" y
-- "T. Cheesecake Mara" para lo mismo.
--
-- Si calzan 150 de 168, adelante. Si calzan 60, el traslado automático
-- no es el camino, y es mucho mejor saberlo AHORA que después de haber
-- escrito 168 recetas mal.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL NÚMERO QUE DECIDE
--
-- QUÉ VER: la columna "porcentaje". Es cuántas de las recetas de Plaza
-- encuentran su producto con el mismo nombre en el Fudo de Angamos.
-- ================================================================
with plaza as (
  select r.fudo_product_id,
         fp.nombre,
         lower(translate(regexp_replace(trim(fp.nombre),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.recetas r
  join public.fudo_productos fp
    on fp.fudo_product_id = r.fudo_product_id and fp.sede = 'plaza'
  where r.sede = 'plaza' and r.activo and fp.activo
),
angamos as (
  select lower(translate(regexp_replace(trim(nombre),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.fudo_productos
  where sede = 'angamos' and activo
)
select count(*)                                              as recetas_en_plaza,
       count(*) filter (where exists
         (select 1 from angamos a where a.clave = p.clave))   as calzan_por_nombre,
       round(100.0 * count(*) filter (where exists
         (select 1 from angamos a where a.clave = p.clave))
         / nullif(count(*),0), 0)                             as porcentaje,
       case
         when count(*) = 0 then '🔍 sin datos — ¿ya trajiste el catálogo de Angamos?'
         when 100.0 * count(*) filter (where exists
              (select 1 from angamos a where a.clave = p.clave))
              / nullif(count(*),0) >= 80
           then '✅ el traslado automático vale la pena'
         when 100.0 * count(*) filter (where exists
              (select 1 from angamos a where a.clave = p.clave))
              / nullif(count(*),0) >= 50
           then '🟡 sirve, pero hay bastante que revisar a mano'
         else '🔴 calzan pocas — conviene conversarlo antes de seguir'
       end                                                    as veredicto
from plaza p;


-- ================================================================
-- BLOQUE 2 — LAS QUE NO CALZAN, CON SU CANDIDATO
--
-- QUÉ VER: cada fila es una receta de Plaza cuyo producto NO existe con
-- el mismo nombre en Fudo Angamos. La última columna PROPONE el más
-- parecido — propone, no concluye (regla 0.1.4). Tú decides.
-- ================================================================
with plaza as (
  select fp.nombre,
         lower(translate(regexp_replace(trim(fp.nombre),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.recetas r
  join public.fudo_productos fp
    on fp.fudo_product_id = r.fudo_product_id and fp.sede = 'plaza'
  where r.sede = 'plaza' and r.activo and fp.activo
),
plaza_clave as (
  select p.*,
         (select w from regexp_split_to_table(p.clave,'\s+') w
           where length(w) >= 4 order by length(w) desc, w limit 1) as palabra
  from plaza p
),
angamos as (
  select nombre,
         lower(translate(regexp_replace(trim(nombre),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.fudo_productos
  where sede = 'angamos' and activo
)
select pc.nombre as receta_en_plaza,
       coalesce((select string_agg(distinct a.nombre, '  ·  ')
                   from angamos a
                  where pc.palabra is not null and a.clave like '%'||pc.palabra||'%'),
                '— ninguno se le parece —') as candidato_en_fudo_angamos
from plaza_clave pc
where not exists (select 1 from angamos a where a.clave = pc.clave)
order by pc.nombre;


-- ================================================================
-- BLOQUE 3 — EL PANORAMA DE LOS DOS CATÁLOGOS
--
-- Para tener contexto: cuántos productos tiene Fudo en cada sede.
-- ================================================================
select sede,
       count(*) filter (where activo) as productos_activos_en_fudo,
       count(*)                       as total_incluyendo_inactivos
from public.fudo_productos
group by sede
order by sede;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-calce-de-catalogos.sql', 'Jhon', 'lo corrió Jhon',
        'Solo lectura. Midió cuántas recetas de Plaza calzan por nombre con el Fudo de Angamos')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
