-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. UNO POR UNO, en orden.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea los envíos a franquicias, que salen de bodega y NO
--             llegan a ninguna app.
--  QUÉ VER:   el bloque 4 tiene que mostrar las 5 franquicias.
-- ================================================================
--
-- QUÉ SON LAS FRANQUICIAS, Y POR QUÉ NO PUEDEN USAR EL REPARTO DE SIEMPRE.
--
-- Adriana también le manda producto a cafés que NO tienen Llamita. Del otro
-- lado no hay nadie que confirme nada: la lista se arma acá, alguien de
-- bodega la prepara, y lo que sale se descuenta acá mismo.
--
-- El reparto normal no sirve para esto, y no es un capricho: cada línea de
-- un reparto **obliga** a apuntar a un producto de la sede que recibe
-- (`producto_id` con llave foránea). Una franquicia no tiene productos en
-- esta base, así que no hay a qué apuntar. Forzarlo —apuntando al producto
-- de bodega— haría que al confirmar se SUMARA en bodega en vez de restar:
-- exactamente al revés.
--
-- Por eso van en tablas propias. Cuesta dos tablas y no toca ni una línea
-- del reparto que hoy funciona todos los días, que a cinco días de la
-- entrega vale más que ahorrarse el espacio.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LAS DOS TABLAS
-- QUÉ VER: "Success". No devuelve filas.
-- ================================================================
create table if not exists public.envios_franquicia (
  id             bigserial primary key,
  franquicia     text not null,                      -- el nombre tal cual se muestra
  estado         text not null default 'abierto',    -- abierto | despachado
  creado_por     text,
  created_at     timestamptz not null default now(),
  despachado_por text,
  despachado_at  timestamptz,
  constraint envios_franquicia_estado_ok check (estado in ('abierto','despachado'))
);
create index if not exists envios_franquicia_estado_idx
  on public.envios_franquicia(estado, created_at desc);

create table if not exists public.envios_franquicia_items (
  id               bigserial primary key,
  envio_id         bigint  not null references public.envios_franquicia(id) on delete cascade,
  -- apunta al producto de BODEGA: es de donde sale. El id manda; el nombre se
  -- guarda para que el historial se siga leyendo aunque después lo renombren.
  producto_id      bigint  not null references public.productos(id),
  producto         text    not null,
  cantidad_pedida  numeric not null default 0,
  estado           text    not null default 'pendiente',  -- pendiente | listo | no_hay
  cantidad_enviada numeric,
  resuelto_por     text,
  resuelto_at      timestamptz,
  constraint envios_franq_items_estado_ok check (estado in ('pendiente','listo','no_hay'))
);
create index if not exists envios_franquicia_items_envio_idx
  on public.envios_franquicia_items(envio_id);

alter table public.envios_franquicia       enable row level security;
alter table public.envios_franquicia_items enable row level security;
drop policy if exists "envios_franquicia all"       on public.envios_franquicia;
drop policy if exists "envios_franquicia_items all" on public.envios_franquicia_items;
create policy "envios_franquicia all"       on public.envios_franquicia
  for all to anon, authenticated using (true) with check (true);
create policy "envios_franquicia_items all" on public.envios_franquicia_items
  for all to anon, authenticated using (true) with check (true);
grant all on public.envios_franquicia       to anon, authenticated;
grant all on public.envios_franquicia_items to anon, authenticated;
grant usage, select on sequence public.envios_franquicia_id_seq       to anon, authenticated;
grant usage, select on sequence public.envios_franquicia_items_id_seq to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — LA FUNCIÓN QUE DESCUENTA  (otro Run)
--
-- Se llama UNA VEZ POR LÍNEA, cuando alguien de bodega marca que la preparó.
-- Hace las dos cosas —bajar el stock y anotar la línea— adentro de la misma
-- llamada: si fueran dos y se cortara la señal en el medio, quedaría stock
-- bajado sin anotar, o anotado sin bajar.
--
-- ⚠️ Este bloque lleva el símbolo $, así que **se corre SOLO**, sin nada más
-- pegado antes ni después. El editor de Supabase se atraganta si no.
--
-- QUÉ VER: "Success".
-- ================================================================
create or replace function public.franquicia_linea_lista(
  p_item  bigint,
  p_cant  numeric,
  p_quien text
) returns jsonb
language plpgsql
security definer
as $fn$
declare
  it   public.envios_franquicia_items;
  prod public.productos;
  nuevo numeric;
