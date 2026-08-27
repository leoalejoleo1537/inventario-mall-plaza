-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque (pégalo entero y aprieta Run)
--  TARDA:     instantáneo
--  QUÉ HACE:  las ocho funciones que mueven una mesa: abrir, agregar,
--             confirmar, precuenta, cerrar, mover mesa y mover productos.
--             NO tocan el inventario.
--  QUÉ VER:   la última consulta deja 8 filas, todas con "1 firma".
-- ================================================================
--
-- POR QUÉ ESTO VA EN LA BASE Y NO EN LA PANTALLA
--
-- Cada una de estas hace VARIAS cosas que tienen que pasar juntas o no pasar.
-- Confirmar, por ejemplo, marca los items Y crea la comanda: si se hiciera en
-- dos llamadas desde el teléfono y se cortara la señal en el medio, quedarían
-- items confirmados sin ningún papel que respalde lo que salió a la cocina.
-- Es el mismo criterio que `mermar` y `reparto_recibir`.
--
-- LAS TRES REGLAS QUE VAN ADENTRO, no en un botón escondido
--
-- 1. Una mesa no puede tener dos cuentas abiertas. Ya lo impide el índice de
--    los cimientos; acá se traduce el error de Postgres a algo legible.
-- 2. Confirmar dos veces NO manda de nuevo lo que ya salió. La función solo
--    toma los `nuevo` — mismo candado que el reparto.
-- 3. No se puede mover una mesa a otra que ya está ocupada.
--
-- CÓMO ESTÁ ESCRITO, y por qué importa
--
-- Los cuerpos van entre comillas de dólar ($$), igual que `mermar` y
-- `reparto_recibir`. La primera versión los puso entre comillas simples para
-- evitar el problema de §3.5, y salió al revés: el editor de Supabase se
-- atragantó con las comillas dobladas de adentro y contestó
-- "relation m does not exist" — un error que no se parece en nada a la causa.
--
-- La lección, y vale para cualquier función futura: **§3.5 dice que las
-- comillas de dólar pueden confundir al editor, pero la evidencia de este
-- proyecto es que las funciones plpgsql con $$ SÍ corren.** Lo que rompe es
-- el SQL dinámico con $q$ anidado y los bloques muy largos. Un cuerpo de
-- plpgsql normal va con $$, como los seis que ya funcionan.
--
-- ⚠️ EL STOCK NO SE TOCA. Ni al confirmar ni al cerrar. Es a propósito y es
-- lo que hace que probar sea seguro: se puede abrir y cerrar mesas veinte
-- veces sin descuadrar el inventario. Se enciende después, con interruptor.
-- ================================================================


-- ---------- 1) ABRIR una mesa ----------
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
  m public.mesas;
  c public.cuentas;
begin
  select * into m from public.mesas where id = p_mesa_id;
  if not found then
    raise exception 'Esa mesa ya no existe.';
  end if;
  if not m.activa then
    raise exception 'La mesa % está apagada.', m.numero;
  end if;

  -- La cuenta viva, si la hay. Se bloquea para que dos teléfonos no creen
  -- dos al mismo tiempo.
  select * into c from public.cuentas
   where mesa_id = p_mesa_id and estado <> 'cerrada'
   for update;
  if found then
    return c;
  end if;

  insert into public.cuentas (sede, mesa_id, estado, abierta_por)
  values (m.sede, m.id, 'abierta', p_quien)
  returning * into c;
  return c;
end;
$$;


-- ---------- 2) AGREGAR un producto ----------
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
  c  public.cuentas;
  it public.cuenta_items;
  v_com text := nullif(btrim(coalesce(p_comentario, '')), '');
begin
  if coalesce(p_cantidad, 0) <= 0 then
    raise exception 'La cantidad tiene que ser mayor que cero.';
  end if;
  if btrim(coalesce(p_nombre, '')) = '' then
    raise exception 'Falta el nombre del producto.';
  end if;

  select * into c from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if c.estado = 'cerrada' then
    raise exception 'La cuenta ya está cerrada. Abre la mesa de nuevo.';
  end if;

  select * into it from public.cuenta_items
   where cuenta_id = p_cuenta_id
     and estado = 'nuevo'
     and nombre = btrim(p_nombre)
     and coalesce(comentario, '') = coalesce(v_com, '')
   order by id limit 1
   for update;

  if found then
    update public.cuenta_items
       set cantidad = cantidad + p_cantidad
     where id = it.id
     returning * into it;
  else
    insert into public.cuenta_items
      (cuenta_id, fudo_product_id, nombre, cantidad, precio, comentario, agregado_por)
    values (p_cuenta_id, p_fudo_id, btrim(p_nombre), p_cantidad,
            coalesce(p_precio, 0), v_com, p_quien)
    returning * into it;
  end if;

  perform public.cuenta_recalcular(p_cuenta_id);
  return it;
end;
$$;


