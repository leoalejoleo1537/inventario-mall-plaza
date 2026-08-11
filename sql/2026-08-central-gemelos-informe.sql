-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        5 bloques. UNO POR UNO (el editor muestra solo el último
--             resultado de cada corrida).
--  TARDA:     instantáneo
--  QUÉ HACE:  MIRA y propone qué producto de cada local es el gemelo de
--             cada producto de bodega. NO escribe ningún par todavía.
--             Lo único que crea el bloque 0 es una función de comparar.
--  QUÉ VER:   pégame los bloques 1, 2 y 3. El 4 es para que lo mires tú.
-- ================================================================
--
-- LA IMAGEN: bodega tiene "Leche entera" y Angamos tiene "Leche entera", pero
-- para el sistema son dos fichas distintas con dos números distintos. Alguien
-- tiene que decirle, una vez, que son la misma cosa. Eso es un gemelo.
--
-- POR QUÉ HACE FALTA: sin esto, cuando salga un reparto de bodega hacia
-- Angamos, el sistema no sabe a qué producto de Angamos sumarle. Los productos
-- se reconocen por ID y nunca por nombre — el nombre solo sirve para PROPONER
-- la pareja acá; una vez confirmada, el enlace es por ID y renombrar cualquiera
-- de los dos no lo rompe.
--
-- ⚠️ LO QUE ESTE INFORME NO HACE, Y ES A PROPÓSITO: no empareja por parecido.
-- Solo junta los que se llaman EXACTAMENTE igual (sin contar tildes, mayúsculas
-- ni espacios de más). El emparejado por parecido ya falló donde más caro
-- salía: propuso `Croissant manjar` para `Croissant Jamon Queso`, que era
-- insumo de 11 recetas. Lo que no calce exacto lo decides tú, no el programa.
-- ================================================================


-- ================================================================
-- BLOQUE 0 — LA REGLA DE COMPARAR, EN UN SOLO LUGAR
--
-- Una función chica que deja los nombres "planos" para compararlos: sin
-- mayúsculas, sin tildes y sin espacios de más. Así "  Café   con LECHE " y
-- "cafe con leche" se reconocen como lo mismo.
--
-- Está aparte por una razón que ya costó caro: el script que ESCRIBA los pares
-- va a usar esta misma función. Si el informe comparara de una forma y la
-- escritura de otra, la vista previa estaría mintiendo — que es exactamente lo
-- que pasó el 9 de agosto (regla 0.6.3).
--
-- No toca ni un dato: solo enseña a comparar.
-- QUÉ VER: tiene que decir  cafe con leche nono
-- ================================================================
create or replace function public.clave_nombre(t text)
returns text language sql immutable
return translate(lower(regexp_replace(trim(coalesce(t,'')), '\s+', ' ', 'g')),
                 'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunaeiouun');

select public.clave_nombre('  Café   con LECHE ñoño ') as ejemplo;


-- ================================================================
-- BLOQUE 1 — EL RESUMEN
--
-- QUÉ VER: tres números por local.
--   pares_limpios = uno de bodega calza con uno solo del local. Estos son los
--                   que se pueden confirmar en bloque.
--   ambiguos      = hay más de un candidato de un lado o del otro. Los decides
--                   tú, uno por uno (bloque 2).
--   sin_pareja    = productos de bodega que no existen en ese local. Casi
--                   seguro son cosas que solo se guardan en bodega.
-- ================================================================
with c as (
  select public.clave_nombre(producto) as clave, count(*) as n_bodega
  from public.productos where sede='central' and activo='SÍ' group by 1
),
s as (
  select sede, public.clave_nombre(producto) as clave, count(*) as n_sede
  from public.productos where sede in ('plaza','angamos') and activo='SÍ' group by 1,2
),
locales as (select unnest(array['plaza','angamos']) as sede)
select l.sede,
       count(*) filter (where s.n_sede is not null and c.n_bodega=1 and s.n_sede=1) as pares_limpios,
       count(*) filter (where s.n_sede is not null and (c.n_bodega>1 or s.n_sede>1)) as ambiguos,
       count(*) filter (where s.n_sede is null)                                      as sin_pareja,
       count(*)                                                                      as total_bodega
