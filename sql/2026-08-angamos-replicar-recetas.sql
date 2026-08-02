-- ================================================================
-- ANGAMOS · PASO 2 — COPIAR LAS RECETAS DE MALL PLAZA (2026-08-01)
--
-- Una receta dice: "cuando en Fudo se venda un Brownie, descuenta un
-- Brownie del inventario". Angamos vende la misma carta, así que las
-- recetas son las mismas. Lo que cambia es el número de serie.
--
-- POR QUÉ NO SE COPIA Y LISTO: la receta no guarda el nombre del
-- producto de Fudo, guarda su CÓDIGO. Y Angamos es otra cuenta de
-- Fudo, con códigos distintos. Copiar la fila tal cual dejaría 168
-- recetas apuntando al vacío: el motor no encontraría nada, el
-- inventario no se movería, y nadie se enteraría. Es el error más
-- probable de toda esta migración (§9.2 del archivo madre).
--
-- LO QUE SÍ SE HACE: se copia la ESTRUCTURA, buscando por nombre en
-- los dos saltos:
--
--     Fudo plaza "Brownie-solo"        →  Fudo angamos "Brownie-solo"
--         ↓ y sus insumos
--     producto plaza "Brownie Vitrina" →  producto angamos "Brownie"
--
-- El segundo salto le quita el apellido de sección, porque en Angamos
-- no hay copia de congelador: un producto, una fila. (Angamos tiene su
-- propia bodega, y ese inventario todavía no se hace.)
--
-- ⚠️ ANTES DE ESTE ARCHIVO hay que haber hecho DOS cosas:
--    1) correr 2026-08-angamos-informe-inventario.sql y revisar sus
--       bloques A y B;
--    2) traer el catálogo de Fudo de Angamos: en la app, elegir Parque
--       Angamos → Recetas → "↻ Productos de Fudo". Sin eso no hay con
--       qué emparejar, y el PASO 2 se detiene solo avisándolo.
--
-- ⚠️ CÓMO CORRERLO: **selecciona un PASO COMPLETO con el mouse** y
--    aprieta Run. Cada paso arma su propia lista de trabajo y la
--    borra al final, así que no se puede correr media hoja.
--    Primero el PASO 1, que solo muestra. El PASO 2 es el único que
--    escribe.
--
-- Los dos pasos calculan la lista con EL MISMO código, a propósito:
-- así lo que muestra el PASO 1 es exactamente lo que hace el PASO 2.
--
-- Es idempotente: correrlo dos veces no duplica nada.
-- ================================================================


