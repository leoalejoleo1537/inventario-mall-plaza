-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque
--  TARDA:     instantáneo
--  QUÉ HACE:  contesta una sola pregunta: ¿la foto automática de las 15:00
--             y las 22:00 está corriendo de verdad?
--  QUÉ VER:   la columna "veredicto". Tiene que decir "✅ las dos fotos".
-- ================================================================
--
-- POR QUÉ HACE FALTA PREGUNTARLO ASÍ. En la lista de días, un día que tiene
-- foto automática Y conteo a mano aparecía como "contada a mano", y la
-- automática quedaba escondida detrás. O sea que mirando esa lista **no se
-- puede saber si la red está puesta**, que es justamente lo único que
-- importa saber.
--
-- Acá se cuentan por separado.
-- ================================================================
select
  fecha,
  sum(case when sede='plaza'   then 1 else 0 end) as plaza,
  sum(case when sede='angamos' then 1 else 0 end) as angamos,
  sum(case when sede='central' then 1 else 0 end) as bodega,
  count(distinct hora)                            as fotos_del_dia,
  case when count(distinct hora) >= 2 then '✅ las dos fotos'
       when count(distinct hora) = 1  then '⚠️ solo una'
       else '❌ ninguna' end                       as veredicto
from (
  select a.fecha::date as fecha, a.sede,
         date_trunc('hour', a.created_at) as hora
  from public.historial_auto a
  where a.fecha >= current_date - 10
) t
group by fecha
order by fecha desc;

-- Si esta consulta dice que la tabla `historial_auto` no existe, entonces
-- el respaldo automático NUNCA se instaló: hay que correr
-- `2026-08-respaldo-automatico-de-verdad.sql`.
--
-- Si existe pero está vacía, se instaló y el reloj no está corriendo:
-- mirar `2026-08-ciclo-por-que-no-responde.sql`.
