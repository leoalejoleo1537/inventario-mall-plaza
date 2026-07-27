-- ================================================================
-- TIPO DE PRODUCTO — el otro eje del inventario
--
-- Las secciones dicen DÓNDE está un producto (Congelador, Vitrina de
-- tortas). El tipo dice QUÉ ES (torta, bollería, sándwich). Son dos ejes
-- distintos: un cinnamon roll está EN el congelador y ES bollería. Hoy
-- solo existe el primero, por eso para ver "todas las tortas" hay que
-- buscarlas una por una.
--
-- Este archivo se corre EN TRES PASOS y cada uno se mira antes del
-- siguiente. El paso 1 y el 2 NO modifican ningún dato.
--
--   PASO 1  crea la columna (vacía) y muestra cómo está la sede
--   PASO 2  PROPONE un tipo para cada producto — solo lectura, para revisar
--   PASO 3  escribe esa propuesta (correr solo después de revisar el 2)
--
-- Cómo correrlo: Supabase -> SQL Editor -> un paso a la vez -> Run.
-- Todo es idempotente: se puede volver a correr sin romper nada.
--
-- Si el PASO 1 no se corre, la app se ve exactamente como antes: la franja
-- de tipos no aparece y el campo "Tipo" de la ficha tampoco.
-- ================================================================


-- ================================================================
-- PASO 1 — la columna. No toca ningún dato existente.
-- ================================================================
alter table public.productos add column if not exists tipo text;

-- índice para que filtrar por tipo no recorra la tabla entera
create index if not exists productos_sede_tipo_idx on public.productos (sede, tipo);

-- ¿cómo está la sede ahora?  (al recién correrlo, todo sale "sin tipo")
select coalesce(nullif(trim(tipo),''),'— sin tipo —') as tipo,
       count(*) as productos
from public.productos
where sede='plaza' and activo='SÍ'
group by 1
order by productos desc;


