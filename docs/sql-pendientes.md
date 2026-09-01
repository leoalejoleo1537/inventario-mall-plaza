# SQL pendientes de pegar en Supabase

> **Para qué existe.** El SQL llegaba en mensajes de chat, y entre varios se
> te confundía cuál ya habías corrido y cuál no. Este es **el único lugar**
> donde se sabe qué falta — y **el SQL completo está acá mismo**, no en otro
> archivo al que haya que saltar. Tocas "▶ Ver el SQL completo", lo copias
> entero, lo pegas en Supabase.
>
> **Link fijo para guardar** (este, no el de una rama de trabajo — esa puede
> cambiar de nombre; `master` no):
> `https://github.com/leoalejoleo1537/inventario-mall-plaza/blob/master/docs/sql-pendientes.md`
>
> **Las dos sesiones (Stock y Lama) agregan acá** apenas dejan un `.sql`
> nuevo listo para correr, **con el texto completo pegado**, no solo el
> nombre del archivo. Vos marcás `[x]` y la fecha cuando lo pegás.
>
> **El orden de la lista importa.** Si dos items dependen uno del otro, van
> en el orden en que hay que correrlos, y se dice por qué.

---

## Pendientes ahora

### 1 · `sql/2026-08-lama-cierre.sql` — el cierre de mesa

- [ ] **Corrido:** ______ (fecha)

Guarda medio de pago, propina y descuento al cerrar una mesa. **Va primero
de los tres.** No toca el inventario.

<details>
<summary>▶ Ver el SQL completo (tócalo para abrir)</summary>

```sql
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
```

**Qué ver:** una fila que diga **`todo listo`**, con 12 medios de pago.

</details>

---

### 2 · `sql/2026-09-lama-anulacion.sql` — anular un producto ya comandado

- [ ] **Corrido:** ______ (fecha)

**Depende del anterior** — reemplaza una función que el de cierre crea. Va
después, no antes.

<details>
<summary>▶ Ver el SQL completo (tócalo para abrir)</summary>

