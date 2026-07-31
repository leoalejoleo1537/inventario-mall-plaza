-- ================================================================
-- BLOQUE 1 — SOLO LECTURA: qué pasó, y qué producto podría ser
--
-- Para cada receta rota muestra el estado del insumo y, si la fila ya
-- no existe, PROPONE productos del inventario cuyo nombre se parece.
-- Propone candidatos: la decisión es tuya (regla 0.1.4 del archivo).
-- ================================================================
with norm as (
  select id, producto, rubro, sede, activo, stock_actual,
         lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as k
  from public.productos
),
rotas as (
  select ri.id as linea_id, ri.producto_id, ri.cantidad, r.id as receta_id,
         coalesce(fp.nombre,'(Fudo '||r.fudo_product_id||')') as receta_de_fudo,
         lower(translate(coalesce(fp.nombre,''),'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as kf
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  left join public.productos p on p.id = ri.producto_id
  left join public.fudo_productos fp on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
  where r.activo and (p.id is null or p.activo <> 'SÍ')
),
palabras as (
  select rotas.linea_id, w
  from rotas, regexp_split_to_table(rotas.kf, '\s+') w
  where length(w) >= 5
)
select ro.receta_de_fudo,
       ro.producto_id                              as insumo_que_falta,
       ro.cantidad                                 as descuenta,
       coalesce(string_agg(distinct n.producto||' (id '||n.id||' · '||n.rubro
                                   ||' · stock '||coalesce(n.stock_actual,0)
                                   ||case when n.activo<>'SÍ' then ' · DESACTIVADO' else '' end||')',
                           '  ·  '),
                'ningun producto se le parece') as candidatos_para_reemplazarlo
from rotas ro
left join palabras pa on pa.linea_id = ro.linea_id
left join norm n on n.k like '%'||pa.w||'%' and n.sede = 'plaza'
group by ro.receta_de_fudo, ro.producto_id, ro.cantidad, ro.linea_id
order by 1;


-- ================================================================
-- BLOQUE 2 — MUFFIN AMAPOLA: ya no se vende
--
-- Jhon eliminó el producto del inventario a propósito. Entonces su
-- receta ya no tiene con qué descontar: se DESACTIVA (no se borra, así
-- queda el rastro y se puede revertir).
--
-- Primero la vista previa. Si muestra la receta correcta, correr el update.
-- ================================================================
select r.id as receta_id, fp.nombre as se_va_a_desactivar, r.activo as ahora
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
left join public.productos p on p.id = ri.producto_id
join public.fudo_productos fp on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
where r.activo and (p.id is null or p.activo <> 'SÍ') and fp.nombre ilike '%amapola%';

-- --- el cambio (deshacer: poner activo = true de nuevo) ---
-- update public.recetas set activo = false
--  where id in (select r.id from public.recetas r
--               join public.receta_items ri on ri.receta_id = r.id
--               left join public.productos p on p.id = ri.producto_id
--               join public.fudo_productos fp on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
--               where r.activo and (p.id is null or p.activo <> 'SÍ') and fp.nombre ilike '%amapola%');


-- ================================================================
-- BLOQUE 3 — DONA PISTACHO DUBAI: apuntar al producto correcto
--
-- La receta apunta a un insumo que ya no está. Acá se la reapunta al
-- producto del inventario que corresponde, SIN escribir ningun id a
-- mano: lo busca por nombre y te muestra cuál eligió.
--
-- ⚠️ La vista previa TIENE que devolver UNA sola fila. Si devuelve dos
-- o ninguna, no correr el update — avisame y lo ajustamos.
-- ================================================================
select ri.id as linea_de_receta, fp.nombre as receta,
       ri.producto_id as apunta_hoy_a,
       p2.id          as pasaria_a_apuntar_a,
       p2.producto    as nombre_del_insumo,
       p2.rubro, p2.stock_actual
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
left join public.productos p on p.id = ri.producto_id
join public.fudo_productos fp on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
join public.productos p2
  on p2.sede = r.sede and p2.activo = 'SÍ'
 and lower(translate(p2.producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) like '%pistacho%'
where r.activo and (p.id is null or p.activo <> 'SÍ') and fp.nombre ilike '%pistacho%';

-- --- el cambio (deshacer: volver a poner el id viejo en esa linea) ---
-- update public.receta_items ri set producto_id = p2.id
--   from public.recetas r
--   join public.fudo_productos fp on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
--   join public.productos p2 on p2.sede = r.sede and p2.activo = 'SÍ'
--    and lower(translate(p2.producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) like '%pistacho%'
--  where ri.receta_id = r.id and r.activo and fp.nombre ilike '%pistacho%'
--    and not exists (select 1 from public.productos px where px.id = ri.producto_id and px.activo='SÍ');
