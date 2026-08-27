-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Corre el 1, mira el resultado, después el 2.
--  TARDA:     ~2 segundos cada uno
--  QUÉ HACE:  crea las cuatro tablas de Llamita Lama y siembra las 12 mesas
--             del Salón de Mall Plaza. NO toca el inventario.
--  QUÉ VER:   el bloque 1 deja 8 filas, TODAS tienen que decir SÍ.
--             El bloque 2 deja 3 filas con los nombres de las tablas.
--  SE PUEDE CORRER de nuevo: el bloque 1 no duplica nada. El 2, si ya lo
--             corriste, va a decir que la tabla ya está en la publicación —
--             ese aviso es normal y no rompe nada.
-- ================================================================
--
-- LA IMAGEN, para entender las cuatro tablas
--
--   Una MESA es un lugar del salón. Existe siempre, esté ocupada o no.
--   Una CUENTA es una visita a esa mesa: nace cuando llega alguien y muere
--   cuando se paga. Una mesa tiene muchas cuentas a lo largo del día.
--   Los ITEMS son lo que se pidió en esa cuenta.
--   Una COMANDA es cada papel que sale a la cocina. Una cuenta puede tener
--   varias: la gente pide, come, y vuelve a pedir.
--
--   mesas ──< cuentas ──< cuenta_items >── comandas
--
-- EL CANDADO QUE IMPORTA, y va en la base
--
--   Una mesa NO puede tener dos cuentas abiertas al mismo tiempo.
--
-- Se pone como índice único en la tabla, no como lógica en la pantalla. Es
-- integridad de datos —dos cuentas abiertas en la misma mesa significa que
-- alguien va a pagar la cuenta de otro— y por eso califica como candado
-- según §0.8. Dos garzones tocando la misma mesa al mismo tiempo es algo que
-- VA a pasar, no una rareza.
--
-- LO QUE ESTA TABLA NO TIENE, Y ES A PROPÓSITO
--
-- No hay `personas`, ni `cliente`, ni `forma` de la mesa. Fudo las pregunta
-- y Jhon las llamó ruido: nadie las mira después. Se dejan fuera en vez de
-- crearlas "por si acaso" — una columna que nadie llena es una pregunta que
-- la gente contesta por contestar.
--
-- Sí se guarda `salon` aunque hoy solo exista "Salón" (Terraza y POPUP están
-- en Fudo pero no se usan). Guardarla ahora hace que agregar Terraza mañana
-- sea agregar filas, no migrar una tabla con datos adentro.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LAS TABLAS
-- ================================================================

-- ---------- 1) las mesas: el plano del salón ----------
create table if not exists public.mesas (
  id         bigserial primary key,
  sede       text    not null,
  salon      text    not null default 'Salón',
  numero     integer not null,
  orden      integer not null default 0,
  activa     boolean not null default true,
  created_at timestamptz not null default now(),
  constraint mesas_una_por_salon unique (sede, salon, numero)
);
create index if not exists mesas_sede_idx on public.mesas(sede, salon, orden);


-- ---------- 2) las cuentas: una visita a una mesa ----------
create table if not exists public.cuentas (
  id            bigserial primary key,
  sede          text    not null,
  mesa_id       bigint  not null references public.mesas(id) on delete restrict,
  -- abierta = roja · precuenta = azul (se imprimió el detalle) · cerrada = ya se pagó
  estado        text    not null default 'abierta',
  total         numeric not null default 0,
  abierta_por   text,
  abierta_at    timestamptz not null default now(),
  precuenta_at  timestamptz,
  cerrada_por   text,
  cerrada_at    timestamptz,
  constraint cuentas_estado_ok check (estado in ('abierta','precuenta','cerrada'))
);

-- EL CANDADO. Un índice único PARCIAL: solo mira las que no están cerradas,
-- así una mesa puede tener cien cuentas cerradas y una sola viva.
create unique index if not exists cuentas_una_viva_por_mesa
  on public.cuentas(mesa_id) where estado <> 'cerrada';

create index if not exists cuentas_sede_idx on public.cuentas(sede, estado);
create index if not exists cuentas_dia_idx  on public.cuentas(sede, abierta_at desc);


-- ---------- 3) las comandas: cada papel que sale a la cocina ----------
-- Va antes de cuenta_items porque los items apuntan acá.
create table if not exists public.comandas (
  id         bigserial primary key,
  sede       text    not null,
  cuenta_id  bigint  not null references public.cuentas(id) on delete cascade,
  numero     integer not null,          -- 1, 2, 3… dentro de esa cuenta
  quien      text,
  contenido  jsonb,                     -- lo que se imprimió, tal cual
  created_at timestamptz not null default now(),
  constraint comandas_una_por_numero unique (cuenta_id, numero)
);
create index if not exists comandas_cuenta_idx on public.comandas(cuenta_id);


-- ---------- 4) los items: lo que se pidió ----------
create table if not exists public.cuenta_items (
  id              bigserial primary key,
  cuenta_id       bigint  not null references public.cuentas(id) on delete cascade,
  -- El id de Fudo manda, pero el NOMBRE se guarda igual: si mañana renombran
  -- el producto, la comanda de ayer se sigue leyendo. Mismo criterio que
  -- reparto_items (§0.1.1).
  fudo_product_id text,
  nombre          text    not null,
  cantidad        numeric not null default 1,
  precio          numeric not null default 0,
  comentario      text,
  -- nuevo = todavía no salió a la cocina · confirmado = ya se imprimió
  estado          text    not null default 'nuevo',
  comanda_id      bigint  references public.comandas(id) on delete set null,
  agregado_por    text,
  agregado_at     timestamptz not null default now(),
  constraint cuenta_items_estado_ok check (estado in ('nuevo','confirmado')),
  constraint cuenta_items_cantidad_ok check (cantidad > 0)
);
create index if not exists cuenta_items_cuenta_idx on public.cuenta_items(cuenta_id, id);


