# 05 · 🔥 Levantar Llamita desde cero

> **El peor caso.** Se perdió el proyecto de Supabase, o hay que montarlo en una
> cuenta nueva. Esta página es la receta completa.
>
> **Tiempo estimado:** una tarde. **Lo que hace falta:** las claves de Fudo de
> cada sede y, si se quiere recuperar los datos, los CSV de respaldo.

---

## Lo que se puede y lo que no

| | |
|---|---|
| **La app** | ✅ Se recupera entera desde GitHub. No se pierde nunca |
| **La estructura de la base** | ✅ Se reconstruye con los archivos de `sql/` |
| **Las funciones de Fudo** | ✅ Están en GitHub, se vuelven a pegar |
| **Los datos** | ⚠️ **Solo si hay respaldo.** Sin CSV y sin plan Pro, hay que volver a contar el inventario a mano |

> Por eso la página **08 · Registro de respaldos** existe, y por eso el respaldo
> automático de las 15:00 y las 22:00 no se apaga nunca.

---

## Paso 1 · Crear el proyecto de Supabase

1. Supabase → **New project**
2. Anotar la **contraseña de la base** en un lugar seguro. No se puede recuperar
3. Elegir la región más cercana (South America)

Del panel se necesitan dos cosas, que van en la app:

- **Project URL** (`https://xxxxx.supabase.co`)
- **Publishable key** (la clave pública, la que empieza con `eyJ…`)

> Esa clave es **pública a propósito**: va escrita dentro de la app y cualquiera
> la puede ver. Es una decisión tomada: la app lee y escribe sin sesión iniciada.
> Lo que toca sistemas externos (Fudo) sí lleva candado, y se comprueba en el
> servidor.

---

## Paso 2 · Levantar la estructura

En **SQL Editor → New query**, pegar y correr **en este orden**. Cada archivo
está en la carpeta `sql/` de GitHub y viene con sus instrucciones adentro.

### Los cimientos

| # | Archivo | Qué levanta |
|---|---|---|
| 1 | `2026-07-fase1-recetas-modo-prueba.sql` | Recetas, `fudo_sync`, `fudo_movimientos` y **el motor de descuento** |
| 2 | `2026-07-fase3a-tabla-fudo-productos.sql` | El espejo del catálogo de Fudo |
| 3 | `2026-07-lotes-vencimiento.sql` | Las fechas de vencimiento |
| 4 | `2026-07-secciones-inventario.sql` | Las secciones |
| 5 | `2026-07-tipo-de-producto.sql` | Los tipos |
| 6 | `2026-07-productos-urgentes.sql` | La marca de urgente |
| 7 | `2026-07-repartos.sql` | Los repartos entre sedes |
| 8 | `2026-07-historial-dias.sql` | El historial agrupado por día |
| 9 | `2026-07-permisos-y-deshacer.sql` | `app_permisos` y la bitácora de empujes |
| 10 | `2026-07-stock-para-fudo-v3-suma-el-par.sql` | El cálculo de cuánto se puede vender |
| 11 | `2026-07-tope-cero-sin-excepcion.sql` | **El stock nunca puede ser negativo** |
| 12 | `2026-07-registro-de-migraciones.sql` | El cuaderno de vacunas |

### La bodega

| # | Archivo |
|---|---|
| 13 | `2026-08-bodega-cimientos.sql` |
| 14 | `2026-08-bodega-nueva-desde-cero.sql` |
| 15 | `2026-08-central-enlaces.sql` |
| 16 | `2026-08-central-mermas.sql` |
| 17 | `2026-08-central-reparto-descuenta.sql` |

### La zona de Ajustes

| # | Archivo |
|---|---|
| 18 | `2026-08-interruptores.sql` |
| 19 | `2026-08-ajustes-quien-entra.sql` |
| 20 | `2026-08-permisos-desde-la-app.sql` |
| 21 | `2026-08-secciones-y-fudo-desde-ajustes.sql` |
| 22 | `2026-08-metas-de-venta.sql` |
| 23 | `2026-08-categorias-de-fudo.sql` |
| 24 | `2026-08-dias-con-foto.sql` |

### Lo automático — va al final

| # | Archivo | Qué enciende |
|---|---|---|
| 25 | `2026-08-respaldo-automatico-de-verdad.sql` | La foto de las 15:00 y las 22:00 |
| 26 | `2026-08-ciclo-fudo-automatico.sql` | El ciclo con Fudo cada 15 minutos |

> ⚠️ **El ciclo va último y no antes.** Si se enciende con el inventario vacío,
> le manda ceros a Fudo y el mesón no puede vender nada.

---

## Paso 3 · Las funciones que hablan con Fudo

Supabase → **Edge Functions** → **Deploy a new function**. Se copia el contenido
de cada carpeta de `supabase/functions/` en GitHub y se pega.

