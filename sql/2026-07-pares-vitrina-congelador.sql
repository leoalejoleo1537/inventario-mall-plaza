-- ================================================================
-- ¿POR QUÉ NO SUMA EL TOTAL? — pares vitrina / congelador
--
-- La app suma el stock de un producto que vive en dos secciones solo si
-- los DOS nombres coinciden después de quitarles el apellido " vitrina"
-- o " congelador". Es lo que hace baseNombre() en index.html:
--
--     "Brownie vitrina"    -> "brownie"   ✅ suman
--     "Brownie congelador" -> "brownie"
--
--     "Macarrons"          -> "macarrons"        ❌ NO suman:
--     "Macarron congelador"-> "macarron"            singular/plural
--
-- O sea: cuando el total no aparece, casi siempre es una diferencia de
-- nombre, no un producto que falte.
--
-- TODO ESTE ARCHIVO ES DE SOLO LECTURA. No cambia ni un nombre.
-- Correr en Supabase -> SQL Editor.
-- ================================================================


-- ================================================================
-- 1) LOS QUE SÍ ESTÁN SUMANDO (para ver que la regla funciona)
-- ================================================================
with base as (
  select id, producto, rubro, stock_actual,
         regexp_replace(
           lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador)$', '') as clave
  from public.productos
  where sede='plaza' and activo='SÍ'
)
select clave,
       count(*)                                   as en_cuantas_secciones,
       sum(stock_actual)                          as total_que_muestra,
       string_agg(producto||' ('||rubro||': '||coalesce(stock_actual,0)||')', '  ·  '
                  order by producto)               as detalle
from base
group by clave
having count(*) > 1
order by clave;


-- ================================================================
-- 2) ⚠️ LOS QUE DEBERÍAN SUMAR Y NO SUMAN
--
-- Busca productos de Vitrina y de Congelador cuyos nombres se PARECEN
-- mucho (comparando solo las primeras letras) pero cuya clave no calza,
-- así que la app los trata como productos distintos.
--
-- ESTA ES LA LISTA QUE HAY QUE MIRAR. Cada fila es un par que hoy no se
-- suma, con los dos nombres exactos tal como están escritos.
-- ================================================================
with base as (
  select id, producto, rubro, stock_actual,
         regexp_replace(
           lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador)$', '') as clave
  from public.productos
  where sede='plaza' and activo='SÍ'
),
cong as (select * from base where rubro ilike '%congelador%'),
vitr as (select * from base where rubro not ilike '%congelador%')
select v.producto        as en_vitrina,
       v.rubro           as seccion_vitrina,
       v.stock_actual    as stock_vitrina,
       c.producto        as en_congelador,
       c.stock_actual    as stock_congelador,
       (coalesce(v.stock_actual,0) + coalesce(c.stock_actual,0)) as total_que_deberia_ver,
       v.clave           as clave_vitrina,
       c.clave           as clave_congelador
from vitr v
join cong c
  -- se parecen en las primeras 6 letras, pero su clave NO es la misma
  on left(v.clave, 6) = left(c.clave, 6)
 and v.clave <> c.clave
order by v.producto;


-- ================================================================
-- 3) PRODUCTOS DE VITRINA QUE NO TIENEN NINGUNA PAREJA EN CONGELADOR
--
-- Puede ser correcto (hay cosas que solo viven en vitrina) o puede ser
-- que falte crear el producto del congelador. Lo decide el equipo.
-- ================================================================
with base as (
  select producto, rubro, stock_actual,
         regexp_replace(
           lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador)$', '') as clave
  from public.productos
  where sede='plaza' and activo='SÍ'
)
select producto, rubro, stock_actual
from base b
where rubro not ilike '%congelador%'
  and rubro ilike 'vitrina%'
  and not exists (
    select 1 from base c
    where c.rubro ilike '%congelador%' and left(c.clave,6) = left(b.clave,6)
  )
order by producto;


-- ================================================================
-- 4) ⚠️ LO QUE MÁS TE PREOCUPABA — productos SIN receta
--
-- Un producto del inventario sin receta NO es peligroso para Fudo: es
-- invisible para el empuje. fudo_stock_calculado() sale DESDE la tabla
-- recetas, así que si no hay receta, ese producto no aparece nunca en
-- la lista de lo que se manda. No puede escribir nada en Fudo.
--
-- El riesgo real es el contrario: Fudo sigue vendiendo ese producto sin
-- límite, porque nadie le dice cuánto queda. Es falta de cobertura, no
-- un dato corrupto.
--
-- Esta consulta lista los que están en esa situación.
-- ================================================================
select p.producto, p.rubro, p.tipo, p.stock_actual
from public.productos p
where p.sede='plaza' and p.activo='SÍ'
  and not exists (
    select 1
    from public.recetas r
    join public.receta_items ri on ri.receta_id = r.id
    where r.sede = p.sede and r.activo and ri.producto_id = p.id
  )
order by p.rubro, p.producto;