from locales l
cross join c
left join s on s.sede = l.sede and s.clave = c.clave
group by l.sede
order by l.sede;


-- ================================================================
-- BLOQUE 2 — LOS AMBIGUOS: los que tienes que decidir tú
--
-- Salen acá cuando hay dos candidatos de un lado. La base NO permite que un
-- producto de bodega tenga dos gemelos en el mismo local, ni que un producto
-- del local venga de dos de bodega — así que estos hay que resolverlos antes
-- de escribir nada.
--
-- QUÉ VER: si la tabla sale VACÍA, mejor: no hay nada que decidir.
-- ================================================================
with c as (select id, producto, public.clave_nombre(producto) as clave
             from public.productos where sede='central' and activo='SÍ'),
s as (select id, sede, producto, public.clave_nombre(producto) as clave
        from public.productos where sede in ('plaza','angamos') and activo='SÍ')
select s.sede,
       string_agg(distinct c.producto || ' [#' || c.id || ']', '  |  ') as en_bodega,
       string_agg(distinct s.producto || ' [#' || s.id || ']', '  |  ') as en_el_local
from c join s on s.clave = c.clave
group by s.sede, c.clave
having count(distinct c.id) > 1 or count(distinct s.id) > 1
order by s.sede;


-- ================================================================
-- BLOQUE 3 — LO QUE SOLO EXISTE EN BODEGA
--
-- Productos de bodega que no aparecen en Plaza NI en Angamos. Lo esperable es
-- que sean cosas que nunca bajan al local con ese nombre: bultos, envases,
-- limpieza. Van agrupados por sección para que se lea de un vistazo.
--
-- QUÉ VER: si en esta lista aparece algo que SÍ debería estar en un local, es
-- que allá se llama distinto — y ese es un gemelo que hay que armar a mano.
-- ================================================================
with c as (select id, producto, rubro, public.clave_nombre(producto) as clave
             from public.productos where sede='central' and activo='SÍ'),
s as (select distinct public.clave_nombre(producto) as clave
        from public.productos where sede in ('plaza','angamos') and activo='SÍ')
select coalesce(c.rubro,'(sin sección)')                    as seccion,
       count(*)                                             as cuantos,
       string_agg(c.producto, ' · ' order by c.producto)     as productos
from c
where not exists (select 1 from s where s.clave = c.clave)
group by 1
order by 2 desc;


-- ================================================================
-- BLOQUE 4 — LA LISTA COMPLETA DE PARES PROPUESTOS
--
-- ⚠️ ESTE NO ME LO PEGUES: son varios cientos de filas y no las necesito.
-- Es para que lo mires TÚ y me digas solo si ves alguno raro — dos nombres
-- iguales que en realidad son cosas distintas.
--
-- Es el paso que pide el plan de bodega: el programa propone, tú confirmas.
-- Ordenado por local y por nombre para poder recorrerlo rápido.
-- ================================================================
with c as (select id, producto, rubro, public.clave_nombre(producto) as clave
             from public.productos where sede='central' and activo='SÍ'),
s as (select id, sede, producto, rubro, public.clave_nombre(producto) as clave
        from public.productos where sede in ('plaza','angamos') and activo='SÍ'),
limpios as (
  select c.id as bodega_id, c.producto as en_bodega, c.rubro as seccion_bodega,
         s.sede, s.id as local_id, s.producto as en_el_local, s.rubro as seccion_local
  from c join s on s.clave = c.clave
  where (select count(*) from c c2 where c2.clave = c.clave) = 1
    and (select count(*) from s s2 where s2.clave = c.clave and s2.sede = s.sede) = 1
)
select sede, en_bodega, en_el_local, seccion_bodega, seccion_local, bodega_id, local_id
from limpios
order by sede, en_bodega;
