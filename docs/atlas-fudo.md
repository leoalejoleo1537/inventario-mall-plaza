# Atlas de Fudo — cómo se comporta el sistema que estamos replicando

> **Para qué existe.** Llamita Lama copia a Fudo a propósito: el equipo ya sabe
> usar esa pantalla, y copiarla hace que no tengan que aprender nada. Pero
> hasta hoy *cómo es Fudo* no estaba escrito en ninguna parte — vivía en la
> cabeza de Jhon y llegaba al chat en fotos sueltas, una por tarea.
>
> **Eso es lo que hacía lento el trabajo.** Cada tarea empezaba de cero,
> reconstruyendo el modelo a partir de una captura. Este archivo lo escribe
> una vez.

---

## ⚠️ LO QUE ESTE ARCHIVO NO CONTIENE, Y ES LA MITAD

El atlas tiene dos mitades y **dos fuentes distintas**. Confundirlas es lo que
hacía que preguntar no rindiera:

| Mitad | De dónde sale | Dónde vive |
|---|---|---|
| **Cómo se comporta** — estados, reglas, qué pasa si… | el manual · NotebookLM | **este archivo** |
| **Cómo se ve** — disposición, medidas, colores, orden | solo de la pantalla corriendo | capturas + Inspeccionar en Chrome |

**Ningún manual dice cuántos píxeles de aire lleva un panel ni de qué naranja
es un botón.** Eso se mide con el botón derecho → Inspeccionar, sobre Fudo
abierto. Si una tarea necesita una medida y acá no está, **no se adivina: se
mide**.

## Cómo se usa

**Jhon:** copia la pregunta tal cual a NotebookLM, y pega la respuesta debajo,
donde dice `⬜ PENDIENTE`. No hace falta ordenarla ni resumirla — pégala como
venga. Se puede hacer de a una, a ratos, desde el teléfono.

**El chat de Lama:** esto se lee **antes** de construir cualquier pantalla del
área de ventas. Una pregunta que siga en `⬜ PENDIENTE` es un hueco conocido:
se pregunta, no se inventa.

**Y la regla que manda sobre todo lo de acá:** el manual va detrás del
producto. **Si el atlas contradice lo que se ve en pantalla, gana la
pantalla.** Cuando pase, se corrige acá y se anota la fecha.

## Cómo sacarle más a NotebookLM

- **Pídele tablas.** Una respuesta en prosa hay que volver a masticarla; una
  tabla se pega y ya sirve.
- **Una pregunta por vez.** Dos juntas se contestan a medias las dos.
- **Pídele que cite la fuente.** Sirve para saber qué es del manual y qué está
  rellenando.
- Si contesta con generalidades, insiste con: *"enumera, no expliques"*.

---

# LA PREGUNTA CERO — el plano de la mina

> Esta va **primero**, y contesta la pregunta que Jhon no sabía hacer: cuáles
> son las preguntas. No hay que adivinar dónde está el oro — el índice del
> material lo dice.

```
Hazme el índice completo de todo el material: cada sección y subsección, con
una línea de qué cubre. No expliques nada todavía, solo el índice.
```

⬜ PENDIENTE

> **Cuando esté:** toda sección de ese índice que tenga que ver con vender y
> que no esté cubierta más abajo, **se agrega como pregunta nueva a este
> archivo**. Este documento crece; no es una lista cerrada.

---

# A · EL MAPA

### A1 · El recorrido completo

```
Lista todas las pantallas del área de ventas, en el orden en que un garzón las
recorre desde que llega un cliente hasta que paga. Tabla: pantalla · para qué
sirve · desde dónde se llega.
```

⬜ PENDIENTE

### A2 · Quién puede hacer qué

```
¿Qué roles o perfiles de usuario existen y qué puede hacer cada uno en el área
de ventas? Tabla: rol · qué puede · qué no puede.
```

⬜ PENDIENTE

> Ojo al leer esto: en Llamita **la seguridad se mantiene en mínimos** por
> decisión de Jhon (§6.1), y el único candado es la puerta de Ajustes. Que
> Fudo tenga cinco roles **no es motivo para copiarlos** — es información
> sobre qué acciones ellos consideran delicadas.

---

# B · LAS MESAS

### B1 · Los estados

```
Lista todos los estados posibles de una mesa, qué acción la lleva a cada
estado y qué acción la saca. Tabla: estado · cómo se entra · cómo se sale ·
cómo se ve en pantalla.
```

⬜ PENDIENTE

> Lama hoy tiene tres —libre, ocupada, cobrando—. Si Fudo tiene más, hay que
> saber si son estados de verdad o adornos.

### B2 · Abrir una mesa

```
¿Qué datos se piden al abrir una mesa? De cada uno: ¿es obligatorio u
opcional, y para qué se usa después?
```

⬜ PENDIENTE

> Contexto: Jhon ya decidió **dejar fuera** personas, cliente y comentario de
> mesa, porque nadie los mira después. Esta respuesta sirve para confirmar que
> no se está perdiendo nada que Fudo use más adelante.

### B3 · Todo lo que se le puede hacer a una mesa

```
¿Qué se puede hacer con una mesa ya abierta? Lista todas las acciones,
incluidas las poco usadas.
```

⬜ PENDIENTE

### B4 · Unir, dividir, trasladar

```
¿Qué pasa exactamente al unir dos mesas, al dividir una y al trasladar
productos de una a otra? ¿Qué se conserva, qué se pierde y qué queda
registrado?
```

⬜ PENDIENTE

---

# C · LA COMANDA

### C1 · De la pantalla a la cocina

