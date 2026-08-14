-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        5 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. No arregla, no escribe, no toca Fudo.
--  QUÉ VER:   el bloque 1 separa los que sí suben de los que no.
--             El bloque 2 es el caso Cannoli en detalle.
-- ================================================================
--
-- LA PREGUNTA: los repartos sí están subiendo a Fudo, pero algunos no.
-- Los Cannolis de Mall Plaza se aceptaron en el reparto y Fudo no cambió.
--
-- CÓMO FUNCIONA HOY, en una frase: cuando el jefe de turno aprieta
-- "Llegó", la app suma al inventario Y le avisa a Fudo. Pero a Fudo solo
-- le avisa de los productos que él vende de a uno — los que son el ÚNICO
-- ingrediente de una receta, con cantidad 1. Un combo no se toca, porque
-- cuántos combos se pueden vender depende también de la bebida.
--
-- Y ACÁ ESTÁ LA SOSPECHA, que es lo que este informe viene a confirmar o
-- a descartar: el aviso a Fudo busca la receta por la FICHA EXACTA que
-- recibió el reparto. Si el reparto entra al Congelador pero la receta
-- descuenta de la Vitrina, para el programa son dos productos distintos y
-- no encuentra a quién avisarle.
--
-- Eso encaja con que "algunos sí y otros no": los que no tienen pareja
-- suben bien, y los que viven en dos muebles fallan calladamente.
--
-- ⚠️ OJO: el botón rojo de administración SÍ suma el par (desde el
-- 2026-07-29 el cálculo usa el nombre base). El aviso del reparto no.
-- Son dos caminos distintos y hoy no piensan igual.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ⭐ LOS QUE SÍ Y LOS QUE NO
--
-- Una fila por cada cosa recibida en los últimos 14 días, en las dos
-- sedes. La última columna dice si a Fudo le TOCABA subir esa ficha.
--
-- QUÉ VER: si los que dicen "NO" son casi todos de Vitrina/Congelador,
-- la sospecha de arriba queda confirmada y el arreglo es chico.
-- ================================================================
with recibido as (
  select r.sede,
         ri.producto_id,
         ri.producto,
         coalesce(ri.cantidad_recibida, ri.cantidad_pedida) as cantidad,
         ri.resuelto_por,
         ri.resuelto_at
  from public.reparto_items ri
  join public.repartos r on r.id = ri.reparto_id
  where ri.estado = 'recibido'
    and ri.resuelto_at > now() - interval '14 days'
),
solo_insumo as (
  -- exactamente el filtro que usa el programa que le escribe a Fudo:
  -- receta activa de la sede, UNA sola línea, cantidad 1
  select rc.sede, ri2.producto_id, count(*) as recetas
  from public.recetas rc
  join public.receta_items ri2 on ri2.receta_id = rc.id
  where rc.activo = true
    and ri2.cantidad = 1
    and (select count(*) from public.receta_items x where x.receta_id = rc.id) = 1
  group by rc.sede, ri2.producto_id
)
select rb.sede,
       rb.resuelto_at         as cuando,
       rb.producto,
       rb.producto_id         as ficha_que_recibio,
       rb.cantidad,
       rb.resuelto_por        as quien_confirmo,
       coalesce(s.recetas, 0) as recetas_que_la_venden_sola,
       case when coalesce(s.recetas, 0) > 0
            then 'sí · a Fudo le tocaba subir'
            else 'NO · ninguna receta usa esta ficha como único ingrediente'
       end                    as veredicto
from recibido rb
left join solo_insumo s on s.sede = rb.sede and s.producto_id = rb.producto_id
order by rb.resuelto_at desc
limit 80;


-- ================================================================
-- BLOQUE 2 — EL CASO CANNOLI, con nombre y apellido
--
-- Todas las fichas de Mall Plaza que se llaman parecido a "cannoli", y
-- por cada una: si tiene receta propia, cuál es, y cuánto stock tiene.
--
-- Se busca con comodines a propósito (§9.7): en Fudo hay nombres con
-- espacios invisibles y comparar letra por letra los esconde.
--
-- QUÉ VER: si aparecen DOS fichas y solo una tiene receta, ahí está el
-- problema — el reparto entró en la que no tiene.
-- ================================================================
select p.sede,
       p.id                        as ficha,
       p.producto,
       p.rubro                     as seccion,
       p.activo,
       coalesce(p.stock_actual, 0) as stock,
       rc.fudo_product_nombre      as se_vende_en_fudo_como,
       rc.fudo_product_id,
       (select count(*) from public.receta_items x where x.receta_id = rc.id) as ingredientes_de_esa_receta,
       ri.cantidad                 as cuanto_descuenta
from public.productos p
left join public.receta_items ri on ri.producto_id = p.id
left join public.recetas rc on rc.id = ri.receta_id and rc.activo = true
where p.producto ilike '%cannoli%'
order by p.sede, p.producto, rc.fudo_product_nombre;


