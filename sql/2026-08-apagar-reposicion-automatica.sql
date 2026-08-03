-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  apaga el traslado automático de 4 unidades desde el
--             Congelador a la Vitrina. SÍ MODIFICA el sistema.
--  QUÉ VER:   el bloque 3 devuelve UNA fila; el bloque 4 confirma
--             que el traslado quedó apagado de verdad.
-- ================================================================
--
-- POR QUÉ SE APAGA (Jhon, 2026-08-01): "este parche está trayendo más
-- problemas que soluciones". El sistema movía producto en los números
-- sin que nadie lo hubiera movido en el mesón: la app decía que la
-- vitrina tenía 4 cuando el estante estaba vacío. Pasa a conteo manual
-- hasta que aparezca una forma mejor.
--
-- ⚠️ LO QUE **NO** SE TOCA:
--   · El tope en cero (regla 0.2). El stock sigue sin poder quedar
--     negativo — eso NO es parte del parche que se apaga.
--   · El motor de descuento `fudo_procesar_item`. No se toca ni se
--     reemplaza, así que no hay riesgo de dejar dos firmas conviviendo
--     (la falla del 2026-07-27). Solo cambia la función auxiliar, y
--     conserva su mismo nombre y sus mismos argumentos.
--   · El cálculo que se le manda a Fudo. Ese ya suma vitrina +
--     congelador por nombre base, así que sigue viendo el total real.
--
-- QUÉ VA A CAMBIAR EN LA PRÁCTICA: cuando la vitrina llegue a 0, se
-- queda en 0. El congelador conserva su stock. Alguien mueve el
-- producto de verdad y ajusta los números a mano. El "Total" de la app
-- sigue mostrando la suma de los dos, así que no se pierde de vista.
--
-- CÓMO SE VUELVE ATRÁS: correr de nuevo
-- `sql/2026-07-reposicion-congelador-y-tope-cero.sql`, que reinstala la
-- versión con traslado.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ANTES: qué hay instalado hoy
--
-- QUÉ VER: cuántas filas salen. Si sale más de una, avisar ANTES de
-- seguir: habría varias versiones conviviendo y el bloque 2 tiene que
-- borrarlas todas.
-- ================================================================
select p.oid::regprocedure as funcion_instalada
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'descontar_con_reposicion';


-- ================================================================
-- BLOQUE 2 — APAGAR EL TRASLADO
--
-- Se borran todas las firmas posibles antes de crear la nueva. Es la
-- lección de la falla del 2026-07-27: reemplazar sin borrar dejó dos
-- funciones del mismo nombre y la llamada por la API quedó ambigua.
-- ================================================================
drop function if exists public.descontar_con_reposicion(text, bigint, numeric);
drop function if exists public.descontar_con_reposicion(text, bigint, double precision);
drop function if exists public.descontar_con_reposicion(text, bigint);

create function public.descontar_con_reposicion(
  p_sede        text,
  p_producto_id bigint,
  p_cantidad    numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $q$
begin
  if p_cantidad is null or p_cantidad <= 0 then return; end if;

  -- El traslado automático de 4 unidades desde el Congelador se apagó el
  -- 2026-08-01 por decisión de Jhon: movía producto en los números sin que
  -- nadie lo hubiera movido en el mesón. Ahora se repone a mano.
  --
  -- La función conserva su nombre y sus argumentos a propósito: así el motor
  -- `fudo_procesar_item` la sigue llamando igual y no hay que tocarlo.

  -- Descuento, con el tope en cero INTACTO (regla 0.2): el stock nunca
  -- queda negativo, haya o no haya pareja en el congelador.
  update public.productos
     set stock_actual = greatest(0, coalesce(stock_actual,0) - p_cantidad),
         updated_at   = now()
   where id = p_producto_id;
end;
$q$;

grant execute on function public.descontar_con_reposicion(text, bigint, numeric)
  to anon, authenticated;


-- ================================================================
-- BLOQUE 3 — DESPUÉS: comprobar que quedó UNA sola
--
-- QUÉ VER: tiene que salir EXACTAMENTE UNA fila, y decir
-- `descontar_con_reposicion(text,bigint,numeric)`.
-- Si salen dos, avisar: la llamada por la API quedaría ambigua.
-- ================================================================
select p.oid::regprocedure as funcion_instalada,
       case when count(*) over () = 1
            then 'ok — una sola, el motor la puede llamar'
            else '🔴 HAY MÁS DE UNA — avisar antes de seguir' end as veredicto
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'descontar_con_reposicion';


-- ================================================================
-- BLOQUE 4 — LA COMPROBACIÓN QUE DE VERDAD IMPORTA
--
-- El bloque 3 solo dice CUÁNTAS funciones hay. Si el bloque 2 hubiera
-- fallado, el 3 mostraría exactamente lo mismo. Esto mira POR DENTRO
-- de la función instalada y confirma qué hace.
--
-- QUÉ VER: las dos primeras columnas tienen que decir ✅.
-- ================================================================
select case when pg_get_functiondef(p.oid) ilike '%v_trasladar%'
              or pg_get_functiondef(p.oid) ilike '%least(4%'
            then '🔴 TODAVIA REPONE — el bloque 2 no se aplico'
            else '✅ APAGADO — ya no traslada nada del congelador' end as traslado_automatico,
       case when pg_get_functiondef(p.oid) ilike '%greatest(0%'
            then '✅ el tope en cero sigue activo'
            else '🔴 OJO: no se ve el tope en cero' end as stock_negativo
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='descontar_con_reposicion';


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-apagar-reposicion-automatica.sql', 'Jhon', 'lo corrió Jhon',
        'Apagó el traslado automático de 4 unidades congelador->vitrina. El tope en cero sigue activo')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
