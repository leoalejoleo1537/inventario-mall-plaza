-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. UNO POR UNO (los bloques 2 y 3 llevan $$ y el
--             editor se atraganta si van pegados a otra cosa).
--  TARDA:     instantáneo
--  QUÉ HACE:  agrega dos columnas al libro de movimientos y crea las dos
--             funciones de merma. NO merma nada ni mueve un solo producto.
--  QUÉ VER:   el bloque 4: tienen que salir 4 filas, las 4 en SÍ.
-- ================================================================
--
-- LA IMAGEN: esto es instalar la máquina, no usarla. Después de correrlo la
-- bodega tiene exactamente el mismo stock que ahora.
--
-- POR QUÉ UNA FUNCIÓN Y NO DOS ÓRDENES SUELTAS: mermar son dos cosas que
-- tienen que pasar juntas o no pasar — bajar el stock y anotarlo en el libro.
-- Si se hicieran por separado desde el teléfono y se cortara la señal en el
-- medio, quedaría stock bajado sin anotar (o al revés). Adentro de una
-- función son una sola operación: o las dos, o ninguna.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — DOS COLUMNAS EN EL LIBRO
--
-- `nota`         = el texto libre cuando el motivo es "otro".
-- `detalle`      = qué fechas exactas se botaron, para poder deshacer con
--                  precisión. Sin esto, deshacer la merma de un sándwich
--                  sería adivinar de qué día era.
-- `deshecha_at`  = cuándo se deshizo, si se deshizo.
-- `deshecha_por` = quién.
--
-- Deshacer NO borra la fila y TAMPOCO le pisa el motivo: si al deshacer se
-- escribiera "deshecha" encima del motivo, se perdería para siempre que esa
-- merma había sido por robo. El motivo y el haberla deshecho son dos hechos
-- distintos y cada uno tiene su columna.
-- ================================================================
alter table public.movimientos add column if not exists nota         text;
alter table public.movimientos add column if not exists detalle      jsonb;
alter table public.movimientos add column if not exists deshecha_at  timestamptz;
alter table public.movimientos add column if not exists deshecha_por text;


-- ================================================================
-- BLOQUE 2 — MERMAR  (correr este bloque SOLO)
--
-- Las tres cosas que se niega a hacer, y son a propósito:
--   · mermar fuera de la bodega  -> la regla de esta etapa, puesta en la
--     base y no solo en la pantalla, para que no dependa de un botón
--   · dejar el stock en negativo -> dice cuánto hay de verdad
--   · mermar un perecedero sin decir de qué fecha -> en un producto con
--     fechas mandan las fechas (regla 0.3.1); tocar el stock directo
--     rompería la cuenta
-- ================================================================
create or replace function public.mermar(
  p_producto_id bigint,
  p_cantidad    numeric default null,
  p_lotes       jsonb   default null,
  p_motivo      text    default null,
  p_nota        text    default null,
  p_quien       text    default null
) returns public.movimientos
language plpgsql
security definer
set search_path = public
as $$
declare
  pr        public.productos;
  lo        public.producto_lotes;
  r         jsonb;
  mv        public.movimientos;
  v_total   numeric := 0;
  v_hay     boolean;
  v_detalle jsonb := '[]'::jsonb;
begin
  select * into pr from public.productos where id = p_producto_id for update;
  if not found then
    raise exception 'Ese producto ya no existe.';
  end if;
  if pr.sede <> 'central' then
    raise exception 'Por ahora la merma solo está habilitada en la bodega.';
  end if;
  if coalesce(p_motivo,'') not in ('daño','robo','vencimiento','otro') then
    raise exception 'Falta el motivo de la merma.';
  end if;

  select exists (select 1 from public.producto_lotes
                  where producto_id = pr.id and coalesce(cantidad,0) > 0)
    into v_hay;

  if v_hay then
    -- CON FECHAS: se descuenta de las fechas y el trigger recalcula el stock
    if p_lotes is null or jsonb_array_length(p_lotes) = 0 then
      raise exception 'Este producto tiene fechas: hay que decir de qué fecha se merma.';
    end if;
    for r in select * from jsonb_array_elements(p_lotes) loop
      select * into lo from public.producto_lotes
       where id = (r->>'lote_id')::bigint and producto_id = pr.id for update;
      if not found then
        raise exception 'Una de las fechas ya no existe. Vuelve a abrir el producto.';
      end if;
      if (r->>'cantidad')::numeric > lo.cantidad then
        raise exception 'De la fecha % hay % y estás mermando %.',
          to_char(lo.vencimiento,'DD/MM/YYYY'), lo.cantidad, (r->>'cantidad')::numeric;
      end if;
      v_detalle := v_detalle || jsonb_build_object(
        'lote_id', lo.id, 'cantidad', (r->>'cantidad')::numeric, 'vencimiento', lo.vencimiento);
      v_total := v_total + (r->>'cantidad')::numeric;
      -- una fecha en cero no es una fecha: se borra (regla 0.3.1)
      if lo.cantidad - (r->>'cantidad')::numeric <= 0 then
        delete from public.producto_lotes where id = lo.id;
      else
        update public.producto_lotes
           set cantidad = cantidad - (r->>'cantidad')::numeric, updated_at = now()
         where id = lo.id;
      end if;
    end loop;
  else
    -- SIN FECHAS: se baja el stock directo
    if coalesce(p_cantidad,0) <= 0 then
      raise exception 'Falta cuánto se merma.';
    end if;
    if p_cantidad > coalesce(pr.stock_actual,0) then
      raise exception 'De % hay % y estás mermando %.',
        pr.producto, coalesce(pr.stock_actual,0), p_cantidad;
    end if;
    v_total := p_cantidad;
    update public.productos
       set stock_actual = stock_actual - p_cantidad, updated_at = now()
     where id = pr.id;
  end if;

  -- si por lo que sea la suma dio cero, no hay merma que anotar. Sin esto el
  -- error que saldría sería el de la restricción de la tabla, ilegible
  if v_total <= 0 then
    raise exception 'Falta cuánto se merma.';
  end if;

  -- el signo lleva la dirección: la merma SALE, así que va en negativo
  insert into public.movimientos
    (sede, producto_id, producto, tipo, cantidad, motivo, nota, quien, detalle)
  values ('central', pr.id, pr.producto, 'merma', -v_total, p_motivo,
          nullif(btrim(coalesce(p_nota,'')),''), p_quien,
          case when v_detalle = '[]'::jsonb then null else v_detalle end)
  returning * into mv;

  return mv;
