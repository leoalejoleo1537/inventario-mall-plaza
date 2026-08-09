-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        5 bloques. Correr UNO POR UNO y mandarme el resultado.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  NADA. Solo mira y cuenta. No crea, no borra, no cambia
--             ni un producto. Es un informe (regla §0).
--  QUÉ VER:   el bloque 5 es el resumen; los otros son el detalle.
-- ================================================================
--
-- PARA QUÉ ES: para que el reparto pueda RESTAR de bodega, el sistema
-- tiene que saber qué producto de bodega es el gemelo de cada producto
-- de la sede. Son filas distintas con ids distintos, así que hay que
-- emparejarlas.
--
-- LA IMAGEN QUE LO EXPLICA: es como la lista de equivalencias entre dos
-- bodegas que usan nombres distintos para lo mismo. Alguien la escribe
-- UNA vez, y después todos los papeles se entienden solos.
--
-- POR QUÉ NO LO HAGO AUTOMÁTICO POR NOMBRE: es exactamente lo que falló
-- con los macarrons — la relación vivía escondida dentro del nombre del
-- producto, alguien lo escribió distinto, y la relación se rompió sin que
-- nadie lo viera. Costó un sobre-stock que hubo que devolver.
-- Acá el programa PROPONE y tú confirmas, igual que hicimos con las 85
-- recetas de Angamos.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL PANORAMA
--
-- Cuántos productos activos tiene cada sede. Sirve para saber de qué
-- tamaño es el trabajo antes de empezarlo.
-- ================================================================
select sede,
       count(*)                                          as productos_activos,
       count(*) filter (where coalesce(stock_actual,0) > 0) as con_stock,
       count(distinct rubro)                             as secciones
from public.productos
where activo = 'SÍ'
group by sede
order by sede;


-- ================================================================
-- BLOQUE 2 — LOS PRODUCTOS DE BODEGA METIDOS EN OTRA SEDE
--
-- Esto es el pendiente que anotamos el 2026-08-06: en Angamos hay
-- productos que se llaman "Bodega leche de avena" y similares, que son
-- de la bodega central y no de la sede.
--
-- NO los toco. Solo los listo para que decidas: moverlos a bodega,
-- apagarlos, o dejarlos.
--
-- QUÉ VER: la columna "stock_actual". Si están todos en 0, moverlos o
-- apagarlos no le cambia el número a nadie.
-- ================================================================
select id, sede, producto, rubro, stock_actual, tipo
from public.productos
where activo = 'SÍ'
  and sede <> 'bodega'
  and producto ilike '%bodega%'
order by sede, producto;


-- ================================================================
-- BLOQUE 3 — LOS PARES QUE CALZAN EXACTO
--
-- Mismo nombre en bodega y en la sede, ignorando mayúsculas, tildes,
-- espacios de más, el apellido " Vitrina"/" Congelador" y el prefijo
-- "Bodega ".
--
-- Estos son los fáciles: los que salgan acá se pueden enlazar sin
-- pensarlos mucho. Igual los vas a ver antes de que se escriba nada.
--
-- ⚠️ MIRAR LA COLUMNA "ojo". Como la comparación ignora el prefijo
-- "Bodega ", un producto contaminado del bloque 2 puede aparecer acá
-- como si fuera un calce perfecto — y enlazarlo sería enlazarlo a algo
-- que está por desaparecer. Esas filas salen marcadas. No las escondo
-- a propósito: esconderlas es cómo un error se vuelve invisible.
-- ================================================================
with n as (
  select id, sede, producto, rubro, stock_actual,
         regexp_replace(
           regexp_replace(
             regexp_replace(
               translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                         'áéíóúüñ', 'aeiouun'),
               '^bodega\s+', ''),
             '\s+(vitrina|congelador)$', ''),
           '\s+de\s+dulces$', '')                       as clave
  from public.productos
  where activo = 'SÍ'
)
select b.id      as id_bodega,
       b.producto as en_bodega,
       s.sede    as sede_destino,
       s.id      as id_sede,
       s.producto as en_la_sede,
       s.rubro   as seccion_en_la_sede,
       b.stock_actual as hay_en_bodega,
       case when s.producto ilike '%bodega%'
            then '⚠️ es un contaminado del bloque 2 — NO enlazar todavía' end as ojo
from n b
join n s on s.clave = b.clave and s.sede <> 'bodega'
where b.sede = 'bodega'
order by (s.producto ilike '%bodega%') desc, s.sede, b.producto;


