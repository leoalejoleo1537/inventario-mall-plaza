-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        5 bloques. UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  ESCRIBE los 292 pares limpios en producto_enlace.
--             NO toca ni un producto: solo agrega filas a una tabla nueva
--             que hoy está vacía.
--  QUÉ VER:   el bloque 1 tiene que decir 292 antes de escribir nada, y el
--             bloque 3 tiene que decir 292 escritos y 0 por escribir.
-- ================================================================
--
-- LA IMAGEN: es una libreta de equivalencias. "El Sandwich Azapa de bodega y
-- el Sandwich Azapa de Angamos son el mismo". Nada más. Ningún stock se mueve,
-- ningún producto cambia de nombre, ninguna receta se toca.
--
-- POR QUÉ ES DE RIESGO BAJO, dicho con precisión: la única tabla que se
-- escribe es `producto_enlace`, que nació vacía en los cimientos y de la que
-- todavía no depende nada. Si algo saliera mal, deshacerlo es una línea
-- (bloque 4) y el inventario no se entera.
--
-- QUÉ ENTRA: solo los pares donde UN producto de bodega calza con UN producto
-- del local, por nombre exacto (sin tildes, mayúsculas ni espacios de más).
-- QUÉ NO ENTRA: el ambiguo del Muffin vainilla chips de Plaza, y los 76 que no
-- calzan con ningún local. Esos los decides tú.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA VISTA PREVIA
--
-- Crea una vista con los pares propuestos y los cuenta. La vista es lo que va
-- a usar el bloque 2 para escribir — LA MISMA, no una copia parecida. Es la
-- regla que salió del 9 de agosto: si la vista previa y la escritura miran
-- cosas distintas, la vista previa no es una vista previa.
--
-- La vista solo muestra lo que TODAVÍA NO está escrito. Por eso después de
-- escribir queda vacía, y correr esto de nuevo dice 0.
--
-- QUÉ VER: angamos 144, plaza 148, total 292.
-- ================================================================
create or replace view public.gemelos_propuestos as
with c as (
  select id, producto, public.clave_nombre(producto) as clave
    from public.productos where sede='central' and activo='SÍ'
),
s as (
  select id, sede, producto, public.clave_nombre(producto) as clave
    from public.productos where sede in ('plaza','angamos') and activo='SÍ'
)
select c.id as producto_bodega_id, c.producto as en_bodega,
       s.sede, s.id as producto_sede_id, s.producto as en_el_local
from c
join s on s.clave = c.clave
where (select count(*) from c c2 where c2.clave = c.clave) = 1
  and (select count(*) from s s2 where s2.clave = c.clave and s2.sede = s.sede) = 1
  -- lo que ya está escrito no se propone de nuevo
  and not exists (select 1 from public.producto_enlace e
                   where e.producto_bodega_id = c.id and e.sede = s.sede)
  and not exists (select 1 from public.producto_enlace e
                   where e.sede = s.sede and e.producto_sede_id = s.id);

select sede, count(*) as pares_por_escribir
from public.gemelos_propuestos
group by sede
union all
select 'TOTAL', count(*) from public.gemelos_propuestos
order by 1;


-- ================================================================
-- BLOQUE 2 — ESCRIBIRLOS
--
-- `on conflict do nothing` es un cinturón de seguridad: la base ya no permite
-- que un producto de bodega tenga dos gemelos en el mismo local, ni que uno
-- del local venga de dos de bodega. Si algo intentara colarse, se descarta en
-- vez de romper la corrida.
--
-- `creado_por` deja escrito CÓMO nació cada par. El día que uno esté mal, se
-- va a poder saber si lo propuso el informe o lo puso alguien a mano.
-- ================================================================
insert into public.producto_enlace (producto_bodega_id, sede, producto_sede_id, factor, creado_por)
select producto_bodega_id, sede, producto_sede_id, 1, 'informe de nombres exactos'
from public.gemelos_propuestos
on conflict do nothing;


-- ================================================================
-- BLOQUE 3 — COMPROBACIÓN
--
-- QUÉ VER: 144 de angamos, 148 de plaza, y "por_escribir" en 0 — porque la
-- vista ya no propone nada que no esté hecho.
-- ================================================================
select e.sede,
       count(*)                                                       as pares_escritos,
       (select count(*) from public.gemelos_propuestos g
         where g.sede = e.sede)                                       as por_escribir
from public.producto_enlace e
group by e.sede
order by e.sede;


-- ================================================================
-- BLOQUE 4 — CÓMO SE VUELVE ATRÁS  (no correr salvo que haga falta)
--
-- Borra TODOS los pares y deja la libreta como estaba. No toca ningún
-- producto: los enlaces son filas de una tabla aparte.
-- ================================================================
-- delete from public.producto_enlace;


-- ================================================================
-- BLOQUE 5 — el cuaderno. Correr SOLO si el bloque 3 dio los números.
-- ================================================================
-- insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
-- values ('2026-08-central-gemelos-escribir.sql', 'Jhon', 'lo corrió Jhon',
--         'Escribe los 292 pares bodega<->local de nombre exacto en producto_enlace. No toca productos.')
-- on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
