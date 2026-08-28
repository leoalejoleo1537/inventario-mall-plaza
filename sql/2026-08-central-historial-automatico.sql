-- ################################################################
-- ⛔ NO CORRER ESTE ARCHIVO. QUEDÓ SUPERADO.
--
-- Agenda las tareas `foto-inventario-tarde` y `foto-inventario-noche`
-- con una instrucción que SOLO escribe en `historial_auto`. Correrlo
-- pisa la tarea buena, y la pestaña Historial deja de recibir fotos.
--
-- Eso pasó de verdad: el 2026-08-28 la pantalla se cortaba el día 25.
-- La tarea corría perfecto todos los días y la pantalla igual quedaba
-- vacía — la peor clase de falla que tiene este proyecto.
--
-- EL BUENO ES:  sql/2026-08-la-foto-volvio-a-la-pantalla.sql
--
-- Se deja el archivo y no se borra porque su texto explica por qué la
-- foto automática existe. Lo que no hay que hacer es ejecutarlo.
-- ################################################################

-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. El 2 lleva $$: ese va SOLO.
--  TARDA:     instantáneo
--  QUÉ HACE:  hace que el inventario se fotografíe SOLO, dos veces al día,
--             en las tres sedes. No cambia ningún stock.
--  QUÉ VER:   el bloque 4: 3 filas en SÍ, y las dos tareas agendadas.
-- ================================================================
--
-- POR QUÉ IMPORTA MÁS DE LO QUE PARECE. El 9 de agosto se perdió el inventario
-- entero de Angamos y no se pudo restaurar NADA — no por falta de herramienta,
-- sino porque nadie había apretado nunca "Guardar inventario de hoy" en esa
-- sede (§0.6). La foto existía; dependía de que alguien se acordara.
--
-- Esto la saca de la memoria de las personas. Es la misma lección del stock
-- negativo: ahí la solución no fue acordarse, fue un CHECK en la base.
--
-- ⚠️ NO reemplaza al botón "Guardar inventario de hoy". Ese sigue siendo la
-- foto manual del día, la que mira la pestaña Historial. Esto es un registro
-- APARTE, en su propia tabla, que se llena solo y sirve para medir cómo se
-- mueve el stock entre una hora y otra.
--
-- POR QUÉ EN UNA TABLA NUEVA Y NO EN `historial`: `historial` guarda UNA foto
-- por día y por sede — la pantalla y `historial_dias()` cuentan con eso. Meterle
-- dos filas por producto por día rompería el conteo de días y el detalle.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA TABLA
--
-- Solo lo que hace falta para medir: qué producto, cuánto había, cuándo.
-- No copia nombre ni sección: eso ya está en `productos` y acá solo agregaría
-- peso a una tabla que va a crecer todos los días.
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
-- BLOQUE 2 — LA FUNCIÓN QUE SACA LA FOTO  (correr este bloque SOLO)
--
-- Fotografía las TRES sedes de una vez. Si se corriera dos veces en el mismo
-- momento del mismo día, no duplica: actualiza.
-- ================================================================
create or replace function public.tomar_foto_inventario(p_momento text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hoy date := (now() at time zone 'America/Santiago')::date;
  v_n   integer;
begin
  if coalesce(p_momento,'') not in ('tarde','noche') then
    raise exception 'El momento tiene que ser tarde o noche.';
  end if;

  insert into public.historial_auto (sede, producto_id, stock_actual, momento, fecha)
  select p.sede, p.id, p.stock_actual, p_momento, v_hoy
  from public.productos p
  where p.activo = 'SÍ' and p.sede in ('central','plaza','angamos')
  on conflict (sede, producto_id, fecha, momento)
  do update set stock_actual = excluded.stock_actual, tomada_at = now();

  get diagnostics v_n = row_count;
  return v_n;
end;
$$;

grant execute on function public.tomar_foto_inventario(text) to anon, authenticated;


-- ================================================================
-- BLOQUE 3 — AGENDAR LAS DOS
--
-- ⚠️ pg_cron trabaja en UTC. Chile en agosto está en UTC−4, así que:
--     15:00 en Antofagasta  =  19:00 UTC
--     22:00 en Antofagasta  =  02:00 UTC del día siguiente
--
-- Cuando entre el horario de verano (UTC−3) las fotos se correrían una hora
-- más tarde. Para lo que sirven —medir consumo entre turnos— una hora no
-- cambia nada; si algún día molesta, se reagenda.
-- ================================================================
select cron.unschedule('foto-inventario-tarde')
 where exists (select 1 from cron.job where jobname = 'foto-inventario-tarde');
select cron.unschedule('foto-inventario-noche')
 where exists (select 1 from cron.job where jobname = 'foto-inventario-noche');

select cron.schedule('foto-inventario-tarde', '0 19 * * *',
                     $q$select public.tomar_foto_inventario('tarde')$q$);
select cron.schedule('foto-inventario-noche', '0 2 * * *',
                     $q$select public.tomar_foto_inventario('noche')$q$);


-- ================================================================
-- BLOQUE 4 — COMPROBACIÓN
--
-- QUÉ VER: 3 filas en SÍ, y las dos tareas agendadas con su horario.
-- La foto NO se toma al instalar: la primera sale sola a las 15:00.
-- ================================================================
select 'tabla historial_auto' as pieza,
       case when to_regclass('public.historial_auto') is not null then 'SÍ' else 'NO' end as quedo
union all
select 'función tomar_foto_inventario, y una sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='tomar_foto_inventario') = 1
            then 'SÍ' else 'NO' end
union all
select 'las dos tareas agendadas',
       case when (select count(*) from cron.job
                   where jobname in ('foto-inventario-tarde','foto-inventario-noche')) = 2
            then 'SÍ' else 'NO' end
union all
select 'agenda: ' || jobname, schedule from cron.job
 where jobname in ('foto-inventario-tarde','foto-inventario-noche');


-- ================================================================
-- SI QUIERES PROBARLA AHORA MISMO, sin esperar a las 15:00:
--   select public.tomar_foto_inventario('tarde');
-- Devuelve cuántos productos fotografió. Correrla dos veces no duplica.
--
-- Y para ver que quedó:
--   select sede, momento, count(*), max(tomada_at)
--     from public.historial_auto group by 1,2 order by 1,2;
-- ================================================================
