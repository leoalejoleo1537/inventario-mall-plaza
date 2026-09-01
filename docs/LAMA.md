# Llamita Lama — el archivo madre

> **Este es el archivo madre del área de ventas.** No se carga solo: si vas a
> tocar Lama, **leelo entero antes de planificar**. Salió de la §12 de
> `CLAUDE.md` el 2026-08-31, cuando ese archivo pasó de 4.114 líneas a 1.751
> para dejar de costar 69.000 tokens por sesión.
>
> **Las reglas duras siguen en `CLAUDE.md`** y se leen igual, siempre. Las dos
> que más pesan acá: **§0.9 — Llamita Stock no se toca** y **§0.5 — el
> `drop function` antes de cambiar una firma**.
>
> La estética manda desde [`DECISIONES-ESTETICA.md`](DECISIONES-ESTETICA.md).

## Índice

| Dónde | Qué hay |
|---|---|
| **Regla de despliegue** | Lama va a `master` apenas pasa las pruebas |
| **Qué es, en una frase** | y por qué está escondida |
| **Etapas 1 y 4** | lo que ya está terminado |
| **Las dos vueltas del 31 de agosto** | la limpieza, y los colores medidos de Fudo |
| **El cierre de mesa** | la especificación completa, dictada por Jhon |
| **LA LISTA DE TRABAJO** | ← *lo que está en curso hoy* |
| **Después, en orden** | lo que viene, y por qué en ese orden |

---

## 12. LLAMITA LAMA — el hermano grande, y dónde quedamos

> **Esta sección es lo primero que tiene que leer el chat que construya Lama.**
> §6.0 cuenta dónde quedó Stock; esta cuenta dónde quedó Lama. Se actualiza al
> cerrar cada etapa, y se le borra lo que envejece — una sección de estado que
> engaña cuesta más que no tenerla (lección del 2026-08-10).

### REGLA — Lama se despliega SIEMPRE, apenas pasa las pruebas

> Jhon, 2026-08-31: *"despliégalo, si no, no tengo cómo verificar… no me sirve
> que me digas 'ya lo corregí' pero no tengo cómo comprobarlo."*

**Todo cambio de Lama va a `master` y se publica.** No se queda en una rama
esperando aprobación.

**Por qué no contradice "nunca push a master sin confirmar" (§7):** esa regla
protege a la gente que está trabajando. A Lama **no la ve nadie** —
`app_permisos.puede_lama` nace apagada para todos y hoy solo la tiene una
cuenta—, así que publicarla no expone nada. Y sin publicar, Jhon no tiene
forma de mirarla: no tiene el repositorio ni usa terminal. **Un arreglo que él
no puede ver es un arreglo que no está entregado.**

**Lo que esta regla NO relaja:** el diff sigue sin poder salir de `view-lama`,
las funciones `lama*` y `pruebas/lama-*` (§0.9). Justamente por eso un push de
Lama nunca puede llevar un cambio de Stock adentro — y por eso se puede
publicar sin pensarlo dos veces.

**Antes de cada push, dos cosas, y no son opcionales:** que las pruebas de
Lama estén en verde, y **comparar la batería contra una línea base** sacada de
`origin/master` con `git worktree`. Decir "no toqué Stock" es una intención;
comparar dos corridas es un dato.

### Qué es, en una frase

**Llamita Stock** sabe qué hay. **Llamita Lama** sabe qué se vende. Lama es el
área de ventas —mesas, comandas y cobro— y es lo que hoy hace Fudo.

**Las dos razones por las que existe**, y las dio Jhon:

1. **Hay otra empresa interesada en comprar Llamita Stock**, y para venderlo
   hace falta que el producto esté completo.
2. Con Lama terminada, **Café del Desierto puede soltar Fudo del todo** — y
   con Fudo desaparece la capa entera de emparejar dos sistemas: recetas que
   no calzan por un nombre, combos que no capturan la elección, ventas que hay
   que ir a leer. Eso ya estaba anticipado en §7.

**Se copia la forma de Fudo a propósito.** El equipo ya sabe usar esa
pantalla; imitarla hace que la curva de aprendizaje sea casi cero. Es el mismo
criterio que hizo que el reparto desde bodega escribiera lo mismo que el
reparto del local (§0.7).

