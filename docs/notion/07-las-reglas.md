# 07 · Las reglas que no se tocan

> Cada una viene de algo que salió mal de verdad. Están acá con su historia,
> porque una regla sin su motivo se salta a la primera que estorba.

---

## 1 · Antes de escribir en una sede, sácale una foto

**Lo que pasó — 9 de agosto de 2026.** A las 17:00, **260 productos de Angamos
quedaron en cero de una sola vez**. Prácticamente toda la sede.

**No se pudo restaurar nada.** No por falta de herramienta: porque **no había
ninguna foto de Angamos que restaurar**. Nadie había apretado nunca "Guardar
inventario de hoy" en esa sede. Hubo que cargar el stock entero a mano.

Lo que sí tenía copia se recuperó: las recetas, los mínimos, los productos
eliminados. **La diferencia entre lo que volvió y lo que no es exactamente esta
regla.**

**Y el daño no se mide el día que pasa.** El inventario volvió a un estado
viejo, así que al día siguiente se iba a armar el reparto mirando lo que faltaba
dos días antes. **Un dato malo no hace daño cuando se corrompe: hace daño cuando
alguien toma una decisión con él.**

> **Hoy la foto es automática, a las 15:00 y a las 22:00, en las tres sedes.**
> Ese respaldo no se apaga: es la red, y una red que se apaga por accidente no
> es una red.
>
> **Y el respaldo va antes del PRIMER paso que escribe**, no antes del que
> parece más peligroso. El paso "inofensivo" que corre primero es el que te deja
> sin red para todos los demás.

---

## 2 · El stock nunca puede ser negativo

Un número negativo en un inventario no significa nada: nadie tiene menos tres
brownies.

**No es una regla que alguien deba recordar.** La base misma rechaza cualquier
número bajo cero, venga del motor, de una edición a mano o de un camino que
todavía no existe. Si se vende más de lo que hay, el stock se queda en 0 y el
sobrante no se refleja.

---

## 3 · Un perecedero entra solo por fechas

Los sándwiches no tienen "cantidad": tienen **fechas de vencimiento**, y la
cantidad es la suma de esas fechas.

Al recibir un reparto, la base **exige** las fechas y se niega a sumar sin
ellas. No depende de que la pantalla se acuerde de pedirlas.

**Y todas las fechas se muestran siempre**, sin resumir ni esconder detrás de un
"+2 fechas". Hubo que corregirlo una vez:

> *"Los sándwiches son uno de los nervios más críticos de la cafetería.
> Necesito que de un vistazo podamos ver TODAS las fechas de vencimiento de ese
> pancito."*

Si hay cuatro fechas, se ven las cuatro sin abrir nada.

---

## 4 · El sistema no simula movimientos que nadie hizo

**Lo que pasó.** Había una función que, cuando la vitrina llegaba a cero,
trasladaba cuatro unidades desde el congelador automáticamente.

Se apagó, y la razón vale para cualquier cosa que se construya después:
**el sistema movía producto en los números sin que nadie lo hubiera movido en el
mesón.** La app decía que la vitrina tenía cuatro cuando el estante estaba
vacío.

El argumento que zanjó el asunto:

> *"Los jefes de turno pueden poner cuatro, cinco, incluso seis productos.
> Muchas veces hay dos en vitrina y por rellenar ponen otros dos."*

**La cantidad de reposición es variable y nadie la registra.** Cualquier número
que el sistema asuma va a estar equivocado casi siempre.

**El costo que se aceptó, dicho sin adornos:** con la vitrina en cero, las
ventas siguientes no se descuentan de ninguna parte, y el número queda por
encima de la realidad hasta el siguiente conteo. **Se prefiere un atraso
conocido antes que un número inventado que parece exacto.**

Por lo mismo, **el reparto descuenta al ACEPTAR, no al enviar**: al enviar actuó
una sola persona y la caja todavía puede quedarse en el pasillo; al aceptar
actuaron dos, y ahí sí hay evidencia de que el producto se movió.

---

## 5 · Nada puede fallar en silencio

