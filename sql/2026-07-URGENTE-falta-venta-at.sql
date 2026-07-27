-- ================================================================
-- URGENTE — el motor no descontaba ninguna venta
--
-- Causa: el motor v5 (sql/2026-07-reposicion-congelador-y-tope-cero.sql)
-- escribe la columna venta_at en fudo_movimientos, pero esa columna se
-- creaba en sql/2026-07-fecha-real-de-venta.sql, que nunca se corrió en
-- esta base. Resultado: el INSERT falla en TODAS las ventas, el motor
-- lanza excepción y la sync las cuenta como errores — pero igual responde
-- "ok", así que la app decía "ventas actualizadas" sin descontar nada.
--
-- QUÉ HACE: agrega la columna que falta. No borra ni modifica ninguna
-- fila. Si la columna ya existiera, no hace nada.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Después: apretar ⟳ en la app.
-- ================================================================

-- ---------- 1) La columna que falta ----------
alter table public.fudo_movimientos
  add column if not exists venta_at timestamptz;

-- ---------- 2) Asegurar que la sede está descontando de verdad ----------
select public.fudo_set_modo('plaza', 'real');

-- ---------- 3) Comprobación ----------
-- 'columna_venta_at' debe decir 1, y el modo debe decir 'real'.
select (select count(*) from information_schema.columns
         where table_schema='public' and table_name='fudo_movimientos'
           and column_name='venta_at')          as columna_venta_at,
       (select modo from public.fudo_sync where sede='plaza') as modo_plaza;
