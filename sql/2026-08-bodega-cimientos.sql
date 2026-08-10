-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Se pueden correr los 3 juntos de una vez.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea una columna y dos tablas VACÍAS. No mueve stock, no
--             cambia productos, no borra nada. Después de correrlo la
--             app se ve exactamente igual que ahora.
--  QUÉ VER:   la comprobación del final: tienen que salir 3 filas en SÍ.
-- ================================================================
--
-- LA IMAGEN: esto es poner los cimientos. No se ve nada arriba todavía,
-- pero sin ellos no se puede levantar ninguna pared.
--
-- Se puede correr las veces que quieras: si algo ya existe, lo deja como
-- está y no se queja.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA UNIDAD DE MEDIDA
--
-- Hoy "Café en grano 8" no dice si son 8 bultos, 8 kilos u 8 paquetes.
-- En un local da lo mismo; en bodega no, porque bodega es justo donde
-- llega el bulto de 30 kg que después se reparte en kilos, y quien
-- cuenta necesita saber qué está contando.
--
-- Nace vacía. En un paso aparte te voy a proponer un valor para cada
-- producto y tú corriges los que estén mal.
-- ================================================================
alter table public.productos add column if not exists unidad text;

comment on column public.productos.unidad is
  'unidad / kilo / litro / bulto / paquete. Vacío = se cuenta de a uno.';


-- ================================================================
-- BLOQUE 2 — LA TABLA DE EQUIVALENCIAS BODEGA <-> SEDE
--
-- Para que el reparto pueda RESTAR de bodega, el sistema tiene que
-- saber qué producto de bodega es el gemelo del de la sede. Son filas
-- distintas con ids distintos, así que hay que decírselo.
--
-- Nace VACÍA a propósito. Se llena en el paso siguiente, con la lista
-- de pares que tú vas a revisar antes.
--
-- LAS DOS REGLAS DE UNICIDAD SON LO IMPORTANTE:
--   · un producto de bodega tiene UN gemelo por sede, no dos
--   · un producto de la sede viene de UN solo producto de bodega
-- Eso es justo lo que faltaba cuando pasó el lío de los macarrons: la
-- relación vivía escondida en el nombre y podía tener dos candidatos
-- sin que nadie lo viera. Acá la base no lo permite.
-- ================================================================
create table if not exists public.producto_enlace (
  id                  bigserial primary key,
  producto_bodega_id  bigint  not null references public.productos(id) on delete cascade,
  sede                text    not null,
  producto_sede_id    bigint  not null references public.productos(id) on delete cascade,
  -- cuántas unidades de la sede salen de UNA de bodega.
  -- Por ahora siempre 1. Existe para el día del bulto de 30 kg, y así
  -- ese día no hay que migrar la tabla con datos adentro.
  factor              numeric not null default 1,
  creado_por          text,
  created_at          timestamptz not null default now(),
  constraint producto_enlace_factor_ok check (factor > 0),
  constraint producto_enlace_uno_por_sede   unique (producto_bodega_id, sede),
  constraint producto_enlace_uno_por_origen unique (sede, producto_sede_id)
);

create index if not exists producto_enlace_bodega_idx on public.producto_enlace(producto_bodega_id);
create index if not exists producto_enlace_sede_idx   on public.producto_enlace(sede, producto_sede_id);

alter table public.producto_enlace enable row level security;
drop policy if exists "producto_enlace all" on public.producto_enlace;
create policy "producto_enlace all" on public.producto_enlace
  for all to anon, authenticated using (true) with check (true);
grant all on public.producto_enlace to anon, authenticated;
grant usage, select on sequence public.producto_enlace_id_seq to anon, authenticated;


-- ================================================================
-- BLOQUE 3 — EL LIBRO DE MOVIMIENTOS
--
-- El cuaderno donde queda anotado TODO lo que se mueve: lo que entra
-- del proveedor, lo que sale a las sedes, lo que se echa a perder y las
-- correcciones a mano.
--
-- Hoy no existe nada así: el historial guarda una foto diaria, no los
-- movimientos. Por eso no se puede responder "cuánto café entró este
-- mes" — el dato nunca se guardó.
--
-- SE CONSTRUYE AHORA aunque las estadísticas queden para después: es de
-- donde van a salir, y agregarlo más tarde obligaría a rehacer todo lo
-- que se construya encima.
--
-- ⚠️ EL SIGNO ES LA DIRECCIÓN, y esto hay que entenderlo una vez:
--   cantidad POSITIVA = entró          (+12)
--   cantidad NEGATIVA = salió          (−3)
-- El "tipo" dice el MOTIVO, no la dirección. Así, para saber cuánto hay
-- que hacer basta sumar la columna, sin andar preguntando por el tipo.
-- ================================================================
create table if not exists public.movimientos (
  id                bigserial primary key,
  sede              text    not null,     -- dónde ocurre el movimiento
  producto_id       bigint  not null references public.productos(id) on delete cascade,
  -- el id es el que manda (los nombres cambian); el nombre se guarda
  -- para que el libro se siga leyendo aunque después renombren algo
  producto          text    not null,
  tipo              text    not null,     -- entrada | salida | merma | ajuste
  cantidad          numeric not null,     -- + entra · − sale
  sede_contraparte  text,                 -- a dónde fue o de dónde vino
  motivo            text,
  reparto_item_id   bigint,               -- si el movimiento nació de un reparto
  quien             text,
  created_at        timestamptz not null default now(),
  constraint movimientos_tipo_ok check (tipo in ('entrada','salida','merma','ajuste')),
  constraint movimientos_cant_ok check (cantidad <> 0)
);

create index if not exists movimientos_sede_fecha_idx on public.movimientos(sede, created_at desc);
create index if not exists movimientos_producto_idx   on public.movimientos(producto_id, created_at desc);
create index if not exists movimientos_tipo_idx       on public.movimientos(sede, tipo, created_at desc);

alter table public.movimientos enable row level security;
drop policy if exists "movimientos all" on public.movimientos;
create policy "movimientos all" on public.movimientos
  for all to anon, authenticated using (true) with check (true);
grant all on public.movimientos to anon, authenticated;
grant usage, select on sequence public.movimientos_id_seq to anon, authenticated;

-- NOTA: a propósito NO se agrega a la publicación de tiempo real. Un
-- libro de registro no necesita llegar solo a los teléfonos, y agregarlo
-- obligaría a usar comillas de dólar, que es justo lo que rompe el
-- editor de Supabase.


-- ================================================================
-- COMPROBACIÓN — tienen que salir 3 filas, las 3 en SÍ
-- ================================================================
select 'columna unidad en productos' as pieza,
       case when exists (select 1 from information_schema.columns
                          where table_schema='public' and table_name='productos'
                            and column_name='unidad')
            then 'SÍ' else 'NO' end as quedo
union all
select 'tabla producto_enlace',
       case when to_regclass('public.producto_enlace') is not null then 'SÍ' else 'NO' end
union all
select 'tabla movimientos',
       case when to_regclass('public.movimientos') is not null then 'SÍ' else 'NO' end;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-bodega-cimientos.sql', 'Jhon', 'lo corrió Jhon',
        'Cimientos de bodega: columna unidad en productos, tabla producto_enlace (vacía) y libro de movimientos (vacío). No mueve datos.')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
