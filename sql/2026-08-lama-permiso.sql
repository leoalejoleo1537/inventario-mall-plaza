-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque (pégalo entero y aprieta Run)
--  TARDA:     instantáneo
--  QUÉ HACE:  abre la puerta de Llamita Lama para UNA sola cuenta.
--             No toca ningún dato del inventario.
--  QUÉ VER:   la última consulta deja UNA fila por cada cuenta que puede
--             entrar. Tiene que salir SOLO leoalejoleo12@gmail.com.
-- ================================================================
--
-- QUÉ ES ESTO
--
-- Llamita Lama es el área de ventas —mesas y comandas— y se construye
-- ESCONDIDA. Jhon: "si algo falla aquí, podríamos perder o entorpecer todo un
-- día de ventas, necesito trabajar tranquilo".
--
-- La puerta es una columna nueva, `puede_lama`, que **nace apagada para
-- todos**. Es el mismo patrón que `puede_ajustes`.
--
-- POR QUÉ NO SE ESCRIBE EL CORREO EN EL CÓDIGO
--
-- Sería lo más rápido y está prohibido en este proyecto. La doctrina de §0.65
-- lo dice con estas palabras: *"si algún día hay que cerrar algo, se cierra
-- desde Ajustes, cuenta por cuenta — nunca escribiéndolo en el código"*. Esa
-- regla salió del día que un candado escrito a mano impidió que llegara el
-- pan. El permiso vive en la tabla, como todos los demás.
--
-- ⚠️ Y QUE QUEDE DICHO: esto es un SEGURO CONTRA EL RESBALÓN, no seguridad.
-- Es lo mismo que el Modo edición (§6.1, §9.6). Alguien que abra las
-- herramientas del navegador vería el código de Lama igual. Para lo que hace
-- falta —que el equipo no la vea ni la pida— alcanza.
-- ================================================================

alter table public.app_permisos
  add column if not exists puede_lama boolean not null default false;

comment on column public.app_permisos.puede_lama is
  'Ve el área de ventas (Llamita Lama). Nace apagada: mientras se construye, solo la cuenta de trabajo la tiene.';

-- La cuenta de trabajo. Si la fila ya existe (porque esa cuenta ya entró a la
-- app alguna vez), se le enciende el permiso en vez de crear una duplicada.
insert into public.app_permisos (correo, nombre, puede_ajustes, puede_editar, puede_fudo, puede_lama)
values ('leoalejoleo12@gmail.com', 'Jhon (Lama)', true, true, true, true)
on conflict (correo) do update
   set puede_lama    = true,
       puede_ajustes = true,
       puede_editar  = true,
       puede_fudo    = true;


insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-lama-permiso.sql', 'Jhon', 'lo corrió Jhon',
        'Columna puede_lama, apagada por defecto. Solo leoalejoleo12@gmail.com la tiene encendida')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;


-- ================================================================
-- COMPROBACIÓN
--
-- QUÉ VER: UNA sola fila, y tiene que decir leoalejoleo12@gmail.com.
-- Si salieran dos, hay una cuenta del equipo con la puerta abierta y hay que
-- apagarla antes de seguir.
-- ================================================================
select correo, nombre, puede_lama
  from public.app_permisos
 where puede_lama
 order by correo;
