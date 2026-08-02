-- ================================================================
-- DIAGNÓSTICO v3 — 2026-07-25 · SOLO LECTURA
--
-- El inventario fue reestructurado (productos desdoblados en
-- "X Congelador" / "X Vitrina", nombres viejos en activo=NO).
-- Hay que ver qué tan mal quedaron las recetas existentes.
--
-- ⚠️ CÓMO CORRERLO: el editor de Supabase solo muestra el
--    resultado del ÚLTIMO select. Así que hay que correr una
--    consulta a la vez:
--      1. Selecciona con el mouse SOLO el bloque que quieres
--      2. Aprieta Correr (o Ctrl+Enter)
--    Empieza por la consulta A, que es la urgente.
-- ================================================================


-- ================================================================
-- CONSULTA A  ← LA URGENTE
-- ¿Hay recetas apuntando a productos DESACTIVADOS?
-- Si devuelve filas, esas ventas descuentan stock de productos
-- que ya nadie cuenta. Debería salir vacía.
-- ================================================================
select r.fudo_product_nombre as producto_fudo,
       p.producto            as descuenta_de,
       p.rubro,
       p.activo,
       p.stock_actual
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
join public.productos    p  on p.id = ri.producto_id
where r.sede='plaza'
  and coalesce(p.activo,'') <> 'SÍ'
order by p.producto, r.fudo_product_nombre;


-- ================================================================
-- CONSULTA B
-- Resumen: cuántas recetas están sanas y cuántas rotas
-- ================================================================
select
  count(distinct r.id)                                              as recetas_total,
  count(distinct r.id) filter (where coalesce(p.activo,'') <> 'SÍ') as con_algun_insumo_inactivo,
  count(distinct r.id) filter (where p.id is null)                  as sin_insumos
from public.recetas r
left join public.receta_items ri on ri.receta_id = r.id
left join public.productos    p  on p.id = ri.producto_id
where r.sede='plaza';


-- ================================================================
-- CONSULTA C
-- Los 10 productos que creé hoy: ¿alguno quedó duplicado?
-- La columna "posibles_duplicados" muestra otros productos activos
-- que comparten la primera palabra.
-- ================================================================
select n.producto, n.rubro, n.activo, n.stock_actual,
       coalesce((
         select string_agg(o.producto || ' [' || coalesce(o.rubro,'?') || ']', '  ·  ' order by o.producto)
         from public.productos o
         where o.sede='plaza' and o.activo='SÍ' and o.id <> n.id
           and translate(lower(o.producto),'áéíóúñü','aeiounu')
               like '%' || translate(lower(split_part(trim(n.producto),' ',1)),'áéíóúñü','aeiounu') || '%'
       ), '(sin duplicados)') as posibles_duplicados
from public.productos n
where n.sede='plaza' and n.origen='FUDO-2026-07-25'
order by n.rubro, n.producto;


-- ================================================================
-- CONSULTA D
-- La lista completa de productos ACTIVOS del inventario.
-- Son ~175 filas: sube el "Límite de 100 filas" a 500, o usa
-- el botón Exportar → CSV y me lo pasas.
-- Con esto rearmo el mapa contra la realidad, de una vez.
-- ================================================================
select rubro, producto, stock_actual
from public.productos
where sede='plaza' and activo='SÍ'
order by rubro, producto;