**Lo que pasó — 27 de julio de 2026.** El sistema estuvo **15 horas leyendo
ventas y descontando nada**, mostrando "✓ ventas actualizadas" en la pantalla.
Se descubrió a mitad de turno, vendiendo una medialuna.

Las causas técnicas se arreglaron el mismo día. **Lo que hubo que cambiar de
fondo fue otra cosa:** el sistema contaba cada venta fallida en un número que la
app nunca mostraba. Nada en pantalla decía que el inventario llevaba horas
congelado.

> **Un sistema que falla en silencio es peor que uno que se cae**, porque nadie
> va a buscar lo que parece estar bien.

Hoy: si el motor lee ventas y no descuenta ninguna, la app abre una ventana que
lo dice. Si falla el 10%, también. Y la alarma tiene su propia prueba, que
comprueba las dos cosas: **que suene cuando debe y que NO suene cuando no**.

---

## 6 · Comparar es un informe, nunca una edición

Pedir "compara los productos de Fudo con los del inventario" es pedir **un
informe**. Nunca crear, fusionar, renombrar ni eliminar nada.

Salió de una vez en que una comparación terminó creando cinco productos
duplicados en producción.

**Si al comparar aparece algo que parece que hay que arreglar, se muestra y se
pregunta.** Lo obvio para quien mira los datos no siempre es obvio para el
negocio.

---

## 7 · Un nombre que no calza no es un error: es una pregunta

Las recetas se unen por **número**, no por nombre. **Renombrar un producto no
rompe nada.**

Durante semanas se arrastraron dos "recetas cruzadas" como el hallazgo más grave
del sistema. Se revisaron y **ninguna de las dos existía**:

| Lo que se reportó | Lo que era |
|---|---|
| *Cheesecake maracuyá descuenta T. Cheesecake **Mora*** → producto equivocado | **No hay cheesecake de mora en la carta.** "Mora" es "Mara", abreviatura de maracuyá, mal tipeada. La receta apuntaba al producto correcto |
| *Cinnamon Roll Vegano descuenta el normal* → dos productos distintos | **Es un solo producto.** El único que se vende es el vegano |

Las dos veces el razonamiento fue el mismo: *los nombres no coinciden, entonces
está mal*. Y ninguna consulta lo habría desmentido: **la carta del café no está
en la base de datos, está en la cabeza de la gente que la vende.**

---

## 8 · Lo que decidió el equipo se respeta

Nombres, secciones, rubros y el modo de cada sede son **decisiones operativas
del café**, no inconsistencias a corregir.

En particular: **nunca proponer bajar una sede de `real` a `prueba`**. Que el
sistema ya esté descontando en producción es un logro del proyecto, no un riesgo
a mitigar.

---

## 9 · Todo se tiene que poder apagar sin romper nada

Toda función nueva nace con interruptor. Y **"apagar" significa volver al
comportamiento anterior, no dejar un hueco** — esa es la mitad que se olvida.

| Encendido | lo nuevo |
| Apagado | **exactamente** lo que había antes, funcionando |
| A medio camino | no existe |

**Por qué vale una regla:** un interruptor es lo que convierte "hay que llamar a
alguien" en "lo apago y sigo trabajando".

> *"Existe la posibilidad de que yo un día me vaya y necesito entregar un
> sistema que sea completamente manejable."*

Las excepciones son pocas y son los candados que protegen datos: el tope en
cero, que un perecedero entre por fechas, el respaldo automático. Ahí "apagado"
sería corromper el inventario.

---

## 10 · Que sea bella, no solo que funcione

> *"Necesito que no solo sea funcional, sino estéticamente bella para que
> incentive su uso."*

**La estética no es un extra que se agrega al final: es parte del encargo.** Una
pantalla correcta pero fea la gente la usa a regañadientes y termina volviendo
al Excel — y esa es la vara del proyecto.

Y su hermana, que se olvida seguido: **si hay que explicarlo con un párrafo, es
que la forma no está bien resuelta.** Nada de textos explicativos en la app. Un
botón bien nombrado más un ícono valen más que dos frases. Cuando dudes, quita
texto.
