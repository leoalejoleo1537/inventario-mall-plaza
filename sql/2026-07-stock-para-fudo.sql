-- ================================================================
-- CÁLCULO DEL STOCK QUE SE LE MANDA A FUDO
--
-- La fórmula espejo del motor de descuento: en vez de restar insumos
-- por cada venta, calcula cuántas ventas más aguanta el stock que
-- queda. Para cada receta manda el insumo que primero se acaba — si
-- el juguete alcanza para 5 combos, da igual que el muffin alcance
-- para 30: solo se pueden armar 5.
--
-- El cálculo vive ACÁ y no en la Edge Function, por la misma razón que
-- el descuento: una sola fuente de verdad, que se puede revisar con un
-- SELECT sin desplegar nada.
--
-- Este archivo NO empuja nada a Fudo. Solo calcula y deja la bitácora
-- lista. Correr en Supabase -> SQL Editor. Es idempotente.
-- ================================================================


-- ================================================================
-- 1) Bitácora de lo que se le manda a Fudo
--
-- Sin esto, un empuje equivocado no deja rastro y no hay cómo saber
-- qué pasó ni cómo volver atrás. Guarda el valor ANTERIOR de Fudo,
-- así siempre se puede reconstruir el estado previo.
-- ================================================================
create table if not exists public.fudo_stock_push(
  id               bigint generated always as identity primary key,
  sede             text        not null,
  fudo_product_id  text        not null,
  producto_fudo    text,
  stock_anterior   numeric,              -- lo que tenía Fudo antes
  stock_enviado    numeric     not null, -- lo que le mandamos
  ok               boolean     not null,
  detalle          text,                 -- el error, si lo hubo
  quien            text,                 -- correo de quien lo mandó
  created_at       timestamptz not null default now()
);
create index if not exists fudo_stock_push_sede_fecha_idx
  on public.fudo_stock_push (sede, created_at desc);

alter table public.fudo_stock_push enable row level security;
drop policy if exists "fudo_stock_push read" on public.fudo_stock_push;
create policy "fudo_stock_push read" on public.fudo_stock_push
  for select to anon, authenticated using (true);
grant select on public.fudo_stock_push to anon, authenticated;
-- Escribe solo la Edge Function, con la llave de servicio (salta RLS).


-- ================================================================
-- 2) EL CÁLCULO
--
-- Devuelve UNA fila por producto de Fudo que se puede actualizar.
--   p_producto_id: si se pasa, devuelve solo los productos de Fudo
--                  cuya receta usa ESE insumo del inventario. Es lo
--                  que necesita el botón de la ficha: cambiar el
--                  stock de un insumo puede afectar a varios
--                  productos de Fudo (un selladito está en el combo
--                  KIDS y también se vende solo).
--
-- Solo entran los que cumplen las tres condiciones: tienen receta,
-- están activos en Fudo, y Fudo les lleva el stock (stockControl).
-- Un producto que no cumple las tres no se toca nunca.
-- ================================================================
create or replace function public.fudo_stock_calculado(
  p_sede        text,
  p_producto_id bigint default null
)
returns table(
  fudo_product_id   text,
  producto_fudo     text,
  stock_en_fudo     numeric,
  stock_calculado   numeric,
  insumo_que_limita text,
  insumos           text,
  deja_en_cero      boolean   -- ⚠ Fudo tiene stock y pasaría a 0
)
language sql
stable
security definer
set search_path = public
as $$
  with ins as (
    select r.fudo_product_id,
           p.producto,
           coalesce(p.stock_actual,0) as stock,
           floor(coalesce(p.stock_actual,0) / nullif(ri.cantidad,0)) as alcanza
    from public.recetas r
    join public.receta_items ri on ri.receta_id = r.id
    join public.productos p     on p.id = ri.producto_id
    where r.sede = p_sede
      and r.activo
      and coalesce(ri.cantidad,0) > 0
      -- si se pide un insumo puntual, solo las recetas que lo usan
      and (p_producto_id is null
           or exists (select 1 from public.receta_items ri2
                       where ri2.receta_id = r.id
                         and ri2.producto_id = p_producto_id
                         and coalesce(ri2.cantidad,0) > 0))
  ),
  calc as (
    select i.fudo_product_id,
           min(i.alcanza)                                as calculado,
           (array_agg(i.producto order by i.alcanza))[1] as limita,
           string_agg(i.producto||' ('||i.stock||')', ' · ' order by i.alcanza) as detalle
    from ins i
    group by i.fudo_product_id
  )
  select c.fudo_product_id,
         fp.nombre,
         (fp.raw->>'stock')::numeric,
         c.calculado,
         c.limita,
         c.detalle,
         (c.calculado = 0 and coalesce((fp.raw->>'stock')::numeric,0) > 0)
  from calc c
  join public.fudo_productos fp
    on fp.sede = p_sede and fp.fudo_product_id = c.fudo_product_id
  where fp.activo
    and coalesce((fp.raw->>'stockControl')::boolean, false)
  order by fp.nombre;
$$;

grant execute on function public.fudo_stock_calculado(text, bigint) to anon, authenticated;


-- ================================================================
-- 3) Comprobación: qué se mandaría hoy, y qué quedaría en cero
-- ================================================================
select count(*) filter (where true)          as se_actualizarian,
       count(*) filter (where deja_en_cero)  as quedarian_en_cero
from public.fudo_stock_calculado('plaza');

-- El detalle de los que quedarían en cero. MIRAR UNO POR UNO: si el
-- insumo que limita no tiene relación con el producto, la receta está
-- cruzada y hay que arreglarla antes de empujar.
select producto_fudo, stock_en_fudo, stock_calculado, insumo_que_limita, insumos
from public.fudo_stock_calculado('plaza')
where deja_en_cero
order by stock_en_fudo desc;
