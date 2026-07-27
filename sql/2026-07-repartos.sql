-- ================================================================
-- REPARTOS — la lista de Adriana se confirma en la app (julio 2026)
--
-- Problema que resuelve: hoy Adriana manda la lista por WhatsApp, los
-- jefes de turno comparan contra lo que llegó, lo guardan… y después
-- tienen que TRANSCRIBIR todo a la app. Ese traspaso es el doble trabajo.
--
-- Ahora: Adriana arma el reparto acá, y el jefe de turno solo confirma
-- lo que llegó. Cada confirmación suma al inventario en el momento.
--
-- Durante un día llegan varios repartos distintos (bodega / proveedor de
-- tortas / emergencia), por eso cada uno lleva su ORIGEN.
--
-- QUÉ CREA: dos tablas nuevas (repartos, reparto_items) y cuatro
-- funciones. No modifica ni borra nada de lo que ya existe.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Es idempotente.
-- ================================================================

-- ---------- 1) El envío ----------
create table if not exists public.repartos (
  id          bigserial primary key,
  sede        text        not null,              -- sede que RECIBE
  origen      text        not null default 'Bodega',
  estado      text        not null default 'abierto',   -- abierto | cerrado
  creado_por  text,
  created_at  timestamptz not null default now(),
  cerrado_por text,
  cerrado_at  timestamptz,
  constraint repartos_estado_ok check (estado in ('abierto','cerrado'))
);
create index if not exists repartos_sede_estado_idx on public.repartos(sede, estado, created_at desc);

-- ---------- 2) Cada línea del envío ----------
create table if not exists public.reparto_items (
  id                bigserial primary key,
  reparto_id        bigint  not null references public.repartos(id) on delete cascade,
  producto_id       bigint  not null references public.productos(id),
  -- el id es el que manda (regla 0.1.1); el nombre se guarda para que el
  -- historial se siga leyendo aunque después renombren el producto
  producto          text    not null,
  cantidad_pedida   numeric not null default 0,
  estado            text    not null default 'pendiente', -- pendiente | recibido | no_llego
  cantidad_recibida numeric,
  lotes_creados     bigint[],          -- fechas que creó esta confirmación (para poder deshacer)
  pendiente_id      bigint,            -- aviso a Fudo que generó (se retira si se deshace)
  extra             boolean not null default false,  -- lo agregó el local, no venía en la lista
  resuelto_por      text,
  resuelto_at       timestamptz,
  constraint reparto_items_estado_ok check (estado in ('pendiente','recibido','no_llego')),
  constraint reparto_items_cant_ok   check (cantidad_recibida is null or cantidad_recibida >= 0)
);
create index if not exists reparto_items_reparto_idx on public.reparto_items(reparto_id);
alter table public.reparto_items add column if not exists pendiente_id bigint;

-- ---------- 3) Permisos (herramienta interna, como el resto) ----------
alter table public.repartos       enable row level security;
alter table public.reparto_items  enable row level security;

drop policy if exists "repartos all"      on public.repartos;
drop policy if exists "reparto_items all" on public.reparto_items;
create policy "repartos all"      on public.repartos      for all to anon, authenticated using (true) with check (true);
create policy "reparto_items all" on public.reparto_items for all to anon, authenticated using (true) with check (true);

grant all on public.repartos      to anon, authenticated;
grant all on public.reparto_items to anon, authenticated;
grant usage, select on sequence public.repartos_id_seq      to anon, authenticated;
grant usage, select on sequence public.reparto_items_id_seq to anon, authenticated;

-- ---------- 4) EN VIVO ----------
-- Sin esto, el jefe de turno no ve lo que Adriana arma hasta refrescar.
-- Es exactamente el problema que tuvimos con producto_lotes: no se olvida.
do $$
begin
  if not exists (select 1 from pg_publication_tables
                  where pubname='supabase_realtime' and schemaname='public' and tablename='repartos') then
    execute 'alter publication supabase_realtime add table public.repartos';
  end if;
  if not exists (select 1 from pg_publication_tables
                  where pubname='supabase_realtime' and schemaname='public' and tablename='reparto_items') then
    execute 'alter publication supabase_realtime add table public.reparto_items';
  end if;
end $$;

-- ================================================================
-- 5) CONFIRMAR QUE UNA LÍNEA LLEGÓ
--
-- Es la pieza importante. Bloquea la línea y comprueba que siga
-- pendiente ANTES de sumar: si dos teléfonos tocan "llegó" a la vez,
-- el segundo no suma nada. Mismo patrón que el motor de Fudo.
--
-- Perecederos: NO se toca stock_actual. Se insertan las fechas y el
-- trigger sync_stock_desde_lotes recalcula el stock. Así se respeta la
-- regla 0.3.1 (cuando se agregan fechas, mandan las fechas).
--   p_lotes: [{"cantidad":6,"vencimiento":"2026-07-28"}, ...]
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
begin
  -- bloquea la línea: nadie más puede procesarla mientras tanto
  select * into it from public.reparto_items where id = p_item_id for update;
  if not found then
    raise exception 'Esa línea del reparto ya no existe.';
  end if;
  -- ya resuelta: no se vuelve a sumar (idempotencia)
  if it.estado <> 'pendiente' then
    return it;
  end if;

  select coalesce(p.perecedero, p.rubro = 'Sándwiches'), p.sede
    into v_perec, v_sede
    from public.productos p where p.id = it.producto_id;

  select exists(select 1 from public.producto_lotes l where l.producto_id = it.producto_id)
    into v_tiene_lot;

  if v_perec or v_tiene_lot then
    -- ---- camino perecedero: entra por fechas, nunca por stock ----
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
    -- ---- camino normal: suma al stock ----
    v_total := coalesce(p_cantidad, it.cantidad_pedida);
    if v_total < 0 then
      raise exception 'La cantidad recibida no puede ser negativa.';
    end if;
    update public.productos
       set stock_actual = coalesce(stock_actual,0) + v_total,
           updated_at   = now()
     where id = it.producto_id;
  end if;

  update public.reparto_items
     set estado='recibido', cantidad_recibida=v_total, lotes_creados=v_ids,
         resuelto_por=p_quien, resuelto_at=now()
   where id = p_item_id
   returning * into it;

  -- el aviso de que hay que actualizar Fudo, igual que al registrar una llegada.
  -- Se guarda su id: si después se deshace, el aviso se retira y nadie suma en
  -- Fudo algo que en la app ya se dio marcha atrás.
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

