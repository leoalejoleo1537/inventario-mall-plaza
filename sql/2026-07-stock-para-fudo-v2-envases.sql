-- ================================================================
-- STOCK PARA FUDO (v2) — los envases no pueden frenar una venta
--
-- Por qué: la simulación mostró que "Torta amor Pedidos Ya" quedaría en
-- 0 con 8 trozos de torta disponibles, porque la receta incluye
-- "Bandeja cartón m" y esa bandeja está en 0. Lo mismo con "Sandwich
-- plateada luco Pedidos Ya", que tiene 5 sándwiches listos.
--
-- La receta NO está mal: un pedido de delivery sí gasta una bandeja, y
-- descontarla es correcto. Lo que está mal es usar ese insumo para
-- decidir CUÁNTO se puede vender. Quedarse sin bandejas no significa
-- quedarse sin torta — significa que hay que comprar bandejas.
--
-- Además, los envases son justo lo que nadie cuenta con precisión: son
-- baratos, se reponen solos y no se anotan. Dejar que un número mal
-- contado de bandejas apague el canal de delivery entero es el peor
-- resultado posible.
--
-- QUÉ CAMBIA: al calcular cuánto se puede vender, se ignoran los
-- insumos cuyo `tipo` esté en la lista (por defecto 'Envases'). Se
-- siguen descontando al vender, como siempre — esto NO toca el motor
-- de descuento, solo el cálculo de disponibilidad.
--
-- Correr en Supabase -> SQL Editor. Idempotente. No modifica datos.
-- ================================================================

-- El script se basta solo: si la columna no estuviera, se crea vacía y
-- el cálculo se comporta como antes en vez de reventar.
alter table public.productos add column if not exists tipo text;

drop function if exists public.fudo_stock_calculado(text, bigint);
drop function if exists public.fudo_stock_calculado(text, bigint, text[]);

create or replace function public.fudo_stock_calculado(
  p_sede           text,
  p_producto_id    bigint  default null,
  p_tipos_libres   text[]  default array['Envases']   -- no limitan la venta
)
returns table(
  fudo_product_id   text,
  producto_fudo     text,
  stock_en_fudo     numeric,
  stock_calculado   numeric,
  insumo_que_limita text,
  insumos           text,
  ignorados         text,     -- envases que NO se tuvieron en cuenta
  deja_en_cero      boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with todos as (
    select r.fudo_product_id,
           p.producto,
           coalesce(p.stock_actual,0) as stock,
           floor(coalesce(p.stock_actual,0) / nullif(ri.cantidad,0)) as alcanza,
           -- un envase acompaña la venta, no la habilita
           (coalesce(nullif(trim(p.tipo),''),'—') = any(p_tipos_libres)) as es_envase
    from public.recetas r
    join public.receta_items ri on ri.receta_id = r.id
    join public.productos p     on p.id = ri.producto_id
    where r.sede = p_sede
      and r.activo
      and coalesce(ri.cantidad,0) > 0
      and (p_producto_id is null
           or exists (select 1 from public.receta_items ri2
                       where ri2.receta_id = r.id
                         and ri2.producto_id = p_producto_id
                         and coalesce(ri2.cantidad,0) > 0))
  ),
  calc as (
    select t.fudo_product_id,
           -- si TODA la receta son envases, no hay nada que limite y no
           -- se toca ese producto (queda null y se descarta más abajo)
           min(t.alcanza) filter (where not t.es_envase)                        as calculado,
           (array_agg(t.producto order by t.alcanza)
              filter (where not t.es_envase))[1]                                as limita,
           string_agg(t.producto||' ('||t.stock||')', ' · ' order by t.alcanza)
              filter (where not t.es_envase)                                    as detalle,
           string_agg(t.producto||' ('||t.stock||')', ' · ' order by t.producto)
              filter (where t.es_envase)                                        as envases
    from todos t
    group by t.fudo_product_id
  )
  select c.fudo_product_id,
         fp.nombre,
         (fp.raw->>'stock')::numeric,
         c.calculado,
         c.limita,
         c.detalle,
         c.envases,
         (c.calculado = 0 and coalesce((fp.raw->>'stock')::numeric,0) > 0)
  from calc c
  join public.fudo_productos fp
    on fp.sede = p_sede and fp.fudo_product_id = c.fudo_product_id
  where fp.activo
    and coalesce((fp.raw->>'stockControl')::boolean, false)
    and c.calculado is not null      -- recetas que solo tienen envases
  order by fp.nombre;
$$;

grant execute on function public.fudo_stock_calculado(text, bigint, text[]) to anon, authenticated;


-- ================================================================
-- COMPROBACIÓN 0 — TIENE QUE SALIR UNA SOLA FILA
--
-- Si salen dos, quedaron dos versiones conviviendo y la llamada desde
-- la Edge Function se vuelve ambigua: PostgREST no puede elegir y
-- rechaza la petición antes de ejecutar nada. Es exactamente lo que
-- dejó el inventario 15 horas sin descontar el 2026-07-27.
-- ================================================================
select p.oid::regprocedure as funcion_instalada
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='fudo_stock_calculado';


-- ================================================================
-- COMPROBACIÓN 1 — el antes y el después de los dos casos del informe
-- ================================================================
select producto_fudo, stock_en_fudo, stock_calculado as ahora_daria,
       insumo_que_limita, ignorados as envases_ignorados
from public.fudo_stock_calculado('plaza')
where producto_fudo in ('Torta amor Pedidos Ya', 'Sandwich plateada luco Pedidos Ya');


-- ================================================================
-- COMPROBACIÓN 2 — cuántos quedan en cero ahora
-- ================================================================
select count(*)                                as se_actualizarian,
       count(*) filter (where deja_en_cero)    as quedarian_en_cero
from public.fudo_stock_calculado('plaza');

select producto_fudo, stock_en_fudo, insumo_que_limita, insumos
from public.fudo_stock_calculado('plaza')
where deja_en_cero
order by stock_en_fudo desc;


-- ================================================================
-- COMPROBACIÓN 3 — qué tipos hay, por si 'Envases' no es el nombre
-- exacto que usaste. Si tus envases están bajo otro nombre, se cambia
-- el valor por defecto de p_tipos_libres arriba.
-- ================================================================
select coalesce(nullif(trim(tipo),''),'— sin tipo —') as tipo, count(*) as productos
from public.productos
where sede='plaza' and activo='SÍ'
group by 1 order by productos desc;