**Y se construye ESCONDIDA.** Jhon: *"si algo falla aquí, podríamos perder o
entorpecer todo un día de ventas, necesito trabajar tranquilo"*, y también:
*"Café del Desierto no puede saber que estoy trabajando en este proyecto
nuevo"*. La puerta es `app_permisos.puede_lama`, que **nace apagada para
todos** — hoy solo la tiene `leoalejoleo12@gmail.com`, una cuenta nueva creada
para esto (la de Jhon no servía: hay dispositivos con su sesión abierta).

⚠️ **Antes de tocar una línea, leer §0.9.** Stock no se toca. Es la regla que
manda sobre todo lo de acá abajo.

### ETAPA 1, TERMINADA — al 2026-08-28

**Los tres SQL ya corrieron en producción**, comprobados por Jhon:

| Archivo | Qué dejó |
|---|---|
| `sql/2026-08-lama-permiso.sql` | la columna `puede_lama` · una sola cuenta la tiene |
| `sql/2026-08-lama-cimientos.sql` | las 4 tablas + realtime + las 12 mesas del Salón de Plaza |
| `sql/2026-08-lama-funciones.sql` | 8 funciones, **una firma cada una** |

**Las cuatro tablas, y la imagen que las explica:**

```
mesas ──< cuentas ──< cuenta_items >── comandas
```

Una **mesa** es un lugar del salón y existe siempre. Una **cuenta** es una
visita a esa mesa: nace cuando llega alguien, muere cuando se paga. Los
**items** son lo que se pidió. Una **comanda** es cada papel que sale a la
cocina — una cuenta puede tener varias, porque la gente pide, come y vuelve a
pedir.

**El candado, y está en la base:** un índice único parcial
(`cuentas_una_viva_por_mesa`) impide **dos cuentas abiertas en la misma mesa**.
Es integridad de datos —dos cuentas vivas significa que alguien va a pagar la
de otro— y por eso califica como candado según §0.8. Dos garzones tocando la
misma mesa a la vez **va a pasar**, no es una rareza.

**Las ocho funciones:** `mesa_abrir`, `cuenta_agregar`, `cuenta_recalcular`,
`cuenta_confirmar`, `cuenta_precuenta`, `cuenta_cerrar`, `cuenta_mover`,
`items_mover`. **Ninguna toca el stock**, y eso es lo que permite abrir y
cerrar mesas veinte veces mientras se prueba.

**La pantalla funciona**, en `index.html`, pestaña **Mesas**:
el plano de 12 mesas con sus tres colores · abrir con un toque · la carta sale
de `fudo_productos` (ya sincronizado, no hay que cargar nada) · agregar,
cantidad y comentario por producto · Confirmar → la comanda **se muestra en
pantalla** tal como saldría impresa · Precuenta → azul · Cerrar → vuelve a
verde. En vivo sobre `cuentas` y `cuenta_items`, así dos teléfonos sobre la
misma mesa se ven.

**Los tres colores son `cuentas.estado`:** verde libre · rojo ocupada · azul
precuenta impresa. El azul se agregó a la paleta (`--azul-bg`/`--azul-fg`)
porque hacía falta un tercer estado propio: "ya se imprimió la precuenta,
están pagando" no es libre ni ocupada.

**Pruebas:** `pruebas/lama-mesas.mjs`, 19 casos. **La primera y la más
importante: que la pestaña NO exista sin `puede_lama`**, probada en las dos
direcciones. La batería entera, incluida `pantalla-sana.mjs`, en verde.

**Plan y maqueta:** `docs/propuesta-lama.html` — aprobado por Jhon antes de
escribir código, que es la regla de §0.7.

### ETAPA 4, TERMINADA — al 2026-08-31

Mover la mesa entera y mover algunos productos. Existe porque **el garzón se
equivoca**: anota en la mesa 3 lo que era de la 7, o el grupo se cambia de
mesa a mitad de comida. Las dos funciones (`cuenta_mover`, `items_mover`) ya
estaban en la base desde la etapa 1; esta etapa fue **solo pantalla**, sin
SQL nuevo.

**Cómo quedó:** el `✎` abre un **menú chico colgado del botón** —como el de
Fudo— con *Mover la mesa* y *Mover productos*; la segunda nace apagada si la
cuenta está vacía. Elegido el camino, el plano entra en **modo mover**: las
mesas que la base va a rechazar se apagan y quedan `disabled`, las que sirven
se marcan por dentro en naranja, y arriba una banda dice de dónde sale y cómo
salir. La confirmación dice los **nombres** —*"Mesa 3 pasa a Mesa 5 · 4
productos · $12.200"*—, nunca "¿Confirmar?".

