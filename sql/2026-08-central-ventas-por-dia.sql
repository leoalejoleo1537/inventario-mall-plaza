-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. El 1 lleva $$: ese va SOLO.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea la función que cuenta cuánto se vendió por día, por sede
--             y por familia. Solo LEE ventas que ya están guardadas.
--  QUÉ VER:   el bloque 3 devuelve las ventas reales de los últimos 7 días.
-- ================================================================
--
-- DE DÓNDE SALE EL DATO: `fudo_movimientos`. El motor de descuento escribe ahí
-- cada ítem vendido desde que se encendió — qué producto del inventario se
-- descontó, cuánto y cuándo. No se le pide nada a la API de Fudo: ya está.
--
-- SE CUENTA EL DESCUENTO, no la cantidad vendida. Son distintos cuando una
-- receta lleva más de una unidad, y lo que importa para reponer es cuánto SALIÓ
-- de la repisa, no cuántos platos se cobraron.
--
-- DOS LÍMITES, dichos acá para que nadie los descubra tarde:
--   · Solo hay historia desde que el motor se encendió en cada sede. Angamos
--     lleva pocos días, así que un promedio de 7 días ahí miente por lo bajo:
--     la función devuelve `dias_con_datos` para poder decirlo en pantalla.
--   · Solo se registra lo que tiene receta. Un producto sin receta se vende y
--     no aparece. Para sándwiches y tortas está cubierto.
--
-- LAS FAMILIAS SE DEFINEN ACÁ, en un solo lugar. Los sándwiches por su sección
-- —el equipo la mantiene— y las tortas por el nombre, que es más frágil y por
-- eso queda escrito y a la vista para poder corregirlo.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA FUNCIÓN  (correr este bloque SOLO)
-- ================================================================
create or replace function public.ventas_por_dia(p_dias integer default 7)
returns table (
  sede            text,
  dia             date,
  familia         text,
  unidades        numeric,
  dias_con_datos  integer
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_desde date := (now() at time zone 'America/Santiago')::date - (greatest(p_dias,1) - 1);
begin
  return query
  with clasificado as (
    select m.sede,
           (m.created_at at time zone 'America/Santiago')::date as dia,
           case
             when public.clave_nombre(p.rubro) like 'sandwich%' then 'sandwiches'
             when public.clave_nombre(p.producto) ~ 'torta|cheesecake|kutchen|pie |tiramisu'
               then 'tortas'
             else 'otros'
           end as familia,
           coalesce(m.descuento, 0) as u
    from public.fudo_movimientos m
    join public.productos p on p.id = m.producto_id
    where m.producto_id is not null
      and (m.created_at at time zone 'America/Santiago')::date >= v_desde
      and coalesce(m.descuento,0) > 0
  ),
  -- cuántos días DISTINTOS traen ventas en esa sede: si son menos que los
  -- pedidos, el promedio hay que decirlo con esa advertencia
  cobertura as (
    select c.sede, count(distinct c.dia)::integer as n from clasificado c group by c.sede
  )
  select c.sede, c.dia, c.familia, sum(c.u) as unidades,
         coalesce(cob.n, 0) as dias_con_datos
  from clasificado c
  left join cobertura cob on cob.sede = c.sede
  where c.familia <> 'otros'
  group by c.sede, c.dia, c.familia, cob.n
  order by c.sede, c.familia, c.dia;
end;
$$;

grant execute on function public.ventas_por_dia(integer) to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — COMPROBACIÓN — 1 fila, en SÍ
-- ================================================================
select 'ventas_por_dia, y una sola firma' as pieza,
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='ventas_por_dia') = 1
            then 'SÍ' else 'NO' end as quedo;


-- ================================================================
-- BLOQUE 3 — QUÉ DEVUELVE DE VERDAD
--
-- QUÉ VER: cuántos días de historia hay en cada sede y cuánto se vendió. Si
-- `dias_con_datos` es mucho menor que 7, el promedio de la pantalla lo va a
-- decir en vez de dividir por 7 y mentir.
-- ================================================================
select sede, familia,
       count(*)                          as dias_con_venta,
       max(dias_con_datos)               as dias_con_datos,
       sum(unidades)                     as total_7_dias,
       round(sum(unidades)/greatest(max(dias_con_datos),1), 1) as promedio_diario
from public.ventas_por_dia(7)
group by sede, familia
order by sede, familia;
