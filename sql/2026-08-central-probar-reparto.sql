-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques, pero NO seguidos: uno antes de la prueba, otro
--             después de confirmar, y otro después de deshacer.
--  TARDA:     instantáneo
--  QUÉ HACE:  solo MIRA. Es la foto del antes y del después.
--  QUÉ VER:   que bodega baje lo mismo que el local sube.
-- ================================================================
--
-- CÓMO SE USA, en orden:
--   1. Correr el BLOQUE 1  -> anotar los números
--   2. En la app: Bodega -> Reparto -> Mall Plaza -> buscar zanahoria ->
--      agregar 2 -> Enviar
--   3. En la app: Mall Plaza -> Reparto -> confirmar esa línea
--   4. Correr el BLOQUE 2  -> bodega bajó 2, Plaza subió 2, el libro lo anota
--   5. En la app: Mall Plaza -> Reparto -> Deshacer esa línea
--   6. Correr el BLOQUE 3  -> todo volvió a como estaba
--
-- ⚠️ AVISO IMPORTANTE ANTES DE EMPEZAR: al confirmar la línea, la app también
-- le sube el stock a FUDO. Eso es real y el "Deshacer" del reparto NO lo
-- revierte — solo retira el aviso pendiente. Si el producto tiene receta en
-- Fudo, hay que corregirlo allá aparte. Por eso conviene probar con 2 unidades
-- y no con 20.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA FOTO DEL ANTES  (correr ANTES de tocar la app)
--
-- QUÉ VER: los ids y el stock de las tres sedes, y la columna `enlace` que
-- dice si bodega sabe de cuál descontar. Si en la fila de bodega el enlace
-- dice "sin enlace a plaza", la prueba no va a descontar nada — avísame.
-- ================================================================
select p.sede, p.id, p.producto, p.stock_actual,
       case
         when p.sede='central' then coalesce((
           select 'enlazado a plaza #' || e.producto_sede_id
             from public.producto_enlace e
            where e.producto_bodega_id = p.id and e.sede='plaza'), '⚠ sin enlace a plaza')
         else coalesce((
           select 'viene de bodega #' || e.producto_bodega_id
             from public.producto_enlace e
            where e.sede = p.sede and e.producto_sede_id = p.id), 'sin origen')
       end as enlace,
       (select count(*) from public.producto_lotes l where l.producto_id = p.id) as fechas
from public.productos p
where p.activo='SÍ' and p.sede in ('central','plaza','angamos')
  and public.clave_nombre(p.producto) like '%zanahoria%'
order by p.sede, p.producto;


-- ================================================================
-- BLOQUE 2 — DESPUÉS DE CONFIRMAR EN MALL PLAZA
--
-- QUÉ VER, y es lo único que importa de toda la prueba:
--   · bodega bajó exactamente lo que Plaza subió
--   · el libro tiene UNA línea de salida, en negativo, con la sede de destino
--   · la línea del reparto guarda de cuál producto de bodega salió
-- ================================================================
select p.sede, p.id, p.producto, p.stock_actual
from public.productos p
where p.activo='SÍ' and p.sede in ('central','plaza')
  and public.clave_nombre(p.producto) like '%zanahoria%'
order by p.sede, p.producto;

-- el libro de movimientos de bodega, lo último primero
select m.created_at, m.producto, m.tipo, m.cantidad, m.sede_contraparte,
       m.motivo, m.quien, m.reparto_item_id
from public.movimientos m
where m.sede='central'
order by m.id desc
limit 10;

-- la línea del reparto: los dos números, el del local y el de bodega
select ri.id, ri.producto, ri.cantidad_pedida, ri.cantidad_recibida, ri.estado,
       ri.producto_id as id_en_el_local, ri.producto_bodega_id as id_en_bodega,
       r.sede as va_a, r.nombre, r.creado_por
from public.reparto_items ri
join public.repartos r on r.id = ri.reparto_id
where ri.producto_bodega_id is not null
order by ri.id desc
limit 5;


-- ================================================================
-- BLOQUE 3 — DESPUÉS DE DESHACER
--
-- QUÉ VER: los stocks vuelven a los del bloque 1, y en el libro aparece una
-- línea de ENTRADA que devuelve lo que había salido. La línea de salida NO se
-- borra: un libro donde se puede borrar una página no sirve de libro.
-- ================================================================
select p.sede, p.id, p.producto, p.stock_actual
from public.productos p
where p.activo='SÍ' and p.sede in ('central','plaza')
  and public.clave_nombre(p.producto) like '%zanahoria%'
order by p.sede, p.producto;

select m.created_at, m.producto, m.tipo, m.cantidad, m.motivo, m.reparto_item_id
from public.movimientos m
where m.sede='central'
order by m.id desc
limit 10;
