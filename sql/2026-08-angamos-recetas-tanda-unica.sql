-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        6 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  crea 81 recetas de Angamos de una sola vez. Los bloques
--             1, 4 y 5 ESCRIBEN. El 2, 3 y 6 solo miran.
--  QUÉ VER:   el bloque 2 es la vista previa y NO se puede saltar. El
--             bloque 3 avisa si alguna pareja quedó suelta.
-- ================================================================
--
-- QUÉ ES UNA RECETA, con una imagen: es la instrucción "cuando vendas
-- esto en Fudo, bájame esto otro del inventario". Estas 81 son las más
-- simples que hay — se vende una dona, baja una dona.
--
-- CÓMO SE ARMÓ: se carga una tabla puente con los pares confirmados por
-- Jhon, y de ahí salen las recetas. Se hace así, y no con un
-- emparejador automático, porque la lista la revisó una persona. Las
-- comparaciones automáticas PROPONEN, no concluyen (regla 0.1.4).
--
-- LOS 81 SON TRES GRUPOS:
--   23  el nombre calza exacto en los dos lados
--   17  variantes "Pedidos Ya" — mismo producto, vendido por delivery
--   41  el mismo producto escrito distinto (Torta amor / Trozo torta
--       amor, Sandiwch jamón serrano / Sandwich Serrano)
--
-- QUÉ **NO** ESTÁ ACÁ, a propósito:
--   · los insumos de barra (pulpas, té de hoja, syrups, azúcar flor,
--     naranjas, limones, bombillas, collarines). Jhon confirmó el
--     2026-08-05: igual que en Mall Plaza, NO se descuentan por ahora.
--     Solo lo cuantificable.
--   · los combos ("+ CAFE", "+ SPRITE ZERO") — los ve administración.
--   · cafés, tés y jugos preparados — necesitan varios insumos y
--     dependen de la medición de granel que está en curso (§10).
--   · "producto prueba", "RESERVA", "Tostadas Admin", "cafe mediano
--     psicóloga" — no llevan receta.
--
-- CÓMO SE DESHACE: bloque 7, al final. Está escrito ANTES de correrlo.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — CARGAR LOS PARES CONFIRMADOS
--
-- Son 4 sentencias seguidas. Copiar TODO el bloque y apretar Run una
-- sola vez. Crea una tabla de trabajo que al final se borra.
-- ================================================================
drop table if exists public.angamos_mapa_recetas;
create table public.angamos_mapa_recetas(
  nombre_fudo text primary key,
  nombre_inv  text not null,
  grupo       text not null
);

-- --- Grupo 1: el nombre calza exacto (23) ---
insert into public.angamos_mapa_recetas values
 ('Agua con gas','Agua con gas','exacto'),
 ('Agua sin gas','Agua sin gas','exacto'),
 ('sprite normal','Sprite normal','exacto'),
 ('Pan masa madre','Pan masa madre','exacto'),
 ('café molido 250 gr','Café molido 250 gr','exacto'),
 ('Pizza Champiñon','Pizza Champiñón','exacto'),
 ('Pizza Hawaiana','Pizza Hawaiana','exacto'),
 ('Pizza Pepperoni','Pizza pepperoni','exacto'),
 ('Alfajor artesanal','Alfajor artesanal','exacto'),
 ('Cachitos','Cachitos','exacto'),
 ('MACARRONS','Macarrons','exacto'),
 ('Maicenitos','Maicenitos','exacto'),
 ('brownie','Brownie','exacto'),
 ('Cannolis Pistacho','Cannolis Pistacho','exacto'),
 ('Donas Frambuesa','Donas frambuesa','exacto'),
 ('donas nutella','Donas nutella','exacto'),
 ('donas oreo','Donas oreo','exacto'),
 ('Galleton Avena con Pasas','Galleton Avena con Pasas','exacto'),
 ('Galleton Red Velvet','Galleton Red Velvet','exacto'),
 ('Mini muffin','Mini muffin','exacto'),
 ('Muffin caramelo','Muffin caramelo','exacto'),
 ('Pie de limón','Pie de limón','exacto'),
 ('Volcán de chocolate','Volcan de chocolate','exacto');

