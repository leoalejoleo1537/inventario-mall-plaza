-- ================================================================
-- ARREGLO: las tablas de Fudo/recetas también para usuarios logueados
--
-- La app inicia sesión, así que sus usuarios son rol "authenticated",
-- no "anon". Las políticas nuevas quedaron solo para "anon", por eso
-- la app veía 0 productos / 0 recetas. Esto las abre a ambos roles.
-- ================================================================
drop policy if exists "recetas all"           on public.recetas;
create policy "recetas all"           on public.recetas          for all    to anon, authenticated using (true) with check (true);
drop policy if exists "receta_items all"      on public.receta_items;
create policy "receta_items all"      on public.receta_items     for all    to anon, authenticated using (true) with check (true);
drop policy if exists "fudo_sync all"         on public.fudo_sync;
create policy "fudo_sync all"         on public.fudo_sync        for all    to anon, authenticated using (true) with check (true);
drop policy if exists "fudo_movimientos read" on public.fudo_movimientos;
create policy "fudo_movimientos read" on public.fudo_movimientos for select to anon, authenticated using (true);
drop policy if exists "fudo_productos read"   on public.fudo_productos;
create policy "fudo_productos read"   on public.fudo_productos   for select to anon, authenticated using (true);

grant select, insert, update, delete on public.recetas          to authenticated;
grant select, insert, update, delete on public.receta_items     to authenticated;
grant select, insert, update, delete on public.fudo_sync        to authenticated;
grant select                         on public.fudo_movimientos to authenticated;
grant select                         on public.fudo_productos   to authenticated;
grant usage, select on sequence public.recetas_id_seq      to authenticated;
grant usage, select on sequence public.receta_items_id_seq to authenticated;
