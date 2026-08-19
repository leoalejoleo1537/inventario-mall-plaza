-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo
--  QUÉ HACE:  deja manejar desde Ajustes las secciones (crear, borrar,
--             reordenar, turno AM/PM), el modo prueba/real de cada sede,
--             el reloj, y la traducción de categorías de Fudo.
--  QUÉ VER:   el bloque 4 muestra las secciones que quedaron y el modo de
--             cada sede. Tiene que decir SÍ en las tres últimas columnas.
-- ================================================================
--
-- QUÉ ES ESTO, sin términos: hasta hoy el orden de las secciones y cuáles
-- se cuentan en la mañana estaban ESCRITOS DENTRO DEL CÓDIGO de la app.
-- Cambiar uno era pedírmelo a mí. Con esto pasan a ser una lista en la
-- base, que la pantalla de Ajustes puede editar.
--
-- LO IMPORTANTE, y es la red: la lista nace COPIADA de lo que hay hoy, y
-- si la tabla estuviera vacía la app usa el orden de siempre. O sea que en
-- el peor caso todo se ve exactamente igual que ahora.
--
-- ⚠️ HAY UN DETALLE QUE COSTÓ CARO ENTENDER, y por eso está escrito acá:
-- una tabla puede estar abierta para LEER y cerrada para ESCRIBIR, y
-- cuando está cerrada **no avisa** — contesta "listo" sin cambiar nada.
-- Fue lo que pasó con los permisos de Adriana y Massiel. Por eso cada
-- tabla de acá lleva sus dos permisos explícitos, y la app además pide de
-- vuelta lo que escribió para comprobarlo.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA TABLA DE SECCIONES
-- QUÉ VER: "Success". No devuelve filas.
-- ================================================================
create table if not exists public.secciones(
  sede    text not null,
  nombre  text not null,
  turno   text not null default 'pm',    -- 'am' = se cuenta en la mañana
  orden   integer not null default 100,  -- más chico, más arriba
  primary key (sede, nombre)
);

alter table public.secciones enable row level security;
drop policy if exists "secciones all" on public.secciones;
create policy "secciones all" on public.secciones
  for all to anon, authenticated using (true) with check (true);
grant select, insert, update, delete on public.secciones to anon, authenticated;

-- No se agrega a la publicación en vivo a propósito: las secciones se
-- cambian una vez cada mucho, la app las vuelve a leer al entrar y al
-- volver del fondo, y `alter publication` falla si ya estuviera agregada
-- —o sea que volver a correr este archivo daría error por algo que no
-- importa.


-- ================================================================
-- BLOQUE 2 — SEMBRARLA CON LO QUE YA HAY  (otro Run)
--
-- Va aparte porque usa la tabla del bloque 1: el editor de Supabase no ve
-- una tabla creada en la misma corrida.
--
-- El orden y el turno salen de la lista que hoy vive en el código. Lo que
-- no esté en esa lista queda al final y en el turno de la tarde, que es
-- exactamente como se comporta hoy.
--
-- QUÉ VER: "Success".
-- ================================================================
insert into public.secciones (sede, nombre, turno, orden)
select p.sede, p.rubro,
       case when translate(lower(p.rubro), 'áéíóúü', 'aeiouu') in
            ('limpieza','mesones','te','congelador','mueble de mezclas',
             'mueble de bolsas','mueble de caja')
            then 'am' else 'pm' end,
       coalesce(array_position(
         array['Vitrina de tortas','Limpieza','Sándwiches','Mesones','Congelador','Té',
               'Vitrina de dulces','Vitrina de bebidas','Mueble de mezclas',
               'Mueble de bolsas','Mueble de caja'], p.rubro), 100)
from (select distinct sede, rubro from public.productos
       where rubro is not null and rubro <> '') p
on conflict (sede, nombre) do nothing;


-- ================================================================
-- BLOQUE 3 — ABRIR FUDO Y LAS CATEGORÍAS  (otro Run)
--
-- `fudo_sync` guarda el modo (prueba/real) y si el reloj está encendido.
-- Estaba abierta solo para las visitas SIN sesión iniciada, así que al
-- tocar el interruptor desde tu cuenta —que sí tiene sesión— no pasaba
-- nada. Es la misma trampa de los permisos, en otra tabla.
--
-- QUÉ VER: "Success".
-- ================================================================
drop policy if exists "fudo_sync auth" on public.fudo_sync;
create policy "fudo_sync auth" on public.fudo_sync
  for all to authenticated using (true) with check (true);
grant select, insert, update on public.fudo_sync to authenticated;

drop policy if exists "fudo_categorias escribir" on public.fudo_categorias;
create policy "fudo_categorias escribir" on public.fudo_categorias
  for all to anon, authenticated using (true) with check (true);
grant select, insert, update on public.fudo_categorias to anon, authenticated;


-- ================================================================
-- BLOQUE 4 — COMPROBAR  (otro Run)
--
-- QUÉ VER: las secciones de cada sede, con su turno y su orden. Tienen que
-- estar TODAS las que ves hoy en el inventario.
--
-- ⚠️ UN RESULTADO POR RUN: el editor de Supabase muestra solo el de la
-- ÚLTIMA consulta, así que el modo de cada sede va en el bloque 5 aparte.
-- ================================================================
select sede, nombre, turno, orden,
       (select count(*) from public.productos p
         where p.sede = s.sede and p.rubro = s.nombre and p.activo = 'SÍ') as productos
from public.secciones s
order by sede, orden, nombre;


-- ================================================================
-- BLOQUE 5 — EL MODO Y EL RELOJ DE CADA SEDE  (otro Run)
--
-- QUÉ VER: una fila por sede. `modo` dice si descuenta de verdad (real) o
-- solo anota (prueba); `cron_activo` dice si el reloj está encendido.
-- Desde ahora los dos se cambian desde Ajustes -> Fudo.
-- ================================================================
select sede, modo, cron_activo, ultima_corrida_at, ultima_corrida_por,
       ultimo_resultado, ultimos_items, ultimos_errores, ultimos_movimientos
from public.fudo_sync
order by sede;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-secciones-y-fudo-desde-ajustes.sql', 'Jhon', 'lo corrió Jhon',
        'Tabla secciones (orden y turno AM/PM editables). fudo_sync y fudo_categorias pasan a aceptar escritura de cuentas con sesión')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
