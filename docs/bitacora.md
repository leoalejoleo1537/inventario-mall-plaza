# Bitácora

> Sale del archivo madre `CLAUDE.md`, que se cargaba entero en cada sesión.
> Se separó el 2026-08-31 para dejar de pagar 69.000 tokens por sesión.
> **Las reglas duras siguen viviendo en `CLAUDE.md`.** Esto es el registro de lo que se hizo, y por qué.

---

## 11. Bitácora (cambios importantes, lo más reciente arriba)

- **2026-08-28** — **Una meta contaba capuchinos creyendo que eran aguas.** Jhon:
  *"el agua Bosqua de Angamos vendió más de 80 y en la meta me aparecen sólo
  dos"*. Su hipótesis era que cerrar una meta borraba el conteo; no era eso, y
  la respuesta real es peor y más útil.
  1. **No contaba de menos: contaba OTRO PRODUCTO.** El id 584 es "Agua Bosqua
     con gas" en Plaza y **"Capuccino Pedidos Ya"** en Angamos. Los ids de Fudo
     solo son únicos dentro de una cuenta —`fudo_productos` lo dice en su propia
     tabla, `unique (sede, fudo_product_id)`— y tanto `meta_productos` como
     `meta_avance` los trataban como globales. Esos "2" eran capuchinos.
  2. **Es §9.2 entrando por una puerta que nadie había cerrado.** Ese aviso
     —*"los ids de Fudo son de otra cuenta"*— estaba escrito para las recetas.
     Las metas nacieron después y repitieron el error, porque la regla vivía en
     un párrafo y no en la forma de la tabla. Ahora la sede está en la clave:
     **una regla escrita solo en prosa se vuelve a incumplir.**
  3. **Tres huecos que se sumaban, y el tercero es un viejo conocido.** El
     buscador pedía el catálogo con `.limit(1000)` y entre las dos sedes hay
     ~1.280 productos: Supabase corta ahí **sin avisar** (bloque A de §6), así
     que media carta de Angamos nunca llegó al buscador y la meta se guardó con
     un solo id. Se lee por páginas hasta que una venga incompleta — sirve con
     dos sedes y con seis.
  4. **Y un cuarto que todavía no daba la cara.** `meta_avance` sumaba
     `cantidad_vendida` sin agrupar por línea de venta, y un producto con receta
     de 3 insumos deja 3 filas en `fudo_movimientos`: esa meta habría contado
     **el triple**. El agua no tiene receta de varios insumos y por eso el error
     estaba escondido detrás del otro. Arreglado con un `distinct on
     (sede, fudo_item_id)`.
  5. **La hipótesis de Jhon se descartó leyendo, no probando.** `meta_avance` no
     guarda ningún contador: recalcula desde `fudo_movimientos` en cada llamada,
     así que cerrar y reabrir no puede perder nada. Decirlo con el código
     delante evitó que buscáramos un bug que no existía.
  6. **Lo que abre, y es más grande que la meta.** Contar lo vendido resultó ser
     una consulta agrupada sobre datos que ya teníamos desde julio — sin tocar
     la API de Fudo (§0.7). Sirve para proyectar el reparto, para saber qué
     ofertar en sobre-stock, y en Lama, para ordenar la carta por lo que de
     verdad se vende. La única salvedad: solo alcanza hasta donde el motor
     estuvo encendido en cada sede.

- **2026-08-28** — **La foto automática corría perfecto y la pantalla igual
  quedaba vacía.** Jhon: *"no se guardó el inventario desde el 25 y hoy ya es
  28"*. Se arregló y no se perdió nada; lo que vale es cómo se llegó.
  1. **La evidencia dio vuelta el diagnóstico en el primer dato.** Yo iba a
     buscar una tarea caída. Pero el respaldo `historial_auto` **sí tenía el
     26 y el 27**. Como la instrucción es UNA sola —borra el día, escribe en
     `historial`, escribe en `historial_auto`— y Postgres deshace todo junto
     si algo revienta, que el respaldo estuviera probaba que la parte de
     `historial` **no había fallado: no se estaba ejecutando.** Un solo
     resultado descartó dos de las tres causas posibles.
  2. **La causa: volver a correr un archivo viejo del repo.** `cron.schedule`
     con el mismo nombre pisa lo que había, así que un `.sql` anterior —de
     cuando la foto solo escribía en `historial_auto`— reemplazó la tarea
     buena. **Es §0.1.2 al revés:** ahí el peligro es *leer* el repo y creer
     que es producción; acá fue *ejecutar* el repo y hacer que producción
     retroceda. El repo no es el estado, y correrlo tampoco lo actualiza:
     lo sobrescribe con una foto vieja.
  3. **Se comprobó leyendo la instrucción instalada, no contando tareas.**
     `command like '%into public.historial (%'` sobre `cron.job`. Contar
     habría dicho "dos tareas, las dos activas" y habría sido cierto e
     inútil — es exactamente la técnica de §0.2.1: mirar el cuerpo.
  4. **Las dos redes salvaron el día, y esa es la moraleja.** El respaldo
     guardaba nombre, sección, stock, mínimo, máximo y activo desde que se
     escribió pensando en el 9 de agosto (§0.6). Por eso el 26 y el 27 se
     devolvieron enteros en vez de perderse. **De lo que hay copia se
     recupera; de lo que no, no** — otra vez.
  5. **La prevención es de una línea y va donde puede doler.** Los dos
     archivos superados llevan ahora **⛔ NO CORRER** en la primera línea, con
     el nombre del bueno. No se borran: su texto explica por qué la foto
     existe. Un archivo del repo no puede decir qué está instalado, pero sí
     puede decir que no se ejecute.
  6. **Queda una decisión de Jhon, sin tocar:** la tarea borra la foto del día
     antes de escribirla, así que pisa la que el equipo guardó a mano después
     de contar. Para restaurar da igual; para ellos no es la que contaron.

- **2026-08-28** — **Nace Llamita Lama, y el archivo madre pasa a tener dos
  mitades.** El área de ventas —mesas y comandas— quedó con su etapa 1
  completa: tres SQL corridos, cuatro tablas, ocho funciones y la pantalla
  funcionando escondida. El detalle está en §12; acá van las decisiones de
  método, que son las que se pierden si no se escriben.
  1. **La regla más importante es una que prohíbe trabajar** (§0.9): mientras
     se construya Lama, **no se toca nada de Stock**. Jhon lo pidió con esas
     palabras y tiene una segunda razón además del riesgo: **si Stock no se
     toca, nada que falle en Stock puede ser culpa del chat de Lama.** Eso es
     lo que hace el trabajo diagnosticable.
  2. **Las conexiones van al final**, y es lo contrario de lo tentador. Que
     cerrar una mesa descuente el inventario es la razón de fondo del proyecto
     entero, y aun así se deja para lo último: hoy Lama no toca el stock, y
     por eso se pueden abrir y cerrar mesas veinte veces probando sin
     descuadrar nada.
  3. **`relation "m" does not exist`, y la primera hipótesis fue falsa.** Yo
     acusé a las comillas de dólar y al separador del editor; convertirlas no
     arregló nada, y simular un separador ingenuo contra las dos versiones no
     reprodujo el error. La explicación que sí encaja: mis variables eran de
     **una letra**, y si Postgres no la reconoce como variable, `m.sede` se
     lee como *"columna sede de la TABLA m"* → 42P01. `mermar`, que funciona,
     usa `pr`, `lo`, `mv`. Se renombraron todas a `v_*` **y** se partió en 9
     bloques, para que un fallo futuro diga cuál. **La lección: descartar una
     hipótesis con una prueba vale más que cambiar código a ver si pasa.**
  4. **La puerta se abre con una columna, no con el correo escrito en el
     código.** Es la doctrina de §0.65 punto 5, que salió del día que un
     candado a mano impidió que llegara el pan. Y `puede_lama` nace apagada
     para todos: una cuenta nueva, una fila que falta o una lectura que no
     llegó significan todas lo mismo — no ve Lama.
  5. **La maqueta antes del código, por tercera vez** (`docs/propuesta-lama.html`).
     Jhon la aprobó antes de que se escribiera una línea de pantalla. Las tres
     veces que se usó ahorró la iteración de estética; la vez que se saltó, se
     perdió el trabajo entero.

