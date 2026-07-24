-- ================================================================
-- ARREGLO: que TODOS los usuarios logueados puedan crear/editar recetas
--
-- Problema: solo la cuenta dueña podía crear recetas nuevas. La causa es
-- una política RLS restringida en la base real (probablemente atada a un
-- usuario) que no está en los archivos del repo, porque el SQL se corre
-- a mano en el panel.
--
-- Este script es DEFINITIVO e IDEMPOTENTE:
--   1) Borra TODAS las políticas actuales de recetas y receta_items
--      (sin importar su nombre), incluidas las restringidas.
--   2) Crea una política abierta para anon + authenticated.
--   3) Reasigna los permisos (grants) y el uso de las secuencias.
--
-- Es un sistema interno del personal del café: todos los usuarios
-- logueados pueden gestionar recetas. No hay dueño exclusivo.
--
-- Cómo correrlo: Supabase → SQL Editor → pegar todo → Run.
-- ================================================================

-- 1) Borrar cualquier política existente en las dos tablas -----------
do $$
declare pol record;
begin
  for pol in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and tablename in ('recetas', 'receta_items')
  loop
    execute format('drop policy if exists %I on public.%I', pol.policyname, pol.tablename);
  end loop;
end $$;

-- 2) Asegurar que RLS está activo y crear política abierta ------------
alter table public.recetas      enable row level security;
alter table public.receta_items enable row level security;

create policy "recetas all"
  on public.recetas      for all to anon, authenticated using (true) with check (true);
create policy "receta_items all"
  on public.receta_items for all to anon, authenticated using (true) with check (true);

-- 3) Permisos de tabla y secuencias para ambos roles -----------------
grant select, insert, update, delete on public.recetas      to anon, authenticated;
grant select, insert, update, delete on public.receta_items to anon, authenticated;
grant usage, select on sequence public.recetas_id_seq       to anon, authenticated;
grant usage, select on sequence public.receta_items_id_seq  to anon, authenticated;

-- 4) Verificación: ver las políticas que quedaron -------------------
--    (deben aparecer "recetas all" y "receta_items all" con roles
--     {anon,authenticated} y qual = true)
select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('recetas', 'receta_items')
order by tablename, policyname;