-- ---------- permisos, igual que todas las demás tablas ----------
alter table public.mesas enable row level security;
drop policy if exists "mesas all" on public.mesas;
create policy "mesas all" on public.mesas
  for all to anon, authenticated using (true) with check (true);
grant all on public.mesas to anon, authenticated;
grant usage, select on sequence public.mesas_id_seq to anon, authenticated;

alter table public.cuentas enable row level security;
drop policy if exists "cuentas all" on public.cuentas;
create policy "cuentas all" on public.cuentas
  for all to anon, authenticated using (true) with check (true);
grant all on public.cuentas to anon, authenticated;
grant usage, select on sequence public.cuentas_id_seq to anon, authenticated;

alter table public.comandas enable row level security;
drop policy if exists "comandas all" on public.comandas;
create policy "comandas all" on public.comandas
  for all to anon, authenticated using (true) with check (true);
grant all on public.comandas to anon, authenticated;
grant usage, select on sequence public.comandas_id_seq to anon, authenticated;

alter table public.cuenta_items enable row level security;
drop policy if exists "cuenta_items all" on public.cuenta_items;
create policy "cuenta_items all" on public.cuenta_items
  for all to anon, authenticated using (true) with check (true);
grant all on public.cuenta_items to anon, authenticated;
grant usage, select on sequence public.cuenta_items_id_seq to anon, authenticated;


-- ---------- las 12 mesas del Salón de Mall Plaza ----------
-- `on conflict do nothing` para poder correr esto de nuevo sin duplicar.
insert into public.mesas (sede, salon, numero, orden)
select 'plaza', 'Salón', n, n from generate_series(1,12) n
on conflict (sede, salon, numero) do nothing;


insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-lama-cimientos.sql', 'Jhon', 'lo corrió Jhon',
        'Cuatro tablas de Llamita Lama (mesas, cuentas, comandas, cuenta_items) + 12 mesas del Salón de Plaza. Candado: una sola cuenta viva por mesa')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;


-- ================================================================
-- COMPROBACIÓN — 8 filas, TODAS en SÍ
-- ================================================================
select 'tabla mesas' as pieza,
       case when to_regclass('public.mesas') is not null then 'SÍ' else 'NO' end as quedo
union all
select 'tabla cuentas',
       case when to_regclass('public.cuentas') is not null then 'SÍ' else 'NO' end
union all
select 'tabla comandas',
       case when to_regclass('public.comandas') is not null then 'SÍ' else 'NO' end
union all
select 'tabla cuenta_items',
       case when to_regclass('public.cuenta_items') is not null then 'SÍ' else 'NO' end
union all
select 'el candado: una sola cuenta viva por mesa',
       case when exists (select 1 from pg_indexes
                          where schemaname='public' and indexname='cuentas_una_viva_por_mesa')
            then 'SÍ' else 'NO (mal: dos garzones podrían abrir la misma mesa)' end
union all
select 'las 12 mesas del Salón',
       case when (select count(*) from public.mesas
                   where sede='plaza' and salon='Salón') = 12
            then 'SÍ' else 'NO (hay ' ||
                 (select count(*) from public.mesas where sede='plaza' and salon='Salón')::text || ')' end
union all
select 'los items no aceptan cantidad 0 ni negativa',
       case when exists (select 1 from pg_constraint
                          where conname='cuenta_items_cantidad_ok')
            then 'SÍ' else 'NO' end
union all
select 'el inventario no se tocó',
       case when to_regclass('public.productos') is not null then 'SÍ' else 'NO' end;


-- ================================================================
-- BLOQUE 2 — EN VIVO  (otro Run, después de que el 1 dé los 8 SÍ)
--
-- mesas, cuentas y cuenta_items SÍ viajan en vivo: dos garzones sobre la
-- misma mesa tienen que verse el uno al otro, o el segundo pide lo que el
-- primero ya pidió.
--
-- comandas NO: es un libro, y un libro no necesita llegar solo a los
-- teléfonos. Mismo criterio que `movimientos` en los cimientos de bodega.
--
-- VA APARTE, y no es capricho: esto se escribía con un bloque `do $$`, y las
-- comillas de dólar son justo lo que a veces atraganta al editor de Supabase
-- (§3.5). Escrito así no hay ninguna, y si algo fallara acá, el bloque 1 —que
-- es el que crea todo— ya quedó hecho.
--
-- QUÉ VER: tres filas, con mesas, cuentas y cuenta_items.
-- Si dice "ya es miembro de la publicación", es que ya lo corriste. Sigue.
-- ================================================================
alter publication supabase_realtime add table public.mesas;
alter publication supabase_realtime add table public.cuentas;
alter publication supabase_realtime add table public.cuenta_items;

select tablename as viaja_en_vivo
  from pg_publication_tables
 where pubname='supabase_realtime'
   and tablename in ('mesas','cuentas','cuenta_items')
 order by tablename;
