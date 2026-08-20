-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. Es la lista de comprobación de la entrega:
--             dice qué está instalado de verdad y qué falta.
--  QUÉ VER:   la columna "estado". Todo tiene que decir ✅.
-- ================================================================
--
-- PARA QUÉ SIRVE. El repositorio y la base son dos cosas distintas: que un
-- archivo exista en GitHub no significa que se haya corrido acá. Este
-- proyecto pagó ese error tres veces —una de ellas costó 15 horas sin
-- descontar, mostrando "✓" en la pantalla—.
--
-- Antes de entregar, esto contesta con datos qué está encendido. No hay que
-- acordarse de nada ni confiar en ninguna lista.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ¿ESTÁ TODO INSTALADO?
--
-- QUÉ VER: la columna "estado" en ✅. Cada ❌ dice al lado qué archivo
-- hay que correr para arreglarlo.
-- ================================================================
with piezas as (
  select 'Inventario · productos'          as pieza, to_regclass('public.productos')        is not null as ok, 'los cimientos' as arreglo union all
  select 'Fechas de vencimiento',                    to_regclass('public.producto_lotes')   is not null, '2026-07-lotes-vencimiento.sql' union all
  select 'Recetas',                                  to_regclass('public.recetas')          is not null, '2026-07-fase1-recetas-modo-prueba.sql' union all
  select 'Repartos',                                 to_regclass('public.repartos')         is not null, '2026-07-repartos.sql' union all
  select 'Historial contado a mano',                 to_regclass('public.historial')        is not null, 'los cimientos' union all
  select 'Foto automática 15:00 y 22:00',            to_regclass('public.historial_auto')   is not null, '2026-08-respaldo-automatico-de-verdad.sql' union all
  select 'Libro de movimientos y mermas',            to_regclass('public.movimientos')      is not null, '2026-08-bodega-cimientos.sql' union all
  select 'Enlace bodega y locales',                  to_regclass('public.producto_enlace')  is not null, '2026-08-bodega-cimientos.sql' union all
  select 'Quién entra a Ajustes',                    to_regclass('public.app_permisos')     is not null, '2026-08-ajustes-quien-entra.sql' union all
  select 'Interruptores',                            to_regclass('public.ajustes')          is not null, '2026-08-interruptores.sql' union all
  select 'Metas de venta',                           to_regclass('public.metas')            is not null, '2026-08-metas-de-venta.sql' union all
  select 'Secciones y turnos editables',             to_regclass('public.secciones')        is not null, '2026-08-secciones-y-fudo-desde-ajustes.sql' union all
  select 'Categorías de Fudo',                       to_regclass('public.fudo_categorias')  is not null, '2026-08-categorias-de-fudo.sql' union all
  select 'Registro de restauraciones',               to_regclass('public.restauraciones')   is not null, '2026-08-restaurar-una-sede.sql' union all
  select 'Registro de fusiones',                     to_regclass('public.fusiones')         is not null, '2026-08-fusionar-duplicados.sql' union all
  select 'Cuaderno de migraciones',                  to_regclass('public.migraciones_aplicadas') is not null, '2026-07-registro-de-migraciones.sql' union all
  select 'Lista de días con foto',
         exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='fotos_por_dia'), '2026-08-dias-con-foto.sql' union all
  select 'Motor de descuento · UNA sola versión',
         (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
           where n.nspname='public' and p.proname='fudo_procesar_item') = 1,
         '2026-07-URGENTE-dos-motores.sql  (si hay dos, la app no descuenta nada)' union all
  select 'El stock no puede ser negativo',
         exists(select 1 from pg_constraint
                 where conrelid='public.productos'::regclass and contype='c'),
         '2026-07-tope-cero-sin-excepcion.sql' union all
  select 'Personas · se puede dar acceso desde la app',
         exists(select 1 from pg_policies where schemaname='public'
                 and tablename='app_permisos' and cmd='UPDATE'),
         '2026-08-permisos-desde-la-app.sql  (sin esto el permiso dice que guarda y no guarda)' union all
  select 'Fudo · se puede cambiar el modo desde la app',
         exists(select 1 from pg_policies where schemaname='public'
                 and tablename='fudo_sync' and 'authenticated' = any(roles)),
         '2026-08-secciones-y-fudo-desde-ajustes.sql' union all
  select 'Las fechas viajan en vivo a los otros teléfonos',
         exists(select 1 from pg_publication_tables
                 where pubname='supabase_realtime' and tablename='producto_lotes'),
         '2026-07-fechas-en-vivo-y-limpieza.sql'
)
select pieza,
       case when ok then '✅' else '❌ FALTA' end as estado,
       case when ok then '' else arreglo end     as que_hacer
from piezas
order by ok, pieza;


-- ================================================================
-- BLOQUE 2 — ¿ESTÁN CORRIENDO LOS RELOJES?  (otro Run)
--
-- QUÉ VER: tres tareas, las tres con "activa" en true.
--   · una cada 15 minutos  -> el ciclo con Fudo
--   · '0 19 * * *'         -> la foto de las 15:00 (Antofagasta)
--   · '0 2 * * *'          -> la foto de las 22:00
--
-- Si da error diciendo que `cron.job` no existe, es que pg_cron no está
-- instalado: Supabase -> Database -> Extensions -> pg_cron.
-- ================================================================
select jobname as tarea, schedule as cada_cuando, active as activa
from cron.job
order by jobname;


-- ================================================================
-- BLOQUE 3 — ¿QUÉ CONTESTARON LAS ÚLTIMAS CORRIDAS?  (otro Run)
--
-- ⚠️ ESTE BLOQUE ES EL QUE IMPORTA, aunque parezca el menos vistoso. Los
-- relojes del bloque 2 pueden estar los cuatro en `activa = true` y aun así
-- no estar haciendo nada: "activa" quiere decir que el reloj SUENA, no que
-- lo que llama esté funcionando. Esto mira lo que contestaron de verdad.
--
-- (La primera versión decía `r.status` y esa columna se llama
-- `status_code`. Un nombre escrito de memoria en vez de copiado tumba la
-- consulta entera.)
--
-- QUÉ VER: `codigo` en 200. Si dice 500 y el texto habla de
-- "SISTEMA_TOKEN", falta ese secreto:
--   Supabase -> Edge Functions -> Secrets -> SISTEMA_TOKEN
--   (cualquier texto largo inventado)
--
-- Si no devuelve ninguna fila, ninguna tarea llamó todavía a nada.
-- ================================================================
select r.created as cuando, r.status_code as codigo,
       left(r.content, 240) as que_contesto
from net._http_response r
order by r.created desc
limit 12;
