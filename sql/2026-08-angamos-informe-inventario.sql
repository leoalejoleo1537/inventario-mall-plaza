-- ================================================================
-- ANGAMOS · PASO 1 — LA FOTO ANTES DE MOVER NADA (2026-08-01)
--
-- Antes de mudarte de casa haces una lista de lo que hay en cada
-- caja. Esto es esa lista: mira el inventario de Angamos al lado del
-- de Mall Plaza y dice qué calza, qué está de más y qué falta.
--
-- NO TOCA NADA. No crea, no borra, no renombra, no cambia stock.
-- Es solo mirar. Puedes correrlo las veces que quieras.
--
-- ¿Para qué sirve? Las recetas de Mall Plaza dicen "el Brownie
-- descuenta el producto Brownie Vitrina". Para copiar esa receta a
-- Angamos hay que saber cómo se llama ahí el mismo producto. Este
-- informe arma esa correspondencia y, sobre todo, MUESTRA LOS CASOS
-- QUE NO SON OBVIOS para que los decidas tú.
--
-- ⚠️ CÓMO CORRERLO: selecciona con el mouse UN BLOQUE a la vez y
--    aprieta Run. El editor de Supabase solo muestra el resultado
--    del último select, así que si los corres todos juntos ves uno
--    solo. Guarda cada resultado antes de pasar al siguiente.
--
-- LA REGLA QUE ORDENA TODO ESTO (conversada el 2026-08-01):
--   · En Mall Plaza un mismo producto vive DOS VECES: la copia de la
--     vitrina y la del congelador. Es una necesidad del local.
--   · En Angamos NO. Angamos tiene su propia bodega, y ese inventario
--     todavía no se hace. Así que en Angamos solo existe la versión
--     de vitrina: un producto, una fila.
-- ================================================================


-- ================================================================
-- BLOQUE 0 — El tamaño de cada cosa
-- Para saber de qué números estamos hablando. Nada más.
-- ================================================================
select
  (select count(*) from public.productos where sede='plaza'   and activo='SÍ') as productos_plaza,
  (select count(*) from public.productos where sede='angamos' and activo='SÍ') as productos_angamos,
  (select count(*) from public.recetas   where sede='plaza')                   as recetas_plaza,
  (select count(*) from public.recetas   where sede='angamos')                 as recetas_angamos,
  (select count(*) from public.fudo_productos where sede='plaza'   and activo) as fudo_plaza,
  (select count(*) from public.fudo_productos where sede='angamos' and activo) as fudo_angamos;


-- ================================================================
-- BLOQUE A — PRODUCTOS QUE ESTÁN DOS VECES EN ANGAMOS
--
-- Esto es lo primero que hay que decidir. Un script de julio
-- (2026-07-duplicar-vitrina-en-congelador.sql) creó la copia de
-- congelador en las DOS sedes, pero Angamos no la necesita.
--
-- Tener el mismo producto dos veces obliga a las jefas a contar dos
-- veces lo mismo, y deja al emparejador sin saber a cuál apuntar.
--
-- LO QUE HAY QUE DECIDIR: si estas copias de Congelador se apagan
-- (activo='NO', no se borran, quedan por si acaso). NO lo hace este
-- script — es tu decisión. El script que lo aplica se escribe después,
-- con la lista que salga de acá ya revisada por ti.
-- ================================================================
with a as (
  select id, producto, rubro, stock_actual,
         translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') as n
  from public.productos
  where sede='angamos' and activo='SÍ'
)
select
  count(*)                                                        as veces,
  min(producto)                                                   as producto,
  string_agg(rubro || ' (stock ' || coalesce(stock_actual::text,'—') || ')',
             '   ·   ' order by rubro)                            as donde_esta
from a
group by n
having count(*) > 1
order by 2;


