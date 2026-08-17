-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. **UNO POR UNO, y el 1 va SOLO.**
--  TARDA:     instantáneo
--  QUÉ HACE:  permite mermar en TODAS las sedes, no solo en la bodega.
--             No merma nada ni mueve un solo producto.
--  QUÉ VER:   en el bloque 2, una fila que diga SÍ.
-- ================================================================
--
-- ⚠️ POR QUÉ FALLÓ LA VEZ ANTERIOR ("relation pr does not exist"), y es
-- culpa mía, no tuya: te lo mandé todo junto en un solo Run. El editor
-- de Supabase parte el texto en instrucciones por su cuenta, y con las
-- comillas de dólar ($$) se confunde: cortó la función por la mitad y
-- ejecutó un pedazo suelto, donde `pr` ya no significaba nada.
--
-- No era un error del SQL —el mensaje no habla de la función ni de la
-- tabla— era el editor. Es §3.5 del archivo madre, y yo la incumplí.
--
-- SOLUCIÓN: el bloque 1 va SOLO. Se pega, se aprieta Run, y recién
-- después se pega el bloque 2.
--
-- ================================================================
-- QUÉ CAMBIA, y son dos líneas:
--
--  1) Se quita el candado que decía "por ahora la merma solo está
--     habilitada en la bodega". Era la regla de esa etapa (§0.7), y hoy
--     Jhon pidió lo contrario: mermar en Mall Plaza, en Angamos y en la
--     bodega.
--
--  2) La merma queda anotada con la sede DEL PRODUCTO. Antes se anotaba
--     siempre 'central' porque no había otra posible; ahora sí la hay, y
--     si no se cambiara, una merma de Mall Plaza aparecería en el libro
--     como si fuera de la bodega. Ese error no se nota el día que ocurre
--     —el stock baja bien igual— y arruina cualquier resumen después.
--
-- LO QUE NO CAMBIA, y son los tres candados que sí valen:
--   · no deja el stock en negativo
--   · en un producto con fechas obliga a decir de qué fecha se merma
--   · exige un motivo
-- Siguen en la base y no en la pantalla, para que no dependan de que un
-- botón esté escondido.
--
-- Es la MISMA función con el mismo nombre y los mismos argumentos, así
-- que no puede quedar una firma vieja conviviendo (§0.5).
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA FUNCIÓN.  ⚠️ ESTE BLOQUE VA SOLO, NADA MÁS PEGADO.
--   Copiar desde la línea de abajo hasta el `$$;` final, y Run.
--   Tiene que contestar "Success. No rows returned".
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
  values (pr.sede, pr.id, pr.producto, 'merma', -v_total, p_motivo,
          nullif(btrim(coalesce(p_nota,'')),''), p_quien,
          case when v_detalle = '[]'::jsonb then null else v_detalle end)
  returning * into mv;

  return mv;
end;
$$;


-- ================================================================
-- BLOQUE 2 — PERMISO Y COMPROBACIÓN  (recién ahora, en otro Run)
--
-- QUÉ VER: una sola fila, y que diga SÍ. Si dijera NO, el bloque 1 no
-- llegó a entrar y hay que volver a pegarlo solo.
-- ================================================================
grant execute on function public.mermar(bigint,numeric,jsonb,text,text,text) to anon, authenticated;

select 'la merma ya funciona en todas las sedes' as pieza,
       case when pg_get_functiondef(p.oid) not like '%<> ''central''%'
            then 'SÍ' else 'NO' end as quedo
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'mermar';

insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-mermas-en-todas-las-sedes.sql', 'Jhon', 'lo corrió Jhon',
        'Quita el candado que limitaba la merma a la bodega, y anota la merma con la sede del producto en vez de central')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
