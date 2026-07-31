-- ================================================================
-- ETAPA 6 — QUE EL MOTOR DEJE DICHO CÓMO LE FUE
--
-- La imagen: hasta hoy la alarma de incendio funcionaba, pero estaba en
-- tu bolsillo. Sonaba solo cuando entrabas a la casa a revisar (o sea,
-- cuando alguien apretaba ⟳). Esto la atornilla al techo.
--
-- QUÉ HACE: le agrega 7 casilleros a la tabla fudo_sync, que ya existe y
-- ya tiene una fila por sede. Ahí el motor va a anotar, cada vez que
-- corra: cuándo fue, cuántos ítems vio, cuántos fallaron y quién lo
-- disparó. La pantalla los lee y avisa sin depender de nadie.
--
-- QUÉ TOCA: solo la tabla fudo_sync. No toca productos, ni recetas, ni
-- stock, ni fechas. Los casilleros nacen vacíos.
--
-- SI SALE MAL: no pasa nada. Los casilleros quedan sin crear y todo
-- sigue funcionando como hoy — el motor descuenta igual.
--
-- Correrlo dos veces no hace nada malo ("if not exists").
-- ================================================================

alter table public.fudo_sync
  add column if not exists cron_activo          boolean not null default false,
  add column if not exists ultima_corrida_at    timestamptz,
  add column if not exists ultima_corrida_por   text,
  add column if not exists ultimo_resultado     text,
  add column if not exists ultimos_items        integer,
  add column if not exists ultimos_errores      integer,
  add column if not exists ultimos_movimientos  integer;

-- La app lee esta tabla sin sesión iniciada, igual que el resto (§6.1).
grant select on public.fudo_sync to anon, authenticated;

drop policy if exists "fudo_sync read" on public.fudo_sync;
create policy "fudo_sync read" on public.fudo_sync
  for select to anon, authenticated using (true);


-- ---------- Comprobación: tienen que salir las 7 ----------
select column_name as casillero
from information_schema.columns
where table_schema='public' and table_name='fudo_sync'
  and column_name in ('cron_activo','ultima_corrida_at','ultima_corrida_por',
                      'ultimo_resultado','ultimos_items','ultimos_errores','ultimos_movimientos')
order by 1;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-07-estado-del-motor.sql', 'Jhon', 'lo corrió Jhon',
        'Casilleros en fudo_sync para que el motor deje dicho cómo le fue')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
