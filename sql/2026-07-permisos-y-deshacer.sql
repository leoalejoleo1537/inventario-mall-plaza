-- ================================================================
-- ZONA DE ADMINISTRACIÓN — permisos y deshacer
--
-- Correr TODO de una vez en Supabase -> SQL Editor. Es idempotente:
-- se puede volver a correr sin romper nada ni duplicar permisos.
--
-- No modifica ningún producto, ningún stock, ni toca Fudo.
-- ================================================================


-- ████████████████████████████████████████████████████████████████
-- ██                                                            ██
-- ██   PARA AGREGAR O QUITAR UNA PERSONA — LEE ESTO             ██
-- ██                                                            ██
-- ████████████████████████████████████████████████████████████████
--
-- Todo lo que hay que saber está en el BLOQUE 2, más abajo, donde
-- dice "LA LISTA DE PERSONAS AUTORIZADAS". Ahí hay una lista de
-- correos; se agrega o se quita una línea y se corre ese bloque.
--
-- NO hace falta correr el archivo entero de nuevo, ni pedirle nada
-- a nadie: es copiar una línea, cambiar el correo, y Run.
--
-- ⚠️ DOS COSAS QUE HAY QUE SABER SÍ O SÍ:
--
--   1) El correo tiene que ser EXACTAMENTE el mismo con el que esa
--      persona INICIA SESIÓN en la app. Si entra con
--      "Adriana@..." y acá dice "adriana@...", igual funciona
--      (se compara en minúsculas), pero si el correo es OTRO, no.
--
--   2) La persona tiene que TENER CUENTA en la app. Agregar un
--      correo acá no crea la cuenta: solo le da permiso a una
--      cuenta que ya existe.
--
-- ████████████████████████████████████████████████████████████████


-- ================================================================
-- BLOQUE 1 — La tabla de permisos. Correr una sola vez.
-- ================================================================
create table if not exists public.app_permisos(
  correo      text primary key,        -- siempre en minúsculas
  nombre      text,                    -- solo para saber quién es al mirar la tabla
  puede_fudo  boolean not null default true,   -- actualizar el stock de Fudo
  puede_editar boolean not null default true,  -- renombrar/eliminar/crear productos
  creado_por  text,
  created_at  timestamptz not null default now()
);

alter table public.app_permisos enable row level security;

-- La app LEE esta tabla para decidir si muestra la zona de administración.
-- Eso es comodidad, no seguridad: el candado de verdad está en la Edge
-- Function, que vuelve a comprobarlo en el servidor antes de tocar Fudo.
drop policy if exists "app_permisos read" on public.app_permisos;
create policy "app_permisos read" on public.app_permisos
  for select to anon, authenticated using (true);
grant select on public.app_permisos to anon, authenticated;
-- Nadie escribe desde la app: los permisos se dan solo desde acá, a mano.


-- ================================================================
-- BLOQUE 2 — LA LISTA DE PERSONAS AUTORIZADAS
--
-- ▼▼▼ ACÁ SE AGREGA O SE QUITA GENTE ▼▼▼
--
-- Para AGREGAR: copia una línea, cámbiale el correo y el nombre,
--               y acuérdate de la coma al final de la anterior.
--               La ÚLTIMA línea termina en punto y coma, sin coma.
-- Para QUITAR:  ver el BLOQUE 3.
--
-- Se puede correr las veces que quieras: si el correo ya está, solo
-- actualiza el nombre y los permisos (no se duplica).
-- ================================================================
insert into public.app_permisos (correo, nombre, puede_fudo, puede_editar, creado_por) values
  ('leoalejoleo1@gmail.com',              'Jhon',      true, true, 'Jhon'),
  ('rrh@cafedeldesierto.cl',              'Verónica',  true, true, 'Jhon'),
  ('orquerapvalentina@gmail.com',         'Valentina', true, true, 'Jhon'),
  ('franquicias@cafedeldesierto.cl',      'Massiel',   true, true, 'Jhon'),
  ('administracion@cafedeldesierto.cl',   'Adriana',   true, true, 'Jhon')
  -- ('nuevo.correo@ejemplo.cl',          'Nombre',    true, true, 'Jhon')   <-- copia esta línea, quítale los guiones del principio
