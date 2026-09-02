-- ================================================================
--  LLAMITA LAMA · PAGO PARCIAL POR PRODUCTO  (A1)
--
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 BLOQUES, uno por uno, en orden. Están marcados abajo.
--             Van separados porque el editor de Supabase se atraganta con un
--             script largo lleno de funciones (§3.5), no porque dependan de
--             algo raro.
--  TARDA:     instantáneo cada uno
--  SEGURO DE RE-CORRER: sí. Todo es `if not exists` / `create or replace`.
--
--  QUÉ HACE:  deja cobrar UNA PARTE de la mesa. Cuatro personas, una se va
--             antes: se eligen SUS productos, se cobran, y la mesa sigue
--             abierta con lo que falta.
--
--  QUÉ VER:   el bloque 3 termina con una consulta que cuenta firmas. Las
--             cinco funciones tienen que decir "1 firma". Si alguna dice 2,
--             PARAR y avisar: hay dos versiones conviviendo y la llamada desde
--             la app se vuelve ambigua. Es la falla que dejó el sistema 15
--             horas sin descontar (§0.5).
--
--  ⚠️ NO TOCA EL INVENTARIO. Cobrar no descuenta un solo producto de Llamita
--     Stock. Esa conexión va al final (§0.9), con interruptor, y no es esta.
--
--  ⚠️ DOS DECISIONES QUE TOMÉ POR VOS, Y SE PUEDEN VETAR ANTES DE CORRER ESTO:
--
--     1. EL DESCUENTO SE REPARTE PROPORCIONALMENTE. Con un 20 % puesto y
--        alguien que paga 2 de 5 productos, esos 2 se cobran con su 20 %
--        descontado. Si se aplicara recién al final, los tres primeros
--        pagarían precio lleno y el último se llevaría el descuento entero.
--
--     2. LA PROPINA VA SOLO EN EL CIERRE FINAL, no en los pagos parciales.
--        Es lo que hace Fudo —la propina es de la venta, no del pago— y
--        evita que cada abono tenga su propio vuelto. Se puede agregar
--        después sin rehacer nada de esto.
--
--  ⚠️ SOBRE §0.5: `cuenta_cobrar`, `item_anular` e `items_mover` se reemplazan
--     con EXACTAMENTE los mismos parámetros que ya tienen. Un `create or
--     replace` solo agrega una segunda firma cuando la lista de parámetros
--     CAMBIA; con la misma lista reemplaza de verdad.
-- ================================================================



-- ################################################################
-- ##  BLOQUE 1 de 3  —  las columnas y la tabla nueva
-- ##  Copiar de acá hasta donde dice FIN DEL BLOQUE 1.
-- ################################################################

-- ----------------------------------------------------------------
-- 1.1) CUÁNTAS UNIDADES DE ESTA LÍNEA YA SE COBRARON
--
-- Es una CANTIDAD y no un sí/no, porque se cobran 2 de 3 cafés. Y la línea
-- NO se parte en dos: partirla sería editar algo que ya salió a la cocina,
-- que es justo lo que no se hace (el bloque C7+C9+C10 de docs/LAMA.md).
-- ----------------------------------------------------------------
alter table public.cuenta_items
  add column if not exists cantidad_pagada numeric not null default 0;

-- EL CANDADO, y es de los que protegen datos (§0.8), no una forma de trabajar:
-- cobrar dos veces la misma unidad corrompe el arqueo. Puesto en la TABLA para
-- que no dependa de que la app se acuerde — igual que el tope en cero (§0.2).
-- Por eso este no lleva interruptor, y es la excepción de §2.2.
do $b1$
begin
  if not exists (select 1 from pg_constraint where conname = 'cuenta_items_pagada_ok') then
    alter table public.cuenta_items
      add constraint cuenta_items_pagada_ok
      check (cantidad_pagada >= 0 and cantidad_pagada <= cantidad);
  end if;
end
$b1$;


-- ----------------------------------------------------------------
-- 1.2) DISTINGUIR EL PAGO PARCIAL DEL PAGO DEL CIERRE
--
-- ⚠️ ESTA COLUMNA ES LA PIEZA MÁS IMPORTANTE DEL ARCHIVO, y conviene decir
-- por qué. `cuenta_cobrar` hace hoy:
--
--     delete from cuenta_pagos where cuenta_id = ...
--
-- antes de insertar los pagos del cierre. Sin esta columna, cerrar la mesa
-- BORRARÍA los pagos parciales: plata cobrada de verdad, desaparecida del
-- arqueo, sin que nadie se entere. Con ella, el cierre borra solo los suyos.
-- ----------------------------------------------------------------
alter table public.cuenta_pagos
  add column if not exists parcial boolean not null default false;


