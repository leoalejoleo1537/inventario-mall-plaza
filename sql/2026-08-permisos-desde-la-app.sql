-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo
--  QUÉ HACE:  deja que el interruptor de "Personas y acceso" de verdad
--             guarde. Hoy dice que guardó y no guarda nada.
--  QUÉ VER:   el bloque 2 tiene que mostrar 3 permisos: leer, agregar y
--             cambiar. Hoy hay uno solo.
-- ================================================================
--
-- QUÉ ESTABA PASANDO, en tus palabras: "he habilitado a Adriana y a
-- Massiel pero cada tanto se desactivan".
--
-- No se desactivaban: nunca llegaron a activarse.
--
-- LA METÁFORA, porque el detalle técnico no ayuda: la lista de personas
-- está detrás de un vidrio. Se puede LEER perfectamente, pero la puerta
-- para escribir está cerrada desde julio, cuando los permisos se daban a
-- mano desde acá y no hacía falta que la app escribiera.
--
-- Y lo peor no es que estuviera cerrada, es que **no avisa**. Al apretar
-- el interruptor, la app le pide a la base que cambie esa fila; la base no
-- la deja, pero en vez de decir "no puedo" contesta "listo, no cambié
-- ninguna fila". La app le cree, pinta el interruptor en verde y te dice
-- "✓ Ahora entra a Ajustes". Al recargar, la lista vuelve a la verdad.
--
-- Se arregla en dos partes, y las dos van juntas:
--   · acá se abre la puerta;
--   · en la app, el interruptor ahora PIDE DE VUELTA la fila que cambió, y
--     si no viene ninguna te lo dice en vez de mentirte.
--
-- ⚠️ SOLO PARA CUENTAS CON SESIÓN INICIADA. La app entera funciona sin
-- iniciar sesión y así se queda (es tu decisión, §6.1) — pero esta lista
-- es la que decide quién puede escribirle a Fudo, así que para tocarla hay
-- que haber entrado con un correo. No es cerrarle la puerta a nadie del
-- equipo: para ver Ajustes ya hay que estar dentro con tu cuenta.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ABRIR LA PUERTA
-- QUÉ VER: "Success". No devuelve filas.
-- ================================================================
drop policy if exists "app_permisos alta"    on public.app_permisos;
drop policy if exists "app_permisos cambio"  on public.app_permisos;

create policy "app_permisos alta" on public.app_permisos
  for insert to authenticated with check (true);

create policy "app_permisos cambio" on public.app_permisos
  for update to authenticated using (true) with check (true);

-- La política dice QUIÉN puede; el grant dice QUÉ operaciones existen.
-- Hacen falta las dos: con una sola, sigue sin escribir.
grant insert, update on public.app_permisos to authenticated;

-- Borrar NO se abre a propósito. Quitarle el acceso a alguien es apagarle
-- el interruptor, que se puede deshacer; borrar la fila entera se lleva
-- también su historial y no tiene botón en ninguna pantalla.


-- ================================================================
-- BLOQUE 2 — COMPROBAR
--
-- QUÉ VER, y es lo único que importa:
--   · TRES filas: "app_permisos read" (select), "app_permisos alta"
--     (insert) y "app_permisos cambio" (update).
--   · Y abajo, la lista de quién entra hoy a Ajustes.
--
-- Si solo aparece una fila, el bloque 1 no corrió.
-- ================================================================
select policyname as permiso, cmd as operacion, roles::text as para_quien
from pg_policies
where schemaname = 'public' and tablename = 'app_permisos'
order by cmd;


-- ================================================================
-- BLOQUE 3 — QUIÉN ENTRA HOY  (correr después del 2, en otro Run)
--
-- QUÉ VER: la lista de personas. Los que digan "true" en puede_ajustes
-- son los que ven la tuerca. Desde la app ya vas a poder cambiarlo tú.
--
-- Si Adriana y Massiel aparecen en false, es justo lo que veníamos
-- diciendo: los cambios que hiciste nunca llegaron. Vuelve a encenderlos
-- desde Ajustes -> Personas y acceso, y esta vez sí queda.
-- ================================================================
select correo, nombre, puede_ajustes, puede_fudo, puede_editar
from public.app_permisos
order by puede_ajustes desc, correo;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-permisos-desde-la-app.sql', 'Jhon', 'lo corrió Jhon',
        'app_permisos pasa a aceptar insert y update de cuentas con sesión. Sin esto el interruptor de Personas decía que guardaba y no guardaba')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
