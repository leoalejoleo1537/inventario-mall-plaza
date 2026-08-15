-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo (el bloque 3 saca una foto de verdad, ~2 seg)
--  QUÉ HACE:  deja el inventario fotografiándose SOLO a las 15:00 y a las
--             22:00, en TODAS las sedes. No cambia ningún stock.
--  QUÉ VER:   el bloque 1 te dice si lo de antes quedó instalado o no.
--             El bloque 4 tiene que dar todo en SÍ.
-- ================================================================
--
-- POR QUÉ ESTE ARCHIVO EXISTE, y son DOS motivos distintos:
--
-- 1) DICES QUE NO FUNCIONA, y lo más probable es que nunca llegara a
--    instalarse. El archivo anterior tenía la función escrita con
--    comillas de dólar ($$) y las tareas con $q$ — que es justo lo que el
--    editor de Supabase no traga (§3.5). Cuando eso pasa, el bloque no se
--    ejecuta y el editor contesta con un error que no habla de SQL. El
--    bloque 1 de acá te lo dice con datos en vez de suposiciones.
--
--    Esta versión **no usa ninguna comilla de dólar y no crea ninguna
--    función**: la foto es una sola instrucción que la tarea corre
--    directo. Menos piezas, menos formas de fallar.
--
-- 2) Y ESTO ES MÁS IMPORTANTE: la versión anterior guardaba **solo el
--    stock**. Eso no alcanza para un respaldo.
--
--    Acordémonos de qué se perdió el 9 de agosto en Angamos: el stock,
--    **los mínimos**, los máximos y **la sección** de cada producto. Una
--    foto que solo guarda el stock no puede devolver ninguna de las otras
--    tres. Parecería un respaldo hasta el día que hiciera falta usarlo —
--    que es la peor clase de falla que tiene este proyecto.
--
--    Esta versión guarda: nombre, sección, stock, mínimo, máximo y si
--    estaba activo. Todo lo que hace falta para reconstruir.
--
-- ⚠️ NO reemplaza al botón "Guardar inventario de hoy". Ese sigue siendo
-- la foto que el equipo saca a mano después de contar, y es la que mira
-- la pestaña Historial. Esta es una red aparte, que no depende de que
-- nadie se acuerde.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ¿QUÉ HAY INSTALADO HOY DE VERDAD?
--
-- Antes de tocar nada. QUÉ VER:
--   · "tabla historial_auto"    NO  -> nunca se instaló
--   · "tareas agendadas"        0   -> nunca se agendó (lo más probable)
--   · "fotos guardadas"         0   -> se agendó pero nunca corrió
-- ================================================================
select 'tabla historial_auto' as pieza,
       case when to_regclass('public.historial_auto') is not null then 'SÍ' else 'NO' end as estado
union all
select 'tareas de foto agendadas',
       (select count(*)::text from cron.job where jobname like 'foto-inventario%')
