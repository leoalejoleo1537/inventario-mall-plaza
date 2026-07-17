-- ================================================================
-- FASE 2B — Insumos según tipo de venta + auto-emparejador (julio 2026)
--
-- 1) Columna "aplica" en receta_items:
--      'siempre' -> se descuenta en toda venta (default)
--      'llevar'  -> solo si la venta es TAKEAWAY o DELIVERY
--      'servir'  -> solo si la venta es EAT-IN (servir en el local)
--
-- 2) Motor v2: fudo_procesar_item() ahora recibe el tipo de venta
--    (saleType de Fudo) y descuenta solo los insumos que aplican.
--
-- 3) Auto-emparejador (sede plaza): crea recetas 1-a-1 para cada
--    producto ACTIVO de Fudo cuyo nombre coincida con un producto
--    del inventario (ignora mayúsculas/tildes/espacios).
--      * si el nombre coincide con 2 productos (ej. copia en
--        Congelador), prefiere el que NO está en Congelador.
--      * no toca recetas que ya tienen insumos (hechas a mano).
--    Al final: lista de productos de Fudo que quedaron SIN receta.
-- ================================================================

-- ---------- 1) columna "aplica" ----------
alter table public.receta_items
  add column if not exists aplica text not null default 'siempre'
  check (aplica in ('siempre','llevar','servir'));

-- ---------- 2) motor v2 ----------
drop function if exists public.fudo_procesar_item(text,text,text,text,text,numeric);

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

-- ---------- 3) auto-emparejador (sede plaza) ----------
with candidatos as (
  select distinct on (fp.fudo_product_id)
         fp.fudo_product_id,
         fp.nombre  as fudo_nombre,
         p.id       as producto_id
  from public.fudo_productos fp
  join public.productos p
    on p.sede = fp.sede and p.activo = 'SÍ'
   and translate(lower(regexp_replace(trim(p.producto ),'\s+',' ','g')),'áéíóúñü','aeiounu')
     = translate(lower(regexp_replace(trim(fp.nombre  ),'\s+',' ','g')),'áéíóúñü','aeiounu')
  where fp.sede = 'plaza' and fp.activo = true
  order by fp.fudo_product_id, (p.rubro = 'Congelador') asc, p.id
)
insert into public.recetas(sede, fudo_product_id, fudo_product_nombre)
select 'plaza', fudo_product_id, fudo_nombre from candidatos
on conflict (sede, fudo_product_id) do nothing;

with candidatos as (
  select distinct on (fp.fudo_product_id)
         fp.fudo_product_id,
         p.id as producto_id
  from public.fudo_productos fp
  join public.productos p
    on p.sede = fp.sede and p.activo = 'SÍ'
   and translate(lower(regexp_replace(trim(p.producto ),'\s+',' ','g')),'áéíóúñü','aeiounu')
     = translate(lower(regexp_replace(trim(fp.nombre  ),'\s+',' ','g')),'áéíóúñü','aeiounu')
  where fp.sede = 'plaza' and fp.activo = true
  order by fp.fudo_product_id, (p.rubro = 'Congelador') asc, p.id
)
insert into public.receta_items(receta_id, producto_id, cantidad, aplica)
select r.id, c.producto_id, 1, 'siempre'
from candidatos c
join public.recetas r on r.sede = 'plaza' and r.fudo_product_id = c.fudo_product_id
where not exists (select 1 from public.receta_items ri where ri.receta_id = r.id)  -- no tocar recetas hechas a mano
on conflict (receta_id, producto_id) do nothing;

-- ---------- Comprobación ----------
select count(*) as recetas_en_plaza from public.recetas where sede='plaza';

-- Productos ACTIVOS de Fudo que quedaron SIN receta (para depurar a mano)
select fp.nombre as producto_fudo_sin_receta, fp.code
from public.fudo_productos fp
where fp.sede='plaza' and fp.activo=true
  and not exists (select 1 from public.recetas r
                  where r.sede='plaza' and r.fudo_product_id=fp.fudo_product_id)
order by fp.nombre;
