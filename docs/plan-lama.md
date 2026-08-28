# LLAMITA LAMA — el plan, al 2026-08-28

> **Llamita Stock** sabe qué hay. **Llamita Lama** sabe qué se vende.
> Lama es el área de ventas —mesas, comandas y cobro— y es lo que hoy hace Fudo.

---

## Por qué existe

1. **Hay otra empresa interesada en comprar Llamita Stock**, y para venderlo
   hace falta que el producto esté completo.
2. Con Lama terminada, **Café del Desierto puede soltar Fudo del todo**. Y con
   Fudo desaparece la capa entera de pelear con dos sistemas: recetas que no
   calzan por un nombre, combos que no capturan la elección del cliente,
   ventas que hay que ir a leer con una Edge Function.

**Se copia la forma de Fudo a propósito.** El equipo ya sabe usar esa
pantalla; imitarla hace que la curva de aprendizaje sea casi cero.

**Y se construye escondida.** Jhon: *"si algo falla aquí, podríamos perder o
entorpecer todo un día de ventas, necesito trabajar tranquilo."*

---

## LAS REGLAS DE ESTE PROYECTO

### 1. No se toca NADA de Llamita Stock

> Jhon: *"lo más importante es que no se toque nada de Llamita Stock."*

Ni una pantalla, ni una función, ni una tabla, ni un `.sql` que ya corrió.
Incluye lo que parece inofensivo: renombrar una variable, mover una función,
"aprovechar y arreglar" algo que se ve mal al pasar.

**Dos razones.** Stock está en producción y Lama no: si algo se rompe, el daño
cae sobre gente que está trabajando. Y una de método: **si Stock no se toca,
nada que falle en Stock puede ser culpa del chat de Lama.** Eso es lo que hace
el trabajo diagnosticable.

**Lo que sí se toca:** `sql/2026-08-lama-*.sql`, las cuatro tablas de Lama, en
`index.html` **solo** la vista `view-lama` y las funciones que empiezan por
`lama`, y `pruebas/lama-*.mjs`.

**Los cuatro enganches que ya existen y no se vuelven a modificar:**
`tabLama` (nace `display:none`) · `TITULOS.lama` · la línea de `pickTab` y la
de `pickSede` · el campo `puede_lama` en `permisosDeLaSede`.
Si hiciera falta **otro** enganche, se pregunta primero.

### 2. Las conexiones van al FINAL

> Jhon: *"las conexiones no las vamos a hacer hasta que el proyecto esté
> totalmente acabado."*

Lo más tentador es lo primero que hay que NO hacer: **que cerrar una mesa
descuente el inventario.** Es la razón de fondo del proyecto entero y aun así
va última, con interruptor, y solo cuando las comandas sean confiables.

Hoy Lama **no toca el stock** — y eso es justamente lo que permite abrir y
cerrar mesas veinte veces mientras se prueba, sin descuadrar nada.

Lo mismo vale para escribirle a Fudo desde Lama y para leer recetas.

### 3. Sigue escondida

La puerta es `app_permisos.puede_lama`, que **nace apagada para todos**. Hoy
solo la tiene `leoalejoleo12@gmail.com`.

**Es un seguro contra el resbalón, no seguridad** —lo mismo que el Modo
edición—: alguien que abra F12 vería el código igual. Para lo que hace falta
—que el equipo no la vea ni la pida— alcanza.

**El correo no se escribe en el código.** El permiso vive en la tabla, como
todos los demás.

---

## ETAPA 1 — TERMINADA

### Lo que corrió en la base

| Archivo | Qué dejó |
|---|---|
| `sql/2026-08-lama-permiso.sql` | la columna `puede_lama` · una sola cuenta la tiene |
| `sql/2026-08-lama-cimientos.sql` | las 4 tablas + realtime + las 12 mesas del Salón de Plaza |
| `sql/2026-08-lama-funciones.sql` | 8 funciones, una firma cada una |

### El modelo

```
mesas ──< cuentas ──< cuenta_items >── comandas
```

Una **mesa** es un lugar del salón y existe siempre. Una **cuenta** es una
visita a esa mesa: nace cuando llega alguien y muere cuando se paga. Los
**items** son lo que se pidió. Una **comanda** es cada papel que sale a la
cocina — una cuenta puede tener varias, porque la gente pide, come y vuelve a
pedir.

**El candado, y está en la base:** el índice único parcial
`cuentas_una_viva_por_mesa` impide **dos cuentas abiertas en la misma mesa**.
Es integridad de datos —dos cuentas vivas significa que alguien va a pagar la
de otro—, no una preferencia. Dos garzones tocando la misma mesa a la vez va a
pasar.

**Lo que las tablas NO tienen, a propósito:** `personas`, `cliente`, `forma` de
la mesa, comentario de mesa. Son las preguntas que Jhon llamó ruido: nadie las
mira después. Una columna que nadie llena es una pregunta que la gente
contesta por contestar.

**Sí se guarda `salon`** aunque hoy solo exista "Salón": agregar Terraza mañana
es agregar filas, no migrar una tabla con datos adentro.

**Y se guarda el nombre del producto además del id**, como en `reparto_items`:
si mañana renombran algo en Fudo, la comanda de ayer se sigue leyendo.

### Las ocho funciones

