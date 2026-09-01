-- ================================================================
--  LLAMITA LAMA · EL CIERRE DE MESA
--
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque. Copiar TODO, pegar, apretar Run.
--  TARDA:     instantáneo
--  SEGURO DE RE-CORRER: sí. Todo es `if not exists` / `on conflict`.
--
--  QUÉ HACE:  guarda CÓMO se pagó una mesa, que es lo que hoy se pierde.
--             Hoy `cuenta_cerrar` guarda un total y nada más; después de esto
--             queda registrado el medio de pago, la propina y el descuento,
--             que es de lo que se va a alimentar el arqueo de caja.
--
--  ⚠️ NO TOCA EL INVENTARIO. Cerrar una mesa sigue sin descontar un solo
--     producto de Llamita Stock. Esa conexión va al final (§0.9), con
--     interruptor, y no es esta.
--
--  ⚠️ NO TOCA `cuenta_cerrar`. La función vieja queda exactamente como está.
--     La nueva se llama `cuenta_cobrar` y es otra función, con otro nombre.
--     Es a propósito: cambiarle los parámetros a `cuenta_cerrar` con un
--     `create or replace` NO la reemplaza, agrega una segunda firma, y la
--     llamada desde la app se vuelve ambigua. Es la falla de las 15 horas
--     (§0.5). Un nombre nuevo no tiene ese problema, y además deja la vuelta
--     atrás gratis: si algo sale mal, la app vuelve a la función vieja.
-- ================================================================


-- ----------------------------------------------------------------
-- 1) LOS MEDIOS DE PAGO
--
-- Es tabla y no una lista escrita en el código para que Adriana pueda cambiar
-- un descuento sin que nadie toque la app.
--
-- `es_cobro = false` son los cinco consumos: NO son formas de cobrar, son
-- formas de registrar que algo salió sin cobrarse. Igual cierran como venta y
-- entran al arqueo — si no, la caja cuadra pero el inventario no.
--
-- `descuento_pct` nace en 0 en todos. Los valores reales los dicta Jhon, y se
-- cambian con un UPDATE de una línea.
-- ----------------------------------------------------------------
create table if not exists public.lama_medios_pago (
  codigo        text primary key,
  nombre        text    not null,
  orden         int     not null default 0,
  es_cobro      boolean not null default true,
  descuento_pct numeric not null default 0,
  activo        boolean not null default true
);

insert into public.lama_medios_pago (codigo, nombre, orden, es_cobro) values
  ('efectivo',   'Efectivo',                1,  true),
  ('debito',     'Tarjeta de débito',       2,  true),
  ('credito',    'Tarjeta de crédito',      3,  true),
  ('transfer',   'Transferencia',           4,  true),
  ('voucher',    'Voucher',                 5,  true),
  ('pedidosya',  'Pedidos Ya',              6,  true),
  ('fidelidad',  'Tarjeta de fidelización', 7,  true),
  ('admin',      'Consumo administrativo',  8,  false),
  ('garzones',   'Consumo garzones',        9,  false),
  ('eventos',    'Consumo eventos',        10,  false),
  ('redes',      'Consumo redes',          11,  false),
  ('cumple',     'Cumpleaños',             12,  false)
on conflict (codigo) do nothing;


-- ----------------------------------------------------------------
-- 2) LOS MOTIVOS DE DESCUENTO
-- Mismo criterio: hoy son estos, mañana Adriana agrega el que necesite.
-- ----------------------------------------------------------------
create table if not exists public.lama_motivos_descuento (
  codigo text primary key,
  nombre text not null,
  orden  int  not null default 0,
  activo boolean not null default true
);

insert into public.lama_motivos_descuento (codigo, nombre, orden) values
  ('empleado',  'Descuento de empleado', 1),
  ('cumple',    'Cumpleaños',            2),
  ('especial',  'Cliente especial',      3),
  ('cortesia',  'Cortesía',              4),
  ('otro',      'Otro',                  9)
on conflict (codigo) do nothing;


-- ----------------------------------------------------------------
-- 3) LAS DOS TABLAS HIJAS
--
-- Son tablas y no columnas porque una cuenta se puede pagar con VARIAS líneas
-- de cada cosa: mitad en efectivo y mitad en débito, o la propina en efectivo
-- con la cuenta en tarjeta. Eso no cabe en una columna.
-- ----------------------------------------------------------------
create table if not exists public.cuenta_pagos (
  id         bigserial primary key,
  cuenta_id  bigint  not null references public.cuentas(id) on delete cascade,
  medio      text    not null references public.lama_medios_pago(codigo),
  monto      numeric not null default 0,
  creado_por text,
  created_at timestamptz not null default now()
);
create index if not exists cuenta_pagos_cuenta_idx on public.cuenta_pagos(cuenta_id);

