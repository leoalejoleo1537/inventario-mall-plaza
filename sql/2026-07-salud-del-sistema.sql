-- ================================================================
-- SALUD DEL SISTEMA — el chequeo que se corre "porque sí"
--
-- TODO DE SOLO LECTURA. No crea, no borra, no modifica nada.
--
-- Para qué sirve: las dos fallas más caras que ha tenido el proyecto
-- (las 15 horas sin descontar del 2026-07-27 y el historial que
-- mostraba días viejos) NO se vieron venir porque nadie estaba
-- mirando el número que las anunciaba. Este archivo junta todos esos
-- números en una sola corrida.
--
-- Cuándo correrlo: una vez al mes, y SIEMPRE antes y después de
-- instalar un motor o un cálculo nuevo.
--
-- CÓMO SE USA: correr SOLO el bloque 0. Devuelve una tabla de 10 filas
-- con el estado de todo. Los bloques 1 al 10 son el detalle de cada
-- una de esas filas — se corren únicamente si alguna sale con algo.
--
-- Ninguno de estos bloques arregla nada solo: se lee, se decide, y
-- recién ahí se toca.
-- ================================================================


-- ================================================================
-- 0) RESUMEN EN UNA SOLA CORRIDA  ←  EMPEZAR POR ACÁ
--
-- Seleccionar TODO este bloque 0 (desde el "with" hasta el ";") y darle
-- Run. Devuelve UNA tabla de 10 filas con el estado de todo.
--
-- La columna que importa es "¿Hay que hacer algo?":
--   ok          → nada que hacer
--   info        → un número para saber cómo vamos, no un problema
--   MIRAR       → hay algo, conviene revisarlo, no es urgente
--   REVISAR YA  → algo está roto o a punto de romperse
--
-- Si alguna fila dice MIRAR o REVISAR YA, el bloque de ese mismo número
-- más abajo muestra el detalle completo (qué producto, qué función, etc.).
--
-- Los bloques 1 al 10 siguen estando: son el detalle de cada línea de
-- este resumen. No hace falta correrlos si todo sale "ok".
-- ================================================================
with q(orden, bloque, sql) as (values

 (1, 'Tope de 1000 filas',
  $q$select (case when max(x.n)>=1000 then 'REVISAR YA' when max(x.n)>=700 then 'MIRAR' else 'ok' end)||'|'||coalesce(string_agg(x.t||' '||x.n, ' · ' order by x.n desc),'-') as c
     from (select t.tabla as t,
                  (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from public.%I', t.tabla), false,true,'')))[1]::text::bigint as n
           from unnest(array['productos','producto_lotes','recetas','receta_items','fudo_productos','repartos','reparto_items','historial']) as t(tabla)
           where to_regclass('public.'||t.tabla) is not null) x$q$),

 (2, 'Funciones duplicadas',
  $q$select (case when count(*)>0 then 'REVISAR YA' else 'ok' end)||'|'||coalesce(string_agg(f.proname||' ('||f.n||' firmas)', ' · '), 'ninguna duplicada') as c
     from (select p.proname, count(*) as n from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
           where ns.nspname='public' and p.proname in ('fudo_procesar_item','fudo_stock_calculado','descontar_lotes',
                 'descontar_con_reposicion','base_nombre','reparto_recibir','reparto_rechazar','reparto_deshacer',
                 'reparto_cerrar','fudo_ultimo_empuje','historial_dias')
           group by p.proname having count(*)>1) f$q$),

 (3, 'Tablas sin actualizacion en vivo',
  $q$select (case when count(*)>0 then 'MIRAR' else 'ok' end)||'|'||coalesce(string_agg(t.tabla, ' · '), 'todas publicadas') as c
     from unnest(array['productos','producto_lotes','repartos','reparto_items']) as t(tabla)
     where to_regclass('public.'||t.tabla) is not null
       and not exists (select 1 from pg_publication_tables pt
                       where pt.pubname='supabase_realtime' and pt.schemaname='public' and pt.tablename=t.tabla)$q$),

 (4, 'Columnas que el motor da por sentadas',
  $q$select (case when count(*)>0 then 'REVISAR YA' else 'ok' end)||'|'||coalesce(string_agg(v.tabla||'.'||v.columna, ' · '), 'todas presentes') as c
     from (values ('fudo_movimientos','venta_at'),('productos','urgente'),('productos','tipo'),
                  ('fudo_stock_push','lote'),('fudo_sync','modo')) as v(tabla,columna)
     where to_regclass('public.'||v.tabla) is not null
       and not exists (select 1 from information_schema.columns ic
                       where ic.table_schema='public' and ic.table_name=v.tabla and ic.column_name=v.columna)$q$),

 (5, 'Stock que no cuadra con las fechas',
  case when to_regclass('public.producto_lotes') is null then $q$select 'ok|sin tabla de fechas' as c$q$ else
  $q$select (case when count(*)=0 then 'ok' else 'MIRAR' end)||'|'||(case when count(*)=0 then 'todo cuadra' else count(*)||' producto(s) descuadrado(s)' end) as c
     from (select p.id from public.productos p join public.producto_lotes l on l.producto_id=p.id
           where p.activo='SÍ' group by p.id, p.stock_actual
           having p.stock_actual <> coalesce(sum(l.cantidad),0)) d$q$ end),

 (6, 'Fechas en cantidad cero',
  case when to_regclass('public.producto_lotes') is null then $q$select 'ok|sin tabla de fechas' as c$q$ else
  $q$select (case when count(*)=0 then 'ok' else 'MIRAR' end)||'|'||(case when count(*)=0 then 'ninguna' else count(*)||' fecha(s) vacia(s)' end) as c
     from public.producto_lotes where cantidad <= 0$q$ end),

 (7, 'Stock negativo',
  $q$select case when (select count(*) from public.productos where coalesce(stock_actual,0)<0)
                    + (select count(*) from public.producto_lotes where coalesce(cantidad,0)<0) = 0
                 then 'ok|ninguno' else 'REVISAR YA|hay stock negativo' end as c$q$),

 (8, 'El motor descuenta (ultimos 7 dias)',
  case when to_regclass('public.fudo_movimientos') is null then $q$select 'ok|sin tabla de movimientos' as c$q$ else
  $q$select case when count(*)=0 then 'ok|no hubo ventas'
                 when count(*) filter (where coalesce(descontado,false))=0 then 'REVISAR YA|leyo '||count(*)||' ventas y no desconto ninguna'
                 when count(*) filter (where coalesce(descontado,false))*2 < count(*) then 'MIRAR|solo '||count(*) filter (where coalesce(descontado,false))||' de '||count(*)||' descontadas'
                 else 'ok|'||count(*) filter (where coalesce(descontado,false))||' de '||count(*)||' descontadas' end as c
     from public.fudo_movimientos where coalesce(venta_at, created_at) > now() - interval '7 days'$q$ end),

 (9, 'Cobertura de recetas',
  $q$select 'info|'||coalesce(string_agg(s.sede||' '||s.pct||'%', ' · '), 'sin productos de Fudo') as c
     from (select fp.sede, round(100.0*count(*) filter (where r.id is not null)/nullif(count(*),0),0) as pct
           from public.fudo_productos fp
           left join public.recetas r on r.fudo_product_id=fp.fudo_product_id and r.sede=fp.sede and r.activo
           where fp.activo group by fp.sede) s$q$),

 (10,'Recetas que apuntan al vacio',
  $q$select (case when count(*)=0 then 'ok' else 'MIRAR' end)||'|'||(case when count(*)=0 then 'ninguna' else count(*)||' insumo(s) inexistente(s)' end) as c
     from public.recetas r join public.receta_items ri on ri.receta_id=r.id
     left join public.productos p on p.id=ri.producto_id and p.activo='SÍ'
     where r.activo and p.id is null$q$)
)
select r.orden as "#",
       r.bloque as "Qué se revisó",
       split_part(r.res, '|', 1) as "¿Hay que hacer algo?",
       split_part(r.res, '|', 2) as "Detalle"
from (select q.orden, q.bloque,
             (xpath('/row/c/text()', query_to_xml(q.sql, false, true, '')))[1]::text as res
      from q) r
order by r.orden;


-- ================================================================
-- 1) EL TOPE DE LAS 1000 FILAS
--
-- Supabase corta cualquier respuesta en 1000 filas y NO avisa: la app
-- recibe 1000 de 1400 y sigue como si nada. Así se perdieron los días
-- recientes del historial en julio.
--
-- Acá está cuánto le falta a cada tabla para llegar a ese tope. Lo que
-- importa no es el número de hoy, es la distancia: una tabla en 850
-- filas funciona perfecto y se rompe sola el mes que viene.
-- ================================================================
select t.tabla,
       (xpath('/row/c/text()',
              query_to_xml(format('select count(*) as c from public.%I', t.tabla),
                           false, true, '')))[1]::text::bigint as filas,
       case
         when (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from public.%I', t.tabla),
                                                   false,true,'')))[1]::text::bigint >= 1000
           then '🔴 YA CORTADA — la app está viendo datos incompletos'
         when (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from public.%I', t.tabla),
                                                   false,true,'')))[1]::text::bigint >= 700
           then '⚠️ cerca del tope — ponerle limit antes de que llegue'
         else 'ok'
       end as veredicto
