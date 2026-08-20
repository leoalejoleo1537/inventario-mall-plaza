-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  arregla la lista de días de Ajustes -> Respaldos, que hoy
--             solo muestra los últimos 2 o 3 aunque haya semanas guardadas.
--  QUÉ VER:   el bloque 2 tiene que traer MUCHOS más días de los que
--             muestra la app hoy.
-- ================================================================
--
-- QUÉ ESTÁ PASANDO, y es el tope de las 1000 filas en su forma más cara.
--
-- La pantalla de Respaldos pide "las fechas del historial" para armar la
-- lista de días a los que se puede volver. Pero el historial guarda **una
-- fila por producto y por día**: unos 250 por sede. Y Supabase nunca
-- devuelve más de 1000 filas de una vez, sin avisar.
--
--   1000 filas ÷ 250 productos  =  4 días.
--
-- O sea que la lista de restauración estaba ofreciendo **los últimos 3 o 4
-- días**, aunque en la base haya un mes entero. Y no avisaba: mostraba una
-- lista corta que parecía completa.
--
-- Es exactamente el mismo error que en julio dejó el Historial ofreciendo
-- días viejos. Y duele el doble acá, porque esta pantalla es la red de
-- emergencia: el día que haga falta volver atrás, uno quiere elegir el día
-- bueno, no el que alcanzó a entrar en las 1000 filas.
--
-- LA SOLUCIÓN, y es la general para este tope: **que la base entregue el
-- resumen ya contado**, en vez de mandar la lista entera para que la app la
-- cuente. Una fila por día son 60 filas, no 15.000.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA FUNCIÓN
-- QUÉ VER: "Success". No devuelve filas.
-- ================================================================
create or replace function public.fotos_por_dia(p_sede text)
returns table(fecha date, cuantos bigint, tipo text)
language sql
stable
as 'select f.fecha, sum(f.cuantos) as cuantos,
           case when bool_or(f.manual) then ''contada a mano'' else ''automática'' end as tipo
      from (
        select h.fecha::date as fecha, count(*) as cuantos, true as manual
          from public.historial h where h.sede = p_sede group by h.fecha::date
        union all
        select a.fecha::date, count(*), false
          from public.historial_auto a where a.sede = p_sede group by a.fecha::date
      ) f
     group by f.fecha
     order by f.fecha desc
     limit 120';

grant execute on function public.fotos_por_dia(text) to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — COMPROBAR  (otro Run)
--
-- QUÉ VER: una fila por día, con cuántos productos tiene la foto y si fue
-- contada a mano o automática. **Tienen que salir muchos más días de los
-- que hoy muestra la pantalla de Respaldos.**
--
-- Si sale un error diciendo que `historial_auto` no existe, es que todavía
-- no se corrió `2026-08-respaldo-automatico-de-verdad.sql`. Córrelo antes
-- que este.
-- ================================================================
select * from public.fotos_por_dia('plaza');


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-dias-con-foto.sql', 'Jhon', 'lo corrió Jhon',
        'fotos_por_dia(): la lista de días de Respaldos se arma en la base. Antes se truncaba en 1000 filas y solo mostraba 3 o 4 días')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