```sql
-- ================================================================
--  LLAMITA LAMA · ANULAR UN PRODUCTO QUE YA SALIÓ A LA COCINA
--
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque. Copiar TODO, pegar, apretar Run.
--  TARDA:     instantáneo
--  SEGURO DE RE-CORRER: sí.
--
--  QUÉ HACE:  hasta hoy, quitar un producto ya comandado lo BORRABA. Después
--             de esto queda, tachado, con el motivo de por qué no salió.
--
--  POR QUÉ, y es de negocio y no de pantalla: lo que salió de la cocina
--  existió. Costó insumos y alguien lo preparó. Si desaparece de la lista,
--  el arqueo pierde el rastro y nadie puede responder por qué el inventario
--  no cuadra al final del turno.
--
--  ⚠️ NO TOCA EL INVENTARIO. Anular no descuenta ni devuelve stock. Esa
--     conexión va al final (§0.9), con interruptor, y no es esta.
--
--  ⚠️ SOBRE §0.5: `cuenta_recalcular` y `cuenta_cobrar` se reemplazan con
--     EXACTAMENTE los mismos parámetros que ya tienen. Un `create or replace`
--     solo agrega una segunda firma cuando la lista de parámetros CAMBIA; con
--     la misma lista reemplaza de verdad. Al final hay una comprobación que
--     cuenta las firmas: si alguna dijera 2, hay que parar.
-- ================================================================


-- ----------------------------------------------------------------
-- 1) LOS MOTIVOS
-- Tabla y no lista escrita en el código: Adriana tiene que poder agregar el
-- motivo que le falte sin que nadie toque la app.
-- ----------------------------------------------------------------
create table if not exists public.lama_motivos_anulacion (
  codigo text primary key,
  nombre text not null,
  orden  int  not null default 0,
  -- "Otro" no dice nada por sí solo: si es ese, el comentario es obligatorio.
  pide_comentario boolean not null default false,
  activo boolean not null default true
);

insert into public.lama_motivos_anulacion (codigo, nombre, orden, pide_comentario) values
  ('error_registro',  'Error de registro',     1, false),
  ('no_disponible',   'Producto no disponible',2, false),
  ('cambio',          'Cambio de producto',    3, false),
  ('cliente',         'Cancelado por cliente', 4, false),
  ('prueba',          'Prueba',                5, false),
  ('otro',            'Otro',                  9, true)
on conflict (codigo) do nothing;


-- ----------------------------------------------------------------
-- 2) LAS MARCAS EN LA LÍNEA
-- No se borra la fila: se le pone encima quién, cuándo y por qué.
-- ----------------------------------------------------------------
alter table public.cuenta_items add column if not exists anulado_at         timestamptz;
alter table public.cuenta_items add column if not exists anulado_por        text;
alter table public.cuenta_items add column if not exists anulado_motivo     text;
alter table public.cuenta_items add column if not exists anulado_comentario text;

-- Para que el arqueo pueda listar lo anulado de un día sin recorrer todo.
create index if not exists cuenta_items_anulado_idx
  on public.cuenta_items(anulado_at) where anulado_at is not null;


-- ----------------------------------------------------------------
-- 3) ANULAR
--
-- Solo se anula lo que YA SALIÓ a la cocina. Lo que todavía no salió no se
-- anula: se borra y ya está, porque no llegó a existir para nadie más que
-- para quien lo tecleó. Pedir un motivo ahí sería trámite sin dato.
-- ----------------------------------------------------------------
create or replace function public.item_anular(
  p_item_id    bigint,
  p_motivo     text,
  p_comentario text default null,
  p_quien      text default null
) returns public.cuenta_items
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item public.cuenta_items;
  v_pide boolean;
begin
  select * into v_item from public.cuenta_items where id = p_item_id for update;
  if not found then
    raise exception 'Ese producto ya no existe en la cuenta.';
  end if;

  -- Idempotente: anular dos veces devuelve la fila, no falla.
  if v_item.anulado_at is not null then
    return v_item;
  end if;

  if v_item.estado <> 'confirmado' then
    raise exception 'Ese producto todavía no salió a la cocina: se quita, no se anula.';
  end if;

  select pide_comentario into v_pide
    from public.lama_motivos_anulacion where codigo = p_motivo and activo;
  if not found then
    raise exception 'Ese motivo de anulación no existe o está apagado.';
  end if;
  if v_pide and coalesce(btrim(p_comentario), '') = '' then
    raise exception 'Ese motivo necesita que se escriba el detalle.';
  end if;

  update public.cuenta_items
     set anulado_at         = now(),
         anulado_por        = p_quien,
         anulado_motivo     = p_motivo,
         anulado_comentario = nullif(btrim(p_comentario), '')
   where id = p_item_id
   returning * into v_item;

  -- El total baja: lo anulado deja de cobrarse.
  perform public.cuenta_recalcular(v_item.cuenta_id);
  return v_item;
end;
$$;


-- ----------------------------------------------------------------
-- 4) LO ANULADO DEJA DE SUMAR — en los DOS lugares donde se cuenta plata
--
-- Si se arregla en uno solo, la pantalla muestra un total y el cobro guarda
-- otro. Es exactamente la clase de descuadre que aparece al final del turno
-- sin que nadie sepa de dónde salió.
--
-- MISMOS PARÁMETROS que las versiones que ya están: esto reemplaza, no
-- agrega una firma nueva (§0.5).
-- ----------------------------------------------------------------
create or replace function public.cuenta_recalcular(p_cuenta_id bigint)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total numeric;
begin
  select coalesce(sum(cantidad * precio), 0) into v_total
    from public.cuenta_items
   where cuenta_id = p_cuenta_id
     and anulado_at is null;          -- ← lo único que cambió
  update public.cuentas set total = v_total where id = p_cuenta_id;
  return v_total;
end;
$$;


create or replace function public.cuenta_cobrar(
  p_cuenta_id bigint,
  p_quien     text    default null,
  p_desc_motivo  text    default null,
  p_desc_formato text    default null,
  p_desc_valor   numeric default null,
  p_propinas  jsonb   default '[]'::jsonb,
  p_pagos     jsonb   default '[]'::jsonb
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
  if v_cuenta.estado = 'cerrada' then
    return v_cuenta;
  end if;

  -- 1. el subtotal SIEMPRE se relee de la base, y SIN lo anulado
  select coalesce(sum(cantidad * precio), 0) into v_subtotal
    from public.cuenta_items
   where cuenta_id = p_cuenta_id
     and anulado_at is null;          -- ← lo único que cambió

  -- 2. el descuento
  if p_desc_formato = 'pct' then
    v_descuento := round(v_subtotal * coalesce(p_desc_valor, 0) / 100);
  elsif p_desc_formato = 'fijo' then
    v_descuento := coalesce(p_desc_valor, 0);
  end if;
  if v_descuento < 0 then v_descuento := 0; end if;
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
    raise exception 'Falta plata: se pagaron % de un total de %.', v_pagado, v_total;
  end if;

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
-- 5) PERMISOS
-- ----------------------------------------------------------------
alter table public.lama_motivos_anulacion enable row level security;
drop policy if exists "motivos anulacion all" on public.lama_motivos_anulacion;
create policy "motivos anulacion all" on public.lama_motivos_anulacion
  for all to anon, authenticated using (true) with check (true);
grant all on public.lama_motivos_anulacion to anon, authenticated;

grant execute on function public.item_anular(bigint,text,text,text) to anon, authenticated;
grant execute on function public.cuenta_recalcular(bigint)          to anon, authenticated;
grant execute on function public.cuenta_cobrar(bigint,text,text,text,numeric,jsonb,jsonb)
  to anon, authenticated;


-- ----------------------------------------------------------------
-- 6) EL CUADERNO
-- ----------------------------------------------------------------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-09-lama-anulacion.sql', 'Jhon', 'lo corrió a mano en el SQL Editor',
        'Anular un producto ya comandado: queda tachado con su motivo, y deja de sumar. No toca el inventario.')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;


-- ----------------------------------------------------------------
-- 7) PARA COMPROBAR QUE QUEDÓ BIEN
--
-- Las dos funciones reemplazadas tienen que decir "1 firma". Si alguna dice
-- 2, hay dos versiones conviviendo y la llamada desde la app se vuelve
-- ambigua: es la falla que dejó el sistema 15 horas sin descontar (§0.5).
-- ----------------------------------------------------------------
select 'cuenta_recalcular' as funcion,
       count(*) || ' firma' || case when count(*) = 1 then '' else 's ← PARAR' end as estado
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'cuenta_recalcular'
union all
select 'cuenta_cobrar',
       count(*) || ' firma' || case when count(*) = 1 then '' else 's ← PARAR' end
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'cuenta_cobrar'
union all
select 'item_anular',
       count(*) || ' firma' || case when count(*) = 1 then '' else 's ← PARAR' end
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'item_anular'
union all
select 'motivos de anulación', count(*) || ' motivos'
  from public.lama_motivos_anulacion;
```

