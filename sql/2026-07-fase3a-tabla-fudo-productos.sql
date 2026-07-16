-- ================================================================
-- FASE 3A — Tabla espejo de los productos de Fudo (julio 2026)
--
-- Aquí el puente "fudo-sync-productos" guarda la lista de productos
-- de cada sede tal como está en Fudo. Sirve para:
--   * el menú desplegable de la pantalla de Recetas
--   * enlazar cada receta con su producto real de Fudo
--
-- Es solo un espejo de lectura: el puente la actualiza; la app la lee.
-- ================================================================
create table if not exists public.fudo_productos(
  id              bigint generated always as identity primary key,
  sede            text not null,
  fudo_product_id text not null,
  nombre          text,
  code            text,
  precio          numeric,
  categoria_id    text,
  activo          boolean,
  raw             jsonb,                       -- todos los datos crudos del producto, por si acaso
  synced_at       timestamptz not null default now(),
  unique (sede, fudo_product_id)
);

alter table public.fudo_productos enable row level security;

drop policy if exists "fudo_productos read" on public.fudo_productos;
create policy "fudo_productos read" on public.fudo_productos for select to anon using (true);

-- La app (anon) solo lee. El puente escribe con la llave de servicio (service role),
-- que salta RLS, así que no necesita permisos de escritura para anon.
grant select on public.fudo_productos to anon;
