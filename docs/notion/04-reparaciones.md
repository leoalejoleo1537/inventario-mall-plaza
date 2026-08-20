# 04 · 🚑 Reparaciones

> **Cuando algo anda mal.** Cada caso trae el síntoma tal como se ve en pantalla,
> qué es en realidad, y el código exacto para arreglarlo.
>
> **Todo lo que dice `SQL` se pega en:** Supabase → SQL Editor → New query → Run.

---

## ⚠️ Antes de tocar nada — las dos reglas

### 1. Saca la foto primero

**Antes de cualquier arreglo que escriba en la base**, guarda una foto de la
sede: app → Historial → **Guardar inventario de hoy**.

Es la copia más barata que existe, y es la diferencia entre "se arregló" y "se
perdió". El 9 de agosto Angamos quedó en cero y no se pudo restaurar **nada**,
porque no había ninguna foto que restaurar.

Se comprueba que exista con esto:

```sql
select fecha, count(*) as productos
from public.historial
where sede = 'angamos'
group by fecha order by fecha desc limit 5;
```

Si no devuelve filas, **no escribas nada** hasta que haya una foto.

### 2. Mira antes de concluir

Que un archivo `.sql` esté en GitHub **no significa que se haya corrido**. La
base cambia desde la app sin dejar rastro en el código.

Antes de afirmar algo sobre el estado de los datos, consúltalo:

```sql
select archivo, aplicado_at, quien, nota
from public.migraciones_aplicadas
order by aplicado_at desc limit 20;
```

> El cuaderno sirve para saber **qué SÍ se hizo**. Nunca para concluir que algo
> no se hizo: hay cosas viejas sin anotar.

---

## 🩺 El chequeo general — empieza siempre por acá

Antes de diagnosticar nada, corre esto. Son 10 filas que dicen el estado de
todo el sistema.

**Archivo:** `sql/2026-07-salud-del-sistema.sql`, **solo el bloque 0**.

O desde la app: **Ajustes → Salud del sistema**, que muestra lo mismo sin SQL.

---

## Caso 1 · "El inventario no se está descontando"

**Se ve así:** una ventana al apretar ⟳, con ese texto y un número de errores.

**Es la alarma más seria del sistema** y aparece a propósito: en julio esto
estuvo fallando **15 horas** sin que nada lo dijera, porque la app mostraba "✓"
igual.

### Qué mirar, en orden

**a) ¿Hay dos versiones del motor conviviendo?**

Es la causa más común y la más silenciosa. Desde SQL el motor funciona perfecto,
pero la app llama por otro camino y ahí el nombre queda ambiguo: la llamada se
rechaza antes de ejecutar nada.

```sql
select p.oid::regprocedure as firma
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'fudo_procesar_item';
```

> **Tiene que devolver UNA sola fila.** Si devuelve dos o más, correr
> `sql/2026-07-URGENTE-dos-motores.sql`.

**b) ¿Le falta una columna a la tabla de movimientos?**

```sql
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'fudo_movimientos'
order by column_name;
```

> Tiene que aparecer **`venta_at`** y **`aplicado`**. Si falta `venta_at`,
> correr `sql/2026-07-URGENTE-falta-venta-at.sql`.

**c) ¿La sede está en modo prueba?**

En `prueba` el motor anota las ventas pero **no toca el stock**. Que todo diga
`aplicado = false` ahí es **lo normal**, no una falla.

```sql
select sede, modo, cron_activo, ultima_corrida_at, ultima_corrida_por,
       ultimo_resultado, ultimos_items, ultimos_errores, ultimos_movimientos
from public.fudo_sync order by sede;
```

Se cambia desde **Ajustes → Fudo**, sin SQL.

---

## Caso 2 · Fudo vende algo que ya no hay

**Casi siempre es que a ese producto le falta la receta.** Sin receta el sistema
no sabe qué descontar, y Fudo lo sigue vendiendo sin límite.

No es un dato corrupto: es cobertura que falta. Se arregla en la pestaña
**Recetas**.

### Ver cuánto falta

```sql
select r.sede,
       count(distinct r.fudo_product_id) as con_receta,
       (select count(*) from public.fudo_productos f
         where f.sede = r.sede and f.activo) as en_la_carta
from public.recetas r
where r.activo group by r.sede;
```

