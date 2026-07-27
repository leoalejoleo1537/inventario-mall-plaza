-- ================================================================
-- DIAGNÓSTICO — se vendió y el stock no bajó
--
-- SOLO LECTURA: no crea, no borra, no modifica nada.
--
-- Por qué: Jhon vendió una medialuna de membrillo (y 6 ventas más) y la
-- sync dijo que leyó las ventas, pero no descontó nada. Que NINGUNA haya
-- descontado apunta a una causa global, no a un producto suelto. Estos
-- 5 bloques separan las causas posibles.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Manda los 5 resultados.
-- ================================================================

-- ---------- BLOQUE 1: ¿la sede está descontando de verdad? ----------
-- 'real'   = descuenta.
-- 'prueba' = registra la venta pero NO toca el stock. Si dice prueba,
--            esta es la causa y no hay que buscar más.
select sede, modo, ultima_venta_at, updated_at
from public.fudo_sync
order by sede;

-- ---------- BLOQUE 2: ¿qué hizo el motor con las últimas ventas? ----------
-- Cada fila es un ítem vendido que la sync procesó. Mirar:
--   producto_nombre = '(sin receta)'  -> ese producto de Fudo no tiene receta
--   aplicado = false                  -> se registró pero NO se descontó
--   aplicado = true                   -> sí descontó (y el stock debió bajar)
select venta_at,
       fudo_product_nombre                   as vendido_en_fudo,
       producto_nombre                       as insumo_descontado,
       cantidad_vendida,
       descuento,
       aplicado,
       created_at                            as procesado_a_las
from public.fudo_movimientos
where sede = 'plaza'
order by created_at desc
limit 40;

-- ---------- BLOQUE 3: resumen de lo mismo, para verlo de un vistazo ----------
select case when producto_nombre = '(sin receta)' then 'sin receta en el sistema'
            when aplicado then 'descontó'
            else 'registrado pero NO descontó' end as que_paso,
       count(*) as veces
from public.fudo_movimientos
where sede = 'plaza' and created_at > now() - interval '24 hours'
group by 1
order by veces desc;

-- ---------- BLOQUE 4: la medialuna de membrillo, en concreto ----------
-- ¿Está en el catálogo de Fudo? ¿Tiene receta? ¿La receta tiene insumos?
select fp.nombre                                   as producto_de_fudo,
       fp.fudo_product_id,
       r.id                                        as tiene_receta,
       r.activo                                    as receta_activa,
       count(ri.id)                                as insumos_en_la_receta
from public.fudo_productos fp
left join public.recetas r
       on r.sede = fp.sede and r.fudo_product_id = fp.fudo_product_id
left join public.receta_items ri on ri.receta_id = r.id
where fp.sede = 'plaza'
  and translate(lower(fp.nombre),'áéíóúñü','aeiounu') like '%medialuna%'
group by fp.nombre, fp.fudo_product_id, r.id, r.activo
order by fp.nombre;

-- ---------- BLOQUE 5: ¿cuántas versiones del motor hay instaladas? ----------
-- Debe salir UNA sola fila, con 8 argumentos (la v5, que recibe venta_at).
-- Si salen dos, hay una versión vieja conviviendo y puede estar corriendo esa.
select p.oid::regprocedure as firma_instalada,
       pg_get_function_identity_arguments(p.oid) as argumentos
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'fudo_procesar_item';

-- ---------- BLOQUE 6 (extra): cobertura de recetas ----------
-- Cuántos productos de Fudo tienen receta con insumos y cuántos no.
select count(*) filter (where con_insumos)     as con_receta,
       count(*) filter (where not con_insumos) as sin_receta,
       round(100.0 * count(*) filter (where con_insumos) / nullif(count(*),0), 1) as cobertura_pct
from (
  select fp.fudo_product_id,
         exists (select 1 from public.recetas r
                 join public.receta_items ri on ri.receta_id = r.id
                 where r.sede = fp.sede and r.fudo_product_id = fp.fudo_product_id and r.activo) as con_insumos
  from public.fudo_productos fp
  where fp.sede = 'plaza' and fp.activo
) t;
