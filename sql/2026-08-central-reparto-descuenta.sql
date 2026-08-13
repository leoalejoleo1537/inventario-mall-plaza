-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Los bloques 1 y 2 llevan $$: cada uno SOLO.
--  TARDA:     instantáneo
--  QUÉ HACE:  hace que al confirmar un reparto en el local, el stock BAJE
--             en bodega. No mueve ningún producto al instalarse.
--  QUÉ VER:   el bloque 3: 3 filas, las 3 en SÍ.
-- ================================================================
--
-- QUÉ CAMBIA Y QUÉ NO. `reparto_recibir()` sigue haciendo exactamente lo mismo
-- que hoy del lado del local: suma al stock (o a las fechas si es perecedero) y
-- encola el aviso a Fudo. Nada de eso se toca. Lo ÚNICO que se agrega es que,
-- si esa línea trae `producto_bodega_id`, también descuenta en bodega y lo
-- anota en el libro de movimientos.
--
-- Las líneas armadas DENTRO del local no traen esa columna, así que para ellas
-- no cambia absolutamente nada. Por eso se pueden seguir usando las dos formas
-- en paralelo sin que nada se descuente dos veces.
--
-- TRES CUIDADOS QUE VALE LA PENA CONOCER:
--
-- · **Nunca negativo** (§0.2). Si bodega tiene 3 y el local confirma 5, baja
--   los 3 y queda en 0 — y el libro anota que bajó 3, no 5. Lo que no cuadre
--   se arregla contando, no inventando el número.
-- · **Si el producto de bodega tiene fechas**, se descuenta por fecha con
--   `descontar_lotes()`, nunca tocando el stock directo (regla 0.3.1). Se le
--   pasa una cantidad que siempre cabe, para no depender de qué versión de esa
--   función esté instalada.
-- · **Deshacer NUNCA puede fallar por culpa de bodega.** Si el jefe de turno se
--   equivocó al confirmar, tiene que poder deshacer aunque devolver a bodega
--   sea imposible. Cuando el producto de bodega tiene fechas no se puede saber
--   a qué día devolver las unidades, así que en ese caso el deshacer igual
--   funciona y queda anotado en el libro que bodega necesita una corrección a
--   mano. Bloquear al local por un dato de bodega sería peor.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — RECIBIR  (correr este bloque SOLO)
-- ================================================================
create or replace function public.reparto_recibir(
  p_item_id  bigint,
  p_cantidad numeric        default null,
  p_lotes    jsonb          default null,
  p_quien    text           default null
) returns public.reparto_items
language plpgsql
security definer
set search_path = public
as $$
declare
  it          public.reparto_items;
  v_perec     boolean;
  v_tiene_lot boolean;
  v_sede      text;
  v_total     numeric := 0;
  v_ids       bigint[] := '{}';
  r           jsonb;
  v_lote_id   bigint;
  v_pend_id   bigint;
  -- lo nuevo, para el descuento en bodega
  v_bod       public.productos;
  v_bod_lotes boolean;
  v_hay       numeric;
  v_baja      numeric := 0;
