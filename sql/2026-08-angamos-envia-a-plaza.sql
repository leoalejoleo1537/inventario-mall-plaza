-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Los bloques 2 y 3 llevan $$: cada uno SOLO.
--  TARDA:     instantáneo
--  QUÉ HACE:  deja que una sede le mande productos a otra (Angamos -> Plaza).
--             No mueve ni un producto al instalarse.
--  QUÉ VER:   el bloque 4: 3 filas, las 3 en SÍ.
-- ================================================================
--
-- POR QUÉ, en una frase de Jhon (2026-08-22): "cuando una torta está a punto
-- de vencerse o un sandwichito, este es enviado a mall plaza". Angamos vende
-- menos y Plaza tiene alto flujo, así que Angamos hace de bodega chica.
--
-- ================================================================
-- LA DECISIÓN DE DISEÑO, Y ES LA QUE HAY QUE ENTENDER
--
-- `reparto_items` ya tenía `producto_bodega_id`: "de cuál producto hay que
-- descontar al confirmar". Ese mecanismo sirve tal cual para Angamos — lo que
-- NO sirve es el nombre. Una columna que diga "bodega" y a veces guarde un
-- producto de Angamos es exactamente la trampa que costó el incidente del 9
-- de agosto: una misma palabra significando dos cosas según el día, y alguien
-- teniendo que adivinar cuál.
--
-- Entonces se agrega `producto_origen_id`, con el nombre honesto, y la función
-- mira `coalesce(producto_origen_id, producto_bodega_id)`. Los repartos que ya
-- existen no se tocan y siguen funcionando igual.
--
-- Y se corrige algo que hasta hoy estaba escrito a mano: el libro de
-- movimientos anotaba `'central'` fijo. Ahora anota **la sede donde vive el
-- producto que bajó**, que para bodega da el mismo resultado de siempre y para
-- Angamos dice la verdad.
--
-- LO QUE NO CAMBIA, y es a propósito: el jefe de turno de Plaza recibe esto
-- con la MISMA pantalla de siempre. Para él es un reparto más. Así lo pidió
-- Jhon: "tiene que enviarse a reparto de Mall Plaza, tiene que ser
-- recepcionada, y una vez recepcionada sí va a ejecutarse tanto la suma en
-- Mall Plaza como la resta en Angamos".
--
-- LO QUE ESTE SCRIPT NO HACE: bajarle el stock a Fudo en Angamos. Eso lo hace
-- la app al confirmar, con `fudo-empujar-stock`, que manda el valor absoluto y
-- se corrige solo en la corrida siguiente. Ponerlo acá obligaría a la base a
-- salir a internet, que es justo lo que este proyecto nunca hace.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA COLUMNA  (este bloque no lleva $$)
-- ================================================================
alter table public.reparto_items
  add column if not exists producto_origen_id bigint references public.productos(id);

comment on column public.reparto_items.producto_origen_id is
  'De qué producto (y por lo tanto de qué sede) hay que descontar al confirmar. Para envios de una sede a otra. Si esta en null se usa producto_bodega_id, que es el camino de bodega.';


-- ================================================================
-- BLOQUE 2 — RECIBIR  (correr este bloque SOLO)
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
  -- de dónde sale: bodega o la otra sede
  v_orig_id   bigint;
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

  -- ---------- BAJA EN EL ORIGEN ----------
  -- Solo si el envío salió de algún lado: de bodega (`producto_bodega_id`) o
  -- de otra sede (`producto_origen_id`). Los repartos armados DENTRO del local
  -- no traen ninguna de las dos y no descuentan nada, igual que siempre.
  -- `producto_origen_id` manda; si no está, es el camino de bodega de siempre
  v_orig_id := coalesce(it.producto_origen_id, it.producto_bodega_id);
  if v_orig_id is not null and v_total > 0 then
    select * into v_bod from public.productos
     where id = v_orig_id for update;
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
        -- la sede del PRODUCTO que bajó, no 'central' escrito a mano
        values (v_bod.sede, v_bod.id, v_bod.producto, 'salida', -v_baja, v_sede,
                'reparto', it.id, p_quien);
      end if;
      -- si bodega no alcanzaba, queda anotado en vez de inventar el número
      if v_baja < v_total then
        insert into public.movimientos
          (sede, producto_id, producto, tipo, cantidad, sede_contraparte, motivo,
           reparto_item_id, quien)
        values (v_bod.sede, v_bod.id, v_bod.producto, 'ajuste', (v_total - v_baja), v_sede,
                'faltó en el origen al confirmar el reparto', it.id, p_quien);
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


-- ================================================================
-- BLOQUE 3 — DESHACER  (correr este bloque SOLO)
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
  v_orig_id bigint;
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

    -- ---------- DEVOLVER AL ORIGEN ----------
    v_orig_id := coalesce(it.producto_origen_id, it.producto_bodega_id);
    if v_orig_id is not null then
      /* Cuánto se le había sacado de verdad (puede ser menos de lo confirmado,
         si el origen no alcanzaba).

         Se busca por PRODUCTO y no por sede. Antes decía `sede='central'`
         escrito a mano, y con un envío de Angamos esa consulta daba 0: se le
         devolvía el stock a Plaza y a Angamos no se le devolvía nada. Lo
         atrapó la prueba local, no la lectura — el filtro se veía inofensivo.
         Por producto además es más preciso de lo que la sede fue nunca. */
      select coalesce(-sum(cantidad),0) into v_dev
        from public.movimientos
       where reparto_item_id = it.id and tipo='salida' and producto_id = v_orig_id;

      if v_dev > 0 then
        select * into v_bod from public.productos where id = v_orig_id for update;
        if found then
          select exists(select 1 from public.producto_lotes l
                         where l.producto_id = v_bod.id) into v_lotes;
          if v_lotes then
            -- con fechas no se puede saber a qué día volvían las unidades.
            -- El deshacer NO se bloquea: queda anotado para corregir contando.
            insert into public.movimientos
              (sede, producto_id, producto, tipo, cantidad, motivo, reparto_item_id)
            values (v_bod.sede, v_bod.id, v_bod.producto, 'ajuste', v_dev,
                    'se deshizo un reparto: hay que devolver estas unidades a su fecha a mano', it.id);
          else
            update public.productos
               set stock_actual = coalesce(stock_actual,0) + v_dev, updated_at = now()
             where id = v_bod.id;
            insert into public.movimientos
              (sede, producto_id, producto, tipo, cantidad, motivo, reparto_item_id)
            values (v_bod.sede, v_bod.id, v_bod.producto, 'entrada', v_dev,
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
-- BLOQUE 4 — COMPROBAR  (este bloque no lleva $$)
-- Las 3 filas tienen que decir SÍ.
-- ================================================================
select 'la columna del origen existe' as pieza,
       case when exists(select 1 from information_schema.columns
                         where table_schema='public' and table_name='reparto_items'
                           and column_name='producto_origen_id') then 'SÍ' else 'NO' end as ok
union all
select 'reparto_recibir, y UNA sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='reparto_recibir') = 1
            then 'SÍ' else 'NO — hay dos, hay que borrar la vieja' end
union all
select 'ya sabe descontar de otra sede',
       case when (select pg_get_functiondef(p.oid) from pg_proc p
                    join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='reparto_recibir' limit 1)
                 like '%producto_origen_id%'
            then 'SÍ' else 'NO — quedó instalada la versión vieja' end;