from unnest(array[
       'productos','producto_lotes','recetas','receta_items',
       'fudo_productos','repartos','reparto_items','historial',
       'fudo_movimientos','fudo_stock_push'
     ]) as t(tabla)
where to_regclass('public.'||t.tabla) is not null
order by 2 desc;


-- ================================================================
-- 2) ¿HAY FUNCIONES DUPLICADAS?
--
-- Esta es LA consulta de la falla del 2026-07-27. Dos funciones con el
-- mismo nombre y distinta firma conviven sin problema si se las llama
-- desde SQL — pero la Edge Function llama por la API, y ahí el nombre
-- queda ambiguo y la llamada se rechaza ANTES de ejecutar nada.
--
-- Cualquier fila con "⚠️" acá significa que ese camino puede estar
-- muerto sin que nada lo diga.
-- ================================================================
select p.proname                                   as funcion,
       count(*)                                    as firmas,
       string_agg(pg_get_function_identity_arguments(p.oid), '  ||  ') as argumentos,
       case when count(*) > 1
            then '⚠️ AMBIGUA por la API — dejar una sola'
            else 'ok' end                          as veredicto
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('fudo_procesar_item','fudo_stock_calculado','descontar_lotes',
                    'descontar_con_reposicion','base_nombre','reparto_recibir',
                    'reparto_rechazar','reparto_deshacer','reparto_cerrar',
                    'fudo_ultimo_empuje','historial_dias')