- **2026-08-21** — **Tres bugs del teléfono, y el del medio no se veía leyendo
  el CSS.**
  1. **Ajustes se salía de la pantalla en Productos y en Actividad.** Jhon:
     *"no se adapta al teléfono y se ve todo en formato grande, sacando de
     proporción todo"*. La causa es una regla que está BIEN donde estaba y
     significa otra cosa al girar: `.aj` lleva `align-items:flex-start` para
     que el riel no se estire a lo alto cuando va **al lado**; en el teléfono
     esa misma regla —ya en columna— hace que cada hijo se anche **lo que pida
     su contenido** en vez de tomar el ancho de la pantalla. Y el contenido
     pedía mucho, porque las filas de Actividad y de Productos llevan una línea
     sin cortes (`white-space:nowrap`): el panel medía **470 px dentro de un
     teléfono de 390** y toda la app se corría hacia la izquierda. Arreglado
     con `align-items:stretch` en la franja del teléfono — recién ahí los
     puntos suspensivos del final del nombre entran a trabajar.
     **La lección de método:** `min-width:0` ya estaba puesto y no alcanzaba,
     porque en columna el que manda es el eje transversal. Mirar el CSS no lo
     delataba; **medir sí**. La prueba nueva no pregunta "¿se ve bien?" sino
     **cuánto mide el documento contra cuánto mide la pantalla** — un número
     contra otro número, igual que el contador de consultas que destapó el
     bucle de Salud.
  2. **El botón Actualizar en Bodega prometía algo imposible.** Bodega no tiene
     cuenta de Fudo: no hay ventas que leer ni stock que devolver. Se esconden
     los dos —el de la barra y el atajo del menú— y **ninguno de los de
     Ajustes**, que es lo que Jhon pidió con esas palabras.
  3. **La etiqueta "Tipo" salía corrida.** Dos sitios mostraban la fila con
     `display:flex`, y `.field` está pensado para apilar: la etiqueta se iba al
     lado del campo en vez de encima. Ahora se muestra con `''`, o sea el
     display que la hoja de estilo ya le da. Es cosmético y por eso importa:
     una etiqueta torcida es lo que hace que una app se sienta poco seria.
  Prueba nueva: `pruebas/telefono-y-bodega.mjs`, 17 casos.

- **2026-08-13** — **El problema de los ID se cerró con la idea de Jhon, no con
  la mía. Y con eso se construyó el reparto desde bodega.**
  1. **Yo estaba emparejando dos catálogos que nunca fueron pensados para
     calzar.** Los 234 nombres de bodega venían copiados de la bodega vieja, así
     que no tenían por qué parecerse a como Plaza y Angamos nombran las cosas
     hoy. Cada pasada de emparejado dejaba un resto, ese resto pedía otro
     diagnóstico, y Jhon se pasó un día corriendo informes para que yo dijera
     "parece que me equivoqué". Tenía razón en frenarlo.
  2. **Su idea: que bodega COPIE el catálogo del local.** Así el enlace no se
     adivina — nace hecho, porque el producto de bodega ES el del local copiado
     con su mismo nombre. Se hizo con dos cambios para no perder nada: **no se
     borró** el catálogo viejo (borrar se llevaba en cascada los 300 enlaces ya
     buenos y los productos que solo existen en bodega: bultos, quinoa, cacao),
     y **no se copió el lado no-congelador** de un par con doble estante.
  3. **Esa segunda decisión convirtió su regla en estructura.** "Todo lo que
     llega a Plaza llega al congelador" dejó de ser una decisión que alguien
     puede equivocar producto por producto. Y salió general sin haberla pensado
     general: el script se salta el lado no-congelador **solo cuando existe** un
     congelador con el mismo nombre base — Plaza tiene esos dobles, Angamos no
     tiene ninguno, así que en Angamos entran los "Vitrina", que allá son el
     único estante. Sin una excepción escrita.
  4. **Resultado: Plaza 219/219 y Angamos 222/222, `sin_origen` en 0.** Bodega
     pasó de 234 a 303 productos. Los 17 tés y las 14 familias con doble estante
     que iban a haber sido trabajo manual se resolvieron solas, porque estaban en
     Plaza.
  5. **La lección de método, y es la que vale:** cuando emparejar dos listas
     deja un resto que exige otro diagnóstico, y otro, **el problema no es el
     algoritmo: es que las dos listas no comparten origen.** Copiar una desde la
     otra convierte el emparejado en construcción. Sirve para cualquier catálogo
     futuro — otra sede, otro proveedor.
  6. **Y con eso, el reparto desde bodega.** Lo que se escribe es idéntico a lo
     que escribe el local hoy, así que el jefe de turno lo recibe en su pestaña
     de siempre y no se tocó una línea de ese lado (§0.7).

- **2026-08-13** — **Enlaces no tenía salida manual, y Jhon lo encontró
  probando.** Abrió un producto de bodega que él reconocía como "Sprite
  Zero" y la pantalla decía que no había ningún candidato en ninguna sede.
  Sin buscador, sin forma de decirle al sistema "es este".
  1. **El diagnóstico, comprobado contra la base real y no supuesto:** el
     producto que abrió era **`Sprite cero`** (con c), un error de tipeo
     dentro de bodega, distinto de `Sprite zero` (con z) — que **sí** está
     enlazado en las dos sedes desde el 12. `clave_nombre()` corrige
     tildes/mayúsculas/espacios, no errores de tipeo, así que nunca iba a
     proponer nada. Y buscando a mano tampoco aparece nada, porque el
     `Sprite zero` de Plaza ya tiene dueño: la base no deja que un producto
     del local tenga dos orígenes de bodega. **No faltaba un enlace — sobraba
     un producto.** Es la misma familia de duplicados que ya documentaba
     `docs/pendiente-gemelos-sin-pareja.md`, y quedó agregado ahí.
  2. **Aun así, la pantalla estaba coja: no había manera de buscar a mano.**
     El algoritmo propone por nombre, pero cuando falla —por un tipeo, o
     porque en verdad no hay candidato— la persona quedaba sin salida.
     Se agregó **"🔍 Buscar otro producto"** en cada sede, siempre visible
     (no solo cuando el automático viene vacío): un buscador de texto libre
     sobre TODO lo que no esté ya tomado en esa sede. Sigue guardando por
     id — la búsqueda solo arma la lista, nunca escribe un par sin que se
     toque.
  3. **La pregunta de fondo, contestada:** `producto_enlace` es solo para el
     REPARTO — que un envío de bodega sepa a qué producto del local sumarle.
     **No tiene nada que ver con el descuento de Fudo.** Eso lo hacen las
     `recetas`, que son por sede y ya existían antes de bodega. Un producto
     "sin enlace" hoy no deja de descontar nada — el reparto ni siquiera
     está construido todavía. Vale la pena decirlo así de claro porque los
     dos sistemas se llaman parecido y es fácil confundirlos.

- **2026-08-12** — **Los gemelos, y la pantalla de Enlaces.** Bodega ya sabe qué
  producto de cada local es el mismo que el suyo, y de ahora en adelante eso se
  arregla desde la app y no con un SQL mío.
  1. **290 pares escritos**: 144 con Angamos, 146 con Plaza. Se propusieron por
     nombre exacto y se guardaron por id. La vista previa y la escritura usan
     **la misma vista** (`gemelos_propuestos`), no dos consultas parecidas —
     que es la regla que salió del 9 de agosto.
  2. **El informe dijo 148 para Plaza y se escribieron 146.** No se rompió
     nada: esos dos nunca llegaron a existir, porque Jhon renombró productos
     entremedio y dejaron de calzar. Cuáles eran exactamente **no se puede
     saber** —el informe no se guardó— y eso quedó escrito así en
     `docs/pendiente-gemelos-sin-pareja.md` en vez de inventar dos nombres
     plausibles.
  3. **Jhon reclamó, con razón aparente, que yo estaba enlazando por nombre.**
     No era así —la tabla guarda dos ids y ninguna palabra— pero mi forma de
     contarlo lo hacía parecer. La aclaración quedó en §0.7: el nombre PROPONE
     una vez, el id GUARDA para siempre.
  4. **La pantalla de Enlaces**, con maqueta aprobada antes de construir
     (`docs/propuesta-enlaces.html`). Pedirla fue idea suya y ahorró la
     iteración de estética que siempre viene después.
  5. **Dos funciones con el mismo nombre no dan error, y esa es la lección.**
     Escribí `candidatos()` sin ver que Recetas ya tenía una: la última gana,
     la primera deja de existir, y la pantalla decía "no hay ninguno parecido"
     para productos que sí tenían gemelo. **Es peor que el choque de `const`
     del 10**, porque aquel al menos reventaba el archivo y se notaba al
     instante. `pruebas/pantalla-sana.mjs` ahora tiene cuatro comprobaciones:
     ids repetidos, `$()` que apunta al vacío, que el guion se pueda leer
     entero, y **nombres de función repetidos**.
  6. **Una alarma que miente se deja de mirar.** El aviso de "ya existe algo
     parecido" se quedaba pegado del nombre anterior cuando la respuesta
     llegaba tarde. Ahora se descarta si el nombre cambió mientras viajaba.

