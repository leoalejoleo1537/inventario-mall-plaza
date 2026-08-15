-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--             (pero ANTES hay dos pasos en Edge Functions, ver abajo)
--  ES:        4 bloques. Correr UNO POR UNO. Entre el 2 y el 3 hay que
--             esperar ~20 minutos.
--  TARDA:     los bloques son instantáneos; la espera es la que cuesta
--  QUÉ HACE:  hace que cada 15 minutos, solo, se lean las ventas de Fudo
--             y DESPUÉS se le mande el inventario entero. En las dos
--             sedes.
--  QUÉ VER:   el bloque 4: las dos tareas agendadas y las dos sedes con
--             su última corrida diciendo "cron".
-- ================================================================
--
-- POR QUÉ, en una frase tuya: "no podemos ir parchando estos fallos de
-- 'no se subió los cannolis'".
--
-- Hasta hoy Fudo se enteraba de lo que entraba por avisos sueltos, uno
-- por cada línea de reparto. Cada aviso podía fallar, y cuando fallaba
-- no se notaba: el número de Fudo se quedaba viejo y nadie tenía motivo
-- para sospechar.
--
-- Un empuje entero cada 15 minutos **no necesita acertar todas las
-- veces**: manda el total, así que la corrida siguiente corrige sola lo
-- que la anterior no hizo. Se cambia "no puede fallar nunca" por "se
-- arregla solo".
--
-- EL ORDEN IMPORTA Y NO ES NEGOCIABLE: primero se leen las ventas y se
-- descuenta, y recién después se empuja. Al revés, se le mandaría a Fudo
-- un stock que todavía no descontó lo vendido, y Fudo volvería a subir
-- algo que ya se vendió. Por eso las dos cosas van dentro de UNA sola
-- función que se espera a sí misma: dos tareas agendadas por separado no
-- garantizan el orden.
--
-- ⚠️ ESTO REEMPLAZA a la tarea `sync-ventas-plaza` de julio. No se
-- pierde nada: leer las ventas es el paso 1 del ciclo, y sigue avisando
-- que la disparó el cron, así que la franja de alarma del motor sigue
-- funcionando igual. Dejar las dos sería llamar dos veces por gusto.
-- ================================================================
--
-- ================================================================
-- PASO 0 — ESTO VA UNA SOLA VEZ, Y NO ES SQL
--
--  a) Supabase -> Edge Functions -> Secrets -> New secret
--       nombre:  SISTEMA_TOKEN
--       valor:   cualquier texto largo inventado, mientras más raro mejor
--                (ej: café-desierto-reloj-9x7k2m-2026)
--
--     PARA QUÉ SIRVE, sin tecnicismos: empujar a Fudo exige permiso, y el
--     permiso hoy es "tal correo puede". Pero el reloj no tiene correo.
--     Este token es su credencial. Vive dentro de Supabase y **no aparece
--     en ningún lado de este archivo**: la tarea agendada no lo conoce.
--
--  b) Supabase -> Edge Functions -> Deploy a new function
--       nombre EXACTO:  fudo-ciclo
--       pegar el contenido de supabase/functions/fudo-ciclo/index.ts
--
--  c) Volver a desplegar `fudo-empujar-stock` con la versión nueva
--     (es la que aprende a reconocer ese token).
--
-- Sin la (a) el ciclo lee las ventas pero no empuja, y te lo dice con
-- todas las letras en vez de fallar callado.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — VER QUÉ HAY AGENDADO HOY
--
-- Antes de tocar nada. QUÉ VER: si aparece `sync-ventas-plaza`, es la
-- tarea de julio y el bloque 2 la va a reemplazar. Si aparece algo más
-- que no reconozcas, páralo acá y me lo mandas.
-- ================================================================
select jobname, schedule, active, command
from cron.job
order by jobname;


-- ================================================================
-- BLOQUE 2 — AGENDAR EL CICLO EN LAS DOS SEDES
--
-- Las dos van cada 15 minutos pero DESFASADAS 7 minutos, para no
-- golpear la API de Fudo con las dos sedes en el mismo segundo.
--
-- Plaza  : en punto, y cada 15   (00 15 30 45)
-- Angamos: siete minutos después (07 22 37 52)
-- ================================================================
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- La de julio se retira: su trabajo es ahora el paso 1 del ciclo.
select cron.unschedule('sync-ventas-plaza')
 where exists (select 1 from cron.job where jobname = 'sync-ventas-plaza');

