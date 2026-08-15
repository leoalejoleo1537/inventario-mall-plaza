-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo (el bloque 2 guarda de verdad, ~2 segundos)
--  QUÉ HACE:  el respaldo automático de las 15:00 y las 22:00 pasa a
--             guardarse DONDE TÚ LO MIRAS: en la pestaña Historial.
--  QUÉ VER:   el bloque 2 tiene que dejar la fecha de HOY en la lista del
--             Historial, en las tres sedes.
-- ================================================================
--
-- POR QUÉ NO LO VEÍAS, y la culpa es mía por no haberlo hecho así de
-- entrada:
--
--   El respaldo SÍ se estaba guardando. Corrió a las 02:00 y volvió a
--   correr a las 15:00. Pero lo guardaba en una tabla aparte
--   (`historial_auto`) que la pantalla de Historial no mira. O sea:
--   existía un salvavidas que no se veía por ninguna parte.
--
--   Un respaldo que no se ve no sirve para lo que tiene que servir, que
--   es que abras la app y sepas, sin preguntarle a nadie, que si algo se
--   rompe hay de dónde volver.
--
-- QUÉ CAMBIA: la misma tarea, a las mismas horas, ahora escribe en
-- `historial` — la misma tabla que llena el botón "Guardar inventario de
-- hoy". Así la fecha de hoy aparece sola en esa lista, todos los días,
-- sin que nadie apriete nada.
--
-- Y SIGUE ESCRIBIENDO en `historial_auto`, que guarda además los
-- productos ELIMINADOS. Esa es la red completa; `historial` es la que se
-- ve. Las dos salen de la misma pasada.
--
-- ⚠️ LO ÚNICO QUE HAY QUE SABER: la foto del día se REEMPLAZA. Si el
-- equipo guardó el inventario a mano en la mañana, la foto de las 15:00
-- la reemplaza con el estado de esa hora, y la de las 22:00 con el de la
-- noche. Queda siempre la más fresca del día, que es lo que sirve para
-- volver atrás.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — QUÉ TAREAS HAY HOY
-- QUÉ VER: las dos fotos y los dos ciclos. Nada más.
-- ================================================================
select jobname, schedule, active from cron.job order by jobname;


-- ================================================================
-- BLOQUE 2 — GUARDAR AHORA MISMO, para verlo en la app enseguida
--
-- Es la MISMA instrucción que va a correr la tarea. Si esta anda, la
-- automática anda.
--
-- QUÉ VER: la última consulta devuelve una fila por sede con la fecha de
-- hoy. Y en el teléfono, entrando a Historial, tiene que aparecer hoy.
-- ================================================================
delete from public.historial
 where fecha = (now() at time zone 'America/Santiago')::date;

insert into public.historial (fecha, sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max)
select (now() at time zone 'America/Santiago')::date,
       p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max
from public.productos p
where p.activo = 'SÍ';

insert into public.historial_auto
       (sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max, activo, momento, fecha)
select p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max, p.activo,
       'tarde', (now() at time zone 'America/Santiago')::date
from public.productos p
on conflict (sede, producto_id, fecha, momento) do update
   set producto = excluded.producto, rubro = excluded.rubro,
       stock_actual = excluded.stock_actual, stock_min = excluded.stock_min,
       stock_max = excluded.stock_max, activo = excluded.activo, tomada_at = now();

select sede, fecha, count(*) as productos
from public.historial
where fecha = (now() at time zone 'America/Santiago')::date
group by sede, fecha
order by sede;


-- ================================================================
-- BLOQUE 3 — REAGENDAR LAS DOS FOTOS
--
-- Mismas horas de siempre: 15:00 y 22:00 de Antofagasta, que en UTC son
-- las 19:00 y las 02:00. Lo que cambia es qué escriben.
--
-- QUÉ VER: dos filas, active = true, con 0 19 y 0 2.
-- ================================================================
create extension if not exists pg_cron;

select cron.unschedule('foto-inventario-tarde')
 where exists (select 1 from cron.job where jobname = 'foto-inventario-tarde');
select cron.unschedule('foto-inventario-noche')
 where exists (select 1 from cron.job where jobname = 'foto-inventario-noche');

select cron.schedule('foto-inventario-tarde', '0 19 * * *',
 'delete from public.historial where fecha = (now() at time zone ''America/Santiago'')::date; insert into public.historial (fecha, sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max) select (now() at time zone ''America/Santiago'')::date, p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max from public.productos p where p.activo = ''SÍ''; insert into public.historial_auto (sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max, activo, momento, fecha) select p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max, p.activo, ''tarde'', (now() at time zone ''America/Santiago'')::date from public.productos p on conflict (sede, producto_id, fecha, momento) do update set producto = excluded.producto, rubro = excluded.rubro, stock_actual = excluded.stock_actual, stock_min = excluded.stock_min, stock_max = excluded.stock_max, activo = excluded.activo, tomada_at = now();'
);

select cron.schedule('foto-inventario-noche', '0 2 * * *',
 'delete from public.historial where fecha = (now() at time zone ''America/Santiago'')::date; insert into public.historial (fecha, sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max) select (now() at time zone ''America/Santiago'')::date, p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max from public.productos p where p.activo = ''SÍ''; insert into public.historial_auto (sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max, activo, momento, fecha) select p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max, p.activo, ''noche'', (now() at time zone ''America/Santiago'')::date from public.productos p on conflict (sede, producto_id, fecha, momento) do update set producto = excluded.producto, rubro = excluded.rubro, stock_actual = excluded.stock_actual, stock_min = excluded.stock_min, stock_max = excluded.stock_max, activo = excluded.activo, tomada_at = now();'
);

select jobname, schedule, active from cron.job
 where jobname like 'foto-inventario%' order by jobname;


-- ================================================================
-- CÓMO SE COMPRUEBA CUALQUIER DÍA, sin entrar acá: abrir la app, pestaña
-- Historial. Si la fecha de hoy está en la lista, el respaldo corrió.
-- Esa es toda la comprobación, y por eso tenía que estar ahí.
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-respaldo-visible-en-la-app.sql', 'Jhon', 'lo corrió Jhon',
        'El respaldo automático de las 15:00 y 22:00 pasa a escribir en historial, que es lo que muestra la pestaña Historial. Sigue llenando historial_auto con los eliminados')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
