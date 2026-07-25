-- ================================================================
-- GUARDAR LA FECHA REAL DE LA VENTA (julio 2026)
--
-- Problema: en fudo_movimientos solo guardábamos created_at, que es
-- CUÁNDO CORRIÓ LA SINCRONIZACIÓN — no cuándo se vendió. Por eso:
--   1. No se puede medir cuánto demora un descuento en reflejarse.
--   2. No se puede analizar la demanda por hora ni por día.
--
-- Esto agrega la columna venta_at con la fecha que entrega Fudo, y el
-- motor pasa a guardarla. Con eso, la diferencia entre venta_at y
-- created_at ES la demora real, medible.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Después hay que actualizar la Edge Function fudo-sync-ventas.
-- Es idempotente.
-- ================================================================

-- ---------- 1) La columna ----------
alter table public.fudo_movimientos
  add column if not exists venta_at timestamptz;

create index if not exists idx_mov_venta_at
  on public.fudo_movimientos (sede, venta_at desc);

-- ---------- 2) Motor v4: igual que el v3, pero recibe y guarda venta_at ----------
-- Se borra la firma anterior para que no queden dos versiones conviviendo.
drop function if exists public.fudo_procesar_item(text,text,text,text,text,numeric,text);

create or replace function public.fudo_procesar_item(
  p_sede                text,
  p_fudo_sale_id        text,
  p_fudo_item_id        text,
  p_fudo_product_id     text,
  p_fudo_product_nombre text,
  p_cantidad            numeric,
  p_sale_type           text default 'EAT-IN',   -- EAT-IN | TAKEAWAY | DELIVERY
  p_venta_at            timestamptz default null -- cuándo se vendió DE VERDAD
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
      -- si el producto lleva lotes de vencimiento, se descuenta del que
      -- vence primero; si no, del stock directo
      if exists (select 1 from public.producto_lotes l where l.producto_id = r.producto_id) then
        perform public.descontar_lotes(r.producto_id, p_cantidad * r.por_unidad);
      else
        update public.productos
          set stock_actual = coalesce(stock_actual,0) - (p_cantidad * r.por_unidad),
              updated_at = now()
        where id = r.producto_id;
      end if;
    end if;

    if found then return next v_mov; end if;
  end loop;

  return;
end;
$$;

-- ---------- 3) LA MEDICIÓN: cuánto demora de verdad ----------
-- Correr esto DESPUÉS de un par de días de uso. Muestra, por cada venta,
-- cuántos minutos pasaron entre que se vendió y que se descontó.
--
-- select sede,
--        count(*)                                                        as movimientos,
--        round(avg(extract(epoch from (created_at - venta_at))/60)::numeric, 1) as demora_promedio_min,
--        round(min(extract(epoch from (created_at - venta_at))/60)::numeric, 1) as demora_minima_min,
--        round(max(extract(epoch from (created_at - venta_at))/60)::numeric, 1) as demora_maxima_min
--   from public.fudo_movimientos
--  where venta_at is not null
--    and created_at > now() - interval '7 days'
--  group by sede;
--
-- Si la demora promedio es alta pero la MÍNIMA es baja, el problema es
-- que nadie aprieta el botón (lo resuelve el cron automático).
-- Si hasta la mínima es alta, el retraso viene de Fudo y no depende de
-- nosotros.

-- ---------- 4) Comprobación de que quedó bien ----------
select column_name, data_type
from information_schema.columns
where table_schema='public' and table_name='fudo_movimientos' and column_name='venta_at';
