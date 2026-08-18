-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. **UNO POR UNO, y los bloques 2 y 3 van SOLOS**
--             (llevan $$ y el editor los corta por la mitad si van
--             pegados a otra cosa).
--  TARDA:     instantáneo
--  QUÉ HACE:  instala la máquina de juntar dos productos repetidos.
--             NO junta nada ni mueve un solo producto.
--  QUÉ VER:   el bloque 4: 3 filas, las 3 en SÍ.
-- ================================================================
--
-- EL PROBLEMA: el mismo producto cargado dos veces. Las jefas cuentan una
-- vez en cada ficha, el stock queda partido en dos, y el número que se le
-- manda a Fudo es el de una sola. Bodega llegó a tener 117 pares así.
--
-- QUÉ HACE LA FUSIÓN, en orden, y cada paso tiene su motivo:
--
--   1. EL STOCK se suma en el que se queda. Es el único paso obvio.
--
--   2. LAS FECHAS se MUEVEN, no se suman. En un producto con fechas el
--      stock lo calcula la base sumándolas; escribir un número a mano ahí
--      rompería la cuenta para siempre (§0.3.1).
--
--   3. LAS RECETAS se repuntan al que se queda. Si no, al apagar el otro
--      quedarían apuntando a un producto muerto — y el motor NO filtra por
--      activo, así que seguiría descontando de una ficha apagada. Es
--      exactamente lo que pasó en Angamos en agosto.
--
--   4. LOS ENLACES con bodega también. Si el que se queda ya tenía uno en
--      esa sede, el del otro se descarta: un producto del local no puede
--      tener dos orígenes.
--
--   5. EL QUE SOBRA SE APAGA, no se borra. En esta app eliminar siempre
--      fue desactivar, y además hay repartos viejos que lo nombran.
--
-- SE NIEGA A HACERLO en dos casos, y los dos son a propósito:
--   · si uno tiene fechas y el otro no: mezclar un producto con fechas y
--     uno sin ellas no tiene una respuesta correcta, y la equivocada
--     descuadra el inventario en silencio
--   · si son de sedes distintas: eso no es un duplicado, son dos
--     inventarios
--
-- Y GUARDA EL ANTES, así se deshace entero.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL CUADERNO DE FUSIONES
-- ================================================================
create table if not exists public.fusiones (
  id            bigserial primary key,
  sede          text        not null,
  queda_id      bigint      not null,
  queda_nombre  text,
  se_va_id      bigint      not null,
  se_va_nombre  text,
  quien         text,
  antes         jsonb       not null,   -- stock, fechas, recetas y enlaces
  created_at    timestamptz not null default now(),
  deshecha_at   timestamptz,
  deshecha_por  text
);
create index if not exists fusiones_sede_idx on public.fusiones(sede, created_at desc);

alter table public.fusiones enable row level security;
drop policy if exists "fusiones all" on public.fusiones;
create policy "fusiones all" on public.fusiones
  for all to anon, authenticated using (true) with check (true);
grant all on public.fusiones to anon, authenticated;
grant usage, select on sequence public.fusiones_id_seq to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — FUSIONAR  (⚠️ ESTE BLOQUE VA SOLO)
-- ================================================================
create or replace function public.fusionar_productos(
  p_queda  bigint,
  p_se_va  bigint,
  p_quien  text default null
) returns public.fusiones
language plpgsql
security definer
set search_path = public
as $$
declare
  a       public.productos;   -- el que se queda
  b       public.productos;   -- el que se va
  v_antes jsonb;
  v_lotes_a integer;
  v_lotes_b integer;
  f       public.fusiones;
