-- ================================================================
-- AUDITORÍA DE RECETAS — comparar Fudo contra el inventario
--
-- SOLO LECTURA: no crea, no borra, no modifica nada. Se puede correr
-- las veces que quieras. Sirve para ver el tamaño real del problema
-- antes de depurar a mano.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Devuelve 9 tablas, una por bloque. Míralas en orden: el bloque 1 es
-- lo que está fallando AHORA, el 9 es lo que hay que revisar a mano.
-- ================================================================

-- Normalizador: mismo criterio que usa la app y el emparejador
-- (sin tildes, sin mayúsculas, sin espacios de más).
create or replace function public.norm_nombre(t text)
returns text language sql immutable as $$
  select translate(lower(regexp_replace(trim(coalesce(t,'')),'\s+',' ','g')),
                   'áéíóúñü','aeiounu');
$$;


-- ================================================================
-- BLOQUE 0 — RESUMEN: los números gruesos
-- ================================================================
select '0 · RESUMEN' as bloque, sede, concepto, cantidad
from (
  select fp.sede, 'Productos activos en Fudo' as concepto, count(*) as cantidad, 1 as ord
    from public.fudo_productos fp where fp.activo group by fp.sede
  union all
  select p.sede, 'Productos activos en el inventario', count(*), 2
    from public.productos p where p.activo='SÍ' group by p.sede
  union all
  select r.sede, 'Recetas creadas', count(*), 3
    from public.recetas r where r.activo group by r.sede
  union all
  select r.sede, 'Recetas CON insumos', count(*), 4
    from public.recetas r
   where r.activo and exists (select 1 from public.receta_items ri where ri.receta_id=r.id)
   group by r.sede
  union all
  select r.sede, 'Recetas VACÍAS (no descuentan nada)', count(*), 5
    from public.recetas r
   where r.activo and not exists (select 1 from public.receta_items ri where ri.receta_id=r.id)
   group by r.sede
  union all
  select fp.sede, 'Productos de Fudo SIN receta', count(*), 6
    from public.fudo_productos fp
   where fp.activo
     and not exists (select 1 from public.recetas r
                      where r.sede=fp.sede and r.fudo_product_id=fp.fudo_product_id and r.activo)
   group by fp.sede
) t
order by sede, ord;


-- ================================================================
-- BLOQUE 1 — 🔴 LO MÁS URGENTE: se vendió en Fudo y NO descontó nada
-- (el motor registró la venta pero no encontró receta)
-- ================================================================
select '1 · VENDIDO SIN DESCONTAR' as bloque,
       m.sede,
       m.fudo_product_nombre               as producto_fudo,
       count(*)                            as veces_vendido,
       sum(m.cantidad_vendida)             as unidades,
       max(m.created_at)::date             as ultima_vez
from public.fudo_movimientos m
where m.producto_nombre = '(sin receta)'
group by m.sede, m.fudo_product_nombre
order by unidades desc nulls last, veces_vendido desc;


-- ================================================================
-- BLOQUE 2 — Productos ACTIVOS en Fudo que no tienen receta
-- (todavía no fallan porque no se han vendido, pero van a fallar)
-- ================================================================
select '2 · FUDO SIN RECETA' as bloque,
       fp.sede, fp.nombre as producto_fudo, fp.precio,
       case when public.norm_nombre(fp.nombre) ~ '(combo|promo|desayuno|menu|kids|\+| y |duo|dúo)'
            then 'posible combo' else '' end as pista
from public.fudo_productos fp
where fp.activo
  and not exists (select 1 from public.recetas r
                   where r.sede=fp.sede and r.fudo_product_id=fp.fudo_product_id and r.activo)
order by fp.sede, fp.nombre;


-- ================================================================
-- BLOQUE 3 — Recetas VACÍAS: existen pero no descuentan nada
-- (tan malas como no tener receta, pero invisibles)
-- ================================================================
select '3 · RECETAS VACÍAS' as bloque,
       r.sede, r.fudo_product_nombre as producto_fudo,
       coalesce(fp.activo, false)    as sigue_activo_en_fudo
from public.recetas r
left join public.fudo_productos fp
       on fp.sede=r.sede and fp.fudo_product_id=r.fudo_product_id
where r.activo
  and not exists (select 1 from public.receta_items ri where ri.receta_id=r.id)
