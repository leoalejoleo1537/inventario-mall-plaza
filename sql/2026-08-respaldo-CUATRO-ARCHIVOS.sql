-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. UNO POR UNO, y después de cada uno se descarga
--             el CSV. NO se pega el archivo entero de una vez.
--  TARDA:     unos segundos cada uno
--  QUÉ HACE:  saca las cuatro copias del inventario. No cambia nada.
--  QUÉ VER:   una tabla con filas después de cada bloque, y el botón
--             "Download CSV" arriba a la derecha del resultado.
-- ================================================================
--
-- POR QUÉ ESTE ARCHIVO EXISTE, y es un error mío del que sale una lección:
--
-- El archivo anterior (`2026-07-respaldo-para-guardar.sql`) tenía los cuatro
-- respaldos y, al final, una línea que decía "ahora comprueba los conteos".
-- Al pegarlo entero y apretar Run, el editor de Supabase **corre todo pero
-- muestra solo el resultado de la ÚLTIMA consulta**. O sea que las cuatro
-- copias se generaron y se perdieron, y en pantalla apareció esa frase suelta.
--
-- Parecía que el respaldo no había funcionado. Funcionó: no había dónde verlo.
--
-- Este archivo no tiene ninguna línea al final, y cada bloque está solo.
-- ================================================================


-- ================================================================
-- BLOQUE 1 de 4 — PRODUCTOS   ← el más importante de todos
--
-- Es el inventario entero de las tres sedes: stock, mínimos, máximos,
-- secciones y tipos.
--
-- QUÉ HACER: Run, y cuando aparezca la tabla, botón **Download CSV**
-- arriba a la derecha del resultado. Guardarlo como `productos.csv`.
-- ================================================================
select * from public.productos order by sede, rubro, producto;


-- ================================================================
-- BLOQUE 2 de 4 — RECETAS   (borrar lo de arriba y correr solo esto)
--
-- Qué producto de Fudo descuenta qué. Es el trabajo de meses.
--
-- QUÉ HACER: Run → Download CSV → `recetas.csv`
-- ================================================================
select r.*, fp.nombre as nombre_en_fudo
from public.recetas r
left join public.fudo_productos fp
       on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
order by r.sede, r.fudo_product_nombre;


-- ================================================================
-- BLOQUE 3 de 4 — LOS INGREDIENTES DE CADA RECETA
--
-- Sin esto, las recetas del bloque 2 quedan vacías: son la cabecera.
--
-- QUÉ HACER: Run → Download CSV → `receta_items.csv`
-- ================================================================
select ri.*, p.producto as insumo, p.sede as sede_del_insumo
from public.receta_items ri
left join public.productos p on p.id = ri.producto_id
order by ri.receta_id, ri.id;


-- ================================================================
-- BLOQUE 4 de 4 — LAS FECHAS DE VENCIMIENTO
--
-- Los sándwiches y todo lo perecedero. Su cantidad ES la suma de estas
-- filas, así que sin esto no se puede reconstruir su stock.
--
-- QUÉ HACER: Run → Download CSV → `producto_lotes.csv`
-- ================================================================
select l.*, p.producto, p.rubro, p.sede
from public.producto_lotes l
join public.productos p on p.id = l.producto_id
order by p.sede, p.producto, l.vencimiento;


-- ================================================================
-- BLOQUE 5 — COMPROBAR QUE LAS COPIAS ESTÁN COMPLETAS
--
-- Correr esto AL FINAL, y comparar cada número con la cantidad de filas
-- que tiene el CSV que descargaste (sin contar la primera línea, que son
-- los títulos de las columnas).
--
-- Si alguno no cuadra, ese CSV se bajó a medias y hay que repetirlo.
-- ================================================================
select 'productos'      as archivo, count(*) as filas_que_debe_tener from public.productos
union all select 'recetas',        count(*) from public.recetas
union all select 'receta_items',   count(*) from public.receta_items
union all select 'producto_lotes', count(*) from public.producto_lotes;