begin
  if p_queda = p_se_va then
    raise exception 'Son el mismo producto.';
  end if;
  select * into a from public.productos where id = p_queda for update;
  if not found then raise exception 'El producto que se queda ya no existe.'; end if;
  select * into b from public.productos where id = p_se_va for update;
  if not found then raise exception 'El producto que se va ya no existe.'; end if;
  if a.sede <> b.sede then
    raise exception 'Están en sedes distintas: eso no es un duplicado.';
  end if;

  select count(*) into v_lotes_a from public.producto_lotes where producto_id = a.id;
  select count(*) into v_lotes_b from public.producto_lotes where producto_id = b.id;
  if (v_lotes_a > 0) <> (v_lotes_b > 0) then
    raise exception 'Uno lleva fechas de vencimiento y el otro no. Igualalos antes de juntarlos.';
  end if;

  -- EL ANTES, completo, guardado antes de tocar nada
  v_antes := jsonb_build_object(
    'queda_stock', a.stock_actual,
    'se_va_stock', b.stock_actual,
    'se_va_activo', b.activo,
    'lotes',   coalesce((select jsonb_agg(l.id) from public.producto_lotes l
                          where l.producto_id = b.id), '[]'::jsonb),
    'recetas', coalesce((select jsonb_agg(jsonb_build_object('id', ri.id, 'cantidad', ri.cantidad))
                          from public.receta_items ri where ri.producto_id = b.id), '[]'::jsonb),
    'enlaces', coalesce((select jsonb_agg(jsonb_build_object('id', e.id, 'campo',
                            case when e.producto_bodega_id = b.id then 'bodega' else 'sede' end))
                          from public.producto_enlace e
                         where e.producto_bodega_id = b.id or e.producto_sede_id = b.id), '[]'::jsonb),
    -- LOS CHOQUES: recetas donde los DOS productos estaban. Esos renglones
    -- se funden en uno y al deshacer no se pueden volver a partir — la
    -- suma ya ocurrió. Se anotan acá para poder DECIRLO en vez de que
    -- alguien lo descubra después mirando una cantidad que no cuadra.
    'choques', coalesce((select jsonb_agg(jsonb_build_object(
                            'receta', r.fudo_product_nombre,
                            'cantidad_sumada', otra.cantidad))
                          from public.receta_items otra
                          join public.receta_items mia
                            on mia.receta_id = otra.receta_id and mia.producto_id = a.id
                          join public.recetas r on r.id = otra.receta_id
                         where otra.producto_id = b.id), '[]'::jsonb));

  -- 1) las FECHAS se mueven; el trigger recalcula los dos stocks
  if v_lotes_b > 0 then
    update public.producto_lotes set producto_id = a.id, updated_at = now()
     where producto_id = b.id;
  else
    -- 2) sin fechas, el stock se suma y el otro queda en cero
    update public.productos
       set stock_actual = coalesce(a.stock_actual,0) + coalesce(b.stock_actual,0),
           updated_at = now()
     where id = a.id;
    update public.productos set stock_actual = 0, updated_at = now() where id = b.id;
  end if;

  -- 3) las RECETAS. Si el que se queda YA estaba en esa receta, se suman
  --    las cantidades en su renglón y el otro se borra: la tabla no admite
  --    el mismo producto dos veces en la misma receta.
  update public.receta_items ri
     set cantidad = ri.cantidad + otra.cantidad
    from public.receta_items otra
   where otra.producto_id = b.id
     and ri.receta_id = otra.receta_id
     and ri.producto_id = a.id;
  delete from public.receta_items ri
   where ri.producto_id = b.id
     and exists (select 1 from public.receta_items x
                  where x.receta_id = ri.receta_id and x.producto_id = a.id);
  update public.receta_items set producto_id = a.id where producto_id = b.id;

  -- 4) los ENLACES con bodega, con el mismo criterio
  delete from public.producto_enlace e
   where e.producto_sede_id = b.id
     and exists (select 1 from public.producto_enlace y
                  where y.sede = e.sede and y.producto_sede_id = a.id);
  update public.producto_enlace set producto_sede_id = a.id where producto_sede_id = b.id;
  delete from public.producto_enlace e
   where e.producto_bodega_id = b.id
     and exists (select 1 from public.producto_enlace y
                  where y.sede = e.sede and y.producto_bodega_id = a.id
                    and y.producto_sede_id = e.producto_sede_id);
  update public.producto_enlace set producto_bodega_id = a.id where producto_bodega_id = b.id;

  -- 5) el que sobra se APAGA, nunca se borra
  update public.productos set activo = 'NO', updated_at = now() where id = b.id;

  insert into public.fusiones (sede, queda_id, queda_nombre, se_va_id, se_va_nombre, quien, antes)
  values (a.sede, a.id, a.producto, b.id, b.producto, p_quien, v_antes)
  returning * into f;

  return f;
