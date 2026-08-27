-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        9 BLOQUES. Corre UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  las ocho funciones que mueven una mesa. NO tocan el inventario.
--  QUÉ VER:   cada bloque contesta "Success. No rows returned" (o CREATE
--             FUNCTION). El bloque 9 deja 8 filas con "1 firma".
--
--  ⚠️ SI ALGUNO FALLA: para ahí y dime CUÁL número. Con eso sé exactamente
--     dónde está el problema en vez de adivinar.
-- ================================================================
--
-- POR QUÉ VAN DE A UNA, Y NO TODAS JUNTAS
--
-- El intento anterior las mandó todas en un Run y el editor contestó
-- "relation m does not exist" — un error que no se parece en nada a la causa.
-- De a una, cada bloque es chico y si algo falla, falla solo y con nombre.
--
-- Y las variables dejaron de llamarse `m`, `c`, `n`. Ahora son `v_mesa`,
-- `v_cuenta`, `v_numero`. Si una variable de una letra no se reconoce, la
-- línea `m.sede` se lee como "la columna sede de la TABLA m" — y ese es
-- exactamente el error que salió. Con nombres largos esa confusión no existe.
-- Es lo mismo que hace `mermar`, que sí corrió: usa `pr`, `lo`, `mv`.
--
-- POR QUÉ ESTO VA EN LA BASE Y NO EN LA PANTALLA
--
-- Cada una hace VARIAS cosas que tienen que pasar juntas o no pasar.
-- Confirmar marca los items Y crea la comanda: si se hiciera en dos llamadas
-- desde el teléfono y se cortara la señal en el medio, quedarían items
-- confirmados sin ningún papel que respalde lo que salió a la cocina.
--
-- ⚠️ EL STOCK NO SE TOCA. Ni al confirmar ni al cerrar. Es a propósito y es
-- lo que hace que probar sea seguro.
-- ================================================================



-- ================================================================
-- BLOQUE 1 — ABRIR una mesa
-- ================================================================
-- ABRIR una mesa ----------
-- Devuelve la cuenta. Si ya había una viva, devuelve ESA en vez de fallar:
-- dos garzones tocando la misma mesa a la vez es lo normal, no un error.
create or replace function public.mesa_abrir(
  p_mesa_id bigint,
  p_quien   text default null
) returns public.cuentas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mesa public.mesas;
  v_cuenta public.cuentas;
begin
  select * into v_mesa from public.mesas where id = p_mesa_id;
  if not found then
    raise exception 'Esa mesa ya no existe.';
  end if;
  if not v_mesa.activa then
    raise exception 'La mesa % está apagada.', v_mesa.numero;
  end if;

  -- La cuenta viva, si la hay. Se bloquea para que dos teléfonos no creen
  -- dos al mismo tiempo.
  select * into v_cuenta from public.cuentas
   where mesa_id = p_mesa_id and estado <> 'cerrada'
   for update;
  if found then
    return v_cuenta;
  end if;

  insert into public.cuentas (sede, mesa_id, estado, abierta_por)
  values (v_mesa.sede, v_mesa.id, 'abierta', p_quien)
  returning * into v_cuenta;
  return v_cuenta;
end;
$$;


-- ================================================================
-- BLOQUE 2 — AGREGAR un producto
-- ================================================================
-- AGREGAR un producto ----------
-- Si ese producto ya está en la cuenta y TODAVÍA NO SALIÓ, sube la cantidad
-- en vez de abrir otra línea: dos renglones iguales en una comanda confunden
-- a la cocina. Si ya salió, se abre una línea nueva — porque es un pedido
-- nuevo y tiene que aparecer en la comanda siguiente.
create or replace function public.cuenta_agregar(
  p_cuenta_id  bigint,
  p_nombre     text,
  p_precio     numeric default 0,
  p_cantidad   numeric default 1,
  p_comentario text default null,
  p_fudo_id    text default null,
  p_quien      text default null
) returns public.cuenta_items
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cuenta  public.cuentas;
  v_item public.cuenta_items;
  v_com text := nullif(btrim(coalesce(p_comentario, '')), '');