begin
  -- se bloquea la línea: dos teléfonos marcando lo mismo a la vez no
  -- pueden descontar dos veces
  select * into it from public.envios_franquicia_items
   where id = p_item for update;
  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'esa línea ya no existe');
  end if;
  if it.estado <> 'pendiente' then
    return jsonb_build_object('ok', false, 'motivo', 'esa línea ya estaba resuelta');
  end if;

  select * into prod from public.productos where id = it.producto_id for update;
  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'el producto ya no está en bodega');
  end if;

  -- el tope en cero es la regla dura del proyecto: no se baja de ahí ni acá
  nuevo := greatest(0, coalesce(prod.stock_actual,0) - greatest(0, coalesce(p_cant,0)));

  update public.productos
     set stock_actual = nuevo, updated_at = now()
   where id = it.producto_id;

  update public.envios_franquicia_items
     set estado = 'listo', cantidad_enviada = greatest(0, coalesce(p_cant,0)),
         resuelto_por = p_quien, resuelto_at = now()
   where id = p_item;

  -- Queda en el libro de movimientos, igual que una merma o una entrada.
  -- La cantidad va en NEGATIVO porque en ese libro el signo es la dirección:
  -- "+ entra · − sale". Copiado de cómo lo escribe `mermar`, no de memoria.
  insert into public.movimientos
    (sede, producto_id, producto, tipo, cantidad, motivo, sede_contraparte, nota, quien)
  values ('central', it.producto_id, it.producto, 'salida',
          -greatest(0, coalesce(p_cant,0)), 'franquicia',
          (select franquicia from public.envios_franquicia where id = it.envio_id),
          null, p_quien);

  return jsonb_build_object('ok', true, 'stock_nuevo', nuevo);
end;
$fn$;


-- ================================================================
-- BLOQUE 3 — MARCAR UNA LÍNEA COMO "NO HAY"  (otro Run, lleva $)
--
-- No descuenta nada: solo deja constancia de que esa línea no salió, para
-- que el resumen que se le manda a la franquicia lo diga.
--
-- QUÉ VER: "Success".
-- ================================================================
create or replace function public.franquicia_linea_no_hay(
  p_item  bigint,
  p_quien text
) returns jsonb
language plpgsql
security definer
as $fn$
declare it public.envios_franquicia_items;
begin
  select * into it from public.envios_franquicia_items where id = p_item for update;
  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'esa línea ya no existe');
  end if;
  if it.estado <> 'pendiente' then
    return jsonb_build_object('ok', false, 'motivo', 'esa línea ya estaba resuelta');
  end if;
  update public.envios_franquicia_items
     set estado = 'no_hay', cantidad_enviada = 0,
         resuelto_por = p_quien, resuelto_at = now()
   where id = p_item;
  return jsonb_build_object('ok', true);
end;
$fn$;

grant execute on function public.franquicia_linea_lista(bigint, numeric, text) to anon, authenticated;
grant execute on function public.franquicia_linea_no_hay(bigint, text)         to anon, authenticated;


-- ================================================================
-- BLOQUE 4 — COMPROBAR  (otro Run)
--
-- QUÉ VER: las dos funciones y las dos tablas. Si falta alguna, el bloque
-- que la crea no llegó a correr.
-- ================================================================
select 'tabla envios_franquicia'       as pieza,
       case when to_regclass('public.envios_franquicia')       is not null then '✅' else '❌' end as estado
union all
select 'tabla envios_franquicia_items',
       case when to_regclass('public.envios_franquicia_items') is not null then '✅' else '❌' end
union all
select 'función franquicia_linea_lista',
       case when exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                         where n.nspname='public' and p.proname='franquicia_linea_lista')
            then '✅' else '❌' end
union all
select 'función franquicia_linea_no_hay',
       case when exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                         where n.nspname='public' and p.proname='franquicia_linea_no_hay')
            then '✅' else '❌' end;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-franquicias.sql', 'Jhon', 'lo corrió Jhon',
        'Envíos a franquicias sin Llamita: tablas propias y funciones que descuentan de bodega. No toca el reparto de los locales')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
