-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Uno por uno. El 3 SOLO si el 1 dice SÍ.
--  TARDA:     instantáneo
--  QUÉ HACE:  solo MIRA y cuenta. No escribe ni una fila, en ninguna sede.
--  QUÉ VER:   copiame la tabla completa de cada bloque, tal cual sale.
-- ================================================================
--
-- LA IMAGEN: antes de repartir hay que abrir la bodega y ver qué hay
-- adentro. Esto es abrir la puerta y mirar — nada más.
--
-- POR QUÉ EXISTE: que un archivo esté en el repo no significa que se haya
-- corrido en la base (regla 0.1.2). Los cimientos y la bodega nueva están
-- escritos; esto pregunta si de verdad están puestos.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ¿ESTÁ PUESTO LO QUE CREEMOS QUE ESTÁ PUESTO?
--
-- QUÉ VER: la fila de la FOTO es la más importante de todas. Si dice 0,
-- no se escribe nada en la bodega nueva hasta que haya una (regla 0.6).
-- ================================================================
select 1 as n, 'Bodega nueva (central) · productos activos' as pregunta,
       (select count(*) from public.productos where sede='central' and activo='SÍ')::text as respuesta
union all
select 2, 'Bodega nueva · cuántos ya tienen algo contado',
       (select count(*) from public.productos
         where sede='central' and activo='SÍ' and coalesce(stock_actual,0) > 0)::text
union all
select 3, 'Bodega nueva · FOTO guardada (días en historial)',
       (select count(distinct fecha) from public.historial where sede='central')::text
union all
select 4, 'Bodega vieja · sigue intacta (activos)',
       (select count(*) from public.productos where sede='bodega' and activo='SÍ')::text
union all
select 5, 'Cimiento · columna unidad en productos',
       (select case when exists (select 1 from information_schema.columns
                                  where table_schema='public' and table_name='productos'
                                    and column_name='unidad') then 'SÍ' else 'NO' end)
union all
select 6, 'Cimiento · tabla producto_enlace (los gemelos)',
       (select case when to_regclass('public.producto_enlace') is not null then 'SÍ' else 'NO' end)
union all
select 7, 'Cimiento · tabla movimientos (el libro)',
       (select case when to_regclass('public.movimientos') is not null then 'SÍ' else 'NO' end)
union all
select 8, 'Cuaderno · scripts de bodega anotados',
       (select count(*) from public.migraciones_aplicadas where archivo like '%bodega%')::text
order by 1;


-- ================================================================
-- BLOQUE 2 — QUÉ HAY QUE MOSTRAR, Y CON QUÉ SE ENLAZA
--
-- Son dos resultados. El primero es el crítico de hoy en las 3 sedes,
-- contado EXACTAMENTE con la misma regla que usa la app en pantalla
-- (estado(): en 0 siempre es crítico, y también si está en el mínimo o
-- por debajo). El segundo mide cuánto trabajo son los gemelos.
--
-- QUÉ VER (primer resultado): la columna 'critico'. En central va a dar
-- casi todo, y eso es correcto: está en 0 hasta que se cuente.
-- QUÉ VER (primer resultado, columna de la derecha): 'con_bodega_en_el_nombre'
-- son los productos de bodega metidos dentro de Angamos, los que anotaste
-- el 6 de agosto. Ensucian la tarjeta de crítico de Angamos.
-- ================================================================
select sede,
       count(*) filter (where activo='SÍ')                                   as activos,
       count(*) filter (where activo='SÍ' and stock_actual is not null
                          and (stock_actual <= 0
                               or (stock_min is not null and stock_actual <= stock_min))) as critico,
       count(*) filter (where activo='SÍ' and stock_actual is null)          as sin_dato,
       count(*) filter (where activo='SÍ' and producto ilike '%bodega%')     as con_bodega_en_el_nombre
from public.productos
where sede in ('central','plaza','angamos')
group by sede
order by sede;

-- los gemelos: cuántos productos de la bodega nueva se llaman igual que
-- uno de cada local. Es la lista que después vas a confirmar par por par.
with c as (
  select translate(lower(regexp_replace(trim(coalesce(producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun') as clave
  from public.productos where sede='central' and activo='SÍ'
),
p as (
  select distinct translate(lower(regexp_replace(trim(coalesce(producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun') as clave
  from public.productos where sede='plaza' and activo='SÍ'
),
a as (
  select distinct translate(lower(regexp_replace(trim(coalesce(producto,'')),'\s+',' ','g')),'áéíóúüñ','aeiouun') as clave
  from public.productos where sede='angamos' and activo='SÍ'
)
select 'Productos de la bodega nueva'                as fila, count(*)::text as cuantos from c
union all
select 'se llaman igual que uno de Mall Plaza',      count(*)::text from c where clave in (select clave from p)
union all
select 'se llaman igual que uno de Angamos',         count(*)::text from c where clave in (select clave from a)
union all
select 'no calzan con ninguno de los dos',           count(*)::text from c
 where clave not in (select clave from p) and clave not in (select clave from a);


-- ================================================================
-- BLOQUE 3 — SOLO SI EL BLOQUE 1 DIJO "SÍ" EN LAS FILAS 6 Y 7
--
-- Si dijo NO, este bloque va a fallar y no pasa nada: significa que los
-- cimientos todavía no se corrieron. Avísame y te paso ese script.
--
-- QUÉ VER: los dos tienen que estar en 0. Nacen vacíos a propósito.
-- ================================================================
select 'producto_enlace · pares confirmados' as tabla, count(*)::text as filas
from public.producto_enlace
union all
select 'movimientos · anotaciones del libro', count(*)::text
from public.movimientos;