-- ================================================================
-- BLOQUE 3 — LOS QUE FALLARON: ¿DÓNDE ESTÁ SU RECETA?
--
-- Toma cada ficha que recibió reparto y no tenía receta propia, y busca
-- si existe OTRA ficha del mismo producto (mismo nombre sin el apellido
-- del mueble) que sí la tenga.
--
-- QUÉ VER:
--   · "MISMO producto, otra ficha" -> es lo que sospechamos. Se arregla
--     y es el mejor caso: el trabajo ya está hecho, solo apunta al
--     mueble equivocado.
--   · "no hay receta en ninguna ficha" -> ese producto Fudo no lo vende
--     de a uno, o le falta la receta. No es una falla del reparto.
-- ================================================================
with recibido as (
  select distinct r.sede, ri.producto_id, ri.producto
  from public.reparto_items ri
  join public.repartos r on r.id = ri.reparto_id
  where ri.estado = 'recibido'
    and ri.resuelto_at > now() - interval '14 days'
),
solo_insumo as (
  select rc.sede, ri2.producto_id,
         min(rc.fudo_product_nombre) as se_vende_en_fudo,
         count(*) as recetas
  from public.recetas rc
  join public.receta_items ri2 on ri2.receta_id = rc.id
  where rc.activo = true
    and ri2.cantidad = 1
    and (select count(*) from public.receta_items x where x.receta_id = rc.id) = 1
  group by rc.sede, ri2.producto_id
),
sin_receta as (
  select rb.* from recibido rb
  left join solo_insumo s on s.sede = rb.sede and s.producto_id = rb.producto_id
  where s.producto_id is null
),
base as (
  -- dos nombres base a propósito:
  --   estricta = exactamente lo que entienden la app, la base y el programa
  --              que le escribe a Fudo (solo " vitrina" / " congelador" al final)
  --   amplia   = además " vitrina de dulces" y compañía, que NINGUNO de los
  --              tres entiende. Sirve para destapar las que necesitan un
  --              renombre — es el caso que costó el sobre-stock de macarrons.
  select p.id, p.sede, p.producto, p.rubro, p.activo,
         btrim(regexp_replace(lower(p.producto),
               '\s+(vitrina|congelador)\s*' || chr(36), '')) as base_estricta,
         btrim(regexp_replace(lower(p.producto),
               '\s+(vitrina|congelador|congelados)(\s+de\s+[a-zA-Z]+)?\s*' || chr(36), '')) as base_amplia
  from public.productos p
)
select sr.sede,
       sr.producto     as llego_en_el_reparto,
       sr.producto_id  as ficha_que_recibio,
       b0.rubro        as entro_en_la_seccion,
       h.id            as la_receta_apunta_a_la_ficha,
       h.producto      as que_se_llama,
       h.rubro         as que_esta_en,
       s2.se_vende_en_fudo,
       case
         when h.id is null
           then 'no hay receta en ninguna ficha de este producto'
         when h.base_estricta = b0.base_estricta
           then 'MISMO producto, otra ficha · el arreglo lo cubre'
         else '⚠️ MISMO producto pero el nombre no calza · hay que renombrar la ficha'
       end             as que_pasa
from sin_receta sr
join base b0 on b0.id = sr.producto_id
left join base h on h.sede = b0.sede and h.base_amplia = b0.base_amplia and h.id <> b0.id
left join solo_insumo s2 on s2.sede = h.sede and s2.producto_id = h.id
where h.id is null or s2.producto_id is not null
order by (h.id is null), sr.sede, sr.producto;


-- ================================================================
-- BLOQUE 4 — LA BITÁCORA: qué se le escribió a Fudo de verdad
--
-- Cada escritura a Fudo queda anotada acá con el valor de antes y el que
-- se mandó. Sirve para confirmar que el camino funciona (y por lo tanto
-- que lo que falla es a QUIÉN se le avisa, no el aviso en sí).
-- ================================================================
select sede,
       date_trunc('day', created_at) as dia,
       ok,
       count(*)        as veces,
       max(created_at) as ultima,
       max(quien)      as un_correo_de_ejemplo,
       max(detalle)    as un_detalle_de_ejemplo
from public.fudo_stock_push
where created_at > now() - interval '14 days'
group by sede, date_trunc('day', created_at), ok
order by dia desc, sede;


-- ================================================================
-- BLOQUE 5 — QUIÉN PUEDE ESCRIBIRLE A FUDO
--
-- Escribir en Fudo es lo único de la app que exige sesión iniciada Y
-- permiso. Si quien confirma el reparto no entró con una cuenta de esta
-- lista, el inventario sube igual y Fudo no.
-- ================================================================
select correo, puede_editar, puede_fudo
from public.app_permisos
order by correo;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-repartos-que-no-suben-a-fudo.sql', 'Jhon', 'lo corrió Jhon',
        'Informe de SOLO LECTURA: por qué algunos repartos suben a Fudo y otros no (caso Cannolis, Mall Plaza)')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