union all
select 'función tomar_foto_inventario',
       (select count(*)::text from pg_proc p join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public' and p.proname = 'tomar_foto_inventario');


-- ================================================================
-- BLOQUE 2 — LA TABLA, CON TODO LO QUE HACE FALTA
--
-- Se crea si no está, y si ya estaba se le agregan las columnas que le
-- faltaban. Correrlo dos veces no rompe nada.
-- ================================================================
create table if not exists public.historial_auto (
  id           bigserial primary key,
  sede         text        not null,
  producto_id  bigint      not null references public.productos(id) on delete cascade,
  stock_actual double precision,
  momento      text        not null,          -- 'tarde' | 'noche'
  tomada_at    timestamptz not null default now(),
  fecha        date        not null default (now() at time zone 'America/Santiago')::date,
  constraint historial_auto_una_por_momento unique (sede, producto_id, fecha, momento)
);

-- Lo que le faltaba para ser un respaldo y no solo una medición.
alter table public.historial_auto add column if not exists producto  text;
alter table public.historial_auto add column if not exists rubro     text;
alter table public.historial_auto add column if not exists stock_min double precision;
alter table public.historial_auto add column if not exists stock_max double precision;
alter table public.historial_auto add column if not exists activo    text;

create index if not exists historial_auto_sede_fecha_idx
  on public.historial_auto(sede, fecha desc, momento);
create index if not exists historial_auto_producto_idx
  on public.historial_auto(producto_id, fecha desc);

alter table public.historial_auto enable row level security;
drop policy if exists "historial_auto all" on public.historial_auto;
create policy "historial_auto all" on public.historial_auto
  for all to anon, authenticated using (true) with check (true);
grant all on public.historial_auto to anon, authenticated;
grant usage, select on sequence public.historial_auto_id_seq to anon, authenticated;


-- ================================================================
-- BLOQUE 3 — SACAR UNA FOTO AHORA MISMO
--
-- Para no esperar a las 15:00 para saber si sirve. Es la MISMA
-- instrucción que va a correr la tarea, así que si esta anda, la
-- automática anda.
--
-- Ojo con dos cosas, que son decisiones:
--   · fotografía TODAS las sedes, sin nombrarlas — así una sede nueva
--     entra sola y nadie tiene que acordarse de agregarla.
--   · fotografía también los productos ELIMINADOS (activo = 'NO'). En
--     esta app eliminar no borra, desactiva; si alguien apaga algo por
--     error, el respaldo tiene que poder devolverlo.
--
-- QUÉ VER: un número. Es cuántos productos quedaron fotografiados.
-- ================================================================
insert into public.historial_auto
       (sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max, activo, momento, fecha)
select p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max, p.activo,
       'tarde', (now() at time zone 'America/Santiago')::date
from public.productos p
on conflict (sede, producto_id, fecha, momento) do update
   set producto = excluded.producto, rubro = excluded.rubro,
       stock_actual = excluded.stock_actual,
       stock_min = excluded.stock_min, stock_max = excluded.stock_max,
       activo = excluded.activo, tomada_at = now();

select sede, momento, count(*) as productos, max(tomada_at) as cuando
from public.historial_auto
group by sede, momento
order by sede, momento;


-- ================================================================
-- BLOQUE 4 — AGENDAR LAS DOS FOTOS Y COMPROBAR
--
-- ⚠️ pg_cron trabaja en UTC. Chile en agosto va en UTC−4:
--       15:00 en Antofagasta  =  19:00 UTC
--       22:00 en Antofagasta  =  02:00 UTC del día siguiente
--
-- La fecha que se guarda usa la hora de Chile, así que la foto de las
-- 22:00 queda con el día correcto aunque en UTC ya sea el día siguiente.
--
-- QUÉ VER: dos filas, active = true, con 0 19 y 0 2.
-- ================================================================
create extension if not exists pg_cron;

select cron.unschedule('foto-inventario-tarde')
 where exists (select 1 from cron.job where jobname = 'foto-inventario-tarde');
select cron.unschedule('foto-inventario-noche')
 where exists (select 1 from cron.job where jobname = 'foto-inventario-noche');

select cron.schedule('foto-inventario-tarde', '0 19 * * *',
 'insert into public.historial_auto (sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max, activo, momento, fecha) select p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max, p.activo, ''tarde'', (now() at time zone ''America/Santiago'')::date from public.productos p on conflict (sede, producto_id, fecha, momento) do update set producto = excluded.producto, rubro = excluded.rubro, stock_actual = excluded.stock_actual, stock_min = excluded.stock_min, stock_max = excluded.stock_max, activo = excluded.activo, tomada_at = now();'
);

select cron.schedule('foto-inventario-noche', '0 2 * * *',
 'insert into public.historial_auto (sede, producto_id, producto, rubro, stock_actual, stock_min, stock_max, activo, momento, fecha) select p.sede, p.id, p.producto, p.rubro, p.stock_actual, p.stock_min, p.stock_max, p.activo, ''noche'', (now() at time zone ''America/Santiago'')::date from public.productos p on conflict (sede, producto_id, fecha, momento) do update set producto = excluded.producto, rubro = excluded.rubro, stock_actual = excluded.stock_actual, stock_min = excluded.stock_min, stock_max = excluded.stock_max, activo = excluded.activo, tomada_at = now();'
);

select jobname, schedule, active from cron.job
 where jobname in ('foto-inventario-tarde','foto-inventario-noche')
 order by jobname;


-- ================================================================
-- PARA MIRARLO CUALQUIER DÍA — qué respaldo hay por sede:
--
--   select sede, fecha, momento, count(*) as productos, max(tomada_at)
--     from public.historial_auto
--    group by sede, fecha, momento
--    order by fecha desc, sede;
--
-- Y si alguna vez hay que devolver una sede a como estaba, la foto tiene
-- nombre, sección, stock, mínimo, máximo y si estaba activo. Con eso se
-- reconstruye — que es exactamente lo que faltó el 9 de agosto.
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-respaldo-automatico-de-verdad.sql', 'Jhon', 'lo corrió Jhon',
        'Foto automática de TODAS las sedes a las 15:00 y 22:00, con nombre, sección, stock, mínimo, máximo y activo. Sin funciones ni comillas de dólar')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
