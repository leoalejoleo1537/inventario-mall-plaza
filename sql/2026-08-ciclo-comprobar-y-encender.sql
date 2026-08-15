-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques cortos. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  el 1 solo mira. El 2 enciende el aviso de Angamos.
--  QUÉ VER:   en el bloque 1, la columna "empuje".
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ⭐ ¿EL EMPUJE OCURRIÓ DE VERDAD?
--
-- Es lo único que todavía no está comprobado. Que la tarea esté agendada
-- dice que va a llamar; esto dice qué contestó.
--
-- QUÉ VER, en la columna "empuje":
--   · {"actualizados": N, ...}       -> ANDA. Ese N es cuántos productos
--     de Fudo se corrigieron en esa pasada. Puede ser 0 y estar perfecto:
--     significa que ya estaban todos iguales.
--   · {"error": "...SISTEMA_TOKEN"}  -> falta el secret
--   · {"error": "...", "status":401} -> `fudo-empujar-stock` quedó en la
--     versión vieja, hay que volver a desplegarla
--   · sin filas                      -> todavía no ha salido ninguna
--     pasada; esperar al minuto 00/15/30/45 (plaza) o 07/22/37/52
--     (angamos) y volver a correr SOLO este bloque
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
limit 8;


-- ================================================================
-- BLOQUE 2 — ENCENDER EL AVISO DE ANGAMOS
--
-- `cron_activo` no enciende ni apaga nada del ciclo: es el interruptor
-- del AVISO. Con él en false, la app no se queja aunque pasen horas sin
-- corridas — que era lo correcto cuando Angamos no tenía tarea agendada.
-- Ahora sí la tiene, así que un silencio largo sí es algo que hay que
-- mirar, y la franja de la pantalla tiene que poder decirlo.
--
-- ⚠️ Correr esto SOLO después de haber visto en el bloque 1 que el ciclo
-- de Angamos contestó. Encenderlo antes pone la app en rojo sin motivo,
-- que es el error que ya se cometió una vez en julio.
--
-- QUÉ VER: las dos sedes con cron_activo = true.
-- ================================================================
update public.fudo_sync
   set cron_activo = true
 where sede in ('plaza','angamos');

select sede, ultima_corrida_at as ultima_vez, ultima_corrida_por as la_disparo,
       ultimo_resultado as como_le_fue, modo, cron_activo
from public.fudo_sync
order by sede;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-ciclo-comprobar-y-encender.sql', 'Jhon', 'lo corrió Jhon',
        'Comprueba que el empuje automático contestó, y enciende el aviso (cron_activo) en las dos sedes')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