-- ----------------------------------------------------------------
-- 1.3) QUÉ PRODUCTOS CUBRIÓ CADA PAGO
--
-- `cantidad_pagada` dice CUÁNTAS unidades se pagaron, pero no en qué pago ni
-- con qué medio. Sin esta tabla, "qué se vendió en efectivo" queda sin
-- respuesta — y esa pregunta es la razón entera de cobrar por producto en vez
-- de por monto.
--
-- El precio se congela: si mañana cambia, lo cobrado ayer tiene que seguir
-- diciendo lo que dijo ayer.
-- ----------------------------------------------------------------
create table if not exists public.cuenta_pago_items (
  id       bigserial primary key,
  pago_id  bigint  not null references public.cuenta_pagos(id) on delete cascade,
  item_id  bigint  not null references public.cuenta_items(id) on delete cascade,
  cantidad numeric not null,
  precio   numeric not null
);
create index if not exists cuenta_pago_items_pago_idx on public.cuenta_pago_items(pago_id);
create index if not exists cuenta_pago_items_item_idx on public.cuenta_pago_items(item_id);

alter table public.cuenta_pago_items enable row level security;
drop policy if exists "pago items all" on public.cuenta_pago_items;
create policy "pago items all" on public.cuenta_pago_items
  for all to anon, authenticated using (true) with check (true);
grant all on public.cuenta_pago_items to anon, authenticated;
grant usage, select on sequence public.cuenta_pago_items_id_seq to anon, authenticated;

-- ##  FIN DEL BLOQUE 1  ##########################################



-- ################################################################
-- ##  BLOQUE 2 de 3  —  cobrar una parte, y poder deshacerlo
-- ##  Copiar de acá hasta donde dice FIN DEL BLOQUE 2.
-- ################################################################

-- ----------------------------------------------------------------
-- 2.1) COBRAR UNA PARTE
--
-- Recibe los productos elegidos y CUÁNTOS de cada uno:
--     p_items = '[{"item_id": 12, "cantidad": 2}, {"item_id": 13, "cantidad": 1}]'
--
-- NO cierra la cuenta. La mesa sigue abierta con lo que falta, y se cierra a
-- mano cuando corresponda: abrir y cerrar una mesa es manual en todo momento.
-- ----------------------------------------------------------------
create or replace function public.cuenta_cobrar_parcial(
  p_cuenta_id bigint,
  p_items     jsonb,
  p_medio     text,
  p_quien     text default null
) returns public.cuenta_pagos
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cuenta    public.cuentas;
  v_pago      public.cuenta_pagos;
  v_sub_venta numeric := 0;   -- el subtotal de la venta ENTERA
  v_desc_venta numeric := 0;  -- el descuento sobre esa venta entera
  v_sub_sel   numeric := 0;   -- lo elegido para cobrar ahora
  v_desc_sel  numeric := 0;   -- la parte del descuento que le toca
  v_monto     numeric := 0;
  v_fila      jsonb;
  v_item      public.cuenta_items;
  v_cant      numeric;