`mesa_abrir` · `cuenta_agregar` · `cuenta_recalcular` · `cuenta_confirmar` ·
`cuenta_precuenta` · `cuenta_cerrar` · `cuenta_mover` · `items_mover`

**Ninguna toca el stock.**

`cuenta_confirmar` es **idempotente por construcción**: solo toma los ítems en
estado `nuevo`. Confirmar dos veces no imprime dos veces lo mismo — el mismo
patrón que `reparto_recibir`.

### La pantalla

Pestaña **Mesas**, escondida. El plano de 12 mesas con sus tres colores
—**verde** libre, **rojo** ocupada, **azul** precuenta impresa, que son
literalmente `cuentas.estado`—; abrir con un toque; la carta sale de
`fudo_productos`, que ya trae nombre, precio, categoría y activo sincronizados;
agregar, cantidad y comentario por producto; Confirmar → la comanda se muestra
en pantalla tal como saldría impresa; Precuenta → azul; Cerrar → vuelve a
verde.

En vivo sobre `cuentas` y `cuenta_items`, así dos teléfonos sobre la misma mesa
se ven el uno al otro.

**Pruebas:** `pruebas/lama-mesas.mjs`, 19 casos. La primera y la más
importante: **que la pestaña no exista sin `puede_lama`**, probada en las dos
direcciones.

---

## LO SIGUIENTE — etapa 4: mover mesa y mover productos

Existe porque **el garzón se equivoca**: anota en la mesa 3 lo que era de la 7,
o el grupo se cambia de mesa a mitad de comida.

| | |
|---|---|
| **Mover la mesa entera** a una libre | se niega si la destino está ocupada |
| **Mover productos** de una mesa a otra | eligiendo cuáles |

**Las dos funciones ya están en la base** (`cuenta_mover`, `items_mover`) y ya
corrieron. **Falta solo la pantalla.** Hoy el botón `✎` de una mesa contesta
"Todavía no" — ese es el punto exacto donde se retoma.

Las dos con vista previa y **confirmación por nombre** —*"Mesa 3 pasa a Mesa
7"*, no "¿Confirmar?"—.

**Los botones que Jhon dijo que no sirven no se construyen:** el del teléfono
y la lupa de arriba de Fudo.

---

## DESPUÉS, en orden

1. **Pulir precuenta y cerrar.** Funcionan; falta afinar cómo se ve el detalle
   que se le muestra al cliente.
2. **El puente de impresión.** Va aislado y de primero entre las cosas grandes.
   La impresora es una **Xprinter XP-N160II** por **USB**, habla **ESC/POS**, y
   ya está instalada y funcionando. El navegador no le puede hablar directo:
   hace falta un programa chico en ese computador que reciba por red local e
   imprima — exactamente lo que hace Fudo con su extensión de Chrome y su
   aplicación de Windows. Si falla, que falle solo. Necesita que Jhon vaya al
   local.
3. **El cierre de caja:** arqueo, efectivo/débito, cuadratura del turno.
4. **La barra de dos niveles** (Stock | Lama arriba, como los iconos de Fudo).
   Es el destino correcto y no se hace todavía: tocaría la navegación que el
   equipo usa todos los días para un beneficio que aún no existe. Se hace el
   día que Lama se muestre, y es trabajo de un día porque `moverCarril()` ya es
   genérico.
5. **Separar en `/caja`**, con el peso de Lama medido y no adivinado.
6. **AL FINAL: las conexiones con Stock.** Que cerrar una mesa descuente el
   inventario, con interruptor.

**La boleta sigue saliendo por Mercado Pago.** Esa línea no se cruza.

---

## Cómo se comprueba que una etapa quedó bien

- **Todo SQL nuevo** probado contra Postgres local con el esquema copiado del
  DDL del repo —no inventado— y **en las dos direcciones**: que haga lo que
  debe, y que **se niegue** cuando corresponde.
- **La puerta:** entrar con una cuenta del equipo y comprobar que la pestaña
  **no existe**. Es la comprobación más importante de todas.
- **De punta a punta:** abrir mesa → agregar dos productos con comentario →
  confirmar → ver la comanda → agregar uno más → confirmar (que la segunda
  comanda traiga **solo** el nuevo) → precuenta → cerrar → la mesa vuelve a
  verde.
- **Dos teléfonos a la vez** sobre la misma mesa: el segundo ve lo que agregó
  el primero, y no puede abrirla dos veces.
- **El inventario no se movió**: comparar el stock antes y después de una
  vuelta completa. Tiene que ser idéntico.
- `pantalla-sana.mjs` y la batería entera en verde antes de fusionar a
  `master`.

---

## Cómo se le entrega algo a Jhon

Él no tiene el repositorio en su computador, no usa terminal ni git. Todo lo
que él hace es: **copiar un texto, pegarlo en Supabase, apretar Run, y mandar
el resultado.**

Cada `.sql` empieza con estas cinco líneas:

```
--  DÓNDE VA:  Supabase -> SQL Editor -> New query
--  ES:        1 solo bloque / 3 bloques, uno por uno
--  TARDA:     instantáneo / ~12 segundos
--  QUÉ HACE:  una frase. Y si escribe algo, decirlo.
--  QUÉ VER:   qué columna mirar y qué significa
```

Y va **corto**, porque el editor de Supabase se atraganta con sentencias muy
largas y con SQL dinámico. Si es largo, se entrega **ya partido**, no se le
pide a él que lo parta.