### Recetas que apuntan al vacío

Una receta que descuenta de un producto que ya no existe. Descuenta nada y
cuenta como "resuelta", así que nadie la busca.

```sql
select r.sede, r.fudo_product_nombre, ri.producto_id as producto_que_no_esta
from public.receta_items ri
join public.recetas r on r.id = ri.receta_id
left join public.productos p on p.id = ri.producto_id
where p.id is null
order by r.sede, r.fudo_product_nombre;
```

---

## Caso 3 · Un cambio de la app no llega al teléfono

**Casi siempre quedó sin fusionar a `master`.** Vercel publica esa rama y
ninguna otra.

1. GitHub → comprobar que el cambio esté en `master`
2. Vercel → comprobar que el último despliegue diga *Ready*
3. En el teléfono: cerrar la app del todo y volver a abrirla

> La app **no guarda copias viejas** a propósito, así que nunca se queda pegada
> en una versión anterior. Si no llegó, es que no se publicó.

---

## Caso 4 · Un permiso que no se guarda

**Se ve así:** se le da acceso a alguien, dice "✓ Ahora entra a Ajustes", y al
recargar volvió a estar apagado.

**Qué es:** la tabla de permisos tiene la puerta cerrada para escribir. Y una
escritura que la puerta no deja pasar **no da error**: contesta "listo, cambié
cero filas".

Desde el 20 de agosto la app se da cuenta y avisa. El arreglo de fondo:

```sql
drop policy if exists "app_permisos alta"   on public.app_permisos;
drop policy if exists "app_permisos cambio" on public.app_permisos;

create policy "app_permisos alta" on public.app_permisos
  for insert to authenticated with check (true);

create policy "app_permisos cambio" on public.app_permisos
  for update to authenticated using (true) with check (true);

grant insert, update on public.app_permisos to authenticated;
```

### Y si te quedaste afuera de Ajustes

Si nadie tiene acceso, se devuelve desde acá:

```sql
insert into public.app_permisos (correo, nombre, puede_ajustes, puede_fudo, puede_editar)
values ('EL-CORREO@ejemplo.cl', 'Nombre', true, true, true)
on conflict (correo) do update set puede_ajustes = true;
```

---

## Caso 5 · El stock y las fechas no cuadran

**Se ve así:** un sándwich en 0 que muestra "1 vence hoy".

En un producto con fechas, **el stock es la suma de sus fechas**. Si no cuadra,
hay un descuadre.

### Ver cuáles

```sql
select p.id, p.sede, p.producto,
       p.stock_actual,
       coalesce(sum(l.cantidad), 0) as suma_de_fechas
from public.productos p
left join public.producto_lotes l on l.producto_id = p.id
where p.activo = 'SÍ'
group by p.id, p.sede, p.producto, p.stock_actual
having p.stock_actual <> coalesce(sum(l.cantidad), 0)
order by p.sede, p.producto;
```

### Quién manda cuando no cuadra

| Situación | Quién manda |
|---|---|
| Alguien **agrega o edita fechas** | **Las fechas.** El stock se calcula sumándolas |
| El producto quedó en **stock 0** y le sobran fechas | **El stock.** Las fechas se borran: no hay unidades que puedan vencer |

Una fecha con cantidad 0 **no es una fecha**: es una fila que quedó vacía al
descontar. Se borra.

```sql
-- primero mirar qué se va a borrar
select l.*, p.producto, p.sede
from public.producto_lotes l join public.productos p on p.id = l.producto_id
where l.cantidad <= 0;

-- y recién después, en otro Run:
delete from public.producto_lotes where cantidad <= 0;
```

---

## Caso 6 · Las fechas no se actualizan solas en otro teléfono

**Se ve así:** se vende un sándwich, el stock baja en el otro teléfono pero las
fechas se quedan viejas.

**Qué es:** la tabla de fechas no está en la lista de "avisar en vivo".

```sql
select tablename from pg_publication_tables
where pubname = 'supabase_realtime' order by tablename;
```

> Tienen que estar por lo menos `productos`, `producto_lotes`, `repartos` y
> `reparto_items`. Si falta alguna:

```sql
alter publication supabase_realtime add table public.producto_lotes;
```

