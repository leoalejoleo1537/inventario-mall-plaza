-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        5 bloques. Correr los 5 y mandarme TODO.
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. No arregla, no restaura, no borra.
--  QUÉ VER:   el bloque 2 dice CUÁNDO cambió cada cosa. Ese decide todo.
-- ================================================================
--
-- ⚠️ NO CORRAS NINGÚN ARREGLO ANTES DE ESTO. Restaurar sobre un estado que
-- no entendemos es cómo un problema se vuelve dos.
--
-- LA BUENA NOTICIA, y va primero porque cambia el ánimo: **no se perdió
-- nada de forma definitiva.**
--   · Eliminar un producto en la app NO borra la fila: la desactiva. Todos
--     los productos que borraste siguen ahí.
--   · El historial guarda, por producto y por día: nombre, SECCIÓN, stock,
--     mínimo y máximo. O sea exactamente lo que dices que perdiste.
--
-- Este archivo confirma qué pasó y con qué material contamos.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ¿CÓMO ESTÁ ANGAMOS AHORA MISMO?
-- ================================================================
select count(*) filter (where activo = 'SÍ')                       as activos,
       count(*) filter (where activo <> 'SÍ')                      as desactivados,
       count(*) filter (where activo = 'SÍ' and coalesce(stock_actual,0) > 0) as con_stock,
       count(*) filter (where activo = 'SÍ' and stock_min is null)  as sin_minimo,
       count(distinct rubro) filter (where activo = 'SÍ')           as secciones,
       string_agg(distinct rubro, ' · ') filter (where activo = 'SÍ') as cuales_secciones
from public.productos
where sede = 'angamos';


-- ================================================================
-- BLOQUE 2 — ⭐ EL QUE DECIDE: ¿CUÁNDO CAMBIÓ CADA FILA?
--
-- `updated_at` se escribe cada vez que alguien edita un producto desde la
-- app. Agrupado por día y hora, dice QUIÉN pudo haber sido:
--
--   · si hay un pico de cientos de filas en un minuto -> fue algo masivo
--   · si está repartido a lo largo de horas -> fue gente editando a mano
--   · si las fechas son viejas -> esas filas NO se tocaron y el problema
--     es otro (por ejemplo, que la pantalla no las está mostrando)
--
-- ⚠️ MIS SCRIPTS NUNCA HICIERON UN `update` NI UN `delete` SOBRE PRODUCTOS.
-- Lo único que hicieron fue INSERTAR 9 filas nuevas. Así que si acá aparece
-- un cambio masivo, vino de otro lado y necesitamos saber de dónde.
-- ================================================================
select date_trunc('hour', updated_at) as cuando,
       count(*)                       as filas_tocadas,
       count(*) filter (where coalesce(stock_actual,0) = 0) as quedaron_en_cero,
       count(*) filter (where stock_min is null)            as quedaron_sin_minimo,
       min(id) as id_mas_bajo, max(id) as id_mas_alto
from public.productos
where sede = 'angamos' and updated_at is not null
group by 1
order by 1 desc
limit 25;


-- ================================================================
-- BLOQUE 3 — ⭐ QUÉ DÍAS DE HISTORIAL HAY PARA RESTAURAR
--
-- Cada fila es un día guardado. "productos" dice cuántos productos tenía
-- ese día, y las otras columnas si ese día trae stock y mínimos de verdad.
--
-- QUÉ VER: busca el día 07 (o el que quieras) y fíjate que "con_stock" y
-- "con_minimo" NO sean cero. Ese es el día que vamos a restaurar.
-- ================================================================
select fecha,
       count(*)                                              as productos,
       count(*) filter (where coalesce(stock_actual,0) > 0)  as con_stock,
       count(*) filter (where stock_min is not null)         as con_minimo,
       count(distinct rubro)                                 as secciones,
       string_agg(distinct rubro, ' · ')                     as cuales_secciones
from public.historial
where sede = 'angamos'
group by fecha
order by fecha desc
limit 15;


-- ================================================================
-- BLOQUE 4 — LOS 9 PRODUCTOS QUE YO CREÉ, y si duplicaron alguno
--
-- Mi script creó 9 productos en Angamos (ids 1019-1027) porque las recetas
-- los necesitaban. El error: comprobé si ya existían mirando SOLO entre los
-- ACTIVOS. Si tú habías eliminado alguno, mi comprobación no lo vio y creé
-- una copia nueva — que en pantalla se ve como "volvió el que yo borré".
--
-- QUÉ VER: la columna "ya_existia_desactivado". Si dice sí, ese es un
-- duplicado que hice yo y hay que apagar.
-- ================================================================
select n.id, n.producto, n.rubro, n.stock_actual, n.activo,
       (select string_agg(v.id::text || ' (' || v.activo || ')', ', ')
          from public.productos v
         where v.sede = 'angamos' and v.id <> n.id
           and translate(lower(trim(v.producto)),'áéíóúüñ','aeiouun')
             = translate(lower(trim(n.producto)),'áéíóúüñ','aeiouun'))
                                                as otras_copias,
       case when exists (select 1 from public.productos v
                          where v.sede='angamos' and v.id <> n.id and v.activo <> 'SÍ'
                            and translate(lower(trim(v.producto)),'áéíóúüñ','aeiouun')
                              = translate(lower(trim(n.producto)),'áéíóúüñ','aeiouun'))
            then '⚠️ sí — lo creé de más' else 'no' end as ya_existia_desactivado
from public.productos n
where n.sede = 'angamos' and n.id between 1019 and 1027
order by n.id;


-- ================================================================
-- BLOQUE 5 — ¿SIGUEN LOS RESPALDOS DE LAS RECETAS?
-- ================================================================
select 'receta_items_respaldo_20260809' as tabla,
       case when to_regclass('public.receta_items_respaldo_20260809') is null then 'NO EXISTE'
            else (select count(*)::text || ' renglones guardados'
                    from public.receta_items_respaldo_20260809) end as estado
union all
select 'recetas de angamos ahora',
       (select count(*)::text from public.recetas where sede='angamos' and activo)
union all
select 'renglones de esas recetas',
       (select count(*)::text from public.receta_items ri
          join public.recetas r on r.id = ri.receta_id
         where r.sede='angamos' and r.activo);


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-INCIDENTE-diagnostico.sql', 'Jhon', 'lo corrió Jhon',
        'SOLO LECTURA: diagnóstico del incidente de Angamos del 9 de agosto — cuándo cambió cada fila, qué días de historial hay para restaurar, y qué duplicados creó mi script')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
