-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  crea la tabla de tareas del turno y le agrega el campo
--             "nombre" a los repartos. SÍ ESCRIBE, pero solo crea cosas
--             nuevas: no toca ni un producto, ni una receta, ni stock.
--  QUÉ VER:   al terminar, en la app: en Angamos aparece el ícono de
--             tareas arriba, y al armar un reparto hay un campo de nombre.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA LISTA DE TAREAS DEL TURNO
--
-- Va por sede: cada local tiene las suyas. Se enciende y se apaga desde
-- el código por ahora (FLAGS en index.html); el día que exista el panel
-- de configuración eso pasa a ser un interruptor.
-- ================================================================
create table if not exists public.tareas(
  id          bigint generated always as identity primary key,
  sede        text    not null,
  texto       text    not null,
  hecha       boolean not null default false,
  creada_por  text,
  created_at  timestamptz not null default now()
);
create index if not exists tareas_sede_idx on public.tareas(sede, id);

alter table public.tareas enable row level security;
drop policy if exists "tareas todos" on public.tareas;
create policy "tareas todos" on public.tareas
  for all to anon, authenticated using (true) with check (true);
grant select, insert, update, delete on public.tareas to anon, authenticated;

-- La app la lee en vivo: sin esto, dos teléfonos no se ven las marcas.
alter publication supabase_realtime add table public.tareas;


-- ================================================================
-- BLOQUE 2 — NOMBRE DEL REPARTO
--
-- Lo pidió el equipo: "reparto de tortas" se reconoce de un vistazo
-- mejor que "Adriana · 06:05". Es opcional — los repartos que ya existen
-- quedan sin nombre y se ven igual que antes.
-- ================================================================
alter table public.repartos
  add column if not exists nombre text;

comment on column public.repartos.nombre is
  'Nombre que le pone quien arma el reparto. Opcional, solo para reconocerlo.';


-- ---------- comprobación ----------
select 'tareas'   as tabla, count(*) as filas from public.tareas
union all
select 'repartos con nombre', count(*) from public.repartos where nombre is not null;


-- ================================================================
-- SI QUIERES DEJAR LA LISTA YA CARGADA
--
-- En vez de escribirlas en la app una por una, se pueden meter de acá.
-- Cambiar los textos por los de verdad y correr:
--
-- insert into public.tareas (sede, texto, creada_por) values
--   ('angamos', 'Revisar fechas de los sándwiches', 'Jhon'),
--   ('angamos', 'Contar la vitrina de tortas',      'Jhon'),
--   ('angamos', 'Botar lo vencido',                 'Jhon');
--
-- Para copiarlas a la otra sede después:
-- insert into public.tareas (sede, texto, creada_por)
-- select 'plaza', texto, creada_por from public.tareas where sede='angamos';
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-tareas-y-nombre-de-reparto.sql', 'Jhon', 'lo corrió Jhon',
        'Tabla de tareas del turno (encendida solo en angamos por FLAGS) y campo nombre en repartos')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
