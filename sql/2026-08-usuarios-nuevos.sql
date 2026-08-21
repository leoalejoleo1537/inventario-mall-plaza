-- ================================================================
--  DÓNDE VA:  primero el panel de Supabase, después el SQL Editor
--  ES:        1 paso a mano + 1 bloque de SQL
--  TARDA:     un minuto
--  QUÉ HACE:  le da entrada a Llamita a Leidy y a Morgan.
--  QUÉ VER:   el bloque 2 tiene que mostrar las dos con su permiso.
-- ================================================================
--
-- POR QUÉ ESTO NO SE PUEDE HACER TODO CON SQL. Entrar a Llamita son DOS
-- cosas distintas y viven en dos sitios:
--
--   1. LA CUENTA — el correo y la contraseña con los que se entra. Eso lo
--      guarda Supabase en su propia zona (Authentication), a la que la app
--      no puede escribir desde el teléfono. Si pudiera, cualquiera que
--      abriera la app podría crearse una cuenta.
--
--   2. EL PERMISO — qué puede hacer esa cuenta adentro. Eso sí es una fila
--      de nuestra tabla `app_permisos`, y se maneja desde Ajustes.
--
-- O sea que hoy el paso 1 se hace a mano. Crear usuarios DESDE Llamita es
-- posible y está anotado como lo siguiente que se construye — necesita una
-- Edge Function, porque la llave que puede crear cuentas no puede vivir
-- dentro de la app.
-- ================================================================


-- ================================================================
-- PASO 1 — CREAR LAS DOS CUENTAS  (a mano, en el panel)
--
-- Supabase  ->  Authentication  ->  Users  ->  **Add user** ->
-- "Create new user"
--
-- Por cada una:
--   · Email:    el de abajo, tal cual, en minúsculas
--   · Password: una que les puedas pasar; ellas la cambian después
--   · Dejar marcado "Auto Confirm User" — si no, la app les va a decir
--     que el correo no está confirmado y no van a poder entrar
--
--   leidysina.05@gmail.com     · Leidy Méndez
--   morganite.cmet@gmail.com   · Morgan Pradena
--
-- QUÉ VER: las dos aparecen en la lista de Users.
-- ================================================================


-- ================================================================
-- PASO 2 — DARLES PERMISO  (esto sí en el SQL Editor)
--
-- Nacen SIN acceso a Ajustes, a propósito: entran a la app, ven el
-- inventario y pueden trabajar, pero no ven la zona de administración.
-- Si alguna lo necesita, se lo enciendes tú desde
-- Ajustes -> Personas y acceso, sin volver acá.
--
-- `puede_editar` sí va en true: es lo que deja corregir stock, mínimos y
-- fechas, que es para lo que están entrando.
--
-- QUÉ VER: "Success". No devuelve filas.
-- ================================================================
insert into public.app_permisos (correo, nombre, puede_ajustes, puede_fudo, puede_editar)
values
  ('leidysina.05@gmail.com',   'Leidy Méndez',   false, false, true),
  ('morganite.cmet@gmail.com', 'Morgan Pradena', false, false, true)
on conflict (correo) do update
  set nombre = excluded.nombre,
      puede_editar = true;


-- ================================================================
-- PASO 3 — COMPROBAR  (otro Run)
--
-- QUÉ VER: la lista de quién entra. Las dos nuevas tienen que aparecer con
-- puede_editar en true y puede_ajustes en false.
-- ================================================================
select correo, nombre, puede_ajustes, puede_fudo, puede_editar
from public.app_permisos
order by puede_ajustes desc, correo;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-usuarios-nuevos.sql', 'Jhon', 'lo corrió Jhon',
        'Leidy Méndez y Morgan Pradena entran a la app. Sin acceso a Ajustes')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
