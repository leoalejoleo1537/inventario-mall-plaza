-- ================================================================
-- LIMPIEZA + FIX DE RECETAS ROTAS — 2026-07-25
--
-- Tres cosas, en este orden:
--   PASO 0: confirmar en qué modo está la sede (prueba / real)
--   PASO 1: borrar los 5 productos duplicados que creó por error el
--           script 2026-07-productos-nuevos-inventario.sql
--   PASO 2: reapuntar las 5 recetas que descuentan de productos
--           desactivados o equivocados
--
-- ⚠️ CÓMO CORRERLO: selecciona con el mouse UN PASO a la vez y
--    aprieta Correr. El editor solo muestra el último select.
-- ================================================================


-- ================================================================
-- PASO 0 — ¿En qué modo está plaza?  ← CORRER PRIMERO, SOLO ESTO
-- 'prueba' = registra pero no toca stock
-- 'real'   = descuenta de verdad
-- ================================================================
select sede, modo, ultima_venta_at, updated_at
from public.fudo_sync
where sede='plaza';


-- ================================================================
-- PASO 1 — Borrar los duplicados que creé hoy
--
-- Se borran SOLO los que tienen origen='FUDO-2026-07-25' (los de
-- hoy) y que duplican un producto preexistente. Al borrarlos,
-- `on delete cascade` se lleva sus receta_items; después se borran
-- las recetas que hayan quedado sin insumos.
--
-- Los 4 productos legítimos NO se tocan:
--   Donas chocolate · Galletas New York · Cinnamon roll vegano
--   Cocacola mini zero
-- ================================================================

-- 1a) ver qué se va a borrar (correr esto solo, para revisar)
select id, producto, rubro, stock_actual, origen
from public.productos
where sede='plaza' and origen='FUDO-2026-07-25'
  and producto in ('Agua Bosqua con gas','Agua Bosqua sin gas',
                   'Dona pistacho Dubai','Galleton vainilla chips',
                   'Muffin de chocolate')
order by producto;

-- 1b) borrarlos
delete from public.productos
where sede='plaza' and origen='FUDO-2026-07-25'
  and producto in ('Agua Bosqua con gas','Agua Bosqua sin gas',
                   'Dona pistacho Dubai','Galleton vainilla chips',
                   'Muffin de chocolate');

-- 1c) limpiar recetas que quedaron sin ningún insumo
delete from public.recetas r
where r.sede='plaza'
  and not exists (select 1 from public.receta_items ri where ri.receta_id = r.id);

-- 1d) mover 'Cocacola mini zero' al rubro correcto
--     (las bebidas activas viven en 'Bebidas', no en 'Vitrina de bebidas')
update public.productos
set rubro='Bebidas', updated_at=now()
where sede='plaza' and producto='Cocacola mini zero';


-- ================================================================
-- PASO 2 — Reapuntar las 5 recetas rotas
--
-- Tres son nombres viejos que quedaron desactivados tras la
-- reestructuración del inventario. Las otras dos son errores de
-- mapeo de la segunda pasada:
--   * 'Selladitos del desierto' descontaba BROWNIE
--   * 'Cheesecake maracuyá'     descontaba CHEESECAKE DE MORA
-- ================================================================
drop table if exists _fix;
create temporary table _fix(fudo_nombre text, inv_viejo text, inv_nuevo text);
insert into _fix values
('Selladitos del desierto',  'Brownie',            'Sandwich Selladito'),
('Cinnamon Roll Pedidos Ya', 'Cinnamon rolls',     'Cinnamon rolls vitrina'),
('Rollo Canela Pedidosb Ya', 'Cinnamon rolls',     'Cinnamon rolls vitrina'),
('Mini muffin',              'Mini muffin Vitrina','mini muffins vitrina'),
('Cheesecake maracuyá',      'T. Cheesecake Mora', 'T. Cheesecake Maracuya');

-- 2a) verificar que los destinos existen y están activos
--     (si alguno sale como 'NO EXISTE', corregir el nombre arriba)
select f.fudo_nombre, f.inv_nuevo,
       case when exists (
         select 1 from public.productos p
         where p.sede='plaza' and p.activo='SÍ'
           and translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
             = translate(lower(regexp_replace(trim(f.inv_nuevo),'\s+',' ','g')),'áéíóúñü','aeiounu'))
       then 'ok' else 'NO EXISTE' end as destino
from _fix f
order by 1;

-- 2b) aplicar el cambio
update public.receta_items ri
set producto_id = nuevo.id
from public.recetas r,
     _fix f,
     public.productos viejo,
     public.productos nuevo
where ri.receta_id = r.id
  and r.sede='plaza'
  and translate(lower(regexp_replace(trim(r.fudo_product_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
    = translate(lower(regexp_replace(trim(f.fudo_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu')
  and viejo.id = ri.producto_id
  and translate(lower(regexp_replace(trim(viejo.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
    = translate(lower(regexp_replace(trim(f.inv_viejo),'\s+',' ','g')),'áéíóúñü','aeiounu')
  and nuevo.sede='plaza' and nuevo.activo='SÍ'
  and translate(lower(regexp_replace(trim(nuevo.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
    = translate(lower(regexp_replace(trim(f.inv_nuevo),'\s+',' ','g')),'áéíóúñü','aeiounu')
  -- no chocar con el unique (receta_id, producto_id)
  and not exists (select 1 from public.receta_items x
                  where x.receta_id = ri.receta_id and x.producto_id = nuevo.id);


-- ================================================================
-- COMPROBACIÓN FINAL — debe salir VACÍA
-- (ninguna receta apuntando a productos inactivos)
-- ================================================================
select r.fudo_product_nombre as producto_fudo,
       p.producto            as descuenta_de,
       p.rubro, p.activo
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
join public.productos    p  on p.id = ri.producto_id
where r.sede='plaza' and coalesce(p.activo,'') <> 'SÍ'
order by 1;