| Función | Para qué |
|---|---|
| `fudo-sync-productos` | Trae el catálogo de Fudo |
| `fudo-sync-ventas` | Lee las ventas y las pasa por el motor |
| `fudo-empujar-stock` | Le manda a Fudo el inventario entero |
| `fudo-sumar-stock` | Le suma a Fudo lo que llegó en un reparto |
| `fudo-deshacer-stock` | Revierte el último empuje |
| `fudo-ciclo` | Une ventas + empuje, **en ese orden** |
| `fudo-crear-producto` | Crea un producto en Fudo y su receta |
| `fudo-activar-producto` | Enciende y apaga productos en Fudo |

> Las que empiezan con `fudo-probar-` son pruebas viejas. No hace falta
> desplegarlas.

### Los secretos

Supabase → Edge Functions → **Secrets**:

```
FUDO_PLAZA_APIKEY
FUDO_PLAZA_APISECRET
FUDO_ANGAMOS_APIKEY
FUDO_ANGAMOS_APISECRET
SISTEMA_TOKEN
```

> **Los nombres no son libres.** El código los arma con el nombre de la sede en
> mayúsculas: `FUDO_${SEDE}_APIKEY`. Si la sede es `angamos`, el secreto tiene
> que llamarse `FUDO_ANGAMOS_APIKEY` y nada más.
>
> `SISTEMA_TOKEN` es cualquier texto largo inventado. Es la llave con la que el
> reloj firma cuando no hay ninguna persona apretando el botón.

Las claves de Fudo se piden en el panel de Fudo de cada local.

---

## Paso 4 · Conectar la app

En `index.html`, cerca del principio, están la dirección y la clave de Supabase.
Se reemplazan por las del proyecto nuevo, se guarda el cambio en la rama
`master`, y Vercel publica solo.

> **Antes de guardar, comprobar que la dirección de la librería de Supabase
> abre de verdad en el navegador.** Si se escribe mal, la app deja de cargar
> entera y no hay ninguna pista de por qué.

---

## Paso 5 · Devolver los datos

### Si hay CSV de respaldo

Supabase → Table Editor → la tabla → **Import data from CSV**.

**El orden importa**, porque unas tablas apuntan a otras:

```
1. productos
2. producto_lotes
3. recetas
4. receta_items
```

> Si al importar `receta_items` da un error de llave, es que falta alguna receta
> o algún producto. Se importa lo que falte primero.

### Si no hay respaldo

Hay que cargar el inventario a mano desde la app: crear los productos, poner
mínimos y máximos, y contar el stock. Las recetas se rehacen desde la pestaña
Recetas.

**Es una semana de trabajo del equipo.** Por eso el respaldo no es opcional.

---

## Paso 6 · Encender, en el orden correcto

Esto no es un detalle: **encender en el orden equivocado le manda ceros a Fudo**
y deja el mesón sin poder vender.

1. **Las dos sedes en `prueba`:**

```sql
update public.fudo_sync set modo = 'prueba' where sede in ('plaza','angamos');
```

2. **Traer el catálogo de Fudo** — desde la app, botón ⟳.

3. **Cargar el inventario** — CSV o a mano.

4. **Comprobar que las recetas descuentan bien.** En `prueba` las ventas se
   anotan pero el stock no se toca, así que se puede mirar sin riesgo:

```sql
select m.created_at, m.sede, m.producto_nombre, m.cantidad_vendida, m.aplicado
from public.fudo_movimientos m
order by m.created_at desc limit 50;
```

> En modo `prueba`, que **todo diga `aplicado = false` es lo normal.**

5. **Pasar a `real`** — desde Ajustes → Fudo, una sede a la vez.

6. **Encender el reloj**, y recién ahí la vigilancia:

```sql
-- a los 20 minutos, comprobar que corrió SOLO:
select sede, ultima_corrida_at, ultima_corrida_por, ultimos_items, ultimos_errores
from public.fudo_sync order by sede;
```

> Tiene que decir **`ultima_corrida_por = 'cron'`**. Recién con eso confirmado
> se enciende la vigilancia desde Ajustes → Fudo. Al revés, la app se pone en
> rojo sin motivo.

7. **Guardar la primera foto**: app → Historial → *Guardar inventario de hoy*,
   en las tres sedes.

---

## Paso 7 · Comprobar que quedó bien

```sql
-- una sola versión del motor
select p.oid::regprocedure from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'fudo_procesar_item';

-- el candado del stock negativo
select conname from pg_constraint
where conrelid = 'public.productos'::regclass and contype = 'c';

-- las tablas que avisan en vivo
select tablename from pg_publication_tables
where pubname = 'supabase_realtime' order by tablename;

-- los relojes
select jobname, schedule, active from cron.job order by jobname;
```

Y desde la app: **Ajustes → Salud del sistema**, que dice lo mismo sin SQL.

---

## La prueba que de verdad vale

**Vender algo de verdad en Fudo y ver que baja en la app.**

Ninguna consulta reemplaza eso. Es la única prueba que confirma que las tres
piezas —Fudo, el motor y la app— están hablando entre sí.
