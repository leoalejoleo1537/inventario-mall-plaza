--  DÓNDE VA:  Supabase -> SQL Editor -> New query
--  ES:        1 solo bloque
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. No escribe, no borra, no toca stock.
--  QUÉ VER:   las filas "RESUMEN" primero (una por sede) y debajo el detalle.
--             La columna "sin_receta" es la respuesta a lo de Adriana:
--             un producto sin receta NO descuenta, y eso no es una falla del
--             motor — es cobertura que falta.

with hoy as (
  select * from public.fudo_movimientos
   where created_at > now() - interval '24 hours'
)
select
  'RESUMEN'                                          as tipo,
  sede,
  count(*) filter (where aplicado)::text || ' de ' || count(*)::text
    || ' descontaron'                                as producto,
  count(*)                                           as veces,
  count(*) filter (where producto_nombre = '(sin receta)') as sin_receta
from hoy
group by sede

union all

select
  'sin descontar',
  sede,
  coalesce(fudo_product_nombre, '(sin nombre)'),
  count(*),
  count(*) filter (where producto_nombre = '(sin receta)')
from hoy
where not aplicado
group by sede, fudo_product_nombre

order by 1, 2, 4 desc;
