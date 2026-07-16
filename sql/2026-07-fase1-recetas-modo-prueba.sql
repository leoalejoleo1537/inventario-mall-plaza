-- ================================================================
-- FASE 1 — Recetas + motor de descuento con MODO PRUEBA (julio 2026)
--
-- Crea la base para el "puente" Fudo -> inventario:
--   * recetas          : un producto de Fudo = varios insumos
--   * receta_items      : cada insumo y cuánto descuenta por unidad
--   * fudo_sync         : modo (prueba/real) y cursor por sede
--   * fudo_movimientos  : bitácora de lo que se descontó (o descontaría)
--
-- Incluye la función fudo_procesar_item(), que en modo 'prueba' SOLO
-- registra en la bitácora sin tocar el stock, y en modo 'real'
-- descuenta de verdad. Es idempotente: nunca descuenta dos veces el
-- mismo ítem de venta.
--
-- Requiere que ya exista la tabla public.productos.
-- ================================================================

-- ---------- Tablas ----------
create table if not exists public.recetas(
  id                  bigint generated always as identity primary key,
  sede                text    not null,
  fudo_product_id     text    not null,
  fudo_product_nombre text,
  activo              boolean not null default true,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (sede, fudo_product_id)
);

create table if not exists public.receta_items(
  id          bigint generated always as identity primary key,
  receta_id   bigint  not null references public.recetas(id) on delete cascade,
  producto_id bigint  not null references public.productos(id) on delete cascade,
  cantidad    numeric not null default 1,     -- cuánto se descuenta por unidad vendida
  created_at  timestamptz not null default now(),
  unique (receta_id, producto_id)
);

create table if not exists public.fudo_sync(
  sede            text primary key,
  modo            text not null default 'prueba' check (modo in ('prueba','real')),
  ultima_venta_at timestamptz,                 -- cursor: hasta qué venta ya procesamos
  updated_at      timestamptz not null default now()
);

create table if not exists public.fudo_movimientos(
  id                  bigint generated always as identity primary key,
  sede                text not null,
  fudo_sale_id        text,
  fudo_item_id        text not null,
  fudo_product_id     text,
  fudo_product_nombre text,
  cantidad_vendida    numeric,
  producto_id         bigint,
  producto_nombre     text,
  descuento           numeric,
  aplicado            boolean not null default false,  -- true = se tocó el stock; false = solo simulado
  created_at          timestamptz not null default now()
);

-- Idempotencia: un ítem de venta descuenta cada insumo una sola vez.
-- (coalesce para tratar el caso "sin receta", donde producto_id es NULL)
create unique index if not exists fudo_movimientos_uni
  on public.fudo_movimientos (sede, fudo_item_id, coalesce(producto_id, -1));

-- ---------- Seguridad (mismo patrón que el resto de la app) ----------
alter table public.recetas          enable row level security;
alter table public.receta_items     enable row level security;
alter table public.fudo_sync        enable row level security;
alter table public.fudo_movimientos enable row level security;

drop policy if exists "recetas all"           on public.recetas;
drop policy if exists "receta_items all"      on public.receta_items;
drop policy if exists "fudo_sync all"         on public.fudo_sync;
drop policy if exists "fudo_movimientos read" on public.fudo_movimientos;

create policy "recetas all"           on public.recetas          for all    to anon using (true) with check (true);
create policy "receta_items all"      on public.receta_items     for all    to anon using (true) with check (true);
create policy "fudo_sync all"         on public.fudo_sync        for all    to anon using (true) with check (true);
create policy "fudo_movimientos read" on public.fudo_movimientos for select to anon using (true);

grant select, insert, update, delete on public.recetas       to anon;
grant select, insert, update, delete on public.receta_items  to anon;
grant select, insert, update, delete on public.fudo_sync     to anon;
grant select                         on public.fudo_movimientos to anon;
grant usage, select on sequence public.recetas_id_seq      to anon;
grant usage, select on sequence public.receta_items_id_seq to anon;

-- ---------- Helper: cambiar el modo de una sede ----------
create or replace function public.fudo_set_modo(p_sede text, p_modo text)
returns void
language sql
as $$
  insert into public.fudo_sync(sede, modo, updated_at) values (p_sede, p_modo, now())
  on conflict (sede) do update set modo = excluded.modo, updated_at = now();
$$;

-- ---------- Motor de descuento ----------
-- Procesa UN ítem de una venta de Fudo. Devuelve las filas de bitácora
-- generadas. En modo 'prueba' no toca el stock; en 'real' sí.
create or replace function public.fudo_procesar_item(
  p_sede                text,
  p_fudo_sale_id        text,
  p_fudo_item_id        text,
  p_fudo_product_id     text,
  p_fudo_product_nombre text,
  p_cantidad            numeric
) returns setof public.fudo_movimientos
language plpgsql
security definer
set search_path = public
as $$
declare
  v_modo      text;
  v_receta_id bigint;
  v_aplicar   boolean;
  r           record;
  v_mov       public.fudo_movimientos;
begin
  -- modo de la sede (si no existe, la crea en 'prueba')
  select modo into v_modo from public.fudo_sync where sede = p_sede;
  if v_modo is null then
    insert into public.fudo_sync(sede, modo) values (p_sede, 'prueba')
      on conflict (sede) do nothing;
    v_modo := 'prueba';
  end if;
  v_aplicar := (v_modo = 'real');

  -- receta activa para ese producto de Fudo en esa sede
  select id into v_receta_id
  from public.recetas
  where sede = p_sede and fudo_product_id = p_fudo_product_id and activo = true;

  -- sin receta: deja constancia en la bitácora (para poder crearla luego)
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

  -- por cada insumo de la receta
  for r in
    select ri.producto_id, ri.cantidad as por_unidad, pr.producto as nombre
    from public.receta_items ri
    join public.productos pr on pr.id = ri.producto_id
    where ri.receta_id = v_receta_id
  loop
    insert into public.fudo_movimientos(
      sede, fudo_sale_id, fudo_item_id, fudo_product_id, fudo_product_nombre,
      cantidad_vendida, producto_id, producto_nombre, descuento, aplicado)
    values (p_sede, p_fudo_sale_id, p_fudo_item_id, p_fudo_product_id, p_fudo_product_nombre,
      p_cantidad, r.producto_id, r.nombre, p_cantidad * r.por_unidad, v_aplicar)
    on conflict (sede, fudo_item_id, coalesce(producto_id, -1)) do nothing
    returning * into v_mov;

    -- solo si la fila es NUEVA y estamos en modo real, descuenta del stock
    if found and v_aplicar then
      update public.productos
        set stock_actual = coalesce(stock_actual,0) - (p_cantidad * r.por_unidad),
            updated_at = now()
      where id = r.producto_id;
    end if;

    if found then return next v_mov; end if;
  end loop;

  return;
end;
$$;
