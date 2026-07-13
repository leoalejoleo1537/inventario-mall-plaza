-- ================================================================
-- Replica en ANGAMOS la clasificación por secciones que se dejó
-- lista a mano en MALL PLAZA (julio 2026).
--
-- Para cada producto de angamos, busca el producto con el mismo
-- nombre en plaza (ignorando mayúsculas, tildes y espacios dobles)
-- y le copia su sección. Bodega no se toca. Los productos que solo
-- existen en angamos conservan su sección actual.
-- ================================================================
update public.productos a
set rubro = p.rubro
from public.productos p
where a.sede='angamos' and p.sede='plaza'
  and translate(lower(regexp_replace(trim(a.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
    = translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu');

-- Comprobación: productos de angamos que NO encontraron pareja en
-- plaza (quedaron con su sección anterior). Si aparece alguno mal
-- clasificado, se corrige desde la app con el selector de sección.
select a.producto, a.rubro as seccion_actual
from public.productos a
where a.sede='angamos' and a.activo='SÍ'
  and not exists (
    select 1 from public.productos p
    where p.sede='plaza'
      and translate(lower(regexp_replace(trim(a.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
        = translate(lower(regexp_replace(trim(p.producto),'\s+',' ','g')),'áéíóúñü','aeiounu')
  )
order by a.producto;