- **2026-08-10** — **La bodega nueva arranca: `central`, sus tarjetas y las
  mermas.** La decisión que estaba pendiente desde el 9 se tomó — construir
  desde cero, sin heredar nada (§0.7).
  1. **El archivo madre estaba mintiendo por omisión.** `central` se creó el
     10 y esta bitácora seguía diciendo *"bodega queda EN PAUSA, la decisión
     es de Jhon y está pendiente"*. Un chat nuevo habría leído eso con toda
     confianza y replanificado sobre una bodega que ya no existe. **Es el
     mismo error del clon local atrasado, pero adentro del propio archivo:**
     una sección de estado que envejece engaña más que no tenerla.
  2. **Los cimientos NO estaban corridos, y el cuaderno no tenía la culpa.**
     Yo lo acusé de mentir al ver "2 scripts de bodega anotados" sin las
     tablas puestas; los dos anotados eran **informes de solo lectura**. El
     cuaderno se queda corto —`bodega-nueva-desde-cero` sí corrió y no quedó
     anotado— pero no se pasa de largo. **Sirve para saber qué se hizo; no
     sirve para concluir que algo no se hizo.**
  3. **Las tarjetas de crítico, y el hueco que encontró Jhon.** La lista del
     local define Crítico como *"el semáforo lo marca O alguien lo marcó
     urgente a mano"*, y la tarjeta solo miraba el semáforo: un producto
     marcado urgente que no estuviera bajo el mínimo era **invisible desde
     bodega**, que es justo donde se arma el reparto. La definición dejó de
     vivir dentro del filtro de la lista y pasa a ser `entraEnCritico()`,
     usada por las dos pantallas. **Una regla escrita dos veces es cómo se
     produjo el hueco.**
  4. **Mermas, con la resta y la anotación adentro de una sola función.** Si
     se hicieran en dos llamadas desde el teléfono y se cortara la señal en el
     medio, quedaría stock bajado sin anotar. La función se niega a mermar
     fuera de `central`, a dejar negativo, y a mermar un perecedero sin decir
     de qué fecha — **en la base, no en la pantalla**, para que no dependa de
     que un botón esté escondido.
  5. **Probada de punta a punta antes de publicarla**, con dos productos de
     mentira que nacen y mueren en el propio script. No se usó uno real a
     propósito: Adriana estaba contando, y tocarle el stock a algo que acaba
     de contar es borrarle el trabajo. Lo que confirmó: el de fechas bajó de
     10 a 6 quitando la fecha entera, `detalle` guardó de qué día era, y al
     deshacer **la fecha borrada se volvió a crear con su día original** y el
     motivo siguió diciendo `robo` y no `deshecha`.
  6. **Rompí la app entera con una línea, y de ahí salió una prueba.**
     `const MOTIVOS` para las mermas chocó con el de Recetas. Dos `const` con
     el mismo nombre no son un error de esa línea: el navegador **no lee el
     archivo completo**. La pantalla se dibujaba igual y no hacía nada, y las
     dos comprobaciones de `pantalla-sana.mjs` pasaron en verde con la app
     muerta, porque miran el HTML y no el guion. La tercera comprobación ya
     existe y está probada en las dos direcciones.

- **2026-08-09** — **Angamos quedó en cero y no se pudo recuperar. El error más
  caro del proyecto.** La regla completa está en §0.6; acá va cómo se llegó,
  que es la parte que sirve.
  1. **El trabajo del día.** Se empezó el área de bodega. Un informe de solo
     lectura destapó que **bodega tiene 117 productos duplicados** y que **las
     recetas de Angamos apuntaban a productos de bodega** — 228 ventas habían
     descontado 254 unidades de la sede equivocada entre el 5 y el 8. El
     repunte de recetas funcionó: 206 de 215 renglones corregidos, y los 9
     restantes salieron en la comprobación.
  2. **Y a las 17:00, 260 productos de Angamos quedaron en cero.** Sigue **sin
     determinarse qué lo causó**, y no hay que inventarlo. Lo comprobado: de
     los 7 archivos entregados ese día, había **una sola escritura sobre
     `productos` y era un `insert`** de 9 filas — ningún `update`, ningún
     `delete`. Eso descarta un culpable; no identifica al otro.
  3. **Lo irrecuperable no fue culpa del comando, fue culpa de la falta de
     copia.** `historial` estaba **vacío para Angamos**: nadie había apretado
     nunca "Guardar inventario de hoy" en esa sede. Sin foto no hay vuelta
     atrás, y el stock se cargó de nuevo a mano.
     La lección general: **el respaldo va antes del primer paso que escribe,
     no antes del paso que parece más peligroso.** El plan tenía el respaldo
     en el paso 7 y las escrituras empezaron en el 3.
  4. **El latigazo, que es el concepto que hay que quedarse.** Jhon: *"este
     error tiene latigazo… las repercusiones vienen mañana"* — Adriana iba a
     armar el reparto mirando lo que faltaba el 07 y no el 09. **Un dato malo
     no hace daño cuando se corrompe: hace daño cuando alguien decide con
     él.**
  5. **Dos veces el mismo descuido en un día: filtrar por `activo = 'SÍ'`
     donde no correspondía.** Eliminar en esta app desactiva, no borra. Una
     comprobación de existencia que solo mira activos no ve lo que el equipo
     eliminó a propósito. En el repunte hizo que **la vista previa mintiera
     por omisión** — mostró 206 casos cuando eran 215, y los 9 que faltaban
     solo aparecieron en la comprobación final, que sí miraba todo.
     De ahí sale la regla: **la vista previa y su comprobación tienen que usar
     exactamente el mismo filtro.**
  6. **Una hipótesis mía que los datos desmintieron, y conviene dejarla
     escrita.** Supuse que mi `insert` había duplicado productos que Jhon
     tenía eliminados. El bloque 4 del diagnóstico dijo que **no**: los 9
     creados no tenían ninguna copia desactivada. Anotarlo importa porque casi
     le hago revisar 9 productos que estaban bien (regla 0.1.5).
  7. **Bodega queda EN PAUSA por decisión de Jhon**, con la entrega del 27
     encima y alta aversión al riesgo. La decisión entre reconstruirla desde
     cero o seguir con la actual es suya y está pendiente.

