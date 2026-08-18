-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr uno y después el otro.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea las metas de venta. Nace vacío: no cambia nada.
--  QUÉ VER:   el bloque 2 tiene que dar 2 filas en SÍ.
-- ================================================================
--
-- PARA QUÉ: administración pone objetivos —"vender 100 aguas Bosqua entre
-- con gas y sin gas antes del 31"— y las dos sedes compiten por llegar
-- primero. Hasta hoy eso vivía en un mensaje de WhatsApp y nadie sabía
-- cómo iba.
--
-- CÓMO SE CUENTA, y esto es lo importante: **no hace falta preguntarle
-- nada a Fudo.** Cada ítem vendido queda en `fudo_movimientos` con su
-- sede, su producto y su cantidad desde julio. Contar lo vendido es una
-- consulta agrupada por sede, no una integración.
--
-- UNA META PUEDE LLEVAR VARIOS PRODUCTOS. "100 aguas Bosqua" son el con
-- gas y el sin gas sumados: por eso los productos van en una tabla
-- aparte y no en una columna.
--
-- QUÉ PRODUCTOS SE ELIGEN: los de FUDO, no los del inventario. La meta es
-- de VENTA, y lo que se vende son los productos de la carta.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LAS DOS TABLAS
-- ================================================================
create table if not exists public.metas (
  id          bigserial primary key,
  titulo      text        not null,
  objetivo    numeric     not null check (objetivo > 0),
  premio      text,
  desde       date        not null,
  hasta       date        not null,
  creada_por  text,
  created_at  timestamptz not null default now(),
  cerrada_at  timestamptz,
  constraint metas_fechas_ok check (hasta >= desde)
);

create table if not exists public.meta_productos (
  meta_id         bigint not null references public.metas(id) on delete cascade,
  fudo_product_id text   not null,
  nombre          text,
  primary key (meta_id, fudo_product_id)
);

alter table public.metas          enable row level security;
alter table public.meta_productos enable row level security;
drop policy if exists "metas all"          on public.metas;
drop policy if exists "meta_productos all" on public.meta_productos;
create policy "metas all"          on public.metas          for all to anon, authenticated using (true) with check (true);
create policy "meta_productos all" on public.meta_productos for all to anon, authenticated using (true) with check (true);
grant all on public.metas          to anon, authenticated;
grant all on public.meta_productos to anon, authenticated;
grant usage, select on sequence public.metas_id_seq to anon, authenticated;

-- En vivo: la barra tiene que moverse sola en el teléfono de la otra sede
-- cuando acá se vende. Si no, la competencia no se siente.
do $$
begin
  if not exists (select 1 from pg_publication_tables
                  where pubname='supabase_realtime' and schemaname='public' and tablename='metas') then
    execute 'alter publication supabase_realtime add table public.metas';
  end if;
end $$;


-- ================================================================
-- BLOQUE 2 — CÓMO VA CADA SEDE  (correr en otro Run)
--
-- Devuelve una fila por sede con lo vendido de esa meta. Sale de
-- `fudo_movimientos`, que guarda cada ítem vendido desde julio.
--
-- Va sin comillas de dólar (§3.5): el cuerpo es una sola consulta entre
-- comillas simples.
--
-- ⚠️ Se cuenta `cantidad_vendida`, no los descuentos: una meta es cuántas
-- unidades se vendieron, y eso no depende de que el producto tenga receta.
-- Así una meta funciona aunque falte enlazar el inventario.
-- ================================================================
create or replace function public.meta_avance(p_meta bigint)
returns table (sede text, vendido numeric)
language sql
stable
as 'select m.sede, coalesce(sum(m.cantidad_vendida), 0)::numeric
      from public.fudo_movimientos m
      join public.meta_productos mp on mp.fudo_product_id = m.fudo_product_id
      join public.metas t on t.id = mp.meta_id
     where mp.meta_id = p_meta
       and m.created_at >= t.desde::timestamptz
       and m.created_at <  (t.hasta + 1)::timestamptz
     group by m.sede';

grant execute on function public.meta_avance(bigint) to anon, authenticated;

select 'tablas de metas' as pieza,
       case when to_regclass('public.metas') is not null
             and to_regclass('public.meta_productos') is not null then 'SÍ' else 'NO' end as quedo
union all
select 'meta_avance, y una sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='meta_avance') = 1
            then 'SÍ' else 'NO' end;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-metas-de-venta.sql', 'Jhon', 'lo corrió Jhon',
        'Metas de venta con varios productos, fechas y premio. El avance sale de fudo_movimientos, sin pedirle nada a Fudo')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