**Qué ver:** cuatro filas. Las tres funciones tienen que decir **`1 firma`**.
Si alguna dice `2 firmas ← PARAR`, no sigas y avisá acá.

</details>

---

### 3 · `sql/2026-08-metas-cuentan-por-sede.sql` — arregla el conteo de las metas por sede

- [ ] **Corrido:** ______ (fecha)

**Independiente de los dos de arriba** — se puede correr cuando quieras. Es
el error del agua Bosqua/Angamos: una meta contaba otro producto porque el
mismo id de Fudo significa cosas distintas en cada sede.

<details>
<summary>▶ Ver el SQL completo (tócalo para abrir) — son 4 bloques, uno por Run</summary>

**Bloque 1 — ver el error (no escribe):**

```sql
select mp.meta_id,
       mp.nombre as nombre_en_la_meta,
       mp.fudo_product_id as id,
       f.sede,
       f.nombre as nombre_en_fudo,
       case when lower(btrim(f.nombre)) = lower(btrim(mp.nombre))
            then 'calza' else 'ES OTRO PRODUCTO' end as veredicto
  from public.meta_productos mp
  left join public.fudo_productos f on f.fudo_product_id = mp.fudo_product_id
 order by mp.meta_id, mp.nombre, f.sede;
```

**Bloque 2 — la columna `sede` (escribe, pero no borra nada):**