group by p.proname
order by count(*) desc, p.proname;


-- ================================================================
-- 3) LO QUE LA APP LEE EN VIVO, ¿ESTÁ PUBLICADO?
--
-- Si una tabla no está en supabase_realtime, el teléfono no se entera
-- de los cambios y muestra datos viejos con toda confianza. Fue la
-- causa del "Champiñón 0 con 1 vence hoy": productos estaba publicada
-- y producto_lotes no.
-- ================================================================
select t.tabla,
       case when exists (
              select 1 from pg_publication_tables pt
              where pt.pubname = 'supabase_realtime'
                and pt.schemaname = 'public' and pt.tablename = t.tabla)
            then 'ok'
            else '⚠️ NO se actualiza sola en el teléfono' end as veredicto
from unnest(array['productos','producto_lotes','repartos','reparto_items']) as t(tabla)
where to_regclass('public.'||t.tabla) is not null
order by 2, 1;


-- ================================================================
-- 4) LAS COLUMNAS QUE EL MOTOR DA POR SENTADAS
--
-- Un motor que escribe una columna inexistente lanza excepción en cada
-- venta, y la Edge Function las cuenta como errores pero responde ok.
-- Es exactamente lo que pasó con venta_at.
-- ================================================================
select c.tabla, c.columna,
       case when exists (
              select 1 from information_schema.columns ic
              where ic.table_schema='public' and ic.table_name=c.tabla
                and ic.column_name=c.columna)
            then 'ok' else '⚠️ FALTA — el camino que la usa está roto' end as veredicto
from (values
        ('fudo_movimientos','venta_at'),
        ('productos','urgente'),
        ('productos','tipo'),
        ('fudo_stock_push','lote'),
        ('fudo_sync','modo')
     ) as c(tabla, columna)
where to_regclass('public.'||c.tabla) is not null
order by 3 desc, 1, 2;


