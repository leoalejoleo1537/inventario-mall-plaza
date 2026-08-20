# La estética — decisiones tomadas y lo que falta elegir

> **Estado: NADA IMPLEMENTADO todavía.** Jhon pidió expresamente guardar esto
> y no aplicarlo hasta ver la pantalla de inicio. Este archivo existe para que
> la decisión no se pierda entre sesiones.

Maquetas: `docs/propuesta-estetica.html` (las tres pieles) y
`docs/propuesta-estetica-2.html` (el contenedor y el ⟳).

---

## ✅ Decidido

| | |
|---|---|
| **La piel** | **C · Aire.** No cambia ningún color: cambia el espacio y las formas. Esquinas de 20 px, filas sin borde y con sombra, más aire entre secciones |
| **Las animaciones** | **Van todas.** Lista escalonada, el número que late al cambiar en vivo, el ✓ del reparto que se dibuja, y la sección que brota con resorte |

---

## ⏸️ Elegido a medias — falta que Jhon decida

### El contenedor del título de sección

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

**Recomendación: la bandeja + pegajosa.** Es la única que *mejora* la
jerarquía en vez de conservarla — hoy la cabecera y sus filas son objetos
separados que están cerca; en la bandeja se ve que se pertenecen.

### El acabado del ⟳

| | |
|---|---|
| **A · Pulso** | Disco limpio con un halo que late como una gota en el agua |
| **B · Neón** | Degradado, borde encendido por dentro, dos capas de resplandor |
| **C · Relieve** | Botón físico con cuerpo y sombra dura; se hunde al tocarlo |

**Recomendación: Relieve para el cuerpo + Pulso para el halo.**

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

## ⬜ Lo que falta ver antes de aplicar

Jhon: *"quiero ver propuestas para la pantalla de inicio, las barras, el
home"*. Falta esa tercera maqueta.

De la barra de arriba ya hay tres ideas propuestas y sin decidir:

1. **La sede en cápsula** en vez de texto gris chico — equivocarse de sede
   tiene consecuencias, así que merece verse.
2. **Las pestañas con un carril que se desliza** en vez de que el naranja
   salte.
3. **La casita con ícono propio** en vez del emoji 🏠, que cada teléfono
   dibuja distinto.

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