-- Y las nuevas, por si este bloque se corre dos veces.
select cron.unschedule('ciclo-fudo-plaza')
 where exists (select 1 from cron.job where jobname = 'ciclo-fudo-plaza');
select cron.unschedule('ciclo-fudo-angamos')
 where exists (select 1 from cron.job where jobname = 'ciclo-fudo-angamos');

select cron.schedule(
  'ciclo-fudo-plaza',
  '0,15,30,45 * * * *',
  'select net.http_post(url := ''https://fqjdecjsbnicvyrxkxcu.supabase.co/functions/v1/fudo-ciclo?sede=plaza&origen=cron'', headers := jsonb_build_object(''Authorization'', ''Bearer sb_publishable_P5TfG3nhMG3oNT9VLs16_w_iKHvktwl'', ''Content-Type'', ''application/json''), body := ''{}''::jsonb);'
);

select cron.schedule(
  'ciclo-fudo-angamos',
  '7,22,37,52 * * * *',
  'select net.http_post(url := ''https://fqjdecjsbnicvyrxkxcu.supabase.co/functions/v1/fudo-ciclo?sede=angamos&origen=cron'', headers := jsonb_build_object(''Authorization'', ''Bearer sb_publishable_P5TfG3nhMG3oNT9VLs16_w_iKHvktwl'', ''Content-Type'', ''application/json''), body := ''{}''::jsonb);'
);

-- QUÉ VER: dos filas, active = true, y ninguna llamada `sync-ventas-plaza`.
select jobname, schedule, active from cron.job order by jobname;


-- ================================================================
-- BLOQUE 3 — ESPERAR ~20 MINUTOS Y MIRAR LA RESPUESTA
--
-- ⚠️ No correrlo antes: el ciclo todavía no habrá salido.
--
-- QUÉ VER, en la columna "empuje":
--   · "actualizados": N   -> está funcionando. Ese N es cuántos productos
--     de Fudo se corrigieron en esa pasada.
--   · un error con SISTEMA_TOKEN -> falta el paso 0-a.
--   · un 401 o 403 -> el token está creado pero `fudo-empujar-stock`
--     todavía es la versión vieja: falta el paso 0-c.
-- ================================================================
select created                                        as cuando,
       status_code                                    as codigo,
       case when content ~ '^\s*\{' then content::jsonb ->> 'sede'   end as sede,
       case when content ~ '^\s*\{' then content::jsonb -> 'ventas'  end as ventas,
       case when content ~ '^\s*\{' then content::jsonb -> 'empuje'  end as empuje,
       case when content ~ '^\s*\{' then content::jsonb ->> 'error'  end as error
from net._http_response
where content like '%"empuje"%' or content like '%SISTEMA_TOKEN%'
order by created desc
limit 6;


-- ================================================================
-- BLOQUE 4 — COMPROBACIÓN FINAL
--
-- QUÉ VER: las dos sedes con `la_disparo = cron` y una hora reciente.
-- Eso confirma que el paso 1 del ciclo (leer ventas) está corriendo
-- solo; el bloque 3 confirma el paso 2 (empujar).
-- ================================================================
select sede,
       ultima_corrida_at   as ultima_vez,
       ultima_corrida_por  as la_disparo,
       ultimo_resultado    as como_le_fue,
       ultimos_items       as items,
       ultimos_errores     as con_error,
       modo,
       cron_activo
from public.fudo_sync
order by sede;


-- ================================================================
-- CÓMO SE APAGA, si alguna vez hace falta
--
--   select cron.unschedule('ciclo-fudo-plaza');
--   select cron.unschedule('ciclo-fudo-angamos');
--
-- Apagarlo no rompe nada: se vuelve al botón, como antes.
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-ciclo-fudo-automatico.sql', 'Jhon', 'lo corrió Jhon',
        'Cada 15 min: lee las ventas de Fudo, descuenta, y después empuja el inventario entero. Plaza y Angamos, desfasadas. Reemplaza a sync-ventas-plaza')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
