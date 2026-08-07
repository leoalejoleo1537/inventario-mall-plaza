-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  corrige los tipos que quedaron mal en Angamos. SÍ ESCRIBE,
--             pero solo la columna `tipo` de 18 productos.
--  QUÉ VER:   el bloque 2 deja el recuento final.
-- ================================================================
--
-- QUÉ SALIÓ MAL, y es un error mío en el clasificador del archivo
-- anterior. Dos reglas eran demasiado anchas:
--
--   1. Para pescar el té usé el patrón `te$` — "termina en te". Pero eso
--      también pesca "desengrasan-TE", "desinfectan-TE", "endulzan-TE" y
--      "chocola-TE". Por eso el desengrasante quedó en Cafetería.
--
--   2. Para los envases usé "está en la sección Mesones". Pero en Mesones
--      también viven las naranjas, los limones, la palta y la canela.
--
-- La lección, y vale para cualquier clasificador futuro: **un patrón que
-- pesca por el final de la palabra pesca cosas que no tienen nada que
-- ver.** Mejor pocos aciertos y revisar a mano, que muchos y mal.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LAS CORRECCIONES
--
-- Van por NOMBRE y no por patrón, a propósito: son 18 productos, ya se
-- vieron uno por uno, y un patrón nuevo puede volver a pescar de más.
-- ================================================================
update public.productos p
   set tipo = v.t
  from (values
  -- el error del `te$`: productos de limpieza que quedaron en Cafetería
  ('Bidón desengrasante',                 'Limpieza'),
  ('Bidón Desinfectante virutex piso',    'Limpieza'),
  -- y otros que no son cafetería sino insumo
  ('Endulzante',                          'Insumos'),
  ('Chocolate',                           'Insumos'),
  ('Helado de chocolate',                 'Insumos'),
  ('SALSA DE CHOCOLATE',                  'Insumos'),
  -- el error de "sección Mesones = envase": esto es fruta e insumo
  ('Canela',                              'Insumos'),
  ('Jengibre',                            'Insumos'),
  ('Limones',                             'Insumos'),
  ('Naranjas',                            'Insumos'),
  ('Palta',                               'Insumos'),
  ('MANTEQUILLA',                         'Insumos'),
  ('Toping',                              'Insumos'),
  -- una caja de pizza es un envase, no un salado
  ('CAJA DE PIZZA',                       'Envases'),
  -- los 6 que quedaron sin tipo
  ('Frutillas Frescas',                   'Insumos'),
  ('Hielo',                               'Insumos'),
  ('platano congelado',                   'Insumos'),
  ('Queque Amapola',                      'Bollería'),
  ('Sellatido Individual',                'Sándwiches'),
  ('yogurt protein',                      'Insumos')
) as v(nombre, t)
 where p.sede='angamos' and p.activo='SÍ' and p.producto = v.nombre;


-- ---------- los dos tipos raros que ya venían de antes ----------
-- "Sandwich" y "4 bolsas de 180 g" no los puso este script: ya estaban.
-- El segundo es una UNIDAD de medida escrita en el campo de tipo — se
-- deja en blanco y se le pone el tipo correcto desde la ficha.
update public.productos set tipo='Sándwiches'
 where sede='angamos' and tipo='Sandwich';
update public.productos set tipo=null
 where sede='angamos' and tipo='4 bolsas de 180 g';


-- ================================================================
-- BLOQUE 2 — CÓMO QUEDÓ
--
-- QUÉ VER: esta es la franja de filtros tal como se va a ver en la app.
-- Si algún tipo se ve raro, se corrige desde la ficha del producto.
-- ================================================================
select coalesce(tipo,'— sin tipo —') as tipo,
       count(*) as productos,
       string_agg(producto, '  ·  ' order by producto) as cuales
from public.productos
where sede='angamos' and activo='SÍ'
group by 1
order by productos desc;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-corregir-tipos-angamos.sql', 'Jhon', 'lo corrió Jhon',
        'Corrigió 20 tipos mal clasificados en Angamos. El patrón te$ pescaba desengrasante, endulzante y chocolate')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
