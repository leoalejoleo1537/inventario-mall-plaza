-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque
--  TARDA:     instantáneo
--  QUÉ HACE:  contesta una sola pregunta: ¿la foto automática de las 15:00
--             y las 22:00 está corriendo de verdad?
--  QUÉ VER:   la columna "veredicto". Tiene que decir "✅ las dos fotos"
--             en los últimos días.
-- ================================================================
--
-- POR QUÉ HACE FALTA PREGUNTARLO ASÍ. En la lista de días, un día que tiene
-- foto automática Y conteo a mano aparecía como "contada a mano", y la
-- automática quedaba escondida detrás. O sea que mirando esa lista **no se
-- puede saber si la red está puesta**, que es justamente lo único que
-- importa saber de un respaldo.
--
-- Acá se cuentan por separado, y por sede.
--
-- ⚠️ CORRECCIÓN DE LA PRIMERA VERSIÓN. Decía `a.created_at` y esa columna
-- no existe: la tabla guarda `tomada_at` y, mejor todavía, una columna
-- `momento` que dice si la foto es la de la tarde o la de la noche. El
-- error fue escribir un nombre de memoria en vez de copiarlo de donde se
-- crea la tabla. Un solo nombre inventado tumba la consulta entera.
-- ================================================================

select
  a.fecha,
  count(*) filter (where a.sede = 'plaza')   as plaza,
  count(*) filter (where a.sede = 'angamos') as angamos,
  count(*) filter (where a.sede = 'central') as bodega,
  string_agg(distinct a.momento, ' + ' order by a.momento) as fotos_del_dia,
  case
    when count(distinct a.momento) >= 2 then '✅ las dos fotos'
    when count(distinct a.momento) = 1  then '⚠️ solo la de la ' || max(a.momento)
    else '❌ ninguna'
  end as veredicto
from public.historial_auto a
where a.fecha >= current_date - 12
group by a.fecha
order by a.fecha desc;

-- ================================================================
-- BLOQUE 2 — ¿O ES QUE TODAVÍA NO LLEGA LA HORA?   (otro Run)
--
-- Si al último día le falta la foto de la noche, hay DOS explicaciones y se
-- parecen mucho: que haya fallado, o que todavía no sean las 22:00 allá.
-- Adivinar cuál es manda a revisar algo que está bien.
--
-- QUÉ VER:
--   · `hora_ahora` es la hora en Antofagasta, no la del servidor.
--   · Si son menos de las 22:00, que falte la foto de la noche de HOY es
--     lo normal: todavía no le toca.
--   · Si ya pasaron las 22:00 y falta, esa corrida falló.
--   · Lo mismo con las 15:00 y la foto de la tarde.
-- ================================================================
select
  (now() at time zone 'America/Santiago')::date            as hoy_en_antofagasta,
  to_char(now() at time zone 'America/Santiago', 'HH24:MI') as hora_ahora,
  (select max(fecha) from public.historial_auto)            as ultima_foto,
  case
    when to_char(now() at time zone 'America/Santiago','HH24')::int >= 22
      then 'ya pasaron las dos horas de hoy'
    when to_char(now() at time zone 'America/Santiago','HH24')::int >= 15
      then 'ya pasó la de las 15:00; la de las 22:00 todavía no'
    else 'todavía no toca ninguna de hoy'
  end                                                       as a_esta_hora;


-- ================================================================
-- CÓMO SE LEE EL RESULTADO, y son tres casos distintos que se confunden:
--
--  · Salen los últimos días con "✅ las dos fotos" y las tres sedes con
--    números  ->  la red está puesta. Nada que hacer.
--
--  · No sale NINGUNA fila, pero la consulta no dio error  ->  la tabla
--    existe y está vacía: se instaló y el reloj nunca corrió. Mirar
--    `2026-08-ciclo-por-que-no-responde.sql`.
--
--  · Dice que `historial_auto` no existe  ->  el respaldo automático nunca
--    se instaló. Correr `2026-08-respaldo-automatico-de-verdad.sql`.
--
--  · Salen días viejos y faltan los recientes  ->  el reloj se detuvo en
--    algún momento. Mismo archivo de diagnóstico.
--
-- Una sede con 0 y las otras con números tampoco es normal: la foto se
-- saca de las tres a la vez.
-- ================================================================
