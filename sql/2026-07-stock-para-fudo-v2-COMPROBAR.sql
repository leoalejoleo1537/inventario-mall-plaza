-- ================================================================
-- COMPROBACIONES de la v2 — correr DESPUÉS del archivo CORTO.
-- Todas de solo lectura. Correr de a una si el panel se corta.
-- ================================================================

-- 1) TIENE QUE SALIR UNA SOLA FILA.
-- Dos versiones conviviendo vuelven ambigua la llamada por la API y la
-- petición se rechaza antes de ejecutar nada. Es lo que dejó el
-- inventario 15 horas sin descontar el 2026-07-27.
select p.oid::regprocedure as funcion_instalada
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='fudo_stock_calculado';


-- 2) Los envases ya no limitan: estos deberían subir de 0 a un número real
select producto_fudo, stock_en_fudo, stock_calculado, insumo_que_limita,
       ignorados as envases_ignorados
from public.fudo_stock_calculado('plaza')
where ignorados is not null
order by producto_fudo;


-- 3) El resumen
select count(*) as se_actualizarian,
       count(*) filter (where deja_en_cero) as quedarian_en_cero
from public.fudo_stock_calculado('plaza');


-- 4) Los que aún quedarían en cero, para revisarlos uno por uno
select producto_fudo, stock_en_fudo, insumo_que_limita, insumos
from public.fudo_stock_calculado('plaza')
where deja_en_cero
order by stock_en_fudo desc;
