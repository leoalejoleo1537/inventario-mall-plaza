-- ================================================================
-- DIAGNÓSTICO — por qué no se guardan las fechas de vencimiento
--
-- SOLO LECTURA: no crea, no borra, no modifica nada. Se puede correr
-- las veces que quieras. Busca "Croissant jamón queso" pero sirve para
-- cualquier producto — cambia el texto de la línea marcada más abajo.
--
-- Cómo correrlo: Supabase -> SQL Editor -> pegar todo -> Run.
-- Manda los 4 resultados (bloques 1 a 4) para poder diagnosticar.
-- ================================================================

-- ---------- BLOQUE 1: ¿existe la tabla, y con qué columnas? ----------
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema='public' and table_name='producto_lotes'
order by ordinal_position;

-- ---------- BLOQUE 2: políticas de seguridad (RLS) reales ----------
-- Debe aparecer "producto_lotes all" con roles {anon,authenticated},
-- cmd "ALL", qual "true" y with_check "true". Si aparece OTRA cosa, o
-- si sale vacío (0 filas), ahí está el problema.
select schemaname, tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname='public' and tablename='producto_lotes';

-- ¿RLS está siquiera activado? (debe decir true)
select relrowsecurity from pg_class where relname='producto_lotes';

-- ---------- BLOQUE 3: permisos de tabla otorgados ----------
select grantee, privilege_type
from information_schema.role_table_grants
where table_schema='public' and table_name='producto_lotes'
order by grantee, privilege_type;

-- ---------- BLOQUE 4: el producto puntual y sus lotes reales ----------
-- Cambia 'croissant' por otra palabra si buscas otro producto.
select p.id as producto_id, p.sede, p.producto, p.rubro, p.perecedero,
       p.stock_actual, p.vencimiento as fecha_unica_antigua, p.updated_at
from public.productos p
where p.activo='SÍ'
  and translate(lower(p.producto),'áéíóúñü','aeiounu') like '%croissant%jamon%queso%'
order by p.producto;

select l.id, l.producto_id, l.cantidad, l.vencimiento, l.created_at, l.updated_at
from public.producto_lotes l
join public.productos p on p.id = l.producto_id
where translate(lower(p.producto),'áéíóúñü','aeiounu') like '%croissant%jamon%queso%'
order by l.producto_id, l.vencimiento;

-- ---------- BLOQUE 5 (extra): ¿la tabla está en la publicación de Realtime? ----------
-- No debería ser la causa (un refresco manual no depende de esto),
-- pero sirve para descartarlo.
select schemaname, tablename
from pg_publication_tables
where pubname = 'supabase_realtime' and tablename = 'producto_lotes';