order by r.sede, r.fudo_product_nombre;


-- ================================================================
-- BLOQUE 4 — RUIDO: recetas de productos que ya no existen o están
-- inactivos en Fudo (se pueden borrar sin miedo)
-- ================================================================
select '4 · RECETA DE PRODUCTO MUERTO' as bloque,
       r.sede, r.fudo_product_nombre as producto_fudo,
       case when fp.fudo_product_id is null then 'ya no existe en Fudo'
            else 'inactivo en Fudo' end as motivo,
       (select count(*) from public.receta_items ri where ri.receta_id=r.id) as insumos
from public.recetas r
left join public.fudo_productos fp
       on fp.sede=r.sede and fp.fudo_product_id=r.fudo_product_id
where r.activo
  and (fp.fudo_product_id is null or fp.activo = false)
order by r.sede, r.fudo_product_nombre;


-- ================================================================
-- BLOQUE 5 — RECETAS ROTAS: descuentan un producto de inventario
-- que fue eliminado. Al venderse, ese insumo no se descuenta.
-- ================================================================
select '5 · RECETA ROTA' as bloque,
       r.sede, r.fudo_product_nombre as producto_fudo,
       ri.producto_id                as insumo_id_faltante,
       ri.cantidad
from public.receta_items ri
join public.recetas r on r.id = ri.receta_id
left join public.productos p on p.id = ri.producto_id and p.activo='SÍ'
where r.activo and p.id is null
order by r.sede, r.fudo_product_nombre;


-- ================================================================
-- BLOQUE 6 — Inventario que NINGUNA receta descuenta
-- (normal en limpieza o desechables; raro en comida)
-- ================================================================
select '6 · INVENTARIO HUÉRFANO' as bloque,
       p.sede, p.rubro as seccion, p.producto, p.stock_actual
from public.productos p
where p.activo='SÍ'
  and not exists (select 1 from public.receta_items ri where ri.producto_id = p.id)
order by p.sede, p.rubro, p.producto;


-- ================================================================
-- BLOQUE 7 — SUGERENCIAS: el nombre calza y no están emparejados
-- (candidatos a receta 1-a-1 automática)
-- ================================================================
select '7 · SUGERENCIA DE EMPAREJAMIENTO' as bloque,
       fp.sede, fp.nombre as producto_fudo, p.producto as insumo_inventario,
       p.rubro as seccion
from public.fudo_productos fp
join public.productos p
  on p.sede = fp.sede and p.activo='SÍ'
 and public.norm_nombre(p.producto) = public.norm_nombre(fp.nombre)
where fp.activo
  and not exists (select 1 from public.recetas r
                   where r.sede=fp.sede and r.fudo_product_id=fp.fudo_product_id and r.activo)
order by fp.sede, fp.nombre;


-- ================================================================
-- BLOQUE 8 — POSIBLES COMBOS mal armados: el nombre sugiere varios
-- ítems pero la receta descuenta uno solo (o ninguno)
-- ================================================================
select '8 · COMBO SOSPECHOSO' as bloque,
       r.sede, r.fudo_product_nombre as producto_fudo,
       (select count(*) from public.receta_items ri where ri.receta_id=r.id) as insumos_actuales
from public.recetas r
where r.activo
  and public.norm_nombre(r.fudo_product_nombre) ~ '(combo|promo|desayuno|menu|kids|\+| y |duo|dúo)'
  and (select count(*) from public.receta_items ri where ri.receta_id=r.id) <= 1
order by r.sede, r.fudo_product_nombre;


-- ================================================================
-- BLOQUE 9 — COBERTURA: qué porcentaje de lo que se vende descuenta
-- ================================================================
select '9 · COBERTURA' as bloque,
       fp.sede,
       count(*)                                          as productos_activos_fudo,
       count(*) filter (where r.id is not null)          as con_receta,
       count(*) filter (where ri.n > 0)                  as con_receta_util,
       round(100.0 * count(*) filter (where ri.n > 0) / nullif(count(*),0), 1) as pct_cubierto
from public.fudo_productos fp
left join public.recetas r
       on r.sede=fp.sede and r.fudo_product_id=fp.fudo_product_id and r.activo
left join lateral (select count(*) as n from public.receta_items x where x.receta_id=r.id) ri on true
where fp.activo
group by fp.sede
order by fp.sede;
