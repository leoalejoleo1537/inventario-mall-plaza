-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO y mandarme el resultado.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  NADA. Mira y cuenta. No apaga, no junta, no borra.
--  QUÉ VER:   el bloque 1 es el resumen; el 2 es la lista para revisar;
--             el 3 son las alarmas; el 4 son los casos raros.
-- ================================================================
--
-- QUÉ ENCONTRAMOS: bodega tiene el mismo producto cargado dos veces.
-- "Alfajor artesanal" está con id 450 (stock 4) y con id 282 (stock 0).
-- Así hay más de 115.
--
-- LA IMAGEN: es como tener dos fichas del mismo estante en el archivador.
-- Mientras estén las dos, nadie sabe en cuál anotar — y el reparto no va a
-- saber de cuál descontar.
--
-- QUÉ VA A PASAR DESPUÉS (no ahora): se queda UNA ficha, se le suma lo de la
-- otra, y la sobrante se apaga (no se borra, para poder volver atrás).
--
-- ESTE ARCHIVO SOLO PREPARA ESA DECISIÓN. No toca nada.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL RESUMEN, y la cuenta que tiene que cuadrar
--
-- ⚠️ LA COLUMNA IMPORTANTE ES LA ÚLTIMA: "stock_total_hoy" tiene que ser
-- IGUAL después de juntar. Si al terminar cambió, algo se perdió por el
-- camino. Es el número contra el cual se comprueba todo.
-- ================================================================
with n as (
  select id, producto, stock_actual,
         translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                   'áéíóúüñ', 'aeiouun') as clave
  from public.productos
  where sede = 'bodega' and activo = 'SÍ'
),
g as (
  select clave, count(*) as cuantos from n group by clave
)
select (select count(*) from n)                                  as productos_activos_hoy,
       (select count(*) from g where cuantos > 1)                as nombres_duplicados,
       (select sum(cuantos) from g where cuantos > 1)            as fichas_involucradas,
       (select sum(cuantos - 1) from g where cuantos > 1)        as se_apagarian,
       (select count(*) from n)
         - coalesce((select sum(cuantos - 1) from g where cuantos > 1), 0) as quedarian_activos,
       (select coalesce(sum(coalesce(stock_actual,0)),0) from n) as stock_total_hoy;


-- ================================================================
-- BLOQUE 2 — LA LISTA PARA REVISAR
--
-- Una fila por ficha. Las del mismo producto salen juntas.
--
-- "que_pasaria" dice QUEDA o se apaga. Lo decidí así, en este orden:
--   1. gana el que su nombre calce EXACTO con el de la sede — es lo que
--      hace que el enlace funcione después;
--   2. si empatan, el que tenga más stock;
--   3. si siguen empatados, el id más bajo.
--
-- ⚠️ ESTO ES UNA PROPUESTA, NO UNA DECISIÓN. Mira sobre todo las filas
-- donde "calza_con_la_sede" dice NO en las dos: ahí elegí a ciegas.
-- ================================================================
with n as (
  select id, producto, rubro, stock_actual,
         coalesce(perecedero, rubro = 'Sándwiches') as es_perecedero,
         translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                   'áéíóúüñ', 'aeiouun') as clave
  from public.productos
  where sede = 'bodega' and activo = 'SÍ'
),
dup as (select clave from n group by clave having count(*) > 1),
marcado as (
  select n.*,
         exists (select 1 from public.productos s
                  where s.sede <> 'bodega' and s.activo = 'SÍ'
                    and s.producto = n.producto)                as calza_exacto,
         exists (select 1 from public.producto_lotes l
                  where l.producto_id = n.id)                   as tiene_fechas
  from n join dup on dup.clave = n.clave
),
ordenado as (
  select m.*,
         row_number() over (partition by m.clave
                            order by m.calza_exacto desc,
                                     coalesce(m.stock_actual,0) desc,
                                     m.id asc)                  as puesto
  from marcado m
)
select clave                                   as producto_normalizado,
       id,
       producto                                as nombre_tal_cual,
       rubro                                   as seccion,
       stock_actual,
       case when calza_exacto then 'sí' else 'NO' end as calza_con_la_sede,
       case when tiene_fechas then 'sí' else '' end   as tiene_fechas,
       case when es_perecedero then 'sí' else '' end  as es_perecedero,
       case when puesto = 1 then '✅ QUEDA' else '⬜ se apaga' end as que_pasaria
from ordenado
order by clave, puesto;


