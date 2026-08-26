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
-- LAS DOS SE CUENTAN POR SEPARADO, y no es un detalle.
--
-- La primera versión juntaba las dos y ponía "contada a mano" si había
-- alguna manual. Resultado: un día con foto automática Y conteo a mano
-- aparecía solo como "contada a mano", y la automática quedaba escondida.
-- O sea que mirando la lista **no se podía saber si la red está puesta**,
-- que es lo único que de verdad importa saber de un respaldo.
-- ⚠️ EL `drop` NO ES ADORNO, y sin él este archivo falla (2026-08-26).
-- Postgres NO deja que `create or replace` cambie las columnas que una
-- función devuelve: contesta "cannot change return type of existing
-- function". En producción vivía la primera versión, de 3 columnas
-- (fecha, cuantos, tipo); esta devuelve 5, con `a_mano` y `automatica`.
--
-- Y el daño de la versión vieja no era que faltaran columnas: era que la
-- app leía `automatica` como `undefined`, lo trataba como 0, y afirmaba
-- "la foto automática nunca corrió en esta sede" teniendo fotos guardadas.
-- Un aviso falso dicho con seguridad (§0.5).
--
-- Se borra por firma exacta, como manda §0.5 — una por cada versión posible.
drop function if exists public.fotos_por_dia(text);

create or replace function public.fotos_por_dia(p_sede text)
returns table(fecha date, cuantos bigint, tipo text, a_mano bigint, automatica bigint)
language sql
stable
as 'select f.fecha,
           sum(f.man) + sum(f.aut)                        as cuantos,
           case when sum(f.man) > 0 and sum(f.aut) > 0 then ''contada a mano + automática''
                when sum(f.man) > 0                   then ''contada a mano''
                else ''automática'' end                    as tipo,
           sum(f.man)                                     as a_mano,
           sum(f.aut)                                     as automatica
      from (
        select h.fecha::date as fecha, count(*) as man, 0::bigint as aut
          from public.historial h where h.sede = p_sede group by h.fecha::date
        union all
        select a.fecha::date, 0::bigint, count(*)
          from public.historial_auto a where a.sede = p_sede group by a.fecha::date
      ) f
     group by f.fecha
     order by f.fecha desc
     limit 120';

grant execute on function public.fotos_por_dia(text) to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — COMPROBAR  (otro Run)
--
-- QUÉ VER: una fila por día, con **dos columnas separadas**: cuántas filas
-- puso el conteo a mano y cuántas la foto automática.
--
-- Lo que hay que mirar de verdad es la columna `automatica`: si trae un
-- número en los días recientes, la red está puesta. Si viene en 0 varios
-- días seguidos, el respaldo automático no está corriendo.
--
-- Y tienen que salir muchos más días de los que mostraba la pantalla antes.
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
