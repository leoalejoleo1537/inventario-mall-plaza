# 🦙 Llamita — Central de conocimiento

> **Qué es esta página.** Todo lo que hay que saber sobre el sistema de inventario
> de Café del Desierto: cómo se usa, cómo se administra, qué hacer cuando algo
> falla y cómo levantarlo desde cero si un día se pierde todo.
>
> Si el código vive en GitHub, **el porqué vive acá**.

---

## Por dónde empezar

| Si eres… | Lee |
|---|---|
| Jefe de turno o barista | **02 · Manual de uso** |
| Administración | **02**, después **03 · Ajustes** |
| El que tiene que arreglar algo ahora | **04 · Reparaciones** |
| El que recibe el proyecto | **06 · Las llaves**, después **01** |
| Un programador nuevo | **01**, **07 · Las reglas**, y `CLAUDE.md` en GitHub |

---

## Las páginas

- **01 · Qué es Llamita** — cómo funciona por dentro, en castellano
- **02 · Manual de uso** — la app, pantalla por pantalla
- **03 · Manual de administración** — la zona de Ajustes
- **04 · 🚑 Reparaciones** — los síntomas, y el código para arreglarlos
- **05 · 🔥 Levantar Llamita desde cero** — el peor caso, paso a paso
- **06 · Las llaves y las cuentas** — qué hay que tener y a nombre de quién
- **07 · Las reglas que no se tocan** — y la falla real que produjo cada una
- **08 · Registro de respaldos** — la tabla donde se anota cada copia guardada

---

## Los tres números que hay que saber de memoria

| | |
|---|---|
| **15 minutos** | cada cuánto el sistema lee las ventas de Fudo y le devuelve el stock |
| **15:00 y 22:00** | cuándo se saca sola la foto del inventario de las tres sedes |
| **1.000 filas** | lo máximo que Supabase devuelve de una vez. Nunca avisa cuando corta |

---

## Cómo se mantiene esta página

Cuando se cambie algo importante en el sistema, se actualiza acá **el mismo
día**. Una página de estado que envejece engaña más que no tenerla: alguien la
va a leer con toda confianza y va a planificar sobre algo que ya no existe.

Eso ya pasó una vez en este proyecto y costó una jornada de trabajo.
