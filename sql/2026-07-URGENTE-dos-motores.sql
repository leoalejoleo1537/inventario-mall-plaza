-- ================================================================
-- URGENTE (2) — había DOS motores instalados y la sync no podía elegir
--
-- Causa: en la base convivían dos versiones de fudo_procesar_item:
--   fudo_procesar_item(text,text,text,text,text,numeric,text)              <- vieja
--   fudo_procesar_item(text,text,text,text,text,numeric,text,timestamptz)  <- v5
--
-- Llamado desde SQL con los 8 argumentos, el motor v5 funciona (probado).
-- Pero la Edge Function llama por la API, y ahí el nombre queda ambiguo:
-- hay dos candidatas, la llamada se rechaza y no se procesa ninguna venta.
-- De ahí el "9 ventas · 0 descuentos" sin ningún error a la vista.
--
-- Por qué quedaron dos: el archivo del motor v5 hacía
--   drop function if exists ...(...,timestamptz)
-- que solo borra la firma de 8 argumentos. La que estaba en producción era
-- la de 7 (motor v3), así que no se borró y el create añadió una segunda.
--
-- QUÉ HACE: borra la versión vieja. No toca datos. La v5 acepta llamadas
-- de 7 argumentos igual, porque p_venta_at tiene valor por defecto.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Después: apretar ⟳ en la app.
-- ================================================================

-- ---------- 1) EL ARREGLO ----------
drop function if exists public.fudo_procesar_item(text,text,text,text,text,numeric,text);

-- ---------- 2) Comprobación: debe quedar UNA sola fila, la de 8 argumentos ----------
select p.oid::regprocedure as motor_instalado
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='fudo_procesar_item';


-- ================================================================
-- 3) LIMPIEZA de la prueba de diagnóstico
--
-- El editor de Supabase no respetó el begin/rollback: las filas de
-- diagnóstico se guardaron de verdad y el bloque 3 sí descontó stock.
-- Esto borra esas filas de la bitácora (no afecta al stock).
-- ================================================================
delete from public.fudo_movimientos
where sede='plaza' and fudo_sale_id in ('DIAG-VENTA-1','DIAG-VENTA-2');

-- ---------- 4) Qué quedó descontado de más por la prueba ----------
-- El bloque 3 descontó 1 unidad de cada uno de estos tres productos.
-- Míralos y, si el número no calza con lo que hay de verdad, corrígelo
-- desde la ficha del producto en la app. No se ajusta solo acá porque
-- para "Bandeja cartón m" y "Bolsa kraft m" el stock pudo haberse
-- quedado en 0 (nunca baja de ahí), y sumar 1 a ciegas inventaría una
-- unidad que no existe.
select id, producto, rubro, stock_actual, perecedero
from public.productos
where id in (110, 113, 192)
order by producto;
