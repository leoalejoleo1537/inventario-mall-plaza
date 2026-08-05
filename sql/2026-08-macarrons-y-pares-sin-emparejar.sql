-- ================================================================
--  DÓNDE VA:  Supabase  ->  SQL Editor  ->  New query
--  ES:        3 bloques. Correr UNO POR UNO.
--  TARDA:     instantáneo cada uno
--  QUÉ HACE:  el 1 y el 2 solo MIRAN. El 3 renombra, y hay que
--             editarlo antes de correrlo.
--  QUÉ VER:   el bloque 2 es la lista de todos los productos que hoy
--             NO están sumando entre vitrina y congelador.
-- ================================================================
--
-- EL PROBLEMA, con el caso real (Jhon, 2026-08-05): en Mall Plaza había
-- 5 macarrons en vitrina y 5 paquetes (60 unidades) en el congelador.
-- Adriana, al armar el reparto, veía 5. Pidió más. Sobre-stock que hubo
-- que devolver.
--
-- POR QUÉ PASA: la app suma vitrina + congelador cuando los dos
-- productos comparten el mismo NOMBRE BASE — o sea el nombre sin el
-- apellido " Vitrina" / " Congelador". Si uno se llama "Macarrons" y el
-- otro "Macarrons congelados", el nombre base NO coincide y la app los
-- trata como dos productos distintos.
--
-- ⚠️ RENOMBRAR NO ROMPE NADA. Las recetas se unen por ID, no por
-- nombre (regla 0.1.1). El descuento sigue funcionando igual.
-- ================================================================


-- ================================================================
-- BLOQUE 1 — EL CASO DE LOS MACARRONS
--
-- QUÉ VER: los nombres EXACTOS de los dos, y su nombre base. Si la
-- columna "nombre_base" no dice lo mismo en las dos filas, ahí está el
-- problema.
-- ================================================================
select id,
       producto,
       rubro,
       stock_actual,
       base_nombre(producto) as nombre_base
from public.productos
where sede='plaza' and activo='SÍ'
  and lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) like '%macarron%'
order by rubro;


-- ================================================================
-- BLOQUE 2 — TODOS LOS QUE HOY NO ESTÁN SUMANDO
--
-- Cada fila es un producto del Congelador que NO tiene pareja con el
-- mismo nombre base en otra sección. O sea: alguien mira la vitrina,
-- ve poco, y no se entera de lo que hay guardado atrás. El macarron es
-- uno; acá salen todos los demás antes de que cuesten otro sobre-stock.
--
-- QUÉ VER: la columna "candidato" propone con qué producto de vitrina
-- podría emparejar. PROPONE, no concluye (regla 0.1.4).
-- ================================================================
with cong as (
  select id, producto, stock_actual,
         base_nombre(producto) as base,
         lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos
  where sede='plaza' and activo='SÍ' and rubro='Congelador'
),
otros as (
  select id, producto, rubro, stock_actual,
         base_nombre(producto) as base,
         lower(translate(producto,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')) as clave
  from public.productos
  where sede='plaza' and activo='SÍ' and rubro <> 'Congelador'
),
-- La palabra más larga sirve para buscar candidatos: en "Macarrons" es
-- "macarrons", y encuentra "Macarrons Vitrina de dulces".
cong_p as (
  select c.*, (select w from regexp_split_to_table(c.clave,'\s+') w
                where length(w) >= 5 order by length(w) desc, w limit 1) as palabra
  from cong c
)
select cp.producto                as en_el_congelador,
       cp.stock_actual            as stock_congelador,
       cp.base                    as su_nombre_base,
       coalesce((select string_agg(o.producto || '  (' || o.rubro || ', stock ' || coalesce(o.stock_actual,0)::text || ')', '   ·   ')
                   from otros o
                  where cp.palabra is not null and o.clave like '%'||cp.palabra||'%'),
                '— ninguno se le parece —') as candidato
from cong_p cp
where not exists (select 1 from otros o where o.base = cp.base)
order by cp.stock_actual desc nulls last, cp.producto;


-- ================================================================
-- BLOQUE 3 — RENOMBRAR PARA QUE SUMEN
--
-- ▼▼▼ EDITAR ANTES DE CORRER. Cambiar los ids y los nombres. ▼▼▼
--
-- LA REGLA: los dos tienen que quedar con el MISMO nombre y el apellido
-- de su sección. Ejemplo con los macarrons — reemplazar 111 y 222 por
-- los ids que salieron en el bloque 1:
--
--   update public.productos set producto='Macarrons Vitrina'
--    where id=111 and sede='plaza';
--   update public.productos set producto='Macarrons Congelador'
--    where id=222 and sede='plaza';
--
-- ⚠️ SIEMPRE con el "where id=" y el "and sede='plaza'". Un update sin
-- where cambia TODOS los productos de una vez y no hay vuelta atrás —
-- es el riesgo que más caro saldría de esta lista (§6 bloque A).
--
-- Después de renombrar, comprobar que ahora sí suman:
--
--   select base_nombre(producto) as nombre_base,
--          string_agg(producto || ' (' || rubro || ')', '  +  ') as productos,
--          sum(stock_actual) as total_que_va_a_ver_adriana
--   from public.productos
--   where sede='plaza' and activo='SÍ'
--     and base_nombre(producto) = 'Macarrons'
--   group by 1;
--
-- Tiene que salir UNA fila con los dos productos y la suma.
-- ================================================================


-- ---------- registro en el cuaderno ----------
insert into public.migraciones_aplicadas (archivo, quien, como_se_supo, nota)
values ('2026-08-macarrons-y-pares-sin-emparejar.sql', 'Jhon', 'lo corrió Jhon',
        'Diagnóstico de los pares vitrina/congelador que no suman. El caso macarrons costó un sobre-stock')
on conflict (archivo) do update set aplicado_at = now(), nota = excluded.nota;