```sql
alter table public.meta_productos add column if not exists sede text;

update public.meta_productos mp
   set sede = f.sede
  from public.fudo_productos f
 where mp.sede is null
   and f.fudo_product_id = mp.fudo_product_id
   and lower(btrim(f.nombre)) = lower(btrim(mp.nombre));

alter table public.meta_productos drop constraint if exists meta_productos_pkey;
create unique index if not exists meta_productos_uni
  on public.meta_productos (meta_id, sede, fudo_product_id);

select meta_id, nombre, fudo_product_id as id, coalesce(sede,'(sin sede)') as sede
  from public.meta_productos
 order by meta_id, nombre, sede;
```

**Bloque 3 — qué falta agregar (no escribe):**

```sql
select mp.meta_id,
       mp.nombre as producto,
       f.sede as sede_que_falta,
       f.fudo_product_id as id_en_esa_sede,
       f.nombre as nombre_en_fudo
  from public.meta_productos mp
  join public.fudo_productos f
    on lower(btrim(f.nombre)) = lower(btrim(mp.nombre))
   and f.sede <> mp.sede
 where mp.sede is not null
   and not exists (select 1 from public.meta_productos x
                    where x.meta_id = mp.meta_id and x.sede = f.sede
                      and x.fudo_product_id = f.fudo_product_id);
```

**Bloque 4 — agregarlo y arreglar el conteo (escribe):**

```sql
insert into public.meta_productos (meta_id, sede, fudo_product_id, nombre)
select distinct mp.meta_id, f.sede, f.fudo_product_id, mp.nombre
  from public.meta_productos mp
  join public.fudo_productos f
    on lower(btrim(f.nombre)) = lower(btrim(mp.nombre))
   and f.sede <> mp.sede
 where mp.sede is not null
   and not exists (select 1 from public.meta_productos x
                    where x.meta_id = mp.meta_id and x.sede = f.sede
                      and x.fudo_product_id = f.fudo_product_id);

drop function if exists public.meta_avance(bigint);

create function public.meta_avance(p_meta bigint)
returns table (sede text, vendido numeric)
language sql
stable
as 'select l.sede, coalesce(sum(l.cantidad_vendida), 0)::numeric
      from (select distinct on (m.sede, m.fudo_item_id)
                   m.sede, m.fudo_item_id, m.cantidad_vendida, m.created_at
              from public.fudo_movimientos m
             where exists (select 1 from public.meta_productos mp
                            where mp.meta_id = p_meta
                              and mp.sede = m.sede
                              and mp.fudo_product_id = m.fudo_product_id)
             order by m.sede, m.fudo_item_id, m.id) l
      join public.metas t on t.id = p_meta
     where l.created_at >= t.desde::timestamptz
       and l.created_at <  (t.hasta + 1)::timestamptz
     group by l.sede';

grant execute on function public.meta_avance(bigint) to anon, authenticated;

select t.id as meta, t.titulo, a.sede, a.vendido
  from public.metas t
  cross join lateral public.meta_avance(t.id) a
 order by t.id, a.sede;
```

**Y este, para el cuaderno:**

```sql
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-metas-cuentan-por-sede.sql', 'Jhon', 'lo corrió Jhon',
        'meta_productos gana columna sede y meta_avance une por (id, sede). Antes contaba otro producto en la segunda sede porque los ids de Fudo se repiten entre cuentas')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
```

**Qué ver, al final:** el avance real de cada meta por sede. El agua de
Angamos tiene que dar del orden de 116, no 2.

</details>

---

## Cómo se marca uno como hecho

Marcás el `[ ]` por `[x]` y completás la fecha, o le decís a cualquiera de
las dos sesiones "ya corrí tal archivo" y ella lo hace por vos.

## Historial (lo que ya se corrió y se sacó de la lista de arriba)

_(vacío por ahora — acá van quedando, para que la lista de pendientes no
crezca para siempre)_