begin
  if coalesce(p_cantidad, 0) <= 0 then
    raise exception 'La cantidad tiene que ser mayor que cero.';
  end if;
  if btrim(coalesce(p_nombre, '')) = '' then
    raise exception 'Falta el nombre del producto.';
  end if;

  select * into v_cuenta from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if v_cuenta.estado = 'cerrada' then
    raise exception 'La cuenta ya está cerrada. Abre la mesa de nuevo.';
  end if;

  select * into v_item from public.cuenta_items
   where cuenta_id = p_cuenta_id
     and estado = 'nuevo'
     and nombre = btrim(p_nombre)
     and coalesce(comentario, '') = coalesce(v_com, '')
   order by id limit 1
   for update;

  if found then
    update public.cuenta_items
       set cantidad = cantidad + p_cantidad
     where id = v_item.id
     returning * into v_item;
  else
    insert into public.cuenta_items
      (cuenta_id, fudo_product_id, nombre, cantidad, precio, comentario, agregado_por)
    values (p_cuenta_id, p_fudo_id, btrim(p_nombre), p_cantidad,
            coalesce(p_precio, 0), v_com, p_quien)
    returning * into v_item;
  end if;

  perform public.cuenta_recalcular(p_cuenta_id);
  return v_item;
end;
$$;


-- ================================================================
-- BLOQUE 3 — el total en un solo lugar
-- ================================================================
-- el total, en un solo lugar ----------
-- Lo llaman todas las demás. Escrito una vez, para que no haya dos formas de
-- calcular el mismo número — que es como se producen los descuadres.
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
    from public.cuenta_items where cuenta_id = p_cuenta_id;
  update public.cuentas set total = v_total where id = p_cuenta_id;
  return v_total;
end;
$$;


-- ================================================================
-- BLOQUE 4 — CONFIRMAR: sale la comanda
-- ================================================================
-- CONFIRMAR: sale la comanda ----------
create or replace function public.cuenta_confirmar(
  p_cuenta_id bigint,
  p_quien     text default null
) returns public.comandas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cuenta   public.cuentas;
  v_comanda  public.comandas;
  v_numero   integer;
  v_contenido jsonb;
begin
  select * into v_cuenta from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if v_cuenta.estado = 'cerrada' then
    raise exception 'La cuenta ya está cerrada.';
  end if;

  -- SOLO LO NUEVO. Confirmar dos veces no vuelve a mandar lo que ya salió.
  select jsonb_agg(jsonb_build_object(
           'nombre', nombre, 'cantidad', cantidad,
           'precio', precio, 'comentario', comentario) order by id)
    into v_contenido
    from public.cuenta_items
   where cuenta_id = p_cuenta_id and estado = 'nuevo';

  if v_contenido is null then
    raise exception 'No hay nada nuevo que mandar a la cocina.';
  end if;

  select coalesce(max(numero), 0) + 1 into v_numero
    from public.comandas where cuenta_id = p_cuenta_id;

  insert into public.comandas (sede, cuenta_id, numero, quien, contenido)
  values (v_cuenta.sede, p_cuenta_id, v_numero, p_quien, v_contenido)
  returning * into v_comanda;

  update public.cuenta_items
     set estado = 'confirmado', comanda_id = v_comanda.id
   where cuenta_id = p_cuenta_id and estado = 'nuevo';

  perform public.cuenta_recalcular(p_cuenta_id);
  return v_comanda;
end;
$$;