begin
  select * into it from public.reparto_items where id = p_item_id for update;
  if not found then
    raise exception 'Esa línea del reparto ya no existe.';
  end if;
  if it.estado <> 'pendiente' then
    return it;
  end if;

  select coalesce(p.perecedero, p.rubro = 'Sándwiches'), p.sede
    into v_perec, v_sede
    from public.productos p where p.id = it.producto_id;

  select exists(select 1 from public.producto_lotes l where l.producto_id = it.producto_id)
    into v_tiene_lot;

  if v_perec or v_tiene_lot then
    if p_lotes is null or jsonb_array_length(p_lotes) = 0 then
      raise exception 'Este producto lleva fecha de vencimiento: hay que indicar la fecha para poder recibirlo.';
    end if;
    for r in select * from jsonb_array_elements(p_lotes) loop
      if (r->>'vencimiento') is null or (r->>'vencimiento') = '' then
        raise exception 'Cada fecha necesita su día.';
      end if;
      if coalesce((r->>'cantidad')::numeric, 0) <= 0 then
        raise exception 'Cada fecha necesita una cantidad mayor que 0.';
      end if;
      insert into public.producto_lotes(producto_id, cantidad, vencimiento)
      values (it.producto_id, (r->>'cantidad')::numeric, (r->>'vencimiento')::date)
      returning id into v_lote_id;
      v_ids   := v_ids || v_lote_id;
      v_total := v_total + (r->>'cantidad')::numeric;
    end loop;
  else
    v_total := coalesce(p_cantidad, it.cantidad_pedida);
    if v_total < 0 then
      raise exception 'La cantidad recibida no puede ser negativa.';
    end if;
    update public.productos
       set stock_actual = coalesce(stock_actual,0) + v_total,
           updated_at   = now()
     where id = it.producto_id;
  end if;

  -- ---------- LO NUEVO: baja en bodega ----------
  -- solo si el envío salió de bodega. Los repartos armados dentro del local
  -- no traen esta columna y no tocan bodega, igual que siempre.
  if it.producto_bodega_id is not null and v_total > 0 then
    select * into v_bod from public.productos
     where id = it.producto_bodega_id for update;
    if found then
      select exists(select 1 from public.producto_lotes l
                     where l.producto_id = v_bod.id and coalesce(l.cantidad,0) > 0)
        into v_bod_lotes;

      if v_bod_lotes then
        -- con fechas: se descuenta por fecha y el trigger recalcula el stock.
        -- Se le pasa una cantidad que SIEMPRE cabe, así no depende de qué
        -- versión de descontar_lotes esté instalada.
        select coalesce(sum(cantidad),0) into v_hay
          from public.producto_lotes where producto_id = v_bod.id;
        v_baja := least(v_total, greatest(v_hay,0));
        if v_baja > 0 then perform public.descontar_lotes(v_bod.id, v_baja); end if;
      else
        -- sin fechas: al stock, con tope en cero (§0.2)
        v_baja := least(v_total, greatest(coalesce(v_bod.stock_actual,0),0));
        if v_baja > 0 then
          update public.productos
             set stock_actual = coalesce(stock_actual,0) - v_baja, updated_at = now()
           where id = v_bod.id;
        end if;
      end if;

      -- el libro. El signo lleva la dirección: sale de bodega, va en negativo
      if v_baja > 0 then
        insert into public.movimientos
          (sede, producto_id, producto, tipo, cantidad, sede_contraparte, motivo,
           reparto_item_id, quien)
        values ('central', v_bod.id, v_bod.producto, 'salida', -v_baja, v_sede,
                'reparto', it.id, p_quien);
      end if;
      -- si bodega no alcanzaba, queda anotado en vez de inventar el número
      if v_baja < v_total then
        insert into public.movimientos
          (sede, producto_id, producto, tipo, cantidad, sede_contraparte, motivo,
           reparto_item_id, quien)
        values ('central', v_bod.id, v_bod.producto, 'ajuste', (v_total - v_baja), v_sede,
                'faltó en bodega al confirmar el reparto', it.id, p_quien);
      end if;
    end if;
  end if;

  update public.reparto_items
     set estado='recibido', cantidad_recibida=v_total, lotes_creados=v_ids,
         resuelto_por=p_quien, resuelto_at=now()
   where id = p_item_id
   returning * into it;

  if v_total > 0 then
    insert into public.fudo_pendientes(sede, producto_id, producto, rubro, cantidad)
    select v_sede, it.producto_id, it.producto, p.rubro, v_total
    from public.productos p where p.id = it.producto_id
    returning id into v_pend_id;
    update public.reparto_items set pendiente_id = v_pend_id where id = p_item_id
      returning * into it;
  end if;

  return it;
end;
$$;


-- ================================================================
-- BLOQUE 2 — DESHACER  (correr este bloque SOLO)
--
-- Devuelve a bodega lo que se le había descontado. NUNCA se niega por culpa de
-- bodega: si el jefe de turno se equivocó, tiene que poder deshacer.
-- ================================================================
create or replace function public.reparto_deshacer(p_item_id bigint)
returns public.reparto_items
language plpgsql security definer set search_path = public
as $$
declare
  it       public.reparto_items;
  v_stock  numeric;
  v_faltan int;
  v_dev    numeric := 0;
  v_bod    public.productos;
  v_lotes  boolean;
