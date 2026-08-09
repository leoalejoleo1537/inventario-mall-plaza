-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. No arregla, no borra, no apaga.
--  QUÉ VER:   el bloque 2 es el que decide. Si sale VACÍO, respiramos.
-- ================================================================
--
-- LA PREGUNTA: el informe de duplicados encontró 24 productos de BODEGA que
-- están usados en RECETAS. Bodega no vende, así que eso no debería pasar.
--
-- POR QUÉ IMPORTA, dicho simple: una receta dice "cuando vendas esto, descuenta
-- aquello". Si una receta de Mall Plaza apunta a un producto de bodega,
-- entonces cada venta en Plaza estaría bajando el stock de LA BODEGA en vez
-- del stock del local. Sería como que al vender un café en el mesón, el
-- descuento se lo anotaran al depósito.
--
-- PERO PUEDE SER INOFENSIVO. Acordémonos de que la bodega de hoy ES la
-- Angamos vieja, renombrada en julio. Ese script movió los productos, el
-- historial y los avisos a Fudo… y NO tocó las recetas. Así que estas
-- podrían ser recetas viejas de esa sede, huérfanas y sin efecto.
--
-- LAS DOS COSAS SE VEN DISTINTO EN LOS DATOS, y por eso este archivo existe.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ¿DE QUÉ SEDE SON ESAS RECETAS?
--
-- QUÉ VER:
--   · si dice 'angamos'  -> ojo, hay que mirar el bloque 2 igual, porque
--     hoy existe una Angamos nueva y usa el mismo nombre de sede
--   · si dice 'plaza'    -> es una receta viva apuntando al lugar equivocado
--   · si no sale nada    -> no hay recetas apuntando a bodega y listo
-- ================================================================
select r.sede                          as sede_de_la_receta,
       r.activo                        as receta_activa,
       count(*)                        as lineas_de_receta,
       count(distinct ri.producto_id)  as productos_de_bodega_apuntados,
       count(distinct r.id)            as recetas_distintas
from public.receta_items ri
join public.recetas   r on r.id = ri.receta_id
join public.productos p on p.id = ri.producto_id
where p.sede = 'bodega'
group by r.sede, r.activo
order by r.sede, r.activo;


-- ================================================================
-- BLOQUE 2 — ⭐ EL QUE DECIDE: ¿ALGUNA VEZ DESCONTÓ DE VERDAD?
--
-- Esto no pregunta por las recetas: pregunta por los HECHOS. La tabla
-- fudo_movimientos guarda, venta por venta, qué producto se descontó y si
-- se aplicó de verdad ("aplicado") o solo se simuló.
--
-- QUÉ VER:
--   · SIN FILAS  -> nunca se descontó de bodega por una venta. Las recetas
--     son papel mojado, se limpian y seguimos tranquilos.
--   · CON FILAS  -> está pasando de verdad. La columna "ultima_vez" dice
--     cuándo fue la última, y "cuanto_se_descuento" cuánto se llevó.
--     Eso se arregla primero, antes que cualquier otra cosa.
-- ================================================================
select m.sede                          as sede_de_la_venta,
       count(*)                        as veces,
       count(distinct m.producto_id)   as productos_de_bodega_tocados,
       sum(coalesce(m.descuento,0))    as cuanto_se_descuento,
       min(m.created_at)               as primera_vez,
       max(m.created_at)               as ultima_vez
from public.fudo_movimientos m
join public.productos p on p.id = m.producto_id
where p.sede = 'bodega'
  and m.aplicado = true
group by m.sede
order by m.sede;


-- ================================================================
-- BLOQUE 3 — EL DETALLE, para saber qué hay que arreglar
--
-- Una fila por línea de receta. Dice qué producto de Fudo se vende, a qué
-- producto de bodega le está pegando, y si existe el gemelo correcto en la
-- sede de esa receta — que es a donde debería apuntar.
-- ================================================================
select r.sede                as sede_de_la_receta,
       r.fudo_product_nombre as se_vende_en_fudo,
       p.id                  as apunta_a_bodega_id,
       p.producto            as apunta_a,
       coalesce(p.stock_actual,0) as stock_en_bodega,
       (select min(s.id) from public.productos s
         where s.sede = r.sede and s.activo = 'SÍ' and s.producto = p.producto)
                             as deberia_apuntar_a_id,
       case when exists (select 1 from public.productos s
                          where s.sede = r.sede and s.activo = 'SÍ'
                            and s.producto = p.producto)
            then 'sí, existe el gemelo en esa sede'
            else '⚠️ no existe un producto con ese nombre en esa sede' end as se_puede_repuntar
from public.receta_items ri
join public.recetas   r on r.id = ri.receta_id
join public.productos p on p.id = ri.producto_id
where p.sede = 'bodega'
order by r.sede, p.producto;


-- ================================================================
-- BLOQUE 4 — EL REPARTO ABIERTO DE LAS NARANJAS
--
-- La otra alarma: el producto 298 (Naranjas, bodega) está en un reparto sin
-- cerrar. Acá se ve cuál es, para poder cerrarlo antes de juntar los
-- duplicados.
-- ================================================================
select r.id            as reparto,
       r.sede          as sede_que_recibe,
       r.origen,
       r.estado,
       r.creado_por,
       r.created_at    as enviado,
       ri.producto     as linea,
       ri.cantidad_pedida,
       ri.estado       as estado_de_la_linea
from public.reparto_items ri
join public.repartos r on r.id = ri.reparto_id
join public.productos p on p.id = ri.producto_id
where p.sede = 'bodega' and r.estado = 'abierto'
order by r.created_at desc;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-bodega-recetas-que-apuntan-aca.sql', 'Jhon', 'lo corrió Jhon',
        'Informe de SOLO LECTURA: si las recetas que apuntan a productos de bodega alguna vez descontaron de verdad, o son huérfanas del renombre de julio')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
