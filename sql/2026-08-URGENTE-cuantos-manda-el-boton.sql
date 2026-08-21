--  DÓNDE VA:  Supabase -> SQL Editor -> New query
--  ES:        1 solo bloque
--  TARDA:     unos segundos (el bloque A hace el cálculo entero, dos veces)
--  QUÉ HACE:  NADA. Solo mira. No toca Fudo, no toca stock.
--  QUÉ VER:   Bloque A -> "cuantos" es cuántos productos le manda a Fudo CADA
--             vez que se aprieta ⟳. Fudo se atiende de a uno por vez, así que
--             ese número, en segundos, es lo que tarda la corrida.
--             Si pasa de ~150, ahí está el 504.
--             Bloque B -> cuántas filas quedaron anotadas en las últimas 6 h.
--             Si el empuje murió de 504 con la versión vieja, no anotó NADA.

select
  'A · lo que manda el boton' as bloque,
  'plaza'                    as sede,
  count(*) filter (where stock_en_fudo is not null
                     and stock_en_fudo <> stock_calculado)::text as cuantos,
  'de ' || count(*)::text || ' calculados'                       as detalle
from public.fudo_stock_calculado('plaza')

union all

select
  'A · lo que manda el boton',
  'angamos',
  count(*) filter (where stock_en_fudo is not null
                     and stock_en_fudo <> stock_calculado)::text,
  'de ' || count(*)::text || ' calculados'
from public.fudo_stock_calculado('angamos')

union all

select
  'B · anotado en 6 h',
  sede,
  count(*) filter (where created_at > now() - interval '6 hours')::text,
  'ultimo: ' || coalesce(to_char(max(created_at) at time zone 'America/Santiago',
                                 'DD/MM HH24:MI'), 'nunca')
from public.fudo_stock_push
group by sede

order by 1, 2;
