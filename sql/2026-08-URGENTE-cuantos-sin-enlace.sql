--  DÓNDE VA:  Supabase -> SQL Editor -> New query
--  ES:        1 solo bloque
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. No escribe, no borra, no toca stock.
--  QUÉ VER:   primero el RESUMEN (una fila por sede) y debajo el detalle:
--             qué productos del local no tienen de dónde bajar en bodega.
--             La columna `hay_uno_igual_en_bodega` dice si el arreglo es
--             fácil (existe un producto con ese nombre y solo falta unirlos)
--             o si de verdad no está en bodega.

with sinlace as (
  select p.id, p.sede, p.producto, p.rubro, p.stock_actual
  from public.productos p
  where p.sede in ('plaza','angamos')
    and p.activo = 'SÍ'
    and not exists (
      select 1 from public.producto_enlace e
       where e.producto_sede_id = p.id and e.sede = p.sede)
)
select 'RESUMEN' as tipo, sede,
       count(*)::text || ' sin enlace' as producto,
       null::text as rubro,
       count(*) filter (where exists (
         select 1 from public.productos b
          where b.sede = 'central'
            and lower(translate(b.producto,'áéíóúÁÉÍÓÚ','aeiouAEIOU'))
              = lower(translate(sinlace.producto,'áéíóúÁÉÍÓÚ','aeiouAEIOU')))) as hay_uno_igual_en_bodega
from sinlace
group by sede

union all

select 'sin enlace', sede, producto, rubro,
       (select count(*) from public.productos b
         where b.sede = 'central'
           and lower(translate(b.producto,'áéíóúÁÉÍÓÚ','aeiouAEIOU'))
             = lower(translate(sinlace.producto,'áéíóúÁÉÍÓÚ','aeiouAEIOU')))
from sinlace

order by 1, 2, 3;