-- --- Grupo 2: "Pedidos Ya" — mismo producto, por delivery (17) ---
insert into public.angamos_mapa_recetas values
 ('Alfajor artesanal Pedidos Ya','Alfajor artesanal','pedidos ya'),
 ('Kuchen Pedidos Ya','T. Kutchen manzana','pedidos ya'),
 ('Macarrons Pedidos Ya','Macarrons','pedidos ya'),
 ('Muffin zanahoria Pedidos Ya','Muffin de zanahoria','pedidos ya'),
 ('Pie de Limón Pedidos Ya','Pie de limón','pedidos ya'),
 ('Pie de plátano Pedidos Ya','Pie de plátano','pedidos ya'),
 ('Rollos de canela Pedidos Ya','Cinnamon rolls','pedidos ya'),
 ('Sandwich Jamón Serrano Pedidos Ya','Sandwich Serrano','pedidos ya'),
 ('Sandwich mechada luco Pedidos Ya','Sandwich Mechada','pedidos ya'),
 ('Sandwich pollo apaltado Pedidos Ya','Sandwich Apaltado','pedidos ya'),
 ('Sandwich capresse azapa Pedidos Ya','Sandwich Azapa','pedidos ya'),
 ('Tiramisu Pedidos Ya','Trozo de Tiramisu','pedidos ya'),
 ('Torta amor Pedidos Ya','Trozo torta amor','pedidos ya'),
 ('Torta de zanahoria Pedidos Ya','Trozo torta de zanahoria','pedidos ya'),
 ('Torta Hojarasca pedidos Ya','Trozo torta hojarasca','pedidos ya'),
 ('Torta Matilda Pedidos Ya','Trozo torta Matilda','pedidos ya'),
 ('Torta tres leche Pedidos Ya','Trozo torta tres leches','pedidos ya');

-- --- Grupo 3: mismo producto, escrito distinto (41) ---
insert into public.angamos_mapa_recetas values
 ('Alfajor manjar con coco','Alfajor manjar coco','otro nombre'),
 ('Bebida Coca cola normal','Unidad coca cola normal','otro nombre'),
 ('Bebida Coca cola zero','Unidad coca cola zero','otro nombre'),
 ('Bebida Sprite normal','Sprite normal','otro nombre'),
 ('Bebida Sprite zero','Sprite zero','otro nombre'),
 ('Bebida Ginger ale','Unidad ginger ale','otro nombre'),
 ('Brownie - solo','Brownie solo','otro nombre'),
 ('café grano 250gr','Café grano 250 gr','otro nombre'),
 ('Cannoli chip chocolate','Cannolis Chips Chocolate','otro nombre'),
 ('Cheescake Frambuesa','T. Cheesecake Fram','otro nombre'),
 ('Cheesecake Maracuya','T. Cheesecake Mara','otro nombre'),
 ('Cinnamon Roll Vegano','Cinnamon rolls','otro nombre'),
 ('Rollo de canela vegano','Cinnamon rolls','otro nombre'),
 ('Crema Chantilly porcion','crema chantilly','otro nombre'),
 ('Donas de oreo','Donas oreo','otro nombre'),
 ('Donas rellena de nutella','Donas nutella','otro nombre'),
 ('Kuchen de manzana','T. Kutchen manzana','otro nombre'),
 ('Media Luna Manjar','Medialuna manjar','otro nombre'),
 ('Medialuna dulce membrillo','Medialuna membrillo','otro nombre'),
 ('Medialunas tradicionales(sin relleno)','Medialuna tradicional','otro nombre'),
 ('Muffin Amapola Vegano','Muffin amapola','otro nombre'),
 ('Muffin Arándano Queso','Muffin relleno arandano','otro nombre'),
 ('Muffin vainilla chips chocolate','Muffin vainilla chips','otro nombre'),
 ('Muffin Zanahoria Vegano','Muffin de zanahoria','otro nombre'),
 ('Muffins de zanahoria','Muffin de zanahoria','otro nombre'),
 ('Pie de plátano manjar','Pie de plátano','otro nombre'),
 ('Pizza 4 Quesos','Pizza de 4 quesos','otro nombre'),
 ('Pizza Capresse','Pizza Capresse Azapa','otro nombre'),
 ('Pizza Serrano','Pizza de serrano','otro nombre'),
 ('Sandiwch jamón serrano','Sandwich Serrano','otro nombre'),
 ('Sandwich Apaltado Nuevo','Sandwich Apaltado','otro nombre'),
 ('Sandwich Azapa Nuevo','Sandwich Azapa','otro nombre'),
 ('Sandwich Champiñon Nuevo','Sandwich Champiñón','otro nombre'),
 ('Sandwich Mechada Luco Nuevo','Sandwich Mechada','otro nombre'),
 ('Tiramisu','Trozo de Tiramisu','otro nombre'),
 ('Torta amor','Trozo torta amor','otro nombre'),
 ('Torta de matilda','Trozo torta Matilda','otro nombre'),
 ('Torta de tres leches','Trozo torta tres leches','otro nombre'),
 ('Torta de zanahoria','Trozo torta de zanahoria','otro nombre'),
 ('Torta hojarasca manjar','Trozo torta hojarasca','otro nombre'),
 ('Waffle','Waffles','otro nombre');


-- ================================================================
-- BLOQUE 2 — LA VISTA PREVIA. NO SALTARSE ESTE PASO.
--
-- QUÉ VER: la columna "la_instruccion" se lee como si se la dijeras a
-- alguien en el mesón. Si alguna no tiene sentido, PARAR y avisar
-- antes del bloque 4.
-- ================================================================
select m.grupo,
       'vender 1 "' || f.nombre || '" baja 1 "' || p.producto || '"' as la_instruccion,
       p.rubro as de_la_seccion
