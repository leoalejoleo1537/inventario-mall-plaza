-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  el bloque 1 solo MIRA si llegó el catálogo de Fudo
--             Angamos. El bloque 2 SÍ ESCRIBE: pone Angamos en
--             modo 'real'. No toca productos, ni recetas, ni stock.
--  QUÉ VER:   bloque 1 -> la columna "veredicto".
--             bloque 2 -> la columna "modo" tiene que decir 'real'.
-- ================================================================
--
-- POR QUÉ EXISTE: creaste las credenciales de Fudo Angamos y apretaste ⟳.
-- El ⟳ NO trae recetas — trae el catálogo de productos de Fudo. Esto
-- comprueba si ese catálogo de verdad llegó.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ¿LLEGÓ EL CATÁLOGO DE FUDO ANGAMOS?
--
-- SOLO LECTURA. No escribe nada.
--
-- QUÉ VER: la fila de 'angamos'.
--   · Si "productos_de_fudo" es 0  ->  las credenciales no funcionaron.
--   · Si trae cientos              ->  la conexión con Fudo Angamos anda.
--
-- La columna "traido_hace" dice cuánto rato pasó desde que se bajó. Si
-- dice algo de hace minutos, es el ⟳ que apretaste tú.
-- ================================================================
select sede,
       count(*)                                   as productos_de_fudo,
       count(*) filter (where activo)             as activos,
       max(synced_at)                             as ultima_bajada,
       case when max(synced_at) is null then '—'
            else (extract(epoch from (now() - max(synced_at)))/60)::int || ' min'
       end                                        as traido_hace,
       case when count(*) = 0
              then '🔴 no llegó nada — revisar credenciales'
            when count(*) > 0
              then '✅ el catálogo está'
       end                                        as veredicto
from public.fudo_productos
group by sede
order by sede;


-- ================================================================
-- BLOQUE 2 — PONER ANGAMOS EN MODO REAL
--
-- ⚠️ ESTE SÍ ESCRIBE, pero solo una fila de configuración.
--
-- Sirva o no exista todavía la ficha de Angamos, esta línea la deja
-- bien: si no está, la crea; si está, le cambia el modo.
--
-- QUÉ SIGNIFICA 'real': el motor descuenta el stock de verdad al leer
-- una venta. En 'prueba' solo anota y no toca nada.
--
-- OJO, y es honesto decirlo: HOY esto no cambia nada en la práctica,
-- porque Angamos tiene 0 recetas y sin receta no hay qué descontar. El
-- modo empieza a importar el día que se creen las 168 recetas de una
-- vez — ahí un emparejamiento equivocado baja stock al toque.
-- ================================================================
insert into public.fudo_sync (sede, modo, cron_activo)
values ('angamos', 'real', false)
on conflict (sede) do update set modo = 'real';


-- ---------- comprobación ----------
-- Las dos sedes tienen que decir 'real'.
select sede,
       modo,
       cron_activo,
       ultima_corrida_at as ultima_vez_que_leyo_ventas,
       case when modo = 'real' then '✅ descuenta de verdad'
            else '🟡 sigue en prueba' end as veredicto
from public.fudo_sync
order by sede;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-catalogo-y-modo-real.sql', 'Jhon', 'lo corrió Jhon',
        'Comprobó el catálogo de Fudo Angamos y dejó la sede en modo real por decisión de Jhon')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