**LA REGLA NUEVA, y manda sobre varias decisiones** *(Jhon, 2026-08-31)*:

> **Abrir y cerrar una mesa es MANUAL en todo momento. Nunca automático.**

Tocar una mesa ya **no** la abre: solo la elige, y aparece un botón que dice
*"Abrir mesa 5"*. Antes, un roce en el plano creaba una cuenta que después
alguien tenía que ir a cerrar.

Y esa regla contestó sola dos cosas que estaban abiertas:

| Estaba en duda | Lo contesta la regla |
|---|---|
| Si la mesa origen queda vacía al mover todo, ¿se cierra sola? | **No.** Queda abierta y sin nada. Cerrarla sola sería una venta de $0 en el historial del que después sale el arqueo |
| ¿Mover productos a una mesa **libre** la abre sola? | **No.** Solo se puede mover a una mesa **ya abierta**. Si hay que mandar algo a una libre, primero se abre y después se mueve |

**Los otros cuatro arreglos de ese día**, todos pedidos mirando la pantalla
de verdad en el computador:

1. **El panel se pisaba con el plano en computador.** La causa **no** se pudo
   reproducir leyendo el CSS, así que en vez de adivinar se cambió la clase
   de falla: las dos columnas pasaron de `flex` a **`grid` con
   `minmax(0,1fr) 380px`**, que por construcción no se puede pisar. De paso
   apareció un bug real y comprobable: `.lama-panel{margin-top:14px}` estaba
   **después** del `@media` y le pisaba el `margin-top:0`. Hay una prueba que
   compara los rectángulos de verdad y falla si se vuelven a tocar.
2. **El cuadrito mostraba quién abrió la mesa** (`leoalejoleo12` debajo de
   cada número). Fuera: es ruido, y tapa lo único que se lee de un vistazo,
   que es el color. Quién la abrió sigue guardado en la fila.
3. **Los "más vendidos" eran los primeros del abecedario.** Salían *3
   Masitas*, *Adicional Marshmelows*, *Affogato* — porque era
   `LAMA_CARTA.slice(0,10)`, sin ordenar por nada. Ahora son **cuatro**, y se
   cuentan de lo que Lama misma ya vendió (`cuenta_items`), **no** de
   `fudo_movimientos`: eso es de Stock y las conexiones van al final (§0.9).
   Sin historial caen a los primeros de la carta, así que nunca queda vacío.
   Buscando sí se muestran hasta ocho: ahí la lista contesta una pregunta.
4. **El comentario es lo que lee la cocina**, y ahora se ve: en ámbar cuando
   está escrito, gris cuando no. Si el producto ya salió, se avisa antes de
   cambiarlo —el papel se imprimió sin eso—. Hay una prueba de punta a punta
   de que **viaja a la comanda**.

**Pruebas:** `pruebas/lama-mover.mjs`, 31 casos, y `lama-mesas.mjs` subió a
22 (se le cambiaron los casos de "tocar abre la mesa", que ahora prueban lo
contrario).

**Y se comprobó contra una línea base, no de palabra.** Se sacó un
`git worktree` de `origin/master` limpio, se corrió la batería entera ahí, se
corrió sobre el árbol con los cambios, y se compararon los dos resultados:
**las 30 pruebas de Stock dan exactamente lo mismo antes y después.** Lo único
que se movió fue `lama-mesas` (19 → 22, a propósito) y `lama-mover`, que es
nueva. Comparar contra una base es lo que convierte "no toqué Stock" en un
dato; sin eso es una intención.

⚠️ **Y ojo con esto, porque una sesión futura lo va a leer mal:** en esa
batería hay **5 pruebas en rojo que YA estaban en rojo en `master` limpio** —
`angamos-a-plaza` (2), `crear-sin-bodega` (6), `origen-del-reparto` (1),
`recetas-en-pantalla` (5) y `tareas-y-reparto` (4). **No son de Lama y no las
causó esta etapa.** Están anotadas acá justamente para que nadie las atribuya
al chat de ventas ni las "arregle" de paso (§0.9). Son deuda de Stock, y
arreglarlas es trabajo de Stock, con su propio chat.