from public.angamos_mapa_recetas m
join public.fudo_productos f on f.sede='angamos' and f.activo   and f.nombre   = m.nombre_fudo
join public.productos      p on p.sede='angamos' and p.activo='SÍ' and p.producto = m.nombre_inv
order by m.grupo, f.nombre;


-- ================================================================
-- BLOQUE 3 — ¿QUEDÓ ALGUNA PAREJA SUELTA?
--
-- QUÉ VER: lo ideal es "Success. No rows returned". Si sale alguna
-- fila, es un nombre que escribí mal o un producto que cambió: esa
-- receta NO se va a crear y hay que avisar.
-- ================================================================
select m.nombre_fudo,
       m.nombre_inv,
       case when not exists (select 1 from public.fudo_productos f
                              where f.sede='angamos' and f.activo and f.nombre = m.nombre_fudo)
            then '🔴 no existe ese producto en el Fudo de Angamos'
            else '🔴 no existe ese producto en el inventario de Angamos' end as problema
from public.angamos_mapa_recetas m
where not exists (select 1 from public.fudo_productos f
                   where f.sede='angamos' and f.activo and f.nombre = m.nombre_fudo)
   or not exists (select 1 from public.productos p
                   where p.sede='angamos' and p.activo='SÍ' and p.producto = m.nombre_inv);


-- ================================================================
-- BLOQUE 4 — CREAR LAS RECETAS (la cabecera)
--
-- Se puede correr las veces que quieras: si ya existe, no la duplica.
-- ================================================================
insert into public.recetas (sede, fudo_product_id, fudo_product_nombre, activo)
select 'angamos', f.fudo_product_id, f.nombre, true
from public.angamos_mapa_recetas m
join public.fudo_productos f on f.sede='angamos' and f.activo and f.nombre = m.nombre_fudo
on conflict (sede, fudo_product_id) do nothing;


-- ================================================================
-- BLOQUE 5 — DECIRLE A CADA RECETA QUÉ DESCUENTA
--
-- Una línea por receta, cantidad 1, aplica siempre: sirva en local o
-- para llevar da lo mismo, es el mismo producto.
-- ================================================================
insert into public.receta_items (receta_id, producto_id, cantidad, aplica)
select r.id, p.id, 1, 'siempre'
from public.recetas r
join public.fudo_productos      f on f.sede='angamos' and f.fudo_product_id = r.fudo_product_id
join public.angamos_mapa_recetas m on m.nombre_fudo = f.nombre
join public.productos           p on p.sede='angamos' and p.activo='SÍ' and p.producto = m.nombre_inv
where r.sede='angamos' and r.activo
on conflict (receta_id, producto_id) do nothing;


-- ================================================================
-- BLOQUE 6 — COMPROBAR, Y LIMPIAR LA MESA
--
-- QUÉ VER: "recetas" y "con_insumo" tienen que dar el MISMO número, y
-- "sin_insumo" tiene que dar 0. Una receta sin insumo no descuenta
-- nada — es justo lo que el chequeo de salud sale a buscar.
-- ================================================================
select count(*)                                        as recetas,
       count(*) filter (where ri.receta_id is not null) as con_insumo,
       count(*) filter (where ri.receta_id is null)     as sin_insumo,
       case when count(*) filter (where ri.receta_id is null) = 0
            then '✅ todas descuentan algo'
            else '🔴 hay recetas que apuntan al vacío — avisar' end as veredicto
from public.recetas r
left join (select distinct receta_id from public.receta_items) ri on ri.receta_id = r.id
where r.sede='angamos' and r.activo;

-- La tabla puente ya cumplió: se borra para no dejar basura en la base.
-- ⚠️ Correr esto DESPUÉS de haber mirado el resultado de arriba.
drop table if exists public.angamos_mapa_recetas;


-- ================================================================
-- BLOQUE 7 — CÓMO SE DESHACE
--
-- Borra TODAS las recetas de angamos. Hoy sirve porque estas 81 son
-- prácticamente las únicas que hay; el día que alguien haga recetas a
-- mano desde la app, esto deja de ser seguro y hay que acotarlo.
--
-- delete from public.receta_items
--  where receta_id in (select id from public.recetas where sede='angamos');
-- delete from public.recetas where sede='angamos';
--
-- ⚠️ Deshacer NO devuelve el stock que ya se haya descontado. Eso se
-- corrige contando, como siempre.
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-recetas-tanda-unica.sql', 'Jhon', 'lo corrió Jhon',
        '81 recetas de un insumo en Angamos: 23 de calce exacto, 17 Pedidos Ya, 41 con el nombre escrito distinto')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
