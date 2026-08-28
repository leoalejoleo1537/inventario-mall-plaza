-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        4 bloques. El 1 y el 3 SOLO MIRAN. El 2 y el 4 escriben.
--             Corre uno, mándame el resultado, y seguimos.
--  TARDA:     instantáneo
--  QUÉ HACE:  hace que las metas cuenten el producto correcto en cada
--             sede. No toca ningún stock ni ninguna venta.
--  QUÉ VER:   el bloque 1 te muestra el error con nombre y apellido.
-- ================================================================
--
-- QUÉ ESTABA MAL, Y NO ERA "CONTABA DE MENOS"
--
-- Jhon: "el agua Bosqua de Angamos vendió más de 80 y la meta muestra 2".
--
-- La meta guardaba un id de Fudo **sin la sede**. Y los ids de Fudo solo
-- son únicos DENTRO de una cuenta — `fudo_productos` lo dice en su propia
-- tabla: `unique (sede, fudo_product_id)`. Son dos cuentas distintas.
--
--     id 584  ->  en Plaza    es  "Agua Bosqua con gas"
--     id 584  ->  en Angamos  es  "Capuccino Pedidos Ya"
--     id 585  ->  en Angamos  es  "Chocolate caliente Pedidos Ya"
--
-- Así que `meta_avance`, que unía solo por id, **contaba otro producto**.
-- Esos "2" de Angamos eran capuchinos por Pedidos Ya. No es un conteo
-- bajo: es un número de algo que no tiene nada que ver.
--
-- Es el error que §9.2 anuncia con estas palabras: *"no copiar las recetas
-- de plaza cambiando la sede — los ids de Fudo son de otra cuenta"*. Acá se
-- coló por una puerta distinta, las metas, porque nadie lo escribió como
-- regla de la TABLA. Ahora sí: la sede va en la clave.
--
-- LOS TRES HUECOS, porque eran tres y se sumaban
--
--   1. `meta_productos` no tenía columna `sede`      -> se arregla acá
--   2. `meta_avance` unía sin mirar la sede          -> se arregla acá
--   3. el buscador de la app pedía el catálogo con `.limit(1000)` y entre
--      las dos sedes hay ~1.280 productos: Supabase cortaba sin avisar y
--      media carta de Angamos no llegaba -> ya arreglado en `index.html`
--
-- Y UN CUARTO, que encontré de paso y no daba la cara todavía:
-- `meta_avance` sumaba `cantidad_vendida` sin agrupar por línea de venta.
-- Un producto con receta de 3 insumos deja 3 filas en `fudo_movimientos`,
-- así que una meta sobre ese producto contaba **el triple**. El agua no
-- tiene receta de varios insumos y por eso no se notaba. Acá se cuenta una
-- vez por línea vendida.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — VER EL ERROR  (no escribe nada)
--
-- QUÉ VER: por cada producto guardado en una meta, qué significa ese id en
-- cada sede. Donde "nombre_en_fudo" no se parezca al nombre de la meta,
-- ahí la meta está contando otra cosa.
-- ================================================================
select mp.meta_id,
       mp.nombre       as nombre_en_la_meta,
       mp.fudo_product_id as id,
       f.sede,
       f.nombre        as nombre_en_fudo,
       case when lower(btrim(f.nombre)) = lower(btrim(mp.nombre))
            then 'calza' else 'ES OTRO PRODUCTO' end as veredicto
  from public.meta_productos mp
  left join public.fudo_productos f on f.fudo_product_id = mp.fudo_product_id
 order by mp.meta_id, mp.nombre, f.sede;


-- ================================================================
-- BLOQUE 2 — LA COLUMNA `sede`  (esto escribe, pero no borra nada)
--
-- Agrega la columna y le pone la sede a cada fila que ya existe: la sede
-- donde ese id **de verdad se llama como dice la meta**. Al 584 le queda
-- 'plaza', porque es en Plaza donde ese id es el agua.
--
-- La clave primaria pasa a ser (meta_id, sede, id): así el mismo id puede
-- estar dos veces, una por sede, que es justo lo que hacía falta.
--
-- QUÉ VER: las mismas filas de antes, ahora con su sede puesta. Si alguna
-- quedara con la sede vacía, es un producto que ya no está en el catálogo
-- de Fudo — mándamelo y lo vemos.
-- ================================================================
alter table public.meta_productos add column if not exists sede text;

update public.meta_productos mp
   set sede = f.sede
  from public.fudo_productos f
 where mp.sede is null
   and f.fudo_product_id = mp.fudo_product_id
   and lower(btrim(f.nombre)) = lower(btrim(mp.nombre));

