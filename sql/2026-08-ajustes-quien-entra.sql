-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea el permiso de entrar a Ajustes y te lo da SOLO a ti.
--  QUÉ VER:   el bloque 2: una sola fila con puede_ajustes en true.
-- ================================================================
--
-- UN SOLO PERMISO, y es tu decisión del 2026-08-17: "hay dos categorías,
-- o puedes o no puedes entrar a ajustes". Quien entra tiene todo lo
-- administrativo, incluido el empuje manual a Fudo; quien no entra ve la
-- app de siempre y no se entera de que existe la tuerca.
--
-- ⚠️ Nace en false para TODOS. Mientras no corras esto, nadie ve el botón
-- —ni siquiera tú—. Es a propósito: una zona de administración que se
-- abre sola por no haber corrido un script sería la peor forma de
-- estrenarla.
--
-- El ⟳ que empuja a Fudo NO se toca: ese quedó abierto para todo el
-- equipo el 15 de agosto y sigue igual.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA COLUMNA, Y EL PERMISO PARA TI
-- QUÉ VER: "Success". No devuelve filas.
-- ================================================================
alter table public.app_permisos
  add column if not exists puede_ajustes boolean not null default false;

-- Si tu correo todavía no estuviera en la tabla, se agrega; y si ya está,
-- solo se le enciende el permiso. Las demás cuentas no se tocan.
insert into public.app_permisos (correo, nombre, puede_ajustes, puede_fudo, puede_editar)
values ('leoalejoleo1@gmail.com', 'Jhon', true, true, true)
on conflict (correo) do update set puede_ajustes = true;


-- ================================================================
-- BLOQUE 2 — COMPROBAR
--
-- QUÉ VER: tu correo con puede_ajustes en true, y TODOS los demás en
-- false. Desde la app vas a poder ir encendiéndoselo a quien quieras,
-- sin volver acá.
--
-- ⚠️ La primera versión de este bloque falló con "column sede does not
-- exist". No era un error del permiso: esa columna la creaba otro script
-- de agosto que decidiste no correr, y nombrarla derecho tumba la
-- consulta entera. Acá se pregunta si existe en vez de darla por hecha.
-- ================================================================
-- `sede` se lee con to_jsonb porque esa columna puede no existir: la
-- creaba `2026-08-permiso-por-sede.sql`, que Jhon decidió NO correr (§9.6).
-- Nombrarla derecho hace fallar el bloque entero por una palabra (§0.1.9),
-- que es exactamente lo que pasó la primera vez.
select correo, nombre, puede_ajustes, puede_fudo, puede_editar,
       to_jsonb(a) ->> 'sede' as sede
from public.app_permisos a
order by puede_ajustes desc, correo;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-ajustes-quien-entra.sql', 'Jhon', 'lo corrió Jhon',
        'Permiso puede_ajustes: un solo nivel para toda la zona de administración. Encendido solo para Jhon')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
