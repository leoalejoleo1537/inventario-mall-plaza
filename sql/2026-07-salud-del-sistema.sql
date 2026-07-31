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
-- Seleccionar TODO este bloque 0 (desde el primer "select" hasta el
-- "order by 1;") y darle Run. Devuelve UNA tabla de 10 filas.
--
-- ⚠️ Escrito a propósito SIN comillas de dólar ($$) y en sentencias
-- cortas: la primera versión usaba SQL dinámico con $q$ y el editor de
-- Supabase respondía "No se pudo obtener" sin llegar a ejecutarla. Si
-- se vuelve a tocar, mantenerlo corto y sin $$ — el editor es el
-- límite real, no Postgres.
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
select 1 as "#", 'Tope de 1000 filas' as "Que se reviso",
  case when max(n)>=1000 then 'REVISAR YA' when max(n)>=700 then 'MIRAR' else 'ok' end as "Hay que hacer algo",
  string_agg(t||' '||n, ' · ' order by n desc) as "Detalle"
from (select 'productos' t, count(*) n from productos
 union all select 'receta_items', count(*) from receta_items
 union all select 'recetas', count(*) from recetas
 union all select 'producto_lotes', count(*) from producto_lotes
 union all select 'fudo_productos', count(*) from fudo_productos
 union all select 'repartos', count(*) from repartos
 union all select 'reparto_items', count(*) from reparto_items
 -- historial crece para siempre (un inventario guardado por día), pero la app
 -- nunca lo pide entero: pide UN día. Lo que puede truncarse es un día, no la
 -- tabla. Medir el total acá haría que el chequeo grite para siempre desde el
 -- quinto día guardado, y una alarma que siempre suena enseña a ignorarla.
 union all select 'historial (el dia mas grande)',
        coalesce((select max(c) from (select count(*) c from historial group by sede, fecha) h),0)) z
union all
select 2, 'Funciones duplicadas',
  case when count(*)>0 then 'REVISAR YA' else 'ok' end,
  coalesce(string_agg(proname||' ('||n||' firmas)', ' · '), 'ninguna')
from (select p.proname, count(*) n from pg_proc p, pg_namespace s
      where s.oid=p.pronamespace and s.nspname='public'
        and p.proname in ('fudo_procesar_item','fudo_stock_calculado','descontar_lotes',
            'descontar_con_reposicion','base_nombre','reparto_recibir','reparto_rechazar',
            'reparto_deshacer','reparto_cerrar','fudo_ultimo_empuje','historial_dias')
      group by p.proname having count(*)>1) f

union all
select 3, 'Tablas sin actualizacion en vivo',
  case when count(*)>0 then 'MIRAR' else 'ok' end,
  coalesce(string_agg(t, ' · '), 'todas publicadas')
from unnest(array['productos','producto_lotes','repartos','reparto_items']) t
where not exists (select 1 from pg_publication_tables
                  where pubname='supabase_realtime' and schemaname='public' and tablename=t)

union all
select 4, 'Columnas que el motor da por sentadas',
  case when count(*)>0 then 'REVISAR YA' else 'ok' end,
  coalesce(string_agg(tb||'.'||co, ' · '), 'todas presentes')
from (values ('fudo_movimientos','venta_at'),('productos','urgente'),('productos','tipo'),
             ('fudo_stock_push','lote'),('fudo_sync','modo')) v(tb,co)
where not exists (select 1 from information_schema.columns
                  where table_schema='public' and table_name=tb and column_name=co)

union all
select 5, 'Stock que no cuadra con las fechas',
  case when count(*)=0 then 'ok' else 'MIRAR' end,
  case when count(*)=0 then 'todo cuadra' else count(*)||' producto(s) descuadrado(s)' end
from (select p.id from productos p join producto_lotes l on l.producto_id=p.id
      where p.activo='SÍ' group by p.id, p.stock_actual
      having p.stock_actual <> coalesce(sum(l.cantidad),0)) d

union all
select 6, 'Fechas en cantidad cero',
  case when count(*)=0 then 'ok' else 'MIRAR' end,
  case when count(*)=0 then 'ninguna' else count(*)||' fecha(s) vacia(s)' end
from producto_lotes where cantidad<=0

union all
select 7, 'Stock negativo',
  case when count(*)=0 then 'ok' else 'REVISAR YA' end,
  case when count(*)=0 then 'ninguno' else count(*)||' fila(s) en negativo' end
from (select 1 from productos where coalesce(stock_actual,0)<0
      union all select 1 from producto_lotes where coalesce(cantidad,0)<0) g

union all
select 8, 'El motor descuenta (ultimos 7 dias)',
  case when count(*)=0 then 'ok'
       when (select modo from fudo_sync where sede='plaza') <> 'real' then 'MIRAR'
       when count(*) filter (where producto_nombre<>'(sin receta)')=0 then 'MIRAR'
       when count(*) filter (where aplicado)=0 then 'REVISAR YA'
       when count(*) filter (where aplicado)*10
            < count(*) filter (where producto_nombre<>'(sin receta)')*9 then 'MIRAR'
       else 'ok' end,
  case when count(*)=0 then 'no hubo ventas'
       else count(*) filter (where aplicado)||' aplicadas de '
            ||count(*) filter (where producto_nombre<>'(sin receta)')||' con receta'
            ||' · '||count(*) filter (where producto_nombre='(sin receta)')||' sin receta'
            ||' · modo '||coalesce((select modo from fudo_sync where sede='plaza'),'?') end
