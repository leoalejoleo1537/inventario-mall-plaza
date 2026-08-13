-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Los bloques 1 y 2 llevan $$: cada uno SOLO.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea las dos funciones para registrar lo que LLEGA a bodega.
--             No suma nada al instalarse.
--  QUÉ VER:   el bloque 3: 2 filas, las 2 en SÍ.
-- ================================================================
--
-- QUÉ ES: hasta ahora bodega solo sabía RESTAR — por reparto y por merma. Lo
-- que llega del proveedor no tenía dónde anotarse, así que el stock había que
-- corregirlo a mano en la ficha y no quedaba rastro de cuánto entró.
--
-- Con esto, "cuánto café entró este mes" pasa a ser una pregunta que el libro
-- puede contestar. Es la razón por la que el libro de movimientos se construyó
-- antes que las estadísticas.
--
-- LAS REGLAS QUE HACE CUMPLIR, y son de la casa:
--
-- · **Un perecedero entra SOLO por fechas** (regla 0.4). Nunca se le suma al
--   stock directo: se insertan las fechas y el trigger recalcula el stock. Si
--   llega un sándwich sin decir su fecha, se niega.
-- · **Solo en bodega.** La comprobación está en la base, no en la pantalla.
-- · **Todo queda anotado**, con quién y de qué proveedor, y se puede deshacer.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — REGISTRAR LA ENTRADA  (correr este bloque SOLO)
--
-- p_items es la lista de lo que llegó:
--   [{"producto_id":1254, "cantidad":10},
--    {"producto_id":1207, "lotes":[{"cantidad":6,"vencimiento":"2026-09-01"}]}]
-- ================================================================
create or replace function public.registrar_entrada(
  p_items     jsonb,
  p_proveedor text default null,
  p_nota      text default null,
  p_quien     text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  it       jsonb;
  lo       jsonb;
  pr       public.productos;
  v_hay    boolean;
  v_total  numeric;
  v_det    jsonb := '[]'::jsonb;
  v_mid    bigint;
begin
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'No hay nada que registrar.';
  end if;

  for it in select * from jsonb_array_elements(p_items) loop
    select * into pr from public.productos
     where id = (it->>'producto_id')::bigint for update;
    if not found then
      raise exception 'Uno de los productos ya no existe. Vuelve a abrir la pantalla.';
    end if;
    if pr.sede <> 'central' then
      raise exception 'Las entradas solo se registran en la bodega.';
    end if;

    select exists(select 1 from public.producto_lotes l
                   where l.producto_id = pr.id and coalesce(l.cantidad,0) > 0)
      into v_hay;
    v_total := 0;

    if coalesce(pr.perecedero,false) or v_hay then
      -- ---- perecedero: entra SOLO por fechas (regla 0.4) ----
      if it->'lotes' is null or jsonb_array_length(it->'lotes') = 0 then
        raise exception '"%" lleva fecha de vencimiento: hay que decir de qué fecha entra.', pr.producto;
      end if;
      for lo in select * from jsonb_array_elements(it->'lotes') loop
        if (lo->>'vencimiento') is null or (lo->>'vencimiento') = '' then
          raise exception 'Cada fecha de "%" necesita su día.', pr.producto;
        end if;
        if coalesce((lo->>'cantidad')::numeric,0) <= 0 then
          raise exception 'Cada fecha de "%" necesita una cantidad mayor que 0.', pr.producto;
        end if;
        insert into public.producto_lotes (producto_id, cantidad, vencimiento)
        values (pr.id, (lo->>'cantidad')::numeric, (lo->>'vencimiento')::date);
        v_total := v_total + (lo->>'cantidad')::numeric;
      end loop;
      -- el stock lo recalcula el trigger desde las fechas: acá NO se toca
    else
      -- ---- normal: se suma al stock ----
      v_total := coalesce((it->>'cantidad')::numeric, 0);
      if v_total <= 0 then
        raise exception 'Falta cuánto llegó de "%".', pr.producto;
      end if;
      update public.productos
         set stock_actual = coalesce(stock_actual,0) + v_total, updated_at = now()
       where id = pr.id;
    end if;

    -- el libro. El signo lleva la dirección: entra, va en positivo
    insert into public.movimientos
      (sede, producto_id, producto, tipo, cantidad, motivo, nota, quien)
    values ('central', pr.id, pr.producto, 'entrada', v_total,
            nullif(btrim(coalesce(p_proveedor,'')),''),
            nullif(btrim(coalesce(p_nota,'')),''), p_quien)
    returning id into v_mid;

    v_det := v_det || jsonb_build_object(
      'producto', pr.producto, 'cantidad', v_total, 'movimiento_id', v_mid);
  end loop;

  return jsonb_build_object('lineas', jsonb_array_length(p_items), 'detalle', v_det);
end;
$$;

grant execute on function public.registrar_entrada(jsonb,text,text,text) to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — DESHACER UNA ENTRADA  (correr este bloque SOLO)
--
-- Saca lo que había entrado. Se niega si ya se movió: si el producto tiene
-- menos de lo que entró, alguien ya lo repartió o lo mermó, y sacarlo dejaría
-- un número inventado. Ahí se corrige contando.
-- ================================================================
create or replace function public.deshacer_entrada(
  p_movimiento_id bigint,
  p_quien         text default null
) returns public.movimientos
language plpgsql
security definer
set search_path = public
as $$
declare
  mv    public.movimientos;
  v_hay numeric;
begin
  select * into mv from public.movimientos where id = p_movimiento_id for update;
  if not found then raise exception 'Esa entrada ya no está.'; end if;
  if mv.tipo <> 'entrada' then raise exception 'Eso no es una entrada.'; end if;
  if mv.deshecha_at is not null then raise exception 'Esa entrada ya se deshizo.'; end if;

  if exists (select 1 from public.producto_lotes l
              where l.producto_id = mv.producto_id and coalesce(l.cantidad,0) > 0) then
    raise exception 'Este producto entró por fechas. Quita la fecha desde la ficha del producto.';
  end if;

  select coalesce(stock_actual,0) into v_hay
    from public.productos where id = mv.producto_id for update;
  if v_hay < mv.cantidad then
    raise exception 'No se puede deshacer: quedan % y habían entrado %. Ya se movió parte. Corrige contando.',
      v_hay, mv.cantidad;
  end if;

  update public.productos
     set stock_actual = v_hay - mv.cantidad, updated_at = now()
   where id = mv.producto_id;

  update public.movimientos
     set deshecha_at = now(), deshecha_por = p_quien
   where id = mv.id
  returning * into mv;

  return mv;
end;
$$;

grant execute on function public.deshacer_entrada(bigint,text) to anon, authenticated;


-- ================================================================
-- BLOQUE 3 — COMPROBACIÓN — 2 filas, las 2 en SÍ
-- ================================================================
select 'registrar_entrada, y UNA sola firma' as pieza,
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='registrar_entrada') = 1
            then 'SÍ' else 'NO' end as quedo
union all
select 'deshacer_entrada, y UNA sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='deshacer_entrada') = 1
            then 'SÍ' else 'NO' end;
