-- ================================================================
-- BORRAR LOS 5 PRODUCTOS DUPLICADOS — 2026-07-25
--
-- Los creó por error el script 2026-07-productos-nuevos-inventario.sql
-- Se identifican por origen='FUDO-2026-07-25' + nombre exacto, así
-- que no hay riesgo de tocar nada más del inventario.
--
-- Los 4 productos legítimos de ese mismo script NO se tocan:
--   Donas chocolate · Galletas New York · Cinnamon roll vegano
--   Cocacola mini zero
--
-- ⚠️ Correr UN PASO a la vez: selecciona el bloque con el mouse
--    y aprieta Correr.
-- ================================================================


-- ================================================================
-- PASO 1 — Ver qué se va a borrar (solo lectura)
-- Deberían salir exactamente 5 filas, todas con stock 0.
-- Si alguna tiene stock distinto de 0, avísame antes de seguir:
-- significa que alguien ya contó o vendió sobre ese producto.
-- ================================================================
select id, producto, rubro, stock_actual, origen, created_at
from public.productos
where sede='plaza'
  and origen='FUDO-2026-07-25'
  and producto in ('Agua Bosqua con gas',
                   'Agua Bosqua sin gas',
                   'Dona pistacho Dubai',
                   'Galleton vainilla chips',
                   'Muffin de chocolate')
order by producto;


-- ================================================================
-- PASO 2 — Ver qué recetas quedarían vacías al borrarlos
-- (solo lectura). Son recetas que mi script creó apuntando a estos
-- productos. Si el producto de Fudo ya tenía receta buena de antes,
-- no aparecerá aquí.
-- ================================================================
select r.id as receta_id, r.fudo_product_nombre, p.producto as unico_insumo
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
join public.productos    p  on p.id = ri.producto_id
where r.sede='plaza'
  and p.origen='FUDO-2026-07-25'
  and p.producto in ('Agua Bosqua con gas',
                     'Agua Bosqua sin gas',
                     'Dona pistacho Dubai',
                     'Galleton vainilla chips',
                     'Muffin de chocolate')
order by r.fudo_product_nombre;


-- ================================================================
-- PASO 3 — Borrar los 5 productos
-- El `on delete cascade` de receta_items se lleva sus insumos.
-- ================================================================
delete from public.productos
where sede='plaza'
  and origen='FUDO-2026-07-25'
  and producto in ('Agua Bosqua con gas',
                   'Agua Bosqua sin gas',
                   'Dona pistacho Dubai',
                   'Galleton vainilla chips',
                   'Muffin de chocolate');


-- ================================================================
-- PASO 4 — Borrar SOLO las recetas que quedaron vacías por esto
-- Se limita a los 9 productos de Fudo que tocó mi script, para no
-- barrer recetas vacías que existan por otro motivo.
-- ================================================================
delete from public.recetas r
where r.sede='plaza'
  and r.fudo_product_nombre in ('Agua Bosqua con gas',
                                'Agua Bosqua sin gas',
                                'Dona Pistacho Dubai',
                                'Galleton vainilla chips',
                                'Muffin de chocolate')
  and not exists (select 1 from public.receta_items ri where ri.receta_id = r.id);


-- ================================================================
-- PASO 5 — Comprobación
-- La primera consulta debe devolver solo los 4 productos legítimos.
-- ================================================================
select producto, rubro, stock_actual
from public.productos
where sede='plaza' and origen='FUDO-2026-07-25'
order by producto;