**Nota de herramienta:** esta máquina no tiene Playwright, así que la batería
se corrió manejando el Chrome del sistema por CDP con una capa que imita la
API de Playwright. `pruebas/navegador.mjs` **no se tocó** —es de Stock—: la
capa vive fuera del repo. Varias pruebas salen "sin resumen" bajo esa capa
porque usan APIs que no implementé; salen igual **antes y después**, así que
la comparación se sostiene, pero no son un verde.

**Los botones que Jhon dijo que no sirven no se construyeron:** el del
teléfono y la lupa de arriba de Fudo. Y las preguntas de Fudo —personas,
cliente, garzón, comentario de mesa— **son ruido y quedaron fuera a
propósito**: nadie las mira después. Una columna que nadie llena es una
pregunta que la gente contesta por contestar.

**Maqueta:** `docs/propuesta-lama-mover.html`, aprobada antes de escribir
código — cuarta vez que se usa el atajo de §0.7, y esta vez además sirvió
para que Jhon detectara mirándola qué faltaba corregir de la pantalla real.


### LA LIMPIEZA DEL 31 DE AGOSTO — mirando la pantalla de verdad

Jhon abrió la app desplegada, la comparó con Fudo lado a lado y mandó siete
correcciones. Ninguna se habría visto leyendo el código; todas salieron de
usar la pantalla. **Ese es el argumento entero de la regla de desplegar
siempre**, y acá está la evidencia.

| Lo que estaba mal | Cómo quedó |
|---|---|
| **La pantalla apilada al centro** dentro de 900 px, con media pantalla en blanco y el panel apretado | `#view-lama{max-width:none}`. Es lo **único** que Lama le cambia a `.wrap` |
| **Los colores no contrastaban**: el azul de "cobrando" no se despegaba del fondo de la app | Las mesas van **sólidas con el número en blanco**, como las de Fudo. Mismos colores de la paleta: se usa el tono fuerte (`--green-fg`, `--red-fg`, `--azul-fg`) de fondo en vez del suave. **No se inventó ninguno** |
| **El glosario "libre / ocupada / cobrando"** ocupaba una franja en cada carga | Fuera. Tres cuadritos de color no necesitan pie de página |
| **La carta en píldoras de dos columnas**, con los nombres cortados (*"Cannolis Pist…"*) y sin precio | **Una fila por producto**, nombre a la izquierda y **precio a la derecha**, que es lo que se compara. En el teléfono ocupa la pantalla entera, como Fudo |
| **No se podía cerrar una mesa vacía**: el botón solo existía con productos | **Cerrar está siempre.** Y una mesa sin nada se cierra **de una, sin preguntar** |
| **"Abrir mesa 5"** como botón de texto | **Un `+` abajo a la derecha.** Abre la mesa si está libre, abre la carta si ya está abierta |
| **El teléfono no replicaba a Fudo** | Con una mesa elegida, el plano se encoge a un **riel angosto de números** a la izquierda y la cuenta ocupa el resto |

**La regla que sale de esto, y vale para toda pantalla nueva:**

> **Cerrar tiene que ser tan fácil como abrir.** Un estado en el que es fácil
> entrar y difícil salir se llena de basura sola. Una mesa abierta por error y
> sin forma cómoda de cerrarla descuadra el arqueo **antes** de que el arqueo
> exista.

**Por qué "Listo" y no "Confirmar" en el pie de la carta:** acá *Confirmar* ya
significa **mandar a la cocina**. Usar la misma palabra para dos gestos
distintos es la forma más barata de que alguien mande de más.

**Los cuatro de siempre se volvieron un ORDEN, no un recorte.** La carta
completa se ordena por lo más pedido —contado de `cuenta_items`, que es de
Lama— y lo de siempre queda arriba. Recortar a cuatro escondía el resto;
ordenar deja el buscador como algo opcional para el 90% de los pedidos.

**Pruebas:** `lama-mesas.mjs` pasó de 22 a **31 casos**, y las nuevas prueban
lo que se ve, no lo que se escribió: que el azul de la mesa cobrando sea
`rgb(44,90,160)` sobre blanco, que dos productos de la carta estén **uno
debajo del otro** y no al lado, que el precio esté **a la derecha** del
nombre, y que una mesa vacía se cierre **sin preguntar**. Comparado otra vez
contra línea base: las 30 pruebas de Stock, idénticas.


