-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Corre UNO, mándame el resultado, después el otro.
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA. Solo mira. No borra, no escribe, no toca ningún stock.
--  QUÉ VER:   el bloque 2 es el importante: dice si la tarea corrió y con
--             qué error. Ahí está la respuesta.
-- ================================================================
--
-- QUÉ PASÓ
--
-- La pestaña Historial de Mall Plaza muestra días seguidos hasta el
-- 25-08-2026 y después nada. Hoy es 28. O sea que la foto automática dejó
-- de guardarse en algún momento entre el 25 y el 26.
--
-- POR QUÉ NO TE MANDO UN ARREGLO DIRECTO
--
-- Porque todavía no sé qué falló, y hay tres causas posibles que se
-- arreglan de maneras distintas:
--
--   a) la tarea se borró o se apagó         -> se vuelve a agendar
--   b) la tarea corre pero revienta         -> hay que arreglar qué la revienta
--   c) la tarea ni siquiera está intentando -> pg_cron dejó de funcionar
--
-- Si adivino y le pego a la equivocada, quedamos igual pero creyendo que
-- está arreglado — que es peor. Es la lección del 9 de agosto: primero se
-- mira, después se escribe.
--
-- LO PRIMERO, Y NO NECESITA ESTO: apretá "Guardar inventario de hoy" en
-- cada sede ahora mismo. Eso guarda la foto del 28 a mano, sin depender de
-- que arreglemos nada. Los días 26 y 27 ya no se pueden recuperar — el
-- stock de esos días no quedó escrito en ninguna parte.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — ¿LA TAREA SIGUE AGENDADA?
--
-- QUÉ VER: tendrían que salir DOS filas, foto-inventario-tarde y
-- foto-inventario-noche, las dos con activa = true.
--   · si no sale ninguna  -> la tarea desapareció (causa a)
--   · si salen con activa = false -> alguien la apagó (causa a)
--   · si salen las dos en true -> está agendada y falla al correr, andá
--     al bloque 2
-- ================================================================
select jobname   as tarea,
       schedule  as horario_utc,
       active    as activa
  from cron.job
 order by jobname;


-- ================================================================
-- BLOQUE 2 — EL BLOQUE IMPORTANTE: ¿CORRIÓ, Y CÓMO LE FUE?
--
-- Postgres anota cada vez que una tarea corre y qué contestó. Esto es la
-- fuente de verdad, no una suposición.
--
-- QUÉ VER: las últimas 25 corridas, de la más nueva a la más vieja.
--   · columna "resultado": succeeded = salió bien · failed = reventó
--   · columna "mensaje": si dice failed, ACÁ está el motivo. Mándamelo
--     entero, aunque parezca ruido.
--   · si la fila más nueva es del 25 y no hay nada después, la tarea
--     dejó de intentarlo (causa c) y no es un error de nuestro SQL.
-- ================================================================
select j.jobname                                   as tarea,
       d.start_time at time zone 'America/Santiago' as cuando_hora_chile,
       d.status                                     as resultado,
       left(coalesce(d.return_message,''), 200)     as mensaje
  from cron.job_run_details d
  join cron.job j on j.jobid = d.jobid
 order by d.start_time desc
 limit 25;


-- ================================================================
-- BLOQUE 3 — QUÉ HAY GUARDADO DE VERDAD, POR SEDE
--
-- Para saber si el hueco es solo de Mall Plaza o de todas, y si la otra
-- red —la tabla del respaldo automático— también se cortó el mismo día.
--
-- QUÉ VER: una fila por sede y día, de la más nueva para atrás.
--   · si "foto_manual" y "respaldo_auto" se cortan el MISMO día, fue la
--     tarea: es una sola instrucción y escribe en las dos.
--   · si el respaldo siguió y la manual no, el problema es solo del
--     pedazo que escribe en historial.
-- ================================================================
select coalesce(h.sede, a.sede)   as sede,
       coalesce(h.fecha, a.fecha)  as dia,
       h.productos                 as foto_manual,
       a.productos                 as respaldo_auto
  from (select sede, fecha, count(*) as productos
          from public.historial
         where fecha > (current_date - 12)
         group by sede, fecha) h
  full join (select sede, fecha, count(*) as productos
               from public.historial_auto
              where fecha > (current_date - 12)
              group by sede, fecha) a
    on a.sede = h.sede and a.fecha = h.fecha
 order by 2 desc, 1;
