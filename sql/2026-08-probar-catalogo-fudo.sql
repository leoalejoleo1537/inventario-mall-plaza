-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--             (pero ANTES hay un paso en Edge Functions, ver abajo)
--  ES:        2 bloques. Correr el 1, esperar ~15 segundos, correr el 2.
--  TARDA:     el bloque 1 es instantáneo; la respuesta demora unos segundos
--  QUÉ HACE:  le pide a la prueba de catálogo que corra, y después trae
--             su respuesta. NO toca ningún producto real de Fudo.
--  QUÉ VER:   en el bloque 2, la columna "veredicto".
-- ================================================================
--
-- ================================================================
-- PASO 0 — ESTO VA UNA SOLA VEZ, Y NO ES SQL
--
-- Una Edge Function es un programa, no una consulta. Vive en otra parte
-- del panel y hay que dejarla instalada antes de poder llamarla:
--
--   Supabase  ->  Edge Functions  ->  Deploy a new function
--   ->  nombre EXACTO:  fudo-probar-catalogo
--   ->  borrar lo que venga de ejemplo y pegar el contenido de
--       supabase/functions/fudo-probar-catalogo/index.ts
--   ->  Deploy
--
-- El nombre tiene que ser idéntico, con guiones: la dirección que usa el
-- bloque 1 se arma con ese nombre.
--
-- Una vez desplegada, esto ya no se repite. Lo de abajo sí es SQL.
-- ================================================================
--
-- POR QUÉ SE LLAMA DESDE ACÁ Y NO DESDE OTRO LADO: `net.http_post` manda
-- la llamada desde la base, que es exactamente lo que hace el cron de las
-- ventas cada 15 minutos desde el 31 de julio. Es un camino ya probado en
-- producción, y así no hay que aprenderse otra pantalla.
--
-- QUÉ VA A HACER LA PRUEBA, para que no haya sorpresas: crea un producto
-- de mentira llamado "ZZZ PRUEBA CLAUDE - ignorar", lo desactiva y lo
-- intenta borrar. NO toca la Dona Pistacho Dubai ni ningún producto de
-- verdad — porque si borrar funciona y crear no, un producto borrado por
-- error no se recupera de ninguna forma.
--
-- Si borrar funciona, no queda nada. Si no, queda ese producto de mentira
-- al final de la lista y la respuesta lo avisa.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — PEDIRLE QUE CORRA
--
-- Devuelve un número (el comprobante de la llamada). Ese número no dice
-- nada todavía. La respuesta llega en el bloque 2.
-- ================================================================
select net.http_post(
  url := 'https://fqjdecjsbnicvyrxkxcu.supabase.co/functions/v1/fudo-probar-catalogo',
  headers := jsonb_build_object(
    'Authorization', 'Bearer sb_publishable_P5TfG3nhMG3oNT9VLs16_w_iKHvktwl',
    'Content-Type',  'application/json'),
  body := '{"sede":"angamos"}'::jsonb
) as comprobante;


-- ================================================================
-- BLOQUE 2 — VER LA RESPUESTA
--
-- ⚠️ ESPERAR unos 15 segundos antes de correrlo: la prueba tiene que
-- hablar con Fudo cinco veces.
--
-- QUÉ VER: la columna "veredicto".
--
-- Trae las 3 últimas respuestas y la respuesta COMPLETA a propósito: si
-- algo falló, prefiero que salga el error a la vista antes que una tabla
-- vacía que no dice por qué. La fila de arriba es la más reciente.
--
-- ⚠️ El "not like" saca de en medio al cron de ventas, que también deja
-- su respuesta acá cada 15 minutos y se cuela como la fila más nueva.
--
-- Si las filas son viejas (mira "cuando"), la prueba todavía no
-- contesta: esperar otro poco y volver a correr ESTE bloque, no el 1.
-- ================================================================
select created                                        as cuando,
       status_code                                    as codigo,
       case when content ~ '^\s*\{' then content::jsonb ->> 'veredicto'  end as veredicto,
       case when content ~ '^\s*\{' then content::jsonb ->> 'que_hacer'  end as que_hacer,
       case when content ~ '^\s*\{' then content::jsonb ->> 'ojo'        end as ojo,
       content                                        as respuesta_completa
from net._http_response
where content is null or content not like '%ventas_leidas%'
order by created desc
limit 3;


-- ================================================================
-- SI EL BLOQUE 2 DA ERROR EN VEZ DE UNA TABLA
--
-- Dos posibilidades, y se distinguen por lo que diga el mensaje:
--
--  · "permission denied for schema net"  o  "does not exist"
--       -> la base no deja leer las respuestas desde acá. Entonces
--          mándame lo que diga y lo hacemos por otro camino.
--
--  · cualquier otra cosa
--       -> cópiame el mensaje tal cual.
--
-- Y para comprobar que pg_net está (tiene que devolver una fila):
--
--   select extname from pg_extension where extname = 'pg_net';
-- ================================================================


-- ---------- registro en el cuaderno ----------
-- Se anota aunque sea una prueba: lo que importa del cuaderno es saber
-- qué se corrió de verdad, no solo qué cambió el esquema.
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-probar-catalogo-fudo.sql', 'Jhon', 'lo corrió Jhon',
        'Prueba aislada: si la API de Fudo deja crear, desactivar y borrar productos del catálogo')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
