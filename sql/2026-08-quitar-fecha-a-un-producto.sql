-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo
--  QUÉ HACE:  el papel mantequilla deja de pedir fecha de vencimiento,
--             conservando su stock.
--  QUÉ VER:   el bloque 4 tiene que mostrar el MISMO stock que el 1.
-- ================================================================
--
-- QUÉ PEDISTE: que el papel mantequilla deje de pedir fecha. Eso es
-- quitarle la marca de "perecedero".
--
-- LA TRAMPA, y por eso no es un update de una línea:
--
--   En un producto con fechas, el stock NO se escribe: se calcula
--   sumando las fechas. Hay un mecanismo en la base que lo mantiene así
--   solo. Entonces, si se borran las fechas, ese mecanismo pone el stock
--   en 0 en el mismo momento — y si no se le devuelve el número después,
--   el papel mantequilla queda en cero sin que nadie lo haya botado.
--
--   Por eso va en tres tiempos: primero se guarda cuánto hay, después se
--   borran las fechas, y al final se devuelve el número guardado.
--
-- POR QUÉ SÍ SE BORRAN LAS FECHAS (y no basta con quitar la marca): al
-- recibir un reparto, la base exige fechas si el producto es perecedero
-- **o si ya tiene fechas cargadas**. Dejándolas ahí, el reparto seguiría
-- pidiéndolas — que es justo lo que te molesta.
--
-- ⚠️ Las fechas borradas no vuelven. El bloque 1 te las muestra antes.
-- El stock sí queda intacto, y el bloque 4 lo comprueba.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — QUÉ SE VA A TOCAR
--
-- QUÉ VER: que la lista sea la que esperas, y **anota el stock**: es el
-- número que tiene que seguir estando al final.
--
-- Se busca ancho a propósito (papel, mantequilla) para que veas si hay
-- algo parecido que no habíamos considerado. Los bloques siguientes solo
-- tocan el que dice "papel mantequilla".
-- ================================================================
select p.id, p.sede, p.producto, p.rubro,
       coalesce(p.stock_actual,0)                   as stock_hoy,
       coalesce(to_jsonb(p) ->> 'perecedero','no')  as pide_fecha,
       (select count(*) from public.producto_lotes l where l.producto_id = p.id)
                                                    as fechas_cargadas
from public.productos p
where p.producto ilike '%mantequilla%' or p.producto ilike '%papel%'
order by p.sede, p.producto;


-- ================================================================
-- BLOQUE 2 — GUARDAR EL STOCK ANTES DE TOCAR NADA
--
-- Deja una copia en una tabla aparte. Es una sola instrucción y no borra
-- ni cambia nada todavía.
--
-- QUÉ VER: "Success". No devuelve filas.
-- ================================================================
drop table if exists public.stock_antes_de_quitar_fecha;

create table public.stock_antes_de_quitar_fecha as
select p.id, p.sede, p.producto, coalesce(p.stock_actual,0) as stock
from public.productos p
where p.producto ilike '%papel mantequilla%';


-- ================================================================
-- BLOQUE 3 — QUITARLE LA FECHA  (recién ahora, en otro Run)
--
-- Va en otro Run a propósito: la tabla del bloque 2 no se puede crear y
-- usar en la misma corrida, el editor no la ve (§3.5).
--
-- QUÉ VER: "Success". No devuelve filas.
-- ================================================================
delete from public.producto_lotes
 where producto_id in (select id from public.stock_antes_de_quitar_fecha);

update public.productos p
   set stock_actual = h.stock,
       perecedero   = false,
       updated_at   = now()
from public.stock_antes_de_quitar_fecha h
where p.id = h.id;


-- ================================================================
-- BLOQUE 4 — COMPROBAR
--
-- QUÉ VER, y esto es lo único que importa:
--   · "stock_ahora" IGUAL al "stock_hoy" del bloque 1
--   · "pide_fecha" en false
--   · "fechas_cargadas" en 0
--
-- La columna "cuadra" lo dice sola: tiene que decir SÍ en todas.
-- ================================================================
select p.id, p.sede, p.producto,
       h.stock                                      as stock_antes,
       coalesce(p.stock_actual,0)                   as stock_ahora,
       case when coalesce(p.stock_actual,0) = h.stock then 'SÍ' else '⚠️ NO' end as cuadra,
       coalesce(to_jsonb(p) ->> 'perecedero','no')  as pide_fecha,
       (select count(*) from public.producto_lotes l where l.producto_id = p.id)
                                                    as fechas_cargadas
from public.productos p
join public.stock_antes_de_quitar_fecha h on h.id = p.id
order by p.sede;

-- La copia se puede borrar cuando el bloque 4 diga SÍ en todas:
--   drop table public.stock_antes_de_quitar_fecha;
-- No corre sola a propósito: si algo saliera mal, ahí está el número.


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-quitar-fecha-a-un-producto.sql', 'Jhon', 'lo corrió Jhon',
        'El papel mantequilla deja de pedir fecha. Conserva el stock: se guarda antes de borrar las fechas y se devuelve después')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
