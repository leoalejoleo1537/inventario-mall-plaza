-- ================================================================
-- TOPE EN CERO + REPOSICIÓN AUTOMÁTICA DESDE CONGELADOR (julio 2026)
--
-- Problema: al vender en Fudo más de lo que quedaba en Vitrina, el stock
-- se iba a negativo (-2 Cinnamon Roll no significa nada en la realidad).
--
-- Solución, en dos partes:
--   1) El stock de un producto NUNCA baja de 0, tenga o no pareja.
--   2) Si el producto tiene pareja en Congelador (mismo nombre base, el
--      mismo criterio que ya usa el "Total" — "Brownie vitrina" y
--      "Brownie congelador" son la misma pareja) y la venta haría que
--      Vitrina llegue a 0 o menos, se trasladan SIEMPRE 4 unidades desde
--      el Congelador a la Vitrina (o las que haya, si hay menos de 4)
--      ANTES de aplicar el descuento de esa venta.
--
-- Aplica a TODOS los productos con pareja Vitrina/Congelador, detectados
-- automáticamente por nombre — no hace falta listar boller ía por
-- boller ía. Si un producto no tiene pareja, simplemente no baja de 0.
--
-- Solo afecta productos que NO usan lotes de vencimiento (los que sí
-- usan lotes — hoy los sándwiches — siguen funcionando como ya estaban,
-- con FIFO por fecha).
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Es idempotente.
-- ================================================================

-- ---------- 1) Nombre base, ignorando el apellido de sección ----------
-- Mismo criterio que baseNombre() en la app: sin tildes/mayúsculas,
-- sin el "vitrina"/"congelador" del final.
create or replace function public.base_nombre(t text)
returns text language sql immutable as $$
  select regexp_replace(
           translate(lower(regexp_replace(trim(coalesce(t,'')),'\s+',' ','g')),'áéíóúñü','aeiounu'),
           '\s+(vitrina|congelador)$', '', 'i'
         );
$$;

-- ---------- 2) Descontar con reposición y tope en 0 ----------
create or replace function public.descontar_con_reposicion(p_sede text, p_producto_id bigint, p_cantidad numeric)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stock_actual numeric;
  v_base         text;
  v_pareja_id    bigint;
  v_pareja_stock numeric;
  v_trasladar    numeric;
begin
  if p_cantidad is null or p_cantidad <= 0 then return; end if;

  select stock_actual, public.base_nombre(producto)
    into v_stock_actual, v_base
    from public.productos where id = p_producto_id;
  v_stock_actual := coalesce(v_stock_actual, 0);

  -- ¿esta venta deja el producto en 0 o menos? -> buscar pareja en Congelador
  if v_stock_actual - p_cantidad <= 0 then
    select p2.id, p2.stock_actual into v_pareja_id, v_pareja_stock
      from public.productos p2
     where p2.sede = p_sede and p2.activo = 'SÍ' and p2.rubro = 'Congelador'
       and p2.id <> p_producto_id
       and public.base_nombre(p2.producto) = v_base
     limit 1;

    if v_pareja_id is not null and coalesce(v_pareja_stock,0) > 0 then
      v_trasladar := least(4, v_pareja_stock);
      update public.productos set stock_actual = stock_actual - v_trasladar, updated_at = now()
       where id = v_pareja_id;
      update public.productos set stock_actual = coalesce(stock_actual,0) + v_trasladar, updated_at = now()
       where id = p_producto_id;
    end if;
  end if;

  -- descuento final: nunca queda negativo, tenga o no haya pareja / stock suficiente
  update public.productos
     set stock_actual = greatest(0, coalesce(stock_actual,0) - p_cantidad),
         updated_at = now()
   where id = p_producto_id;
end;
$$;

grant execute on function public.descontar_con_reposicion(text, bigint, numeric) to anon, authenticated;

-- ---------- 3) Motor v5: usa la reposición para productos SIN lotes ----------
-- Igual que el motor v4 (con venta_at), solo cambia esta rama.
drop function if exists public.fudo_procesar_item(text,text,text,text,text,numeric,text,timestamptz);

