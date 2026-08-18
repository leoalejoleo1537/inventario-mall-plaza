-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. **UNO POR UNO, y los bloques 2 y 3 van SOLOS**
--             (llevan $$ y el editor se atraganta si van pegados a otra
--             cosa — es lo que nos pasó con las mermas).
--  TARDA:     instantáneo
--  QUÉ HACE:  instala la máquina de devolver una sede a una fecha.
--             NO restaura nada ni mueve un solo producto.
--  QUÉ VER:   el bloque 4: 3 filas, las 3 en SÍ.
-- ================================================================
--
-- LA IMAGEN: esto es instalar el botón de "volver atrás". Después de
-- correrlo el inventario está exactamente igual que ahora.
--
-- POR QUÉ ES LA PIEZA MÁS IMPORTANTE DE AJUSTES. El 9 de agosto Angamos
-- quedó en cero y no se pudo recuperar nada: no faltó la herramienta,
-- faltó la copia. Hoy la copia existe y se saca sola dos veces al día;
-- lo que falta es poder usarla sin escribir SQL a las corridas.
--
-- QUÉ DEVUELVE, y qué NO:
--
--   SÍ: el stock, el mínimo, el máximo y la sección de cada producto.
--       Es exactamente lo que se perdió en Angamos.
--
--   NO: el nombre. Renombrar es siempre deliberado —nadie renombra sin
--       querer— y no rompe nada, porque las recetas van por id. Devolver
--       nombres viejos desharía trabajo bueno.
--
--   NO: revivir productos apagados. Si el equipo eliminó algo a
--       propósito, una restauración no puede resucitarlo por su cuenta:
--       eso ya nos pasó y Jhon vio reaparecer productos que él había
--       borrado. Se cuentan aparte y él decide.
--
--   NO: productos creados después de la foto. No estaban, así que no hay
--       a qué volver: se quedan como están.
--
-- Y ANTES DE ESCRIBIR, GUARDA. Cada restauración deja anotado el valor
-- anterior de cada producto, así que se puede deshacer entera. Es la
-- regla de §0.6 metida adentro de la función, para que no dependa de que
-- alguien se acuerde.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL CUADERNO DE RESTAURACIONES
--
-- Una fila por restauración, con el "antes" de cada producto adentro.
-- Sin esto, volver atrás sería adivinar.
-- ================================================================
create table if not exists public.restauraciones (
  id            bigserial primary key,
  sede          text        not null,
  fecha         date        not null,        -- a qué día se volvió
  origen        text        not null,        -- 'historial' | 'historial_auto'
  quien         text,
  productos     integer     not null default 0,
  filas         jsonb       not null,        -- el ANTES, producto por producto
  created_at    timestamptz not null default now(),
  deshecha_at   timestamptz,
  deshecha_por  text
);
create index if not exists restauraciones_sede_idx
  on public.restauraciones(sede, created_at desc);

alter table public.restauraciones enable row level security;
drop policy if exists "restauraciones all" on public.restauraciones;
create policy "restauraciones all" on public.restauraciones
  for all to anon, authenticated using (true) with check (true);
grant all on public.restauraciones to anon, authenticated;
grant usage, select on sequence public.restauraciones_id_seq to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — RESTAURAR  (⚠️ ESTE BLOQUE VA SOLO)
-- ================================================================
create or replace function public.restaurar_sede(
  p_sede   text,
  p_fecha  date,
  p_quien  text default null
) returns public.restauraciones
language plpgsql
security definer
set search_path = public
as $$
declare
  v_origen text;
  v_filas  jsonb;
  v_n      integer;
  r        public.restauraciones;