-- ---------- 3) el total, en un solo lugar ----------
-- Lo llaman todas las demás. Escrito una vez, para que no haya dos formas de
-- calcular el mismo número — que es como se producen los descuadres.
create or replace function public.cuenta_recalcular(p_cuenta_id bigint)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v numeric;
begin
  select coalesce(sum(cantidad * precio), 0) into v
    from public.cuenta_items where cuenta_id = p_cuenta_id;
  update public.cuentas set total = v where id = p_cuenta_id;
  return v;
end;
$$;


-- ---------- 4) CONFIRMAR: sale la comanda ----------
create or replace function public.cuenta_confirmar(
  p_cuenta_id bigint,
  p_quien     text default null
) returns public.comandas
language plpgsql
security definer
set search_path = public
as $$
declare
  c   public.cuentas;
  cm  public.comandas;
  n   integer;
  cont jsonb;
begin
  select * into c from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if c.estado = 'cerrada' then
    raise exception 'La cuenta ya está cerrada.';
  end if;

  -- SOLO LO NUEVO. Confirmar dos veces no vuelve a mandar lo que ya salió.
  select jsonb_agg(jsonb_build_object(
           'nombre', nombre, 'cantidad', cantidad,
           'precio', precio, 'comentario', comentario) order by id)
    into cont
    from public.cuenta_items
   where cuenta_id = p_cuenta_id and estado = 'nuevo';

  if cont is null then
    raise exception 'No hay nada nuevo que mandar a la cocina.';
  end if;

  select coalesce(max(numero), 0) + 1 into n
    from public.comandas where cuenta_id = p_cuenta_id;

  insert into public.comandas (sede, cuenta_id, numero, quien, contenido)
  values (c.sede, p_cuenta_id, n, p_quien, cont)
  returning * into cm;

  update public.cuenta_items
     set estado = 'confirmado', comanda_id = cm.id
   where cuenta_id = p_cuenta_id and estado = 'nuevo';

  perform public.cuenta_recalcular(p_cuenta_id);
  return cm;
end;
$$;


-- ---------- 5) PRECUENTA: la mesa se pone azul ----------
create or replace function public.cuenta_precuenta(
  p_cuenta_id bigint,
  p_quien     text default null
) returns public.cuentas
language plpgsql
security definer
set search_path = public
as $$
declare
  c public.cuentas;
begin
  select * into c from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if c.estado = 'cerrada' then
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
   returning * into c;
  return c;
end;
$$;


-- ---------- 6) CERRAR: la mesa vuelve a verde ----------
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
  c public.cuentas;
begin
  select * into c from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  -- Idempotente: cerrar dos veces devuelve la fila, no falla. Dos toques
  -- seguidos en un teléfono lento es algo que pasa.
  if c.estado = 'cerrada' then
    return c;
  end if;

  perform public.cuenta_recalcular(p_cuenta_id);
  update public.cuentas
     set estado = 'cerrada', cerrada_por = p_quien, cerrada_at = now()
   where id = p_cuenta_id
   returning * into c;
  return c;
end;
$$;


-- ---------- 7) MOVER la mesa entera ----------
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
  c public.cuentas;
  m public.mesas;
begin
  select * into c from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa cuenta ya no existe.';
  end if;
  if c.estado = 'cerrada' then
    raise exception 'La cuenta ya está cerrada: no se puede mover.';
  end if;
  if c.mesa_id = p_mesa_id then
    return c;
  end if;

  select * into m from public.mesas where id = p_mesa_id;
  if not found then
    raise exception 'Esa mesa no existe.';
  end if;
  if m.sede <> c.sede then
    raise exception 'No se puede mover una cuenta a otra sede.';
  end if;
  if exists (select 1 from public.cuentas
              where mesa_id = p_mesa_id and estado <> 'cerrada') then
    raise exception 'La mesa % ya está ocupada. Elige una libre.', m.numero;
  end if;

  update public.cuentas set mesa_id = p_mesa_id
   where id = p_cuenta_id returning * into c;
  return c;
end;
$$;


-- ---------- 8) MOVER productos de una mesa a otra ----------
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
  destino public.cuentas;
  origen  bigint[];
  n       integer;
  o       bigint;
begin
  if p_items is null or array_length(p_items, 1) is null then
    raise exception 'No elegiste ningún producto.';
  end if;

  select * into destino from public.cuentas where id = p_cuenta_id for update;
  if not found then
    raise exception 'Esa mesa ya no tiene cuenta abierta.';
  end if;
  if destino.estado = 'cerrada' then
    raise exception 'La cuenta de destino ya está cerrada.';
  end if;

  -- De qué cuentas salen, para poder recalcularles el total después.
  select array_agg(distinct cuenta_id) into origen
    from public.cuenta_items where id = any(p_items);

  update public.cuenta_items
     set cuenta_id = p_cuenta_id
   where id = any(p_items) and cuenta_id <> p_cuenta_id;
  get diagnostics n = row_count;

  perform public.cuenta_recalcular(p_cuenta_id);
  if origen is not null then
    foreach o in array origen loop
      perform public.cuenta_recalcular(o);
    end loop;
  end if;

  return n;
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
