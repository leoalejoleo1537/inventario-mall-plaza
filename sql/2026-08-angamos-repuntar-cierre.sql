-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  cierra los 9 renglones que quedaron del repunte anterior.
--             El bloque 1 NO toca nada.
--  QUÉ VER:   el bloque 4 tiene que dar CERO.
-- ================================================================
--
-- POR QUÉ FALTARON ESTOS 9, y el error es mío: la vista previa y el repunte
-- del script anterior solo miraban productos ACTIVOS. Estos 6 productos de
-- bodega están apagados, así que la vista previa ni los mostró — y la
-- comprobación, que no filtraba por activo, sí los encontró.
--
-- La lección, escrita para no repetirla: **si la vista previa y la
-- comprobación no usan el mismo filtro, la vista previa miente por omisión.**
-- Acá los dos bloques miran exactamente lo mismo.
--
-- ⚠️ Y no era inofensivo: una receta que apunta a un producto apagado igual
-- lo descuenta, porque el motor tampoco filtra por activo.
--
-- QUÉ SE HACE CON CADA UNO:
--   Bebida Fanta normal (717) → Unidad fanta (746)
--   Brownie solo (526)        → Brownie Vitrina (905)
--   Bolsas craf M (721)       → Bolsa kraft m (827)   "craf" es "kraft"
--   Unidad ginger ale (539)   → Ginger ale (1009)
--   Soda (533)                → ❌ se borra la línea · insumo interno
--   Bidón de Agua (719)       → ❌ se borra la línea · insumo interno
-- ================================================================


-- ================================================================
-- BLOQUE 1 — VISTA PREVIA. No cambia nada.
--
-- Esta vez SIN filtrar por activo, que es lo que faltaba.
-- QUÉ VER: que salgan 9 filas y que "que_haria" diga lo que esperas.
-- ================================================================
select r.fudo_product_nombre as se_vende_en_fudo,
       b.id                  as id_bodega,
       b.producto            as apunta_hoy_a,
       b.activo              as bodega_activo,
       case b.id when 717 then 746 when 526 then 905
                 when 721 then 827 when 539 then 1009 end as pasaria_a_id,
       (select p.producto from public.productos p
         where p.id = case b.id when 717 then 746 when 526 then 905
                                when 721 then 827 when 539 then 1009 end) as pasaria_a,
       case when b.id in (533, 719) then '❌ borrar la línea · insumo interno'
            else 'repuntar' end as que_haria
from public.receta_items ri
join public.recetas   r on r.id = ri.receta_id
join public.productos b on b.id = ri.producto_id
where r.sede = 'angamos' and r.activo and b.sede = 'bodega'
order by que_haria, b.producto, r.fudo_product_nombre;


-- ================================================================
-- BLOQUE 2 — EL RESPALDO (una tabla nueva, vacía)
--
-- El respaldo anterior solo guardaba a dónde apuntaba cada línea, y eso
-- NO alcanza para deshacer un borrado. Este guarda la fila entera.
-- ================================================================
create table if not exists public.receta_items_borradas_20260809 (
  item_id     bigint primary key,
  receta_id   bigint not null,
  producto_id bigint not null,
  cantidad    numeric,
  aplica      text,
  guardado_at timestamptz not null default now()
);

create table if not exists public.recetas_borradas_20260809 (
  receta_id           bigint primary key,
  sede                text,
  fudo_product_id     text,
  fudo_product_nombre text,
  guardado_at         timestamptz not null default now()
);

select 'respaldos listos' as estado;


-- ================================================================
-- BLOQUE 3 — REPUNTAR LOS 7 Y BORRAR LOS 2
--
-- Primero guarda, después toca. Igual que el script anterior.
-- ================================================================

-- 3.1 · guardar las 2 líneas que se van a borrar
insert into public.receta_items_borradas_20260809 (item_id, receta_id, producto_id, cantidad, aplica)
select ri.id, ri.receta_id, ri.producto_id, ri.cantidad, ri.aplica
from public.receta_items ri
join public.recetas r on r.id = ri.receta_id
where r.sede = 'angamos' and r.activo and ri.producto_id in (533, 719)
on conflict (item_id) do nothing;

