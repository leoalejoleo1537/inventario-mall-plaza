--  DÓNDE VA:  Supabase -> SQL Editor -> New query
--  ES:        2 bloques. El bloque 1 lleva $$: va SOLO.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea el motor del botón "Descontar de bodega" que aparece en
--             cada lista de reparto. Al instalarse NO mueve ni un producto.
--  QUÉ VER:   el bloque 2: 2 filas, las 2 en SÍ.
-- ================================================================
--
-- EL PROBLEMA QUE RESUELVE, contado por Jhon el 2026-08-22: Adriana armó
-- varios repartos desde la pantalla de la SEDE en vez de desde Bodega ->
-- Enviar, creyendo que igual se iba a descontar de bodega. No se descontó.
-- El local sumó de verdad; bodega nunca se enteró.
--
-- POR QUÉ PASA. `repartos.origen` dice "Bodega" por defecto en toda fila
-- nueva, la haya armado quien la haya armado: ese campo no prueba nada. Lo
-- único que decide si bodega baja es que la LÍNEA traiga
-- `producto_bodega_id`, y eso solo lo pone la pantalla de Bodega.
--
-- LA SOLUCIÓN ES DE JHON, y es mejor que la que yo había empezado: en vez
-- de un script retroactivo que corrija todo de una, un BOTÓN en cada lista.
-- Se ve qué lista es, se mira la vista previa, se aprieta. Una por una y a
-- la vista, en vez de una corrida a ciegas sobre meses de historial.
--
-- TRES CUIDADOS, y son los de siempre:
--
-- · **Idempotente.** Cada bajada queda anotada en `movimientos` con el id
--   de esa línea del reparto. Antes de tocar una línea se comprueba si ya
--   tiene su anotación; si la tiene, se salta. Apretar el botón dos veces
--   no descuenta dos veces. Es el mismo seguro que el motor de Fudo.
-- · **Nunca negativo** (regla 0.2). Si a bodega le faltan unidades, baja
--   hasta 0 y el resto queda anotado como `ajuste` — no se inventa un
--   número negativo ni se corrige a ojo.
-- · **Solo lo que tiene enlace.** Sin enlace no se sabe de qué producto de
--   bodega bajar, así que esa línea no se toca y se cuenta aparte. Se
--   arregla en Bodega -> Enlaces y después se vuelve a apretar el botón.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL MOTOR  (correr este bloque SOLO)
-- ================================================================

-- El script se basta solo: si la columna del origen todavía no existe
-- —porque falta correr el SQL de Angamos -> Plaza— la crea acá (§0.1.2).
alter table public.reparto_items
  add column if not exists producto_origen_id bigint references public.productos(id);

drop function if exists public.reparto_descontar_bodega(bigint);
drop function if exists public.reparto_descontar_bodega(bigint, text);

create or replace function public.reparto_descontar_bodega(
  p_reparto_id bigint,
  p_quien      text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  -- OJO: la variable del loop NO puede llamarse igual que el alias de la
  -- consulta de adentro. Con los dos como "ri", Postgres intenta resolver
  -- ri.id contra la variable de PL/pgSQL y falla con "record is not
  -- assigned yet". Por eso acá se llama "fila".
  fila     record;
  v_bod    public.productos;
  v_baja   numeric;
  v_lotes  boolean;
  v_hay    numeric;
  n_lineas int := 0;
  n_falto  numeric := 0;
  n_total  numeric := 0;
begin
  for fila in
    select ri.id as item_id, ri.cantidad_recibida, ri.resuelto_por, pe.producto_bodega_id
      from public.reparto_items ri
      join public.repartos r on r.id = ri.reparto_id
      join public.producto_enlace pe
        on pe.sede = r.sede and pe.producto_sede_id = ri.producto_id
     where ri.reparto_id = p_reparto_id
       and ri.estado = 'recibido'
       and coalesce(ri.cantidad_recibida,0) > 0
       and ri.producto_bodega_id is null
       and ri.producto_origen_id is null
       and not exists (
         select 1 from public.movimientos m
          where m.reparto_item_id = ri.id
            and m.motivo = 'se descontó de bodega desde la lista')
  loop
    select * into v_bod from public.productos where id = fila.producto_bodega_id for update;
    if not found then continue; end if;

    -- Con fechas se descuenta por fecha y el trigger recalcula el stock
    -- (regla 0.3.1): nunca se toca el stock directo de un perecedero.
    select exists(select 1 from public.producto_lotes l
                   where l.producto_id = v_bod.id and coalesce(l.cantidad,0) > 0)
      into v_lotes;

    if v_lotes then
      select coalesce(sum(cantidad),0) into v_hay
        from public.producto_lotes where producto_id = v_bod.id;
      v_baja := least(fila.cantidad_recibida, greatest(v_hay,0));
      if v_baja > 0 then perform public.descontar_lotes(v_bod.id, v_baja); end if;
    else
      v_baja := least(fila.cantidad_recibida, greatest(coalesce(v_bod.stock_actual,0),0));
      if v_baja > 0 then
        update public.productos
           set stock_actual = coalesce(stock_actual,0) - v_baja
         where id = v_bod.id;
      end if;
    end if;

    if v_baja > 0 then
      insert into public.movimientos
        (sede, producto_id, producto, tipo, cantidad, motivo, reparto_item_id, quien)
      values ('central', v_bod.id, v_bod.producto, 'salida', -v_baja,
              'se descontó de bodega desde la lista', fila.item_id,
              coalesce(p_quien, fila.resuelto_por));
      n_lineas := n_lineas + 1;
      n_total  := n_total + v_baja;
    end if;

    -- Lo que bodega no alcanzó a cubrir queda anotado en vez de inventarse.
    if v_baja < fila.cantidad_recibida then
      insert into public.movimientos
        (sede, producto_id, producto, tipo, cantidad, motivo, reparto_item_id, quien)
      values ('central', v_bod.id, v_bod.producto, 'ajuste',
              (fila.cantidad_recibida - v_baja),
              'se descontó de bodega desde la lista', fila.item_id,
              coalesce(p_quien, fila.resuelto_por));
      n_falto := n_falto + (fila.cantidad_recibida - v_baja);
    end if;
  end loop;

  return jsonb_build_object(
    'lineas',   n_lineas,
    'unidades', n_total,
    'falto',    n_falto);
end;
$$;

grant execute on function public.reparto_descontar_bodega(bigint, text) to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — COMPROBAR  (este bloque no lleva $$)
-- Las 2 filas tienen que decir SÍ.
-- ================================================================
select 'la función existe, y una sola firma' as pieza,
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='reparto_descontar_bodega') = 1
            then 'SÍ' else 'NO — hay dos, hay que borrar la vieja' end as ok
union all
select 'la columna del origen existe',
       case when exists(select 1 from information_schema.columns
                         where table_schema='public' and table_name='reparto_items'
                           and column_name='producto_origen_id')
            then 'SÍ' else 'NO' end;

-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-descontar-de-bodega-por-lista.sql', 'Jhon', 'lo corrió Jhon',
        'Motor del botón "Descontar de bodega" de cada lista de reparto. Idempotente, nunca negativo, solo lo que tiene enlace.')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
