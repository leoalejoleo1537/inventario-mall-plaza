# 08 · Registro de respaldos

> **Para qué existe esta página.** Para que nunca haya que preguntarse "¿tenemos
> respaldo?". Si la respuesta hay que buscarla, la respuesta es no.

---

## Lo que corre solo, sin que nadie haga nada

| Cuándo | Qué guarda | Dónde |
|---|---|---|
| **15:00 y 22:00**, todos los días | Nombre, sección, stock, mínimo, máximo y si está activo — de **cada producto de las tres sedes** | Dentro de la misma base, en `historial_auto` |

Se ve en la app: **Ajustes → Respaldos**, y desde ahí se puede volver una sede a
como estaba cualquiera de esos días.

> ⚠️ **Esto es la red del inventario, no de la base entera.** Si se perdiera el
> proyecto de Supabase completo, esta foto se iría con él. Para eso están los
> CSV de abajo.

### Cómo se comprueba que está corriendo

**En la app:** Ajustes → Respaldos. Arriba de la lista de días hay una franja
que lo dice en una frase: verde si la red está puesta, roja si hace tres días
o más que no se saca sola.

**Con SQL**, si se quiere el detalle día por día y sede por sede:
`sql/2026-08-esta-corriendo-el-respaldo.sql`.

> Mirar la lista de fechas **no alcanza**: un día con foto automática y conteo
> a mano se veía solo como "contada a mano", y la automática quedaba escondida
> detrás. Por eso ahora se cuentan por separado.

---

## Lo que hay que hacer a mano

### Cada cierto tiempo, y siempre antes de un cambio grande

Correr **`sql/2026-08-respaldo-CUATRO-ARCHIVOS.sql`**, y correr **cada bloque
por separado**. Después de cada uno, botón **Download CSV** arriba a la derecha
del resultado.

> ⚠️ **No pegar el archivo entero y apretar Run una sola vez.** El editor de
> Supabase corre todo pero **muestra solo el resultado de la última consulta**:
> las cuatro copias se generan y se pierden, y en pantalla queda una línea
> suelta. Parece que no funcionó. Funcionó — no había dónde verlo.

Los cuatro archivos se **guardan acá, adjuntos a esta página**:

| Archivo | Qué es |
|---|---|
| `productos.csv` | El inventario entero de las tres sedes |
| `recetas.csv` | Qué producto de Fudo descuenta qué |
| `receta_items.csv` | Los ingredientes de cada receta |
| `producto_lotes.csv` | Las fechas de vencimiento |

**Cuándo hacerlo, sin falta:**

- Antes de cualquier tanda de renombres o de cambios masivos
- Antes de encender una sede nueva
- El día de un traspaso
- Una vez al mes, aunque no pase nada

---

## La tabla del registro

> Crear acá una tabla de Notion con estas columnas y **una fila por respaldo**.
> Adjuntar los CSV en la fila.

| Fecha | Quién | Qué se guardó | Motivo | Archivos |
|---|---|---|---|---|
| | | productos · recetas · receta_items · lotes | rutina / antes de un cambio / traspaso | *(adjuntos)* |

---

## Cómo se comprueba que un respaldo sirve

**Un respaldo que nunca se probó no es un respaldo.** Lo único que confirma que
sirve es haberlo restaurado alguna vez.

Se probó en julio de 2026: se respaldó, se vaciaron las tablas, se restauró, y
quedó todo igual — incluidos los nombres con tildes y comillas, y los enlaces
entre recetas y productos.

Vale la pena repetirlo **una vez al año**, sobre un proyecto de prueba, no sobre
el real.

---

## Lo que un respaldo NO cubre

| | |
|---|---|
| Las claves de Fudo | Están dentro de Supabase y **no se pueden volver a leer**. Hay que anotarlas aparte (ver **06 · Las llaves**) |
| La contraseña de la base | Se define al crear el proyecto y no se recupera |
| Las Edge Functions | Están en GitHub. Se vuelven a pegar |
| El historial de ventas de Fudo | Vive en Fudo, no acá |

---

## El plan Pro de Supabase

**~25 USD al mes**, y es la única forma de tener **respaldo diario automático de
la base entera** con punto de restauración.

En el plan gratuito **no hay a dónde volver**. La red es la foto de las 15:00 y
las 22:00 —que cubre el inventario— más los CSV que alguien se acuerde de
guardar acá.

> Es la decisión más barata del proyecto y la que más caro sale no haber tomado.
