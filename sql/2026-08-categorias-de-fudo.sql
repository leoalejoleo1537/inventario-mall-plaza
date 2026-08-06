-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 pasos. Correr UNO POR UNO, cada uno en su Run.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  crea una tabla chica que traduce cada categoría de Fudo
--             a una sección NUESTRA. Los pasos 1 y 2 escriben, pero
--             solo esa tabla nueva: no tocan productos, ni recetas,
--             ni stock.
--  QUÉ VER:   el paso 3 devuelve ~15 filas por sede. Ese resultado hay
--             que pegárselo a Claude.
-- ================================================================
--
-- PARA QUÉ SIRVE, con una imagen: la portada de Recetas va a mostrar
-- barras que dicen "Vitrina de tortas: 18 de 22". Para eso hay que
-- poder decir a qué sección pertenece CADA producto de Fudo — incluidos
-- los que todavía no tienen receta.
--
-- Y ahí está el problema: la sección de un producto vive en el producto
-- del INVENTARIO, que es justo el que falta enlazar. Huevo y gallina.
--
-- Ya se probó deducirlo solo, mirando las recetas que ya existen, y NO
-- funcionó: 212 de 437 productos caían en "Vitrina de tortas" porque
-- Fudo agrupa mucho más grueso que nosotros. Una barra gigante que no
-- dice dónde está el hueco no sirve para nada.
--
-- La salida es esta tabla. Son ~15 categorías por sede, se llena UNA
-- vez, y con eso las barras salen honestas desde el primer día y con
-- los nombres que el equipo reconoce.
-- ================================================================


-- ================================================================
-- PASO 1 — CREAR LA TABLA (correr esto SOLO, y apretar Run)
--
-- ⚠️ Va en su propio Run a propósito. El editor de Supabase no ve una
-- tabla recién creada dentro de la misma corrida (§3.5).
-- ================================================================
create table if not exists public.fudo_categorias(
  sede         text not null,
  categoria_id text not null,
  rubro        text,          -- nuestra sección. Vacío = todavía sin decidir
  ejemplos     text,          -- qué productos hay adentro, para acordarse
  updated_at   timestamptz not null default now(),
  primary key (sede, categoria_id)
);

alter table public.fudo_categorias enable row level security;
drop policy if exists "fudo_categorias read" on public.fudo_categorias;
create policy "fudo_categorias read" on public.fudo_categorias
  for select to anon, authenticated using (true);
grant select on public.fudo_categorias to anon, authenticated;


-- ================================================================
-- PASO 2 — SEMBRARLA (ahora sí, en un Run aparte)
--
-- Mete una fila por cada categoría que Fudo tiene hoy, en las DOS
-- sedes, con la columna "rubro" VACÍA y unos ejemplos de qué hay
-- adentro. Nadie decide nada todavía.
--
-- Se puede correr las veces que quieras: no pisa lo que ya esté
-- decidido, solo refresca los ejemplos y agrega categorías nuevas.
-- ================================================================
insert into public.fudo_categorias (sede, categoria_id, ejemplos)
select p.sede,
       p.categoria_id,
       string_agg(p.nombre, '  ·  ' order by p.rn) filter (where p.rn <= 6)
from (
  select f.sede, f.categoria_id, f.nombre,
         row_number() over (partition by f.sede, f.categoria_id order by f.nombre) as rn
  from public.fudo_productos f
  where f.activo and f.categoria_id is not null
) p
group by p.sede, p.categoria_id
on conflict (sede, categoria_id) do update
  set ejemplos = excluded.ejemplos, updated_at = now();


-- ================================================================
-- PASO 3 — MIRARLA  ➜  ESTE RESULTADO SE LE PEGA A CLAUDE
--
-- QUÉ VER: una fila por categoría. La columna "que_hay_adentro" dice
-- qué productos tiene, y de ahí sale el nombre de la sección.
--
-- Fudo nos manda un número de categoría, no un nombre — por eso hay
-- que mirar los ejemplos en vez del id.
-- ================================================================
select c.sede,
       c.categoria_id,
       count(f.fudo_product_id)                                as productos,
       count(r.id)                                             as ya_enlazados,
       coalesce(c.rubro, '— falta decidir —')                  as nuestra_seccion,
       c.ejemplos                                              as que_hay_adentro
from public.fudo_categorias c
left join public.fudo_productos f
  on f.sede = c.sede and f.categoria_id = c.categoria_id and f.activo
left join public.recetas r
  on r.sede = c.sede and r.activo and r.fudo_product_id = f.fudo_product_id
group by c.sede, c.categoria_id, c.rubro, c.ejemplos
order by c.sede, count(f.fudo_product_id) desc;


-- ---------- ¿quedó algún producto sin categoría? ----------
-- Lo ideal es 0. Si hay muchos, avisar: esos no podrían agruparse en
-- ninguna barra y habría que decidir dónde van.
select sede, count(*) as sin_categoria
from public.fudo_productos
where activo and categoria_id is null
group by sede;


-- ================================================================
-- PASO 4 — (lo escribe Claude con tus respuestas)
--
-- Van a ser ~15 líneas así, una por categoría:
--
--   update public.fudo_categorias set rubro='Vitrina de tortas'
--    where sede='angamos' and categoria_id='8';
--
-- Y después esta comprobación, que es la que cierra el tema:
--
--   select coalesce(c.rubro,'— sin sección —') as seccion,
--          count(*) as productos_de_fudo
--   from public.fudo_productos f
--   left join public.fudo_categorias c
--     on c.sede=f.sede and c.categoria_id=f.categoria_id
--   where f.sede='angamos' and f.activo
--   group by 1 order by 2 desc;
--
-- "— sin sección —" tiene que quedar en 0 o casi.
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-categorias-de-fudo.sql', 'Jhon', 'lo corrió Jhon',
        'Tabla que traduce cada categoría de Fudo a una sección nuestra. Es lo que agrupa las barras de la portada de Recetas')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
