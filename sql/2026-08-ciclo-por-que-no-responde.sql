-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr el 1, ESPERAR 20 segundos, correr el 2.
--  TARDA:     el 1 es instantáneo; la respuesta demora unos segundos
--  QUÉ HACE:  llama a fudo-ciclo desde la base y trae su respuesta cruda.
--             No toca Fudo si la función no existe.
--  QUÉ VER:   en el bloque 2, "codigo" y "respuesta".
-- ================================================================
--
-- POR QUÉ ESTE ARCHIVO. El aviso de la app decía "Failed to send a
-- request to the Edge Function". Eso NO es un rechazo de Fudo: es que la
-- llamada no llegó a destino. Llamando desde acá se salta el navegador y
-- se ve el código que contesta el servidor, que es lo que distingue las
-- causas.
--
-- ⚠️ Y una corrección mía: la comprobación anterior filtraba las
-- respuestas que dijeran "empuje". Un 404 no dice "empuje", así que
-- salía como "sin resultados" — o sea, el mismo vacío para "no corrió"
-- que para "falló". Estaba mal hecha. Esta trae la respuesta cruda.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LLAMARLA
-- Devuelve un número, que es solo el comprobante. La respuesta va abajo.
-- ================================================================
select net.http_post(
  url := 'https://fqjdecjsbnicvyrxkxcu.supabase.co/functions/v1/fudo-ciclo?sede=plaza&origen=cron',
  headers := jsonb_build_object(
    'Authorization', 'Bearer sb_publishable_P5TfG3nhMG3oNT9VLs16_w_iKHvktwl',
    'Content-Type',  'application/json'),
  body := '{}'::jsonb
) as comprobante;


-- ================================================================
-- BLOQUE 2 — LA RESPUESTA CRUDA  (esperar 20 segundos)
--
-- QUÉ VER, en "codigo":
--
--   404  -> la función NO está desplegada, o quedó con otro nombre.
--           Tiene que llamarse exactamente  fudo-ciclo
--           (Edge Functions -> el nombre se ve en la lista)
--
--   401  -> está desplegada pero pide sesión. Se apaga en:
--           Edge Functions -> fudo-ciclo -> Details -> "Verify JWT" -> off
--           (fudo-sync-ventas ya está así, por eso el cron de julio andaba)
--
--   200 / 502 -> la función SÍ contestó. Ahí la columna "respuesta" trae
--           el detalle de los dos pasos y ya sabemos dónde mirar.
--
-- Si las filas son viejas, esperar otro poco y correr SOLO este bloque.
-- ================================================================
select created      as cuando,
       status_code  as codigo,
       left(content, 900) as respuesta
from net._http_response
order by created desc
limit 5;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-ciclo-por-que-no-responde.sql', 'Jhon', 'lo corrió Jhon',
        'SOLO LECTURA: llama a fudo-ciclo desde la base y trae la respuesta cruda, para distinguir 404 (no desplegada) de 401 (pide sesión)')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