begin
  select * into v_cuenta from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if v_cuenta.estado = 'cerrada' then
    raise exception 'Esa mesa ya está cerrada.';
  end if;

  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'No elegiste ningún producto para cobrar.';
  end if;

  if not exists (select 1 from public.lama_medios_pago
                  where codigo = p_medio and activo) then
    raise exception 'Ese medio de pago no existe o está apagado.';
  end if;

  -- 1. LA VENTA ENTERA, para poder repartir el descuento.
  select coalesce(sum(cantidad * precio), 0) into v_sub_venta
    from public.cuenta_items
   where cuenta_id = p_cuenta_id and anulado_at is null;

  if v_cuenta.descuento_formato = 'pct' then
    v_desc_venta := round(v_sub_venta * coalesce(v_cuenta.descuento_valor, 0) / 100);
  elsif v_cuenta.descuento_formato = 'fijo' then
    v_desc_venta := coalesce(v_cuenta.descuento_valor, 0);
  end if;
  if v_desc_venta < 0 then v_desc_venta := 0; end if;
  if v_desc_venta > v_sub_venta then v_desc_venta := v_sub_venta; end if;

  -- 2. EL PAGO, primero, para poder colgarle los productos.
  insert into public.cuenta_pagos (cuenta_id, medio, monto, creado_por, parcial)
  values (p_cuenta_id, p_medio, 0, p_quien, true)
  returning * into v_pago;

  -- 3. LOS PRODUCTOS ELEGIDOS, uno por uno y con la fila trabada.
  for v_fila in select * from jsonb_array_elements(p_items) loop
    v_cant := (v_fila->>'cantidad')::numeric;
    if v_cant is null or v_cant <= 0 then
      raise exception 'Hay un producto elegido con cantidad cero.';
    end if;

    select * into v_item from public.cuenta_items
     where id = (v_fila->>'item_id')::bigint for update;
    if not found then
      raise exception 'Uno de los productos ya no está en la cuenta.';
    end if;
    if v_item.cuenta_id <> p_cuenta_id then
      raise exception 'Uno de los productos es de otra mesa.';
    end if;
    if v_item.anulado_at is not null then
      raise exception 'No se puede cobrar "%": está anulado.', v_item.nombre;
    end if;
    -- La regla dura de acá: nunca se cobra dos veces la misma unidad. El
    -- `check` de la tabla lo garantiza igual, pero el mensaje se entiende.
    if v_item.cantidad_pagada + v_cant > v_item.cantidad then
      raise exception 'De "%" quedan % sin cobrar, y se pidieron %.',
        v_item.nombre, v_item.cantidad - v_item.cantidad_pagada, v_cant;
    end if;

    v_sub_sel := v_sub_sel + v_cant * v_item.precio;

    insert into public.cuenta_pago_items (pago_id, item_id, cantidad, precio)
    values (v_pago.id, v_item.id, v_cant, v_item.precio);

    update public.cuenta_items
       set cantidad_pagada = cantidad_pagada + v_cant
     where id = v_item.id;
  end loop;

  -- 4. EL DESCUENTO, REPARTIDO. La parte que le toca a lo que se está
  --    cobrando, en proporción a lo que pesa dentro de la venta.
  if v_sub_venta > 0 then
    v_desc_sel := round(v_desc_venta * v_sub_sel / v_sub_venta);
  end if;
  v_monto := v_sub_sel - v_desc_sel;
  if v_monto < 0 then v_monto := 0; end if;

  update public.cuenta_pagos set monto = v_monto
   where id = v_pago.id
   returning * into v_pago;

  return v_pago;
end;
$$;


-- ----------------------------------------------------------------
-- 2.2) DESHACER UN COBRO PARCIAL
--
-- NO es un extra. Salió de preguntarse cuál es la excepción legítima del
-- candado de arriba (§0.8, pregunta 3), y la respuesta apareció enseguida:
-- COBRAR LOS PRODUCTOS EQUIVOCADOS. Sin esto, ese error deja la mesa sin
-- ninguna forma de cerrarse bien.
--
-- Solo mientras la cuenta siga abierta. Una vez cerrada, la venta es
-- inmutable y corregirla es harina de otro costal (el arqueo).
-- ----------------------------------------------------------------
create or replace function public.cuenta_pago_parcial_deshacer(
  p_pago_id bigint,
  p_quien   text default null
) returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pago   public.cuenta_pagos;
  v_cuenta public.cuentas;
  v_n      integer := 0;
begin
  select * into v_pago from public.cuenta_pagos where id = p_pago_id for update;
  if not found then
    raise exception 'Ese cobro ya no existe.';
  end if;
  if not v_pago.parcial then
    raise exception 'Ese no es un cobro parcial: es el pago del cierre.';
  end if;

  select * into v_cuenta from public.cuentas where id = v_pago.cuenta_id for update;
  if v_cuenta.estado = 'cerrada' then
    raise exception 'La mesa ya está cerrada: ese cobro no se puede deshacer.';
  end if;

  -- Devolver las unidades a "sin cobrar".
  update public.cuenta_items ci
     set cantidad_pagada = ci.cantidad_pagada - pi.cantidad
    from public.cuenta_pago_items pi
   where pi.pago_id = p_pago_id and ci.id = pi.item_id;
  get diagnostics v_n = row_count;

  -- Borra el pago; los renglones se van con él (on delete cascade).
  delete from public.cuenta_pagos where id = p_pago_id;

  return v_n;
end;
$$;

-- ##  FIN DEL BLOQUE 2  ##########################################



-- ################################################################
-- ##  BLOQUE 3 de 3  —  las tres que se reemplazan, y la comprobación
-- ##  Copiar de acá hasta el final.
-- ################################################################