---

## Caso 7 · Un producto duplicado

El mismo producto cargado dos veces. Las jefas cuentan una vez en cada ficha, el
stock queda partido, y a Fudo se le manda el de una sola.

**Desde la app:** Ajustes → Productos → *Juntar duplicados*. Propone los pares
y muestra qué va a pasar antes de hacerlo. **Se puede deshacer.**

**Para verlos con SQL:**

```sql
select sede, lower(translate(producto,'áéíóúÁÉÍÓÚ','aeiouAEIOU')) as clave,
       count(*) as cuantos, string_agg(id::text || ' · ' || producto, '  |  ') as fichas
from public.productos
where activo = 'SÍ'
group by sede, clave
having count(*) > 1
order by sede, clave;
```

---

## Caso 8 · Volver una sede a como estaba un día

**Desde la app:** Ajustes → Respaldos. Se elige la sede, el día, y muestra
**producto por producto** qué cambiaría antes de tocar nada. Se puede deshacer.

> Es la herramienta más importante de esta página. Antes de usarla, **guarda
> una foto de hoy**: restaurar sobre un estado sin respaldar es cómo un
> incidente se convierte en dos.

### Ver qué días hay disponibles

```sql
select * from public.fotos_por_dia('plaza');
```

---

## Caso 9 · El reloj dejó de correr

**Se ve así:** una franja bajo las pestañas diciendo que hace horas que no
sincroniza. Solo la ve administración.

### ¿Están agendadas las tareas?

```sql
select jobid, jobname, schedule, active
from cron.job order by jobname;
```

> Tienen que estar: el ciclo de Fudo (cada 15 min) y las dos fotos del
> inventario (`0 19 * * *` y `0 2 * * *`, que en hora de Antofagasta son las
> 15:00 y las 22:00).

### ¿Corrieron, y qué contestaron?

```sql
select r.status_code as codigo, r.content, r.created
from net._http_response r
order by r.created desc limit 10;
```

> Si aparece **"Falta el secret SISTEMA_TOKEN"**, hay que crearlo:
> Supabase → Edge Functions → Secrets → `SISTEMA_TOKEN` con cualquier texto largo.

---

## Caso 10 · El editor de Supabase dice "No se pudo obtener"

**No es un error de SQL.** Es el editor, que se atraganta.

Se reconoce porque **el error nombra la API de Supabase y no habla de sintaxis
ni de tablas**. Si dijera "relation does not exist" sería SQL.

Dos causas conocidas:

| | Solución |
|---|---|
| El script tiene el símbolo `$` | Ese bloque se corre **solo**, sin nada más |
| Una sola instrucción de más de ~5.000 caracteres | Partirla en dos |

**Y una tercera trampa:** no se puede **crear una tabla y usarla en la misma
corrida**. Va en dos Run separados.

**Y una cuarta:** el editor muestra **solo el resultado de la última consulta**.
Un bloque con dos `select` entrega uno y pierde el otro en silencio.

---

## Caso 11 · Aparece stock negativo

**No debería poder pasar.** La base misma lo rechaza:

```sql
select conname, pg_get_constraintdef(oid) as regla
from pg_constraint
where conrelid in ('public.productos'::regclass, 'public.producto_lotes'::regclass)
  and contype = 'c';
```

> Tienen que aparecer `stock_actual >= 0` y `cantidad >= 0`. Si no están, se
> vuelven a poner corriendo `sql/2026-07-tope-cero-sin-excepcion.sql`.

---

## 🧯 El botón rojo — parar todo sin romper nada

Si algo está pasando y no se sabe qué, **lo primero es dejar de escribir en
Fudo**, no apagar el sistema.

```sql
-- las ventas se siguen anotando, pero el stock deja de moverse
update public.fudo_sync set modo = 'prueba' where sede in ('plaza','angamos');
```

Y para que el reloj deje de correr:

```sql
select cron.unschedule(jobname) from cron.job
where jobname like '%ciclo%' or jobname like '%sync%';
```

> **La foto del inventario NO se apaga.** Es la red, y una red que se apaga por
> accidente no es una red.

Para volver a encender: `modo = 'real'` y volver a agendar con
`sql/2026-08-ciclo-fudo-automatico.sql`.
