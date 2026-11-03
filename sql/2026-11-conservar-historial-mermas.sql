-- ================================================================
-- Conserva las mermas como libro histórico permanente.
--
-- La limpieza nocturna sigue quitando los movimientos operativos
-- transitorios después de 30 días, pero deja intacta cada fila cuyo
-- tipo es `merma`. Una merma ocupa muy poco y es el dato fuente de
-- los análisis por producto, sede y vencimiento.
-- ================================================================

-- Las dos consultas que alimentan la pantalla histórica: una para el
-- consolidado de Bodega y otra filtrada por sede en cada local.
create index if not exists movimientos_merma_created_at_idx
  on public.movimientos (created_at desc)
  where tipo = 'merma';

create index if not exists movimientos_merma_sede_created_at_idx
  on public.movimientos (sede, created_at desc)
  where tipo = 'merma';

-- El trabajo conserva el mismo horario y las mismas limpiezas de
-- historial, fotos automáticas y empujes. La única diferencia es que
-- ya no borra el libro de mermas.
select cron.alter_job(
  job_id := (select jobid from cron.job where jobname = 'limpieza-diaria'),
  command := $limpieza$
    with borra_hist as (
      delete from public.historial h
      using public.dias_de_historial d
      where d.sede = h.sede
        and d.fecha = h.fecha
        and d.puesto > 5
        and h.fecha < (current_date - 30)
      returning 1
    ), borra_auto as (
      delete from public.historial_auto a
      using public.dias_de_historial_auto d
      where d.sede = a.sede
        and d.fecha = a.fecha
        and d.puesto > 5
        and a.fecha < (current_date - 30)
      returning 1
    ), borra_mov as (
      delete from public.movimientos
      where tipo is distinct from 'merma'
        and created_at < (now() - interval '30 days')
      returning 1
    ), borra_push as (
      delete from public.fudo_stock_push
      where created_at < (now() - interval '2 days')
      returning 1
    )
    insert into public.limpiezas (historial, auto, movimientos, empujes)
    select (select count(*) from borra_hist),
           (select count(*) from borra_auto),
           (select count(*) from borra_mov),
           (select count(*) from borra_push);
  $limpieza$
);

insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values (
  '2026-11-conservar-historial-mermas.sql',
  'Codex',
  'Aplicado desde el repositorio',
  'La limpieza diaria conserva indefinidamente las filas de movimientos tipo merma.'
)
on conflict (archivo) do update
  set aplicado_at = now(), nota = excluded.nota;

-- Verificación esperada: la tarea sigue activa y su comando dice
-- `tipo is distinct from ''merma''`.
select jobid, jobname, schedule, active, command
from cron.job
where jobname = 'limpieza-diaria';