from fudo_movimientos
where sede='plaza' and coalesce(venta_at, created_at) > now() - interval '7 days'

union all
select 9, 'Cobertura de recetas', 'info',
  coalesce(string_agg(sede||' '||pct||'%', ' · '), 'sin productos de Fudo')
from (select fp.sede, round(100.0*count(*) filter (where r.id is not null)/nullif(count(*),0),0) pct
      from fudo_productos fp
      left join recetas r on r.fudo_product_id=fp.fudo_product_id and r.sede=fp.sede and r.activo
      where fp.activo group by fp.sede) s

union all
select 10, 'Recetas que apuntan al vacio',
  case when count(*)=0 then 'ok' else 'MIRAR' end,
  case when count(*)=0 then 'ninguna' else count(*)||' insumo(s) inexistente(s)' end
from recetas r join receta_items ri on ri.receta_id=r.id
left join productos p on p.id=ri.producto_id and p.activo='SÍ'
where r.activo and p.id is null

order by 1;


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
select tabla, filas,
       case when filas >= 1000 then '🔴 YA CORTADA — la app ve datos incompletos'
            when filas >=  700 then '⚠️ cerca del tope — ponerle limit antes de que llegue'
            else 'ok' end as veredicto,
       1000 - filas as le_faltan_para_el_tope
from (
  select 'productos' as tabla, count(*) as filas from productos
  union all select 'producto_lotes',  count(*) from producto_lotes
  union all select 'recetas',         count(*) from recetas
  union all select 'receta_items',    count(*) from receta_items
  union all select 'fudo_productos',  count(*) from fudo_productos
  union all select 'repartos',        count(*) from repartos
  union all select 'reparto_items',   count(*) from reparto_items
  union all select 'historial',       count(*) from historial
  union all select 'fudo_movimientos',count(*) from fudo_movimientos
  union all select 'fudo_stock_push', count(*) from fudo_stock_push
) z
order by filas desc;


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
-- Un sistema que falla en silencio es peor que uno que se cae.
--
-- ⚠️ La columna se llama `aplicado`, NO `descontado`. Y en modo 'prueba'
-- `aplicado=false` es lo NORMAL (el motor registra pero no toca el
-- stock), así que ahí un cero no es una falla. Por eso el veredicto
-- mira el modo antes de gritar.
-- ================================================================
select date_trunc('day', coalesce(m.venta_at, m.created_at))::date as dia,
       m.sede,
       count(*)                                                as items_leidos,
       count(*) filter (where m.aplicado)                       as items_aplicados,
       count(*) filter (where m.producto_nombre = '(sin receta)') as sin_receta,
       (select modo from public.fudo_sync s where s.sede = m.sede) as modo,
       case when (select modo from public.fudo_sync s where s.sede = m.sede) <> 'real'
              then 'modo prueba — no descuenta a propósito'
            when count(*) filter (where m.aplicado) = 0
              then '🔴 leyó ventas y no aplicó NINGUNA'
            when count(*) filter (where m.aplicado) * 2 < count(*)
              then '⚠️ falló más de la mitad'
            else 'ok' end                                       as veredicto
from public.fudo_movimientos m
where coalesce(m.venta_at, m.created_at) > now() - interval '7 days'
group by 1, 2
order by 1 desc, 2;


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
-- Dos casos distintos, con arreglos distintos:
--   · la fila se BORRÓ            -> hay que rehacer esa línea de receta
--   · el producto está DESACTIVADO -> reactivarlo, o apuntar la receta a otro
--
-- Mientras tanto ese insumo no limita la venta: el cálculo para Fudo lo
-- deja fuera del join, así que ese producto de Fudo se ofrece como si
-- ese ingrediente sobrara.
-- ================================================================
select ri.producto_id                                    as insumo_id,
       coalesce(fp.nombre, '(Fudo '||r.fudo_product_id||')') as receta_de_fudo,
       coalesce(p.producto, '— YA NO EXISTE la fila —')   as insumo,
       coalesce(p.sede,  '—')                            as sede,
       coalesce(p.rubro, '—')                            as seccion,
       coalesce(p.activo,'—')                            as activo,
       coalesce(p.stock_actual::text,'—')                as stock,
       ri.cantidad                                       as descuenta,
       case when p.id is null       then 'la fila se borró: rehacer esta línea de receta'
            when p.activo <> 'SÍ'   then 'existe pero DESACTIVADO: reactivarlo o apuntar a otro'
            else 'ok' end                                as que_pasa
from public.recetas r
join public.receta_items ri on ri.receta_id = r.id
left join public.productos p       on p.id = ri.producto_id
left join public.fudo_productos fp on fp.fudo_product_id = r.fudo_product_id and fp.sede = r.sede
where r.activo
  and (p.id is null or p.activo <> 'SÍ')
order by ri.producto_id;