-- ================================================================
-- BLOQUE 4 — LOS DE BODEGA SIN PAREJA EXACTA, CON SU CANDIDATO
--
-- Acá está el trabajo de verdad. Cuando el nombre no calza letra por
-- letra, propongo el candidato donde un nombre CONTIENE al otro
-- ("Torta amor" dentro de "Trozo torta amor").
--
-- ⚠️ EL CANDIDATO PROPONE, NO DECIDE. En Angamos el automático se
-- equivocó justo en el producto de más peso: propuso "Croissant manjar"
-- para "Croissant Jamon Queso", que era insumo de 11 recetas.
--
-- QUÉ VER: si "candidato" está vacío, ese producto de bodega no tiene
-- gemelo — puede ser normal (algo que solo existe en bodega) o puede
-- faltar crearlo en la sede.
--
-- Y MIRAR "cuantos_candidatos": si dice 1, la propuesta es sólida. Si
-- dice 5, es que "Leche" se parece a leche de avena, leche condensada y
-- leche sin lactosa, y elegí una sola para mostrarte. Ahí hay que mirar
-- de verdad. Un número alto no es un error del informe: es el aviso de
-- que ese caso no se puede automatizar.
-- ================================================================
with n as (
  select id, sede, producto, stock_actual,
         regexp_replace(
           regexp_replace(
             regexp_replace(
               translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                         'áéíóúüñ', 'aeiouun'),
               '^bodega\s+', ''),
             '\s+(vitrina|congelador)$', ''),
           '\s+de\s+dulces$', '')                       as clave
  from public.productos
  where activo = 'SÍ'
),
sin_par as (
  select b.* from n b
  where b.sede = 'bodega'
    and not exists (select 1 from n s where s.sede <> 'bodega' and s.clave = b.clave)
),
-- Los candidatos de cada uno. El "escape" del final NO es adorno: sin él,
-- un producto que llevara % o _ en el nombre se comportaría como comodín
-- y emparejaría con cualquier cosa, sin que nada lo delatara.
cand as (
  select b.id as id_bodega, s.sede, s.id as id_cand, s.producto as cand,
         abs(length(s.clave) - length(b.clave)) as distancia
  from sin_par b
  join n s
    on s.sede <> 'bodega'
   and length(b.clave) > 3
   and (s.clave like '%' || replace(replace(replace(b.clave,'\','\\'),'%','\%'),'_','\_') || '%'
     or b.clave like '%' || replace(replace(replace(s.clave,'\','\\'),'%','\%'),'_','\_') || '%')
)
select b.id            as id_bodega,
       b.producto      as en_bodega,
       b.stock_actual  as hay_en_bodega,
       c.sede          as sede_candidata,
       c.id_cand       as id_candidato,
       c.cand          as candidato,
       coalesce(t.cuantos, 0) as cuantos_candidatos,
       case when c.cand ilike '%bodega%' then '⚠️ es un contaminado del bloque 2'
            when t.cuantos > 1          then '⚠️ hay ' || t.cuantos || ' posibles — mirar'
       end as ojo
from sin_par b
left join lateral (
  select count(*) as cuantos from cand x where x.id_bodega = b.id
) t on true
left join lateral (
  select x.sede, x.id_cand, x.cand from cand x
  where x.id_bodega = b.id
  order by x.distancia, x.cand
  limit 1
) c on true
order by (c.id_cand is null), coalesce(t.cuantos,0) desc, b.producto;


-- ================================================================
-- BLOQUE 5 — EL RESUMEN, que es el número que importa
--
-- Cuántos productos de bodega tienen gemelo y cuántos no. Si "calzan
-- exacto" es alto, el trabajo de revisión es corto.
-- ================================================================
with n as (
  select id, sede, producto,
         regexp_replace(
           regexp_replace(
             regexp_replace(
               translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                         'áéíóúüñ', 'aeiouun'),
               '^bodega\s+', ''),
             '\s+(vitrina|congelador)$', ''),
           '\s+de\s+dulces$', '')                       as clave
  from public.productos
  where activo = 'SÍ'
)
select count(*) filter (where b.sede = 'bodega')                       as productos_en_bodega,
       count(*) filter (where b.sede = 'bodega' and ex.hay)            as calzan_exacto,
       count(*) filter (where b.sede = 'bodega' and not ex.hay)        as hay_que_revisar,
       -- de los que "calzan", cuántos calzan solo contra un contaminado
       count(*) filter (where b.sede = 'bodega' and ex.hay
                          and not ex.hay_limpio)                       as calzan_solo_con_contaminado,
       (select count(*) from n c
         where c.sede <> 'bodega' and c.producto ilike '%bodega%')     as contaminados_en_las_sedes
from n b
cross join lateral (
  select exists (select 1 from n s
                  where s.sede <> 'bodega' and s.clave = b.clave)      as hay,
         exists (select 1 from n s
                  where s.sede <> 'bodega' and s.clave = b.clave
                    and s.producto not ilike '%bodega%')               as hay_limpio
) ex;


-- ================================================================
-- LO QUE VIENE DESPUÉS (todavía NO se hace acá)
--
-- Con el resultado de estos 5 bloques armo la tabla de enlace y te la
-- mando ya revisada, para que la mires antes de que escriba nada.
-- Ese script sí escribirá — y va a llevar su vista previa y su deshacer.
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-bodega-informe-enlaces.sql', 'Jhon', 'lo corrió Jhon',
        'Informe de SOLO LECTURA: propone los pares bodega<->sede para el reparto que resta, y lista los productos de bodega metidos en otras sedes')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
