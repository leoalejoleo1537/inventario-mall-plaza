-- ================================================================
-- v2 CORTO — solo el cálculo. Sin las consultas de comprobación,
-- para que el panel de Supabase no se corte con un archivo largo.
--
-- Qué hace: al calcular cuánto se puede vender, ignora los insumos de
-- tipo 'Envases'. Quedarse sin bandejas no es quedarse sin torta.
-- Al VENDER se siguen descontando igual — esto no toca el descuento.
--
-- Pegar TODO y Run. Idempotente. No modifica ningún dato.
-- ================================================================
alter table public.productos add column if not exists tipo text;

drop function if exists public.fudo_stock_calculado(text, bigint);
drop function if exists public.fudo_stock_calculado(text, bigint, text[]);

create or replace function public.fudo_stock_calculado(
  p_sede         text,
  p_producto_id  bigint  default null,
  p_tipos_libres text[]  default array['Envases']
)
returns table(
  fudo_product_id   text,
  producto_fudo     text,
  stock_en_fudo     numeric,
  stock_calculado   numeric,
  insumo_que_limita text,
  insumos           text,
  ignorados         text,
  deja_en_cero      boolean
)
language sql stable security definer set search_path = public
as $$
  with todos as (
    select r.fudo_product_id, p.producto,
           coalesce(p.stock_actual,0) as stock,
           floor(coalesce(p.stock_actual,0) / nullif(ri.cantidad,0)) as alcanza,
           (coalesce(nullif(trim(p.tipo),''),'—') = any(p_tipos_libres)) as es_envase
    from public.recetas r
    join public.receta_items ri on ri.receta_id = r.id
    join public.productos p     on p.id = ri.producto_id
    where r.sede = p_sede and r.activo and coalesce(ri.cantidad,0) > 0
      and (p_producto_id is null
           or exists (select 1 from public.receta_items ri2
                       where ri2.receta_id = r.id and ri2.producto_id = p_producto_id
                         and coalesce(ri2.cantidad,0) > 0))
  ),
  calc as (
    select t.fudo_product_id,
           min(t.alcanza) filter (where not t.es_envase) as calculado,
           (array_agg(t.producto order by t.alcanza)
              filter (where not t.es_envase))[1] as limita,
           string_agg(t.producto||' ('||t.stock||')', ' · ' order by t.alcanza)
              filter (where not t.es_envase) as detalle,
           string_agg(t.producto||' ('||t.stock||')', ' · ' order by t.producto)
              filter (where t.es_envase) as envases
    from todos t group by t.fudo_product_id
  )
  select c.fudo_product_id, fp.nombre, (fp.raw->>'stock')::numeric,
         c.calculado, c.limita, c.detalle, c.envases,
         (c.calculado = 0 and coalesce((fp.raw->>'stock')::numeric,0) > 0)
  from calc c
  join public.fudo_productos fp
    on fp.sede = p_sede and fp.fudo_product_id = c.fudo_product_id
  where fp.activo
    and coalesce((fp.raw->>'stockControl')::boolean, false)
    and c.calculado is not null
  order by fp.nombre;
$$;

grant execute on function public.fudo_stock_calculado(text, bigint, text[]) to anon, authenticated;
