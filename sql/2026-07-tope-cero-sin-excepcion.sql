-- ================================================================
-- TOPE EN CERO SIN EXCEPCIÓN — para TODOS los productos (julio 2026)
--
-- La regla anterior (reposicion-congelador-y-tope-cero.sql) solo
-- garantizaba "nunca negativo" para productos SIN lotes de vencimiento.
-- Jhon aclaró: "es absurdo, no podemos tener números negativos en el
-- inventario, sin excepción" — así que ahora se cierra el único hueco
-- que quedaba: los productos CON lotes de vencimiento (sándwiches, etc.),
-- donde descontar_lotes() dejaba a propósito el sobrante en negativo en
-- el lote más próximo a vencer.
--
-- Qué cambia:
--   1) descontar_lotes(): si se vende más de lo que hay, el sobrante ya
--      NO se refleja como negativo — el stock simplemente se queda en 0.
--   2) Restricción a nivel de base de datos (CHECK) en productos.stock_actual
--      y producto_lotes.cantidad: es el respaldo final, para que ningún
--      camino futuro (otro motor, una edición manual, un bug) pueda dejar
--      un número negativo, aunque alguien se olvide de este archivo.
--
-- Antes de poner la restricción hay que limpiar cualquier negativo que
-- ya exista hoy en la base (si no, el ALTER TABLE falla).
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Es idempotente y reversible (para quitar las restricciones: DROP
-- CONSTRAINT con los nombres de abajo).
-- ================================================================

-- ---------- 1) Limpiar negativos existentes (si los hay) ----------
update public.producto_lotes set cantidad = 0, updated_at = now() where cantidad < 0;
update public.productos set stock_actual = 0, updated_at = now() where stock_actual < 0;

-- ---------- 2) descontar_lotes(): ya no deja sobrante en negativo ----------
create or replace function public.descontar_lotes(p_producto_id bigint, p_cantidad numeric)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_resta numeric := p_cantidad;   -- lo que falta por descontar
  v_toma  numeric;
  r       record;
begin
  if p_cantidad is null or p_cantidad <= 0 then return; end if;

  -- consume lote por lote, empezando por el que vence primero
  for r in
    select id, cantidad from public.producto_lotes
     where producto_id = p_producto_id and cantidad > 0
     order by vencimiento asc nulls last, id asc
  loop
    exit when v_resta <= 0;
    v_toma := least(r.cantidad, v_resta);
    update public.producto_lotes
       set cantidad = cantidad - v_toma, updated_at = now()
     where id = r.id;
    v_resta := v_resta - v_toma;
  end loop;

  -- si se vendió más de lo que había: el sobrante YA NO se refleja en
  -- negativo (antes sí) — el stock simplemente se queda en 0.

  -- los lotes que quedaron en cero ya no sirven: se limpian
  delete from public.producto_lotes
   where producto_id = p_producto_id and cantidad = 0;
end;
$$;

-- ---------- 3) Restricción a nivel de base: respaldo final, sin excepción ----------
alter table public.productos
  drop constraint if exists productos_stock_no_negativo;
alter table public.productos
  add constraint productos_stock_no_negativo check (stock_actual >= 0);

alter table public.producto_lotes
  drop constraint if exists producto_lotes_cantidad_no_negativa;
alter table public.producto_lotes
  add constraint producto_lotes_cantidad_no_negativa check (cantidad >= 0);

-- ---------- 4) Comprobación: no debe quedar ninguna fila negativa ----------
select 'productos' as tabla, count(*) as filas_negativas
from public.productos where stock_actual < 0
union all
select 'producto_lotes', count(*)
from public.producto_lotes where cantidad < 0;