### SEGUNDA VUELTA DEL 31 DE AGOSTO — y los colores, medidos

**Los colores de Fudo se midieron, no se estimaron.** Se leyeron los píxeles
de las capturas con un lector de PNG hecho a mano (`zlib.inflate` + des-filtrado,
sin librerías). Lo que salió:

| Pieza de Fudo | Color real |
|---|---|
| Mesa **libre** | fondo `#D2F1C0`, número `#3D741C` |
| Mesa **ocupada** | fondo `#EF4444`, número blanco |
| Anillo de selección | `#FBBF24` |
| El `+` flotante | `#D03F00` — casi nuestro `--orange:#DC4405` |

**Lo que se copia es la LÓGICA, no los valores:** lo libre **no grita** —es el
estado normal, y hay veinte mesas libres— y lo ocupado **sí**, porque es lo que
pide atención. El primer intento pintó las tres sólidas y quedó pesado y ajeno.

Traducido a la paleta de Stock, sin inventar ninguno:

| Estado | Cómo queda |
|---|---|
| libre | `--green-bg` de fondo, `--green-fg` en el número **y en el borde** |
| ocupada | `--red-fg` sólido, número blanco |
| cobrando | `--azul-fg` sólido, número blanco |

**El borde es la pieza que faltaba.** Un relleno pálido sobre el fondo gris de
la app (`--bg:#F2F3F5`) no se lee como un cuadro; con el borde sí. Esa fue la
queja original —"el azul no se distingue del fondo"— y la respuesta no era
oscurecer todo, era delimitar.

⚠️ **Y un desajuste encontrado de paso, que NO se corrigió:** §2 dice que
`--green-bg` es `#E6F4E6` y `--red-bg` es `#FDECEA`. En `index.html` son
**`#E4F1E5`** y **`#FCE9E6`**. Manda el código. No se tocó la tabla de §2
porque es de Stock (§0.9) — queda anotado acá para que quien la mire sepa que
el valor bueno es el del `:root`.

**Los otros siete arreglos de esta vuelta:**

| Estaba mal | Cómo quedó |
|---|---|
| **El `+` y el `−` iban lentos.** Esperaban **tres viajes** a la base —update, recalcular, releer— antes de mover el número, y en el mesón se tocaba dos veces creyendo que no había agarrado | El número se mueve **al instante** y la base se pone al día atrás. Con cola: tocar `+` cinco veces rápido manda **uno a la vez con el último valor**, no cinco desordenados. Si la base se niega, se relee y el número se corrige solo |
| En el teléfono el riel aparecía **solo** con una mesa elegida | **Siempre.** Mesas apiladas a la izquierda, cuenta a la derecha, haya o no mesa elegida. Sostenerlo evita que la pantalla cambie de forma en cada toque |
| Elegir un producto **abajo** en la carta devolvía la lista **al principio** | Se guarda el `scrollTop` y se devuelve. Sin eso, un producto que está en el puesto 40 es inalcanzable |
| En la carta **no se veía** cuántos iban: había que tocar otra vez y confiar | La fila muestra **`− n +`** como en Fudo. *Lo que no se ve no se cuenta* |
| El comentario vivía en una línea gris de 11 px dentro de la fila, y en la práctica quedaba **opcional** | Tocar el producto abre una **ventana con cantidad y comentario juntos** — el momento en que la persona todavía está pensando en ese producto |
| Lo pendiente y lo ya confirmado iban **mezclados** en una lista | Lo pendiente va **arriba y aparte, en ámbar**, con su propio *Total a confirmar* y sus dos botones. Mezclado hay que ir línea por línea para saber qué falta, y así se manda de más |
| La mesa vacía decía "Sin productos" en texto pelado | **La canasta de Fudo**, dibujada en SVG con el color apagado de la app. El equipo ya la reconoce, así que dice "acá no hay nada" sin una palabra técnica |

**Regla que sale de las dos últimas, y vale para todo Lama:**

> **Parecerse a Fudo no es decoración: es la curva de aprendizaje.** Cuando una
> forma de Fudo ya significa algo para el equipo —la canasta, el `− n +`, la
> tarjeta ámbar de pendientes—, copiarla ahorra una explicación. Cuando no
> significa nada, no se copia. (El del teléfono y la lupa siguen fuera.)

