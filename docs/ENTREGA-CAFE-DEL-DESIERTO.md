# La foto de lo que usa Café del Desierto

> **Qué es este archivo.** El 2026-09-02 se decidió separar el proyecto en dos:
> Café del Desierto se queda con **Llamita Stock** tal como está en este punto,
> y Jhon se lleva **una copia** sobre la que sigue construyendo Llamita Lama
> para formar Llamita Plus.
>
> Este archivo marca **exactamente qué versión es la de ellos**. Sin esto,
> dentro de tres meses la pregunta *"¿qué les entregamos?"* no tiene respuesta.
> Es la misma lección de §0.6: **la foto se saca antes, no después.**

---

## La versión entregada

| | |
|---|---|
| **Commit** | `b4883c6` — *C8 · Los tres símbolos del teléfono, y con eso la F1 queda cerrada* |
| **Fecha** | 2026-09-02 |
| **Rama** | `master` — la que publica Vercel |
| **Base de datos** | proyecto Supabase `fqjdecjsbnicvyrxkxcu` |

Para ver el código exacto de ese momento:
`https://github.com/leoalejoleo1537/inventario-mall-plaza/tree/b4883c6`

## Qué hay en ese punto

**Llamita Stock, completo y en producción:** inventario multi-sede, bodega
central, reparto, mermas, recetas, enlaces, metas de venta, respaldo automático
dos veces al día, y el motor que descuenta desde las ventas de Fudo.

**Llamita Lama, escondida:** las mesas, el cobro, la anulación y el panel ya
construidos, detrás de `app_permisos.puede_lama`, que nace apagada para todos.
**Inerte para el equipo:** no toca el inventario, no aparece en la barra, y
nadie salvo la cuenta de trabajo puede verla.

## Qué pasa con Lama en la versión de ellos

**Se queda dormida, y a propósito.** Está escondida, no toca el stock, y tocar
un sistema congelado en producción para borrar código que no hace nada es más
riesgo que beneficio. Queda documentada acá para que nadie se pregunte, dentro
de un año, qué son esas tablas `mesas` y `cuentas` que nadie usa.

## Y lo que sigue, para la copia

El plan completo de la separación —las fases, la lista de peligro y las
comprobaciones que prueban que quedó separada de verdad— está en el plan de
trabajo de Jhon. Lo único que hay que recordar acá:

> **Nada de este lado se toca.** Ni el repositorio, ni la base, ni el Vercel,
> ni los crons, ni las Edge Functions. La única operación sobre este proyecto
> es **leer** un respaldo para clonarlo.
