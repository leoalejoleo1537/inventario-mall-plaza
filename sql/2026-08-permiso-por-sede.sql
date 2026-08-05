-- ================================================================
--  ⚠️⚠️  NO CORRER. GUARDADO POR SI ALGÚN DÍA HACE FALTA.  ⚠️⚠️
--
--  Jhon decidió el 2026-08-04 NO acotar el permiso por sede: le presta
--  su cuenta al personal de Angamos y los capacita él. Son dos personas
--  y un producto borrado se vuelve a crear. Ver §9.6 del archivo madre.
--
--  Mientras este archivo no se corra, la columna `sede` no existe y la
--  app funciona exactamente como siempre — `permisosDeLaSede()` devuelve
--  el permiso completo. Eso está probado (pruebas/permiso-por-sede.mjs).
--
--  Cuándo volver a mirarlo: si crece la cantidad de gente con permiso,
--  o cuando se encienda el empuje de stock a Fudo en Angamos.
-- ================================================================
--
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  agrega una columna "sede" a la tabla de permisos, para
--             poder dar Modo edición SOLO en Angamos. El bloque 3 SÍ
--             ESCRIBE: crea la cuenta del personal de Angamos.
--  QUÉ VER:   el bloque 3 devuelve la lista completa de quién puede
--             qué, y en qué sede.
-- ================================================================
--
-- LA IMAGEN QUE LO EXPLICA: hoy el permiso es una llave maestra —
-- abre las dos sedes. Esto la convierte en la llave de UNA puerta:
-- la cuenta de Angamos abre Angamos y no abre Mall Plaza.
--
-- POR QUÉ IMPORTA: el personal de Angamos va a hacer su depuración —
-- borrar el Muffin Amapola, agregar el Agua Bosqua, apagar los
-- duplicados de Congelador que allá no van. Todo eso necesita Modo
-- edición. Pero Mall Plaza lleva meses cuadrada, y un borrado sin
-- querer allá es caro de deshacer.
--
-- ⚠️ LO QUE ESTO **NO** ES: no es seguridad, es un seguro contra
-- accidentes — y está bien que así sea (§6.1: la seguridad se mantiene
-- en mínimos). Evita el resbalón, no al malintencionado.
--
-- ⚠️ Y ESTO TAMPOCO LE CAMBIA NADA A NADIE: las 5 cuentas que ya
-- existen quedan con la sede VACÍA, que significa "todas las sedes".
-- Adriana, Valentina y las demás siguen exactamente igual que ayer.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ANTES: quién puede qué hoy
--
-- SOLO LECTURA. Para tener la foto de partida y ver los correos tal
-- como están escritos.
-- ================================================================
select correo, nombre, puede_fudo, puede_editar
from public.app_permisos
order by nombre;


-- ================================================================
-- BLOQUE 2 — AGREGAR LA COLUMNA
--
-- Nace vacía en todas las filas = todas las cuentas siguen abriendo
-- las dos sedes. Nadie pierde nada al correr esto.
-- ================================================================
alter table public.app_permisos
  add column if not exists sede text;

comment on column public.app_permisos.sede is
  'Acota el permiso a UNA sede. Vacío = todas las sedes.';


-- ================================================================
-- BLOQUE 3 — LA CUENTA DEL PERSONAL DE ANGAMOS
--
-- ▼▼▼ CAMBIA EL CORREO POR EL DE VERDAD ANTES DE APRETAR RUN ▼▼▼
--
-- Tres cosas de esta línea, y las tres son a propósito:
--
--   puede_editar = true    -> pueden crear, renombrar y eliminar
--   puede_fudo   = false   -> NO pueden escribirle el stock a Fudo.
--                             Ese botón todavía no se enciende en
--                             Angamos (§9.2) y no hace falta para
--                             ordenar el inventario.
--   sede = 'angamos'       -> el Modo edición no aparece en Plaza.
--
-- Se puede correr las veces que quieras: si el correo ya está, solo
-- le actualiza los permisos. No duplica.
-- ================================================================
insert into public.app_permisos (correo, nombre, puede_fudo, puede_editar, sede, creado_por)
values ('CAMBIAR@correo.cl', 'Angamos', false, true, 'angamos', 'Jhon')
on conflict (correo) do update
  set nombre       = excluded.nombre,
      puede_fudo   = excluded.puede_fudo,
      puede_editar = excluded.puede_editar,
      sede         = excluded.sede;


-- ---------- comprobación: la lista completa ----------
-- La columna "alcance" es la que hay que mirar.
select correo,
       nombre,
       puede_editar,
       puede_fudo,
       coalesce(sede, 'TODAS')                       as alcance,
       case when sede is null then 'abre las dos sedes'
            else 'solo ' || sede end                 as que_significa
from public.app_permisos
order by sede nulls first, nombre;


-- ================================================================
-- SI HAY QUE DESHACERLO
--
-- Quitarle el límite a alguien (que vuelva a abrir todas las sedes):
--   update public.app_permisos set sede = null where correo = 'el@correo.cl';
--
-- Quitarle el permiso del todo:
--   delete from public.app_permisos where correo = 'el@correo.cl';
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-permiso-por-sede.sql', 'Jhon', 'lo corrió Jhon',
        'app_permisos.sede acota el permiso a una sede. Modo edición para el personal de Angamos, solo allá')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