create table if not exists public.cuenta_propinas (
  id         bigserial primary key,
  cuenta_id  bigint  not null references public.cuentas(id) on delete cascade,
  medio      text    not null references public.lama_medios_pago(codigo),
  monto      numeric not null default 0,
  creado_por text,
  created_at timestamptz not null default now()
);
create index if not exists cuenta_propinas_cuenta_idx on public.cuenta_propinas(cuenta_id);


-- ----------------------------------------------------------------
-- 4) LO QUE SE CONGELA EN `cuentas` AL CERRAR
--
-- Se guardan aunque se puedan recalcular, y a propósito: el arqueo de dentro
-- de seis meses no tiene por qué volver a sumar seis meses de líneas para
-- saber cuánto se cobró un martes. Y si mañana cambia un precio, la venta de
-- ayer tiene que seguir diciendo lo que dijo ayer.
-- ----------------------------------------------------------------
alter table public.cuentas add column if not exists subtotal          numeric not null default 0;
alter table public.cuentas add column if not exists descuento         numeric not null default 0;
alter table public.cuentas add column if not exists descuento_motivo  text;
alter table public.cuentas add column if not exists descuento_formato text;   -- 'pct' | 'fijo'
alter table public.cuentas add column if not exists descuento_valor   numeric;
alter table public.cuentas add column if not exists propina           numeric not null default 0;
alter table public.cuentas add column if not exists pagado            numeric not null default 0;
alter table public.cuentas add column if not exists vuelto            numeric not null default 0;


-- ----------------------------------------------------------------
-- 5) COBRAR
--
-- LAS CUENTAS LAS HACE ESTA FUNCIÓN, no la pantalla. La pantalla muestra el
-- mismo cálculo para que se sienta instantáneo, pero quien decide es la base:
-- si no, un teléfono con un precio viejo en memoria cierra una venta por el
-- monto equivocado y nadie se entera.
--
--   subtotal  = Σ (cantidad × precio)          ← se relee de cuenta_items
--   descuento = pct sobre el subtotal, o fijo
--   propina   = Σ líneas de propina
--   total     = subtotal − descuento + propina
--   pagado    = Σ líneas de pago
--   vuelto    = pagado − total                 ← NUNCA negativo
--
-- LA REGLA DURA: si pagado < total, NO SE CIERRA. Falta plata, y una mesa que
-- se cierra con menos de lo que vale es un descuadre que aparece al final del
-- turno sin que nadie sepa de dónde salió.
-- ----------------------------------------------------------------
create or replace function public.cuenta_cobrar(
  p_cuenta_id bigint,
  p_quien     text    default null,
  p_desc_motivo  text    default null,
  p_desc_formato text    default null,   -- 'pct' | 'fijo' | null
  p_desc_valor   numeric default null,
  p_propinas  jsonb   default '[]'::jsonb,   -- [{"medio":"efectivo","monto":1000}]
  p_pagos     jsonb   default '[]'::jsonb    -- [{"medio":"debito","monto":11000}]
) returns public.cuentas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cuenta    public.cuentas;
  v_subtotal  numeric := 0;
  v_descuento numeric := 0;
  v_propina   numeric := 0;
  v_total     numeric := 0;
  v_pagado    numeric := 0;