end;
$$;

grant execute on function public.fusionar_productos(bigint,bigint,text) to anon, authenticated;


-- ================================================================
-- BLOQUE 3 — DESHACER UNA FUSIÓN  (⚠️ ESTE BLOQUE VA SOLO)
--
-- Devuelve las fechas, las recetas, los enlaces y los dos stocks. Lo que
-- NO puede devolver son los renglones que se borraron por chocar: si el
-- que se queda ya estaba en esa receta, ese renglón se fundió con el
-- suyo. Se avisa en el resultado en vez de fingir que volvió todo.
-- ================================================================
create or replace function public.deshacer_fusion(
  p_id    bigint,
  p_quien text default null
) returns public.fusiones
language plpgsql
security definer
set search_path = public
as $$
declare
  f public.fusiones;
  v_lotes jsonb;
begin
  select * into f from public.fusiones where id = p_id for update;
  if not found then raise exception 'Esa fusión ya no está.'; end if;
  if f.deshecha_at is not null then raise exception 'Esa fusión ya se deshizo.'; end if;

  v_lotes := f.antes -> 'lotes';

  -- las fechas vuelven a su ficha
  if jsonb_array_length(v_lotes) > 0 then
    update public.producto_lotes set producto_id = f.se_va_id, updated_at = now()
     where id in (select (x)::text::bigint from jsonb_array_elements(v_lotes) x);
  end if;

  -- las recetas y los enlaces que solo cambiaron de dueño
  update public.receta_items set producto_id = f.se_va_id
   where id in (select (x->>'id')::bigint from jsonb_array_elements(f.antes->'recetas') x)
     and producto_id = f.queda_id;
  update public.producto_enlace set producto_sede_id = f.se_va_id
   where id in (select (x->>'id')::bigint from jsonb_array_elements(f.antes->'enlaces') x
                 where x->>'campo' = 'sede')
     and producto_sede_id = f.queda_id;
  update public.producto_enlace set producto_bodega_id = f.se_va_id
   where id in (select (x->>'id')::bigint from jsonb_array_elements(f.antes->'enlaces') x
                 where x->>'campo' = 'bodega')
     and producto_bodega_id = f.queda_id;

  -- los stocks, tal como estaban
  if jsonb_array_length(v_lotes) = 0 then
    update public.productos set stock_actual = (f.antes->>'queda_stock')::double precision,
           updated_at = now() where id = f.queda_id;
    update public.productos set stock_actual = (f.antes->>'se_va_stock')::double precision,
           updated_at = now() where id = f.se_va_id;
  end if;

  update public.productos set activo = coalesce(f.antes->>'se_va_activo','SÍ'), updated_at = now()
   where id = f.se_va_id;

  update public.fusiones set deshecha_at = now(), deshecha_por = p_quien
   where id = p_id returning * into f;
  return f;
end;
$$;

grant execute on function public.deshacer_fusion(bigint,text) to anon, authenticated;


-- ================================================================
-- BLOQUE 4 — COMPROBACIÓN
-- QUÉ VER: 3 filas, las 3 en SÍ.
-- ================================================================
select 'tabla fusiones' as pieza,
       case when to_regclass('public.fusiones') is not null then 'SÍ' else 'NO' end as quedo
union all
select 'fusionar_productos, y una sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='fusionar_productos') = 1
            then 'SÍ' else 'NO' end
union all
select 'deshacer_fusion, y una sola firma',
       case when (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                   where n.nspname='public' and p.proname='deshacer_fusion') = 1
            then 'SÍ' else 'NO' end;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-fusionar-duplicados.sql', 'Jhon', 'lo corrió Jhon',
        'Juntar dos productos repetidos: suma el stock, mueve las fechas, repunta recetas y enlaces, apaga el que sobra. Con deshacer')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
