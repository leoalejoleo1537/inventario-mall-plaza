-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. El 1 SOLO (lleva $$). Después el 2 y el 3.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea UNA función, la que crea un producto en bodega y en las
--             sedes que elijas y los deja enlazados. No crea ningún
--             producto ahora: instala la herramienta.
--  QUÉ VER:   el bloque 2: 2 filas, las 2 en SÍ.
-- ================================================================
--
-- POR QUÉ UNA FUNCIÓN Y NO VARIAS ÓRDENES DESDE EL TELÉFONO: crear la torta
-- en bodega, crearla en Mall Plaza y anotar el enlace son tres cosas que
-- tienen que pasar juntas. Si se hicieran por separado y se cortara la señal
-- en el medio, quedaría un producto suelto en Plaza que nadie pidió y sin
-- gemelo — un duplicado, que es lo que obliga a las jefas a contar dos veces
-- lo mismo. Adentro de una función son una sola operación.
--
-- LAS CUATRO COSAS QUE SE NIEGA A HACER:
--   · crear fuera de central / plaza / angamos
--   · crear un producto sin nombre
--   · duplicar: si el nombre ya existe en esa sede, lo REUTILIZA y solo enlaza
--   · resucitar: si existe pero está APAGADO, se detiene y avisa. Eliminar en
--     esta app desactiva, no borra — y revivir a la fuerza algo que el equipo
--     apagó a propósito es la forma silenciosa de crear el duplicado (§0.6.3)
--
-- LO QUE NUNCA HACE: borrar, apagar, renombrar ni tocar el stock de nada que
-- ya exista en Plaza o Angamos. Solo agrega.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA FUNCIÓN  (correr este bloque SOLO)
-- ================================================================
create or replace function public.crear_producto_enlazado(
  p_nombre     text,
  p_seccion    text,
  p_min        numeric default null,
  p_max        numeric default null,
  p_perecedero boolean default false,
  p_destinos   jsonb   default '[]'::jsonb,
  p_quien      text    default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nombre text := btrim(coalesce(p_nombre,''));
  v_bid    bigint;
  v_sid    bigint;
  v_act    text;
  v_sede   text;
  v_rubro  text;
  v_estado text;
  r        jsonb;
  v_det    jsonb := '[]'::jsonb;
begin
  if v_nombre = '' then
    raise exception 'Falta el nombre del producto.';
  end if;

  -- ---------- 1) en bodega ----------
  -- la búsqueda NO filtra por activo: si está apagado hay que saberlo, no
  -- pasarle por encima creando otro igual
  select id, activo into v_bid, v_act
    from public.productos
   where sede='central' and clave_nombre(producto) = clave_nombre(v_nombre)
   order by id limit 1;

  if v_bid is not null and v_act <> 'SÍ' then
    raise exception 'En Bodega ya existe "%" pero está apagado. Actívalo desde el inventario o usa otro nombre.', v_nombre;
  end if;

  if v_bid is null then
    insert into public.productos
      (sede, producto, rubro, stock_actual, stock_min, stock_max, activo, perecedero)
    values ('central', v_nombre, nullif(btrim(coalesce(p_seccion,'')),''),
            0, p_min, p_max, 'SÍ', coalesce(p_perecedero,false))
    returning id into v_bid;
    v_det := v_det || jsonb_build_object('sede','central','estado','creado','id',v_bid);
  else
    v_det := v_det || jsonb_build_object('sede','central','estado','ya existía','id',v_bid);
  end if;

  -- ---------- 2) cada sede de destino ----------
  for r in select * from jsonb_array_elements(coalesce(p_destinos,'[]'::jsonb)) loop
    v_sede  := r->>'sede';
    v_rubro := nullif(btrim(coalesce(r->>'rubro','')),'');

    if v_sede is null or v_sede not in ('plaza','angamos') then
      raise exception 'Solo se puede crear en Mall Plaza o Parque Angamos.';
    end if;

    select id, activo into v_sid, v_act
      from public.productos
     where sede = v_sede and clave_nombre(producto) = clave_nombre(v_nombre)
     order by id limit 1;

    if v_sid is not null and v_act <> 'SÍ' then
      raise exception 'En % ya existe "%" pero está apagado. Actívalo desde esa sede o usa otro nombre.', v_sede, v_nombre;
    end if;

    if v_sid is null then
      -- el mínimo y el máximo NO se copian: son de la repisa de bodega y en el
      -- local significan otra cosa. Los pone el local cuando cuente
      insert into public.productos
        (sede, producto, rubro, stock_actual, stock_min, stock_max, activo, perecedero)
      values (v_sede, v_nombre, v_rubro, 0, null, null, 'SÍ', coalesce(p_perecedero,false))
      returning id into v_sid;
      v_estado := 'creado';
    else
      v_estado := 'ya existía';
    end if;

    -- el enlace. Si ya estaba, no se duplica ni se pisa
    insert into public.producto_enlace
      (producto_bodega_id, sede, producto_sede_id, factor, creado_por)
    values (v_bid, v_sede, v_sid, 1, coalesce(p_quien,'desde bodega'))
    on conflict do nothing;

    v_det := v_det || jsonb_build_object('sede',v_sede,'estado',v_estado,'id',v_sid);
  end loop;

  return jsonb_build_object('bodega_id', v_bid, 'detalle', v_det);
end;
$$;

grant execute on function public.crear_producto_enlazado(text,text,numeric,numeric,boolean,jsonb,text)
  to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — COMPROBACIÓN — 2 filas, las 2 en SÍ
-- ================================================================
select 'función crear_producto_enlazado, y una sola firma' as pieza,
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='crear_producto_enlazado') = 1
            then 'SÍ' else 'NO' end as quedo
union all
select 'la función de comparar nombres sigue puesta',
       case when to_regprocedure('public.clave_nombre(text)') is not null then 'SÍ' else 'NO' end;


-- ================================================================
-- BLOQUE 3 — el cuaderno. Correr SOLO si el bloque 2 dio los dos SÍ.
-- ================================================================
-- insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
-- values ('2026-08-central-enlaces.sql', 'Jhon', 'lo corrió Jhon',
--         'Función crear_producto_enlazado: crea un producto en bodega y en las sedes elegidas y los enlaza, en una sola operación. No crea nada al instalarse.')
-- on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