-- ================================================================
-- PASO 1 — VISTA PREVIA. No toca nada. (seleccionar hasta el "drop")
--
-- Léelo como una lista de mudanza: qué caja llega entera, cuál llega
-- incompleta y cuál no tiene dirección a la que ir.
--
--   ✓ se copia          → todos sus insumos tienen pareja única
--   ✗ no está en Fudo   → ese producto no existe en el Fudo de Angamos
--   ⚠ insumo sin pareja → falta ese producto en el inventario de Angamos
--   ⚠ insumo ambiguo    → hay dos productos con ese nombre en Angamos
--                         (son los duplicados del bloque A del informe)
--   ⚠ mismo insumo, dos reglas → dos líneas de Plaza caen en el mismo
--                         producto de Angamos pero con un "aplica"
--                         distinto. Se hace a mano.
--
-- Las que NO salen ✓ quedan fuera A PROPÓSITO. Una receta a medias es
-- peor que ninguna: descontaría solo una parte de lo vendido y nadie
-- lo notaría. Esas se arreglan primero y después se re-corre esto.
-- ================================================================
drop table if exists _plan_angamos;
create temporary table _plan_angamos as
with fp_ang as (
  select fudo_product_id,
         translate(lower(regexp_replace(trim(nombre),'\s+',' ','g')),'áéíóúñü','aeiounu') as n
  from public.fudo_productos where sede='angamos' and activo
),
prod_ang as (
  select id,
         regexp_replace(
           translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
           '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
         ) as base
  from public.productos where sede='angamos' and activo='SÍ'
),
plaza as (
  select
    r.id                  as receta_plaza,
    r.fudo_product_nombre as producto_fudo,
    p.producto            as insumo_plaza,
    ri.cantidad,
    ri.aplica,
    translate(lower(regexp_replace(trim(r.fudo_product_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu') as n_fudo,
    regexp_replace(
      translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
      '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
    ) as base_insumo
  from public.recetas      r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos    p  on p.id = ri.producto_id
  where r.sede='plaza' and r.activo
)
select
  z.receta_plaza,
  z.producto_fudo,
  z.insumo_plaza,
  z.cantidad,
  z.aplica,
  (select count(*)                from fp_ang   f where f.n    = z.n_fudo)      as veces_en_fudo,
  (select min(f.fudo_product_id)  from fp_ang   f where f.n    = z.n_fudo)      as fudo_id_angamos,
  (select count(*)                from prod_ang a where a.base = z.base_insumo) as candidatos_insumo,
  (select min(a.id)               from prod_ang a where a.base = z.base_insumo) as producto_angamos
from plaza z;

select
  case
    when min(veces_en_fudo) = 0                                  then '✗ no está en Fudo Angamos'
    when max(veces_en_fudo) > 1                                  then '⚠ nombre repetido en Fudo Angamos'
    when min(candidatos_insumo) = 0                              then '⚠ insumo sin pareja'
    when max(candidatos_insumo) > 1                              then '⚠ insumo ambiguo (duplicado)'
    when count(distinct producto_angamos)
       <> count(distinct producto_angamos || '|' || aplica)      then '⚠ mismo insumo, dos reglas'
    else                                                              '✓ se copia'
  end                                                            as estado,
  producto_fudo,
  count(*)                                                       as lineas,
  string_agg(insumo_plaza || ' x' || cantidad ||
             case when aplica <> 'siempre' then ' (' || aplica || ')' else '' end,
             '  ·  ' order by insumo_plaza)                      as descuenta_en_plaza
from _plan_angamos
group by receta_plaza, producto_fudo
order by 1, 2;

drop table if exists _plan_angamos;


-- ================================================================
-- PASO 2 — APLICAR. (seleccionar todo el paso, hasta el "drop" final)
--
-- Esta es la única parte que escribe. Solo toca las recetas que en el
-- PASO 1 salieron "✓ se copia"; todo lo demás lo deja como está.
-- ================================================================

-- ---------- 2a) freno de seguridad ----------
-- Si el catálogo de Fudo de Angamos está vacío, este script no crearía
-- nada y parecería que funcionó. Ese silencio es justo lo que el
-- archivo madre prohíbe (§0.5), así que acá se detiene y lo dice.
do $$
declare v_n int;
begin
  select count(*) into v_n from public.fudo_productos where sede='angamos' and activo;
  if v_n = 0 then
    raise exception E'DETENIDO. El catálogo de Fudo de Angamos está vacío.\n\nHay que traerlo primero: abre la app, elige Parque Angamos, entra a Recetas y aprieta "↻ Productos de Fudo". Después vuelve a correr este paso.';
  end if;
end $$;

-- ---------- 2b) armar la misma lista del PASO 1 ----------
drop table if exists _plan_angamos;
create temporary table _plan_angamos as
with fp_ang as (
  select fudo_product_id,
         translate(lower(regexp_replace(trim(nombre),'\s+',' ','g')),'áéíóúñü','aeiounu') as n
  from public.fudo_productos where sede='angamos' and activo
),
prod_ang as (
  select id,
         regexp_replace(
           translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
           '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
         ) as base
  from public.productos where sede='angamos' and activo='SÍ'
),
plaza as (
  select
    r.id                  as receta_plaza,
    r.fudo_product_nombre as producto_fudo,
    p.producto            as insumo_plaza,
    ri.cantidad,
    ri.aplica,
    translate(lower(regexp_replace(trim(r.fudo_product_nombre),'\s+',' ','g')),'áéíóúñü','aeiounu') as n_fudo,
    regexp_replace(
      translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu'),
      '\s+(de\s+)?(vitrina|congelador)(\s+de\s+(dulces|tortas|bebidas))?$', ''
    ) as base_insumo
  from public.recetas      r
  join public.receta_items ri on ri.receta_id = r.id
  join public.productos    p  on p.id = ri.producto_id
  where r.sede='plaza' and r.activo
)
select
  z.receta_plaza, z.producto_fudo, z.insumo_plaza, z.cantidad, z.aplica,
  (select count(*)                from fp_ang   f where f.n    = z.n_fudo)      as veces_en_fudo,
  (select min(f.fudo_product_id)  from fp_ang   f where f.n    = z.n_fudo)      as fudo_id_angamos,
  (select count(*)                from prod_ang a where a.base = z.base_insumo) as candidatos_insumo,
  (select min(a.id)               from prod_ang a where a.base = z.base_insumo) as producto_angamos
from plaza z;

-- las recetas que llegan enteras, sin un solo cabo suelto
drop table if exists _listas_angamos;
create temporary table _listas_angamos as
select receta_plaza,
       min(producto_fudo)   as producto_fudo,
       min(fudo_id_angamos) as fudo_id_angamos
from _plan_angamos
group by receta_plaza
having min(veces_en_fudo) = 1
   and max(veces_en_fudo) = 1
   and min(candidatos_insumo) = 1
   and max(candidatos_insumo) = 1
   and count(distinct producto_angamos) = count(distinct producto_angamos || '|' || aplica);

-- ---------- 2c) crear las recetas ----------
insert into public.recetas(sede, fudo_product_id, fudo_product_nombre)
select 'angamos', l.fudo_id_angamos, l.producto_fudo
from _listas_angamos l
on conflict (sede, fudo_product_id) do nothing;

-- ---------- 2d) crear sus insumos ----------
-- Si dos insumos de Plaza ("X Vitrina" y "X Congelador") caen sobre el
-- mismo producto de Angamos, se suman en una sola línea: la tabla no
-- admite el mismo producto dos veces en una receta.
insert into public.receta_items(receta_id, producto_id, cantidad, aplica)
select ra.id, j.producto_angamos, j.cantidad, j.aplica
from (
  select p.receta_plaza, p.producto_angamos,
         sum(p.cantidad) as cantidad, min(p.aplica) as aplica
  from _plan_angamos p
  join _listas_angamos l on l.receta_plaza = p.receta_plaza
  group by p.receta_plaza, p.producto_angamos
) j
join _listas_angamos l  on l.receta_plaza = j.receta_plaza
join public.recetas  ra on ra.sede='angamos' and ra.fudo_product_id = l.fudo_id_angamos
-- no pisar recetas de angamos que ya tengan insumos (hechas a mano)
where not exists (select 1 from public.receta_items x where x.receta_id = ra.id)
on conflict (receta_id, producto_id) do nothing;

