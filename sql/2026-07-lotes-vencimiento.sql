-- ================================================================
-- LOTES DE VENCIMIENTO (julio 2026)
--
-- Problema: un producto tenía UNA sola fecha de vencimiento. En la
-- realidad hay 9 sándwiches que vencen el 27 y 1 que vence hoy.
--
-- Solución: tabla public.producto_lotes — cada fila es "cantidad +
-- fecha". El stock del producto pasa a ser la SUMA de sus lotes
-- (lo mantiene un trigger), y cuando Fudo vende, se descuenta del
-- lote que vence primero (FIFO).
--
-- Solo aplica a los productos marcados como perecederos. Los demás
-- siguen funcionando igual que siempre (stock escrito a mano).
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Es idempotente: se puede correr más de una vez.
-- ================================================================

-- ---------- 1) Tabla de lotes ----------
create table if not exists public.producto_lotes (
  id          bigserial primary key,
  producto_id bigint not null references public.productos(id) on delete cascade,
  cantidad    numeric not null default 0,
  vencimiento date,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists idx_lotes_producto on public.producto_lotes(producto_id);
create index if not exists idx_lotes_venc     on public.producto_lotes(producto_id, vencimiento);

-- ---------- 2) Permisos (mismo criterio que el resto: personal interno) ----------
alter table public.producto_lotes enable row level security;

do $$
declare pol record;
begin
  for pol in select policyname from pg_policies
             where schemaname='public' and tablename='producto_lotes'
  loop
    execute format('drop policy if exists %I on public.producto_lotes', pol.policyname);
  end loop;
end $$;

create policy "producto_lotes all" on public.producto_lotes
  for all to anon, authenticated using (true) with check (true);

grant select, insert, update, delete on public.producto_lotes to anon, authenticated;
grant usage, select on sequence public.producto_lotes_id_seq to anon, authenticated;

-- ---------- 3) El stock del producto = suma de sus lotes ----------
create or replace function public.sync_stock_desde_lotes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare v_pid bigint;
begin
  v_pid := coalesce(new.producto_id, old.producto_id);

  update public.productos p
     set stock_actual = coalesce((
           select sum(l.cantidad) from public.producto_lotes l
            where l.producto_id = v_pid), 0),
         updated_at = now()
   where p.id = v_pid;

  return null;   -- trigger AFTER: el valor de retorno no se usa
end;
$$;

drop trigger if exists trg_sync_stock_lotes on public.producto_lotes;
create trigger trg_sync_stock_lotes
  after insert or update or delete on public.producto_lotes
  for each row execute function public.sync_stock_desde_lotes();

-- ---------- 4) Descontar por FIFO (primero lo que vence antes) ----------
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

  -- si se vendió más de lo que había, el sobrante queda en negativo en el
  -- lote más próximo (para que el stock siga reflejando la realidad)
  if v_resta > 0 then
    update public.producto_lotes
       set cantidad = cantidad - v_resta, updated_at = now()
     where id = (select id from public.producto_lotes
                  where producto_id = p_producto_id
                  order by vencimiento asc nulls last, id asc
                  limit 1);
  end if;

  -- los lotes que quedaron en cero ya no sirven: se limpian
  delete from public.producto_lotes
   where producto_id = p_producto_id and cantidad = 0;
end;
$$;

grant execute on function public.descontar_lotes(bigint, numeric) to anon, authenticated;

-- ---------- 5) Migrar lo que ya existe ----------
-- Cada producto perecedero con fecha pasa a tener su primer lote.
insert into public.producto_lotes(producto_id, cantidad, vencimiento)
select p.id, coalesce(p.stock_actual, 0), p.vencimiento
from public.productos p
where p.activo = 'SÍ'
  and p.vencimiento is not null
  and coalesce(p.perecedero, p.rubro = 'Sándwiches') = true
  and not exists (select 1 from public.producto_lotes l where l.producto_id = p.id);


-- ---------- 7) Motor v3: descontar del lote que vence primero ----------
-- Igual que el motor v2, pero si el producto tiene lotes, el descuento
-- sale del más próximo a vencer en vez del stock suelto.
create or replace function public.fudo_procesar_item(
  p_sede                text,
  p_fudo_sale_id        text,
  p_fudo_item_id        text,
  p_fudo_product_id     text,
  p_fudo_product_nombre text,
  p_cantidad            numeric,
  p_sale_type           text default 'EAT-IN'   -- EAT-IN | TAKEAWAY | DELIVERY
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
      cantidad_vendida, producto_id, producto_nombre, descuento, aplicado)
    values (p_sede, p_fudo_sale_id, p_fudo_item_id, p_fudo_product_id, p_fudo_product_nombre,
      p_cantidad, null, '(sin receta)', null, false)
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
      cantidad_vendida, producto_id, producto_nombre, descuento, aplicado)
    values (p_sede, p_fudo_sale_id, p_fudo_item_id, p_fudo_product_id, p_fudo_product_nombre,
      p_cantidad, r.producto_id, r.nombre, p_cantidad * r.por_unidad, v_aplicar)
    on conflict (sede, fudo_item_id, coalesce(producto_id, -1)) do nothing
    returning * into v_mov;

    if found and v_aplicar then
      -- si el producto lleva lotes de vencimiento, se descuenta del que
      -- vence primero (el trigger de lotes recalcula el stock del producto);
      -- si no, se descuenta el stock directo como siempre
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

-- ---------- 6) Comprobación ----------
select p.sede, p.producto, p.stock_actual as stock_total,
       l.cantidad, l.vencimiento
from public.productos p
join public.producto_lotes l on l.producto_id = p.id
where p.activo = 'SÍ'
order by p.sede, p.producto, l.vencimiento;
