-- ================================================================
-- RESPALDO PARA GUARDAR EN EL REPO
--
-- TODO DE SOLO LECTURA. No modifica nada.
--
-- Para qué: en el plan gratuito de Supabase NO hay punto de
-- restauración. Y el modo de trabajo del proyecto es copiar `update`
-- generados y pegarlos a mano — un `where` que se quedó fuera al copiar
-- cambia 200 filas de una vez y no hay marcha atrás.
--
-- Esto no reemplaza al respaldo diario del plan Pro. Es el piso: si un
-- día se pierde todo, en vez de partir de cero se parte de acá.
--
-- ⚠️ Se respalda lo que NO se puede volver a generar:
--      productos      — el catálogo y el stock del momento
--      recetas        — el enlace con Fudo
--      receta_items   — qué descuenta cada venta (lo más caro de rehacer)
--      producto_lotes — las fechas de vencimiento
--    NO se respaldan los movimientos ni el historial: son registro, se
--    pueden perder sin que el sistema deje de funcionar.
--
-- ================================================================
-- CÓMO SE USA (5 minutos, una vez al mes y antes de cada tanda de
-- renombres):
--
--   1. Correr el BLOQUE 1. Da una fila por tabla con el conteo. Sirve
--      para comprobar después que el respaldo salió completo.
--   2. Correr los bloques 2 a 5, UNO POR UNO.
--   3. En cada uno, botón "Download CSV" del editor de Supabase.
--   4. Guardar los 4 archivos en la carpeta `respaldos/` del repo, con
--      la fecha en el nombre:  productos-2026-07-30.csv
--   5. Commit. Listo.
--
-- Si prefieres un solo archivo de texto en vez de 4 CSV, el BLOQUE 6
-- devuelve los INSERT ya escritos para volver a cargar todo.
-- ================================================================


-- ================================================================
-- 1) ANTES — cuántas filas debería traer cada archivo
--
-- Anotar estos números. Si un CSV trae menos, se cortó (el tope de las
-- 1000 filas también aplica acá si se descarga desde la app; desde el
-- editor de SQL no, pero conviene comprobar igual).
-- ================================================================
select 'productos'      as tabla, count(*) as filas from public.productos
union all select 'recetas',       count(*) from public.recetas
union all select 'receta_items',  count(*) from public.receta_items
union all select 'producto_lotes',count(*) from public.producto_lotes
order by 1;


-- ================================================================
-- 2) PRODUCTOS  →  respaldos/productos-AAAA-MM-DD.csv
-- ================================================================
select * from public.productos order by sede, rubro, producto;


-- ================================================================
-- 3) RECETAS  →  respaldos/recetas-AAAA-MM-DD.csv
--
-- Va con el nombre del producto de Fudo al lado. En el CSV crudo la
-- receta es solo un identificador, y si un día hay que leer esto a ojo
-- para reconstruir, el nombre es lo único que orienta.
-- ================================================================
select r.*, fp.nombre as nombre_en_fudo
from public.recetas r
left join public.fudo_productos fp
       on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
order by r.sede, fp.nombre nulls last, r.id;


-- ================================================================
-- 4) RECETA_ITEMS  →  respaldos/receta-items-AAAA-MM-DD.csv
--
-- Lo más caro de rehacer a mano. Va con los dos nombres al lado por la
-- misma razón que arriba: sin ellos, es una lista de números.
-- ================================================================
select ri.*,
       fp.nombre  as receta_de_fudo,
       p.producto as insumo_del_inventario,
       p.rubro    as seccion_del_insumo
from public.receta_items ri
join public.recetas r      on r.id = ri.receta_id
left join public.fudo_productos fp
       on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
left join public.productos p on p.id = ri.producto_id
order by r.sede, fp.nombre nulls last, p.producto;


-- ================================================================
-- 5) PRODUCTO_LOTES  →  respaldos/producto-lotes-AAAA-MM-DD.csv
--
-- Las fechas de vencimiento. Con el nombre del producto al lado.
-- ================================================================
select l.*, p.producto, p.rubro, p.sede
from public.producto_lotes l
join public.productos p on p.id = l.producto_id
order by p.sede, p.producto, l.vencimiento;


