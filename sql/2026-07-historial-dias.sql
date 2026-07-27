-- ================================================================
-- HISTORIAL — la lista de días mostraba días viejos (julio 2026)
--
-- Problema: la app pedía TODAS las filas del historial de la sede para
-- sacar de ahí las fechas. Con ~232 productos por día, Supabase corta la
-- respuesta en 1000 filas (unos 4 días) y, sin un orden pedido, devuelve
-- las primeras que encuentra: las más antiguas. Resultado: la lista
-- mostraba el 13/07 y los guardados recientes no aparecían nunca.
--
-- Los datos siempre estuvieron bien guardados; lo que fallaba era leerlos.
--
-- QUÉ HACE: crea una función que devuelve UNA fila por día, agrupando en
-- la base. Así la lista no depende de cuántos productos tenga cada día.
-- No modifica ni borra ningún dato.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Es idempotente.
-- ================================================================

create or replace function public.historial_dias(p_sede text)
returns table(fecha text, productos bigint)
language sql
stable
security definer
set search_path = public
as $$
  select h.fecha::text, count(*)::bigint
  from public.historial h
  where h.sede = p_sede
  group by h.fecha
  order by h.fecha desc;
$$;

grant execute on function public.historial_dias(text) to anon, authenticated;

-- ---------- Comprobación: los días guardados de Mall Plaza ----------
-- Acá tienen que salir TODOS, incluido el más reciente.
select * from public.historial_dias('plaza');
