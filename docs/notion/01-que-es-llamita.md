# 01 · Qué es Llamita

> Un inventario de café conectado al punto de venta. Reemplazó las planillas de
> Excel que se llevaban a mano.

---

## Las tres cosas que hace, y que el Excel no hacía

### 1. Descuenta solo

Cuando se vende un cappuccino en Fudo, la leche y el vaso bajan del inventario
**sin que nadie anote nada**.

Lo hace una lista de **recetas**: cada producto de la carta dice qué insumos
gasta y cuánto. Un cappuccino descuenta 1 vaso y 0,2 litros de leche; un
sándwich descuenta 1 pan y 1 relleno.

Cada 15 minutos el sistema le pregunta a Fudo qué se vendió, busca la receta de
cada cosa vendida y baja esos insumos.

### 2. Le devuelve el stock a Fudo

El camino de vuelta. Cada 15 minutos le manda a Fudo **cuánto queda de verdad**,
para que no se venda lo que ya no hay.

Antes eso se hacía a mano, producto por producto, y por eso se ponía "1.000" de
todo: era la única forma de que Fudo no bloqueara las ventas.

> ⚠️ **El orden importa y no es negociable.** Primero se leen las ventas y se
> descuenta; recién después se empuja el stock. Al revés, se le mandaría a Fudo
> un número que todavía no descontó lo vendido, y Fudo volvería a subir el stock
> de algo que ya se vendió.

### 3. Muestra las tres sedes en vivo

Jefatura ve el stock real desde el teléfono, con las fechas de vencimiento de
cada sándwich a la vista. Sin llamar a nadie y sin abrir un Excel.

---

## Las tres sedes

| En pantalla | Nombre interno | Qué es |
|---|---|---|
| Café Mall Plaza | `plaza` | Local. Vende, descuenta y le escribe a Fudo |
| Parque Angamos | `angamos` | Local. Igual que Plaza, con su propia cuenta de Fudo |
| Bodega | `central` | Abastece a los dos locales. No vende |

> ⚠️ **Cuidado con una palabra.** Existe una cuarta sede, `bodega`, que es **la
> bodega vieja**. Ya no se ofrece en la app, pero sigue en la base con todo su
> historial porque hay repartos y recetas antiguas que apuntan ahí.
> **Una fila que diga `bodega` es la vieja. Siempre. No se toca y no se borra.**

---

## Las piezas, y dónde vive cada una

| Pieza | Qué es | Dónde |
|---|---|---|
| **La app** | Un solo archivo HTML. No se instala nada, se abre una dirección web | `index.html` en GitHub → Vercel publica la rama `master` |
| **La base de datos** | Productos, stock, recetas, repartos, historial, permisos | Supabase (PostgreSQL) |
| **El puente con Fudo** | 8 funciones que hablan con la API de Fudo | Supabase → Edge Functions |
| **Los relojes** | Las 3 tareas automáticas | Supabase → Database → Cron |
| **Las claves de Fudo** | Una por sede | Supabase → Edge Functions → Secrets |

---

## Las tablas de la base, en castellano

| Tabla | Qué guarda |
|---|---|
| `productos` | El inventario. Una fila por producto y por sede |
| `producto_lotes` | Las fechas de vencimiento. Una fila por fecha |
| `recetas` + `receta_items` | Qué descuenta cada producto de Fudo al venderse |
| `repartos` + `reparto_items` | Los envíos de bodega a los locales |
| `historial` | Las fotos del inventario, contadas a mano |
| `historial_auto` | Las fotos automáticas de las 15:00 y 22:00 |
| `movimientos` | El libro de mermas y entradas de bodega |
| `fudo_sync` | El modo (prueba/real) y el estado del reloj, por sede |
| `fudo_movimientos` | Cada ítem vendido, con su cantidad y su fecha |
| `fudo_productos` | Una copia local del catálogo de Fudo |
| `app_permisos` | Quién entra a Ajustes |
| `secciones` | El orden de las secciones y su turno AM/PM |
| `ajustes` | Los interruptores |
| `metas` + `meta_productos` | Las metas de venta |
| `migraciones_aplicadas` | **El cuaderno de vacunas**: qué scripts se corrieron |

---

## Dos ideas que hay que entender antes de tocar nada

### Las recetas se unen por número, no por nombre

Una receta apunta al **identificador** del producto, no a su nombre.
**Renombrar un producto no rompe nada**: el descuento sigue funcionando igual.

Esto importa porque el error más repetido de este proyecto fue mirar dos nombres
que no coincidían y concluir que algo estaba mal. Un nombre raro es una pregunta
para el equipo, no un hallazgo.

### El sistema prefiere ir atrasado antes que inventar

Un inventario puede ir atrasado respecto a la realidad —eso se corrige
contando—, pero **no puede inventar movimientos**.

Por eso se apagó una función que trasladaba producto del congelador a la vitrina
automáticamente: la app decía que la vitrina tenía cuatro cuando el estante
estaba vacío. Un número inventado que parece exacto es peor que un número
atrasado que todos saben que hay que contar.