create or replace function public.fudo_procesar_item(
  p_sede                text,
  p_fudo_sale_id        text,
  p_fudo_item_id        text,
  p_fudo_product_id     text,
  p_fudo_product_nombre text,
  p_cantidad            numeric,
  p_sale_type           text default 'EAT-IN',
  p_venta_at            timestamptz default null
) returns setof public.fudo_movimientos
language plpgsql
security definer
set search_path = public
as $$
declare
  v_modo      text;
  v_tipo      text;
  v_receta_id bigint;
  v_aplicar   boolean;
  r           record;
  v_mov       public.fudo_movimientos;
begin
  v_tipo := upper(coalesce(p_sale_type,'EAT-IN'));

  select modo into v_modo from public.fudo_sync where sede = p_sede;
  if v_modo is null then
    insert into public.fudo_sync(sede, modo) values (p_sede, 'prueba')
      on conflict (sede) do nothing;
    v_modo := 'prueba';
  end if;
  v_aplicar := (v_modo = 'real');

  select id into v_receta_id
  from public.recetas
  where sede = p_sede and fudo_product_id = p_fudo_product_id and activo = true;

  if v_receta_id is null then
    insert into public.fudo_movimientos(
      sede, fudo_sale_id, fudo_item_id, fudo_product_id, fudo_product_nombre,
      cantidad_vendida, producto_id, producto_nombre, descuento, aplicado, venta_at)
    values (p_sede, p_fudo_sale_id, p_fudo_item_id, p_fudo_product_id, p_fudo_product_nombre,
      p_cantidad, null, '(sin receta)', null, false, p_venta_at)
    on conflict (sede, fudo_item_id, coalesce(producto_id, -1)) do nothing
    returning * into v_mov;
    if found then return next v_mov; end if;
    return;
  end if;

  for r in
    select ri.producto_id, ri.cantidad as por_unidad, pr.producto as nombre
    from public.receta_items ri
    join public.productos pr on pr.id = ri.producto_id
    where ri.receta_id = v_receta_id
      and (   coalesce(ri.aplica,'siempre') = 'siempre'
           or (ri.aplica = 'llevar' and v_tipo in ('TAKEAWAY','DELIVERY'))
           or (ri.aplica = 'servir' and v_tipo = 'EAT-IN') )
  loop
    insert into public.fudo_movimientos(
      sede, fudo_sale_id, fudo_item_id, fudo_product_id, fudo_product_nombre,
      cantidad_vendida, producto_id, producto_nombre, descuento, aplicado, venta_at)
    values (p_sede, p_fudo_sale_id, p_fudo_item_id, p_fudo_product_id, p_fudo_product_nombre,
      p_cantidad, r.producto_id, r.nombre, p_cantidad * r.por_unidad, v_aplicar, p_venta_at)
    on conflict (sede, fudo_item_id, coalesce(producto_id, -1)) do nothing
    returning * into v_mov;

    if found and v_aplicar then
      -- perecedero con lotes: sigue igual (FIFO por fecha de vencimiento)
      if exists (select 1 from public.producto_lotes l where l.producto_id = r.producto_id) then
        perform public.descontar_lotes(r.producto_id, p_cantidad * r.por_unidad);
      else
        -- sin lotes: tope en 0 + reposición automática desde el congelador
        perform public.descontar_con_reposicion(p_sede, r.producto_id, p_cantidad * r.por_unidad);
      end if;
    end if;

    if found then return next v_mov; end if;
  end loop;

  return;
end;
$$;

-- ---------- 4) Comprobación: parejas Vitrina/Congelador detectadas ----------
select p.sede, public.base_nombre(p.producto) as producto_base,
       max(case when p.rubro='Congelador' then p.producto end)   as copia_congelador,
       max(case when p.rubro<>'Congelador' then p.producto end)  as copia_vitrina,
       sum(case when p.rubro='Congelador' then p.stock_actual else 0 end)  as stock_congelador,
       sum(case when p.rubro<>'Congelador' then p.stock_actual else 0 end) as stock_vitrina
from public.productos p
where p.activo='SÍ'
group by p.sede, public.base_nombre(p.producto)
having count(*) > 1
order by p.sede, producto_base;
