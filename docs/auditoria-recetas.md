# Depuración de recetas — el plan

> Las recetas son el corazón del proyecto: si están mal, el stock miente y
> cualquier dashboard construido encima mide humo. Esto va **antes** del
> dashboard (`docs/dashboard-analisis-posibles.md`).

## El problema, en concreto

Hay desalineación en las dos direcciones y nadie la ve:

- Productos creados **en el inventario** que quizá no existen en Fudo.
- Productos **en Fudo** que no están en el inventario.
- Productos en Fudo que **ya no se venden** pero siguen ahí metiendo ruido.
- **Combos** (Llamita KIDS, desayunos, "sándwich + bebida") que deberían
  descontar varios insumos y hoy descuentan uno o ninguno.
- Recetas que existen pero están **vacías** — invisibles, tan malas como no tener.
- Recetas que apuntan a un insumo **eliminado** del inventario.

Mientras no se vea el tamaño real de cada hueco, depurar es adivinar.

## Paso 1 — Ver (hecho): `sql/2026-07-auditoria-recetas.sql`

Informe de **solo lectura**. No crea, no borra, no modifica. Se corre en
Supabase → SQL Editor y devuelve 10 tablas:

| Bloque | Qué muestra | Para qué |
|---|---|---|
| 0 | Resumen: cuántos productos en Fudo, cuántos en inventario, cuántas recetas, cuántas vacías | el tamaño del problema |
| 1 | 🔴 **Se vendió y no descontó nada** — con unidades y última vez | lo que está fallando AHORA |
| 2 | Productos activos en Fudo sin receta (marca los que parecen combo) | lo que va a fallar |
| 3 | Recetas vacías | huecos invisibles |
| 4 | Recetas de productos que ya no existen o están inactivos en Fudo | ruido a borrar |
| 5 | Recetas rotas: apuntan a un insumo eliminado | descuentos que se pierden |
| 6 | Inventario que ninguna receta descuenta | normal en limpieza, raro en comida |
| 7 | Sugerencias: el nombre calza y no están emparejados | trabajo automatizable |
| 8 | Combos sospechosos: el nombre sugiere varios ítems y descuenta ≤ 1 | Llamita KIDS y compañía |
| 9 | **% de cobertura**: cuánto de lo que se vende sí descuenta | la métrica de avance |

El bloque 9 es el marcador: se corre hoy, se anota el porcentaje, y se vuelve a
correr después de cada tanda de limpieza para ver si sube.

## Paso 2 — Ordenar el trabajo

El informe separa lo que se arregla **solo** de lo que necesita criterio humano:

- **Automático:** bloque 7 (nombres que calzan) → una pasada del emparejador.
- **Borrar sin pensar:** bloques 4 y 5 (productos muertos, recetas rotas).
- **A mano, uno por uno:** bloques 2, 3 y 8 — sobre todo los combos, porque hay
  que decidir qué insumos lleva cada uno. Nadie más que el equipo lo sabe.

Prioridad dentro de "a mano": ordenar por **unidades vendidas** (bloque 1). Un
producto que vendió 200 unidades sin descontar hace más daño que veinte que
vendieron una.

## Paso 3 — Limpiar Fudo (tarea de Jhon, en paralelo)

Mientras Fudo tenga productos que ya no se venden, el informe va a mostrar ruido.
Cada producto dado de baja en Fudo desaparece solo del bloque 2 en la siguiente
sincronización (botón "↻ Productos de Fudo").

## Pendiente / a decidir

- [ ] ¿Llevar este informe a una pantalla dentro de la app, para que el equipo
      lo vea sin entrar a Supabase?
- [ ] ¿Editar combos desde la app con varios insumos de una? Hoy se puede, pero
      hay que agregarlos de a uno.
- [ ] Recordar: al terminar cada tanda, correr el bloque 9 y anotar el %.
