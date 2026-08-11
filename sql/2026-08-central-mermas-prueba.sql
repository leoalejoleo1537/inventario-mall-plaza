-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        6 bloques. UNO POR UNO, en orden.
--  TARDA:     instantáneo
--  QUÉ HACE:  prueba la merma de punta a punta con DOS PRODUCTOS DE
--             MENTIRA que se crean acá y se borran en el bloque 6.
--             No toca ni un producto de verdad de ninguna sede.
--  QUÉ VER:   cada bloque termina en una tabla. Pégamelas todas.
-- ================================================================
--
-- POR QUÉ EXISTE: las funciones mermar() y deshacer_merma() están escritas y
-- revisadas contra el esquema, pero **nunca se han ejecutado**. Revisar un
-- motor y hacerlo andar no son lo mismo. Esto lo hace andar una vez, en
-- terreno donde no puede romper nada.
--
-- ⚠️ NO se usa un producto real de la bodega a propósito: Adriana puede estar
-- contando justo ahora, y tocarle el stock a un producto que ella acaba de
-- contar sería borrarle el trabajo. Estos dos nacen y mueren acá.
--
-- Se prueban los DOS caminos, porque son distintos por dentro:
--   · producto normal  -> se le baja el stock
--   · producto con fechas -> se le quita de la fecha, y el stock se recalcula
--     solo. Este es el delicado (regla 0.3.1).
-- ================================================================


-- ================================================================
-- BLOQUE 1 — CREAR LOS DOS DE MENTIRA
-- QUÉ VER: dos filas. El normal con 5. El de fechas con 10 (4 + 6), que lo
-- calculó solo el sistema a partir de las fechas — nadie escribió ese 10.
-- ================================================================
insert into public.productos (sede, producto, rubro, stock_actual, stock_min, stock_max, activo, perecedero)
values ('central','ZZZ PRUEBA MERMA normal','Limpieza', 5, 1, 10,'SÍ', false),
       ('central','ZZZ PRUEBA MERMA fechas','Limpieza', 0, 1, 10,'SÍ', true);

insert into public.producto_lotes (producto_id, cantidad, vencimiento)
select id, 4, current_date + 2 from public.productos
 where sede='central' and producto='ZZZ PRUEBA MERMA fechas';

insert into public.producto_lotes (producto_id, cantidad, vencimiento)
select id, 6, current_date + 9 from public.productos
 where sede='central' and producto='ZZZ PRUEBA MERMA fechas';

select producto, stock_actual,
       (select count(*) from public.producto_lotes l where l.producto_id = p.id) as fechas
from public.productos p
where sede='central' and producto like 'ZZZ PRUEBA MERMA%'
order by producto;


-- ================================================================
-- BLOQUE 2 — MERMAR EL NORMAL: 2 por robo
-- QUÉ VER: stock 3 (era 5), y una fila en el libro con −2 y motivo robo.
-- ================================================================
select public.mermar(
  (select id from public.productos where sede='central' and producto='ZZZ PRUEBA MERMA normal'),
  2, null, 'robo', null, 'prueba');

select p.producto, p.stock_actual, m.tipo, m.cantidad, m.motivo, m.quien
from public.productos p
left join public.movimientos m on m.producto_id = p.id
where p.sede='central' and p.producto='ZZZ PRUEBA MERMA normal';


-- ================================================================
-- BLOQUE 3 — LO QUE TIENE QUE NEGARSE A HACER
--
-- Las tres son ERRORES ESPERADOS: la prueba pasa si FALLAN. Córrelas de a
-- una y pégame el mensaje que sale — lo importante es que el mensaje se
-- entienda, porque es el que va a leer la persona en el mesón.
-- ================================================================
-- 3a) mermar más de lo que hay (quedan 3). Tiene que decir cuánto hay.
select public.mermar(
  (select id from public.productos where sede='central' and producto='ZZZ PRUEBA MERMA normal'),
  99, null, 'daño', null, 'prueba');

-- 3b) mermar sin motivo
-- select public.mermar(
--   (select id from public.productos where sede='central' and producto='ZZZ PRUEBA MERMA normal'),
--   1, null, null, null, 'prueba');