on conflict (correo) do update
  set nombre       = excluded.nombre,
      puede_fudo   = excluded.puede_fudo,
      puede_editar = excluded.puede_editar;

-- ▲▲▲ HASTA ACÁ LA LISTA ▲▲▲


-- ---------- Comprobación: quién quedó con permiso ----------
select correo, nombre, puede_fudo, puede_editar, created_at
from public.app_permisos
order by nombre;


-- ================================================================
-- BLOQUE 3 — QUITARLE EL PERMISO A ALGUIEN
--
-- Descomenta la línea (quítale los dos guiones), pon el correo y
-- córrela sola. Quitar el permiso NO borra su cuenta: sigue usando
-- la app normal, solo deja de ver la zona de administración.
-- ================================================================
-- delete from public.app_permisos where correo = 'correo.a.quitar@ejemplo.cl';

-- Si prefieres dejarlo registrado pero sin acceso a Fudo:
-- update public.app_permisos set puede_fudo = false where correo = 'correo@ejemplo.cl';


-- ================================================================
-- BLOQUE 4 — Preparar el DESHACER
--
-- Hasta ahora cada empuje a Fudo dejaba sus filas en fudo_stock_push,
-- pero sin nada que dijera "estas 58 son del mismo envío". Sin eso no
-- se puede deshacer "el último empuje": no se sabe cuál fue.
--
-- Se agrega una marca de lote (un código por envío) y se les pone una
-- a las filas que ya existen, agrupándolas por el segundo en que se
-- guardaron — que es como se hicieron: todas juntas.
-- ================================================================
alter table public.fudo_stock_push add column if not exists lote uuid;

create index if not exists fudo_stock_push_lote_idx
  on public.fudo_stock_push (sede, lote);

-- Rellena las filas viejas. Solo toca las que no tienen lote.
--
-- El lote se calcula a partir de la sede y del segundo en que se guardó:
-- las filas de un mismo envío comparten los dos, así que caen en el mismo
-- lote. NO se usa gen_random_uuid() acá: al ser una función volátil,
-- Postgres la vuelve a evaluar en CADA fila y cada producto terminaba en
-- un lote propio — con eso, "el último empuje" era un solo producto.
update public.fudo_stock_push p
set lote = md5(p.sede || '|' || date_trunc('second', p.created_at)::text)::uuid
where p.lote is null;


-- ================================================================
-- BLOQUE 5 — Qué devolvería el deshacer
--
-- Devuelve las filas del ÚLTIMO empuje de la sede: qué producto, qué
-- número tiene Fudo ahora y a cuál volvería. Solo las que se
-- aplicaron bien (ok = true): las que fallaron nunca cambiaron nada.
--
-- Solo el ÚLTIMO. Deshacer uno de hace tres días, con ventas de por
-- medio, restauraría números que ya no significan nada.
-- ================================================================
create or replace function public.fudo_ultimo_empuje(p_sede text)
returns table(
  lote             uuid,
  cuando           timestamptz,
  quien            text,
  fudo_product_id  text,
  producto_fudo    text,
  stock_ahora      numeric,   -- lo que le mandamos entonces
  volveria_a       numeric    -- lo que tenía antes
)
language sql
stable
security definer
set search_path = public
as $$
  with ultimo as (
    select p.lote
    from public.fudo_stock_push p
    where p.sede = p_sede and p.lote is not null and p.ok
    order by p.created_at desc
    limit 1
  )
  select p.lote, p.created_at, p.quien, p.fudo_product_id, p.producto_fudo,
         p.stock_enviado, p.stock_anterior
  from public.fudo_stock_push p
  join ultimo u on u.lote = p.lote
  where p.ok
  order by p.producto_fudo;
$$;

grant execute on function public.fudo_ultimo_empuje(text) to anon, authenticated;


-- ---------- Comprobación: TIENE QUE SALIR UNA SOLA FILA ----------
-- Dos versiones de la misma función vuelven ambigua la llamada por la
-- API y la petición se rechaza antes de ejecutar nada.
select p.oid::regprocedure as funcion_instalada
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='fudo_ultimo_empuje';


-- ---------- Comprobación: qué devolvería el deshacer hoy ----------
select producto_fudo, stock_ahora, volveria_a, quien, cuando
from public.fudo_ultimo_empuje('plaza')
order by producto_fudo
limit 20;
