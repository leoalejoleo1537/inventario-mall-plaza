-- ================================================================
-- Le pone el "apellido" de sección a los productos de bollería:
--   Vitrina    -> "Donas frambuesa vitrina"
--   Congelador -> "Donas frambuesa congelador"
--
-- Solo toca la bollería (la misma lista que se duplicó en Congelador).
-- NO toca pizzas, pulpas, bebidas ni nada fuera de esa lista.
-- Solo toca filas cuya sección sea Congelador o Vitrina*.
--
-- Es IDEMPOTENTE: si el nombre ya termina en su apellido, lo deja igual.
-- La app suma el total ignorando el apellido, así "Brownie vitrina" (9)
-- y "Brownie congelador" (5) siguen mostrando Total 14.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- El paso 1 es una VISTA PREVIA: revísala antes de aplicar el paso 2.
-- ================================================================

-- Lista de bollería + normalizador, reutilizables en los dos pasos.
create or replace view public.v_bolleria_apellido as
with norm as (
  select
    id, sede, producto, rubro,
    translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') as n
  from public.productos
  where activo = 'SÍ'
),
conf as (
  select
    id, sede, producto, rubro, n,
    case
      when rubro = 'Congelador'  then 'congelador'
      when rubro ilike 'Vitrina%' then 'vitrina'
    end as apellido
  from norm
  where n in (
    'volcan de chocolate','donas frambuesa','donas nutella','donas oreo',
    'muffin relleno arandano','muffin vainilla chips','muffin amapola',
    'muffin de zanahoria','mini muffin','macarrons','brownie','waffles',
    'galleton red velvet','galleton pasas','galleton chips')
)
select
  id, sede, rubro,
  producto                                as nombre_actual,
  regexp_replace(trim(producto),'\s+',' ','g') || ' ' || apellido as nombre_nuevo
from conf
where apellido is not null
  and n !~ ('\s' || apellido || '$');   -- ya lo tiene: no tocar

-- ---------------------------------------------------------------
-- PASO 1 — VISTA PREVIA: qué se va a renombrar (no cambia nada)
-- ---------------------------------------------------------------
select sede, rubro, nombre_actual, nombre_nuevo
from public.v_bolleria_apellido
order by sede, rubro, nombre_actual;

-- ---------------------------------------------------------------
-- PASO 2 — APLICAR (descomenta y corre cuando la vista previa esté ok)
-- ---------------------------------------------------------------
-- update public.productos p
--    set producto   = v.nombre_nuevo,
--        updated_at = now()
--   from public.v_bolleria_apellido v
--  where p.id = v.id;

-- ---------------------------------------------------------------
-- PASO 3 — COMPROBACIÓN: cómo quedó la bollería
-- ---------------------------------------------------------------
-- select sede, rubro, producto, stock_actual
--   from public.productos
--  where activo='SÍ'
--    and (producto ilike '% vitrina' or producto ilike '% congelador')
--  order by sede, producto;

-- Limpieza opcional de la vista auxiliar:
-- drop view if exists public.v_bolleria_apellido;