-- ----------------------------------------------------------------
-- 3.1) EL CIERRE, QUE AHORA CONVIVE CON LO YA COBRADO
--
-- MISMOS PARÁMETROS que la versión que ya está: esto reemplaza, no agrega una
-- firma nueva (§0.5).
--
-- LO QUE CAMBIA, y es lo que decide si el arqueo cuadra:
--
--   · ya no borra TODOS los pagos, solo los del cierre (`and not parcial`)
--   · lo que hay que pagar ahora es el total de la venta MENOS lo ya cobrado
--   · lo que se congela en `cuentas` describe LA VENTA ENTERA, no el resto
--
-- Ese último punto es el que se hace mal fácil. Si se congelara solo lo que
-- faltaba, el arqueo vería una venta del tamaño del resto y la plata de los
-- cobros parciales quedaría sin ninguna venta que la explique.
--
-- Y ojo con la cuenta del descuento: NO se calcula un "descuento de lo que
-- falta". Se toma el total de la venta y se le resta lo ya cobrado. Así los
-- redondeos de cada cobro parcial no pueden acumularse ni desviar el total.
-- ----------------------------------------------------------------
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
  v_parcial   numeric := 0;   -- lo ya cobrado en pagos parciales
  v_ahora     numeric := 0;   -- lo que entra en este cierre
  v_falta     numeric := 0;   -- lo que hay que pagar ahora
begin
  select * into v_cuenta from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if v_cuenta.estado = 'cerrada' then
    return v_cuenta;
  end if;

  -- 1. el subtotal de la VENTA ENTERA, sin lo anulado
  select coalesce(sum(cantidad * precio), 0) into v_subtotal
    from public.cuenta_items
   where cuenta_id = p_cuenta_id
     and anulado_at is null;

  -- 2. el descuento, sobre esa venta entera
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

  -- 4. lo que ya se cobró de a poco
  select coalesce(sum(monto), 0) into v_parcial
    from public.cuenta_pagos
   where cuenta_id = p_cuenta_id and parcial;

  -- 5. lo que entra ahora
  select coalesce(sum((x->>'monto')::numeric), 0) into v_ahora
    from jsonb_array_elements(coalesce(p_pagos, '[]'::jsonb)) x;

  -- 6. LA REGLA DURA, ahora sobre lo que falta. Si no hay cobros parciales
  --    esto es exactamente lo de antes: v_parcial = 0.
  v_falta := v_total - v_parcial;
  if v_ahora < v_falta then
    raise exception 'Falta plata: se pagaron % de los % que faltaban.', v_ahora, v_falta;
  end if;

  -- Solo los pagos DEL CIERRE. Los parciales sobreviven: son plata cobrada.
  delete from public.cuenta_pagos    where cuenta_id = p_cuenta_id and not parcial;
  delete from public.cuenta_propinas where cuenta_id = p_cuenta_id;

  insert into public.cuenta_propinas (cuenta_id, medio, monto, creado_por)
  select p_cuenta_id, x->>'medio', (x->>'monto')::numeric, p_quien
    from jsonb_array_elements(coalesce(p_propinas, '[]'::jsonb)) x
   where (x->>'monto')::numeric <> 0;

  insert into public.cuenta_pagos (cuenta_id, medio, monto, creado_por, parcial)
  select p_cuenta_id, x->>'medio', (x->>'monto')::numeric, p_quien, false
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
         pagado            = v_parcial + v_ahora,
         vuelto            = (v_parcial + v_ahora) - v_total,
         cerrada_por       = p_quien,
         cerrada_at        = now()
   where id = p_cuenta_id
   returning * into v_cuenta;

  return v_cuenta;
end;
$$;


-- ----------------------------------------------------------------
-- 3.2) NO SE ANULA LO QUE YA SE COBRÓ
--
-- Anular una línea ya cobrada borraría plata recibida y dejaría el arqueo con
-- un pago sin venta. Es lo mismo que hace Fudo: lo pagado se bloquea.
--
-- MISMOS PARÁMETROS (§0.5). Lo único que se agrega es el candado.
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

  -- ← EL CANDADO NUEVO
  if coalesce(v_item.cantidad_pagada, 0) > 0 then
    raise exception 'De "%" ya se cobraron % : eso no se puede anular. Primero hay que deshacer el cobro.',
      v_item.nombre, v_item.cantidad_pagada;
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

  perform public.cuenta_recalcular(v_item.cuenta_id);
  return v_item;
