-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque (pégalo entero y aprieta Run)
--  TARDA:     instantáneo
--  QUÉ HACE:  agenda una limpieza que corre sola todos los días a las 03:30
--             y borra lo viejo: historial y actividad a los 30 días, los
--             empujes a Fudo a los 2. No toca ningún stock.
--  QUÉ VER:   la última consulta deja 4 filas. Las 4 tienen que decir SÍ.
-- ================================================================
--
-- POR QUÉ, Y CUÁL ES EL PELIGRO
--
-- Esto BORRA. Y lo que borra del `historial` es la única red que tiene este
-- proyecto: el 9 de agosto Angamos quedó en cero y no se pudo recuperar nada
-- porque esa sede no tenía ni una foto guardada (§0.6).
--
-- Así que la limpieza lleva un candado, y este SÍ es de los que se quedan
-- —protege datos, no una forma de trabajar—:
--
--   ⚠️ NUNCA deja una sede con menos de 5 fotos.
--
-- Si una sede tuviera 3 fotos y las 3 fueran de hace un año, no se borra
-- ninguna. "Viejo" no alcanza como motivo para quedarse sin red: solo se
-- borra lo viejo cuando además hay de sobra.
--
-- Y se borra por DÍA COMPLETO, no fila por fila. Media foto es peor que
-- ninguna: al restaurar devolvería la mitad de los productos y nadie lo
-- notaría hasta el descuadre.
--
-- LOS PLAZOS, y por qué no son iguales
--
--   historial        30 días · la foto que saca el equipo al contar. Es la
--                              red, y un mes cubre cualquier vuelta atrás
--   historial_auto   30 días · la foto automática. ES LA QUE MÁS CRECE:
--                              dos por día por cada producto de cada sede,
--                              o sea ~40.000 filas al mes
--   movimientos      30 días · mermas y entradas. El registro de Actividad
--   fudo_stock_push   2 días · contesta "¿alguien ya empujó hace un rato?",
--                              y esa pregunta no mira más atrás que ayer
--
-- `restauraciones` y `fusiones` NO se tocan: son pocas filas y cada una es
-- una decisión grande que conviene poder mirar el año que viene.
--
-- NOTA DE FORMA: no hay ni una comilla de dólar en este archivo, a propósito.
-- El editor de Supabase no las traga (§3.5) y por eso la limpieza va como
-- texto entre comillas simples —dobladas por dentro— en vez de una función.
-- ================================================================

create extension if not exists pg_cron;

-- El script se basta solo (§0.1.2): si la foto automática todavía no se
-- instaló, la tabla se crea acá vacía. Sin esto, el día que se instalara,
-- la limpieza fallaría entera por una tabla que no existe — y fallaría en
-- silencio, de madrugada, que es la peor combinación.
create table if not exists public.historial_auto (
  id           bigserial primary key,
  sede         text        not null,
  producto_id  bigint      not null references public.productos(id) on delete cascade,
  stock_actual double precision,
  momento      text        not null,
  tomada_at    timestamptz not null default now(),
  fecha        date        not null default (now() at time zone 'America/Santiago')::date,
  constraint historial_auto_una_por_momento unique (sede, producto_id, fecha, momento)
);
alter table public.historial_auto add column if not exists producto  text;
alter table public.historial_auto add column if not exists rubro     text;
alter table public.historial_auto add column if not exists stock_min double precision;
alter table public.historial_auto add column if not exists stock_max double precision;
alter table public.historial_auto add column if not exists activo    text;

create table if not exists public.limpiezas (
  id          bigserial primary key,
  corrida_at  timestamptz not null default now(),
  historial   integer not null default 0,
  auto        integer not null default 0,
  movimientos integer not null default 0,
  empujes     integer not null default 0
);

comment on table public.limpiezas is
  'Qué borró la limpieza diaria. Si esta tabla deja de crecer, la limpieza dejó de correr.';

-- Cada día guardado por sede, numerado del más nuevo al más viejo.
-- puesto = 1 es la foto más reciente de esa sede.
create or replace view public.dias_de_historial as
select sede, fecha, row_number() over (partition by sede order by fecha desc) as puesto
  from (select distinct sede, fecha from public.historial) d;

create or replace view public.dias_de_historial_auto as
select sede, fecha, row_number() over (partition by sede order by fecha desc) as puesto
  from (select distinct sede, fecha from public.historial_auto) d;


-- ---------- la limpieza, agendada a las 03:30 ----------
-- se quita primero la vieja, si la hubiera: dos tareas con el mismo nombre
-- borrarían dos veces y la segunda no encontraría nada que anotar
select cron.unschedule(jobid) from cron.job where jobname = 'limpieza-diaria';

select cron.schedule('limpieza-diaria', '30 3 * * *',
 'with borra_hist as (delete from public.historial h using public.dias_de_historial d where d.sede = h.sede and d.fecha = h.fecha and d.puesto > 5 and h.fecha < (current_date - 30) returning 1), borra_auto as (delete from public.historial_auto a using public.dias_de_historial_auto d where d.sede = a.sede and d.fecha = a.fecha and d.puesto > 5 and a.fecha < (current_date - 30) returning 1), borra_mov as (delete from public.movimientos where created_at < (now() - interval ''30 days'') returning 1), borra_push as (delete from public.fudo_stock_push where created_at < (now() - interval ''2 days'') returning 1) insert into public.limpiezas (historial, auto, movimientos, empujes) select (select count(*) from borra_hist), (select count(*) from borra_auto), (select count(*) from borra_mov), (select count(*) from borra_push);'
);


-- ================================================================
-- COMPROBACIÓN — 4 filas, las 4 tienen que decir SÍ
-- ================================================================
select 'la limpieza quedó agendada' as pieza,
       case when exists (select 1 from cron.job where jobname='limpieza-diaria')
            then 'SÍ' else 'NO' end as quedo
union all
select 'una sola, no dos',
       case when (select count(*) from cron.job where jobname='limpieza-diaria') = 1
            then 'SÍ' else 'NO (mal: hay repetidas)' end
union all
select 'la tabla que anota lo borrado',
       case when to_regclass('public.limpiezas') is not null then 'SÍ' else 'NO' end
union all
select 'el candado de las 5 fotos se puede leer',
       case when to_regclass('public.dias_de_historial') is not null
             and to_regclass('public.dias_de_historial_auto') is not null
            then 'SÍ' else 'NO' end;


insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-limpieza-automatica.sql', 'Jhon', 'lo corrió Jhon',
        'Limpieza diaria 03:30 — historial, historial_auto y movimientos a 30 días; empujes a Fudo a 2. Nunca deja una sede con menos de 5 fotos')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;


-- ================================================================
-- PARA MIRARLO CUALQUIER DÍA — ¿está corriendo la limpieza?
--
--   select * from public.limpiezas order by corrida_at desc limit 10;
--
-- Si la fila más nueva es de hace tres días, la limpieza dejó de correr.
-- ================================================================
