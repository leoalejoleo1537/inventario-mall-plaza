-- ================================================================
-- ENCENDER EL CRON — que la sincronización corra sola cada 15 minutos
--
-- La imagen: hasta ahora el inventario se pone al día cuando alguien
-- aprieta ⟳, como regar las plantas a mano. Esto instala el riego
-- automático. Y el paso 3 enciende el sensor que avisa si el riego se
-- corta — sin ese sensor, un riego automático roto es PEOR que regar a
-- mano, porque nadie mira.
--
-- ⚠️ VAN EN ORDEN Y CON ESPERA EN EL MEDIO. El paso 3 no se corre hasta
-- que el paso 2 confirme que el cron corrió solo al menos una vez. Si
-- se enciende el sensor antes, la app se pone roja mientras todavía no
-- hay nada que avisar.
--
-- Escrito SIN comillas de dólar a propósito: la versión anterior de
-- este archivo las usaba, y el editor de Supabase responde "No se pudo
-- obtener" sin llegar a ejecutar (§3.5). Los datos del proyecto van ya
-- rellenados — no hay que reemplazar nada a mano.
-- ================================================================


-- ================================================================
-- PASO 1 — AGENDAR (correr esto solo)
--
-- QUÉ HACE: le dice a la base "cada 15 minutos, llama al motor de
-- ventas". No toca stock, ni recetas, ni productos.
-- SI SALE MAL: no queda agendado y todo sigue como hoy, con el botón.
-- ================================================================
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Si ya existía uno con este nombre se borra, para no dejar dos corriendo.
-- (Dos no romperían el stock —el motor no descuenta dos veces— pero
-- ensucian el registro y duplican las llamadas.)
select cron.unschedule('sync-ventas-plaza')
where exists (select 1 from cron.job where jobname = 'sync-ventas-plaza');

select cron.schedule(
  'sync-ventas-plaza',
  '*/15 * * * *',
  'select net.http_post(url := ''https://fqjdecjsbnicvyrxkxcu.supabase.co/functions/v1/fudo-sync-ventas?sede=plaza&origen=cron'', headers := jsonb_build_object(''Authorization'', ''Bearer sb_publishable_P5TfG3nhMG3oNT9VLs16_w_iKHvktwl'', ''Content-Type'', ''application/json''), body := ''{}''::jsonb);'
);

-- Comprobación: tiene que salir UNA fila, con schedule */15 y active = true
select jobname, schedule, active from cron.job where jobname = 'sync-ventas-plaza';


-- ================================================================
-- PASO 2 — ESPERAR 20 MINUTOS Y COMPROBAR (correr solo esto)
--
-- Tiene que decir 'cron' en la columna la_disparo. Si dice 'boton', el
-- cron todavía no ha corrido: esperar otro rato. Si a los 40 minutos
-- sigue diciendo 'boton', avisar y NO seguir al paso 3.
-- ================================================================
select sede,
       ultima_corrida_at   as ultima_vez,
       ultima_corrida_por  as la_disparo,
       ultimo_resultado    as como_le_fue,
       ultimos_items       as items,
       ultimos_errores     as con_error,
       cron_activo         as sensor_encendido
from public.fudo_sync where sede = 'plaza';


-- ================================================================
-- PASO 3 — ENCENDER EL SENSOR (solo después de que el paso 2 diga 'cron')
--
-- QUÉ HACE: le avisa a la app que de ahora en más la sincronización es
-- automática. Desde ese momento, si pasan 45 minutos sin que el motor
-- corra, la app muestra una franja roja sola.
-- CÓMO SE APAGA:
--   update public.fudo_sync set cron_activo = false where sede = 'plaza';
-- ================================================================
update public.fudo_sync set cron_activo = true where sede = 'plaza';

select sede, cron_activo as sensor_encendido from public.fudo_sync where sede = 'plaza';


-- ================================================================
-- SI HAY QUE APAGAR TODO
--   select cron.unschedule('sync-ventas-plaza');
--   update public.fudo_sync set cron_activo = false where sede = 'plaza';
--
-- PARA ANGAMOS, cuando toque: se repite el paso 1 cambiando el nombre a
-- 'sync-ventas-angamos' y sede=angamos en la dirección. El sensor NO se
-- enciende hasta que esa sede pase a modo real (§9).
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-07-cron-automatico-ventas.sql', 'Jhon', 'lo corrió Jhon',
        'Sincronización automática cada 15 min en plaza, con el aviso encendido')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
