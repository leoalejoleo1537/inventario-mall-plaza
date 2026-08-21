--  DÓNDE VA:  Supabase -> SQL Editor -> New query
--  ES:        1 solo bloque
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. No escribe, no borra, no toca stock.
--  QUÉ VER:   una fila por sede. Las tres columnas que importan:
--             · hace_min        -> hace cuántos minutos corrió el motor
--             · aplicados_3h    -> cuántos descuentos hizo en las últimas 3 h
--             · ultimo_descuento-> cuándo fue el último de verdad
--             Si "leidos_3h" tiene número y "aplicados_3h" está en 0,
--             el motor está LEYENDO y NO DESCONTANDO. Eso es la falla.

select
  s.sede,
  s.modo,
  s.cron_activo as reloj,
  to_char(s.ultima_corrida_at at time zone 'America/Santiago','DD/MM HH24:MI') as corrio,
  round(extract(epoch from (now() - s.ultima_corrida_at)) / 60)::int as hace_min,
  s.ultima_corrida_por as la_disparo,
  s.ultimo_resultado   as resultado,
  s.ultimos_items      as items,
  s.ultimos_errores    as errores,
  s.ultimos_movimientos as descuentos,
  m.leidos_3h,
  m.aplicados_3h,
  to_char(m.ultimo_aplicado at time zone 'America/Santiago','DD/MM HH24:MI') as ultimo_descuento
from public.fudo_sync s
left join lateral (
  select
    count(*) filter (where v.created_at > now() - interval '3 hours') as leidos_3h,
    count(*) filter (where v.created_at > now() - interval '3 hours' and v.aplicado) as aplicados_3h,
    max(v.created_at) filter (where v.aplicado) as ultimo_aplicado
  from public.fudo_movimientos v
  where v.sede = s.sede
) m on true
order by s.sede;