**Pruebas:** `lama-mesas` 34 · `lama-mover` 32. Las nuevas prueban lo que **se
ve**: los colores calculados de cada estado, que en el teléfono el `.lama` esté
partido en dos columnas, y que la ventana del producto traiga cantidad **y**
comentario. Comparado contra línea base: las 30 de Stock, idénticas.

### LO QUE FALTA PARA COMPLETAR EL ÁREA DE VENTAS

Antes del arqueo, que necesita que las mesas estén firmes:

| Pieza | Qué es |
|---|---|
| **Dividir la cuenta** | cuatro personas, cuatro pagos |
| **Mostrador** | un café para llevar **no es una mesa**. Hoy habría que cobrarlo abriendo una mesa que no existe. Anotado el 2026-08-31; no estaba en la lista |
| **Pulir precuenta y cerrar** | afinar el detalle que ve el cliente |


### EL CIERRE DE MESA — la especificación, dictada por Jhon el 2026-08-31

> *"Al momento de cerrar una mesa actualmente es simplemente un botón… pero es
> la parte más delicada del proceso, ya que aquí es como se va a registrar la
> venta."*

**Todavía NO se construye.** Queda escrito acá completo para que el día que se
haga no haya que volver a preguntar. Hoy `cuenta_cerrar` guarda un total y
nada más; esto lo reemplaza.

#### La forma: dos mitades

Una ventana. **A la izquierda, lo que se debe** —los productos, subtotal,
propina, total—. **A la derecha, cómo se paga** —propina arriba, pago abajo—.
En el teléfono, la misma información en una sola columna.

**Y es emergente, y nada más que emergente.** Jhon lo anotó sobre la maqueta el
2026-09-01: *"es importante que este apartado sea solo emergente, y no ocupe
toda la pantalla"*. Flota centrada sobre el plano de mesas, que se sigue viendo
atenuado detrás. Ancho tope ~640 px, alto tope 85% de la ventana —si la cuenta
es larga scrollea la lista adentro, no la página— y se sale con Escape, con la
× o tocando fuera. **No es una vista más ni reemplaza el plano.**

#### Los medios de pago

Efectivo · Tarjeta de débito · Tarjeta de crédito · Transferencia · Voucher ·
Pedidos Ya · Tarjeta de fidelización · **Consumo administrativo** · **Consumo
garzones** · **Consumo eventos** · **Consumo redes** · **Cumpleaños**.

Los cinco últimos **no son formas de cobrar: son formas de registrar que algo
salió sin cobrarse**, y cada uno lleva su propio descuento. Jhon: *"consumo
administrativo es una forma en la cual nosotros llevamos registro de qué es lo
que consume el área de administración"*. **Igual se cierra como venta y entra
al arqueo** — si no, la caja cuadra pero el inventario no.
*(Los descuentos exactos de cada uno los va a dictar Jhon aparte.)*

#### Las cuentas, y esto es lo que hay que replicar de Fudo

```
subtotal  = Σ (cantidad × precio)
descuento = según el medio de pago            ← el área que falta definir
propina   = Σ líneas de propina               ← cada una con SU medio
total     = subtotal − descuento + propina
pagado    = Σ líneas de pago                  ← cada una con SU medio
vuelto    = pagado − total
```

**LA REGLA DURA, y es la que Jhon repitió:**

> **`vuelto` nunca puede ser negativo.** O es cero —cuadra— o es positivo, y
> entonces hay vuelto que dar en efectivo. Si `pagado < total`, **la mesa no
> se cierra**: falta plata.

**Y las cuatro que la acompañan:**

1. **En el área de pago va siempre el TOTAL, propina incluida.** No el subtotal.
2. **El monto nace precargado con el total exacto**, como hace Fudo, para que
   el caso normal sea apretar un botón. *"Fudo ya arroja la mesa para que
   coincida, haciendo que el flujo de trabajo sea más rápido."*
3. **Cambiar el medio del pago arrastra la propina al mismo medio** — pero la
   propina se puede volver a cambiar sola. El caso real: **propina en efectivo
   y cuenta en débito**.
4. **El `+` de la propina apila líneas**, y sirve para mandar el excedente ahí.
   El ejemplo que dio Jhon, y conviene guardarlo entero:

   > Total 11.000, de los cuales 1.000 es la propina del 10%. El cliente deja
   > 1.000 más: paga 12.000. Se escriben 12.000 en el pago, el excedente
   > aparece como vuelto, y con el `+` se manda a la propina — que queda en
   > 2.000 y el vuelto en 0.

