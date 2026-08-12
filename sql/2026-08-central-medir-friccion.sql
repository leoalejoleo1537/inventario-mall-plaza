-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Uno por uno.
--  TARDA:     instantáneo
--  QUÉ HACE:  solo MIRA. Mide cuánta pregunta le va a hacer el reparto a
--             Adriana antes de construirlo. No escribe nada.
--  QUÉ VER:   pégame las dos tablas.
-- ================================================================
--
-- LA PREGUNTA QUE CONTESTA: cuando Adriana arme el reparto buscando en la
-- lista de Plaza o de Angamos, ¿cuántas veces se va a topar con un producto
-- que bodega no reconoce como suyo?
--
-- Los 290 pares ya escritos cubren lo que calzaba por nombre. Lo que falta son
-- productos del local sin origen en bodega. La pregunta no es cuántos son,
-- sino QUÉ SON: si son preparados del local, combos o cosas que solo vive en
-- la carta de Fudo, bodega nunca los manda y la fricción es cero. Si aparecen
-- insumos de verdad, hay que emparejarlos antes de construir.
--
-- Se mide ahora y no después porque el resultado puede cambiar el diseño.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL TAMAÑO, DE UN VISTAZO
--
-- QUÉ VER: la columna `sin_origen`. Es el techo de cuántas veces se podría
-- preguntar — el techo, no lo que va a pasar: solo se pregunta por lo que
-- Adriana de verdad envíe alguna vez.
-- ================================================================
select s.sede,
       count(*)                                                          as productos_del_local,
       count(*) filter (where e.id is not null)                          as con_origen_en_bodega,
       count(*) filter (where e.id is null)                              as sin_origen
from public.productos s
left join public.producto_enlace e
       on e.sede = s.sede and e.producto_sede_id = s.id
where s.sede in ('plaza','angamos') and s.activo = 'SÍ'
group by s.sede
order by s.sede;


-- ================================================================
-- BLOQUE 2 — Y SOBRE TODO: QUÉ SON
--
-- Los que no tienen origen en bodega, agrupados por sección para poder
-- reconocerlos de una pasada.
--
-- QUÉ VER, y es lo único que importa de todo el script: recorré las
-- secciones y preguntate por cada una **"¿esto se lo manda bodega al local?"**
--   · Si son preparados, combos o cosas de la carta -> perfecto, seguimos.
--   · Si aparece un insumo que bodega SÍ manda -> decímelo, lo emparejamos
--     antes y el reparto nace sin preguntar nada.
-- ================================================================
select s.sede,
       coalesce(s.rubro,'(sin sección)')                                 as seccion,
       count(*)                                                          as cuantos,
       string_agg(s.producto, ' · ' order by s.producto)                 as cuales
from public.productos s
where s.sede in ('plaza','angamos') and s.activo = 'SÍ'
  and not exists (select 1 from public.producto_enlace e
                   where e.sede = s.sede and e.producto_sede_id = s.id)
group by s.sede, coalesce(s.rubro,'(sin sección)')
order by s.sede, count(*) desc;
