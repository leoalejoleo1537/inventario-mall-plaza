-- ================================================================
-- ETAPA 3 — EL CUADERNO DE LO QUE YA SE CORRIÓ
--
-- Es como la cartilla de vacunas de un niño: una hoja donde queda
-- anotado qué se le puso y cuándo. Sin esa hoja uno termina o poniendo
-- la misma vacuna dos veces, o creyendo que ya se la pusieron cuando no.
--
-- Eso último es lo que nos pasó tres veces:
--   · las 15 horas sin descontar
--   · el cálculo viejo que quedó activo
--   · producto_lotes sin publicar (encontrado hoy)
-- Las tres fueron "creíamos que ese archivo ya se había corrido".
--
-- Este bloque CREA una tabla nueva y vacía. No toca ni un dato del
-- inventario. Correrlo dos veces no hace nada malo.
-- ================================================================

create table if not exists public.migraciones_aplicadas(
  archivo      text primary key,
  aplicado_at  timestamptz not null default now(),
  quien        text,
  como_se_supo text,
  nota         text
);

alter table public.migraciones_aplicadas enable row level security;

drop policy if exists "migraciones read" on public.migraciones_aplicadas;
create policy "migraciones read" on public.migraciones_aplicadas
  for select to anon, authenticated using (true);

grant select on public.migraciones_aplicadas to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — ANOTAR LO QUE YA SABEMOS, Y SOLO ESO
--
-- Acá NO se anota lo que "debería" haberse corrido. Se anota lo que el
-- chequeo de salud del 30 de julio COMPROBÓ que está en la base, más lo
-- que corriste tú con tus propias manos.
--
-- Siguiendo la metáfora de la cartilla: no se anota una vacuna porque
-- estaba en el calendario, se anota porque se ve la marca en el brazo.
--
-- Cada línea dice CÓMO se supo. Los archivos que no aparecen acá siguen
-- siendo un "no sabemos" — y eso es honesto, no un olvido.
-- ================================================================
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota) values
 ('2026-07-fase1-recetas-modo-prueba.sql','Jhon','chequeo 30-07: las tablas existen','Creó fudo_sync y fudo_movimientos'),
 ('2026-07-lotes-vencimiento.sql',        'Jhon','chequeo 30-07: la tabla existe','Creó producto_lotes'),
 ('2026-07-repartos.sql',                 'Jhon','chequeo 30-07: tablas existen y publicadas','Creó repartos y reparto_items'),
 ('2026-07-productos-urgentes.sql',       'Jhon','chequeo 30-07 bloque 4','Agregó productos.urgente'),
 ('2026-07-tipo-de-producto.sql',         'Jhon','chequeo 30-07 bloque 4','Agregó productos.tipo'),
 ('2026-07-URGENTE-falta-venta-at.sql',   'Jhon','chequeo 30-07 bloque 4','Agregó fudo_movimientos.venta_at'),
 ('2026-07-permisos-y-deshacer.sql',      'Jhon','chequeo 30-07 bloque 4','Agregó fudo_stock_push.lote y app_permisos'),
 ('2026-07-historial-dias.sql',           'Jhon','chequeo 30-07: la función está instalada','Arregló el historial que mostraba días viejos'),
 ('2026-07-stock-para-fudo-v3-suma-el-par.sql','Jhon','Jhon lo corrió y el alfajor pasó a 17','Fudo recibe la suma vitrina+congelador'),
 ('2026-07-salud-del-sistema.sql',        'Jhon','Jhon lo corrió el 30-07','Solo lectura. Se repite una vez al mes'),
 ('2026-07-respaldo-para-guardar.sql',    'Jhon','Jhon lo corrió el 30-07','Solo lectura. Los CSV quedaron guardados'),
 ('2026-07-fechas-en-vivo-y-limpieza.sql','Jhon','Jhon publicó producto_lotes el 30-07','⚠️ Estuvo SIN correr semanas creyendo que sí. Es el caso que motivó este cuaderno')
on conflict (archivo) do update
  set aplicado_at = now(), quien = excluded.quien,
      como_se_supo = excluded.como_se_supo, nota = excluded.nota;


-- ================================================================
-- BLOQUE 3 — LA LÍNEA QUE VA AL FINAL DE CADA SCRIPT DE AHORA EN MÁS
--
-- Esto NO se corre ahora. Es el molde. De aquí en adelante, todo script
-- que Claude te entregue va a traer estas líneas pegadas al final, ya
-- rellenadas. Así el cuaderno se escribe SOLO cuando aprietas Run, y no
-- depende de que alguien se acuerde de anotarlo.
--
-- Es la misma idea que el tope de stock en cero: no se resolvió pidiendo
-- que la gente se acordara, se resolvió poniendo el candado en la base.
--
-- insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
-- values ('nombre-del-archivo.sql', 'Jhon', 'lo corrió Jhon', 'qué hace en una línea')
-- on conflict (archivo) do update
--   set aplicado_at = now(), nota = excluded.nota;
-- ================================================================


-- ---------- registro de este mismo archivo ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-07-registro-de-migraciones.sql', 'Jhon', 'lo corrió Jhon',
        'Creó el cuaderno de migraciones y anotó lo verificado el 30-07')
on conflict (archivo) do update
  set aplicado_at = now(), nota = excluded.nota;


-- ================================================================
-- BLOQUE 4 — CÓMO QUEDÓ EL CUADERNO
--
-- Va al FINAL a propósito: el editor de Supabase muestra el resultado
-- de la ÚLTIMA consulta, así que si esto va antes del registro de más
-- arriba, la foto sale con una fila de menos y confunde.
--
-- Tienen que salir 13 filas.
-- ================================================================
select archivo, aplicado_at::date as se_corrio_el, quien, como_se_supo, nota
from public.migraciones_aplicadas
order by aplicado_at desc, archivo;