begin
  select * into it from public.reparto_items where id = p_item_id for update;
  if not found then raise exception 'Esa línea del reparto ya no existe.'; end if;
  if it.estado = 'pendiente' then return it; end if;

  if it.estado = 'recibido' and coalesce(it.cantidad_recibida,0) > 0 then
    if it.lotes_creados is not null and array_length(it.lotes_creados,1) > 0 then
      select count(*) into v_faltan
        from unnest(it.lotes_creados) as lid
       where not exists (select 1 from public.producto_lotes l where l.id = lid);
      if v_faltan > 0 then
        raise exception 'No se puede deshacer: ya se vendieron unidades de este producto. Corrige el stock en la ficha.';
      end if;
      delete from public.producto_lotes where id = any(it.lotes_creados);
    else
      select coalesce(stock_actual,0) into v_stock from public.productos where id = it.producto_id;
      if v_stock < it.cantidad_recibida then
        raise exception 'No se puede deshacer: ya se vendieron unidades de este producto. Corrige el stock en la ficha.';
      end if;
      update public.productos
         set stock_actual = v_stock - it.cantidad_recibida, updated_at = now()
       where id = it.producto_id;
    end if;

    -- ---------- LO NUEVO: devolver a bodega ----------
    if it.producto_bodega_id is not null then
      -- cuánto se le había sacado de verdad (puede ser menos de lo confirmado)
      select coalesce(-sum(cantidad),0) into v_dev
        from public.movimientos
       where reparto_item_id = it.id and tipo='salida' and sede='central';

      if v_dev > 0 then
        select * into v_bod from public.productos where id = it.producto_bodega_id for update;
        if found then
          select exists(select 1 from public.producto_lotes l
                         where l.producto_id = v_bod.id) into v_lotes;
          if v_lotes then
            -- con fechas no se puede saber a qué día volvían las unidades.
            -- El deshacer NO se bloquea: queda anotado para corregir contando.
            insert into public.movimientos
              (sede, producto_id, producto, tipo, cantidad, motivo, reparto_item_id)
            values ('central', v_bod.id, v_bod.producto, 'ajuste', v_dev,
                    'se deshizo un reparto: hay que devolver estas unidades a su fecha a mano', it.id);
          else
            update public.productos
               set stock_actual = coalesce(stock_actual,0) + v_dev, updated_at = now()
             where id = v_bod.id;
            insert into public.movimientos
              (sede, producto_id, producto, tipo, cantidad, motivo, reparto_item_id)
            values ('central', v_bod.id, v_bod.producto, 'entrada', v_dev,
                    'se deshizo un reparto', it.id);
          end if;
        end if;
      end if;
    end if;
  end if;

  if it.pendiente_id is not null then
    delete from public.fudo_pendientes where id = it.pendiente_id;
  end if;

  update public.reparto_items
     set estado='pendiente', cantidad_recibida=null, lotes_creados=null,
         pendiente_id=null, resuelto_por=null, resuelto_at=null
   where id = p_item_id
   returning * into it;
  return it;
end;
$$;


-- ================================================================
-- BLOQUE 3 — COMPROBACIÓN — 3 filas, las 3 en SÍ
--
-- La fila de las firmas es la que importa: si quedaran DOS versiones de la
-- misma función, la llamada desde la app se vuelve ambigua y falla sin decir
-- por qué. Es la falla de las 15 horas de julio (§0.5).
-- ================================================================
select 'reparto_recibir, y UNA sola firma' as pieza,
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='reparto_recibir') = 1
            then 'SÍ' else 'NO' end as quedo
union all
select 'reparto_deshacer, y UNA sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='reparto_deshacer') = 1
            then 'SÍ' else 'NO' end
union all
select 'reparto_recibir ya sabe descontar en bodega',
       case when pg_get_functiondef(
              (select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                where n.nspname='public' and p.proname='reparto_recibir' limit 1)
            ) like '%producto_bodega_id%' then 'SÍ' else 'NO' end;


-- ================================================================
-- BLOQUE 4 — el cuaderno. Correr SOLO si el bloque 3 dio los tres SÍ.
-- ================================================================
-- insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
-- values ('2026-08-central-reparto-descuenta.sql', 'Jhon', 'lo corrió Jhon',
--         'reparto_recibir baja el stock en bodega cuando la línea trae producto_bodega_id, y reparto_deshacer lo devuelve. No cambia nada del lado del local.')
-- on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
