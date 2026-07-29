-- ================================================================
-- EMPAREJAR VITRINA CON CONGELADOR — propuesta de renombres
--
-- Problema: la app suma el stock de un producto que vive en dos
-- secciones solo si los dos nombres son iguales una vez que se les
-- quita el apellido " vitrina" o " congelador".
--
--   "Alfajor artesanal"            -> "alfajor artesanal"
--   "Alfajor artesanal congelado"  -> "alfajor artesanal congelado"  ✗
--                                     (dice "congelado", no "congelador")
--
-- Por eso Fudo se actualizaba con los 2 de la vitrina y no con los 17
-- que hay de verdad.
--
-- ⚠️ IMPORTANTE Y TRANQUILIZADOR: renombrar un producto NO rompe nada.
-- Las recetas se unen por ID, no por nombre (regla 0.1.1 del archivo
-- madre). El descuento sigue funcionando igual después del renombre.
--
-- ESTE ARCHIVO NO MODIFICA NADA. Genera la lista de cambios propuestos
-- y te escribe los UPDATE listos para copiar — pero tú decides cuáles
-- corres. Correr en Supabase -> SQL Editor.
-- ================================================================


-- ================================================================
-- 1) LA PROPUESTA — qué renombraría y a qué
--
-- Empareja cada producto del Congelador con el de la vitrina que más
-- se le parece, y propone renombrar EL DEL CONGELADOR a
-- "<nombre de vitrina> congelador", que es la forma que la app entiende.
--
-- Se toca solo el del congelador, nunca el de la vitrina: el de vitrina
-- es el que sale en el resumen de WhatsApp y el que el equipo nombra
-- en voz alta.
--
-- MIRAR la columna "parecido": 1.0 es idéntico. Bajo 0.45 conviene
-- revisarlo a ojo antes de aceptarlo.
-- ================================================================
create extension if not exists pg_trgm;

-- DOS claves, y la diferencia importa:
--   clave_app   -> quita solo " vitrina" y " congelador", igual que
--                  baseNombre() en index.html. Decide si HOY suman.
--   clave_busca -> quita además "congelado", plurales, etc. Solo sirve
--                  para ENCONTRAR la pareja, nunca para concluir nada.
-- Mezclarlas hacía que el informe dijera "ya suman" cuando no suman.
with base as (
  select id, producto, rubro, stock_actual,
         regexp_replace(lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador)$', '')            as clave_app,
         regexp_replace(lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador|congelado|congelada)$', '') as clave_busca,
         -- el nombre de vitrina sin su apellido, para armar el propuesto
         regexp_replace(producto, '\s+(vitrina|Vitrina|VITRINA)$', '') as raiz
  from public.productos
  where sede='plaza' and activo='SÍ'
),
cong as (select * from base where rubro ilike '%congelador%'),
vitr as (select * from base where rubro not ilike '%congelador%'),
mejor as (
  select c.id                as id_congelador,
         c.producto          as nombre_actual,
         c.stock_actual      as stock_congelador,
         v.producto          as pareja_en_vitrina,
         v.raiz              as raiz_vitrina,
         v.rubro             as seccion_vitrina,
         v.stock_actual      as stock_vitrina,
         v.clave_app         as clave_vitrina,
         c.clave_app         as clave_congelador,
         similarity(c.clave_busca, v.clave_busca) as parecido,
         row_number() over (partition by c.id
                            order by similarity(c.clave_busca, v.clave_busca) desc) as rn
  from cong c
  join vitr v on similarity(c.clave_busca, v.clave_busca) > 0.35
)
select nombre_actual,
       pareja_en_vitrina,
       seccion_vitrina,
       stock_congelador,
       stock_vitrina,
       (coalesce(stock_congelador,0)+coalesce(stock_vitrina,0)) as total_que_sumaria,
       round(parecido::numeric,2)                               as parecido,
       case when clave_vitrina = clave_congelador
            then '✅ ya suman, no hay que tocar nada'
            else '⚠️ hoy NO suman' end                          as estado,
       raiz_vitrina || ' congelador'                            as nombre_propuesto
from mejor
where rn = 1
order by (clave_vitrina = clave_congelador), parecido desc;


-- ================================================================
-- 2) LOS UPDATE, ESCRITOS PARA COPIAR
--
-- Esta consulta NO renombra: devuelve el texto de cada UPDATE en una
-- columna. Revisa la lista de arriba, y de acá copia SOLO las líneas
-- de los pares que te hagan sentido. Pégalas en una consulta nueva
-- y córrelas.
--
-- Así el renombre lo decides tú producto por producto, y no hay
-- ninguna posibilidad de que un emparejamiento equivocado cambie un
-- nombre sin que lo hayas visto.
-- ================================================================
with base as (
  select id, producto, rubro,
         regexp_replace(lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador)$', '')            as clave_app,
         regexp_replace(lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador|congelado|congelada)$', '') as clave_busca,
         regexp_replace(producto, '\s+(vitrina|Vitrina|VITRINA)$', '') as raiz
  from public.productos
  where sede='plaza' and activo='SÍ'
),
cong as (select * from base where rubro ilike '%congelador%'),
vitr as (select * from base where rubro not ilike '%congelador%'),
mejor as (
  select c.id, c.producto as actual, v.raiz as vitrina,
         c.clave_app as ck, v.clave_app as vk,
         similarity(c.clave_busca, v.clave_busca) as parecido,
         row_number() over (partition by c.id
                            order by similarity(c.clave_busca, v.clave_busca) desc) as rn
  from cong c join vitr v on similarity(c.clave_busca, v.clave_busca) > 0.35
)
select 'update public.productos set producto = '
       || quote_literal(vitrina || ' congelador')
       || ' where id = ' || id || ';   -- '
       || actual || '  →  ' || vitrina || ' congelador'
       as copia_esta_linea
from mejor
where rn = 1 and ck <> vk
order by parecido desc;


-- ================================================================
-- 3) LOS DEL CONGELADOR QUE NO ENCONTRARON PAREJA
--
-- O el de la vitrina no existe (hay que crearlo), o el nombre es tan
-- distinto que ni parecido da. Estos se resuelven a mano.
-- ================================================================
with base as (
  select id, producto, rubro, stock_actual,
         regexp_replace(lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador|congelado|congelada)$', '') as clave_busca
  from public.productos
  where sede='plaza' and activo='SÍ'
),
cong as (select * from base where rubro ilike '%congelador%'),
vitr as (select * from base where rubro not ilike '%congelador%')
select c.producto as en_congelador, c.stock_actual
from cong c
where not exists (select 1 from vitr v where similarity(c.clave_busca, v.clave_busca) > 0.35)
order by c.producto;


-- ================================================================
-- 4) DESPUÉS DE RENOMBRAR — comprobar que quedaron sumando
--
-- Correr esto al final. Cada fila que salga acá es un par que ya suma.
-- ================================================================
with base as (
  select producto, rubro, stock_actual,
         regexp_replace(
           lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')),
           '\s+(vitrina|congelador)$', '') as clave
  from public.productos
  where sede='plaza' and activo='SÍ'
)
select clave, count(*) as secciones, sum(stock_actual) as total,
       string_agg(producto || ' (' || coalesce(stock_actual,0) || ')', '  ·  ' order by producto) as detalle
from base
group by clave
having count(*) > 1
order by clave;