-- ================================================================
-- BLOQUE 5 — PRECUENTA: la mesa se pone azul
-- ================================================================
-- PRECUENTA: la mesa se pone azul ----------
create or replace function public.cuenta_precuenta(
  p_cuenta_id bigint,
  p_quien     text default null
) returns public.cuentas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cuenta public.cuentas;
begin
  select * into v_cuenta from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if v_cuenta.estado = 'cerrada' then
    raise exception 'La cuenta ya está cerrada.';
  end if;
  if exists (select 1 from public.cuenta_items
              where cuenta_id = p_cuenta_id and estado = 'nuevo') then
    raise exception 'Hay productos que todavía no salieron a la cocina. Confirma primero.';
  end if;

  perform public.cuenta_recalcular(p_cuenta_id);
  update public.cuentas
     set estado = 'precuenta', precuenta_at = now()
   where id = p_cuenta_id
   returning * into v_cuenta;
  return v_cuenta;
end;
$$;


-- ================================================================
-- BLOQUE 6 — CERRAR: la mesa vuelve a verde
-- ================================================================
-- CERRAR: la mesa vuelve a verde ----------
-- ⚠️ NO toca el stock. Ver la cabecera.
create or replace function public.cuenta_cerrar(
  p_cuenta_id bigint,
  p_quien     text default null
) returns public.cuentas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cuenta public.cuentas;
begin
  select * into v_cuenta from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  -- Idempotente: cerrar dos veces devuelve la fila, no falla. Dos toques
  -- seguidos en un teléfono lento es algo que pasa.
  if v_cuenta.estado = 'cerrada' then
    return v_cuenta;
  end if;

  perform public.cuenta_recalcular(p_cuenta_id);
  update public.cuentas
     set estado = 'cerrada', cerrada_por = p_quien, cerrada_at = now()
   where id = p_cuenta_id
   returning * into v_cuenta;
  return v_cuenta;
end;
$$;


-- ================================================================
-- BLOQUE 7 — MOVER la mesa entera
-- ================================================================
-- MOVER la mesa entera ----------
-- El garzón abrió la 3 y era la 7. Se niega si la destino está ocupada.
create or replace function public.cuenta_mover(
  p_cuenta_id bigint,
  p_mesa_id   bigint,
  p_quien     text default null
) returns public.cuentas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cuenta public.cuentas;
  v_mesa public.mesas;
begin
  select * into v_cuenta from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if v_cuenta.estado = 'cerrada' then
    raise exception 'La cuenta ya está cerrada: no se puede mover.';
  end if;
  if v_cuenta.mesa_id = p_mesa_id then
    return v_cuenta;
  end if;

  select * into v_mesa from public.mesas where id = p_mesa_id;
  if not found then
    raise exception 'Esa mesa no existe.';
  end if;
  if v_mesa.sede <> v_cuenta.sede then
    raise exception 'No se puede mover una cuenta a otra sede.';
  end if;
  if exists (select 1 from public.cuentas
              where mesa_id = p_mesa_id and estado <> 'cerrada') then
    raise exception 'La mesa % ya está ocupada. Elige una libre.', v_mesa.numero;
  end if;

  update public.cuentas set mesa_id = p_mesa_id
   where id = p_cuenta_id returning * into v_cuenta;
  return v_cuenta;
end;
$$;


-- ================================================================
-- BLOQUE 8 — MOVER productos entre mesas
-- ================================================================
-- MOVER productos de una mesa a otra ----------
-- Se pidió en la 3 lo que era para la 7. Los productos viajan con su estado:
-- lo que ya salió a la cocina sigue contando como salido.
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
  v_destino public.cuentas;
  v_origenes  bigint[];
  v_numero       integer;
  v_origen       bigint;
begin
  if p_items is null or array_length(p_items, 1) is null then
    raise exception 'No elegiste ningún producto.';
  end if;

  select * into v_destino from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa mesa ya no tiene cuenta abierta.';
  end if;
  if v_destino.estado = 'cerrada' then
    raise exception 'La cuenta de v_destino ya está cerrada.';
  end if;

  -- De qué cuentas salen, para poder recalcularles el total después.
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


