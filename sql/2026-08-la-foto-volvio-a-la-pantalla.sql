-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        YA SE CORRIÓ el 2026-08-28. Queda como registro.
--  TARDA:     instantáneo
--  QUÉ HACE:  devuelve a las dos tareas automáticas la instrucción
--             completa (la que escribe en `historial`, que es lo que mira
--             la pestaña Historial) y rellena el 26 y el 27.
--  QUÉ VER:   el bloque 1 deja 2 filas, las dos con SÍ.
-- ================================================================
--
-- QUÉ PASÓ, Y ES LA REGLA §0.1.2 CON OTRA CARA
--
-- La pestaña Historial de Mall Plaza se cortaba el 25-08 y ya era 28.
--
-- Lo que NO era, y saberlo cambió el diagnóstico: la tarea no estaba
-- caída. Corrió los dos días y dejó sus filas en `historial_auto`. Como la
-- instrucción es UNA sola —borra el día, escribe en `historial`, escribe
-- en `historial_auto`— y Postgres deshace todo junto si algo revienta, el
-- hecho de que el respaldo SÍ tuviera el 26 y el 27 probaba que la parte
-- de `historial` **no había fallado: no se estaba ejecutando.**
--
-- Lo que era: la tarea agendada había vuelto a una versión ANTERIOR, la de
-- `2026-08-respaldo-automatico-de-verdad.sql`, que solo escribe en
-- `historial_auto`. Volver a correr un archivo viejo del repo reemplaza la
-- tarea, porque `cron.schedule` con el mismo nombre pisa lo que había.
--
-- Se comprobó **leyendo la instrucción instalada**, no contando tareas:
--
--   select jobname, active,
--          case when command like '%into public.historial (%'
--               then 'SÍ' else 'NO' end as escribe_foto_manual
--     from cron.job where jobname like 'foto-inventario%';
--
-- Es la misma técnica del apagado de la reposición automática (§0.2.1):
-- contar no alcanza, hay que mirar el cuerpo.
--
-- POR QUÉ NO SE PERDIÓ NADA
--
-- Porque había DOS redes y solo se cayó una. `historial_auto` guardaba
-- nombre, sección, stock, mínimo, máximo y si estaba activo — todo lo que
-- hace falta para reconstruir (§0.6). El 26 y el 27 se devolvieron desde
-- ahí, usando la foto de las 22:00, que es el estado con que cerró el día.
--
-- ⚠️ LO QUE HAY QUE HACER PARA QUE NO VUELVA A PASAR
--
-- Los dos archivos viejos que agendan estas mismas tareas llevan ahora un
-- aviso arriba diciendo que NO se corran. Son:
--     sql/2026-08-central-historial-automatico.sql
--     sql/2026-08-respaldo-automatico-de-verdad.sql
-- El bueno es este. Si algún día hay que reagendar la foto, es este.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA INSTRUCCIÓN COMPLETA, DE VUELTA
--
-- No borra nada de lo ya guardado: solo reemplaza qué van a hacer las
-- tareas de mañana en adelante.
--
-- ⚠️ pg_cron trabaja en UTC. Chile en agosto va en UTC−4:
--       15:00 en Antofagasta = 19:00 UTC · 22:00 = 02:00 UTC del día siguiente
--    La fecha que se guarda usa la hora de Chile, así que la de las 22:00
--    queda con el día correcto.
--
-- QUÉ VER: dos filas, las dos con escribe_foto_manual = SÍ.
-- ================================================================
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

select jobname as tarea, active as activa,
       case when command like '%into public.historial (%' then 'SÍ' else 'NO' end as escribe_foto_manual
  from cron.job
 where jobname like 'foto-inventario%'
 order by jobname;


-- ================================================================
-- BLOQUE 2 — LA VISTA PREVIA DEL RELLENO  (no escribe)
--
-- Va antes del bloque 3 y usa EXACTAMENTE el mismo filtro que él. Si los
-- dos filtros no fueran idénticos, la vista previa mentiría por omisión —
-- que es lo que pasó el 9 de agosto y por eso está escrito como regla
-- (§0.6, punto 3).
-- ================================================================
select a.sede, a.fecha, count(*) as se_agregarian
  from public.historial_auto a
 where a.momento = 'noche'
   and a.fecha in (date '2026-08-26', date '2026-08-27')
   and a.activo = 'SÍ'
   and not exists (select 1 from public.historial h
                    where h.sede = a.sede and h.fecha = a.fecha
                      and h.producto_id = a.producto_id)
 group by a.sede, a.fecha
 order by a.fecha, a.sede;


-- ================================================================
-- BLOQUE 3 — EL RELLENO  (ESTE SÍ ESCRIBE)
--
-- Escribe en `historial` los días 26 y 27, copiados del respaldo de las
-- 22:00. No toca ningún stock: `historial` es un libro de fotos.
--
-- CÓMO SE DESHACE: esos dos días estaban vacíos antes de esto, así que
-- borrarlos devuelve el estado exacto de antes.
--     delete from public.historial where fecha in (date '2026-08-26', date '2026-08-27');
--
-- QUÉ VER: 8 filas con los mismos números que dio el bloque 2.
-- Corrido el 2026-08-28: 26 -> angamos 247, bodega 351, central 259,
-- plaza 257 · 27 -> angamos 242, bodega 351, central 260, plaza 258.
-- Calzó exacto con la vista previa.
-- ================================================================
insert into public.historial
       (fecha, sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max)
select a.fecha, a.sede, a.producto_id, a.producto, a.rubro,
       a.stock_actual, a.stock_min, a.stock_max
  from public.historial_auto a
 where a.momento = 'noche'
   and a.fecha in (date '2026-08-26', date '2026-08-27')
   and a.activo = 'SÍ'
   and not exists (select 1 from public.historial h
                    where h.sede = a.sede and h.fecha = a.fecha
                      and h.producto_id = a.producto_id);

select fecha, sede, count(*) as productos
  from public.historial
 where fecha in (date '2026-08-26', date '2026-08-27')
 group by fecha, sede
 order by fecha, sede;


-- ================================================================
-- QUEDA PENDIENTE, Y ES DECISIÓN DE JHON
--
-- La instrucción empieza borrando la foto del día. O sea: si el equipo
-- cuenta y guarda a las 10:00, a las 15:00 la tarea la reemplaza por el
-- stock de esa hora. Para restaurar da igual —es una foto válida del día—
-- pero no es la que ellos contaron.
--
-- Se puede hacer que la automática no pise a la manual. No se cambió
-- porque nadie lo pidió, y cambiar un comportamiento que no se pidió es un
-- riesgo que nadie aceptó.
-- ================================================================


insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-la-foto-volvio-a-la-pantalla.sql', 'Jhon', 'lo corrió Jhon',
        'Las tareas foto-inventario volvieron a escribir en historial (habían vuelto a una versión vieja que solo escribía en historial_auto). Rellenados el 26 y el 27 desde el respaldo de las 22:00')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