-- ---------- 6) Marcar que NO llegó ----------
create or replace function public.reparto_rechazar(p_item_id bigint, p_quien text default null)
returns public.reparto_items
language plpgsql security definer set search_path = public
as $$
declare it public.reparto_items;
begin
  select * into it from public.reparto_items where id = p_item_id for update;
  if not found then raise exception 'Esa línea del reparto ya no existe.'; end if;
  if it.estado <> 'pendiente' then return it; end if;

  update public.reparto_items
     set estado='no_llego', cantidad_recibida=0, resuelto_por=p_quien, resuelto_at=now()
   where id = p_item_id
   returning * into it;
  return it;
end;
$$;

-- ================================================================
-- 7) DESHACER
--
-- Solo si el producto NO se movió desde que se confirmó. Si ya se
-- vendieron unidades, no se puede saber qué pasó de verdad, así que
-- avisa en vez de inventar un número.
-- ================================================================
create or replace function public.reparto_deshacer(p_item_id bigint)
returns public.reparto_items
language plpgsql security definer set search_path = public
as $$
declare
  it       public.reparto_items;
  v_stock  numeric;
  v_faltan int;
begin
  select * into it from public.reparto_items where id = p_item_id for update;
  if not found then raise exception 'Esa línea del reparto ya no existe.'; end if;
  if it.estado = 'pendiente' then return it; end if;

  if it.estado = 'recibido' and coalesce(it.cantidad_recibida,0) > 0 then
    if it.lotes_creados is not null and array_length(it.lotes_creados,1) > 0 then
      -- perecedero: las fechas que creó tienen que seguir intactas
      select count(*) into v_faltan
        from unnest(it.lotes_creados) as lid
       where not exists (select 1 from public.producto_lotes l where l.id = lid);
      if v_faltan > 0 then
        raise exception 'No se puede deshacer: ya se vendieron unidades de este producto. Corrige el stock en la ficha.';
      end if;
      delete from public.producto_lotes where id = any(it.lotes_creados);
      -- el trigger recalcula el stock solo
    else
      select coalesce(stock_actual,0) into v_stock from public.productos where id = it.producto_id;
      if v_stock < it.cantidad_recibida then
        raise exception 'No se puede deshacer: ya se vendieron unidades de este producto. Corrige el stock en la ficha.';
      end if;
      update public.productos
         set stock_actual = v_stock - it.cantidad_recibida, updated_at = now()
       where id = it.producto_id;
    end if;
  end if;

  -- retira el aviso a Fudo que había generado esta confirmación
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

-- ---------- 8) Cerrar el reparto (lo hace el jefe de turno) ----------
create or replace function public.reparto_cerrar(p_reparto_id bigint, p_quien text default null)
returns public.repartos
language plpgsql security definer set search_path = public
as $$
declare rep public.repartos; v_pend int;
begin
  select * into rep from public.repartos where id = p_reparto_id for update;
  if not found then raise exception 'Ese reparto ya no existe.'; end if;
  if rep.estado = 'cerrado' then return rep; end if;

  select count(*) into v_pend from public.reparto_items
   where reparto_id = p_reparto_id and estado = 'pendiente';
  if v_pend > 0 then
    if v_pend = 1 then
      raise exception 'Todavía queda 1 producto sin confirmar.';
    else
      raise exception 'Todavía quedan % productos sin confirmar.', v_pend;
    end if;
  end if;

  update public.repartos set estado='cerrado', cerrado_por=p_quien, cerrado_at=now()
   where id = p_reparto_id returning * into rep;
  return rep;
end;
$$;

grant execute on function public.reparto_recibir(bigint,numeric,jsonb,text) to anon, authenticated;
grant execute on function public.reparto_rechazar(bigint,text)             to anon, authenticated;
grant execute on function public.reparto_deshacer(bigint)                  to anon, authenticated;
grant execute on function public.reparto_cerrar(bigint,text)               to anon, authenticated;

-- ---------- 9) Comprobación ----------
select 'tablas creadas' as paso,
       (select count(*) from information_schema.tables
         where table_schema='public' and table_name in ('repartos','reparto_items')) as tablas
union all
select 'publicadas en vivo',
       (select count(*) from pg_publication_tables
         where pubname='supabase_realtime' and tablename in ('repartos','reparto_items'));
