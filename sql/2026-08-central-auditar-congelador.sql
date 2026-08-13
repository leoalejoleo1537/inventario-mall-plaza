-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Uno por uno.
--  TARDA:     instantáneo
--  QUÉ HACE:  solo MIRA. Revisa los ~300 enlaces ya escritos contra tu
--             regla del congelador. No corrige nada todavía.
--  QUÉ VER:   si el bloque 1 sale vacío, ninguno está mal apuntado.
-- ================================================================
--
-- POR QUÉ AHORA: tu regla es "todo lo que llega a Mall Plaza llega al
-- congelador, así tenga un doble en vitrina de tortas". Eso vale para TODOS
-- los enlaces, no solo para los nuevos — y desde la última revisión se
-- escribieron enlaces más (Plaza pasó de 146 a 151, Angamos de 144 a 149).
--
-- Un enlace apuntando a la vitrina le sumaría stock a un estante que nadie
-- llenó. Es el mismo error que hizo apagar la reposición automática (§0.2.1),
-- así que se revisa antes de escribir un enlace más.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ENLACES QUE APUNTAN A LA VITRINA TENIENDO CONGELADOR
--
-- QUÉ VER: si sale vacío, están todos bien. Si salen filas, esos son los que
-- hay que redirigir — cambiando el número, nunca el nombre del producto.
-- ================================================================
select e.sede,
       b.producto  as en_bodega,        b.id  as bodega_id,
       s.producto  as apunta_ahora,     s.id  as id_actual,
       c.producto  as deberia_apuntar,  c.id  as id_congelador
from public.producto_enlace e
join public.productos b on b.id = e.producto_bodega_id
join public.productos s on s.id = e.producto_sede_id
join public.productos c
  on c.sede = e.sede and c.activo = 'SÍ' and c.id <> s.id
 and c.producto ilike '% congelador'
 and public.clave_nombre(regexp_replace(c.producto,'\s+(vitrina|congelador)$','','i'))
   = public.clave_nombre(regexp_replace(s.producto,'\s+(vitrina|congelador)$','','i'))
where s.producto not ilike '% congelador'
order by e.sede, b.producto;


-- ================================================================
-- BLOQUE 2 — LOS PARES VITRINA/CONGELADOR QUE EXISTEN EN CADA LOCAL
--
-- Para entender el mapa completo: qué productos tienen doble estante, y cuál
-- de los dos está enlazado a bodega hoy.
--
-- QUÉ VER: la columna `enlazado_a_bodega`. Según tu regla tendría que decir
-- SIEMPRE "el del congelador" o "ninguno" — nunca "el de vitrina".
-- ================================================================
with pares as (
  select p.sede,
         public.clave_nombre(regexp_replace(p.producto,'\s+(vitrina|congelador)$','','i')) as base,
         max(case when p.producto ilike '% congelador' then p.id end) as id_cong,
         max(case when p.producto not ilike '% congelador' then p.id end) as id_otro,
         max(case when p.producto ilike '% congelador' then p.producto end) as nom_cong,
         max(case when p.producto not ilike '% congelador' then p.producto end) as nom_otro
  from public.productos p
  where p.sede in ('plaza','angamos') and p.activo='SÍ'
  group by 1,2
  having count(*) > 1
     and count(*) filter (where p.producto ilike '% congelador') = 1
)
select sede, nom_cong as el_del_congelador, nom_otro as el_otro,
       case
         when exists (select 1 from public.producto_enlace e
                       where e.sede=pares.sede and e.producto_sede_id=id_cong)
              then 'el del congelador ✓'
         when exists (select 1 from public.producto_enlace e
                       where e.sede=pares.sede and e.producto_sede_id=id_otro)
              then '⚠ el de vitrina'
         else 'ninguno'
       end as enlazado_a_bodega
from pares
order by sede, enlazado_a_bodega desc, nom_cong;
