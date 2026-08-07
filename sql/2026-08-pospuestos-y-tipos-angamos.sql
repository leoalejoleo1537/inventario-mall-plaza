-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Correr UNO POR UNO, en orden.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  el 1 crea una tabla nueva. El 2 solo MIRA. El 3 SÍ
--             ESCRIBE: le pone tipo a los productos de Angamos.
--  QUÉ VER:   el bloque 2 es la propuesta y hay que mirarla antes de
--             correr el 3.
-- ================================================================
--
-- DOS COSAS, las dos pedidas desde el local:
--
--   1. Que "Después" se recuerde. Hoy solo salta el producto en esa
--      sesión y al día siguiente vuelve a estorbar — y como las recetas
--      se hacen de a poco durante semanas, la cola nunca bajaba.
--
--   2. Que Angamos tenga la franja de filtros de arriba (Cafetería,
--      Insumos, Bollería…). Esa franja NO es código que falte: aparece
--      sola cuando los productos tienen tipo. En Angamos están todos
--      vacíos porque el script original decía `sede='plaza'`.
--      Es la trampa que §9.2 avisa: 22 de los 42 archivos de sql/ tienen
--      'plaza' escrito a mano.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — LA TABLA DE "LO VEO DESPUÉS"
--
-- Va aparte de `fudo_no_lleva_receta` a propósito: son cosas distintas.
-- "No lleva receta" es una DECISIÓN (la bolsa de basura no se vende).
-- "Después" es el ESTADO DEL TRABAJO (hoy no me dio el tiempo).
-- Si se mezclaran, en tres meses nadie podría distinguir una de otra.
-- ================================================================
create table if not exists public.fudo_pospuestos(
  sede            text not null,
  fudo_product_id text not null,
  quien           text,
  created_at      timestamptz not null default now(),
  primary key (sede, fudo_product_id)
);

alter table public.fudo_pospuestos enable row level security;
drop policy if exists "pospuestos todos" on public.fudo_pospuestos;
create policy "pospuestos todos" on public.fudo_pospuestos
  for all to anon, authenticated using (true) with check (true);
grant select, insert, delete on public.fudo_pospuestos to anon, authenticated;


-- ================================================================
-- BLOQUE 2 — LA PROPUESTA DE TIPOS PARA ANGAMOS. Solo mira.
--
-- QUÉ VER: la columna "propuesta". Las que digan "— revisar —" son las
-- que el nombre no alcanzó a identificar: quedan sin tipo y se les pone
-- después desde la ficha del producto, en la app.
--
-- Si un tipo se ve muy mal repartido, avisar ANTES de correr el bloque 3.
-- ================================================================
with base as (
  select producto, rubro,
         lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as n,
         lower(translate(coalesce(rubro,''),'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as r
  from public.productos
  where sede='angamos' and activo='SÍ' and tipo is null
)
select case
    when n ~ 'sandwich|sanguche|croasan|croissant|selladito|ciabatta|pan '     then 'Sándwiches'
    when n ~ 'torta|cheesecake|pie de|tiramisu|matilda|kutchen|selva negra'    then 'Tortas'
    when n ~ 'cannoli|cinnamon|dona|donut|muffin|medialuna|berlin|bolleria'    then 'Bollería'
    when n ~ 'galleta|galleton|cookie|alfajor|maicenito|cachito|brownie|volcan|macarron|waffle' then 'Pastelería'
    when n ~ 'pizza|empanada|calzone'                                          then 'Salados'
    when n ~ 'pulpa|jugo|bebida|agua|gaseosa|coca|sprite|fanta|pepsi|soda|tonica|ginger' then 'Bebidas'
    when n ~ 'cafe|espresso|leche|te |te$|infusion|matcha|chai|syrup'           then 'Cafetería'
    when r ~ 'limpieza'                                                        then 'Limpieza'
    when n ~ 'bolsa|vaso|tapa|servilleta|bandeja|caja|cuchar|removedor|revolvedor|papel|bombilla|collarin' then 'Envases'
    when r ~ 'bolsas|caja|mesones'                                             then 'Envases'
    when n ~ 'azucar|harina|crema|mantequilla|huevo|salsa|queso|jamon|palta|mezcla|helado|mermelada' then 'Insumos'
    when r ~ 'mezclas'                                                         then 'Insumos'
    else '— revisar —'
  end                                    as propuesta,
  count(*)                               as cuantos,
  string_agg(producto, '  ·  ' order by producto) as ejemplos
from base
group by 1
order by cuantos desc;


-- ================================================================
-- BLOQUE 3 — ESCRIBIRLO
--
-- Solo toca los que NO tienen tipo todavía: así una corrección hecha a
-- mano desde la app nunca se pisa al volver a correr esto.
-- Los "— revisar —" quedan sin tipo, a propósito.
--
-- QUÉ VER: al terminar, la consulta de abajo muestra cómo quedó. Y en la
-- app, entrar a Parque Angamos: la franja de filtros ya tiene que estar.
--
-- CÓMO SE DESHACE:  update public.productos set tipo=null where sede='angamos';
-- ================================================================
with base as (
  select id, producto,
         lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as n,
         lower(translate(coalesce(rubro,''),'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as r
  from public.productos
  where sede='angamos' and activo='SÍ' and tipo is null
),
prop as (
  select id, case
    when n ~ 'sandwich|sanguche|croasan|croissant|selladito|ciabatta|pan '     then 'Sándwiches'
    when n ~ 'torta|cheesecake|pie de|tiramisu|matilda|kutchen|selva negra'    then 'Tortas'
    when n ~ 'cannoli|cinnamon|dona|donut|muffin|medialuna|berlin|bolleria'    then 'Bollería'
    when n ~ 'galleta|galleton|cookie|alfajor|maicenito|cachito|brownie|volcan|macarron|waffle' then 'Pastelería'
    when n ~ 'pizza|empanada|calzone'                                          then 'Salados'
    when n ~ 'pulpa|jugo|bebida|agua|gaseosa|coca|sprite|fanta|pepsi|soda|tonica|ginger' then 'Bebidas'
    when n ~ 'cafe|espresso|leche|te |te$|infusion|matcha|chai|syrup'           then 'Cafetería'
    when r ~ 'limpieza'                                                        then 'Limpieza'
    when n ~ 'bolsa|vaso|tapa|servilleta|bandeja|caja|cuchar|removedor|revolvedor|papel|bombilla|collarin' then 'Envases'
    when r ~ 'bolsas|caja|mesones'                                             then 'Envases'
    when n ~ 'azucar|harina|crema|mantequilla|huevo|salsa|queso|jamon|palta|mezcla|helado|mermelada' then 'Insumos'
    when r ~ 'mezclas'                                                         then 'Insumos'
    else null
  end as t
  from base
)
update public.productos p
   set tipo = prop.t
  from prop
 where p.id = prop.id and prop.t is not null;


-- ---------- cómo quedó ----------
select coalesce(tipo,'— sin tipo, se pone desde la ficha —') as tipo,
       count(*) as productos
from public.productos
where sede='angamos' and activo='SÍ'
group by 1
order by productos desc;


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-pospuestos-y-tipos-angamos.sql', 'Jhon', 'lo corrió Jhon',
        'Tabla fudo_pospuestos para que "Después" se recuerde, y tipos de producto en Angamos para que aparezca la franja de filtros')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