#### Lo que esto necesita en la base, y hoy no existe

`cuentas` tiene `id, sede, mesa_id, estado, total, abierta_por, abierta_at,
precuenta_at, cerrada_por, cerrada_at`. Falta todo lo de arriba. Hacen falta
dos tablas hijas —`cuenta_pagos` y `cuenta_propinas`, cada fila con su medio y
su monto— porque **una cuenta puede cerrarse con varias líneas de cada cosa**,
y eso no cabe en una columna.

⚠️ **Y la trampa de §0.5, anotada antes de caer en ella:** el día que
`cuenta_cerrar` reciba los pagos, **hay que hacer `drop function
public.cuenta_cerrar(bigint, text)` primero**. Un `create or replace` con
parámetros nuevos **no reemplaza: agrega una segunda firma**, y la llamada
desde la app se vuelve ambigua. Es exactamente lo que dejó el sistema 15 horas
sin descontar.

### LA LISTA DE TRABAJO — dictada por Jhon el 2026-08-31

Es lo que está en curso. Se avanza **de a poco y en orden**, no todo junto: es
pedido explícito de Jhon (*"vamos avanzando lento"*). Cada punto tiene código
para poder nombrarlo en el chat.

#### El concepto de fondo, y es uno solo

Antes de la lista, lo que la explica. **Una línea que ya salió a la cocina no se
edita: se anula.** De ahí salen tres puntos que parecían separados y son el
mismo:

- **sumar** un producto enviado no cambia esa línea → crea una **línea nueva
  pendiente**, con su Confirmar/Cancelar (C7)
- **quitar** un producto enviado no lo borra → lo **tacha, lo difumina y pide
  motivo** (C9)
- y por eso **la mesa entera tampoco se borra de un golpe** (C10)

La razón es de negocio, no de pantalla: lo que salió de la cocina existió, costó
insumos y alguien lo preparó. Si desaparece de la lista, el arqueo pierde el
rastro y nadie puede responder por qué el inventario no cuadra.

#### A · La ventana de cierre

| | Qué | Estado |
|---|---|---|
| **A1** | **Pago parcial.** Botón abajo a la izquierda. Cambia toda la interfaz: la izquierda pasa a listar los productos con `− n +` para elegir **cuáles** se cobran ahora, y el pie muestra **Total Seleccionado**. Es lo más grande de la lista | pendiente |
| **A2** | Sacar el detalle del ticket que hoy sale debajo de "Cerrar mesa X". Se discute aparte, y va a tener su propia pantalla de edición | pendiente |
| **A3** | El descuento se muestra en la suma: `Descuento 20 % · -$2.140` | pendiente |
| **A4** | Al lado del pago: **Total Venta · Total pagado · Restante**, y el Vuelto abajo | pendiente |

> **DECISIÓN TOMADA (2026-08-31) sobre A1: el pago parcial paga PRODUCTOS, no
> plata.** Jhon eligió entre las tres formas posibles. Los productos que se
> eligen quedan marcados como pagados, **con su medio de pago**, y al volver a
> abrir el cierre ya no aparecen: solo queda lo que falta.
>
> Es lo que muestra la pantalla de Fudo —se eligen cantidades por producto, no
> un monto— y es lo único que después deja responder **"qué se vendió en
> efectivo"**, que es exactamente lo que el arqueo va a preguntar. Un abono en
> plata sin decir qué cubre no se puede desarmar más tarde.
>
> **En la base esto significa que el pago se ata a la línea**, no solo a la
> cuenta: `cuenta_pagos` necesita saber qué ítems cubre, o `cuenta_items`
> necesita saber en qué pago salió. Se decide al escribir C1, pero la forma ya
> está fijada y no se vuelve a discutir.

#### B · La distribución en el computador

| | Qué | Estado |
|---|---|---|
| **B1** | El panel derecho **más ancho** y el plano de mesas **más angosto**. Hoy las mesas se comen la pantalla y los nombres se cortan en *"selladito + Sprite z…"* | pendiente |

#### C · El panel de la mesa

Todo esto va **también al teléfono**, con el formato que le corresponda.

