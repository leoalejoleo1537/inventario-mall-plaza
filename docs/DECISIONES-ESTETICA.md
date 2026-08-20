# La estética — decisiones tomadas y lo que falta elegir

> **Estado: NADA IMPLEMENTADO todavía.** Jhon pidió expresamente guardar esto
> y no aplicarlo hasta ver la pantalla de inicio. Este archivo existe para que
> la decisión no se pierda entre sesiones.

Maquetas: `propuesta-estetica.html` (las tres pieles),
`propuesta-estetica-2.html` (el contenedor y el ⟳) y
`propuesta-estetica-3.html` (la lista completa, el dial y la barra).

---

## ✅ Decidido

| | |
|---|---|
| **La piel** | **C · Aire.** No cambia ningún color: cambia el espacio y las formas. Esquinas de 20 px, filas sin borde y con sombra, más aire entre secciones |
| **Las animaciones** | **Van todas.** Lista escalonada, el número que late al cambiar en vivo, el ✓ del reparto que se dibuja, y la sección que brota con resorte |

---

## ⏸️ Elegido a medias — falta que Jhon decida

### El contenedor del título de sección — **elegido: la cápsula**

Jhon eligió la **cápsula** (opción 3), con una condición: *"me preocupa que se
mezcle con el fondo y se vea casi invisible… no quiero un contraste tan
notorio, y ya sabes que no me gustan los rebordes, eso sí que no"*.

Por eso la maqueta 3 trae un **dial de cuatro niveles** en vez de un valor
elegido por mí — el punto exacto entre "se pierde" y "vuelve el ladrillo" lo
tiene que ver él, sobre cinco secciones apiladas. **Falta que diga el número.**
Mi voto: el 2.

<details><summary>Las otras tres que se descartaron</summary>

Jhon lo planteó bien: *"me preocupa que no los contenga nada… es importante
que no sacrifiquemos en el altar de la estética la jerarquía de colores y
formas"*. Tiene razón, y por eso hay cuatro opciones en vez de un rótulo
suelto:

| | Qué es |
|---|---|
| **1 · El riel** | Una barra vertical azul que abraza la sección entera por el costado |
| **2 · La bandeja** ⭐ | El título y sus filas dentro de una misma caja gris clara |
| **3 · La cápsula** | El azul relleno, pero solo del ancho de la palabra |
| **4 · Cabecera pegajosa** | Se queda arriba al desplazar. **Suma a cualquiera de las tres** |

</details>

### El ⟳ — **rehecho según lo que pidió**

Ya no es un círculo con ícono. Es una **pastilla alargada que dice
"Actualizar"**, con:

- **cuerpo en relieve** que se hunde de verdad al tocarlo,
- **el neón como él lo imaginaba**: una luz naranja que sale **por detrás**
  del botón y late — no un borde encendido, que fue lo que entendí mal la
  primera vez,
- y **la ventana de carga a pantalla completa con el fondo desenfocado se
  queda tal cual**, porque ya funciona y le gusta. El botón avisa *cuándo* hay
  que apretarlo; la ventana muestra *mientras*.

**Falta:** confirmar si la palabra es "Actualizar" u otra.

### La barra superior — tres opciones, falta elegir

Fuera el texto **"Inventario"**: era redundante con la pestaña. El
protagonista pasa a ser **la sede**, en grande, y debajo un dato que sirve
—cuántos críticos hay ahora—.

| | |
|---|---|
| **A · Profunda** | Navy con degradado suave, para que no sea una plancha plana |
| **B · Clara** | Barra blanca. La más ligera, y la que más deja brillar al botón. Cuesta el marco oscuro que hoy le da peso a la app |
| **C · Filo de sede** ⭐ | Como la profunda, más un filo de color al pie que **cambia según la sede**: naranja Plaza, verde Angamos, morado Bodega |

**Recomendación: C.** Equivocarse de sede tiene consecuencias, y el color te
dice dónde estás antes de leer.

Más: **las pestañas con un carril que se desliza** en vez de que el naranja
salte, y **la casita con ícono propio** en vez del emoji 🏠, que cada teléfono
dibuja distinto.

---

## La regla que gobierna el ⟳, y no se negocia

**El botón brilla porque hace falta apretarlo, no porque quede bonito.**

Un brillo permanente rompería la regla de la casa (§2): si el naranja brilla
siempre, deja de significar *esto necesita atención*, y en una barra donde
también viven alertas rojas le ganaría la pelea a algo más urgente.

Entonces el halo tiene cuatro estados, atados a un dato real —cuánto hace que
no sincroniza—, no a la decoración:

| Estado | Cómo se ve |
|---|---|
| Al día | quieto, sombra suave |
| Hace ~20 min | respira despacio |
| Hace horas | respira más rápido |
| Falló | rojo, y **no se calma solo** |

Ese último punto es §0.5 llevada al botón: nada puede fallar en silencio.

**Y el anillo de progreso no es adorno:** el ciclo son tres pasos en orden
—catálogo, ventas, empujar a Fudo— y cada tercio que se completa es un paso
que terminó. Es la única forma de saber en cuál va sin leer texto.

---

## ✅ Ya implementado — no era estética

**Deslizar a la derecha merma** (Jhon, 2026-08-20): *"mermamos varias cosas y
quiero que sea rápido"*.

En **Plaza y Angamos**: izquierda → al reparto, derecha → abre la ventana de
merma con motivo y cantidad. **En Bodega no cambia**, porque allá los lados ya
significaban algo desde antes —derecha Mall Plaza, izquierda Angamos— y ese
gesto está en uso.

Mientras se arrastra, el símbolo dice qué va a pasar: **"+" naranja** hacia un
lado, **"Mermar" en rojo** hacia el otro. Sin eso el gesto sería una apuesta.

⚠️ **Es un cambio de hábito y hay que avisarlo.** Quien venía deslizando a la
derecha para el reparto se va a encontrar con la merma. No resta nada solo
—abre una ventana que hay que completar y se puede cerrar—, así que el peor
caso es un susto, pero conviene decirlo antes que lo descubran.

---

## Lo que NO se toca, en ninguna propuesta

- **El naranja** significa acción y urgencia, y nada más
- **Los colores de estado**: rojo crítico, verde en rango, ámbar aviso
- **Las píldoras de fecha**: todas visibles, la urgencia en el color, vencido
  distinto de vence-hoy
- **Dónde está cada cosa**: ninguna propuesta mueve un botón de sitio

## Cómo se implementa cuando se decida

Las tres pieles están escritas como variables CSS. Aplicar la elegida es
reemplazar el bloque de tokens de `:root` en `index.html` —unas veinte
líneas— y no reescribir pantallas. Las animaciones van aparte y se pueden
agregar de a una.
