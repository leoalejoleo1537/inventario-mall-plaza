-- ================================================================
-- EMPAREJADOR DE PRODUCTOS SIMPLES (sede plaza) — julio 2026
--
-- Crea recetas 1-a-1 (cantidad 1, "siempre") SOLO para productos de Fudo
-- que no son compuestos: el producto que se vende ES el mismo insumo que
-- se descuenta (bebidas embotelladas, tortas por porción, etc.) — no
-- combos ni platos con varios ingredientes.
--
-- Sigue la regla 0.1 del archivo madre: analizar ≠ escribir.
--   PASO 1 (abajo) es la VISTA PREVIA — no toca nada, solo muestra.
--   PASO 2 es el que escribe, y solo toca los casos SIN AMBIGÜEDAD
--   (el nombre coincide con exactamente un producto del inventario).
--
-- Lo que este script NUNCA hace:
--   - No toca productos de Fudo que ya tienen una receta CON insumos
--     (una receta armada a mano, aunque sea un combo simple, no se toca).
--   - No crea nada si el nombre coincide con 0 o con 2+ productos del
--     inventario — esos casos quedan listados para decidir a mano.
--   - No adivina nombres "parecidos": la coincidencia es exacta después
--     de normalizar (sin tildes/mayúsculas/espacios de más), igual que
--     usa la app. "Brownie" y "brownie " son iguales; "Brownie" y
--     "Brownie relleno" NO.
--
-- Es idempotente: correrlo dos veces no crea nada duplicado.
-- Reversible: los insumos creados quedan con cantidad=1 y aplica='siempre';
-- para deshacer, borrar esa receta desde la app (Recetas → abrir → Eliminar).
--
-- Cómo correrlo: Supabase -> SQL Editor -> primero el PASO 1, revisar,
-- después el PASO 2.
-- ================================================================

-- Normalizador (mismo criterio que la app y el resto de emparejadores).
create or replace function public.norm_nombre(t text)
returns text language sql immutable as $$
  select translate(lower(regexp_replace(trim(coalesce(t,'')),'\s+',' ','g')),
                   'áéíóúñü','aeiounu');
$$;

-- ================================================================
-- PASO 1 — VISTA PREVIA (no toca nada)
-- ================================================================
with candidatos as (
  select
    fp.fudo_product_id, fp.nombre as fudo_nombre,
    count(p.id)                                as coincidencias,
    array_agg(p.producto order by p.producto)  as productos_coincidentes,
    -- nombres que huelen a combo: aunque coincidan, van a "revisar a mano"
    (public.norm_nombre(fp.nombre) ~ '(combo|promo|desayuno|menu|kids|\+| y |duo|dúo)') as parece_combo
  from public.fudo_productos fp
  left join public.productos p
    on p.sede = fp.sede and p.activo = 'SÍ'
   and public.norm_nombre(p.producto) = public.norm_nombre(fp.nombre)
  where fp.sede = 'plaza' and fp.activo
    and not exists (
      select 1 from public.recetas r
      join public.receta_items ri on ri.receta_id = r.id
      where r.sede = fp.sede and r.fudo_product_id = fp.fudo_product_id and r.activo
    )
  group by fp.fudo_product_id, fp.nombre
)
select
  case
    when parece_combo               then '⚠ parece combo — revisar a mano'
    when coincidencias = 1          then '✓ automático (Paso 2 lo crea)'
    when coincidencias = 0          then '✗ sin pareja en el inventario'
    else '⚠ ambiguo — ' || coincidencias || ' coincidencias'
  end as estado,
  fudo_nombre,
  productos_coincidentes
from candidatos
order by
  case when parece_combo then 0 when coincidencias=1 then 1 else 2 end,
  fudo_nombre;

-- ================================================================
-- PASO 2 — APLICAR (solo los "✓ automático" del Paso 1)
-- ================================================================
with candidatos as (
  select
    fp.sede, fp.fudo_product_id, fp.nombre as fudo_nombre,
    (array_agg(p.id))[1] as producto_id,
    count(p.id) as coincidencias
  from public.fudo_productos fp
  join public.productos p
    on p.sede = fp.sede and p.activo = 'SÍ'
   and public.norm_nombre(p.producto) = public.norm_nombre(fp.nombre)
  where fp.sede = 'plaza' and fp.activo
    and public.norm_nombre(fp.nombre) !~ '(combo|promo|desayuno|menu|kids|\+| y |duo|dúo)'
    and not exists (
      select 1 from public.recetas r
      join public.receta_items ri on ri.receta_id = r.id
      where r.sede = fp.sede and r.fudo_product_id = fp.fudo_product_id and r.activo
    )
  group by fp.sede, fp.fudo_product_id, fp.nombre
  having count(p.id) = 1
)
insert into public.recetas(sede, fudo_product_id, fudo_product_nombre)
select sede, fudo_product_id, fudo_nombre from candidatos
on conflict (sede, fudo_product_id) do nothing;

with candidatos as (
  select
    fp.sede, fp.fudo_product_id,
    (array_agg(p.id))[1] as producto_id
  from public.fudo_productos fp
  join public.productos p
    on p.sede = fp.sede and p.activo = 'SÍ'
   and public.norm_nombre(p.producto) = public.norm_nombre(fp.nombre)
  where fp.sede = 'plaza' and fp.activo
    and public.norm_nombre(fp.nombre) !~ '(combo|promo|desayuno|menu|kids|\+| y |duo|dúo)'
    and not exists (
      select 1 from public.recetas r
      join public.receta_items ri on ri.receta_id = r.id
      where r.sede = fp.sede and r.fudo_product_id = fp.fudo_product_id and r.activo
    )
  group by fp.sede, fp.fudo_product_id
  having count(p.id) = 1
)
insert into public.receta_items(receta_id, producto_id, cantidad, aplica)
select r.id, c.producto_id, 1, 'siempre'
from candidatos c
join public.recetas r on r.sede = c.sede and r.fudo_product_id = c.fudo_product_id
where not exists (select 1 from public.receta_items x where x.receta_id = r.id);

-- ================================================================
-- PASO 3 — COMPROBACIÓN: qué quedó recién emparejado
-- ================================================================
select r.fudo_product_nombre, p.producto as insumo, ri.cantidad
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
join public.productos p on p.id = ri.producto_id
where r.sede = 'plaza'
order by r.fudo_product_nombre;
