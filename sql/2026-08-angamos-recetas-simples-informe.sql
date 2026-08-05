-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  propone los pares "producto de Fudo Angamos -> producto
--             del inventario Angamos" para las recetas de UN insumo.
--             NO ESCRIBE NADA.
--  QUÉ VER:   el bloque 1 da los totales. Los bloques 3 y 4 son los
--             que hay que pegarme de vuelta.
-- ================================================================
--
-- POR QUÉ ESTO ES MÁS SIMPLE DE LO QUE PARECÍA: para una receta de UN
-- solo insumo no hacen falta las recetas de Mall Plaza. Se empareja
-- directo el catálogo de Fudo de Angamos contra el inventario de
-- Angamos — un solo salto de nombre en vez de dos, y los dos lados los
-- cargó la misma gente en la misma sede.
--
-- ⚠️ CORRER DESPUÉS de apagar los 14 duplicados de Congelador. Si no,
-- cada producto tiene dos candidatos y las recetas podrían quedar
-- apuntando a la copia que después se apaga.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL TAMAÑO DEL TRABAJO
--
-- QUÉ VER: cuántos productos de Fudo Angamos encuentran su pareja
-- exacta en el inventario. Ese número es cuántas recetas se pueden
-- armar de una.
-- ================================================================
with fudo as (
  select fudo_product_id, nombre,
         lower(translate(regexp_replace(trim(nombre),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.fudo_productos
  where sede='angamos' and activo
),
inv as (
  select id, producto, rubro,
         lower(translate(regexp_replace(trim(producto),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos
  where sede='angamos' and activo='SÍ'
),
pares as (
  select f.fudo_product_id, f.nombre,
         (select count(*) from inv i where i.clave = f.clave) as cuantos
  from fudo f
  where not exists (select 1 from public.recetas r
                     where r.sede='angamos' and r.fudo_product_id = f.fudo_product_id)
)
select case when cuantos = 1 then '1 · calza con UNO — se puede armar sola'
            when cuantos > 1 then '2 · calza con VARIOS — hay que elegir'
            else                  '3 · sin pareja — o es combo, o falta el insumo'
       end                                    as situacion,
       count(*)                               as cuantos_productos_de_fudo
from pares
group by 1
order by 1;


-- ================================================================
-- BLOQUE 2 — LA VISTA PREVIA DE LO QUE SE ARMARÍA
--
-- Solo MIRARLO acá, no hace falta pegármelo: son muchas filas.
-- Es la lista de recetas de un insumo que quedarían creadas.
--
-- QUÉ VER: pasar el ojo por la columna "descontaria". Si alguna se ve
-- rara, esa es la que hay que avisar.
-- ================================================================
with fudo as (
  select fudo_product_id, nombre,
         lower(translate(regexp_replace(trim(nombre),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.fudo_productos
  where sede='angamos' and activo
),
inv as (
  select id, producto, rubro,
         lower(translate(regexp_replace(trim(producto),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos
  where sede='angamos' and activo='SÍ'
)
select f.nombre                as se_vende_en_fudo,
       i.producto              as descontaria,
       i.rubro                 as de_la_seccion,
       i.id                    as producto_id
from fudo f
join inv  i on i.clave = f.clave
where not exists (select 1 from public.recetas r
                   where r.sede='angamos' and r.fudo_product_id = f.fudo_product_id)
  and (select count(*) from inv i2 where i2.clave = f.clave) = 1
order by i.rubro, f.nombre;


-- ================================================================
-- BLOQUE 3 — LOS QUE CALZAN CON VARIOS  ➜  PEGÁRMELO
--
-- Cada fila es un producto de Fudo que encontró más de un candidato en
-- el inventario. Casi siempre es el mismo nombre en dos secciones.
-- Alguien tiene que decir cuál — y ese alguien no es el sistema.
-- ================================================================
with fudo as (
  select fudo_product_id, nombre,
         lower(translate(regexp_replace(trim(nombre),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.fudo_productos
  where sede='angamos' and activo
),
inv as (
  select id, producto, rubro,
         lower(translate(regexp_replace(trim(producto),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos
  where sede='angamos' and activo='SÍ'
)
select f.nombre as se_vende_en_fudo,
       (select string_agg(i.rubro || ' (id ' || i.id || ')', '   ·   ' order by i.rubro)
          from inv i where i.clave = f.clave) as candidatos
from fudo f
where not exists (select 1 from public.recetas r
                   where r.sede='angamos' and r.fudo_product_id = f.fudo_product_id)
  and (select count(*) from inv i2 where i2.clave = f.clave) > 1
order by f.nombre;


-- ================================================================
-- BLOQUE 4 — LOS QUE NO CALZAN CON NADA  ➜  PEGÁRMELO
--
-- Acá van a caer TRES cosas mezcladas, y separarlas es el trabajo:
--   · combos y promociones      -> no son mías, las ve administración
--   · el mismo producto escrito distinto -> hay que emparejarlo
--   · insumos que de verdad faltan       -> hay que crearlos
--
-- La columna "parecido_en_inventario" propone, no concluye.
-- Se muestran solo los que Fudo tiene con precio, para dejar fuera
-- ingredientes sueltos y modificadores que no se venden solos.
-- ================================================================
with fudo as (
  select fudo_product_id, nombre, precio,
         lower(translate(regexp_replace(trim(nombre),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.fudo_productos
  where sede='angamos' and activo
),
fudo_clave as (
  select f.*,
         (select w from regexp_split_to_table(f.clave,'\s+') w
           where length(w) >= 4 order by length(w) desc, w limit 1) as palabra
  from fudo f
),
inv as (
  select id, producto, rubro,
         lower(translate(regexp_replace(trim(producto),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos
  where sede='angamos' and activo='SÍ'
)
select fc.nombre  as se_vende_en_fudo,
       fc.precio,
       coalesce((select string_agg(distinct i.producto, '  ·  ')
                   from inv i
                  where fc.palabra is not null and i.clave like '%'||fc.palabra||'%'),
                '— nada parecido —') as parecido_en_inventario
from fudo_clave fc
where not exists (select 1 from public.recetas r
                   where r.sede='angamos' and r.fudo_product_id = fc.fudo_product_id)
  and not exists (select 1 from inv i where i.clave = fc.clave)
  and coalesce(fc.precio,0) > 0
order by fc.nombre;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-recetas-simples-informe.sql', 'Jhon', 'lo corrió Jhon',
        'Solo lectura. Propuso los pares Fudo Angamos -> inventario Angamos para las recetas de un insumo')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