end;
$$;


-- ----------------------------------------------------------------
-- 3.3) NO SE MUEVE A OTRA MESA LO QUE YA SE COBRÓ
--
-- Se llevaría la plata a otra cuenta. MISMOS PARÁMETROS (§0.5).
-- ----------------------------------------------------------------
create or replace function public.items_mover(
  p_items     bigint[],
  p_cuenta_id bigint,
  p_quien     text default null
) returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_destino  public.cuentas;
  v_origenes bigint[];
  v_numero   integer;
  v_origen   bigint;
  v_pagado   text;
begin
  if p_items is null or array_length(p_items, 1) is null then
    raise exception 'No elegiste ningún producto.';
  end if;

  select * into v_destino from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa mesa ya no tiene cuenta abierta.';
  end if;
  if v_destino.estado = 'cerrada' then
    raise exception 'La cuenta de destino ya está cerrada.';
  end if;

  -- ← EL CANDADO NUEVO
  select string_agg(nombre, ', ') into v_pagado
    from public.cuenta_items
   where id = any(p_items) and coalesce(cantidad_pagada, 0) > 0;
  if v_pagado is not null then
    raise exception 'Esto ya está cobrado y no se puede mover: %', v_pagado;
  end if;

  select array_agg(distinct cuenta_id) into v_origenes
    from public.cuenta_items where id = any(p_items);

  update public.cuenta_items
     set cuenta_id = p_cuenta_id
   where id = any(p_items) and cuenta_id <> p_cuenta_id;
  get diagnostics v_numero = row_count;

  perform public.cuenta_recalcular(p_cuenta_id);
  if v_origenes is not null then
    foreach v_origen in array v_origenes loop
      perform public.cuenta_recalcular(v_origen);
    end loop;
  end if;

  return v_numero;
end;
$$;


-- ----------------------------------------------------------------
-- 3.4) PERMISOS
-- ----------------------------------------------------------------
grant execute on function public.cuenta_cobrar_parcial(bigint,jsonb,text,text) to anon, authenticated;
grant execute on function public.cuenta_pago_parcial_deshacer(bigint,text)     to anon, authenticated;
grant execute on function public.item_anular(bigint,text,text,text)            to anon, authenticated;
grant execute on function public.items_mover(bigint[],bigint,text)             to anon, authenticated;
grant execute on function public.cuenta_cobrar(bigint,text,text,text,numeric,jsonb,jsonb)
  to anon, authenticated;


-- ----------------------------------------------------------------
-- 3.5) EL CUADERNO — se anota solo
-- ----------------------------------------------------------------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-09-lama-pago-parcial.sql', 'Jhon', 'lo corrió a mano en el SQL Editor',
        'Pago parcial por producto: cantidad_pagada, cuenta_pago_items, cobrar y deshacer un cobro parcial. No toca el inventario.')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;


-- ----------------------------------------------------------------
-- 3.6) PARA COMPROBAR QUE QUEDÓ BIEN
--
-- Las cinco funciones tienen que decir "1 firma". Si alguna dice 2, PARAR:
-- hay dos versiones conviviendo y la llamada desde la app se vuelve ambigua.
-- Es la falla que dejó el sistema 15 horas sin descontar (§0.5).
-- ----------------------------------------------------------------
select f.nombre as funcion,
       count(p.oid) || ' firma' ||
       case when count(p.oid) = 1 then '' else 's  ← PARAR' end as estado
  from (values ('cuenta_cobrar'), ('cuenta_cobrar_parcial'),
               ('cuenta_pago_parcial_deshacer'), ('item_anular'), ('items_mover')) as f(nombre)
  left join pg_proc p on p.proname = f.nombre
   and p.pronamespace = (select oid from pg_namespace where nspname = 'public')
 group by f.nombre

union all

select 'columna cantidad_pagada',
       case when exists (select 1 from information_schema.columns
                          where table_schema='public' and table_name='cuenta_items'
                            and column_name='cantidad_pagada')
            then 'puesta' else 'FALTA  ← PARAR' end

union all

select 'columna parcial en cuenta_pagos',
       case when exists (select 1 from information_schema.columns
                          where table_schema='public' and table_name='cuenta_pagos'
                            and column_name='parcial')
            then 'puesta' else 'FALTA  ← PARAR' end

union all

select 'tabla cuenta_pago_items',
       case when to_regclass('public.cuenta_pago_items') is not null
            then 'creada' else 'FALTA  ← PARAR' end;