-- ================================================================
-- BLOQUE 3 — LAS ALARMAS
--
-- Apagar una ficha que está enganchada a otra cosa rompe algo. Acá salen
-- SOLO las que se apagarían y tienen algún enganche.
--
-- ⚠️ LOS TRES ENGANCHES NO SIGNIFICAN LO MISMO, y por eso hay una columna
-- que lo dice:
--   · fechas de vencimiento  -> NO bloquea. Las fechas se mudan a la ficha
--     que queda y el stock se recalcula solo. Es el camino de los
--     perecederos y ya está previsto.
--   · usado en una receta    -> SÍ bloquea. Bodega no debería tener recetas;
--     si aparece una, hay que entender por qué antes de apagar nada.
--   · en un reparto abierto  -> SÍ bloquea. Hay un envío a medias apuntando
--     a esa ficha. Primero se cierra el reparto.
--
-- QUÉ VER: si esto sale VACÍO, la limpieza es segura y seguimos.
-- Si sale algo, mirar la columna "que_significa".
-- ================================================================
with n as (
  select id, producto, stock_actual,
         translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                   'áéíóúüñ', 'aeiouun') as clave
  from public.productos
  where sede = 'bodega' and activo = 'SÍ'
),
dup as (select clave from n group by clave having count(*) > 1),
marcado as (
  select n.*,
         exists (select 1 from public.productos s
                  where s.sede <> 'bodega' and s.activo = 'SÍ'
                    and s.producto = n.producto) as calza_exacto
  from n join dup on dup.clave = n.clave
),
ordenado as (
  select m.*, row_number() over (partition by m.clave
                order by m.calza_exacto desc, coalesce(m.stock_actual,0) desc, m.id asc) as puesto
  from marcado m
),
se_apagan as (select * from ordenado where puesto > 1),
con_enganches as (
  select a.id, a.producto, a.stock_actual,
         (select count(*) from public.producto_lotes l where l.producto_id = a.id) as fechas,
         (select count(*) from public.receta_items ri where ri.producto_id = a.id) as recetas,
         (select count(*) from public.reparto_items ri
            join public.repartos r on r.id = ri.reparto_id
           where ri.producto_id = a.id and r.estado = 'abierto')                   as repartos_abiertos
  from se_apagan a
)
select id, producto, stock_actual,
       fechas             as fechas_de_vencimiento,
       recetas            as usado_en_recetas,
       repartos_abiertos  as en_repartos_abiertos,
       case when recetas > 0 and repartos_abiertos > 0
              then '🛑 PARA — está en una receta y en un reparto abierto'
            when recetas > 0
              then '🛑 PARA — bodega no debería tener recetas; hay que entenderlo'
            when repartos_abiertos > 0
              then '🛑 PARA — hay un envío a medias; primero cerrar ese reparto'
            else '✅ se puede — las fechas se mudan a la ficha que queda'
       end as que_significa
from con_enganches
where fechas > 0 or recetas > 0 or repartos_abiertos > 0
order by (recetas > 0 or repartos_abiertos > 0) desc, producto;


-- ================================================================
-- BLOQUE 4 — LOS CASOS RAROS, que son los que hay que mirar de verdad
--
-- Dos cosas junté acá porque las dos piden criterio humano:
--   · grupos de TRES o más fichas del mismo producto
--   · grupos donde NINGUNA ficha calza con el nombre de la sede — ahí mi
--     regla no tuvo con qué decidir y elegí por stock nomás
--
-- QUÉ VER: si sale vacío, el bloque 2 se puede aprobar tal cual.
-- ================================================================
with n as (
  select id, producto, stock_actual,
         translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                   'áéíóúüñ', 'aeiouun') as clave
  from public.productos
  where sede = 'bodega' and activo = 'SÍ'
),
dup as (select clave, count(*) as cuantos from n group by clave having count(*) > 1),
marcado as (
  select n.*, d.cuantos,
         exists (select 1 from public.productos s
                  where s.sede <> 'bodega' and s.activo = 'SÍ'
                    and s.producto = n.producto) as calza_exacto
  from n join dup d on d.clave = n.clave
)
select clave                          as producto_normalizado,
       max(cuantos)                   as cuantas_fichas,
       string_agg(id::text || ' (' || producto || ' · ' ||
                  coalesce(stock_actual,0)::text || ')', '  |  ' order by id) as las_fichas,
       case when max(cuantos) > 2 and not bool_or(calza_exacto)
              then 'tres o más fichas Y ninguna calza con la sede'
            when max(cuantos) > 2
              then 'tres o más fichas'
            else 'ninguna calza con el nombre de la sede' end as por_que_esta_aca
from marcado
group by clave
having max(cuantos) > 2 or not bool_or(calza_exacto)
order by max(cuantos) desc, clave;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-bodega-duplicados-informe.sql', 'Jhon', 'lo corrió Jhon',
        'Informe de SOLO LECTURA: los productos duplicados dentro de bodega, con el superviviente propuesto y las alarmas antes de apagar nada')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