-- ================================================================
-- 6) OPCIONAL — todo en un solo texto, listo para volver a cargar
--
-- Devuelve UNA fila con los INSERT completos. Se copia el contenido de
-- esa celda y se guarda como respaldos/restaurar-AAAA-MM-DD.sql
--
-- ⚠️ Para RESTAURAR con esto hay que entender dos cosas:
--    · Los identificadores van incluidos, porque las recetas se unen
--      por ID. Restaurar sin los ids deja las recetas apuntando al
--      vacío — que es exactamente lo que hay que evitar.
--    · Por eso al final reajusta el contador de cada tabla. Sin eso, el
--      siguiente producto que se cree choca con un id ya usado.
--
-- Cada fila se guarda como JSON y se restaura con json_populate_record.
-- Eso NO es una complicación gratuita: hace que las columnas se tomen
-- por NOMBRE desde la tabla real, en vez de depender del orden que yo
-- suponga que tienen. Si mañana se agrega una columna, este respaldo
-- la incluye solo y el archivo viejo se sigue pudiendo restaurar.
--
-- Si la celda sale cortada en pantalla, usar los CSV de arriba: son
-- menos cómodos de restaurar pero no tienen ese límite.
-- ================================================================
select
  '-- Respaldo del ' || to_char(now(),'YYYY-MM-DD HH24:MI') || E'\n'
  || '-- Restaurar en una base VACÍA, en este orden.' || E'\n\n'
  || 'begin;' || E'\n\n'
  || (select coalesce(string_agg(format(
       'insert into public.productos select * from json_populate_record(null::public.productos, %L);',
       row_to_json(t)), E'\n' order by t.id), '') from public.productos t)
  || E'\n\n'
  || (select coalesce(string_agg(format(
       'insert into public.recetas select * from json_populate_record(null::public.recetas, %L);',
       row_to_json(t)), E'\n' order by t.id), '') from public.recetas t)
  || E'\n\n'
  || (select coalesce(string_agg(format(
       'insert into public.receta_items select * from json_populate_record(null::public.receta_items, %L);',
       row_to_json(t)), E'\n' order by t.id), '') from public.receta_items t)
  || E'\n\n'
  || (select coalesce(string_agg(format(
       'insert into public.producto_lotes select * from json_populate_record(null::public.producto_lotes, %L);',
       row_to_json(t)), E'\n' order by t.id), '') from public.producto_lotes t)
  || E'\n\n'
  || '-- Los contadores, para que el próximo id no choque con uno ya usado:' || E'\n'
  || 'select setval(pg_get_serial_sequence(''public.productos'',''id''), coalesce((select max(id) from public.productos),1));' || E'\n'
  || 'select setval(pg_get_serial_sequence(''public.recetas'',''id''), coalesce((select max(id) from public.recetas),1));' || E'\n'
  || 'select setval(pg_get_serial_sequence(''public.receta_items'',''id''), coalesce((select max(id) from public.receta_items),1));' || E'\n'
  || 'select setval(pg_get_serial_sequence(''public.producto_lotes'',''id''), coalesce((select max(id) from public.producto_lotes),1));' || E'\n\n'
  || 'commit;' || E'\n'
  as guardar_esto_como_un_archivo_sql;


-- ================================================================
-- 7) AL TERMINAR — comprobar que el respaldo sirve
--
-- Un respaldo que nadie abrió no es un respaldo. Abrir los CSV y mirar:
--   · ¿receta-items trae los dos nombres llenos, o hay columnas vacías?
--     Una columna vacía ahí es una receta apuntando a un producto que
--     ya no existe — se arregla ahora, no el día del incendio.
--   · ¿Los conteos calzan con el bloque 1?
-- ================================================================
select 'Comprobar los conteos del bloque 1 contra las filas de cada CSV' as ultimo_paso;