-- ================================================================
-- BLOQUE B — LOS INSUMOS DE LAS RECETAS DE PLAZA, Y SU PAREJA EN ANGAMOS
--
-- Este es el corazón del informe. Toma cada producto del inventario
-- que hoy descuenta alguna receta de Mall Plaza, y busca cómo se
-- llama el mismo producto en Angamos.
--
-- Para buscar, le quita el apellido de sección al nombre de Plaza:
-- "Brownie Vitrina" y "Brownie Congelador" se buscan los dos como
-- "brownie", que es como se llama en Angamos.
--
-- CÓMO LEER LA COLUMNA "estado":
--   ✓ pareja única      → listo, la receta se puede copiar sola
--   ⚠ varios candidatos → casi siempre es un duplicado del BLOQUE A.
--                         Se arregla solo cuando decidas ese bloque.
--   ✗ sin pareja        → hay que mirarlo. Puede ser (a) el mismo
--                         producto con otro nombre en Angamos, o
--                         (b) un producto que de verdad falta ahí.
--                         ESO LO DICES TÚ, no el script.
--
-- ⚠️ IMPORTANTE (regla 0.1.4 del archivo madre): que dos nombres no
--    calcen NO significa que algo esté mal. Significa que hay que
--    preguntar. Un "✗" es una pregunta, no un error.
-- ================================================================
with ins as (
  select distinct
    p.producto,
    p.rubro,
    regexp_replace(
      translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
      '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
    ) as base
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos    p  on p.id = ri.producto_id
  where r.sede = 'plaza'
),
ang as (
  select
    producto, rubro,
    regexp_replace(
      translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
      '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
    ) as base
  from public.productos
  where sede='angamos' and activo='SÍ'
)
select
  case
    when count(a.producto) = 1 then '✓ pareja única'
    when count(a.producto) = 0 then '✗ sin pareja — revisar'
    else '⚠ ' || count(a.producto) || ' candidatos'
  end                                                              as estado,
  i.producto                                                       as insumo_en_plaza,
  i.rubro                                                          as seccion_en_plaza,
  coalesce(string_agg(a.producto || ' [' || a.rubro || ']', '  ·  ' order by a.producto), '—')
                                                                   as en_angamos_seria
from ins i
left join ang a on a.base = i.base
group by i.producto, i.rubro
order by
  case when count(a.producto)=0 then 0 when count(a.producto)>1 then 1 else 2 end,
  i.producto;


-- ================================================================
-- BLOQUE B2 — El mismo resultado, pero contado
--
-- Cuántas LÍNEAS de receta (no productos distintos) quedarían de cada
-- color. Sirve para saber si esto es un rato de revisión o un día.
-- ================================================================
with lin as (
  select
    ri.id,
    regexp_replace(
      translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
      '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
    ) as base
  from public.recetas r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos    p  on p.id = ri.producto_id
  where r.sede = 'plaza'
),
ang as (
  select
    regexp_replace(
      translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
      '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
    ) as base
  from public.productos
  where sede='angamos' and activo='SÍ'
),
conteo as (
  select l.id, (select count(*) from ang a where a.base = l.base) as candidatos
  from lin l
)
select
  count(*)                                          as lineas_de_receta_en_plaza,
  count(*) filter (where candidatos = 1)            as con_pareja_unica,
  count(*) filter (where candidatos > 1)            as ambiguas_por_duplicado,
  count(*) filter (where candidatos = 0)            as sin_pareja
from conteo;


-- ================================================================
-- BLOQUE C — LO QUE SOLO EXISTE EN ANGAMOS
--
-- Productos activos de Angamos que no tienen ningún equivalente en
-- Mall Plaza. Pueden ser de la carta del local, o restos de cuando
-- esa sede se usaba como bodega.
--
-- No hay nada que arreglar acá: es para que los mires y digas cuáles
-- se quedan. (Los que aparecen dos veces salen en el BLOQUE A.)
-- ================================================================
with a as (
  select producto, rubro, stock_actual,
         regexp_replace(
           translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
           '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
         ) as base
  from public.productos where sede='angamos' and activo='SÍ'
),
p as (
  select regexp_replace(
           translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
           '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
         ) as base
  from public.productos where sede='plaza' and activo='SÍ'
)
select distinct a.producto, a.rubro as seccion, a.stock_actual
from a
where not exists (select 1 from p where p.base = a.base)
order by a.rubro, a.producto;


-- ================================================================
-- BLOQUE D — ANOTAR EN EL CUADERNO
--
-- Es la cartilla de vacunas: deja escrito que este informe se corrió.
-- Es la ÚNICA línea de todo el archivo que escribe algo, y escribe en
-- el cuaderno, no en el inventario.
-- ================================================================
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-informe-inventario.sql', 'Jhon', 'lo corrió en el SQL Editor',
        'Solo lectura. Foto del inventario de Angamos antes de replicar recetas')
on conflict (archivo) do update set aplicado_at = now();