begin
  if coalesce(p_sede,'') = '' or p_fecha is null then
    raise exception 'Falta la sede o la fecha.';
  end if;

  -- ¿De dónde sale la foto? La manual manda: es la que sacó una persona
  -- después de contar. La automática es el respaldo de las 15:00 y 22:00.
  if exists (select 1 from public.historial where sede = p_sede and fecha = p_fecha) then
    v_origen := 'historial';
  elsif exists (select 1 from public.historial_auto where sede = p_sede and fecha = p_fecha) then
    v_origen := 'historial_auto';
  else
    raise exception 'No hay ninguna foto de % del %.', p_sede, to_char(p_fecha,'DD/MM/YYYY');
  end if;

  -- EL ANTES, guardado antes de tocar nada. Si esto fallara, no se
  -- escribe: la función entera es una sola operación.
  select coalesce(jsonb_agg(jsonb_build_object(
           'producto_id', p.id,
           'stock_actual', p.stock_actual,
           'stock_min', p.stock_min,
           'stock_max', p.stock_max,
           'rubro', p.rubro)), '[]'::jsonb)
    into v_filas
  from public.productos p
  where p.sede = p_sede and p.activo = 'SÍ'
    and p.id in (
      select h.producto_id from public.historial h
       where v_origen = 'historial' and h.sede = p_sede and h.fecha = p_fecha
      union all
      select a.producto_id from public.historial_auto a
       where v_origen = 'historial_auto' and a.sede = p_sede and a.fecha = p_fecha
    );

  -- Y recién ahora se escribe. Solo productos ACTIVOS hoy: una
  -- restauración no revive lo que el equipo apagó a propósito.
  with foto as (
    select h.producto_id, h.stock_actual, h.stock_min, h.stock_max, h.rubro
      from public.historial h
     where v_origen = 'historial' and h.sede = p_sede and h.fecha = p_fecha
    union all
    select a.producto_id, a.stock_actual, a.stock_min, a.stock_max, a.rubro
      from public.historial_auto a
     where v_origen = 'historial_auto' and a.sede = p_sede and a.fecha = p_fecha
  )
  update public.productos p
     set stock_actual = coalesce(f.stock_actual, p.stock_actual),
         stock_min    = coalesce(f.stock_min,    p.stock_min),
         stock_max    = coalesce(f.stock_max,    p.stock_max),
         rubro        = coalesce(f.rubro,        p.rubro),
         updated_at   = now()
  from foto f
  where p.id = f.producto_id and p.sede = p_sede and p.activo = 'SÍ';

  get diagnostics v_n = row_count;

  insert into public.restauraciones (sede, fecha, origen, quien, productos, filas)
  values (p_sede, p_fecha, v_origen, p_quien, v_n, v_filas)
  returning * into r;

  return r;
end;
$$;

grant execute on function public.restaurar_sede(text,date,text) to anon, authenticated;


-- ================================================================
-- BLOQUE 3 — DESHACER UNA RESTAURACIÓN  (⚠️ ESTE BLOQUE VA SOLO)
--
-- Devuelve cada producto al valor que tenía justo antes. La fila del
-- cuaderno no se borra: se marca. Un libro donde se puede borrar una
-- página no sirve de libro.
-- ================================================================
create or replace function public.deshacer_restauracion(
  p_id    bigint,
  p_quien text default null
) returns public.restauraciones
language plpgsql
security definer
set search_path = public
as $$
declare r public.restauraciones;
begin
  select * into r from public.restauraciones where id = p_id for update;
  if not found then
    raise exception 'Esa restauración ya no está.';
  end if;
  if r.deshecha_at is not null then
    raise exception 'Esa restauración ya se deshizo.';
  end if;

  update public.productos p
     set stock_actual = (f->>'stock_actual')::double precision,
         stock_min    = (f->>'stock_min')::double precision,
         stock_max    = (f->>'stock_max')::double precision,
         rubro        = f->>'rubro',
         updated_at   = now()
  from jsonb_array_elements(r.filas) f
  where p.id = (f->>'producto_id')::bigint and p.sede = r.sede;

  update public.restauraciones
     set deshecha_at = now(), deshecha_por = p_quien
   where id = p_id
  returning * into r;

  return r;
end;
$$;

grant execute on function public.deshacer_restauracion(bigint,text) to anon, authenticated;


-- ================================================================
-- BLOQUE 4 — COMPROBACIÓN
-- QUÉ VER: 3 filas, las 3 en SÍ.
-- ================================================================
select 'tabla restauraciones' as pieza,
       case when to_regclass('public.restauraciones') is not null then 'SÍ' else 'NO' end as quedo
union all
select 'restaurar_sede, y una sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='restaurar_sede') = 1
            then 'SÍ' else 'NO' end
union all
select 'deshacer_restauracion, y una sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='deshacer_restauracion') = 1
            then 'SÍ' else 'NO' end;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-restaurar-una-sede.sql', 'Jhon', 'lo corrió Jhon',
        'Devolver una sede a una fecha, con el valor anterior guardado para poder deshacerlo entero')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