-- 3.2 · repuntar los 7 con destino
update public.receta_items ri
   set producto_id = case ri.producto_id
                       when 717 then 746 when 526 then 905
                       when 721 then 827 when 539 then 1009 end
from public.recetas r
where r.id = ri.receta_id
  and r.sede = 'angamos' and r.activo
  and ri.producto_id in (717, 526, 721, 539)
  -- si la receta ya tiene ese insumo, no se puede duplicar
  and not exists (
    select 1 from public.receta_items x
     where x.receta_id = ri.receta_id
       and x.producto_id = case ri.producto_id
                             when 717 then 746 when 526 then 905
                             when 721 then 827 when 539 then 1009 end);

-- 3.3 · borrar las 2 líneas de insumos internos
delete from public.receta_items ri
using public.recetas r
where r.id = ri.receta_id
  and r.sede = 'angamos' and r.activo
  and ri.producto_id in (533, 719);

-- 3.4 · guardar y borrar las recetas que quedaron SIN ningún insumo.
-- Una receta sin insumos no descuenta nada pero cuenta como "resuelta" en la
-- portada. Al borrarla, el producto vuelve a aparecer como pendiente y Jhon
-- puede marcarlo "no lleva receta · insumo interno" desde la app.
insert into public.recetas_borradas_20260809 (receta_id, sede, fudo_product_id, fudo_product_nombre)
select r.id, r.sede, r.fudo_product_id, r.fudo_product_nombre
from public.recetas r
where r.sede = 'angamos' and r.activo
  and not exists (select 1 from public.receta_items x where x.receta_id = r.id)
on conflict (receta_id) do nothing;

delete from public.recetas r
where r.sede = 'angamos' and r.activo
  and not exists (select 1 from public.receta_items x where x.receta_id = r.id);

-- comprobación de este bloque: exactamente lo que acaba de pasar
select (select count(*) from public.receta_items_borradas_20260809) as lineas_borradas,
       (select count(*) from public.recetas_borradas_20260809)      as recetas_vacias_borradas,
       (select string_agg(fudo_product_nombre, ' · ')
          from public.recetas_borradas_20260809)                    as cuales_recetas;


-- ================================================================
-- BLOQUE 4 — LA COMPROBACIÓN. Tiene que dar CERO.
--
-- Misma consulta que la vista previa del bloque 1, sin filtrar por activo.
-- ================================================================
select count(*) as siguen_apuntando_a_bodega
from public.receta_items ri
join public.recetas   r on r.id = ri.receta_id
join public.productos b on b.id = ri.producto_id
where r.sede = 'angamos' and r.activo and b.sede = 'bodega';

-- y el estado general de las recetas de Angamos, para cerrar tranquilo
select count(distinct r.id)          as recetas_de_angamos,
       count(ri.id)                  as renglones,
       count(*) filter (where p.sede = 'angamos') as renglones_ok
from public.recetas r
left join public.receta_items ri on ri.receta_id = r.id
left join public.productos    p  on p.id = ri.producto_id
where r.sede = 'angamos' and r.activo;


-- ================================================================
-- SI HAY QUE VOLVER ATRÁS (no correr salvo que haga falta)
--
-- insert into public.recetas (id, sede, fudo_product_id, fudo_product_nombre, activo)
-- select receta_id, sede, fudo_product_id, fudo_product_nombre, true
-- from public.recetas_borradas_20260809 on conflict (id) do nothing;
--
-- insert into public.receta_items (id, receta_id, producto_id, cantidad, aplica)
-- select item_id, receta_id, producto_id, cantidad, aplica
-- from public.receta_items_borradas_20260809 on conflict (id) do nothing;
--
-- update public.receta_items ri set producto_id = s.producto_id_antes
-- from public.receta_items_respaldo_20260809 s where ri.id = s.item_id;
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-repuntar-cierre.sql', 'Jhon', 'lo corrió Jhon',
        'Cierra los 9 renglones que el repunte anterior no vio porque su vista previa filtraba por activo y los productos de bodega estaban apagados')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
