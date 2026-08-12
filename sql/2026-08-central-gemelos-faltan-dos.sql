-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Uno por uno.
--  TARDA:     instantáneo
--  QUÉ HACE:  solo MIRA. Busca por qué Plaza pasó de 148 pares en el
--             informe a 146 escritos.
--  QUÉ VER:   pégame las dos tablas.
-- ================================================================
--
-- QUÉ PASÓ, EN CORTO: el informe se corrió antes y la escritura después. La
-- vista recalcula cada vez en vez de usar una lista congelada — por eso el
-- número bajó en lugar de escribir dos pares que ya no correspondían. El
-- sistema se comportó bien; lo que falta es saber CUÁLES son esos dos, porque
-- son dos productos que el reparto no va a poder mover hasta que se resuelvan.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LOS QUE TIENEN CANDIDATO EN PLAZA Y NO QUEDARON ENLAZADOS
--
-- QUÉ VER: deberían salir 3. El `Muffin vainilla chips` que ya conocíamos
-- (tiene dos candidatos) y los dos que cambiaron.
--
-- Las columnas dicen el porqué:
--   candidatos_en_plaza = 2  -> hay dos productos iguales en Plaza, hay que elegir
--   copias_en_bodega    = 2  -> el duplicado está del lado de bodega
--   estado_del_candidato     -> si ese producto de Plaza ya lo tomó otro
-- ================================================================
with c as (
  select id, producto, public.clave_nombre(producto) as clave
    from public.productos where sede='central' and activo='SÍ'
),
s as (
  select id, producto, public.clave_nombre(producto) as clave
    from public.productos where sede='plaza' and activo='SÍ'
)
select c.producto                                          as en_bodega,
       c.id                                                as bodega_id,
       count(distinct s.id)                                as candidatos_en_plaza,
       (select count(*) from c c2 where c2.clave = c.clave) as copias_en_bodega,
       string_agg(distinct s.producto || ' [#' || s.id || ']', '  |  ') as cuales,
       string_agg(distinct case
         when exists (select 1 from public.producto_enlace e
                       where e.sede='plaza' and e.producto_sede_id = s.id)
         then 'ese ya está tomado por otro de bodega' else 'libre' end, ' · ') as estado
from c
join s on s.clave = c.clave
where not exists (select 1 from public.producto_enlace e
                   where e.producto_bodega_id = c.id and e.sede='plaza')
group by c.id, c.producto, c.clave
order by c.producto;


-- ================================================================
-- BLOQUE 2 — QUÉ SE EDITÓ EN LAS ÚLTIMAS 24 HORAS
--
-- Si alguien apagó, renombró o creó productos en Plaza mientras probabas la
-- app, acá aparecen. Es la explicación más probable del cambio de número.
--
-- QUÉ VER: si ves dos de Plaza que reconozcas como algo que tú tocaste, ya
-- está explicado y no hay nada que arreglar.
-- ================================================================
select sede, producto, activo,
       to_char(updated_at,'DD/MM HH24:MI') as editado
from public.productos
where sede in ('central','plaza')
  and updated_at > now() - interval '24 hours'
order by updated_at desc
limit 40;
