-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque
--  TARDA:     instantáneo
--  QUÉ HACE:  quita UNA regla de la tabla de equivalencias que puse mal.
--             La tabla está vacía, así que no toca ningún dato.
--  QUÉ VER:   la comprobación deja UNA fila, y tiene que decir SÍ y NO.
-- ================================================================
--
-- QUÉ ESTABA MAL, y lo destapó el informe de los enlaces:
--
-- Yo había puesto que un producto de bodega puede tener UN solo gemelo por
-- sede. Los datos dicen que no:
--
--     "Brownie" (bodega)  ->  "Brownie Vitrina"  Y  "Brownie Congelador"
--
-- No es un error del inventario: en las sedes el mismo producto vive en dos
-- muebles. Pasa con brownies, donas, muffins, galletones, macarrons y
-- volcanes. Con esa regla puesta, la mitad de los enlaces no se podrían
-- guardar.
--
-- LA OTRA REGLA SE QUEDA, y es la que de verdad importa: cada producto de
-- la sede viene de UN SOLO producto de bodega. Esa es la dirección que el
-- reparto necesita — de la línea del reparto, que apunta al producto de la
-- sede, hay que poder llegar a un único producto de bodega. Si esa se
-- perdiera, volvería la ambigüedad de los macarrons.
--
-- Se puede correr aunque los cimientos no se hayan corrido todavía: si la
-- tabla no existe, no hace nada y la comprobación lo dice.
-- ================================================================

alter table if exists public.producto_enlace
  drop constraint if exists producto_enlace_uno_por_sede;


-- ================================================================
-- COMPROBACIÓN — una fila. Tiene que decir:
--    uno_por_sede    -> NO   (la que sacamos)
--    uno_por_origen  -> SÍ   (la que se queda)
-- ================================================================
select case when to_regclass('public.producto_enlace') is null
            then 'la tabla no existe todavía — corre primero los cimientos'
            else 'la tabla existe' end                            as estado,
       case when exists (
              select 1 from pg_constraint
               where conname = 'producto_enlace_uno_por_sede')
            then 'SÍ (mal: todavía está)' else 'NO' end           as uno_por_sede,
       case when exists (
              select 1 from pg_constraint
               where conname = 'producto_enlace_uno_por_origen')
            then 'SÍ' else 'NO (mal: debería estar)' end          as uno_por_origen;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-bodega-arreglar-enlace.sql', 'Jhon', 'lo corrió Jhon',
        'Quita producto_enlace_uno_por_sede: un producto de bodega SÍ va a dos de la sede cuando existe el par vitrina/congelador')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
