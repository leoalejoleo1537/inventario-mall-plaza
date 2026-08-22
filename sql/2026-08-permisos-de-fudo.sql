--  DÓNDE VA:  Supabase -> SQL Editor -> New query
--  ES:        1 solo bloque
--  TARDA:     instantáneo
--  QUÉ HACE:  le agrega UNA columna a la lista de personas: `fudo_bloqueos`.
--             Es la lista de lo que esa cuenta NO puede hacer en Fudo.
--             Nace VACÍA para todos, o sea: todos pueden todo, como hoy.
--  QUÉ VER:   la tabla de abajo, con una fila por persona y la columna
--             `bloqueos` en `{}` (vacío) para todos.

-- ============================================================
-- POR QUÉ LA COLUMNA GUARDA LO QUE **NO** SE PUEDE
--
-- El 21 de agosto el reparto dejó de subir a Fudo, y la causa de fondo fue
-- que las cuentas nuevas NACÍAN sin el permiso: había que acordarse de
-- dárselo. Un permiso que hay que acordarse de dar es un permiso que
-- alguien va a olvidar, y el día que se olvide nadie se entera — el
-- inventario queda bien y Fudo mal, en silencio.
--
-- Guardando los BLOQUEOS en vez de los permisos, eso no puede volver a
-- pasar: una cuenta nueva, una fila que falta, una columna que todavía no
-- existe o una lectura que no llegó significan todas lo mismo, "no hay
-- ningún bloqueo", o sea todo permitido. Nacer abierto deja de ser un
-- valor por defecto que alguien puede cambiar sin querer, y pasa a ser la
-- forma de la tabla.
-- ============================================================

alter table public.app_permisos
  add column if not exists fudo_bloqueos text[] not null default '{}'::text[];

-- Que nadie quede bloqueado por el cambio (por si la columna ya existía).
update public.app_permisos set fudo_bloqueos = '{}'::text[] where fudo_bloqueos is null;

-- La app tiene que poder escribirla desde Ajustes.
grant select, insert, update on public.app_permisos to anon, authenticated;

drop policy if exists "app_permisos escribir" on public.app_permisos;
create policy "app_permisos escribir" on public.app_permisos
  for update to anon, authenticated using (true) with check (true);

-- Queda anotado en el cuaderno de migraciones, sin depender de que
-- alguien se acuerde.
insert into public.migraciones_aplicadas (archivo, nota)
values ('2026-08-permisos-de-fudo.sql',
        'fudo_bloqueos: lista de lo que una cuenta NO puede hacer en Fudo. Nace vacia.')
on conflict do nothing;

select correo, nombre,
       coalesce(fudo_bloqueos, '{}'::text[]) as bloqueos,
       cardinality(coalesce(fudo_bloqueos,'{}'::text[])) as cuantos_bloqueos
from public.app_permisos
order by correo;