-- ---------- quién puede llamarlas ----------
grant execute on function public.mesa_abrir(bigint,text)                                        to anon, authenticated;
grant execute on function public.cuenta_agregar(bigint,text,numeric,numeric,text,text,text)     to anon, authenticated;
grant execute on function public.cuenta_recalcular(bigint)                                      to anon, authenticated;
grant execute on function public.cuenta_confirmar(bigint,text)                                  to anon, authenticated;
grant execute on function public.cuenta_precuenta(bigint,text)                                  to anon, authenticated;
grant execute on function public.cuenta_cerrar(bigint,text)                                     to anon, authenticated;
grant execute on function public.cuenta_mover(bigint,bigint,text)                               to anon, authenticated;
grant execute on function public.items_mover(bigint[],bigint,text)                              to anon, authenticated;


insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-lama-funciones.sql', 'Jhon', 'lo corrió Jhon',
        'Ocho funciones de Llamita Lama. NO tocan el stock. Confirmar solo manda lo nuevo; no se puede mover a una mesa ocupada')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;


-- ================================================================
-- COMPROBACIÓN — 8 filas, TODAS tienen que decir "1 firma"
--
-- Si alguna dijera "2 firmas", hay dos versiones conviviendo y la llamada
-- desde la app se vuelve ambigua: es la falla que dejó el sistema 15 horas
-- sin descontar (§0.5).
-- ================================================================
select p.proname as funcion, count(*)::text || ' firma' as estado
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('mesa_abrir','cuenta_agregar','cuenta_recalcular','cuenta_confirmar',
                     'cuenta_precuenta','cuenta_cerrar','cuenta_mover','items_mover')
 group by p.proname
 order by p.proname;


-- ================================================================
-- BLOQUE 9 — LOS PERMISOS Y LA COMPROBACIÓN
--
-- Después de que los 8 bloques anteriores hayan pasado.
-- QUÉ VER: 8 filas, TODAS tienen que decir "1 firma".
-- Si alguna dijera "2 firmas", hay dos versiones conviviendo y la llamada
-- desde la app se vuelve ambigua: es la falla que dejó el sistema 15 horas
-- sin descontar (§0.5).
-- ================================================================
-- ---------- quién puede llamarlas ----------
grant execute on function public.mesa_abrir(bigint,text)                                        to anon, authenticated;
grant execute on function public.cuenta_agregar(bigint,text,numeric,numeric,text,text,text)     to anon, authenticated;
grant execute on function public.cuenta_recalcular(bigint)                                      to anon, authenticated;
grant execute on function public.cuenta_confirmar(bigint,text)                                  to anon, authenticated;
grant execute on function public.cuenta_precuenta(bigint,text)                                  to anon, authenticated;
grant execute on function public.cuenta_cerrar(bigint,text)                                     to anon, authenticated;
grant execute on function public.cuenta_mover(bigint,bigint,text)                               to anon, authenticated;
grant execute on function public.items_mover(bigint[],bigint,text)                              to anon, authenticated;


insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-lama-funciones.sql', 'Jhon', 'lo corrió Jhon',
        'Ocho funciones de Llamita Lama. NO tocan el stock. Confirmar solo manda lo nuevo; no se puede mover a una mesa ocupada')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;


-- ================================================================
-- COMPROBACIÓN — 8 filas, TODAS tienen que decir "1 firma"
--
-- Si alguna dijera "2 firmas", hay dos versiones conviviendo y la llamada
-- desde la app se vuelve ambigua: es la falla que dejó el sistema 15 horas
-- sin descontar (§0.5).
-- ================================================================
select p.proname as funcion, count(*)::text || ' firma' as estado
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('mesa_abrir','cuenta_agregar','cuenta_recalcular','cuenta_confirmar',
                     'cuenta_precuenta','cuenta_cerrar','cuenta_mover','items_mover')
 group by p.proname
 order by p.proname;