-- 3c) mermar un producto CON FECHAS sin decir de qué fecha
-- select public.mermar(
--   (select id from public.productos where sede='central' and producto='ZZZ PRUEBA MERMA fechas'),
--   3, null, 'vencimiento', null, 'prueba');

-- 3d) mermar en OTRA SEDE. Tiene que negarse aunque el producto exista.
--     (solo lee para elegir uno de Angamos; si se negara, no lo toca)
-- select public.mermar(
--   (select id from public.productos where sede='angamos' and activo='SÍ' order by id limit 1),
--   1, null, 'daño', null, 'prueba');


-- ================================================================
-- BLOQUE 4 — MERMAR EL DE FECHAS: 4 de la fecha más próxima, por vencimiento
-- QUÉ VER: stock 6 (era 10), UNA sola fecha viva (la de 4 se botó entera y
-- desaparece: una fecha en cero no es una fecha), y en el libro un −4 que
-- guarda de qué fecha salió.
-- ================================================================
select public.mermar(
  (select id from public.productos where sede='central' and producto='ZZZ PRUEBA MERMA fechas'),
  null,
  (select jsonb_agg(jsonb_build_object('lote_id', l.id, 'cantidad', 4))
     from public.producto_lotes l
     join public.productos p on p.id = l.producto_id
    where p.sede='central' and p.producto='ZZZ PRUEBA MERMA fechas'
      and l.cantidad = 4),
  'vencimiento', null, 'prueba');

select p.stock_actual,
       (select count(*) from public.producto_lotes l where l.producto_id=p.id) as fechas_vivas,
       (select string_agg(l.cantidad || ' vencen ' || to_char(l.vencimiento,'DD/MM'), ' · ')
          from public.producto_lotes l where l.producto_id=p.id) as cuales,
       (select m.cantidad from public.movimientos m where m.producto_id=p.id order by m.id desc limit 1) as libro,
       (select m.detalle  from public.movimientos m where m.producto_id=p.id order by m.id desc limit 1) as guardo_la_fecha
from public.productos p
where p.sede='central' and p.producto='ZZZ PRUEBA MERMA fechas';


-- ================================================================
-- BLOQUE 5 — DESHACER LAS DOS
-- QUÉ VER: el normal vuelve a 5. El de fechas vuelve a 10 y a tener SUS DOS
-- fechas — la que se había borrado por quedar en cero se vuelve a crear con
-- su día original. Y las dos mermas siguen en el libro, marcadas.
-- ================================================================
select public.deshacer_merma(m.id, 'prueba')
from public.movimientos m
join public.productos p on p.id = m.producto_id
where p.sede='central' and p.producto like 'ZZZ PRUEBA MERMA%'
  and m.tipo='merma' and m.deshecha_at is null;

select p.producto, p.stock_actual,
       (select string_agg(l.cantidad || ' vencen ' || to_char(l.vencimiento,'DD/MM'), ' · ')
          from public.producto_lotes l where l.producto_id=p.id) as fechas,
       (select count(*) from public.movimientos m
         where m.producto_id=p.id and m.deshecha_at is not null) as mermas_deshechas,
       (select string_agg(m.motivo,', ') from public.movimientos m
         where m.producto_id=p.id) as motivos_que_se_conservan
from public.productos p
where p.sede='central' and p.producto like 'ZZZ PRUEBA MERMA%'
group by p.id, p.producto, p.stock_actual
order by p.producto;


-- ================================================================
-- BLOQUE 6 — BORRAR LOS DOS DE MENTIRA
--
-- Al borrar el producto se van con él sus fechas y sus movimientos (la
-- tabla está hecha así). Después de esto no queda rastro de la prueba.
-- QUÉ VER: la tabla tiene que salir VACÍA, y bodega volver a 234.
-- ================================================================
delete from public.productos
 where sede='central' and producto like 'ZZZ PRUEBA MERMA%';

select (select count(*) from public.productos
         where sede='central' and producto like 'ZZZ PRUEBA MERMA%')      as quedan_de_prueba,
       (select count(*) from public.productos
         where sede='central' and activo='SÍ')                            as productos_en_bodega,
       (select count(*) from public.movimientos where sede='central')     as filas_en_el_libro;
