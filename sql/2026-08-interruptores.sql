-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr uno y después el otro.
--  TARDA:     instantáneo
--  QUÉ HACE:  crea la tabla donde viven los interruptores de Ajustes.
--             No enciende ni apaga nada: nace vacía y todo sigue igual.
--  QUÉ VER:   "Success", y al final una tabla con los valores por defecto.
-- ================================================================
--
-- POR QUÉ EXISTE (regla §2.2, tuya): "la gran mayoría de cosas deben
-- poder deshabilitarse sin romper nada". Hasta hoy cada interruptor era
-- una línea del código que solo yo podía cambiar — o sea, una dependencia
-- de mí metida en un sistema que tiene que poder funcionar sin mí.
--
-- CÓMO FUNCIONA: cada fila es un interruptor. Si la fila no está, manda
-- el valor por defecto que trae la app. Así, si esto no se corriera, la
-- app funciona exactamente como hoy — que es la prueba de que un
-- interruptor está bien hecho.
--
-- LA `sede` VACÍA quiere decir "para todas". Un interruptor por sede
-- lleva su nombre.
-- ================================================================

create table if not exists public.ajustes (
  clave       text not null,
  sede        text not null default '',
  valor       boolean not null,
  cambiado_at timestamptz not null default now(),
  cambiado_por text,
  primary key (clave, sede)
);

alter table public.ajustes enable row level security;
drop policy if exists "ajustes all" on public.ajustes;
create policy "ajustes all" on public.ajustes
  for all to anon, authenticated using (true) with check (true);
grant all on public.ajustes to anon, authenticated;

-- Los que ya existen hoy, con el valor que tienen hoy. Se siembran para
-- que la pantalla los muestre en su estado real desde el primer momento,
-- en vez de mostrarlos apagados y que alguien los "encienda" creyendo que
-- estaban apagados.
insert into public.ajustes (clave, sede, valor, cambiado_por) values
  ('ciclo_fudo',   'plaza',   true,  'instalación'),
  ('ciclo_fudo',   'angamos', true,  'instalación'),
  ('tareas_turno', 'angamos', true,  'instalación'),
  ('tareas_turno', 'plaza',   false, 'instalación'),
  ('tareas_turno', 'central', false, 'instalación'),
  ('marca_nuevo',  '',        true,  'instalación'),
  ('aviso_motor',  '',        true,  'instalación')
on conflict (clave, sede) do nothing;

select clave, sede, valor from public.ajustes order by clave, sede;


-- ================================================================
-- BLOQUE 2 — CUÁNTAS RECETAS APUNTAN AL VACÍO
--
-- Lo usa la pantalla de Salud. Una receta rota descuenta de un producto
-- que ya no está: es el chequeo que habría avisado del lío de Angamos
-- cuatro días antes de que alguien lo notara.
--
-- Va sin comillas de dólar a propósito (§3.5): el cuerpo es una sola
-- consulta entre comillas simples, así el editor no lo puede cortar.
-- ================================================================
create or replace function public.recetas_rotas()
returns integer
language sql
stable
as 'select count(*)::integer from public.receta_items ri
      left join public.productos p on p.id = ri.producto_id
     where p.id is null';

grant execute on function public.recetas_rotas() to anon, authenticated;

select public.recetas_rotas() as recetas_que_apuntan_al_vacio;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-interruptores.sql', 'Jhon', 'lo corrió Jhon',
        'Tabla ajustes: los interruptores de la app dejan de vivir en el código')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
