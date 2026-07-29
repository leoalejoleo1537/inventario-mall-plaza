-- ================================================================
-- REVISIÓN DE SEGURIDAD — ¿quién puede leer y escribir qué?
--
-- TODO DE SOLO LECTURA. No cambia ni un permiso.
--
-- Contexto para leer los resultados:
-- La app corre en el navegador con la clave PUBLICABLE, que va escrita
-- en index.html y cualquiera puede ver con F12. O sea: la clave NO es
-- un secreto. Lo único que decide qué puede hacer alguien con esa clave
-- son las políticas RLS de cada tabla.
--
-- Si una tabla tiene RLS apagado, o una política que deja escribir a
-- "anon", entonces cualquiera que abra la URL de la app puede modificar
-- esa tabla desde la consola del navegador.
--
-- Eso puede estar BIEN (es un inventario de café, no datos bancarios)
-- pero tiene que ser una decisión tomada, no un descuido.
-- ================================================================


-- ================================================================
-- 1) ¿QUÉ TABLAS TIENEN RLS ENCENDIDO?
--
-- rls_encendido = false  ->  la tabla está completamente abierta a
--                            cualquiera que tenga la clave publicable.
-- ================================================================
select c.relname                        as tabla,
       c.relrowsecurity                 as rls_encendido,
       (select count(*) from pg_policies p
         where p.schemaname='public' and p.tablename=c.relname) as politicas
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname='public' and c.relkind='r'
order by c.relrowsecurity, c.relname;


-- ================================================================
-- 2) ⚠️ LO QUE MÁS IMPORTA — quién puede ESCRIBIR
--
-- Cada fila acá es un permiso de escritura. Si aparece "anon" en la
-- columna "a_quien", esa operación la puede hacer CUALQUIERA que abra
-- la app, sin iniciar sesión.
-- ================================================================
select tablename                        as tabla,
       policyname                       as politica,
       cmd                              as operacion,
       array_to_string(roles,', ')      as a_quien,
       case when 'anon' = any(roles) then '⚠️ SIN SESIÓN' else 'con sesión' end as riesgo
from pg_policies
where schemaname='public'
  and cmd in ('INSERT','UPDATE','DELETE','ALL')
order by ('anon' = any(roles)) desc, tablename, cmd;


-- ================================================================
-- 3) Los permisos de tabla (GRANT), que van antes que RLS
--
-- Aunque RLS esté bien, un GRANT de más deja pasar. Acá se ve qué
-- puede hacer cada rol a nivel de tabla.
-- ================================================================
select table_name    as tabla,
       grantee       as rol,
       string_agg(privilege_type, ', ' order by privilege_type) as permisos
from information_schema.role_table_grants
where table_schema='public' and grantee in ('anon','authenticated')
group by table_name, grantee
order by table_name, grantee;


-- ================================================================
-- 4) Las funciones que corren con permisos elevados
--
-- security definer significa que la función corre con los permisos de
-- quien la creó, no de quien la llama — se salta RLS. Está bien para
-- lo que necesita hacerlo, pero conviene saber cuáles son.
-- ================================================================
select p.proname                     as funcion,
       case when p.prosecdef then 'SÍ (se salta RLS)' else 'no' end as security_definer,
       pg_get_function_identity_arguments(p.oid) as argumentos
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public'
  and p.proname not like 'pg_%'
order by p.prosecdef desc, p.proname;


-- ================================================================
-- 5) ¿Hay respaldos? (importante antes de manejar caja o crecer)
--
-- Esto solo dice qué plan de Supabase hay. Los respaldos diarios
-- necesitan plan Pro; en el gratuito no hay punto de restauración.
-- Se mira en el panel: Settings -> Database -> Backups.
-- Acá solo se deja el recordatorio.
-- ================================================================
select 'Revisar en el panel: Settings → Database → Backups' as recordatorio;
