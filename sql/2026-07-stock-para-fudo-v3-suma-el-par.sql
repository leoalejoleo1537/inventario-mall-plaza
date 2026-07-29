-- ================================================================
-- STOCK PARA FUDO (v3) — sumar vitrina + congelador
--
-- El problema que resuelve, con el caso real de Jhon:
--   Alfajor artesanal          (Vitrina)     →  2
--   Alfajor artesanal congelador (Congelador) → 15
--   La receta de Fudo apunta SOLO al de vitrina, así que a Fudo le
--   llegaba 2 cuando en el café hay 17.
--
-- Ahora, para saber cuánto se puede vender, el stock de un insumo es la
-- SUMA de todos los productos que comparten su nombre base — el mismo
-- criterio que ya usa el motor de descuento para reponer desde el
-- congelador, y el mismo "Total" que la app muestra en la lista.
--
-- Esto NO cambia el descuento: al vender se sigue descontando del
-- producto que dice la receta, y si la vitrina se queda en 0 el motor
-- baja unidades del congelador como ya lo hacía.
--
-- Correr en Supabase -> SQL Editor. Es idempotente y no modifica datos.
-- ⚠️ Correr DESPUÉS de haber emparejado los nombres
--    (sql/2026-07-emparejar-vitrina-congelador.sql), porque la suma se
--    apoya justamente en que los nombres calcen.
-- ================================================================


-- ================================================================
-- 1) base_nombre() — el nombre sin el apellido de sección
--
-- Se crea SOLO si no existe. El motor de descuento ya la usa; volver a
-- definirla podría cambiarle el comportamiento al descuento sin querer,
-- y eso es exactamente lo que no se hace.
-- ================================================================
do $$
begin
  if not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'base_nombre'
  ) then
    execute $f$
      create function public.base_nombre(t text) returns text
      language sql immutable as $q$
        select regexp_replace(
                 lower(translate(coalesce(t,''),'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
                 '\s+(vitrina|congelador)$', '')
      $q$;
    $f$;
  end if;
end $$;


-- ================================================================
-- 2) EL CÁLCULO, sumando la pareja
-- ================================================================
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
  ignorados         text,     -- envases: no limitan la venta
  sumados           text,     -- pares vitrina+congelador que se sumaron
  deja_en_cero      boolean
)
language sql
stable
security definer
set search_path = public
as $$
  -- cuánto hay de cada nombre base, sumando todas sus secciones
  with total_por_base as (
    select public.base_nombre(producto) as base,
           sum(coalesce(stock_actual,0)) as total,
           count(*)                      as secciones,
           string_agg(producto||' '||coalesce(stock_actual,0), ' + ' order by producto) as desglose
    from public.productos
    where sede = p_sede and activo = 'SÍ'
    group by 1
  ),
  todos as (
    select r.fudo_product_id,
           p.producto,
           tb.total                                        as stock,
           tb.secciones,
           tb.desglose,
           floor(tb.total / nullif(ri.cantidad,0))          as alcanza,
           (coalesce(nullif(trim(p.tipo),''),'—') = any(p_tipos_libres)) as es_envase
    from public.recetas r
    join public.receta_items ri on ri.receta_id = r.id
    join public.productos p     on p.id = ri.producto_id
    join total_por_base tb      on tb.base = public.base_nombre(p.producto)
    where r.sede = p_sede
      and r.activo
      and coalesce(ri.cantidad,0) > 0
      -- Al pedir UN producto se toman también sus hermanos de sección:
      -- tocar el alfajor del congelador tiene que mover lo mismo que
      -- tocar el de la vitrina, porque para Fudo son el mismo producto.
      and (p_producto_id is null
           or exists (
             select 1
             from public.receta_items ri2
             join public.productos p2 on p2.id = ri2.producto_id
             where ri2.receta_id = r.id
               and coalesce(ri2.cantidad,0) > 0
               and public.base_nombre(p2.producto) = (
                     select public.base_nombre(px.producto)
                     from public.productos px where px.id = p_producto_id)
           ))
  ),
  calc as (
    select t.fudo_product_id,
           min(t.alcanza) filter (where not t.es_envase)                       as calculado,
           (array_agg(t.producto order by t.alcanza)
              filter (where not t.es_envase))[1]                               as limita,
           string_agg(t.producto||' ('||t.stock||')', ' · ' order by t.alcanza)
              filter (where not t.es_envase)                                   as detalle,
           string_agg(t.producto||' ('||t.stock||')', ' · ' order by t.producto)
              filter (where t.es_envase)                                       as envases,
           string_agg(t.desglose, ' · ' order by t.producto)
              filter (where not t.es_envase and t.secciones > 1)               as sumas
    from todos t
    group by t.fudo_product_id
  )
  select c.fudo_product_id, fp.nombre, (fp.raw->>'stock')::numeric,
         c.calculado, c.limita, c.detalle, c.envases, c.sumas,
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


-- ================================================================
-- 3) COMPROBACIÓN — TIENE QUE SALIR UNA SOLA FILA
--
-- Dos versiones conviviendo vuelven ambigua la llamada por la API y la
-- petición se rechaza antes de ejecutar nada. Es lo que dejó el
-- inventario 15 horas sin descontar el 2026-07-27.
-- ================================================================
select p.oid::regprocedure as funcion_instalada
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='fudo_stock_calculado';


-- ================================================================
-- 4) LOS QUE AHORA SUMAN LA PAREJA
--
-- Acá tienen que aparecer los alfajores, brownies, muffins, donas…
-- La columna "sumados" muestra de dónde sale cada número.
-- ================================================================
select producto_fudo, stock_en_fudo, stock_calculado, insumo_que_limita, sumados
from public.fudo_stock_calculado('plaza')
where sumados is not null
order by producto_fudo;