-- ================================================================
-- PASO 2 — PROPUESTA, de solo lectura. NO ESCRIBE NADA.
--
-- Adivina el tipo por el nombre del producto y por su sección. Es una
-- primera pasada para no clasificar 232 productos a mano: lo que quede
-- mal se corrige en la propia consulta antes del paso 3, o después desde
-- la ficha del producto en la app.
--
-- MIRAR sobre todo la columna "propuesta": las que digan "— revisar —"
-- son las que el nombre no alcanzó a identificar.
-- ================================================================
with base as (
  select id, producto, rubro,
         -- sin tildes y en minúsculas, para que "bollería" y "bolleria" calcen
         lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as n,
         lower(translate(coalesce(rubro,''),'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as r
  from public.productos
  where sede='plaza' and activo='SÍ'
)
select id, producto, rubro,
  case
    when n ~ 'sandwich|sanguche|croasan|croissant|selladito|ciabatta|pan '     then 'Sándwiches'
    when n ~ 'torta|cheesecake|pie de|tiramisu|matilda|selva negra'            then 'Tortas'
    when n ~ 'cannoli|cinnamon|dona|donut|muffin|medialuna|berlin|bolleria'    then 'Bollería'
    when n ~ 'galleta|cookie|alfajor|maicenito|cachito|brownie|volcan'         then 'Pastelería'
    when n ~ 'pizza|empanada|calzone'                                          then 'Salados'
    when n ~ 'pulpa|jugo|bebida|agua|gaseosa|coca|sprite|fanta'                then 'Bebidas'
    when n ~ 'cafe|espresso|leche|te |te$|infusion|matcha|chai'                then 'Cafetería'
    when r ~ 'limpieza'                                                        then 'Limpieza'
    when n ~ 'bolsa|vaso|tapa|servilleta|bandeja|caja|cuchar|removedor|papel'  then 'Envases'
    when r ~ 'bolsas|caja|mesones'                                             then 'Envases'
    when n ~ 'azucar|harina|crema|mantequilla|huevo|salsa|queso|jamon|palta'   then 'Insumos'
    when r ~ 'mezclas'                                                         then 'Insumos'
    else '— revisar —'
  end as propuesta
from base
order by propuesta, producto;


-- ---------- PASO 2b — el resumen de la propuesta, en una mirada ----------
-- Cuántos caerían en cada tipo y cuántos quedan sin identificar.
-- Si "— revisar —" sale muy alto, conviene ajustar los patrones de arriba
-- antes de escribir nada.
with base as (
  select producto, rubro,
         lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as n,
         lower(translate(coalesce(rubro,''),'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as r
  from public.productos where sede='plaza' and activo='SÍ'
)
select case
    when n ~ 'sandwich|sanguche|croasan|croissant|selladito|ciabatta|pan '     then 'Sándwiches'
    when n ~ 'torta|cheesecake|pie de|tiramisu|matilda|selva negra'            then 'Tortas'
    when n ~ 'cannoli|cinnamon|dona|donut|muffin|medialuna|berlin|bolleria'    then 'Bollería'
    when n ~ 'galleta|cookie|alfajor|maicenito|cachito|brownie|volcan'         then 'Pastelería'
    when n ~ 'pizza|empanada|calzone'                                          then 'Salados'
    when n ~ 'pulpa|jugo|bebida|agua|gaseosa|coca|sprite|fanta'                then 'Bebidas'
    when n ~ 'cafe|espresso|leche|te |te$|infusion|matcha|chai'                then 'Cafetería'
    when r ~ 'limpieza'                                                        then 'Limpieza'
    when n ~ 'bolsa|vaso|tapa|servilleta|bandeja|caja|cuchar|removedor|papel'  then 'Envases'
    when r ~ 'bolsas|caja|mesones'                                             then 'Envases'
    when n ~ 'azucar|harina|crema|mantequilla|huevo|salsa|queso|jamon|palta'   then 'Insumos'
    when r ~ 'mezclas'                                                         then 'Insumos'
    else '— revisar —'
  end as propuesta,
  count(*) as productos
from base
group by 1
order by productos desc;


-- ================================================================
-- PASO 3 — ESCRIBE la propuesta.  ⚠️ ESTE SÍ MODIFICA DATOS.
--
-- Qué hace: pone el tipo propuesto a los productos que HOY no tienen tipo.
-- Nunca pisa un tipo puesto a mano (por eso el `where tipo is null`), así
-- que se puede correr de nuevo sin deshacer correcciones.
-- Los que salían "— revisar —" quedan SIN tipo: no aparecen en ninguna
-- píldora y se les pone el tipo desde la ficha del producto en la app.
--
-- Cómo revertirlo: `update public.productos set tipo=null where sede='plaza';`
-- (deja todo como antes de este paso, sin tocar nada más).
--
-- Correr SOLO después de mirar el paso 2.
-- ================================================================
update public.productos p
set tipo = t.propuesta
from (
  select id,
    case
      when n ~ 'sandwich|sanguche|croasan|croissant|selladito|ciabatta|pan '     then 'Sándwiches'
      when n ~ 'torta|cheesecake|pie de|tiramisu|matilda|selva negra'            then 'Tortas'
      when n ~ 'cannoli|cinnamon|dona|donut|muffin|medialuna|berlin|bolleria'    then 'Bollería'
      when n ~ 'galleta|cookie|alfajor|maicenito|cachito|brownie|volcan'         then 'Pastelería'
      when n ~ 'pizza|empanada|calzone'                                          then 'Salados'
      when n ~ 'pulpa|jugo|bebida|agua|gaseosa|coca|sprite|fanta'                then 'Bebidas'
      when n ~ 'cafe|espresso|leche|te |te$|infusion|matcha|chai'                then 'Cafetería'
      when r ~ 'limpieza'                                                        then 'Limpieza'
      when n ~ 'bolsa|vaso|tapa|servilleta|bandeja|caja|cuchar|removedor|papel'  then 'Envases'
      when r ~ 'bolsas|caja|mesones'                                             then 'Envases'
      when n ~ 'azucar|harina|crema|mantequilla|huevo|salsa|queso|jamon|palta'   then 'Insumos'
      when r ~ 'mezclas'                                                         then 'Insumos'
      else null
    end as propuesta
  from (
    select id,
           lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as n,
           lower(translate(coalesce(rubro,''),'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as r
    from public.productos where sede='plaza' and activo='SÍ'
  ) b
) t
where p.id = t.id and t.propuesta is not null and p.tipo is null;

-- ---------- Comprobación: cómo quedó ----------
select coalesce(nullif(trim(tipo),''),'— sin tipo —') as tipo,
       count(*) as productos
from public.productos
where sede='plaza' and activo='SÍ'
group by 1
order by productos desc;