alter table public.meta_productos drop constraint if exists meta_productos_pkey;
create unique index if not exists meta_productos_uni
  on public.meta_productos (meta_id, sede, fudo_product_id);

select meta_id, nombre, fudo_product_id as id, coalesce(sede,'(sin sede)') as sede
  from public.meta_productos
 order by meta_id, nombre, sede;


-- ================================================================
-- BLOQUE 3 — QUÉ FALTA AGREGAR  (no escribe nada)
--
-- La meta quedó con el agua de Plaza y sin la de Angamos. Esto busca, en
-- las sedes que faltan, el producto que se llama IGUAL.
--
-- El nombre PROPONE, el id GUARDA — la regla de §0.7. Por eso esto se
-- mira antes de escribirlo.
--
-- QUÉ VER: las filas que el bloque 4 va a agregar. Revisá que el nombre
-- sea de verdad el mismo producto antes de seguir.
-- ================================================================
select mp.meta_id,
       mp.nombre        as producto,
       f.sede           as sede_que_falta,
       f.fudo_product_id as id_en_esa_sede,
       f.nombre         as nombre_en_fudo
  from public.meta_productos mp
  join public.fudo_productos f
    on lower(btrim(f.nombre)) = lower(btrim(mp.nombre))
   and f.sede <> mp.sede
 where mp.sede is not null
   and not exists (select 1 from public.meta_productos x
                    where x.meta_id = mp.meta_id and x.sede = f.sede
                      and x.fudo_product_id = f.fudo_product_id)
 order by mp.meta_id, mp.nombre, f.sede;


-- ================================================================
-- BLOQUE 4 — AGREGAR LO QUE FALTA Y ARREGLAR EL CONTEO  (esto escribe)
--
-- Dos cosas:
--   1. mete las filas que mostró el bloque 3
--   2. reemplaza `meta_avance` por la versión que mira la sede y cuenta
--      una vez por línea de venta
--
-- Se borra la firma vieja antes de crear la nueva (§0.5), y se vuelve a
-- dar el permiso porque el `drop` se lo lleva.
--
-- CÓMO SE DESHACE lo primero: las filas nuevas son las que tienen una sede
-- distinta de la que ya estaba. Si algo no cuadra, se borran nombrándolas.
--
-- QUÉ VER: la última consulta deja una fila por meta y sede con lo
-- vendido de verdad. El agua de Angamos tiene que dar del orden de 116
-- (68 con gas + 48 sin gas), no 2.
-- ================================================================
insert into public.meta_productos (meta_id, sede, fudo_product_id, nombre)
select distinct mp.meta_id, f.sede, f.fudo_product_id, mp.nombre
  from public.meta_productos mp
  join public.fudo_productos f
    on lower(btrim(f.nombre)) = lower(btrim(mp.nombre))
   and f.sede <> mp.sede
 where mp.sede is not null
   and not exists (select 1 from public.meta_productos x
                    where x.meta_id = mp.meta_id and x.sede = f.sede
                      and x.fudo_product_id = f.fudo_product_id);


drop function if exists public.meta_avance(bigint);

create function public.meta_avance(p_meta bigint)
returns table (sede text, vendido numeric)
language sql
stable
as 'select l.sede, coalesce(sum(l.cantidad_vendida), 0)::numeric
      from (select distinct on (m.sede, m.fudo_item_id)
                   m.sede, m.fudo_item_id, m.cantidad_vendida, m.created_at
              from public.fudo_movimientos m
             where exists (select 1 from public.meta_productos mp
                            where mp.meta_id = p_meta
                              and mp.sede = m.sede
                              and mp.fudo_product_id = m.fudo_product_id)
             order by m.sede, m.fudo_item_id, m.id) l
      join public.metas t on t.id = p_meta
     where l.created_at >= t.desde::timestamptz
       and l.created_at <  (t.hasta + 1)::timestamptz
     group by l.sede';

grant execute on function public.meta_avance(bigint) to anon, authenticated;


select t.id as meta, t.titulo, a.sede, a.vendido
  from public.metas t
  cross join lateral public.meta_avance(t.id) a
 order by t.id, a.sede;


insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-metas-cuentan-por-sede.sql', 'Jhon', 'lo corrió Jhon',
        'meta_productos gana columna sede y meta_avance une por (id, sede). Antes contaba otro producto en la segunda sede porque los ids de Fudo se repiten entre cuentas. Además ya no multiplica por los insumos de la receta')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