- **2026-08-08** — **Se midió qué deja hacer Fudo con el catálogo, y una
  falsa alarma mía de por medio.** Jhon lo pidió porque es el problema de
  fondo de Adriana: 4 años de catálogo sucio que la pantalla de Fudo no la
  deja limpiar. Él lo llamó *"la joya de la corona"*. El resultado está en
  §8; acá va cómo se llegó, que es la parte que sirve.
  1. **La v1 de la prueba dio un veredicto FALSO.** Intentó crear un
     producto de mentira, crear falló con un 400 de esquema —el campo
     `active` no va en un alta— y al fallar crear se saltó desactivar y
     borrar, devolviendo *"la API no deja tocar el catálogo"*. **Nunca lo
     intentó.** Es la regla 0.1.5 incumplida por mí: concluir desde algo
     que no se probó. Por poco le cierra a Jhon la puerta más importante
     que tiene abierta el proyecto.
     **La regla que sale de ahí, y vale para cualquier diagnóstico:**
     un informe tiene que distinguir **"no se pudo probar"** de **"no se
     puede"**. La v2 tiene esas dos palabras distintas en la respuesta, a
     propósito.
  2. **La técnica que sí sirvió: preguntar sin tocar.** Para saber si un
     endpoint acepta una operación no hace falta ejecutarla — se le pide
     sobre un **id que no existe** y se lee qué contesta. Cuesta cero y no
     puede romper nada. Es la lección de la impresora (§7) llevada a su
     forma más barata.
  3. **Pero el 404 engaña, y esa es la trampa que hay que recordar.** Yo
     leí el 404 del DELETE como *"la operación existe, solo que ese
     producto no está"*. Falso: el DELETE sobre un producto **que sí
     existía** devolvió el mismo 404, y al releerlo seguía ahí. Era un 404
     **de ruta**. Lo que separó las dos lecturas no fue una consulta más
     lista: fue **releer después de actuar** — el mismo patrón que ya se
     usaba para el empuje de stock ("se comprueba releyendo lo que Fudo
     devuelve, no el 200") y que acá volvió a ser lo único concluyente.
  4. **Lo medido:** crear ✅ (201), desactivar ✅ (200), borrar ❌ (no
     existe). Y eso **habilita dos cosas que estaban esperando**: crear
     productos en Fudo desde el taller de recetas (§6.3) y apagar los
     duplicados de Adriana. Lo que no habilita es prometerle "borrar".
  5. **Falta la comprobación del mesón, y no la puede dar la API:** que
     un producto con `active: false` de verdad desaparezca de la pantalla
     de venta. El producto 917 "ZZZ PRUEBA CLAUDE - ignorar" quedó
     desactivado en el Fudo de Angamos justamente para eso — se mira y se
     sabe. **No se puede borrar, así que ahí se queda.**
  6. **Y la propia pantalla de Fudo corrigió mi hipótesis, el mismo día.**
     Yo había escrito que Fudo no deja borrar productos porque el
     historial de ventas apunta a ellos. El motivo era correcto; el
     alcance, no. Jhon intentó borrar `Crema Zapallo` y Fudo contestó
     *"está siendo usado en un combo o está adicionado en una venta"* —
     o sea que **borrar existe y funciona con productos vírgenes**; lo
     que no se puede borrar es lo que ya se vendió. Después de 4 años,
     eso es justamente todo lo que estorba.
     **La lección de método es la de siempre y van tres en un día:** la
     API contestó *qué* pasa, la pantalla contestó *por qué*. Ninguna
     consulta más lista habría dado ese mensaje — estaba en la interfaz
     que usa la gente. Cuando algo del lado de Fudo no cuadre, mirar
     también la pantalla, no solo el endpoint.
     De ahí sale además que la casilla **"Activo"** es un campo del
     propio formulario de Fudo: desactivar desde nuestro sistema no es un
     rodeo, es destildar esa casilla.

- **2026-07-30 (noche)** — **El archivo madre, reforzado para el salto a
  Angamos.** Jhon va a abrir un chat nuevo (las skills que instaló no cargan en
  el chat viejo), así que lo que no esté escrito acá se pierde. Se agregó:
  1. **Mapa de entrada** arriba del todo: con ~1500 líneas, un chat nuevo
     necesita saber qué leer según lo que vaya a hacer, y cuáles son las tres
     cosas que más caro han costado.
  2. **§6.0 "Dónde quedamos"**: el estado de las etapas en curso. Lleva
     instrucción de mantenerlo al día — una sección de estado que envejece
     engaña más de lo que ayuda.
  3. **§9, encender una sede nueva.** Verificado leyendo el repo, no supuesto:
     la app y las 5 Edge Functions **ya son multi-sede** (`SEDES` trae angamos;
     las funciones arman `FUDO_${sede.toUpperCase()}_APIKEY`). No hay código
     nuevo que escribir. Lo que sí hay: secrets de la cuenta de Fudo de
     Angamos, fila de `fudo_sync` **en `prueba`**, catálogo, y **rehacer las
     recetas** — porque Angamos es otra cuenta de Fudo y los `fudo_product_id`
     son distintos, así que copiar las de plaza cambiando la sede no funciona.
     Ese es el error más probable de esta migración y por eso está escrito.
  4. **§3.5, el editor de Supabase es el límite real, no Postgres.** El mismo
     día, el bloque 0 del chequeo devolvió "No se pudo obtener" sin llegar a
     ejecutarse: comillas de dólar (`$q$`) y 5.578 caracteres en una sentencia.
     Ya había pasado con `stock-para-fudo`. Cómo se reconoce: el error nombra
     la API de Supabase y no habla de sintaxis ni de tablas — no hay que
     rediagnosticar el SQL. Todo lo que se le entregue a Jhon va corto, sin
     `$$`, y si es largo ya partido en dos.
  5. **Se anotó que `app_permisos` no tiene columna `sede`**: con dos sedes
     vivas, quien puede empujar a Fudo puede hacerlo en cualquiera. Pasa de
     detalle teórico a decisión que hay que tomar antes de encender el empuje
     en Angamos.

- **2026-07-30 (tarde)** — **Jhon corrigió el informe, y el hallazgo más grave
  resultó no existir.** Las tres correcciones y lo que se hizo con ellas:
  1. **Las "recetas cruzadas" estaban bien.** No hay cheesecake de mora en la
     carta (hay de frambuesa y de maracuyá): `Mora` es `Mara` mal tipeado. Y no
     hay dos cinnamon rolls — el único que se vende es el vegano. Yo las había
     subido a "lo más grave del informe" razonando que los nombres no calzaban,
     que es **exactamente lo que la regla 0.1.1 dice que no se haga**. Ninguna
     consulta SQL lo habría atrapado: la carta del café no está en la base.
     Quedó como **regla 0.1.8**, con el caso completo — incluida la advertencia
     de que subir de categoría un hallazgo viejo exige verificar su base, no
     solo el argumento nuevo.
  2. **El respaldo se hace ahora, antes de pedir los 25 USD/mes.**
     `sql/2026-07-respaldo-para-guardar.sql` + carpeta `respaldos/`. Genera los
     4 CSV y, opcionalmente, un `.sql` de restauración. **Probado de verdad**:
     se respaldó, se vaciaron las tablas, se restauró, y quedó todo igual —
     nombres con tildes/comillas/`$$`, los enlaces receta→producto por id, y el
     contador entregando ids nuevos sin chocar. Las filas se guardan como JSON
     y se restauran con `json_populate_record`, así las columnas se toman por
     nombre desde la tabla real en vez de depender del orden que yo suponga.
  3. **Los 5 administradores ya tienen cuenta propia.** La hipótesis de las
     cuentas compartidas queda descartada; el `session_not_found` pasó en la
     cuenta de Jhon, la única abierta en más de dos dispositivos. Baja de
     "riesgo abierto" a "anotado".
  4. **La seguridad se mantiene en mínimos, por decisión de Jhon** → nueva
     sección 6.1. No es un pendiente: es una decisión, y no se vuelve a
     proponer cerrarla.
  5. **`supabase-js` fijado — y la comprobación cambió el número.** Al mirar el
     registro de npm apareció que la **2.111.0 se publicó el 28 de julio**: la
     app ya había cambiado sola de versión desde que anoté "hoy corre la
     2.110.9". O sea que el riesgo no era teórico, ya había ocurrido. Se fijó
     en **2.111.0**, que es la que corre hoy y con la que se probó el empuje a
     Fudo; fijar la 2.110.9 habría sido *revertir* la librería, no congelarla.
  6. **Catálogo de soluciones aplicadas** → nueva sección 8. La bitácora cuenta
     cómo se llegó a cada cambio; el catálogo se lee al revés, buscando un
     problema para ver si ya está resuelto y dónde.

- **2026-07-30** — **Informe de estabilidad, y un chequeo que se corre solo.**
  Jhon pidió el mapa completo de por dónde se puede caer esto. Nada de código
  cambió: lo que cambió es qué se está mirando. La sección 6 quedó reordenada
  **por cómo se anuncia la falla**, no por lo grave que suena — bloque A las
  calladas, B las ruidosas — porque esa es la lección de la regla 0.5 aplicada
  a la lista de pendientes y no solo al motor.
  1. **`sql/2026-07-salud-del-sistema.sql`**, solo lectura, 10 bloques. Junta
     en una corrida los números que anunciaban las dos fallas más caras del
     proyecto y que nadie estaba mirando: distancia al tope de las 1000 filas,
     funciones con firma duplicada, tablas fuera de `supabase_realtime`,
     columnas que un motor da por sentadas, stock que no cuadra con las
     fechas, ventas leídas sin descontar. **Probado contra Postgres local con
     fallas sembradas a propósito** — eso valida que los detectores disparan,
     no el estado de la base real (regla 0.5: una prueba contra un esquema que
     uno mismo construye no valida una migración).
  2. ~~**Las recetas cruzadas suben de categoría.**~~ **ESTO ESTABA MAL** —
     Jhon lo corrigió ese mismo día: las dos recetas estaban bien. Ver la
     entrada de más arriba y la regla 0.1.8. Se deja tachado y no borrado
     porque el error de método es la parte útil. Lo único que sí se sostiene
     de este punto es la idea general: **cuando se conecta una salida nueva
     hay que volver a mirar los errores conocidos, porque alguno cambió de
     consecuencia** — pero antes de escalar uno, hay que verificar que exista.
  3. **La alarma del motor solo suena si falla el 100% de las ventas**
     (`index.html:2903`, `if(err && !desc)`). Un fallo parcial —8 de 9— sale
     en un aviso que se va solo. Es la falla de julio en versión chica y por
     eso peor: la grande se nota en una tarde, la chica dura semanas.
     Verificado leyendo el código, no supuesto.
  4. **Medido**: pintar 232 productos toma 146 ms y 1000 toma 583 ms — crece
     al cuadrado porque `totalProducto()` recorre `DATA` entero una vez por
     fila (**233 recorridos por pintada, 67% del tiempo**). Detalle y arreglo
     en el bloque D.
  5. **Lo que NO está en riesgo quedó escrito** al final de la sección 6. Una
     lista de vulnerabilidades invita a "arreglar" cosas que ya están bien.

- **2026-07-29** — **Fudo ya recibe el total del par, no solo la vitrina.**
  Jhon lo detectó con el alfajor: 2 en vitrina, 15 en congelador, y a Fudo le
  llegaba **2**. La receta apunta a UN producto, y ese producto era el de
  vitrina.
  Ahora, para calcular cuánto se puede vender, el stock de un insumo es la
  **suma de todos los productos con su mismo nombre base** — igual que el
  "Total" de la lista y que la reposición del motor de descuento. El alfajor
  pasa a **17**.
  1. **No cambia el descuento.** Al vender se sigue descontando del producto
     que dice la receta, y si la vitrina llega a 0 el motor baja del
     congelador como siempre. Lo único que cambió es cuánto se dice que se
     PUEDE vender.
  2. **`base_nombre()` se crea solo si no existe.** El motor de descuento ya
     la usa; redefinirla podría cambiarle el comportamiento sin querer.
     Probado: si ya está, el script no la toca.
  3. **Tocar el producto del congelador mueve lo mismo que tocar el de
     vitrina.** Para Fudo son el mismo producto, así que el botón de la ficha
     busca la receta por nombre base y no por id.
  4. **Los envases siguen sin limitar**, y la respuesta muestra de dónde sale
     cada suma (`sumados`), para que el número no sea un acto de fe.
  **Depende de que los nombres calcen**: correr antes
  `sql/2026-07-emparejar-vitrina-congelador.sql`. Van 12 pares.

- **2026-07-28** — **El gesto de deslizar, rehecho; y el botón de Fudo por
  producto.** Jhon: *"es demasiado poco profesional y estéticamente feo"*.
  1. **Un símbolo que asoma DETRÁS y crece con el gesto**, como el archivar de
     Gmail. Va en `position:fixed` con `z-index` por debajo de la fila, así la
     fila lo destapa al correrse. Antes era un texto dentro de la fila que se
     encimaba sobre la píldora — el bug de la foto.
     **Ojo:** la posición se mide en el `touchstart`, ANTES de mover la fila.
     `getBoundingClientRect()` incluye el `transform`, así que medir durante el
     gesto hacía que el símbolo viajara con la fila en vez de quedarse quieto.
  2. **Luz naranja de atrás, no reborde** (`box-shadow`, sin `border-color`).
     Jhon: *"los rebordes no me gustan"* — se leía como gráfico de Excel.
     Fuerte al cruzar el tope, suave y permanente en lo ya agregado.
  3. **Vuelve con resorte**: `cubic-bezier(.18,1.5,.42,1)` pasa de largo y
     regresa. Antes aparecía de golpe en su sitio y el gesto se sentía cortado.
  4. **Botón "🚨 Actualizar en Fudo" en la ficha del producto**, solo para
     `puede_fudo`. Un producto del inventario puede afectar a VARIOS de Fudo,
     así que la revisión los lista todos antes de escribir; al aplicar manda
     `producto_id` y no empuja el resto.
  **Sobre crear productos sin par en Fudo** (preocupación de Jhon): un producto
  sin receta **no puede escribir nada en Fudo** — `fudo_stock_calculado()` sale
  DESDE `recetas`, así que sin receta nunca aparece en la lista. El riesgo real
  es el contrario: Fudo lo sigue vendiendo sin límite. Es falta de cobertura,
  no un dato corrupto. Diagnóstico en `sql/2026-07-pares-vitrina-congelador.sql`.

- **2026-07-28** — **Zona de administración: el botón para escribir en Fudo.**
  Adriana perdía horas cada día actualizando el stock de Fudo a mano, producto
  por producto — por eso ponía 1.000 unidades de todo. Ahora es un botón.
  Vive en el menú ☰, bajo el rótulo "Solo administración", y **solo la ven las
  cuentas de `app_permisos`**.
  1. **Rojo, no naranja.** El naranja de la casa significa "acción" y está en
     todas partes; el rojo se reserva para lo crítico y **este es el único
     lugar de la app donde manda**. Franja a rayas arriba de cada ventana.
  2. **Nada se escribe de un toque.** El botón rojo abre la revisión (llama en
     modo `simular`, que no toca Fudo): resumen en números, tabla con verde
     para lo que sube y rojo para lo que baja. El botón que aplica **dice el
     número** — "Sí, actualizar 58 productos", no "Confirmar" — y **Cancelar va
     abajo y en gris**: el camino peligroso no es el más cómodo.
  3. **Ventana de "trabajando"** con fondo desenfocado mientras escribe, para
     que nadie apriete dos veces ni cierre la app a medias.
  4. **"Última vez: hace 2 h · Valentina · 58 productos"** en el propio botón.
     Con cinco personas con permiso, alguien iba a apretar por las dudas.
  5. **El historial agrupa por lote**, así un envío es una línea y no 58.
  6. **Se mudan acá `Modo edición` y `Agregar producto`.** Ya no están sueltos
     en el menú: crear, renombrar y eliminar productos pasa a ser cosa de
     administración (`puede_editar`).
  **El candado está en el servidor.** Las Edge Functions vuelven a comprobar el
  permiso contra `app_permisos` antes de tocar Fudo; esconder el botón es
  comodidad, no seguridad. 34 comprobaciones de la zona, 138 del inventario.

- **2026-07-28** — **Deslizar una fila la manda al reparto.** Adriana lo pidió
  así: *"literal tengo que hacer esto con dos pantallas"* — entraba a Crítico,
  anotaba qué faltaba, y se cambiaba a Reparto a escribirlo. Ahora entra a
  Crítico y va deslizando; después, en Reparto, solo pone las cantidades.
  1. **Sirve para los dos lados.** No hay una segunda acción que confundir, así
     que no hay que acordarse de para dónde: izquierda o derecha, da igual.
  2. **El eje se decide una vez y no cambia** (`swEje`): si el gesto arranca
     vertical, la fila no se mueve. Sin eso, desplazar la lista con el dedo
     torcido arrastraba filas sin querer.
  3. **El rótulo "+ Reparto" se contra-mueve** (`translateX(-tope)`) para
     quedarse quieto en pantalla y brotar en el hueco que se abre. Sin eso
     viajaba con la fila y se encimaba sobre el nombre y las fechas.
  4. **La fila queda marcada "En reparto"** hasta que se envía, para no
     agregarla dos veces; deslizarla de nuevo avisa en vez de duplicar.
  `touch-action:pan-y` en `.row` deja que el desplazamiento vertical siga
  funcionando. 14 comprobaciones del gesto, con toques simulados de verdad.

- **2026-07-28** — **HITO: el inventario ya le escribe a Fudo.** 58 productos
  actualizados en producción, 0 errores. Es la primera vez que la información
  viaja del inventario hacia Fudo y no al revés.
  **Cómo se llegó, que es lo que vale:** primero un prototipo aislado
  (`fudo-probar-escritura`) que tocaba UN producto y lo dejaba como estaba —
  la lección de la impresora, sección 7. Recién con esa respuesta se construyó
  el resto. Confirmado: **`PATCH /products/{id}` con formato JSON:API**
  (`{data:{type:"Product",id,attributes:{stock}}}`).
  Piezas: `sql/2026-07-stock-para-fudo-v2-CORTO.sql` (el cálculo) y la Edge
  Function `fudo-empujar-stock`.
  **Decisiones que NO se cambian sin preguntar:**
  1. **El cálculo vive en la base** (`fudo_stock_calculado`), no en la Edge
     Function — mismo criterio que el motor de descuento: se revisa con un
     SELECT sin desplegar nada.
  2. **Siempre valor ABSOLUTO, nunca una diferencia.** Fudo descuenta su
     propio stock al vender; un "+3" restaría dos veces.
  3. **Los envases NO limitan la venta.** Un delivery gasta bandeja y bolsa, y
     se siguen descontando — pero quedarse sin bandejas no es quedarse sin
     torta. Se excluyen por `productos.tipo = 'Envases'`. Sin esto, "Torta
     amor Pedidos Ya" quedaba en 0 con 8 trozos disponibles.
  4. **Tres tandas, no una.** Por defecto solo se mandan los productos que
     Fudo YA controlaba: `incluir_ceros` (los que quedarían en 0 y dejarían de
     venderse) e `incluir_nuevos` (los que Fudo nunca controló, hoy se venden
     sin límite) se piden aparte y avisados.
  5. **Se comprueba releyendo** lo que Fudo devuelve, no se confía en el 200.
     Y todo queda en `fudo_stock_push` con el valor anterior.
  **Ojo:** es un empujón manual, NO una sincronización continua. Al segundo
  siguiente los dos sistemas vuelven a separarse.
  **Pendiente:** el botón en la app, el deshacer, y las tandas 2 y 3.

- **2026-07-28** — **Adriana ya no tiene que salirse de Reparto para armar el
  pedido.** Ella lo reportó así: *"tengo que salirme de reparto, ir a ver qué
  falta y sus cantidades, luego volver"*. El stock **sí** aparecía al buscar,
  pero desaparecía justo cuando importa: al agregarlo al pedido, la fila solo
  mostraba el nombre — y ese es el momento en que se decide cuánto mandar.
  1. **El buscador** muestra el número en una píldora con el **color de su
     estado** (rojo crítico / verde en rango), más mín y máx. Cuánto hay y
     cómo está, en un gesto.
  2. **La fila del pedido** conserva `hay N · máx M`, y se **relee de DATA en
     cada pintada**: si alguien vende mientras ella arma el pedido, el número
     se corrige solo.
  3. **Atajo "llenar N"**: la cantidad que falta para el máximo, a un toque.
     Es la decisión que ella toma decenas de veces al día.
  **Cuidado con las unidades** (error que cometí y corregí): el "hay" del
  buscador es el TOTAL entre secciones (así lo pidió Jhon, para guiar el
  pedido), pero **`máx` es por sección**. Al calcular "llenar" contra el total
  daba 0 en un congelador vacío solo porque la vitrina estaba llena. En la
  fila del pedido manda el stock de ESA sección — que es a donde va el
  reparto — y el total se muestra aparte. 125 comprobaciones de reparto.

- **2026-07-27** — **Filtrar por TIPO de producto, y fuera la tarjeta Urgente.**
  Las secciones dicen **dónde está** un producto; faltaba el otro eje: **qué
  es**. En el Congelador conviven cinnamon rolls, pulpas y pizzas, así que para
  ver "todas las tortas" había que buscarlas una por una. Ahora hay una franja
  de píldoras deslizable entre las tarjetas y la lista.
  1. **Los tipos los define el equipo llenando `productos.tipo`**, no una lista
     escrita en el código: la franja muestra los que de verdad existen, con
     cuántos hay, del más numeroso al menos. Se editan desde la ficha del
     producto (campo "Tipo", con sugerencias de los que ya existen para no
     inventar uno nuevo por una tilde).
  2. **SQL en `sql/2026-07-tipo-de-producto.sql`, en tres pasos.** El 1 crea la
     columna, el 2 **propone** un tipo para cada producto sin escribir nada, y
     el 3 escribe esa propuesta — y solo a los que no tienen tipo, así una
     corrección a mano nunca se pisa al volver a correrlo. Los que el nombre no
     identifica quedan sin tipo y se arreglan desde la ficha. Probado contra
     Postgres local, incluida la idempotencia.
  3. **Se elimina la tarjeta Urgente.** Todo lo urgente ya sale arriba del todo
     al filtrar por Crítico, así que era un camino repetido. La marca manual,
     su píldora naranja y el bloque URGENTE **se mantienen**: lo que se fue es
     la cuarta tarjeta. Las métricas vuelven a 3 columnas.
  4. **Mirando UN tipo no se separa en AM/PM.** Los turnos son para contar el
     inventario; al mirar "todas las tortas" no se está contando un turno.
     Vuelven solos al soltar el tipo.
  5. **La lista brota desde la píldora que se tocó** — ver regla 2.0.
  **Bug de paso:** `items.map(rowHTML)` le pasaba el ÍNDICE como segundo
  argumento, así que toda fila que no fuera la primera de su sección recibía
  `conSeccion=1` y repetía su propia sección ("Vitrina de tortas · mín 6 · máx
  20" estando dentro de Vitrina de tortas). Una línea de ruido por fila, en
  toda la app. 137 comprobaciones del inventario, 114 del reparto.

- **2026-07-27** — **La pantalla de Reparto, reordenada por importancia.**
  Jhon pidió primero una propuesta estética y solo después construirla. Lo que
  quedó:
  1. **"Armar pedido, <nombre>" va arriba y siempre abierto**, con el buscador
     a la vista. Adriana manda ~3 repartos al día: abrir un desplegable cada
     vez era un toque de más en la acción más frecuente de la pantalla. Por lo
     mismo **ya no se cierra al enviar** — lo normal es armar el siguiente.
  2. **El símbolo es el "+" naranja relleno del botón flotante** (`.mas-fab`),
     no un ícono de línea: Jhon lo eligió porque es el que ya significa "crear"
     en el resto de la app y llama más la atención.
  3. **Los repartos por confirmar van bajo un rótulo "POR CONFIRMAR"**, con el
     mismo fondo gris de los turnos AM/PM. Es la única parte de la pantalla que
     pide una acción del jefe de turno; el rótulo desaparece cuando no queda
     ninguno.
  4. **Los repartos cerrados se despliegan.** Antes solo se veía el encabezado.
     Ahora cada uno abre y muestra línea por línea qué llegó y con cuánto, lo
     que no llegó en rojo, y el botón para volver a copiar el resumen. Arranca
     plegado: es historial, no lo del día.
  5. **Marca "NUEVO" en la pestaña Reparto**, para que el equipo entre a ver la
     pantalla nueva. **Se apaga sola** en `FIN_NUEVO` (2026-08-03) — no depende
     de que alguien se acuerde de sacarla.
  La consulta de cerrados va **con `order` + `limit(20)`**, aplicando la
  lección del historial: un `select` sin tope se trunca en 1000 filas sin
  avisar. 105 comprobaciones de la pantalla de reparto, 113 del inventario.

- **2026-07-27** — **El historial mostraba días viejos.** Jhon guardó el
  inventario del 26 y la lista le ofrecía el 13/07, con cantidades que no
  cuadraban (9 tortas donde había 14). El guardado siempre estuvo bien: lo
  que fallaba era LEER. `loadHistorial` pedía todas las filas del historial
  de la sede para sacar de ahí las fechas — **≈232 por día**, y Supabase
  corta la respuesta en 1000 filas. Sin un orden pedido, devolvía las
  primeras insertadas: los días más antiguos. Con más de ~4 días guardados,
  los recientes desaparecían de la lista.
  Arreglado con `sql/2026-07-historial-dias.sql`: una función que agrupa por
  fecha en la base y devuelve **una fila por día**, así la lista no depende
  de cuántos productos tenga cada uno. Si esa función no está, la app cae a
  un respaldo que al menos pide los días **más recientes** (`order` +
  `limit`), no los más viejos. **Lección general: cualquier `select` que
  pueda devolver más de 1000 filas está truncado sin avisar** — si se
  necesita un resumen (días, totales, conteos), se agrupa en la base, no en
  la app.

- **2026-07-27** — **FALLA GRAVE: 15 horas sin descontar, en silencio.**
  Ver la regla 0.5, que es el análisis completo. Resumen: el motor v5 se
  escribió suponiendo el estado de producción desde el repo (faltaba la
  columna `venta_at`) y su `drop` solo borraba una de las dos firmas, así
  que quedaron dos `fudo_procesar_item` conviviendo y la llamada por la API
  se volvió ambigua. Las pruebas contra Postgres local pasaron porque esa
  base la construí yo copiando el repo — validaban la lógica, no el encaje
  con la base real. Arreglado con `sql/2026-07-URGENTE-falta-venta-at.sql` y
  `sql/2026-07-URGENTE-dos-motores.sql`; el archivo del motor v5 ya crea su
  columna y borra todas las firmas. **La app ahora avisa en ventana cuando
  lee ventas y no descuenta ninguna**, que es lo que faltaba para que esto
  no pasara 15 horas invisible.

- **2026-07-27** — **Repartos: la lista de Adriana se confirma en la app.**
  Antes Adriana mandaba la lista por WhatsApp, el local comparaba contra lo
  que llegaba… y después tenía que TRANSCRIBIRLO a la app. Ese traspaso era
  el doble trabajo. Ahora Adriana arma el reparto acá (bloque "Armar pedido,
  <nombre>") y el jefe de turno solo confirma: ✓ Llegó / cantidad distinta /
  ✕ No llegó. Cada confirmación suma al inventario en el momento.
  SQL en `sql/2026-07-repartos.sql`: tablas `repartos` + `reparto_items` y las
  funciones `reparto_recibir` / `reparto_rechazar` / `reparto_deshacer` /
  `reparto_cerrar`. Puntos de diseño que NO se tocan sin preguntar:
  1. **La suma ocurre en la base, no en la app.** `reparto_recibir` bloquea la
     línea (`for update`) y comprueba que siga pendiente antes de sumar: dos
     teléfonos tocando "Llegó" a la vez no suman dos veces. Mismo patrón que
     el motor de Fudo.
  2. **Los perecederos entran por fechas** — ver regla 0.4.
  3. **Enviar NO toca el stock.** Solo deja la lista esperando; el stock sube
     recién cuando el local confirma.
  4. **Deshacer solo si el producto no se movió.** Si ya hubo ventas, avisa
     ("corrige el stock en la ficha") en vez de inventar un número. También
     retira el aviso a Fudo que había generado, para que nadie sume en Fudo
     algo que en la app se dio marcha atrás.
  5. **Varios repartos por día**: al local llegan ~3 distintos. Se distinguen
     por **quién lo envió y a qué hora** ("Jhon · 06:05"). La columna `origen`
     existe en la base pero NO se pregunta en la app — Jhon lo consideró
     información irrelevante para el mesón; si alguna vez hace falta, el campo
     ya está.
  6. **Adriana no edita lo enviado.** Si se le olvidó algo, manda otro reparto.
     El que cierra es el jefe de turno, y solo con todas las líneas resueltas.
  7. **El resumen para WhatsApp sirve en los DOS momentos**, sin que nadie
     elija nada. Adriana lo copia apenas envía —**antes de que el reparto
     salga**— y ahí lista lo que va en camino con las cantidades pedidas; el
     jefe de turno lo copia al terminar y ahí salen las cantidades reales,
     con sus fechas, y al final **lo que faltó con ⚠️**. Una línea muestra lo
     recibido si ya se resolvió, y lo pedido si sigue pendiente. El desglose
     de fechas de un sándwich muestra SOLO las que entraron en ese reparto,
     no todas las del producto.
  Las dos tablas van a la publicación `supabase_realtime` (está en el SQL):
  sin eso el local no ve lo que Adriana arma hasta refrescar. 50 comprobaciones
  de la pantalla + 14 contra Postgres local.

- **2026-07-27** — **Al filtrar por Crítico, lo urgente va arriba del todo.**
  Adriana arma la lista de pedido para Mall Plaza entrando por la tarjeta
  **Crítico**, así que ese filtro ahora trae también los productos marcados a
  mano como urgentes, en un bloque propio rotulado "URGENTE" **antes** de los
  bloques AM/PM. Sube incluso un producto que el semáforo NO marca como
  crítico (ej. uno en sobre-stock que igual se está acabando) — ese es
  justamente el caso que la marca manual existe para cubrir. Un urgente sale
  **una sola vez**: arriba, no repetido abajo en su sección. Como quedan fuera
  del contexto de su sección, esas filas muestran de dónde vienen
  ("Mueble de bolsas · mín 10 · máx 30"). Las tarjetas de arriba siguen
  contando lo suyo (Crítico cuenta críticos, Urgente cuenta urgentes): son el
  diagnóstico, el filtro es la lista de trabajo.

- **2026-07-27** — **Jerarquía de color + detalles del local.**
  Cabeceras de sección en **azul pizarra `#2F4A6D`** (Jhon eligió el color 3 de
  un selector provisorio que ya se borró): el naranja se leía como demasiado
  urgente y competía con las alertas. Ahora el naranja queda **solo para acción
  y urgencia**. Un producto marcado urgente lleva píldora naranja rellena con
  sombra y borde naranja en la fila, el mismo lenguaje del botón "+".
  **Marcar urgente se guarda solo al tocarlo** — ya no hay que pasar por
  "Guardar"; es un aviso para Adriana y no puede depender de que alguien se
  acuerde. En el resumen de WhatsApp, lo que **vence hoy o ya venció lleva ⚠️**
  pegado al nombre. La línea de producto en dos secciones dice **dónde** está
  ("Total: 10 · Congelador y Vitrina de dulces") en vez de "2 secciones".
  Fuera de las cabeceras: el contador de productos y el triangulito; fuera
  también "232 de 232 productos". **El aviso "1 crít." se mantiene**: no es
  ruido, es la alerta. La píldora de fecha pasa a año completo
  (`5 V 27/07/2026`); el resumen de WhatsApp sigue en año corto, son dos
  formatos distintos a propósito (`fmtPildora` y `fmtCorta`).
  **Bug corregido:** al eliminar un producto reaparecía un instante. Eran dos
  cosas: la fila se quitaba recién después de que respondía Supabase, y un
  evento en vivo rezagado del mismo producto (con `activo='SÍ'`, emitido antes
  del borrado) lo volvía a insertar. Ahora se saca al toque y `BORRADOS`
  ignora cualquier evento de un id recién eliminado durante 20 s; si el
  borrado falla, la fila vuelve sola.

- **2026-07-27** — **Las fechas ahora viajan en vivo, y se limpió el descuadre.**
  Jhon reportó que el resumen de sándwiches traía datos erróneos. Comparado
  contra su foto, el texto copiado era **idéntico** a la pantalla: el resumen
  estaba bien, los datos no. Causa raíz encontrada con el diagnóstico:
  **`producto_lotes` no estaba en la publicación `supabase_realtime`** (sí
  `productos`). Al vender, el teléfono recibía el stock nuevo pero conservaba
  las fechas viejas — por eso "Champiñón 0" aparecía con "1 vence hoy" y el
  resumen a Adriana anunciaba unidades inexistentes. SQL en
  `sql/2026-07-fechas-en-vivo-y-limpieza.sql`: publica la tabla y borra las
  fechas que no representan unidades reales (cantidad 0, o de productos en
  stock 0), con respaldo previo en `producto_lotes_respaldo_20260727` y vista
  previa antes de tocar nada. Jerarquía que fijó Jhon, ahora en la sección
  0.3.1: **si el stock está en 0 manda el stock y la fecha sobra; pero cuando
  se AGREGAN fechas mandan las fechas** (verificado contra Postgres local: tras
  limpiar, agregar una fecha nueva vuelve a fijar el stock desde las fechas).
  Además, la píldora pasa a `cantidad V fecha` (`5 V 27/07/26`) porque
  "5 vencen mañana 28/07/26" no cabía y se encimaba; la urgencia la lleva el
  color, y **vencido pasa a rojo relleno** para no confundirse con "vence hoy".
  Congelador se mueve al turno **AM**.

- **2026-07-27** — **Cuatro cambios pedidos desde el local:**
  1. **Inicio limpia la pantalla.** Tocar el ícono de casa borra la búsqueda,
     suelta los filtros y cierra las secciones (`irAlInicio()`). Antes había
     que deshacer cada cosa a mano para volver a ver la lista completa.
  2. **Turnos AM / PM.** El inventario se cuenta en dos rondas y las secciones
     ahora van agrupadas en dos bloques con fondo gris, sin más explicación
     que una etiqueta "AM"/"PM". Qué sección va en cada turno se define en la
     lista **`SEC_AM`** de `index.html` — mover una sección de turno es
     agregarla o sacarla de ahí, nada más.
  3. **Grupo "Urgente".** Cuarta tarjeta junto a Crítico / Sobre-stock / Sin
     dato. Es una marca MANUAL (botón en la ficha del producto), no un estado
     calculado: convive con los otros (un producto puede estar crítico y
     urgente a la vez) y sirve para que el personal le avise a Adriana lo que
     se está acabando aunque el semáforo no lo marque. Necesita
     `sql/2026-07-productos-urgentes.sql` (columna `productos.urgente`); si no
     se corre, la tarjeta y el botón no aparecen y la app se ve igual que antes.
  4. **Todas las fechas de vencimiento a la vista** — ver regla 0.3, que quedó
     como regla dura. Antes se mostraba solo la más próxima y un "+1 fecha".
  5. **Botón de resumen para WhatsApp** en la sección Sándwiches: un ícono en
     la barra naranja que copia al portapapeles una línea por fecha con su
     cantidad ("Croasan 5 / Fv. 27/07/26"). Es solo texto, no toca la base.
     "Mechada" sale como "Plateada" (`NOMBRES_RESUMEN`) porque para el equipo
     son el mismo producto — es solo la etiqueta del mensaje, no un renombre.
  Probado en navegador con Supabase simulado: 47 comprobaciones, incluido que
  si el SQL de urgentes no se corre la pantalla queda idéntica a hoy.

- **2026-07-27** — **Modo edición: el nombre y la sección quedan bajo llave.**
  A un producto le cambiaron el nombre sin querer y nadie se dio cuenta hasta
  que Jhon lo notó. Ahora la ficha del producto muestra solo lo del día a día
  (stock, mín/máx, urgente, perecedero); **nombre, sección y eliminar** salen
  únicamente con el interruptor **"Modo edición"** del menú lateral. Eliminar
  dejó de ser un botón grande y pasó a un ícono de basurero arriba a la
  derecha del título — es una acción de la que no se vuelve, no algo que se
  toca de paso. **El modo NO se guarda entre sesiones**: al abrir la app
  siempre arranca apagado, así encenderlo es siempre una decisión consciente.
  Si en el futuro se agrega otra acción peligrosa, va detrás de este mismo
  interruptor (`setModoEdicion`), no suelta en la ficha.
  Además, la fila del producto urgente **pierde el reborde naranja** (parecía
  gráfico de Excel): la píldora naranja rellena ya lo identifica sola.

- **2026-07-27** — **Se acabaron las ventanas del navegador.** No queda ni un
  `alert`, `confirm` ni `prompt` en la app: todos pintaban media pantalla de
  negro y se leían como si algo se hubiera roto. Tres helpers, con el mismo
  fondo desenfocado y la paleta de la casa:
  - `aviso(txt)` — el mensajito que aparece abajo y se va solo (toast). Ya existía.
  - `avisar(txt)` — ventana que hay que cerrar. **Reemplaza a `alert`** en los
    40 sitios donde estaba; se llama igual, así que el código no cambió de forma.
  - `preguntar(titulo, detalle, textoOk)` — sí/no, devuelve promesa y se usa con
    `await` igual que `confirm`. Confirmar en naranja, cancelar en gris.
  - `elegirProducto(titulo, excluir)` — buscador emergente que devuelve el
    producto elegido. **Reemplaza al `prompt`** de "llegó algo que no estaba en
    la lista": antes había que escribir el nombre completo a ciegas.
  Las ventanas de aviso van en **z-index 56**, por encima de las demás:
  preguntado desde la ficha de un producto quedaba detrás y no se podía tocar.
  El desenfoque se aplicó a `.overlay`, así que TODAS las ventanas de la app
  (ficha, nuevo producto, receta, fechas del reparto) lo llevan.

- **2026-07-27** — **Tope en 0 sin excepción, para todos los productos.**
  Jhon aclaró que la regla del cambio anterior (mismo día) se quedaba corta:
  no debe haber negativos en NINGÚN producto, tenga o no pareja de
  Congelador. Quedaba un hueco: los productos con lotes de vencimiento
  (sándwiches) — `descontar_lotes()` dejaba a propósito el sobrante en
  negativo en el lote más próximo si se vendía más de lo que había. SQL en
  `sql/2026-07-tope-cero-sin-excepcion.sql`: 1) `descontar_lotes()` ya no
  deja sobrante negativo, se queda en 0; 2) se agregan restricciones CHECK
  reales (`productos.stock_actual >= 0`, `producto_lotes.cantidad >= 0`)
  como respaldo final — así ningún camino futuro (motor nuevo, edición
  manual, bug) puede dejar un negativo, aunque nadie se acuerde de esta
  regla. También en la app: los campos de stock editables a mano ahora
  tienen `min="0"` y se clampean en JS antes de guardar, y si de todas
  formas la base rechaza un negativo, el aviso dice "El stock no puede
  quedar negativo" en vez del mensaje genérico de conexión. Probado contra
  Postgres local: venta que excede el lote disponible (queda en 0, sin fila
  fantasma negativa), venta exacta seguida de otra venta con stock ya en 0
  (no falla, se queda en 0), e intento directo de forzar un stock_actual
  negativo por UPDATE (rechazado por el CHECK). Regla ahora está en la
  sección 0.2 del archivo madre. Falta correr el SQL a mano en Supabase
  (después del de reposición-congelador, si aún no se corrió).

- **2026-07-27** — **El stock ya no baja de 0, y Vitrina se repone sola desde
  Congelador.** Motivo: una venta en Fudo podía dejar, por ejemplo, Cinnamon
  Roll en -2 en Vitrina — un número que no significa nada en la realidad.
  Motor v5 de `fudo_procesar_item` (SQL en
  `sql/2026-07-reposicion-congelador-y-tope-cero.sql`): para productos SIN
  lotes de vencimiento, si una venta dejaría el stock en 0 o menos, primero
  se buscan **4 unidades fijas** (o las que haya, si hay menos) en su pareja
  de Congelador — detectada automáticamente por nombre base, el mismo
  criterio que ya usa el "Total" (`base_nombre()` en SQL, gemelo de
  `baseNombre()` en la app) — y se trasladan a Vitrina ANTES de aplicar el
  descuento. El stock final nunca es negativo, tenga o no pareja
  (`greatest(0, stock - cantidad)`). Aplica a TODOS los pares Vitrina/Congelador
  detectados automáticamente (galletas, brownies, volcanes, donas, muffins,
  cinnamon rolls) — no es una lista curada a mano. Los sándwiches y demás
  productos con lotes de vencimiento siguen igual, por FIFO de fecha, sin
  tocar. Probado contra Postgres local: 5 escenarios (traspaso normal, menos
  de 4 disponibles, sin pareja, perecedero con lotes sin cambios, venta que
  agota ambos lados sin quedar negativo) + idempotencia + respeta
  `fudo_sync.modo = 'prueba'`. Falta correr el SQL a mano en Supabase.

- **2026-07-25** — Buscador siempre visible (se quitó la lupa: sumaba toques y no se
  notaba que abría) y **suelta los filtros al tocarlo** — buscar "torta de zanahoria"
  estando en el filtro Sobre-stock no la encontraba, aunque el producto existía. El
  estado se sigue viendo en la píldora de color junto al nombre. Además, los
  **encabezados de sección pasan a naranja** (antes blancos, iguales a los productos,
  y al desplazar se perdía dónde terminaba una sección y empezaba otra).

- **2026-07-25** — Se acorta la demora del descuento y se puede medir. La app no era
  el problema (un descuento por la conexión en vivo se refleja en ~5 ms sin refrescar,
  verificado). La demora real estaba en el sincronizador: Fudo filtra por cuándo se
  ABRIÓ la mesa, no cuándo se cerró — con la ventana de 2h, una mesa abierta horas
  antes de cerrarse quedaba fuera y **no se descontaba nunca** (no era lenta, se
  perdía). Ventana ampliada a 8h + tope corrido 1h (por si el reloj de Fudo va
  adelantado). Se agrega columna `venta_at` (motor v4, `fudo_procesar_item` recibe
  `p_venta_at`) para guardar CUÁNDO se vendió de verdad, no cuándo corrió la sync —
  antes estábamos ciegos para medir esto. SQL en `sql/2026-07-fecha-real-de-venta.sql`,
  trae la consulta para medir la demora real. Probado en cafetería: funcionó con una
  venta real.

- **2026-07-25** — **Un solo botón de actualizar.** Había cuatro puntos para dos
  acciones (⟳ de la barra, botón suelto en Recetas, dos atajos en el menú) y en el
  mesón generaba fricción. Ahora el ⟳ corre todo en orden: catálogo de Fudo →
  ventas → relectura de pantalla. Los pasos viven en el registro **`PASOS_SYNC`**:
  **para agregar una sincronización futura, sumar una entrada ahí y el botón la
  incluye sola** — no crear botones nuevos. Si un paso falla los demás igual corren,
  y la pantalla se relee siempre. Se arregló de paso el "+ Nueva" de Recetas, que
  había quedado dentro de la fila del buscador y se ocultaba con él.

- **2026-07-25** — Cabecera replicando la app de Fudo (de 182 px a 114 px): barra navy
  con ☰ · título de la vista · lupa · recargar, y debajo las píldoras en franja blanca
  (activa en naranja). Desaparece la franja naranja: "Actualizar inventario" es ahora
  el ícono ⟳ y el resultado sale en un aviso transitorio (`aviso()`). El buscador se
  abre con la lupa (en Reparto arranca abierto). Menú lateral ☰ con sede, en vivo,
  quién está conectado, salir, y **atajos** a acciones que siguen existiendo en su
  lugar (agregar producto, actualizar inventario, productos de Fudo); "Cambiar sede"
  se mudó ahí. Regla: los atajos NO reemplazan a los botones originales.

- **2026-07-25** — Lotes de vencimiento: un producto puede tener VARIAS fechas, cada
  una con su cantidad (9 vencen el 27, 1 vence hoy). Tabla `producto_lotes`; el stock
  del producto es la SUMA de sus lotes (trigger), por eso queda de solo lectura cuando
  hay fechas. Al vender en Fudo se descuenta del lote que vence primero (FIFO,
  `descontar_lotes()` + motor v3). En la lista se ve el más urgente con su cantidad
  ("1 vence HOY") y cuántas fechas más hay. SQL en `sql/2026-07-lotes-vencimiento.sql`
  (correr a mano). Si la tabla no existe, la app sigue con la fecha única de antes.

- **2026-07-24** — Tiempo real completo: crear/renombrar/eliminar productos ahora sí
  se refleja en los otros dispositivos. La conexión en vivo se corta al dejar la app
  de fondo y nadie recuperaba lo perdido (el stock "funcionaba" solo porque se
  editaba con la app en pantalla). Se recarga al volver (`visibilitychange`, focus,
  online) y al reconectar el canal; el indicador marca "sin conexión" de verdad; se
  maneja el DELETE real (viene en `payload.old`). Además se escapan los nombres al
  mostrarlos, ahora que los escribe el personal.

- **2026-07-24** — Editar el nombre del producto desde la app (campo "Nombre" en el
  modal). Valida vacío y duplicado *dentro de la misma sección* (el mismo producto
  sí puede vivir en dos secciones). Además, apellido de sección para la bollería:
  `sql/2026-07-apellido-seccion-bolleria.sql` renombra a "… vitrina" / "… congelador"
  solo la lista de bollería (no toca pizzas ni pulpas), con vista previa e idempotente.
  Para que el total siga sumando, `totalProducto()` agrupa con `baseNombre()`, que
  ignora ese apellido.

- **2026-07-24** — Buscadores sin tildes: buscar "azucar" ahora encuentra "Azúcar
  morena/blanca/flor". Los tres buscadores (Inventario, Reparto, Recetas) usan
  `normNombre()` — quita tildes, mayúsculas y espacios de más. Antes una tilde de
  diferencia escondía productos y se creaban duplicados. Una sola definición del
  helper, arriba junto a los demás.

- **2026-07-24** — Total por producto: cuando un mismo producto vive en 2+ secciones
  (ej. Brownie en Congelador y Vitrina), la app muestra el TOTAL sumado en el
  inventario (y en el filtro Críticos) y en el buscador de Reparto, para que Adriana
  guíe el pedido por el total. Es solo lectura: no toca mínimos, ni estado crítico,
  ni el registro de llegada. Agrupa por nombre normalizado. Helper `totalProducto()`.
- **2026-07-24** — Permisos de recetas: todos los usuarios logueados pueden crear/
  editar recetas (antes solo la cuenta dueña). SQL en
  `sql/2026-07-recetas-todos-pueden-crear.sql` — borra cualquier política vieja/
  restringida y deja `recetas`/`receta_items` abiertas a anon+authenticated. Hay
  que correrlo a mano en Supabase → SQL Editor.
- **2026-07-24** — Ícono real de Jhon aplicado (redimensionado desde su PNG, sin
  redibujar). Botón "↻ Productos de Fudo" agregado en Recetas + CORS en la Edge
  Function `fudo-sync-productos`. Se quitó el párrafo explicativo bajo el botón
  (regla de texto mínimo). Se creó este archivo madre.
- **2026-07 (antes)** — Buscador con filtro en Recetas; encabezado reordenado (solo
  la barra de sync queda fija); bloqueo de zoom en iPhone; PWA instalable; se quitó
  la tarjeta "En rango"; campo `aplica` y motor v2 con `saleType`.

---
