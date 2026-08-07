-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  el 1 le da permiso de actualizar Fudo a las 11 personas.
--             El 2 carga la lista de tareas del turno de Angamos.
--             SÍ ESCRIBE, pero no toca productos, recetas ni stock.
--  QUÉ VER:   cada bloque deja su comprobación al final.
-- ================================================================
--
-- ⚠️ LOS CORREOS VAN EN MINÚSCULAS, siempre. La app compara el correo de
-- la sesión en minúsculas contra esta tabla; uno con mayúscula no calza y
-- esa persona simplemente no tendría el permiso, sin ningún error visible.
-- Los de la lista ya vienen convertidos.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — QUIÉN PUEDE ACTUALIZAR FUDO
--
-- Se puede correr las veces que quieras: si el correo ya está, solo
-- le actualiza el nombre y los permisos. No duplica.
--
-- ⚠️ QUÉ ENCIENDE ESTE PERMISO, para que no sea una sorpresa: además de
-- que el reparto sume a Fudo al recibirlo, `puede_fudo` hace aparecer en
-- el menú ☰ la zona de administración con el botón rojo que reescribe el
-- stock de todos los productos de una vez. Jhon lo sabe y decidió así
-- (2026-08-06): el reparto pasa por tres filtros humanos —Adriana al
-- recibir del proveedor, Adriana al armar, y el jefe al confirmar— y hoy
-- es trivial marcar "no llegó" y que un producto desaparezca sin dejar
-- rastro. Cerrar esa fuga vale más que el riesgo del botón.
-- ================================================================
insert into public.app_permisos (correo, nombre, puede_fudo, puede_editar, creado_por) values
  ('leoalejoleo1@gmail.com',             'Jhon',      true, true,  'Jhon'),
  ('rrh@cafedeldesierto.cl',             'Verónica',  true, true,  'Jhon'),
  ('administracion@cafedeldesierto.cl',  'Adriana',   true, true,  'Jhon'),
  ('orquerapvalentina@gmail.com',        'Valentina', true, true,  'Jhon'),
  ('franquicias@cafedeldesierto.cl',     'Massiel',   true, true,  'Jhon'),
  -- jefatura de turno: reciben repartos, no arman inventario
  ('co16966@gmail.com',                  'Camila Ortega',   true, false, 'Jhon'),
  ('leorios050@gmail.com',               'Joan Ríos',       true, false, 'Jhon'),
  ('fernanda.javiera2002@gmail.com',     'Fernanda',        true, false, 'Jhon'),
  ('danilo.da420@gmail.com',             'Danilo',          true, false, 'Jhon'),
  ('jesuspimentel1611@gmail.com',        'Jesús',           true, false, 'Jhon'),
  ('kdhdjeb1234@gmail.com',              'Linda',           true, false, 'Jhon')
on conflict (correo) do update
  set nombre       = excluded.nombre,
      puede_fudo   = excluded.puede_fudo,
      puede_editar = excluded.puede_editar;


-- ---------- comprobación: quién quedó con qué ----------
-- "puede_editar" en false = puede recibir repartos y que suban a Fudo,
-- pero NO puede renombrar ni eliminar productos. Es lo que corresponde a
-- jefatura de turno.
select nombre, correo, puede_fudo, puede_editar,
       case when puede_editar then 'administración' else 'jefatura de turno' end as rol
from public.app_permisos
order by puede_editar desc, nombre;


-- ================================================================
-- BLOQUE 2 — LAS TAREAS DEL TURNO DE ANGAMOS
--
-- Se puede correr de nuevo sin que se dupliquen: solo mete las que
-- todavía no están.
-- ================================================================
insert into public.tareas (sede, texto, creada_por)
select 'angamos', v.texto, 'Jhon'
from (values
  ('Revisión de funcionamiento de equipos (horno, vitrinas, cooler)'),
  ('Revisión de rótulos'),
  ('Subir cosas de bodega'),
  ('Surtir vitrina'),
  ('Mise en place (zumo, palta, pulpas)'),
  ('Montaje salón'),
  ('Abrir Pedidos Ya · 9:30'),
  ('Llenado de planilla'),
  ('Limpieza de módulo'),
  ('Limpieza de trampa')
) as v(texto)
where not exists (
  select 1 from public.tareas t where t.sede='angamos' and t.texto = v.texto);


-- ---------- comprobación ----------
select texto, hecha from public.tareas where sede='angamos' order by id;


-- ================================================================
-- SI DESPUÉS LAS QUIERES TAMBIÉN EN MALL PLAZA
--
-- La lista se copia con esto, pero OJO: el botón en Plaza está apagado
-- desde el código (FLAGS en index.html). Copiarlas no las hace aparecer.
--
-- insert into public.tareas (sede, texto, creada_por)
-- select 'plaza', texto, creada_por from public.tareas t where t.sede='angamos'
--  and not exists (select 1 from public.tareas p where p.sede='plaza' and p.texto=t.texto);
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-permisos-fudo-y-tareas-angamos.sql', 'Jhon', 'lo corrió Jhon',
        'puede_fudo a las 11 personas para que el reparto suba a Fudo al recibirlo, y las 10 tareas del turno de Angamos')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