-- ================================================================
-- 5) LA INVARIANTE DE LOS PERECEDEROS
--
-- Regla 0.3.1 del archivo madre: en un producto con fechas, el stock
-- tiene que ser la SUMA de sus lotes. Si no cuadra, alguien va a botar
-- comida buena o a vender comida vencida.
--
-- Acá salen SOLO los descuadres. Lo normal es que no salga ninguno.
-- ================================================================
select p.sede, p.producto, p.rubro,
       p.stock_actual                    as dice_el_stock,
       coalesce(sum(l.cantidad), 0)      as suman_las_fechas,
       p.stock_actual - coalesce(sum(l.cantidad),0) as diferencia
from public.productos p
join public.producto_lotes l on l.producto_id = p.id
where p.activo = 'SÍ'
group by p.id, p.sede, p.producto, p.rubro, p.stock_actual
having p.stock_actual <> coalesce(sum(l.cantidad), 0)
order by abs(p.stock_actual - coalesce(sum(l.cantidad),0)) desc;


-- ================================================================
-- 6) FECHAS QUE NO REPRESENTAN NADA
--
-- Un lote en 0 no es una fecha: es una fila que quedó vacía al
-- descontar. No debería mostrarse ni copiarse en el resumen.
-- ================================================================
select count(*) filter (where cantidad <= 0)                    as fechas_en_cero,
       count(*) filter (where vencimiento < current_date
                          and cantidad > 0)                     as fechas_vencidas_con_stock,
       case when count(*) filter (where cantidad <= 0) > 0
            then '⚠️ correr sql/2026-07-fechas-en-vivo-y-limpieza.sql'
            else 'ok' end                                       as veredicto
from public.producto_lotes;


-- ================================================================
-- 7) NEGATIVOS — la regla 0.2 no admite excepciones
--
-- Los CHECK de la base deberían hacer esto imposible. Si acá sale
-- algo, es que un CHECK no se llegó a crear.
-- ================================================================
select 'productos.stock_actual' as donde, count(*) as negativos,
       case when count(*) > 0 then '🔴 revisar el CHECK' else 'ok' end as veredicto
from public.productos where coalesce(stock_actual,0) < 0
union all
select 'producto_lotes.cantidad', count(*),
       case when count(*) > 0 then '🔴 revisar el CHECK' else 'ok' end
from public.producto_lotes where coalesce(cantidad,0) < 0;


-- ================================================================
-- 8) ¿EL MOTOR ESTÁ DESCONTANDO?
--
-- Un sistema que falla en silencio es peor que uno que se cae. Si en
-- los últimos 7 días hubo ventas y CERO descuentos, el inventario
-- lleva días congelado aunque la pantalla diga "✓".
-- ================================================================
select date_trunc('day', coalesce(m.venta_at, m.created_at))::date as dia,
       count(*)                                                    as items_leidos,
       count(*) filter (where coalesce(m.descontado, false))        as items_descontados,
       case when count(*) > 0
             and count(*) filter (where coalesce(m.descontado,false)) = 0
            then '🔴 leyó ventas y no descontó NADA'
            else 'ok' end                                          as veredicto
from public.fudo_movimientos m
where coalesce(m.venta_at, m.created_at) > now() - interval '7 days'
group by 1
order by 1 desc;


-- ================================================================
-- 9) COBERTURA DE RECETAS
--
-- Un producto de Fudo sin receta se vende sin descontar nada. No es un
-- error del sistema: es un hueco en la cobertura, y el porcentaje es
-- la métrica de avance de la depuración.
-- ================================================================
select fp.sede,
       count(*)                                                   as productos_de_fudo,
       count(*) filter (where r.id is not null)                   as con_receta,
       round(100.0 * count(*) filter (where r.id is not null) / nullif(count(*),0), 1) as cobertura_pct
from public.fudo_productos fp
left join public.recetas r
       on r.fudo_product_id = fp.fudo_product_id and r.sede = fp.sede and r.activo
where fp.activo
group by fp.sede
order by fp.sede;


-- ================================================================
-- 10) RECETAS QUE APUNTAN A UN PRODUCTO QUE YA NO ESTÁ
--
-- Si un insumo se desactivó o se borró, la receta queda apuntando al
-- vacío y el cálculo para Fudo deja de considerarlo.
-- ================================================================
select r.sede, r.fudo_product_id, ri.producto_id as insumo_que_no_existe
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
left join public.productos p on p.id = ri.producto_id and p.activo = 'SÍ'
where r.activo and p.id is null
order by r.sede, r.fudo_product_id;
