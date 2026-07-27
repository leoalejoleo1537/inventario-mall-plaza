-- ================================================================
-- PRODUCTOS URGENTES (julio 2026)
--
-- Hay productos que se están acabando y hay que avisarle a Adriana YA,
-- aunque el semáforo no los marque como críticos (ej.: quedan 3 pero se
-- van a acabar hoy). El personal los marca a mano desde la ficha del
-- producto y aparecen agrupados en la tarjeta "Urgente" del inventario.
--
-- Es una marca MANUAL: no la calcula el sistema, no la borra la sync de
-- Fudo, y convive con crítico / sobre-stock / sin dato (un producto puede
-- estar crítico y urgente a la vez). Se quita tocando el mismo botón.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Es idempotente. Para revertir: alter table public.productos drop column urgente;
-- ================================================================

alter table public.productos
  add column if not exists urgente boolean not null default false;

-- ---------- Comprobación: la columna quedó, y nadie está marcado todavía ----------
select count(*) filter (where urgente) as marcados_urgentes,
       count(*)                        as productos_activos
from public.productos
where activo = 'SÍ';