drop table if exists _plan_angamos;
drop table if exists _listas_angamos;


-- ================================================================
-- PASO 3 — COMPROBACIONES. Correr UNA a la vez.
-- ================================================================

-- 3a) ¿Cuántas recetas quedaron en cada sede?
select sede, count(*) as recetas from public.recetas group by sede order by sede;

-- 3b) ⚠️ DEBE SALIR VACÍO: recetas de angamos sin ningún insumo.
--     Una receta sin insumos no descuenta nada y no avisa.
select r.id, r.fudo_product_nombre
from public.recetas r
where r.sede='angamos'
  and not exists (select 1 from public.receta_items ri where ri.receta_id = r.id)
order by 2;

-- 3c) ⚠️ DEBE SALIR VACÍO: insumos que apuntan a un producto de otra
--     sede o desactivado. Sería descontarle a Mall Plaza lo que se
--     vendió en Angamos.
select r.fudo_product_nombre, p.producto, p.sede, p.activo
from public.recetas      r
join public.receta_items ri on ri.receta_id = r.id
join public.productos    p  on p.id = ri.producto_id
where r.sede='angamos' and (p.sede <> 'angamos' or coalesce(p.activo,'') <> 'SÍ')
order by 1;

-- 3d) Lo que quedó copiado, para revisarlo a ojo.
select r.fudo_product_nombre as producto_fudo,
       string_agg(p.producto || ' x' || ri.cantidad, '  ·  ' order by p.producto) as descuenta
from public.recetas      r
join public.receta_items ri on ri.receta_id = r.id
join public.productos    p  on p.id = ri.producto_id
where r.sede='angamos'
group by r.fudo_product_nombre
order by 1;

-- 3e) Lo que quedó AFUERA: productos de Fudo Angamos sin receta.
--     No es una falla: es la cobertura que falta.
select fp.nombre as sigue_sin_receta, fp.code
from public.fudo_productos fp
where fp.sede='angamos' and fp.activo
  and not exists (select 1 from public.recetas r
                  where r.sede='angamos' and r.fudo_product_id = fp.fudo_product_id)
order by 1;


-- ================================================================
-- PASO 4 — ANOTAR EN EL CUADERNO
-- ================================================================
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-replicar-recetas.sql', 'Jhon', 'lo corrió en el SQL Editor',
        'Copió a Angamos las recetas completas de Plaza, emparejando por nombre')
on conflict (archivo) do update set aplicado_at = now();
