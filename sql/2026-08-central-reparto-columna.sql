-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        1 solo bloque.
--  TARDA:     instantáneo
--  QUÉ HACE:  agrega UNA columna a las líneas del reparto. No mueve stock,
--             no cambia ningún producto, no toca los repartos que existen.
--  QUÉ VER:   la comprobación del final: 1 fila, en SÍ.
-- ================================================================
--
-- QUÉ ES: cada línea de un reparto ya sabe a qué producto del LOCAL sumarle.
-- Esta columna guarda de cuál producto de BODEGA hay que descontar.
--
-- Se resuelve al armar el envío y se guarda ahí, no se busca al recibirlo. La
-- razón importa: si el día que el jefe confirma alguien ya cambió una pareja de
-- la libreta, el envío tiene que descontar de donde se decidió cuando salió, no
-- de donde apunte la libreta después.
--
-- Las líneas armadas DENTRO del local quedan con esta columna vacía, y eso es
-- correcto: esos envíos no salen de bodega, así que bodega no baja. Es lo que
-- hace que se puedan seguir usando las dos formas en paralelo sin que nada se
-- descuente dos veces.
--
-- Todavía NO descuenta nada. Esto solo deja escrito de dónde habría que
-- descontar; el descuento entra en el paso siguiente.
-- ================================================================

alter table public.reparto_items
  add column if not exists producto_bodega_id bigint
  references public.productos(id) on delete set null;

comment on column public.reparto_items.producto_bodega_id is
  'De cuál producto de bodega descontar al confirmar esta línea. Vacío = el envío no salió de bodega.';

create index if not exists reparto_items_bodega_idx
  on public.reparto_items(producto_bodega_id);


-- ---------- comprobación: 1 fila, en SÍ ----------
select 'columna producto_bodega_id en reparto_items' as pieza,
       case when exists (select 1 from information_schema.columns
                          where table_schema='public' and table_name='reparto_items'
                            and column_name='producto_bodega_id')
            then 'SÍ' else 'NO' end as quedo;