begin
  select * into v_cuenta from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  -- Idempotente: cobrar dos veces devuelve la fila, no falla. Dos toques
  -- seguidos en un teléfono lento es algo que pasa.
  if v_cuenta.estado = 'cerrada' then
    return v_cuenta;
  end if;

  -- 1. el subtotal SIEMPRE se relee de la base
  select coalesce(sum(cantidad * precio), 0) into v_subtotal
    from public.cuenta_items where cuenta_id = p_cuenta_id;

  -- 2. el descuento
  if p_desc_formato = 'pct' then
    v_descuento := round(v_subtotal * coalesce(p_desc_valor, 0) / 100);
  elsif p_desc_formato = 'fijo' then
    v_descuento := coalesce(p_desc_valor, 0);
  end if;
  if v_descuento < 0 then v_descuento := 0; end if;
  -- Un descuento no puede dejar la cuenta en negativo: sería una venta que
  -- devuelve plata.
  if v_descuento > v_subtotal then v_descuento := v_subtotal; end if;

  -- 3. la propina
  select coalesce(sum((x->>'monto')::numeric), 0) into v_propina
    from jsonb_array_elements(coalesce(p_propinas, '[]'::jsonb)) x;
  if v_propina < 0 then v_propina := 0; end if;

  v_total := v_subtotal - v_descuento + v_propina;

  -- 4. lo pagado
  select coalesce(sum((x->>'monto')::numeric), 0) into v_pagado
    from jsonb_array_elements(coalesce(p_pagos, '[]'::jsonb)) x;

  -- 5. LA REGLA DURA
  if v_pagado < v_total then
    raise exception 'Falta plata: se pagaron % de un total de %.',
      v_pagado, v_total;
  end if;

  -- 6. se guardan las líneas. Se borran las de un intento anterior para que
  --    re-cobrar no duplique.
  delete from public.cuenta_pagos    where cuenta_id = p_cuenta_id;
  delete from public.cuenta_propinas where cuenta_id = p_cuenta_id;

  insert into public.cuenta_propinas (cuenta_id, medio, monto, creado_por)
  select p_cuenta_id, x->>'medio', (x->>'monto')::numeric, p_quien
    from jsonb_array_elements(coalesce(p_propinas, '[]'::jsonb)) x
   where (x->>'monto')::numeric <> 0;

  insert into public.cuenta_pagos (cuenta_id, medio, monto, creado_por)
  select p_cuenta_id, x->>'medio', (x->>'monto')::numeric, p_quien
    from jsonb_array_elements(coalesce(p_pagos, '[]'::jsonb)) x
   where (x->>'monto')::numeric <> 0;

  -- 7. la foto, congelada
  update public.cuentas
     set estado            = 'cerrada',
         subtotal          = v_subtotal,
         descuento         = v_descuento,
         descuento_motivo  = p_desc_motivo,
         descuento_formato = p_desc_formato,
         descuento_valor   = p_desc_valor,
         propina           = v_propina,
         total             = v_total,
         pagado            = v_pagado,
         vuelto            = v_pagado - v_total,
         cerrada_por       = p_quien,
         cerrada_at        = now()
   where id = p_cuenta_id
   returning * into v_cuenta;

  return v_cuenta;
end;
$$;


-- ----------------------------------------------------------------
-- 6) PERMISOS Y POLÍTICAS
-- Mismo criterio que el resto de Lama: la pantalla está escondida detrás de
-- `app_permisos.puede_lama`, que nace apagada para todos.
-- ----------------------------------------------------------------
alter table public.lama_medios_pago       enable row level security;
alter table public.lama_motivos_descuento enable row level security;
alter table public.cuenta_pagos           enable row level security;
alter table public.cuenta_propinas        enable row level security;

drop policy if exists "medios all" on public.lama_medios_pago;
create policy "medios all" on public.lama_medios_pago
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "motivos all" on public.lama_motivos_descuento;
create policy "motivos all" on public.lama_motivos_descuento
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "pagos all" on public.cuenta_pagos;
create policy "pagos all" on public.cuenta_pagos
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "propinas all" on public.cuenta_propinas;
create policy "propinas all" on public.cuenta_propinas
  for all to anon, authenticated using (true) with check (true);

grant all on public.lama_medios_pago       to anon, authenticated;
grant all on public.lama_motivos_descuento to anon, authenticated;
grant all on public.cuenta_pagos           to anon, authenticated;
grant all on public.cuenta_propinas        to anon, authenticated;
grant usage, select on sequence public.cuenta_pagos_id_seq    to anon, authenticated;
grant usage, select on sequence public.cuenta_propinas_id_seq to anon, authenticated;

grant execute on function public.cuenta_cobrar(bigint,text,text,text,numeric,jsonb,jsonb)
  to anon, authenticated;


-- ----------------------------------------------------------------
-- 7) QUEDA ANOTADO EN EL CUADERNO
-- ----------------------------------------------------------------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-lama-cierre.sql', 'Jhon', 'lo corrió a mano en el SQL Editor',
        'Cierre de mesa: medios de pago, motivos de descuento, cuenta_pagos, cuenta_propinas y cuenta_cobrar. No toca el inventario.')
on conflict (archivo) do nothing;


-- ----------------------------------------------------------------
-- 8) PARA COMPROBAR QUE QUEDÓ BIEN
-- Correr esto después. Tiene que devolver una fila que diga "todo listo".
-- ----------------------------------------------------------------
select
  (select count(*) from public.lama_medios_pago)                        as medios_de_pago,
  (select count(*) from public.lama_motivos_descuento)                  as motivos_descuento,
  (select count(*) from information_schema.columns
     where table_name = 'cuentas' and column_name = 'propina')          as columna_propina,
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.proname = 'cuenta_cobrar')         as funciones_cobrar,
  case when (select count(*) from public.lama_medios_pago) = 12
        and (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname = 'cuenta_cobrar') = 1
       then 'todo listo'
       else 'REVISAR: algo no quedó'
  end as veredicto;
