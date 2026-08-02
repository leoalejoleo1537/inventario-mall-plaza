-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO, no todo junto.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  compara el inventario de Angamos contra el de Plaza y
--             devuelve tres listas para que decidas. NO ESCRIBE NADA.
--  QUÉ VER:   cada bloque dice qué mirar y qué decidir.
-- ================================================================
--
-- POR QUÉ EXISTE: antes de trasladar las 168 recetas de Plaza a Angamos
-- hay que dejar el inventario de Angamos ordenado. Si no, cada insumo
-- tiene dos candidatos y el emparejador no puede decidir.
--
-- ⚠️ TODO DE SOLO LECTURA. No crea, no borra, no desactiva, no renombra.
-- Las listas son PREGUNTAS para Jhon (regla 0 del archivo madre).
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL PANORAMA
--
-- Los números de las dos sedes, lado a lado. Es la foto de partida.
-- ================================================================
select 'productos activos'            as que,
       count(*) filter (where sede='plaza'   and activo='SÍ') as plaza,
       count(*) filter (where sede='angamos' and activo='SÍ') as angamos
from public.productos
union all
select 'recetas activas',
       (select count(*) from public.recetas where sede='plaza'   and activo),
       (select count(*) from public.recetas where sede='angamos' and activo)
union all
select 'productos de Fudo (catálogo)',
       (select count(*) from public.fudo_productos where sede='plaza'   and activo),
       (select count(*) from public.fudo_productos where sede='angamos' and activo)
union all
select 'líneas de receta',
       (select count(*) from public.receta_items ri
          join public.recetas r on r.id=ri.receta_id where r.sede='plaza' and r.activo),
       (select count(*) from public.receta_items ri
          join public.recetas r on r.id=ri.receta_id where r.sede='angamos' and r.activo);


-- ================================================================
-- BLOQUE 2 — LISTA A: LOS DUPLICADOS DE ANGAMOS
--
-- QUÉ MIRAR: cada fila es un producto que existe DOS veces en Angamos,
-- uno en su sección y otro en Congelador.
--
-- DE DÓNDE SALEN: sql/2026-07-duplicar-vitrina-en-congelador.sql corre
-- sobre las dos sedes (`where p.sede in ('plaza','angamos')`). En Plaza
-- el par vitrina/congelador es necesario; en Angamos NO — esa sede tiene
-- su propia bodega y ese inventario todavía no se hace.
--
-- QUÉ DECIDIR: si se desactiva la copia de Congelador (activo='NO', no
-- borrar). Fíjate en la columna "stock_congelador": si alguna tiene
-- stock distinto de cero, alguien la está usando y hay que preguntar
-- antes de apagarla.
-- ================================================================
select p1.producto,
       p1.rubro                       as seccion_original,
       p1.stock_actual                as stock_original,
       p2.rubro                       as seccion_duplicada,
       p2.stock_actual                as stock_congelador,
       p2.id                          as id_a_desactivar,
       case when coalesce(p2.stock_actual,0) <> 0
            then '⚠️ tiene stock — preguntar antes de apagar'
            else 'se puede apagar' end as veredicto
from public.productos p1
join public.productos p2
  on p2.sede = p1.sede
 and p2.producto = p1.producto
 and p2.id <> p1.id
 and p2.rubro = 'Congelador'
where p1.sede = 'angamos'
  and p1.activo = 'SÍ'
  and p2.activo = 'SÍ'
  and p1.rubro <> 'Congelador'
order by p1.producto;


-- ================================================================
-- BLOQUE 3 — LISTA B: INSUMOS DE PLAZA SIN PAREJA EN ANGAMOS
--
-- QUÉ MIRAR: cada fila es un insumo que las recetas de Plaza usan y que
-- NO tiene un producto con el mismo nombre en Angamos.
--
-- La columna "candidato_en_angamos" propone el nombre más parecido.
-- PROPONE — no concluye (regla 0.1.4). Hay dos casos y solo tú los
-- distingues:
--   · es el mismo producto con otro nombre  ->  hay que emparejarlos
--   · de verdad falta en Angamos            ->  hay que crearlo
--
-- La comparación quita el apellido de sección de Plaza (" Vitrina" /
-- " Congelador"), porque en Angamos los productos van sin apellido.
-- ⚠️ NO quita "congelado" ni "congelada": en "Plátano congelado" eso es
-- parte del nombre, no una sección.
-- ================================================================
with base_plaza as (
  select distinct
         p.producto,
         p.rubro,
         lower(translate(regexp_replace(p.producto,'\s+(Vitrina|Congelador|vitrina|congelador)$','')
               ,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.receta_items ri
  join public.recetas  r on r.id = ri.receta_id and r.sede='plaza' and r.activo
  join public.productos p on p.id = ri.producto_id and p.sede='plaza'
),
-- La palabra MÁS LARGA del nombre, no la primera: en "T. Cheesecake Mara" la
-- primera es "T." y no sirve para buscar. La más larga es "cheesecake", que sí
-- encuentra "T. Cheesecake Maracuya" en Angamos.
plaza_clave as (
  select bp.*,
         (select w from regexp_split_to_table(bp.clave, '\s+') w
           where length(w) >= 4 order by length(w) desc, w limit 1) as palabra
  from base_plaza bp
),
base_angamos as (
  select producto, rubro,
         lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos
  where sede='angamos' and activo='SÍ'
),
usos as (
  select p.producto, count(*) as veces
  from public.receta_items ri
  join public.recetas  r on r.id = ri.receta_id and r.sede='plaza' and r.activo
  join public.productos p on p.id = ri.producto_id
  group by p.producto
)
select pc.producto            as insumo_en_plaza,
       pc.rubro               as seccion_en_plaza,
       coalesce((select string_agg(distinct ba.producto, '  ·  ')
                   from base_angamos ba
                  where pc.palabra is not null and ba.clave like '%'||pc.palabra||'%'),
                '— ninguno se le parece —')
                              as candidato_en_angamos,
       coalesce(u.veces, 0)   as en_cuantas_recetas
from plaza_clave pc
left join usos u on u.producto = pc.producto
where not exists (select 1 from base_angamos ba where ba.clave = pc.clave)
order by en_cuantas_recetas desc, pc.producto;


-- ================================================================
-- BLOQUE 4 — LISTA C: PRODUCTOS QUE SOLO EXISTEN EN ANGAMOS
--
-- QUÉ MIRAR: Jhon confirmó que las dos sedes tienen la MISMA CARTA, así
-- que acá NO deberían aparecer platos. Lo esperable son insumos, envases
-- o limpieza propios de esa sede.
--
-- QUÉ DECIDIR: nada todavía. Si aparece un plato de la carta, es señal
-- de que algo no calza con lo que creemos y hay que mirarlo antes de
-- trasladar recetas.
-- ================================================================
with clave_plaza as (
  select lower(translate(regexp_replace(producto,'\s+(Vitrina|Congelador|vitrina|congelador)$','')
        ,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos where sede='plaza' and activo='SÍ'
)
select rubro                as seccion,
       producto,
       stock_actual         as stock,
       coalesce(tipo,'—')   as tipo
from public.productos a
where a.sede='angamos' and a.activo='SÍ'
  and not exists (
    select 1 from clave_plaza cp
     where cp.clave = lower(translate(a.producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')))
order by rubro, producto;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-informe-inventario.sql', 'Jhon', 'lo corrió Jhon',
        'Solo lectura. Informe previo al traslado de recetas a Angamos')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
