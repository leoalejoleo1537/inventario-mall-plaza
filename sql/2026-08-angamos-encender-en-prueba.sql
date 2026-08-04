-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque. Copiar TODO, pegar, apretar Run.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea la ficha de Angamos en MODO PRUEBA. SÍ escribe,
--             pero solo una fila de configuración: no toca productos,
--             ni recetas, ni stock.
--  QUÉ VER:   la columna "modo" TIENE que decir 'prueba'.
-- ================================================================
--
-- QUÉ ES EL MODO PRUEBA, con una imagen: es el motor girando en punto
-- muerto. Lee todas las ventas de Fudo y las anota, pero NO toca el
-- stock. Así podemos mirar qué habría descontado antes de dejar que
-- descuente de verdad.
--
-- ⚠️ ESTO VA ANTES de traer el catálogo de Fudo. Si Angamos no tiene
-- ficha, el motor asume 'prueba' igual — pero prefiero que esté escrito
-- y no que dependa de un valor por omisión.
--
-- El paso a 'real' lo decides tú, más adelante, cuando los números de
-- unos días cuadren. No se hace hoy.
-- ================================================================

insert into public.fudo_sync (sede, modo, cron_activo)
values ('angamos', 'prueba', false)
on conflict (sede) do nothing;


-- ---------- comprobación: mirar la fila de angamos ----------
-- 'modo' debe decir 'prueba' y 'cron_activo' debe decir false.
-- Si dijera 'real', AVISAR antes de seguir: no lo cambio yo solo porque
-- el modo es una decisión operativa (regla 0.1.7).
select sede,
       modo,
       cron_activo,
       ultima_corrida_at as ultima_vez,
       -- El veredicto solo aplica a angamos: Plaza tiene que estar en 'real'
       -- y marcarla en rojo por eso sería una falsa alarma — de las que
       -- enseñan a ignorar el tablero.
       case when sede <> 'angamos'  then 'no aplica — esta sede ya está andando'
            when modo = 'prueba'    then '✅ listo para traer el catálogo'
            else '🔴 OJO: angamos no quedó en prueba — avisar' end as veredicto
from public.fudo_sync
order by sede;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-angamos-encender-en-prueba.sql', 'Jhon', 'lo corrió Jhon',
        'Creó la ficha de fudo_sync para angamos en modo prueba, antes de conectar Fudo')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