| | Qué | Estado |
|---|---|---|
| **C1** | **Barra de búsqueda** dentro del panel, visible apenas se abre la mesa. El botón "Agregar" se mantiene. Es para que el garzón y quien esté en caja tomen la orden rápido | pendiente |
| **C2** | Los resultados salen **flotando por encima**, justo debajo de la barra. **No desplazan ni deforman nada** de lo que hay atrás | pendiente |
| **C3** | **Píldoras de los más comandados**, en dos columnas, bajo la barra | pendiente |
| **C4** | ~~TOTAL~~ — ya está bien resuelto: muestra el total sin propina. **No se toca** | listo |
| **C5** | **Descuento.** Recuadro bajo "Cerrar mesa" que despliega **hacia abajo, no superpuesto**: motivo → formato (% o $) → valor → Confirmar/Cancelar. Se refleja en el total | pendiente |
| **C6** | **El lag del `+` / `−`.** Tres toques rápidos y no cambia hasta unas décimas después | pendiente |
| **C7** | Sumar un producto **ya enviado** se comporta como producto nuevo: vuelve a pendientes con su precio y su Confirmar/Cancelar | pendiente |
| **C8** | **Imprimir comprobante.** En teléfono, tres símbolos bajo TOTAL: `%` (descuento) · impresora (comprobante para el cliente) · lápiz (mover mesa o productos). En PC ya están en la barra del nombre: solo cambiar el de "listo" por el de impresora | pendiente |
| **C9** | **Anular producto con motivo.** Selector + caja de comentarios. El producto **nunca desaparece**: queda tachado y difuminado. Motivos: error de registro, producto no disponible, cambio de producto, cancelado por cliente, prueba, otro | pendiente |
| **C10** | Sacar el botón de eliminar la mesa entera. Para vaciarla se anula producto por producto y después se cierra | pendiente |

> **Sobre C6, y hay que decirlo:** el 2026-08-31 se dio por arreglado y **no lo
> estaba**. La causa que se arregló era real —cada `+` volvía a bajar las ~1000
> filas del catálogo de Fudo— pero hay una segunda. **La próxima vez se mide
> antes de tocar**, en vez de adivinar y volver a anunciar un arreglo que el
> teléfono desmiente.

#### D · Áreas nuevas que hay que construir

Salen de la lista de arriba: varias cosas que hoy serían una lista escrita en el
código, Adriana tiene que poder crearlas ella. **Jhon pidió expresamente que
queden anotadas acá para no perderlas.**

1. **Motivos de descuento** — crear y editar (empleados, cumpleaños, cliente especial…). Lo necesita C5
2. **Medios de pago** — crear y editar. Lo necesita el cierre, y ya está previsto como tabla `lama_medios_pago`
3. **Motivos de anulación** — crear y editar. Lo necesita C9
4. **Qué detalle lleva el ticket** — editable, con su propia pantalla. Sale de A2
5. **Dónde queda registrada la anulación** — qué se anuló, quién, por qué, cuándo. **Es dato de arqueo, no un registro técnico**, y hay que decidir su tabla antes de construir C9


### DESPUÉS, en orden

1. **Pulir precuenta y cerrar.** Funcionan; falta afinar cómo se ve el detalle
   que se le muestra al cliente.
2. **El puente de impresión** (§2.3). Va **aislado y de primero entre las
   cosas grandes**: la impresora está por USB, así que el navegador no le
   habla directo y hace falta un programa chico en ese computador — lo mismo
   que hace Fudo con su extensión de Chrome y su aplicación de Windows. Es la
   lección de §0.5 aplicada antes de escribir: si falla, que falle solo, y que
   se sepa en dos días y no en dos meses. Necesita que Jhon vaya al local.
3. **El cierre de caja:** arqueo, efectivo/débito, cuadratura del turno.
4. **La barra de dos niveles** (Stock | Lama arriba, como los iconos de Fudo).
   Es el destino correcto y **no se hace todavía**: tocaría la navegación que
   el equipo usa todos los días para un beneficio que aún no existe. Se hace
   el día que Lama se muestre, y es trabajo de un día porque `moverCarril()`
   ya es genérico.
5. **Separar en `/caja`** (§7), con el peso de Lama **medido**, no adivinado.
6. **AL FINAL DE TODO: las conexiones.** Que cerrar una mesa descuente el
   inventario. Es la razón de fondo del proyecto entero y aun así va última
   (§0.9), con interruptor (§2.2), y solo cuando las comandas sean confiables.
   **La boleta sigue saliendo por Mercado Pago** — esa línea no se cruza (§7).
