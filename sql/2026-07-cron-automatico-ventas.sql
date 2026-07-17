-- ================================================================
-- AUTOMÁTICO: correr el puente de ventas cada 15 min (julio 2026)
--
-- OPCIÓN A (recomendada): usar el panel de Supabase → "Cron".
--   No necesitas este SQL. Ver instrucciones en el chat.
--
-- OPCIÓN B (este archivo): agendar con pg_cron por SQL.
--   Reemplaza <PROJECT_REF> y <ANON_KEY> por los de tu proyecto:
--     * PROJECT_REF: está en la URL de tu proyecto (xxxx.supabase.co)
--     * ANON_KEY: Project Settings → API → "anon public"
--   (La anon key es pública — ya viaja en la app — así que va bien aquí.)
-- ================================================================

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Plaza: cada 15 minutos
select cron.schedule(
  'sync-ventas-plaza',
  '*/15 * * * *',
  $$
  select net.http_post(
    url     := 'https://<PROJECT_REF>.supabase.co/functions/v1/fudo-sync-ventas?sede=plaza',
    headers := jsonb_build_object(
                 'Authorization', 'Bearer <ANON_KEY>',
                 'Content-Type',  'application/json'),
    body    := '{}'::jsonb
  );
  $$
);

-- (Cuando sincronices Angamos, se duplica cambiando el nombre y ?sede=angamos)

-- Ver los cron agendados:
--   select jobid, schedule, jobname from cron.job;
-- Borrar el de plaza si hace falta:
--   select cron.unschedule('sync-ventas-plaza');