```
Describe paso a paso qué ocurre desde que se agrega un producto hasta que sale
impreso en la cocina. ¿Qué estados atraviesa ese producto?
```

⬜ PENDIENTE

### C2 · Modificar lo ya enviado

```
¿Se puede modificar o eliminar un producto ya enviado a cocina? ¿Bajo qué
condiciones, qué queda registrado, y qué ve la cocina?
```

⬜ PENDIENTE

> **Esta es la más importante del bloque C.** Lama ya tomó una decisión acá
> —*lo que salió a la cocina no se edita, se anula*— y conviene saber si Fudo
> hace lo mismo. Si el equipo está acostumbrado a otra cosa, hay que saberlo
> antes y no después.

### C3 · Lo que lleva un producto

```
¿Qué opciones tiene un producto dentro de una comanda: comentarios, variantes,
agregados, cantidades, media porción? Lista todas.
```

⬜ PENDIENTE

---

# D · EL COBRO ← *lo que se está construyendo ahora*

### D1 · La pantalla entera

```
Describe la pantalla de cobro completa: cada zona, cada campo y cada botón, en
el orden en que aparecen.
```

⬜ PENDIENTE

### D2 · Pago parcial

```
¿Cómo funciona el pago parcial o dividido? ¿Se divide por monto, por producto
o por comensal? ¿Qué queda pendiente después y cómo se ve?
```

⬜ PENDIENTE

> **Es el A1 de la lista de trabajo, lo más grande que falta.** Jhon ya
> decidió que en Lama **el pago parcial paga PRODUCTOS, no plata**. Esta
> respuesta confirma o corrige esa decisión con el comportamiento real.

### D3 · Descuentos

```
¿Cómo se aplica un descuento: sobre qué se calcula, se puede combinar con
otro, quién puede aplicarlo, y qué queda registrado?
```

⬜ PENDIENTE

### D4 · Propina

```
¿Cómo se maneja la propina: se calcula sola, se puede pagar con un medio
distinto al de la cuenta, y entra al arqueo?
```

⬜ PENDIENTE

### D5 · Medios de pago y consumos internos

```
¿Qué medios de pago existen y cuáles no son un cobro real —consumo interno,
cortesía, invitación—? ¿Cómo los trata el sistema y cómo aparecen en los
informes?
```

⬜ PENDIENTE

### D6 · Cuando la plata no cuadra

```
¿Qué pasa si se intenta cerrar una mesa con menos plata de la que vale? ¿Y con
más? ¿Cómo se maneja el vuelto?
```

⬜ PENDIENTE

---

# E · LO QUE SE DESCUBRE TARDE Y CUESTA CARO

### E1 · Todo lo que el sistema NO deja hacer

```
Lista todo lo que el sistema no permite en el área de ventas: validaciones,
bloqueos y mensajes de error. Tabla: qué se intentó · qué contesta el sistema.
```

⬜ PENDIENTE

> Esta es la que más rinde por pregunta. **Los bloqueos son las reglas del
> negocio escritas al revés**, y son justo lo que uno descubre a mitad de
> construir.

### E2 · Qué se puede deshacer

```
¿Qué acciones se pueden deshacer y cuáles no? Tabla: acción · reversible sí/no
· cómo se deshace · qué rastro deja.
```

⬜ PENDIENTE

### E3 · Sin internet

```
¿Qué ocurre si se pierde la conexión a internet en medio de una venta? ¿Qué se
puede seguir haciendo y qué se pierde?
```

⬜ PENDIENTE

> §7 ya midió la vara acá: **Fudo ya falla sin conexión hoy**, así que lo
> correcto es "no peor que hoy", no "perfecto".

---

# F · EL VOCABULARIO

### F1 · Las palabras exactas

```
Dame la lista exacta de nombres de botones, títulos de pantalla y mensajes del
área de ventas, tal como están escritos, en español.
```

⬜ PENDIENTE

> **La más barata y la más rentable de todas.** Si Lama dice *"Anular"* donde
> Fudo dice *"Cancelar producto"*, el equipo tiene que reaprender palabras — y
> la razón entera de copiar a Fudo era que no tuvieran que aprender nada.
>
> Cuando esta llegue, **se revisa contra los textos que Lama ya tiene puestos**
> y se corrigen los que no calcen.

---

# G · LOS HUECOS

### G1 · Lo que el manual no cuenta

```
¿Qué aspectos del área de ventas NO están documentados, o se mencionan solo de
pasada?
```

⬜ PENDIENTE

> Lo que salga acá **es la lista de lo que hay que ir a mirar a la pantalla**.
> Tenerla antes de empezar evita descubrirlo a mitad de construir.

---

# H · LO VISUAL — no va acá, pero se anota dónde va

Esto **no** sale de NotebookLM. Se mide sobre Fudo abierto, con botón derecho
→ Inspeccionar, y se guarda junto a la captura de cada pantalla.

De cada pantalla que Lama vaya a replicar:

- [ ] captura en **computador** y en **teléfono**
- [ ] los **colores** de fondo, texto, botones y de cada estado de mesa
- [ ] el **tamaño de letra** de título, de producto y de total
- [ ] el **orden** de los elementos, de arriba abajo
- [ ] qué **crece y qué se queda fijo** al agrandar la ventana
- [ ] qué pasa al **tocar** cada cosa

> **Adjetivos no sirven.** *"Se ve apretado"* deja al que construye eligiendo
> entre veinte versiones válidas; `padding: 14px` no deja ninguna. Esa
> diferencia es la que hace que un mismo pedido salga bien o salga a medias.

---

## Registro

| Fecha | Qué se agregó |
|---|---|
| 2026-09-01 | Se crea el archivo con las preguntas. Ninguna respondida todavía |
