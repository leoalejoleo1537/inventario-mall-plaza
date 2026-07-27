-- ================================================================
-- FECHAS EN VIVO + LIMPIEZA DEL DESCUADRE (julio 2026)
--
-- Dos problemas distintos, confirmados con el diagnóstico:
--
-- A) Las fechas NO viajaban en vivo. En la publicación de Realtime estaba
--    'productos' pero NO 'producto_lotes': al vender, el teléfono recibía
--    el stock nuevo pero seguía mostrando las fechas viejas. Por eso se
--    veía "Champiñón 0" con "1 vence hoy" al mismo tiempo.
--
-- B) Quedaron fechas huérfanas de productos que ya están en 0. Regla que
--    fijó Jhon: **si el stock está en 0, la fecha sobra** — se le cree al
--    stock. (Al revés NO: cuando alguien AGREGA fechas, son las fechas las
--    que mandan y el stock se calcula sumándolas. Eso no cambia.)
--
-- QUÉ HACE ESTE SCRIPT: borra filas de producto_lotes — solo las que no
-- representan unidades reales (cantidad <= 0, o de productos en stock 0).
-- No crea ni modifica productos, y no toca ninguna fecha de un producto
-- que sí tenga stock.
--
-- REVERSIBLE: antes de borrar, copia todo lo que va a borrar en la tabla
-- producto_lotes_respaldo_20260727. Para deshacer:
--   insert into public.producto_lotes(producto_id, cantidad, vencimiento)
--   select producto_id, cantidad, vencimiento from public.producto_lotes_respaldo_20260727;
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Es idempotente. El PASO 1 no toca nada: míralo antes de seguir.
-- ================================================================

-- ================================================================
-- PASO 1 — VISTA PREVIA (no toca nada): qué se va a borrar y por qué
-- ================================================================
select p.producto,
       p.stock_actual,
       l.cantidad,
       l.vencimiento,
       case when coalesce(l.cantidad,0) <= 0 then 'fecha sin unidades'
            else 'producto en stock 0' end as motivo
from public.producto_lotes l
join public.productos p on p.id = l.producto_id
where coalesce(l.cantidad,0) <= 0
   or coalesce(p.stock_actual,0) = 0
order by p.producto, l.vencimiento;

-- ================================================================
-- PASO 2 — APLICAR
-- ================================================================

-- ---------- A) las fechas ahora viajan en vivo, como el stock ----------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'producto_lotes'
  ) then
    execute 'alter publication supabase_realtime add table public.producto_lotes';
  end if;
end $$;

-- ---------- B) respaldo de lo que se va a borrar ----------
create table if not exists public.producto_lotes_respaldo_20260727 (
  id bigint, producto_id bigint, cantidad numeric, vencimiento date, respaldado_at timestamptz default now()
);

insert into public.producto_lotes_respaldo_20260727(id, producto_id, cantidad, vencimiento)
select l.id, l.producto_id, l.cantidad, l.vencimiento
from public.producto_lotes l
join public.productos p on p.id = l.producto_id
where (coalesce(l.cantidad,0) <= 0 or coalesce(p.stock_actual,0) = 0)
  and not exists (select 1 from public.producto_lotes_respaldo_20260727 r where r.id = l.id);

-- ---------- C) borrar las fechas que no representan unidades reales ----------
-- 1. fechas con cantidad 0 o menos: son filas que quedaron vacías al descontar
delete from public.producto_lotes where coalesce(cantidad,0) <= 0;

-- 2. fechas de productos que están en 0: manda el stock (regla de Jhon)
delete from public.producto_lotes l
using public.productos p
where p.id = l.producto_id
  and coalesce(p.stock_actual,0) = 0;

-- ================================================================
-- PASO 3 — COMPROBACIÓN
-- ================================================================

-- 1) el descuadre debe quedar en 0 para TODOS los productos con fechas
--    (si alguna fila sale acá, mándamela: es un caso que no cubre la regla)
select p.producto,
       p.stock_actual                                as stock_guardado,
       coalesce(sum(l.cantidad),0)                   as suma_de_fechas,
       p.stock_actual - coalesce(sum(l.cantidad),0)  as descuadre
from public.productos p
join public.producto_lotes l on l.producto_id = p.id
where p.activo = 'SÍ'
group by p.id, p.producto, p.stock_actual
having p.stock_actual - coalesce(sum(l.cantidad),0) <> 0
order by p.producto;

-- 2) las dos tablas tienen que aparecer acá para que todo viaje en vivo
select tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
  and tablename in ('productos','producto_lotes')
order by tablename;
