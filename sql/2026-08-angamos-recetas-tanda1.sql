-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  crea las primeras 23 recetas de Angamos. Los bloques 2 y
--             3 SÍ ESCRIBEN. El 1 y el 4 solo miran.
--  QUÉ VER:   el bloque 1 tiene que devolver 23 filas y hay que
--             mirarlas antes de seguir. El bloque 4 confirma.
-- ================================================================
--
-- QUÉ ES UNA RECETA, con una imagen: es la instrucción "cuando vendas
-- esto en Fudo, bájame esto otro del inventario". Estas 23 son las más
-- simples que existen — se vende una dona, baja una dona.
--
-- ⚠️ ANGAMOS ESTÁ EN MODO REAL. Estas recetas descuentan de verdad
-- desde la primera venta. Por eso son 23 y no 170: si algo está mal
-- enlazado, se nota en una tarde y se arregla, en vez de descubrirlo
-- dentro de un mes con el inventario torcido.
--
-- QUÉ **NO** ESTÁ ACÁ, a propósito:
--   · los insumos de barra (pulpas, té de hoja, syrups, azúcar flor,
--     naranjas, limones, bombillas, collarines) — en Mall Plaza se
--     decidió que NO descuentan porque no se pueden contar por unidad.
--     Hasta que Jhon confirme si en Angamos es igual, no se tocan.
--   · los combos (los "+ CAFE", "+ SPRITE") — los ve administración.
--   · los cafés, tés y jugos — necesitan varios insumos y eso depende
--     de la medición de granel que está en curso (§10).
--
-- CÓMO SE DESHACE: está al final del archivo.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — VISTA PREVIA. MIRARLA ANTES DE SEGUIR.
--
-- QUÉ VER: 23 filas. Leer la frase de la última columna como si fuera
-- una instrucción al mesón. Si alguna no tiene sentido, PARAR y avisar.
-- ================================================================
with elegidos(nombre_fudo) as (values
  ('Agua con gas'), ('Agua sin gas'), ('sprite normal'),
  ('Pan masa madre'), ('café molido 250 gr'),
  ('Pizza Champiñon'), ('Pizza Hawaiana'), ('Pizza Pepperoni'),
  ('Alfajor artesanal'), ('Cachitos'), ('MACARRONS'), ('Maicenitos'),
  ('brownie'), ('Cannolis Pistacho'),
  ('Donas Frambuesa'), ('donas nutella'), ('donas oreo'),
  ('Galleton Avena con Pasas'), ('Galleton Red Velvet'),
  ('Mini muffin'), ('Muffin caramelo'),
  ('Pie de limón'), ('Volcán de chocolate')
),
inv as (
  select id, producto, rubro,
         lower(translate(regexp_replace(trim(producto),'\s+',' ','g'),
               'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos where sede='angamos' and activo='SÍ'
)
select f.nombre                                     as se_vende_en_fudo,
       i.producto                                   as descuenta,
       i.rubro                                      as de_la_seccion,
       'vender 1 "' || f.nombre || '" baja 1 "' || i.producto || '"' as la_instruccion
from elegidos e
join public.fudo_productos f
  on f.sede='angamos' and f.activo and f.nombre = e.nombre_fudo
join inv i
  on i.clave = lower(translate(regexp_replace(trim(f.nombre),'\s+',' ','g'),
                     'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun'))
order by i.rubro, f.nombre;


-- ================================================================
-- BLOQUE 2 — CREAR LAS RECETAS (la cabecera)
--
-- Se puede correr las veces que quieras: si la receta ya existe, no
-- la duplica.
-- ================================================================
insert into public.recetas (sede, fudo_product_id, fudo_product_nombre, activo)
select 'angamos', f.fudo_product_id, f.nombre, true
from public.fudo_productos f
where f.sede='angamos' and f.activo
  and f.nombre in (
    'Agua con gas','Agua sin gas','sprite normal',
    'Pan masa madre','café molido 250 gr',
    'Pizza Champiñon','Pizza Hawaiana','Pizza Pepperoni',
    'Alfajor artesanal','Cachitos','MACARRONS','Maicenitos',
    'brownie','Cannolis Pistacho',
    'Donas Frambuesa','donas nutella','donas oreo',
    'Galleton Avena con Pasas','Galleton Red Velvet',
    'Mini muffin','Muffin caramelo',
    'Pie de limón','Volcán de chocolate')
on conflict (sede, fudo_product_id) do nothing;


-- ================================================================
-- BLOQUE 3 — DECIRLE A CADA RECETA QUÉ DESCUENTA
--
-- Una línea por receta, cantidad 1, aplica siempre (sirva en local o
-- para llevar, da lo mismo: es el mismo producto).
-- ================================================================
insert into public.receta_items (receta_id, producto_id, cantidad, aplica)
select r.id, p.id, 1, 'siempre'
from public.recetas r
join public.fudo_productos f
  on f.sede='angamos' and f.fudo_product_id = r.fudo_product_id
join public.productos p
  on p.sede='angamos' and p.activo='SÍ'
 and lower(translate(regexp_replace(trim(p.producto),'\s+',' ','g'),
           'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun'))
   = lower(translate(regexp_replace(trim(f.nombre),'\s+',' ','g'),
           'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun'))
where r.sede='angamos' and r.activo
on conflict (receta_id, producto_id) do nothing;


-- ================================================================
-- BLOQUE 4 — COMPROBAR QUE QUEDÓ BIEN
--
-- QUÉ VER: "recetas" y "con_insumo" tienen que dar el MISMO número, y
-- "sin_insumo" tiene que dar 0. Una receta sin insumo es una receta
-- que no descuenta nada — es justo lo que el chequeo de salud
-- (bloque 10) sale a buscar.
-- ================================================================
select count(*)                                          as recetas,
       count(*) filter (where ri.receta_id is not null)   as con_insumo,
       count(*) filter (where ri.receta_id is null)       as sin_insumo,
       case when count(*) filter (where ri.receta_id is null) = 0
            then '✅ todas descuentan algo'
            else '🔴 hay recetas que apuntan al vacío — avisar' end as veredicto
from public.recetas r
left join (select distinct receta_id from public.receta_items) ri
       on ri.receta_id = r.id
where r.sede='angamos' and r.activo;


-- ================================================================
-- CÓMO SE DESHACE
--
-- Borra SOLO estas 23 recetas, no las que se hagan después a mano.
-- Correr los dos, en este orden:
--
-- delete from public.receta_items
--  where receta_id in (
--    select r.id from public.recetas r
--     where r.sede='angamos'
--       and r.fudo_product_nombre in (
--         'Agua con gas','Agua sin gas','sprite normal',
--         'Pan masa madre','café molido 250 gr',
--         'Pizza Champiñon','Pizza Hawaiana','Pizza Pepperoni',
--         'Alfajor artesanal','Cachitos','MACARRONS','Maicenitos',
--         'brownie','Cannolis Pistacho',
--         'Donas Frambuesa','donas nutella','donas oreo',
--         'Galleton Avena con Pasas','Galleton Red Velvet',
--         'Mini muffin','Muffin caramelo',
--         'Pie de limón','Volcán de chocolate'));
--
-- delete from public.recetas
--  where sede='angamos'
--    and fudo_product_nombre in ( ...la misma lista... );
--
-- ⚠️ Deshacer NO devuelve el stock que ya se descontó. Eso se corrige
-- contando, como siempre.
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-recetas-tanda1.sql', 'Jhon', 'lo corrió Jhon',
        'Primeras 23 recetas de Angamos: un producto de Fudo -> un insumo del inventario, cantidad 1')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
