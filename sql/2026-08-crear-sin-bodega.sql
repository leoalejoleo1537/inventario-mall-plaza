-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque (pégalo entero y aprieta Run)
--  TARDA:     instantáneo
--  QUÉ HACE:  deja crear un producto SIN crearlo también en Bodega.
--             No toca ningún dato: solo reemplaza una función.
--  QUÉ VER:   la última consulta deja 2 filas, las 2 tienen que decir SÍ.
-- ================================================================
--
-- QUÉ ESTABA MAL
--
-- La función obligaba a que todo producto naciera en Bodega. En el caso que
-- lo destapó —el "Alfajor Brownie vitrina" de Mall Plaza— eso no tiene
-- sentido: en bodega ya existe UN "Alfajor Brownie", y lo que falta es el
-- segundo mueble del local. Crear un tercer producto en bodega sería
-- inventar un duplicado justo en la sede que estamos tratando de mantener
-- limpia.
--
-- La regla no era falsa: casi todo lo que se crea SÍ nace en bodega. El
-- error fue convertir "casi siempre" en "siempre".
--
-- CÓMO QUEDA, y por qué así
--
-- Bodega pasa a ser UN DESTINO MÁS dentro de `p_destinos`, igual que Plaza y
-- Angamos. No se agrega un parámetro nuevo: LA FIRMA NO CAMBIA.
--
-- Esa decisión es a propósito y sale de la falla del 27 de julio (§0.5). Al
-- cambiar la firma de una función que ya vive en producción quedan dos
-- versiones conviviendo, y la llamada desde la app —que va por la API— se
-- vuelve ambigua y se rechaza antes de ejecutar nada. El sistema estuvo 15
-- horas sin descontar por eso. Metiendo el destino en el arreglo que ya
-- existe, ese riesgo no aparece.
--
-- Y de yapa queda más flexible: el día que haya otra sede, es un elemento
-- más en la lista, no otro parámetro.
--
-- EL ENLACE, cuando no hay bodega
--
-- Si el producto no se crea en bodega, no se escribe ningún enlace — no hay
-- de dónde bajar. Eso NO es un hueco: es exactamente lo que dice §0.66 (un
-- producto puede venir de un proveedor y no bajarle nada a nadie) y §0.7 (de
-- un par vitrina/congelador, el enlace vive en el del congelador, que es
-- donde aterriza el reparto).
--
-- LO QUE SIGUE PROTEGIDO, y no se toca:
--   · si el producto ya existe APAGADO, se detiene y avisa (no lo revive)
--   · el mínimo y el máximo no se copian al local
--   · el stock nace en 0
--   · el enlace no se duplica ni se pisa
--   · y ahora además: hay que elegir al menos un lugar
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
  v_nombre    text := btrim(coalesce(p_nombre,''));
  v_dest      jsonb := coalesce(p_destinos,'[]'::jsonb);
  v_en_bodega boolean;
  v_bid       bigint;
  v_sid       bigint;
  v_act       text;
  v_sede      text;
  v_rubro     text;
  v_estado    text;
  r           jsonb;
  v_det       jsonb := '[]'::jsonb;
begin
  if v_nombre = '' then
    raise exception 'Falta el nombre del producto.';
  end if;

  if jsonb_array_length(v_dest) = 0 then
    raise exception 'Elige al menos un lugar donde crearlo.';
  end if;

  select coalesce(bool_or(e->>'sede' = 'central'), false)
    into v_en_bodega
    from jsonb_array_elements(v_dest) e;

  -- ---------- 1) en bodega, SI SE PIDIÓ ----------
  -- la búsqueda NO filtra por activo: si está apagado hay que saberlo, no
  -- pasarle por encima creando otro igual
  if v_en_bodega then
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
  end if;

  -- ---------- 2) cada sede de destino ----------
  for r in select * from jsonb_array_elements(v_dest) loop
    v_sede  := r->>'sede';
    continue when v_sede = 'central';            -- ya se hizo arriba
    v_rubro := nullif(btrim(coalesce(r->>'rubro','')),'');

    if v_sede is null or v_sede not in ('plaza','angamos') then
      raise exception 'Solo se puede crear en Bodega, Mall Plaza o Parque Angamos.';
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

    -- el enlace, SOLO si hay un producto de bodega del cual bajar.
    -- Sin bodega no hay origen, y eso es una decisión válida (§0.66), no un
    -- hueco: el producto sube en la sede y no le baja nada a nadie.
    if v_bid is not null then
      insert into public.producto_enlace
        (producto_bodega_id, sede, producto_sede_id, factor, creado_por)
      values (v_bid, v_sede, v_sid, 1, coalesce(p_quien,'desde bodega'))
      on conflict do nothing;
    end if;

    v_det := v_det || jsonb_build_object('sede',v_sede,'estado',v_estado,'id',v_sid);
  end loop;

  return jsonb_build_object('bodega_id', v_bid, 'detalle', v_det);
end;
$$;

grant execute on function public.crear_producto_enlazado(text,text,numeric,numeric,boolean,jsonb,text)
  to anon, authenticated;

insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-crear-sin-bodega.sql', 'Jhon', 'lo corrió Jhon',
        'Bodega pasa a ser un destino más: se puede crear un producto solo en una sede. Misma firma, para no dejar dos funciones conviviendo')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;

-- ================================================================
-- COMPROBACIÓN — 2 filas, las 2 tienen que decir SÍ
-- ================================================================
select 'una sola firma de crear_producto_enlazado' as pieza,
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='crear_producto_enlazado') = 1
            then 'SÍ' else 'NO (mal: hay dos conviviendo)' end as quedo
union all
select 'ya sabe crear sin bodega',
       case when (select pg_get_functiondef(p.oid) from pg_proc p
                    join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='crear_producto_enlazado'
                   limit 1) like '%v_en_bodega%'
            then 'SÍ' else 'NO (quedó la versión vieja)' end;
