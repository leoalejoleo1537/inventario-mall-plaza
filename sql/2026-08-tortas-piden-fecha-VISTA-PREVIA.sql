-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        2 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo
--  QUÉ HACE:  NADA todavía. Solo muestra qué tortas se marcarían y con
--             cuánto stock. El script que marca va después, cuando veas
--             esta lista.
--  QUÉ VER:   el bloque 1 es la lista. El bloque 2 es la advertencia
--             importante: cuántas tortas tienen stock que hay que
--             cuidar al hacer el cambio.
-- ================================================================
--
-- QUÉ PEDISTE: que las tortas pidan fecha de vencimiento en el reparto,
-- igual que los sándwiches. Eso es marcarlas como "perecederas".
--
-- LA TRAMPA, y por eso esto va en dos tiempos:
--
--   En un producto con fechas, el stock NO se escribe: se calcula
--   sumando las fechas. Es la regla que hace que los sándwiches cuadren.
--
--   Entonces, una torta que hoy tiene 8 en la vitrina y NO tiene ninguna
--   fecha cargada: el día que llegue un reparto con 4 y su fecha, el
--   sistema recalcula el stock desde las fechas y esa torta queda en
--   **4**, no en 12. Los 8 que ya estaban se pierden sin que nadie lo
--   note, porque no tenían fecha con la cual contarse.
--
--   Es la misma clase de falla que ya nos costó caro: no se cae nada,
--   solo queda un número más chico.
--
-- CÓMO SE EVITA: al marcarlas, las unidades que ya hay se anotan como
-- una fecha "por poner". Así el total no cambia, y esas unidades quedan
-- a la vista para que el local les ponga la fecha de verdad al contar.
-- Eso lo hace el script siguiente; este solo te muestra el terreno.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — QUÉ TORTAS HAY, Y DÓNDE
--
-- Se buscan por tres caminos porque no sé cuál usa cada sede: por el
-- TIPO del producto, por la SECCIÓN, y por el nombre.
--
-- QUÉ VER: que la lista sea la que esperas. Si sobra algo (una "torta"
-- que en realidad es un insumo, o un envase), decímelo y lo saco.
-- ================================================================
-- ⚠️ `tipo` y `perecedero` se leen con to_jsonb a propósito: si alguna de
-- las dos columnas no estuviera en la base, escribirla derecho haría fallar
-- el informe entero por una palabra (§0.1.9). Así, si falta, sale vacía.
select p.sede,
       p.id                        as ficha,
       p.producto,
       p.rubro                     as seccion,
       to_jsonb(p) ->> 'tipo'      as tipo,
       coalesce(p.stock_actual, 0) as stock_hoy,
       coalesce(to_jsonb(p) ->> 'perecedero', 'no') as ya_pedia_fecha,
       (select count(*) from public.producto_lotes l where l.producto_id = p.id)
                                   as fechas_que_ya_tiene,
       case when coalesce(to_jsonb(p) ->> 'tipo','') ilike '%torta%' then 'por el tipo'
            when p.rubro ilike '%torta%' then 'por la sección'
            else 'por el nombre' end       as por_que_esta_en_la_lista
from public.productos p
where p.activo = 'SÍ'
  and (coalesce(to_jsonb(p) ->> 'tipo','') ilike '%torta%'
       or p.rubro ilike '%torta%'
       or p.producto ilike '%torta%')
order by p.sede, p.rubro, p.producto;


-- ================================================================
-- BLOQUE 2 — ⚠️ EL TAMAÑO DE LA TRAMPA
--
-- Cuántas de esas tortas tienen stock hoy y ninguna fecha cargada. Esas
-- son exactamente las que perderían su stock si se marcaran a secas.
--
-- QUÉ VER: el número de la columna "en_riesgo". Si es 0, el cambio es
-- trivial. Si no, el script que sigue tiene que cuidarlas — y lo hace.
-- ================================================================
select p.sede,
       count(*)                                        as tortas,
       count(*) filter (where coalesce(p.stock_actual,0) > 0
                          and not exists (select 1 from public.producto_lotes l
                                           where l.producto_id = p.id))
                                                       as en_riesgo,
       sum(coalesce(p.stock_actual,0)) filter (where not exists
             (select 1 from public.producto_lotes l where l.producto_id = p.id))
                                                       as unidades_que_hay_que_cuidar
from public.productos p
where p.activo = 'SÍ'
  and (coalesce(to_jsonb(p) ->> 'tipo','') ilike '%torta%'
       or p.rubro ilike '%torta%'
       or p.producto ilike '%torta%')
group by p.sede
order by p.sede;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-tortas-piden-fecha-VISTA-PREVIA.sql', 'Jhon', 'lo corrió Jhon',
        'SOLO LECTURA: qué tortas se marcarían como perecederas y cuántas unidades hay que cuidar al hacerlo')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