end;
$$;

grant execute on function public.mermar(bigint,numeric,jsonb,text,text,text) to anon, authenticated;


-- ================================================================
-- BLOQUE 3 — DESHACER UNA MERMA  (correr este bloque SOLO)
--
-- Devuelve lo mermado y deja el rastro: la fila de la merma NO se borra, se
-- marca. Un libro donde se puede borrar una página no sirve de libro.
-- ================================================================
create or replace function public.deshacer_merma(
  p_movimiento_id bigint,
  p_quien         text default null
) returns public.movimientos
language plpgsql
security definer
set search_path = public
as $$
declare
  mv  public.movimientos;
  r   jsonb;
  n   bigint;
begin
  select * into mv from public.movimientos where id = p_movimiento_id for update;
  if not found then
    raise exception 'Esa merma ya no está.';
  end if;
  if mv.tipo <> 'merma' then
    raise exception 'Eso no es una merma.';
  end if;
  if mv.deshecha_at is not null then
    raise exception 'Esa merma ya se deshizo.';
  end if;

  if mv.detalle is not null then
    -- tenía fechas: se devuelve a la fecha exacta de la que salió. Si esa
    -- fecha se había quedado en cero y se borró, se vuelve a crear.
    for r in select * from jsonb_array_elements(mv.detalle) loop
      select id into n from public.producto_lotes where id = (r->>'lote_id')::bigint;
      if n is null then
        insert into public.producto_lotes (producto_id, cantidad, vencimiento)
        values (mv.producto_id, (r->>'cantidad')::numeric, (r->>'vencimiento')::date);
      else
        update public.producto_lotes
           set cantidad = cantidad + (r->>'cantidad')::numeric, updated_at = now()
         where id = n;
      end if;
    end loop;
  else
    -- no tenía fechas cuando se mermó. Si AHORA tiene, devolver al stock
    -- directo sería mentir: el trigger recalcula desde las fechas y la
    -- devolución se borraría sola en el próximo cambio. Mejor negarse.
    if exists (select 1 from public.producto_lotes
                where producto_id = mv.producto_id and coalesce(cantidad,0) > 0) then
      raise exception 'A este producto le pusieron fechas después de la merma. Devuélvelo agregando la fecha a mano.';
    end if;
    update public.productos
       set stock_actual = coalesce(stock_actual,0) + abs(mv.cantidad), updated_at = now()
     where id = mv.producto_id;
  end if;

  update public.movimientos
     set deshecha_at = now(), deshecha_por = p_quien
   where id = mv.id
  returning * into mv;

  return mv;
end;
$$;


-- ---------- permisos, igual que el resto de las funciones ----------
grant execute on function public.mermar(bigint,numeric,jsonb,text,text,text) to anon, authenticated;
grant execute on function public.deshacer_merma(bigint,text)                 to anon, authenticated;


-- ================================================================
-- BLOQUE 4 — COMPROBACIÓN — 4 filas, las 4 en SÍ
-- ================================================================
select 'columna nota en movimientos' as pieza,
       case when exists (select 1 from information_schema.columns
                          where table_schema='public' and table_name='movimientos'
                            and column_name='nota') then 'SÍ' else 'NO' end as quedo
union all
select 'columna detalle en movimientos',
       case when exists (select 1 from information_schema.columns
                          where table_schema='public' and table_name='movimientos'
                            and column_name='detalle') then 'SÍ' else 'NO' end
union all
select 'función mermar, y una sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='mermar') = 1
            then 'SÍ' else 'NO' end
union all
select 'función deshacer_merma, y una sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='deshacer_merma') = 1
            then 'SÍ' else 'NO' end;


-- ================================================================
-- BLOQUE 5 — el cuaderno. Correr SOLO si el bloque 4 dio los 4 SÍ.
-- Va aparte a propósito: si se anotara en la misma corrida, el cuaderno
-- podría quedar diciendo que algo se instaló cuando falló.
-- ================================================================
-- insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
-- values ('2026-08-central-mermas.sql', 'Jhon', 'lo corrió Jhon',
--         'Mermas de bodega: columnas nota y detalle en movimientos, funciones mermar() y deshacer_merma(). No mueve stock.')
-- on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
