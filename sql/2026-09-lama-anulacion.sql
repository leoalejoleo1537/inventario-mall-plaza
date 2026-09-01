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
  ('error_registro',  'Error de registro',    1, false),
  ('no_disponible',   'Producto no disponible',2, false),
  ('cambio',          'Cambio de producto',   3, false),
  ('cliente',         'Cancelado por cliente',4, false),
  ('prueba',          'Prueba',               5, false),
  ('otro',            'Otro',                 9, true)
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
