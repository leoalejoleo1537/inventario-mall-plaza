-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea una bodega NUEVA y limpia. NO toca la bodega vieja
--             ni una sola vez — ni un update, ni un delete.
--  QUÉ VER:   el bloque 1 es la vista previa; el 3 tiene que dar ~236.
-- ================================================================
--
-- POR QUÉ SE HACE ASÍ, en una frase: la bodega de hoy ES la Angamos vieja
-- renombrada en julio, y por eso las recetas, los repartos y el historial
-- de ventas apuntan a sus filas. Una sede nueva nace **sin una sola
-- herencia**: nada viejo la señala.
--
-- ⚠️ LA CLAVE INTERNA ES `central`, NO `bodega`. En pantalla igual va a
-- decir "Bodega". Esto no es un capricho: el lío empezó porque en julio la
-- palabra `angamos` pasó a significar otra cosa, y desde entonces hubo que
-- adivinar según la fecha. **Reciclar `bodega` sería repetir la causa.**
-- Una fila que diga `bodega` significa la vieja. Siempre. Sin excepción.
--
-- QUÉ SE COPIA: solo palabras — nombre, sección, mínimo y máximo.
-- QUÉ NO SE COPIA: el stock (nace en 0 y se cuenta), los 117 duplicados,
-- y por supuesto ningún enlace.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — VISTA PREVIA. No escribe nada.
--
-- Qué productos nacerían, ya sin duplicados. De 351 filas activas en la
-- bodega vieja tienen que quedar ~236.
--
-- La regla para elegir cuál de cada par se copia es la que ya revisaste:
--   1. el que su nombre calce exacto con el de una sede (así el enlace
--      con Plaza y Angamos funciona después)
--   2. si empatan, el que tenga más stock hoy (es el que se está usando)
--   3. si siguen empatados, el id más bajo
--
-- QUÉ VER: el total de abajo, y date una vuelta por la lista de secciones
-- del segundo resultado — si alguna no te gusta, se renombra desde la app
-- después, no hace falta tocarla acá.
-- ================================================================
with n as (
  select id, producto, rubro, stock_actual, stock_min, stock_max, perecedero, tipo,
         translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                   'áéíóúüñ', 'aeiouun') as clave
  from public.productos
  where sede = 'bodega' and activo = 'SÍ'
),
ordenado as (
  select n.*,
         row_number() over (
           partition by n.clave
           order by (exists (select 1 from public.productos s
                              where s.sede in ('plaza','angamos') and s.activo='SÍ'
                                and s.producto = n.producto)) desc,
                    coalesce(n.stock_actual,0) desc,
                    n.id asc) as puesto
  from n
)
select count(*) filter (where puesto = 1) as naceran,
       count(*) filter (where puesto > 1) as duplicados_que_no_se_copian,
       count(*)                           as filas_en_la_bodega_vieja
from ordenado;

-- las secciones con las que nacería
with n as (
  select rubro,
         translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                   'áéíóúüñ', 'aeiouun') as clave,
         id, producto, stock_actual
  from public.productos where sede = 'bodega' and activo = 'SÍ'
),
ordenado as (
  select n.*, row_number() over (partition by n.clave
           order by (exists (select 1 from public.productos s
                              where s.sede in ('plaza','angamos') and s.activo='SÍ'
                                and s.producto = n.producto)) desc,
                    coalesce(n.stock_actual,0) desc, n.id asc) as puesto
  from n
)
select coalesce(rubro,'(sin sección)') as seccion, count(*) as productos
from ordenado where puesto = 1
group by 1 order by 2 desc;


-- ================================================================
-- BLOQUE 2 — CREARLA
--
-- Se puede correr dos veces sin duplicar: si el producto ya existe en
-- `central`, no lo vuelve a crear.
--
-- ⚠️ Este bloque SOLO INSERTA filas nuevas con sede='central'.
-- No hay ningún `update` ni `delete` sobre la bodega vieja.
-- ================================================================
with n as (
  select id, producto, rubro, stock_min, stock_max, perecedero, tipo, stock_actual,
         translate(lower(regexp_replace(trim(coalesce(producto,'')), '\s+', ' ', 'g')),
                   'áéíóúüñ', 'aeiouun') as clave
  from public.productos
  where sede = 'bodega' and activo = 'SÍ'
),
ordenado as (
  select n.*, row_number() over (partition by n.clave
           order by (exists (select 1 from public.productos s
                              where s.sede in ('plaza','angamos') and s.activo='SÍ'
                                and s.producto = n.producto)) desc,
                    coalesce(n.stock_actual,0) desc, n.id asc) as puesto
  from n
)
insert into public.productos
  (sede, producto, rubro, stock_actual, stock_min, stock_max, activo, perecedero, tipo)
select 'central', o.producto, o.rubro, 0, o.stock_min, o.stock_max, 'SÍ', o.perecedero, o.tipo
from ordenado o
where o.puesto = 1
  -- la comprobación de existencia NO filtra por activo, a propósito:
  -- si alguien ya lo desactivó en `central`, fue a propósito y no se
  -- vuelve a crear. Es la regla 0.6.3.
  and not exists (
    select 1 from public.productos c
     where c.sede = 'central'
       and translate(lower(regexp_replace(trim(coalesce(c.producto,'')), '\s+',' ','g')),'áéíóúüñ','aeiouun')
         = o.clave);


-- ================================================================
-- BLOQUE 3 — COMPROBACIÓN
--
-- Tiene que decir ~236 productos, todos en 0, y la bodega vieja
-- exactamente igual que antes: 351 activos.
-- ================================================================
select sede,
       count(*) filter (where activo='SÍ')                            as activos,
       count(*) filter (where activo='SÍ' and coalesce(stock_actual,0) > 0) as con_stock,
       count(distinct rubro) filter (where activo='SÍ')                as secciones
from public.productos
where sede in ('central','bodega')
group by sede order by sede;


-- ================================================================
-- LO QUE SIGUE, y es lo más importante de todo:
--
-- 1. Entrar a la app, elegir Bodega, y CONTAR.
-- 2. Apenas esté contada, apretar **"Guardar inventario de hoy"**.
--    Esa es la foto que hoy faltó. Desde ese momento la sede tiene red.
--
-- SI HAY QUE VOLVER ATRÁS: como solo se insertaron filas nuevas, deshacer
-- es una línea y no toca nada más:
--   delete from public.productos where sede = 'central';
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-bodega-nueva-desde-cero.sql', 'Jhon', 'lo corrió Jhon',
        'Crea la sede central (la bodega nueva) con ~236 productos depurados, stock 0. NO toca la bodega vieja: solo inserta filas nuevas.')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
