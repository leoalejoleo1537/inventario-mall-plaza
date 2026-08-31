# Inventario Café del Desierto — Archivo Madre

> **Para Claude:** Lee este archivo completo al inicio de cada sesión. Es el hilo
> conductor del proyecto. Si algo que vas a hacer contradice lo que dice aquí,
> detente y confírmalo con Jhon antes. Cuando cerremos un cambio importante,
> **actualiza este archivo** (sección "Bitácora").

---

## ÍNDICE

> **Cómo usar este archivo sin leerlo entero.** Son ~2.300 líneas y leerlas
> todas cuesta caro. Este índice existe para saltar directo. La regla:
> **las secciones 0 a 0.5 se leen SIEMPRE** — son duras, salen de fallas
> reales y no se negocian. El resto se abre cuando el trabajo lo pide.

| § | Qué hay ahí | Cuándo abrirla |
|---|---|---|
| **0** | Comparar Fudo vs. inventario es de SOLO LECTURA | **siempre** |
| **0.1** | Reglas al tocar datos · 9 reglas + checklist | **siempre** |
| **0.2** | El stock nunca puede ser negativo | **siempre** |
| 0.2.1 | La reposición automática está APAGADA, y por qué | antes de proponer que el sistema mueva stock solo |
| **0.3** | Las fechas de los sándwiches se muestran todas | tocar perecederos |
| 0.3.1 | Quién manda cuando el stock y las fechas no cuadran | tocar perecederos |
| **0.4** | Un perecedero entra solo por fechas | sumar stock desde cualquier camino |
| **0.5** | La falla de las 15 horas · cómo tocar el motor | tocar el motor o cualquier función SQL |
| **0.6** | **El día que Angamos quedó en cero** · saca la foto antes | **siempre, antes de escribir en una sede** |
| **0.7** | **La bodega es `central`; `bodega` es la vieja** · y las 3 reglas de esta etapa | **siempre, mientras se trabaje en bodega** |
| **0.8** | **Antes de poner un candado, seis preguntas** | **antes de hacer algo obligatorio** |
| **0.9** | **NO SE TOCA Llamita Stock mientras se construye Lama** | **siempre, en el chat de Lama** |
| 1 | Qué es esto y para quién | contexto general |
| 2 | Estética · paleta y formas | tocar la pantalla |
| 2.0 | Que sea bella, no solo que funcione | tocar la pantalla |
| 2.1 | Texto mínimo — nada de párrafos explicativos | escribir cualquier texto de la app |
| **2.3** | **La impresora: USB, ESC/POS, y por qué hace falta un puente** | construir Llamita Lama |
| 3 | Arquitectura · dónde vive cada pieza | desplegar algo |
| 3.5 | **Los 3 límites del editor de Supabase** | escribir un `.sql` para Jhon |
| 3.6 | Jhon no tiene el repo en su computador | entregarle instrucciones |
| 4 | Cómo funciona el motor de inventario | entender el descuento |
| 5 | Git · Vercel publica `master` | publicar un cambio |
| **6.0** | **DÓNDE QUEDAMOS** — el estado de hoy | **empezar una sesión** |
| 6 A–E | Pendientes, ordenados por si la falla avisa o no | elegir en qué trabajar |
| 6.1 | La seguridad se mantiene en mínimos (decisión) | antes de proponer cerrar permisos |
| 6.2 | **La zona de configuración** — el pendiente grande | el trabajo que viene |
| 6.3 | **Recetas rediseñada** — decisiones ya tomadas | construir la pantalla nueva |
| 6.4 | Lo que viene después: tablero de análisis y la planilla del café | terminada la zona de configuración |
| 7 | ¿POS propio? · la conversación con administración | decisiones de largo plazo |
| **8** | **Catálogo de soluciones** — se busca el problema | antes de "arreglar" algo |
| 9 | Encender una sede nueva · el caso Angamos completo | otra sede |
| 9.7 | Cómo se armaron las recetas de Angamos | armar recetas |
| 10 | Insumos a granel (té, café, naranja) | el trabajo de medición |
| 10.1 | El doble descuento del conteo nocturno | mesas abiertas |
| **11** | Bitácora — por qué algo está hecho así | entender una decisión vieja |
| **12** | **LLAMITA LAMA — el hermano grande · dónde quedamos** | **empezar una sesión de Lama** |

---

## EMPIEZA POR ACÁ (mapa de este archivo)

Este es el orden en que conviene usarlas:

| Si vas a… | Lee primero |
|---|---|
| **Cualquier cosa** | Las reglas 0 a 0.5. Son duras, salen de fallas reales y no se negocian |
| Comparar / auditar / revisar algo | §0 — es un INFORME, nunca una edición |
| Tocar productos, recetas o stock | §0.1 — el checklist del final es obligatorio |
| Tocar el motor de descuento o cualquier función SQL | §0.5 — la falla de 15 horas está ahí |
| Tocar la pantalla | §2 y §2.0 — la estética es parte del encargo, no un extra |
| Saber si un problema ya está resuelto | **§8, el catálogo** — se busca el problema y dice dónde vive la solución |
| Saber qué falta por hacer | §6, ordenado por si la falla avisa o no |
| Encender una sede nueva | **§9** — el caso Angamos, paso a paso |
| Proponer que el sistema mueva stock solo | **§0.2.1** — ya se intentó y se apagó; leer por qué antes |
| Poner recetas a insumos a granel (té, café, naranja) | **§10** — el marco y los datos ya medidos |
| Entender por qué algo está hecho así | §11, la bitácora |

**Las cuatro cosas que más caro han costado**, para no repetirlas:

0. **Escribir sobre una sede viva sin sacarle antes una foto.** El 2026-08-09
   Angamos quedó en cero y **no se pudo restaurar nada**, porque nunca se había
   guardado un inventario de esa sede. Lo que tenía copia se recuperó; lo que
   no, se cargó a mano. (§0.6 · el error más caro del proyecto)


1. **Suponer el estado de producción leyendo el repo.** Un `.sql` en git dice
   lo que se corrió alguna vez, no lo que está ahora. Se consulta con un
   SELECT, siempre. (§0.1.2 · costó 15 horas sin descontar)
2. **Concluir que algo está mal porque dos nombres no calzan.** Las recetas se
   unen por ID; un nombre raro es una pregunta para el equipo, no un hallazgo.
   (§0.1.8 · costó un informe entero mal priorizado)
3. **Entregar algo que falla en silencio.** Si un camino puede romperse sin
   que la pantalla lo diga, eso es peor que si se cayera. (§0.5)

**Cómo trabaja Jhon** (§3.5): no tiene el repositorio en su computador, no usa
terminal ni git. Todo lo que él haga tiene que ser: copiar un texto, pegarlo en
Supabase, apretar Run, y guardar el resultado en Notion. Lo que va al repo lo
commitea Claude.

**Cómo hablarle a Jhon** *(pedido por él el 2026-07-31)*: el tono está bien,
pero **falta bajar el nivel técnico**. Él entiende con **metáforas y ejemplos**,
no con términos. Antes de entregarle un script hay que decirle, en lenguaje
llano, **qué hace, qué toca y qué pasa si sale mal** — porque si no entiende
para qué sirve, lo copia a medias o no lo copia. Ejemplos que ya funcionaron:
el cuaderno de migraciones = *la cartilla de vacunas*; el modo `prueba` = *el
motor girando en punto muerto*. Un párrafo de metáfora antes del script ahorra
dos vueltas de confusión.

**Y una regla que sale de la misma conversación:** todo script que se le entregue
lleva al final la línea que lo anota solo en `migraciones_aplicadas` (§8). Que
el cuaderno se escriba no puede depender de que él se acuerde.

**CABECERA OBLIGATORIA EN TODO ARCHIVO QUE SE LE ENTREGUE** *(pedido por Jhon el
2026-08-01, después de perder varias vueltas preguntando dónde se pega cada
cosa).* Él dijo textual: *"asume que ni sé utilizar bien aún Supabase"*. Cada
archivo empieza con estas cinco líneas, antes de cualquier otra cosa:

```
--  DÓNDE VA:  Supabase -> SQL Editor -> New query     (o -> Edge Functions -> Deploy)
--  ES:        1 solo bloque / 3 bloques, uno por uno
--  TARDA:     instantáneo / ~12 segundos / hay que esperar 20 min entre el 1 y el 2
--  QUÉ HACE:  una frase. Y si escribe algo, decirlo.
--  QUÉ VER:   qué columna mirar y qué significa
```

No es cortesía: **cada vez que falta, él pierde una vuelta preguntando y eso
cuesta tokens que le hacen falta para avanzar.** Un `.sql` va al SQL Editor y un
`.ts` va a Edge Functions — eso ya lo tiene claro; lo que falta siempre es en
cuántas partes va, cuánto tarda y qué tiene que mirar del resultado.

## 0. REGLA DURA — comparar Fudo vs. inventario es SIEMPRE de solo lectura

> Se agrega esta regla porque una sesión anterior, al pedirle "compara los
> productos de Fudo con los del inventario", **creó productos duplicados en
> vez de mostrar un informe**. No vuelva a pasar.

- **Cualquier pedido de comparar/auditar Fudo vs. inventario es un INFORME, no
  una edición.** La herramienta ya existe y es de solo lectura:
  `sql/2026-07-auditoria-recetas.sql` (bloque 0 resumen, bloque 2 Fudo sin
  receta, bloque 6 inventario huérfano, bloque 7 sugerencias de emparejamiento).
  **Úsala o adáptala — no reinventes la comparación escribiendo INSERTs.**
- **Nunca crear, fusionar, renombrar o eliminar productos/recetas como efecto
  secundario de "revisar" o "comparar".** Eso son acciones que decide Jhon,
  después de ver el informe — no una consecuencia automática de pedir un análisis.
- Si al comparar aparece algo que "parece" que hay que arreglar (duplicado,
  producto sin pareja, nombre que no calza): **mostrarlo en el informe y
  preguntar**. No corregirlo solo, por muy obvio que parezca — lo obvio para
  un modelo no siempre es obvio para el negocio (ver sección 7, combos).
- Esta regla aplica a **cualquier sesión**, incluso una sin el historial de
  conversación de hoy. Por eso está acá arriba y no en la bitácora: la
  bitácora se lee después, esto se lee primero.

## 0.1 Reglas duras al tocar datos (aprendidas el 2026-07-25)

> Otra sesión de Claude, para una tarea que solo pedía comparar dos listas,
> terminó creando 5 productos duplicados en producción y reportando bugs
> que no existían. Jhon pidió el reporte de qué salió mal y estas reglas
> son ese reporte, verificadas contra el código real antes de guardarlas.

1. **Las recetas van por ID, no por nombre.** `recetas.fudo_product_id` y
   `receta_items.producto_id` son la unión real (confirmado en
   `fudo_procesar_item`: el join es `pr.id = ri.producto_id`, el nombre solo
   se usa para mostrarlo). **Renombrar un producto del inventario no rompe
   nada** — el descuento sigue funcionando por ID. Los nombres los define el
   equipo según cómo cuentan en cada sección; no son inconsistencias a
   corregir. Los `*-emparejador-*.sql` usan nombres solo como heurística para
   crear recetas la primera vez — una vez creada la receta, el nombre deja de
   importar. Si algo propone un cambio basado en "este nombre no calza",
   está resolviendo un problema que no existe.

2. **Los archivos del repo NO son el estado de producción.** El SQL se
   corre a mano en Supabase: un `.sql` en el repo describe lo que se
   ejecutó alguna vez, no lo que está ahora. La base cambia sin dejar
   rastro en git (renombres, altas y reestructuras hechas desde la app).
   Antes de afirmar algo sobre el estado de los datos, o de proponer un
   cambio basado en ese estado, **consultarlo con un SELECT** — nunca
   inferirlo de un archivo del repo.

   **Corolario, aprendido a la mala el 2026-07-27:** esto vale también para
   las COLUMNAS y funciones que usa un script nuevo. El motor v5 escribía
   `fudo_movimientos.venta_at` dando por hecho que la columna existía
   porque se creaba en otro `.sql` del repo — que nunca se había corrido.
   Resultado: el motor lanzaba excepción en CADA venta, la Edge Function
   las contaba como errores pero respondía `ok`, y la app decía "ventas
   actualizadas" sin descontar nada. A mitad de turno y sin aviso.
   **Todo script SQL tiene que bastarse solo**: si usa una columna, un
   índice o una función, la crea él mismo con `add column if not exists` /
   `create ... if not exists`, aunque "ya debería estar".

   **Y al reemplazar una función, borrar TODAS sus firmas anteriores.** El
   mismo día, el motor v5 hacía `drop function ...(...,timestamptz)` — solo
   la firma de 8 argumentos. En producción vivía la de 7, así que no se
   borró y quedaron dos `fudo_procesar_item` conviviendo. Llamado desde SQL
   el motor funcionaba perfecto; pero la Edge Function llama por la API, y
   ahí el nombre quedaba **ambiguo entre dos candidatas**: la llamada se
   rechazaba antes de ejecutar nada. La sync informaba "9 ventas · 0
   descuentos" y ni un error a la vista. Al cambiar la firma de una función
   que ya está en producción, hay un `drop` por cada firma vieja posible.

3. **Analizar ≠ escribir.** Ver sección 0: comparar/auditar es un informe,
   no un script que modifica la base. Pasar de análisis a escritura
   necesita que Jhon lo pida explícitamente, y todo script de escritura
   debe ir precedido de un SELECT que muestre qué va a tocar, decir en una
   línea qué crea/modifica/borra, y ser reversible o explicar cómo
   revertirlo. **Nunca crear un producto en `productos` sin antes buscarlo
   por si ya existe con otro nombre** — un duplicado obliga a las jefas a
   contar dos veces lo mismo y rompe la confianza en el sistema.

4. **Comparar con criterio, no con `=`.** "Brownie" y "Brownie-solo" son el
   mismo producto; normalizar texto (sin tildes, minúsculas, espacios) sirve
   para *proponer* candidatos, nunca para concluir que algo falta o sobra.
   Si el resultado de una comparación automática es largo, revisarlo con
   criterio antes de presentarlo.

5. **Verificar antes de anunciar.** No reportar "bug" o "está roto" sin
   contrastarlo contra la base — un hallazgo sin verificar manda a Jhon a
   revisar cosas que están bien, y eso cuesta más caro que no encontrarlo.
   Si algo parece un bug pero no se pudo verificar, decirlo así: *"esto
   podría estar mal, hay que confirmarlo con esta consulta"*.

6. **Si la evidencia contradice el modelo, PARAR.** Señal concreta: una
   verificación que falla en masa (ej. la mitad de los nombres no calzan)
   casi nunca es un problema de los datos — es el modelo mental de Claude
   el que está mal. Ahí toca detenerse y decirlo, no seguir parchando:
   un ciclo de "diagnóstico → nuevo error → nuevo diagnóstico" consume el
   tiempo de Jhon y erosiona la confianza más rápido que el error original.

7. **Lo que decidió el equipo se respeta.** Nombres, rubros, secciones y el
   `modo` de sync (`fudo_sync.modo`) son decisiones operativas del café. No
   se proponen cambios ahí salvo que Jhon lo pida — y en particular, **nunca
   proponer bajar de `real` a `prueba`**: si el sistema ya está descontando
   en producción, eso es un logro del proyecto, no un riesgo a mitigar.

8. **Un nombre que no calza NO es una receta mal enlazada. Preguntar.**
   *(regla nueva el 2026-07-30, y es la regla 1 de esta misma sección
   incumplida — vale la pena dejar el caso escrito.)*

   Durante semanas el archivo madre arrastró dos "recetas cruzadas
   detectadas y sin corregir", y en el informe de estabilidad las subí a
   **el hallazgo más grave de todos**, con el argumento de que desde que el
   inventario le escribe a Fudo ese error haría vender producto inexistente.
   Jhon las revisó y **ninguna de las dos existía**:

   | Lo que yo reporté | Lo que es de verdad |
   |---|---|
   | `Cheesecake maracuyá` descuenta `T. Cheesecake Mora` → producto equivocado | **No hay cheesecake de mora en la carta.** Hay de frambuesa y de maracuyá. `Mora` es casi seguro `Mara`, abreviatura de maracuyá, mal tipeada. La receta apunta al producto correcto con el nombre mal escrito. |
   | `Cinnamon Roll Vegano` descuenta el cinnamon normal → dos productos distintos | **Es un solo producto.** No hay dos tipos de cinnamon roll: el único que se vende es el vegano. La receta está bien. |

   Las dos veces el razonamiento fue el mismo: *los nombres no coinciden,
   entonces la receta está mal*. Y la regla 1 de esta sección ya decía, en
   estas palabras, que eso resuelve un problema que no existe. Lo que faltó
   no fue una consulta SQL — ninguna consulta habría dicho que en la carta
   no hay cheesecake de mora. **Faltó preguntar.**

   Entonces:
   - **Un nombre raro es una pregunta para el equipo, no un hallazgo.** La
     carta del café no está en la base de datos; está en la cabeza de la
     gente que la vende.
   - **Un nombre mal escrito no rompe nada** (regla 1: la unión es por ID).
     Como mucho es un renombre cosmético, y lo decide Jhon.
   - **Cuidado especial al subir algo de categoría.** Escalar un hallazgo
     viejo a "lo más grave" es fácil de hacer y caro de deshacer: le da
     autoridad a algo que nunca se verificó, solo porque cambió el contexto
     alrededor. Antes de escalar, verificar la base del hallazgo — no solo
     el argumento nuevo.

9. **Un nombre de columna inventado rompe el script entero. Copiarlo del DDL,
   no recordarlo.** *(2026-07-30, y es la regla 0.5 incumplida en su forma más
   simple.)*

   El chequeo de salud usaba `fudo_movimientos.descontado`. Esa columna **no
   existe**: se llama **`aplicado`**. El script falló entero —Postgres analiza
   toda la sentencia antes de ejecutar, así que los 10 bloques murieron por
   una palabra— y Jhon perdió dos vueltas.

   Cómo se coló: probé contra un Postgres local cuyo esquema **escribí yo**, y
   ahí puse `descontado` porque me pareció el nombre natural. La prueba pasó
   en verde validando mi propia invención. Es exactamente lo que dice §0.5:
   *una prueba contra un esquema que uno mismo construye no valida nada.*

   Entonces, al escribir cualquier consulta:
   - **El DDL real del repo es la fuente**, no la memoria. `fudo_movimientos`
     y `fudo_sync` están definidas en `2026-07-fase1-recetas-modo-prueba.sql`.
     Copiar los nombres de ahí, literal.
   - **Si se arma una base local para probar, su esquema se copia del DDL del
     repo**, no se escribe a mano. Un esquema inventado convierte la prueba en
     una tautología.
   - Y aun así el repo no es producción: por eso el patrón bueno es el del
     bloque 4 del chequeo, que **pregunta por `information_schema` si la
     columna existe** en vez de asumirlo. Ese bloque no puede fallar por un
     nombre equivocado — reporta.

   **Columnas que se confunden fácil, escritas acá para no volver a errar:**

   | Tabla | Es | NO es |
   |---|---|---|
   | `fudo_movimientos` | `aplicado` (boolean) | ~~`descontado`~~ |
   | `fudo_movimientos` | `producto_nombre = '(sin receta)'` marca los ítems sin receta | — |
   | `fudo_sync` | `modo` ∈ `prueba` / `real` | — |
   | `productos` | `activo` es **texto** `'SÍ'`, no boolean | ~~`activo = true`~~ |

   **Y un matiz de lógica, no de nombres:** en `modo = 'prueba'` tener
   `aplicado = false` en todo es lo NORMAL —el motor registra sin tocar el
   stock—, así que un diagnóstico que grite "no descuenta nada" sin mirar el
   modo va a dar una falsa alarma cada vez que una sede esté en prueba. Es
   justo lo que va a pasar con Angamos (§9), que arranca en `prueba`.

**Checklist antes de entregar algo que toque datos:**
- [ ] ¿Verifiqué el estado real con un SELECT, o lo inferí de un archivo?
- [ ] ¿Lo que me pidieron era analizar o modificar?
- [ ] Si creo productos: ¿busqué primero si ya existen con otro nombre?
- [ ] ¿Estoy reportando algo como "bug" sin haberlo confirmado?
- [ ] ¿Alguna verificación falló en masa? → parar y decirlo.
- [ ] ¿Estoy proponiendo cambiar algo que el equipo decidió a propósito?
- [ ] ¿Mi hallazgo se apoya en que "dos nombres no calzan"? → preguntar, no reportar.
- [ ] ¿Copié los nombres de columna del DDL del repo, o los escribí de memoria?
- [ ] Si armé una base local: ¿su esquema salió del DDL del repo o lo inventé yo?

---

## 0.2 REGLA DURA — el stock nunca puede ser negativo, sin excepción

> Jhon, 2026-07-27: "es absurdo, no podemos tener números negativos en el
> inventario... esta regla se aplica a todos los productos sin excepción."

> ⚠️ **2026-08-01:** el *traslado automático* de 4 unidades congelador→vitrina
> que vivía en ese mismo archivo **se apagó** (§0.2.1). El **tope en cero sigue
> intacto** — son dos cosas distintas que compartían archivo.

- **Ningún producto, en ningún camino, puede quedar con stock negativo.**
  No solo los que tienen pareja Vitrina/Congelador (`sql/2026-07-reposicion-
  congelador-y-tope-cero.sql`) — **también** los productos con lotes de
  vencimiento (sándwiches, etc.): si se vende más de lo que hay, el sobrante
  ya NO se refleja en negativo, el stock se queda en 0
  (`sql/2026-07-tope-cero-sin-excepcion.sql`, corrige `descontar_lotes()`).
- **Respaldo a nivel de base de datos:** `productos.stock_actual >= 0` y
  `producto_lotes.cantidad >= 0` son restricciones CHECK reales en la tabla
  (no solo lógica en el motor). Esto es intencional: si en el futuro se
  agrega un motor nuevo, una edición manual, o cualquier otro camino que
  intente dejar un número negativo, la base lo rechaza sola, sin depender
  de que alguien se acuerde de esta regla.
- **Si algún cambio futuro a `fudo_procesar_item`, `descontar_lotes()`,
  `descontar_con_reposicion()`, o a la edición manual de stock en la app
  necesita "permitir" un negativo por algún motivo** (ej. para "ver cuánto
  faltó"), eso es una decisión que se pregunta a Jhon explícitamente — no
  se asume. La regla por defecto es tope duro en 0.

---

## 0.2.1 APAGADO — la reposición automática congelador → vitrina

> Jhon, 2026-08-01: *"este parche está trayendo más problemas que soluciones
> realmente. Lo mejor que podemos hacer es desactivar este sistema y pasar a un
> sistema de conteo manual mientras se nos ocurra algo mejor."*

**Qué hacía:** cuando una venta iba a dejar la vitrina en 0, el motor trasladaba
solo 4 unidades desde el producto pareja del Congelador (detectado por nombre
base) antes de descontar.

**Por qué se apagó, y la lección general:** el sistema **movía producto en los
números sin que nadie lo hubiera movido en el mesón.** La app decía que la
vitrina tenía 4 cuando el estante estaba vacío. Es la misma clase de error que
el doble descuento del conteo nocturno (§10.1): **el sistema simulando una
acción física que nadie hizo.** Un inventario puede ir atrasado respecto a la
realidad —eso se corrige contando—, pero no puede inventar movimientos.

**Cómo quedó** (`sql/2026-08-apagar-reposicion-automatica.sql`):

| | |
|---|---|
| Traslado automático de 4 unidades | ❌ apagado |
| Tope en cero (regla 0.2) | ✅ **intacto** — no era parte del parche |
| `fudo_procesar_item` | **no se tocó**: la función auxiliar conserva nombre y argumentos, así que no hubo riesgo de dejar dos firmas (§0.5) |
| Cálculo para Fudo | **no cambia**: `fudo_stock_calculado` ya suma vitrina + congelador por nombre base |
| "Total" en la app | **no cambia**: sigue sumando el par |

**Qué pasa ahora:** la vitrina llega a 0 y se queda en 0. El congelador conserva
su stock. Alguien mueve el producto de verdad y ajusta a mano.

**DECISIÓN CERRADA (Jhon, 2026-08-01), después de evaluar cuatro alternativas.**
La vitrina llega a 0 y **ahí se detiene el descuento**, aunque el congelador
tenga stock. No se cascadea al congelador, no se traslada nada, no se asume
nada. Queda en conteo manual.

**La razón, y es la que zanja el asunto:** *"los jefes de turno pueden poner
cuatro, cinco, incluso seis productos. Muchas veces hay dos en vitrina y por
rellenar ponen otros dos."* **La cantidad de reposición es variable y nadie la
registra.** Cualquier número que el sistema asuma va a estar equivocado casi
siempre, y cada suposición descalibra un poco más el modelo.

Se evaluó y se **descartó** que la venta cascadeara al congelador cuando la
vitrina llega a 0. El argumento a favor era que la venta prueba que el producto
salió del local; el argumento en contra —el que ganó— es que igual obliga al
sistema a interpretar un movimiento entre estantes que nadie mapeó.

Aplica a los pares vitrina/congelador: brownies, donas, cinnamon rolls,
muffins, galletones y demás bollería.

**El costo aceptado, dicho sin adornos:** con la vitrina en 0, las ventas
siguientes **no se descuentan de ninguna parte**. El total que muestra la app
—y el que se le manda a Fudo— queda por encima de la realidad hasta el
siguiente conteo. Es un atraso conocido y corregible contando, y se prefiere a
un número inventado que parece exacto.

**Antes de proponer una versión nueva de esto**, entender por qué falló la
primera: no fue el número 4 ni la detección de la pareja. Fue que **el traslado
físico y el traslado en los números son dos hechos distintos**, y el sistema
asumía el segundo sin evidencia del primero. Cualquier solución futura tiene que
apoyarse en algo que alguien haga de verdad — no en una suposición.

**Cómo se comprueba que quedó apagado.** Contar las firmas NO alcanza: si el
`create` fallara, el conteo daría lo mismo. Hay que mirar el cuerpo instalado —
`pg_get_functiondef()` y buscar `v_trasladar` / `least(4`. Está como bloque 4
del propio archivo, y probado en las dos direcciones: delata la versión vieja y
confirma la nueva.

**Probado** contra un esquema copiado del DDL del repo, en las dos direcciones:
con la versión vieja instalada la vitrina saltaba sola de 1 a 4 y el congelador
bajaba de 9 a 5; con la nueva la vitrina queda en 0, el congelador queda intacto
en 9, y vender 5 teniendo 2 sigue dejando 0 y no −3.

**Cómo se vuelve atrás:** correr de nuevo
`sql/2026-07-reposicion-congelador-y-tope-cero.sql`.

---

## 0.3 REGLA DURA — las fechas de los sándwiches se muestran TODAS, siempre

> Jhon, 2026-07-27: "los sándwiches son uno de los nervios más críticos de la
> cafetería... necesito que de un vistazo podamos ver TODAS las fechas de
> vencimiento de ese pancito. Esto es extremadamente delicado."

- **En la lista del inventario, un producto perecedero muestra una píldora por
  CADA fecha de vencimiento**, con su cantidad y el día exacto. Nunca se
  resume, nunca se esconde detrás de un "+N fechas" ni de un "ver más" — eso
  fue justamente lo que hubo que corregir. Si hay 4 fechas, se ven las 4 sin
  abrir la ficha ni tocar nada.
- **Formato de la píldora: `cantidad V fecha`, con año completo** → `5 V 27/07/2026`. La urgencia
  la lleva el COLOR, no la palabra (rojo relleno = VENCIDO, rojo claro = vence
  hoy, ámbar = mañana, gris = más adelante). Se llegó a esto porque
  "5 vencen mañana 28/07/26" no cabía y el texto se encimaba. **Vencido y
  "vence hoy" tienen que seguir distinguiéndose de un vistazo** — uno se bota
  y el otro se vende; por eso vencido es rojo relleno y no comparte estilo.
- **Dos formatos de fecha, a propósito** (`fmtPildora` y `fmtCorta`): la
  píldora de la lista lleva el año completo (`27/07/2026`) para que en pantalla
  no quede duda del año; el resumen de WhatsApp va en año corto (`27/07/26`),
  que es como lo pidió Jhon. Cambiar uno no implica cambiar el otro.
- Si un cambio futuro necesita acortar, agrupar o esconder fechas por razones
  de espacio, **se pregunta a Jhon primero**. Ahorrar dos líneas de pantalla no
  justifica que una fecha deje de verse.

### 0.3.1 Quién manda cuando el stock y las fechas no cuadran

> Jhon, 2026-07-27: "la mejor opción es siempre creerle al stock cero. Si está
> en stock cero, la fecha sobra. Ahora, hay que tener mucho cuidado, porque
> cuando tú agregas fechas a un sandwichito son las fechas las que dicen qué
> cantidad hay."

**La invariante:** en un producto con fechas, `stock_actual` = suma de las
cantidades de sus lotes (lo mantiene el trigger `sync_stock_desde_lotes`). Si
alguna vez no cuadra, hay un problema — no es un caso normal.

Las dos direcciones NO son simétricas, y confundirlas rompe el inventario:

| Situación | Quién manda |
|---|---|
| Alguien **agrega/edita fechas** en la ficha | **Las fechas.** El stock se calcula sumándolas; el campo de stock queda de solo lectura. Esto no se toca. |
| El producto quedó en **stock 0** y le sobran fechas | **El stock.** Las fechas se borran (no hay unidades que puedan vencer). |

- Una **fecha con cantidad 0 no es una fecha**: no se muestra en la lista, no
  se copia en el resumen y se borra de la base. Son filas que quedan vacías al
  descontar.
- Limpieza de descuadres:
  `sql/2026-07-fechas-en-vivo-y-limpieza.sql` (respalda antes de borrar).
- **`producto_lotes` tiene que estar en la publicación `supabase_realtime`.**
  No lo estaba, y esa fue la causa de un susto real: al vender, el teléfono
  recibía el stock nuevo pero seguía mostrando las fechas viejas, así que se
  veía "Champiñón 0" junto a "1 vence hoy" y el resumen a Adriana salía con
  cantidades que ya no existían. Si se crea otra tabla que la app lea en vivo,
  hay que acordarse de publicarla.
- **Antes de tocar cualquier cosa de sándwiches/fechas: verificar con un
  SELECT y preguntar.** Es el punto más delicado de la cafetería; un número
  equivocado acá manda a botar comida buena o a vender comida vencida.

---

## 0.4 REGLA DURA — un perecedero entra al inventario SOLO por fechas

> Vale para el reparto, para la ficha del producto y para cualquier camino
> futuro que sume stock.

- **Nunca sumar a `productos.stock_actual` de un producto perecedero.** Se
  insertan filas en `producto_lotes` y el trigger `sync_stock_desde_lotes`
  recalcula el stock. Si se suma al stock directo, se rompe la invariante de
  la sección 0.3.1 y vuelve el descuadre de "Champiñón 0 con fecha".
- `reparto_recibir()` lo hace cumplir **en la base**: si el producto es
  perecedero (o ya tiene lotes) y no le llegan fechas, lanza un error en vez
  de sumar. No depende de que la app se acuerde.
- En la pantalla, un perecedero no tiene campo de cantidad: tiene botón de
  fechas, y **la cantidad recibida se calcula sumando las fechas**.

---

## 0.5 REGLA DURA — tocar el motor de descuento (la falla del 2026-07-27)

> El sistema estuvo ~15 horas leyendo ventas y descontando NADA, mostrando
> "ventas actualizadas" en la pantalla. Jhon lo descubrió a mitad de turno
> vendiendo una medialuna de membrillo. Es la peor falla que ha tenido el
> proyecto, y la causa no fue una línea mal escrita: fue el método.

### Qué pasó, en orden

1. **Se escribió el motor v5 suponiendo el estado de producción a partir del
   repo.** El archivo `2026-07-fecha-real-de-venta.sql` estaba en git con la
   columna `venta_at`, así que se dio por corrido. **Nunca se había
   corrido.** El motor v5 escribía una columna que no existía → excepción en
   cada venta.
2. **El `drop` apuntaba a una sola firma.** El script hacía
   `drop function ...(...,timestamptz)`, que borra la firma de 8 argumentos.
   En producción vivía la de **7** (motor v3). No se borró, y el `create`
   agregó una segunda. Quedaron **dos `fudo_procesar_item` conviviendo**.
3. **La llamada por la API quedó ambigua.** Desde SQL el motor funcionaba
   perfecto, porque ahí los argumentos deciden cuál usar. Pero la Edge
   Function llama por PostgREST, que con dos funciones del mismo nombre no
   puede elegir y **rechaza la llamada antes de ejecutar nada**.
4. **El fallo era invisible.** La Edge Function cuenta cada venta fallida en
   un campo `errores` y devuelve `ok: true` igual. La app solo mostraba
   "N ventas · M descuentos" y jamás ese número. Nada en pantalla decía que
   el inventario llevaba horas congelado.

### Por qué las pruebas no lo detectaron (esto es lo importante)

El motor v5 se probó contra un Postgres local con 5 escenarios y todos
pasaron. **Pero ese Postgres lo construyó Claude desde cero copiando el
esquema del repo**: tenía `venta_at` porque el repo la tenía, y no tenía
ninguna función vieja porque era una base recién creada.

Se probó contra un mundo ideal idéntico al repo, no contra el mundo real.
Las pruebas validaban la LÓGICA del motor —que estaba bien— y no el ENCAJE
con la base que existe. De ahí la falsa confianza: 5 escenarios en verde
mientras el cambio era imposible de ejecutar en producción.

**Una prueba contra un esquema que uno mismo construye no valida una
migración. Solo valida la lógica.**

### Reglas, entonces

- **Antes de escribir un script que toque el motor, MIRAR la base real.**
  Qué columnas tiene `fudo_movimientos`, qué firmas de `fudo_procesar_item`
  existen. Son dos consultas y evitan las dos causas de esta falla:
  ```sql
  select column_name from information_schema.columns
   where table_schema='public' and table_name='fudo_movimientos';
  select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='fudo_procesar_item';
  ```
- **El script se basta solo**: crea las columnas que usa
  (`add column if not exists`) aunque "ya deberían estar".
- **Al reemplazar una función, un `drop` por cada firma vieja posible.**
  Nunca solo la firma nueva.
- **Después de instalar, comprobar que quedó UNA sola firma** y correr el
  motor a mano una vez antes de darlo por bueno.
- **Ojo con `begin/rollback` en el editor de Supabase: NO se respeta.** Un
  diagnóstico "inocuo" con rollback escribió filas y descontó stock de
  verdad. Si un script prueba algo que escribe, decirlo así y dar la
  limpieza — no prometer que no deja rastro.

### Y la regla que evita que se repita el silencio

**Un fallo del motor tiene que verse en la pantalla.** Ya está hecho: si la
sync lee ventas y no descuenta ninguna, la app abre una ventana que dice
*"El inventario no se está descontando"* con el número de errores, en vez
del "✓" de siempre. Cualquier cambio futuro al aviso de sincronización
mantiene esto: **un sistema que falla en silencio es peor que uno que se
cae**, porque nadie va a buscar lo que parece estar bien.

---

## 0.6 REGLA DURA — antes de escribir en una sede viva, SACA LA FOTO

> **El error más caro del proyecto. 2026-08-09.** Jhon: *"creo que estamos
> frente a una de las meteduras de pata más grandes que hemos metido durante
> todo este proyecto."* Y tenía razón.

### Qué pasó

El 9 de agosto, a las 17:00, **260 productos de Angamos quedaron en cero de
una sola vez** (ids 730–1018, o sea prácticamente toda la sede). Se perdió el
stock. Jhon tuvo que volver a cargarlo entero a mano.

**No se pudo restaurar nada.** No por falta de herramienta: porque **no había
ninguna foto de Angamos que restaurar.** La tabla `historial` estaba vacía para
esa sede — nadie había apretado nunca "Guardar inventario de hoy" ahí.

### La causa que de verdad importa

No es "qué comando lo hizo". Sigue **sin determinarse** qué produjo el cero
masivo, y **no hay que inventar una explicación** — se comprobó que ninguno de
los scripts entregados ese día tenía un `update` ni un `delete` sobre
`productos` (solo un `insert` de 9 filas), pero eso descarta un culpable, no
identifica al otro.

**La causa real es que se dirigió una tanda de escrituras sobre una sede en
producción sin haber sacado antes una copia de esa sede.** El plan sí decía
"respaldo antes del paso 7" — y las escrituras ocurrieron en el paso 3.
El respaldo llegaba tarde en el propio plan.

### El latigazo — por qué el daño no se mide el día que pasa

Jhon lo nombró mejor que yo: *"este error tiene latigazo… las repercusiones
vienen mañana."* El inventario volvió a un estado viejo, así que **Adriana iba
a armar el reparto del día siguiente mirando lo que faltaba el 07, no el 09.**

**Un dato malo en un inventario no hace daño cuando se corrompe: hace daño
cuando alguien toma una decisión con él.** Ese retraso —de horas o de un día—
es lo que hace que estos errores se descubran tarde y cuesten el doble.

### LAS REGLAS

1. **Antes de cualquier tanda de escrituras sobre una sede, esa sede tiene que
   tener una foto del día.** El mecanismo ya existe y es el botón **"Guardar
   inventario de hoy"** de la app, que escribe en `historial` el nombre, la
   **sección**, el stock, el mínimo y el máximo de cada producto, por
   `producto_id`. Es la copia más barata que tiene el proyecto.
   **Si `historial` de esa sede está vacío, NO se escribe nada hasta que haya
   una foto.** Se comprueba con una línea:
   ```sql
   select fecha, count(*) from public.historial where sede='<la sede>'
    group by fecha order by fecha desc limit 5;
   ```
2. **El respaldo va ANTES del primer paso que escribe, no antes del paso más
   riesgoso.** El paso "inofensivo" que corre primero es el que te deja sin
   red para todos los demás.
3. **`activo = 'SÍ'` es un filtro peligroso cuando se busca "si algo ya
   existe".** Eliminar en esta app **no borra: desactiva** (`index.html:2792`).
   Una comprobación de existencia que solo mira activos **no ve lo que el
   equipo eliminó a propósito**, y crea duplicados. Pasó dos veces el mismo
   día: en el `insert` de productos y en la vista previa del repunte de
   recetas — donde además hizo que la vista previa **mintiera por omisión**,
   mostrando 206 casos cuando eran 215.
   **Una vista previa y su comprobación tienen que usar exactamente el mismo
   filtro.** Si no, la vista previa no es una vista previa.
4. **Una sede en `real` sin foto es una sede sin red.** Angamos estaba en
   `real` por decisión de Jhon (§9.5) y con buenas razones — el problema no
   fue el modo, fue que no había copia.

### Lo que sí sobrevivió, y por qué

| | |
|---|---|
| **Recetas** | ✅ 170 recetas, 214 renglones. El repunte funcionó |
| **Mínimos** | ✅ solo 8 de 249 productos los perdieron |
| **Productos eliminados** | ✅ nunca se borran, quedan `activo='NO'` |
| **Stock** | ❌ **irrecuperable** — no había foto |

La diferencia entre las tres primeras filas y la última es exactamente esta
regla: **de lo que había copia, se recuperó; de lo que no, no.**

### El estado de la bodega quedó en pausa

Jhon, el mismo día: *"el costo de oportunidad de seguir con la bodega actual es
de alto riesgo, y actualmente tengo una alta aversión al riesgo… este proyecto
tiene fecha de entrega, y es el 27."*

**Nada de bodega se retoma sin cerrar antes esta regla.** Y la decisión entre
reconstruir bodega desde cero o seguir con la actual **es suya y está
pendiente** — no se avanza por defecto.

---

## 0.65 REGLA DURA — quién puede escribir en Fudo (doctrina, 2026-08-21)

> Fijada por Jhon el día que el reparto dejó de subir a Fudo. Él la escribió
> punto por punto para que "en futuros cambios no se ponga un candado".

1. **El botón ⟳ lo aprieta CUALQUIERA.** Sin excepción, sea jefe o no. Hace
   lo mismo que el empuje de administración: manda el inventario COMPLETO,
   no una suma.
2. **El reloj automático corre SIEMPRE**, en la cuenta que sea. Usa
   `SISTEMA_TOKEN` y no pasa por ningún permiso — si alguien se lo pone, el
   inventario se desincroniza de noche y nadie lo ve hasta la mañana.
3. **El reparto sube a Fudo SIEMPRE**, lo acepte quien lo acepte. Y suma, no
   reemplaza.
4. **El ÚNICO candado del sistema es la puerta de Ajustes** (`puede_ajustes`).
5. **No hay restricciones para escribir en Fudo.** Si algún día hay que
   cerrar algo, se cierra desde Ajustes, cuenta por cuenta — nunca
   escribiéndolo en el código.

### De dónde salió el candado que rompió el reparto

`puede_fudo` nació el **2026-07-28** con el botón rojo de administración, y
ahí era razonable: había UN camino a Fudo y era un empuje masivo de jefatura.
Después se agregaron caminos que no se parecen en nada a aquel —recibir un
reparto, mermar, el reloj— y **cada uno copió el mismo candado "igual que el
resto"**, sin que nadie decidiera que correspondía. El comentario original de
`fudo-sumar-stock` lo dice con esas palabras.

**El candado no se diseñó para esos caminos: se heredó.** Y el golpe de
gracia fue que la app creaba las cuentas nuevas con `puede_fudo:false`
(`index.html`, alta desde Ajustes), así que **nacían sin poder actualizar
Fudo** y había que acordarse de dárselo.

**La lección general, que vale más que el caso:** un permiso pensado para una
acción no se hereda a otra solo porque toca el mismo sistema externo. Lo que
importa no es *qué* toca, sino **si decide algo**. Recibir un reparto no
decide nada — alguien ya abrió la caja y contó. Un permiso ahí no evitaba que
el pan llegara: evitaba que Fudo se enterara.

### Cómo quedó: se guarda lo que NO se puede

`app_permisos.fudo_bloqueos text[]`, vacío para todos
(`sql/2026-08-permisos-de-fudo.sql`).

**Guardar los bloqueos y no los permisos es lo que hace que el incidente no
se pueda repetir.** Una cuenta nueva, una fila que falta, la columna que
todavía no existe, una lectura que no llegó o ninguna sesión significan todas
lo mismo: **ningún bloqueo, o sea puede todo**. Nacer abierto deja de ser un
valor por defecto que alguien puede cambiar sin querer, y pasa a ser la forma
de la tabla.

### Los ocho caminos que escriben en Fudo

Viven en `FUDO_ACCIONES` (`index.html`) con su nombre en castellano y qué
pasa si se apagan. **Un camino nuevo se agrega ahí**; si no está, no se puede
apagar desde Ajustes, y eso es a propósito.

| clave | Qué es |
|---|---|
| `boton` | el ⟳ de la barra · manda el inventario completo |
| `ficha` | el botón dentro de la ficha de un producto |
| `todo` | el empuje grande de Ajustes |
| `reparto` | al recibir un reparto · **suma** lo que llegó |
| `merma` | al mermar · le baja a Fudo lo botado |
| `crear` | crear un producto en Fudo |
| `apagar` | encender o apagar un producto en Fudo |
| `deshacer` | deshacer el último empuje |

**No están acá, y es correcto:** el reloj automático (punto 2), leer el
catálogo y leer las ventas — esas no escriben en Fudo.

**Esto es un seguro contra el resbalón, no seguridad**, igual que el Modo
edición (§6.1, §9.6). Se comprueba en la app, no en el servidor, **y eso es
deliberado**: un candado del lado del servidor es exactamente lo que produjo
el 403 silencioso del 21 de agosto. Se dice en pantalla con esas palabras.

Pantalla: **Ajustes → Fudo → "Permisos de actualización a Fudo"**.
Prueba: `pruebas/permisos-de-fudo.mjs`, 44 casos — la mitad dedicados a
comprobar que todo lo que puede fallar signifique "puede todo".

---

## 0.66 REGLA DURA — todo producto tiene un ORIGEN, y hay que preguntarlo

> Jhon, 2026-08-22, razonando el modelo — **no viéndolo fallar**. Es la primera
> vez en este proyecto que un fallo silencioso se atrapa antes de que muerda.

**El principio:** Llamita es un sistema con **inicio y fin**. Un producto entra,
viaja, se vende. Y lo más importante para cualquier cosa que se construya
después: **todo lo que SUMA en una sede tiene que RESTAR en algún lado — o en
ninguno, pero a propósito.**

### Los tres orígenes, y qué hace cada uno

| Origen | Qué pasa al recibirlo en la sede |
|---|---|
| **Bodega** | bodega **baja**, la sede sube. Es un traslado |
| **Otra sede** (Angamos → Plaza) | Angamos **merma** (stock y Fudo), Plaza suma. **Bodega no se toca** |
| **Proveedor** | **nada baja en ningún lado.** Solo sube en la sede |

El caso que lo destapó: las **medialunas**. Existen en bodega y en Angamos,
pero al local las trae un repartidor. Adriana igual arma esa línea desde
Bodega —porque es ella quien organiza el envío—, y Llamita daba por hecho que
todo lo que sale de esa pantalla sale de bodega.

**Por qué no se veía:** bodega recién se está contando. Dentro de un mes, con
el conteo cuadrado, **bodega diría 0 medialunas donde hay 7**.

### LA REGLA

> **Toda construcción futura que mueva stock tiene que preguntar de dónde sale
> ese producto.** No asumirlo por la pantalla desde la que se armó.

Un producto que aparece en bodega **no prueba** que venga de bodega. Esa
inferencia —"se armó en la pantalla de bodega, entonces sale de bodega"— es
justamente el error.

### Cómo quedó, y por qué costó tan poco

**Cero cambios en la base.** `reparto_recibir()` descuenta de bodega **solo si
la línea trae `producto_bodega_id`** (`sql/2026-08-central-reparto-descuenta.sql`).
El motor ya hacía la pregunta correcta desde el principio: **nunca faltó
lógica, faltaba una forma de decirle que no.**

Una línea de proveedor viaja con ese campo en `null` y bodega ni se entera.
En la pantalla es una píldora que se toca: `de bodega · 12 → 9` (gris) /
`de proveedor · bodega no baja` (ámbar).

**Y una distinción que importa:** "de proveedor" es una **decisión** y no
pregunta nada; "sin enlace" es un **hueco de configuración** y sí avisa al
enviar. Antes eran lo mismo —las dos dejaban a bodega sin descontar— y
mezclarlas convertía el aviso en ruido que Adriana iba a aprender a saltarse.

Prueba: `pruebas/origen-del-reparto.mjs`, 15 casos, con el caso de las
medialunas de punta a punta.

---

## 0.7 REGLA DURA — la bodega es `central`, y `bodega` es la vieja

> Decisión de Jhon del 2026-08-10, después del incidente de §0.6: en vez de
> depurar la bodega que existía, **construir una nueva desde cero sin heredar
> nada**. *"mejor construirlo desde cero, no heredar nada, así tienes el
> control de todo."*

**El problema de la bodega vieja nunca fue que estuviera sucia:** sus filas
**SON** las de la Angamos vieja renombrada en julio, y por eso las recetas, los
repartos y el historial de ventas apuntan ahí. Una sede nueva nace sin una sola
herencia: nada viejo la señala.

| | |
|---|---|
| Clave interna | **`central`** |
| En pantalla | dice **"Bodega"** — para el equipo no cambió nada |
| Nació con | 236 productos depurados (de 351 activos, quitando 117 duplicados). Quedaron **234** |
| Stock | **0 a propósito.** El de la vieja arrastra el descuadre de las 254 unidades del problema de las recetas; copiarlo sería heredar un error sin saber de cuánto es |
| La vieja | intacta, oculta del portal. **Ni un update, ni un delete** |

**POR QUÉ LA CLAVE NO ES `bodega`, y esto es lo más importante del diseño.** La
palabra `bodega` quedó ocupada para siempre por la vieja. Reciclarla sería
repetir **exactamente** la causa del incidente: una misma palabra significando
dos cosas según la fecha, y alguien teniendo que adivinar cuál. **Una fila que
diga `bodega` es la vieja. Siempre. Sin excepción.**

**Por qué no se borra la vieja:** verificado, no supuesto —
`reparto_items.producto_id` tiene llave foránea a `productos` sin cascada, así
que cualquier producto que aparezca en un reparto no se puede borrar. Se oculta
sacándola del portal, que es un cambio en `index.html` y no en la base.

### Las reglas de esta etapa (Jhon, 2026-08-10), y no se negocian

1. **No se toca, modifica, edita, borra ni agrega nada en ninguna sede que no
   sea `central`** — salvo que él lo pida explícitamente y por escrito en el
   momento. Lo repitió dos veces: *"insisto en que no quiero que elimines nada
   de ninguna sede"*. Los productos con "bodega" en el nombre metidos en
   Angamos **los depura él**, no nosotros.
2. **Nada de la bodega vieja.** Es un apéndice y qué hacer con él se decide
   después.
3. Única excepción autorizada: **agregar** el aviso de reparto en Angamos —
   agregar, nunca modificar ni quitar.

### REGLA — el reparto llega SIEMPRE al congelador

*(Jhon, 2026-08-12.)* En Mall Plaza varios productos están duplicados a
propósito: uno vive en el **Congelador** y su gemelo en la **Vitrina** (`Mini
muffin Congelador` / `Mini muffin Vitrina`). Es el fenómeno de §0.2.1.

> **Todo producto que tenga doble en vitrina y congelador: lo que viene de
> bodega entra al CONGELADOR, siempre.**

`producto_enlace` solo admite **un gemelo por sede**, así que hay que elegir —
y la respuesta es el del congelador, porque es donde la caja aterriza de
verdad. Apuntar a la vitrina sumaría stock a un estante que nadie llenó, que
es exactamente el error que hizo apagar la reposición automática.

Comprobado el 2026-08-12: de los 290 pares escritos, **uno solo** apuntaba
mal (`Alfajor artesanal` → vitrina #76 en vez de congelador #687).

### El enlace se GUARDA por id; el nombre solo sirve para PROPONER

*(Aclaración pedida por Jhon el 2026-08-12, y vale para cualquier
emparejamiento futuro — recetas, gemelos, lo que venga.)*

`producto_enlace` guarda **dos números** (`producto_bodega_id`,
`producto_sede_id`) y **ninguna columna de nombre**. Renombrar un producto no
rompe un enlace ya escrito. Nunca.

El nombre se usa **una sola vez**, para adivinar qué par proponer, porque
entre un producto de bodega y uno del local **no existe ninguna relación
previa**: son filas creadas en momentos distintos, sin código común, sin id de
Fudo compartido. Alguien tiene que crear esa relación de cero, y las únicas
señales disponibles son el nombre y el criterio de una persona.

**Las dos consecuencias que hay que decir en voz alta, porque confunden:**

1. Si el nombre cambia **entre que se propone y que se escribe**, el par no se
   escribe. No se rompe nada — nunca llegó a existir. Pasó el 2026-08-12: el
   informe dijo 148 pares para Plaza y se escribieron 146, porque Jhon estuvo
   renombrando productos entremedio.
2. Volver a correr el script de gemelos **no repara** enlaces: agrega los que
   faltan. La distinción importa, porque decir "córrelo cada vez que renombres"
   suena a que los enlaces dependen del nombre, y no es así.

### La pantalla de Enlaces — dónde se arreglan los gemelos

*(Construida el 2026-08-12. Maqueta aprobada por Jhon antes de escribir código:
`docs/propuesta-enlaces.html`.)*

Pestaña **Enlaces**, solo en Bodega. Es una página, no una ventana emergente —
emparejar setenta productos abriendo y cerrando una ventana cada vez es
agotador. Dos modos:

| | |
|---|---|
| **Enlazar** | Los 234 con su estado por sede. Al entrar a uno, propone candidatos del local y se toca el gemelo. Cuando hay doble, el del congelador va primero y marcado — sugiere, no obliga |
| **Producto nuevo** | Crea el producto en bodega y en las sedes elegidas, y los enlaza. Una sola operación en la base (`crear_producto_enlazado`) |

**Lo que la hace segura, y sale de reglas viejas:** la sección se elige de las
que YA existen en esa sede (nunca se inventa una); el stock nace en 0; el
mínimo y el máximo **no se copian** al local porque allá significan otra cosa;
busca duplicados **incluyendo los apagados** antes de crear; y si el producto
ya existe apagado, se detiene y avisa en vez de revivirlo (§0.6.3).

**Desde acá no se borra ni se apaga nada.** Solo se agrega.

**Enlaces ≠ Recetas, y no comparten trabajo.** `producto_enlace` solo le sirve
al REPARTO: que un envío de bodega sepa a qué producto del local sumarle.
**No tiene nada que ver con que Fudo descuente al vender** — eso lo hacen las
`recetas`, por sede, y existían antes de que `central` naciera. Un producto de
bodega "sin enlace" hoy no deja de descontarse nada en ningún local: el
reparto todavía no está construido, así que un enlace que falta no bloquea
nada del día a día. Aclarado el 2026-08-13 porque los dos nombres se prestan
a confusión y Jhon preguntó exactamente esto.

**Si un producto de bodega no propone candidatos NI a mano, revisar si sobra
un duplicado antes de asumir que falta un enlace.** Caso real: `Sprite cero`
(error de tipeo) no tiene destino posible porque `Sprite zero` —el correcto—
ya está enlazado, y la base no deja que un producto del local tenga dos
orígenes. La solución ahí no es un enlace, es que el equipo decida qué hacer
con el duplicado (ver `docs/pendiente-gemelos-sin-pareja.md`).

### REGLA DURA — en Bodega, cada pantalla contesta una DECISIÓN

*(2026-08-13, después de entregar una lista de texto donde se había pedido un
vistazo. Jhon: "yo lo que necesito son o gráficos o tarjetas".)*

**El objetivo de Bodega no es mostrar el inventario: es que Adriana decida qué
mandar hoy, rápido.** Todo lo que se construya ahí se juzga contra esa frase.

**La prueba, y es una sola:** ¿se entiende **sin leer**? Un número grande, una
barra, un color — eso se entiende de un vistazo. Una lista de catorce filas con
fechas **no**, por muy correcta que sea la información.

Se entregó exactamente eso —los sándwiches de los dos locales listados con
todas sus fechas— y hubo que revertirlo entero. El dato era cierto y útil; la
forma lo hacía inservible. **Información correcta presentada como lista es una
funcionalidad no entregada.**

Las tres reglas que salen de ahí, para cualquier pantalla de Bodega:

1. **Números y barras primero; el detalle se toca, no se lee.** Si hace falta
   recorrer con el dedo para entender, está mal resuelto.
2. **Comparar contra la referencia que importa, no entre sedes.** Cada local
   tiene su propio mín/máx: Plaza con 38 sándwiches sobre un mínimo de 50 está
   mal, y Angamos con 50 sobre un mínimo de 30 está bien. Ponerlas a competir
   por el número absoluto miente.
3. **Decir la instrucción, no el indicador.** "Para 3 días, mandar 27" es
   accionable; "cobertura 44%" hay que traducirlo.

**Y el atajo que evita repetirlo: maqueta antes de código.** Ya funcionó dos
veces (`docs/propuesta-enlaces.html`, `docs/propuesta-tablero.html`) y la vez
que se saltó, se perdió el trabajo entero. Jhon lo pidió con esas palabras: *"me
ahorraré en el futuro iterar en el frontend"*.

### Las ventas ya están en la base: no hace falta la API de Fudo

`fudo_movimientos` guarda **cada ítem vendido** con `sede`, `producto_id`,
`cantidad_vendida` y `created_at`, desde que el motor se encendió
(`sql/2026-07-fase1-recetas-modo-prueba.sql`).

Cualquier pregunta del tipo *"cuánto se vendió los últimos días"* — para
gráficos, para proyectar demanda, para el relleno del reparto — **es una
consulta agrupada por día, no una integración**. Verificado el 2026-08-13.

La API de Fudo solo haría falta para lo que el motor NO registra: importes,
medios de pago, mesas abiertas.

### El reparto descuenta al ACEPTAR, no al enviar

*(Decisión de Jhon del 2026-08-10, y cambia lo que decía `docs/plan-bodega.html`.)*

**El producto no se mueve de ningún lado hasta que alguien lo acepta en
destino.** Al aceptar en Angamos o Plaza: se descuenta de `central` y se suma en
la sede, en el mismo momento. Si se rechaza o no llega, no pasa nada — porque
nunca se movió nada.

Se evaluó la otra opción —restar al enviar y mostrar "en tránsito"— y se
descartó. **La razón de fondo es la regla de §0.2.1:** el sistema no puede
simular un movimiento que nadie hizo. Al enviar actuó una sola persona y la caja
todavía puede quedarse en el pasillo; al aceptar actuaron dos, y ahí sí hay
evidencia. Además desaparece el limbo y con él la posibilidad de descontar dos
veces.

**El costo aceptado:** entre que sale y que se confirma, `central` muestra
producto que ya salió físicamente. Se resuelve **sin tocar el stock**: al armar
un reparto, junto al "hay 12" va "· 5 comprometidos". El número no miente
porque nada se movió.

---

## 0.8 REGLA DURA — antes de poner un candado, seis preguntas

> Pedida por Jhon el 2026-08-25, el día que un candado mío le impidió crear un
> producto que necesitaba: *"he pensado en lo común que es este problema,
> implemento un cambio importante y este a veces me limita o crea otros
> problemas"*. Él trajo una lista de quince preguntas; esto es esa lista
> refinada contra los golpes que este proyecto ya se dio.

### La pregunta que manda, y de la que salen las demás

> **¿Esta regla describe lo que pasa CASI SIEMPRE, o lo que tiene que pasar
> SIN EXCEPCIÓN?**

Si es lo primero, va como **valor por defecto**. Si es lo segundo, va como
**candado**. Confundirlas es el error, y en este proyecto tiene nombres
propios:

| La regla | Qué era | Qué se hizo |
|---|---|---|
| "Todo producto nace en bodega" | **casi siempre** | se puso como candado → bloqueó el gemelo de vitrina, y encima creaba un duplicado sin sección |
| "Todo lo que sale de bodega entra al congelador" | **casi siempre** | se sugiere y se marca primero, no se obliga (§0.7) |
| "Quien empuja a Fudo necesita permiso" | **una preferencia** | se puso como candado → rompió el reparto (§0.65) |
| "El stock nunca queda negativo" | **sin excepción** | candado, y con `CHECK` en la tabla (§0.2) |
| "Un perecedero entra solo por fechas" | **sin excepción** | candado, en la base (§0.4) |
| "El reparto no descuenta dos veces" | **sin excepción** | candado |

**El patrón, y es la regla práctica que resume todo:** los candados legítimos
de este proyecto **protegen la integridad de los datos**. Ninguno protege una
preferencia sobre cómo se trabaja. Cuando un candado protege una forma de
trabajar, tarde o temprano aparece la persona que necesita trabajar distinto —
y el candado se lo impide sin que nadie lo haya decidido.

### Las seis preguntas

1. **¿Casi siempre o sin excepción?** Casi siempre → valor por defecto, no
   candado.
2. **¿Protege los datos o una forma de trabajar?** Solo lo primero justifica
   un candado.
3. **Nombra una excepción legítima.** Si no aparece ninguna en dos minutos,
   es que no se buscó — este sistema tiene demasiadas piezas como para que de
   verdad no exista.
4. **Si la regla se cumple *casi*: ¿avisa, o hace algo raro en silencio?**
   No es "¿qué pasa si falla?". Es qué pasa con el 5% que no encaja. El
   candado de bodega **no daba error**: creaba el duplicado y decía "listo".
   Un candado que se equivoca gritando cuesta una vuelta; uno que se equivoca
   callado cuesta un mes hasta que alguien nota el descuadre (§0.5).
5. **¿Lo decidí para ESTE caso, o lo heredé de otro que se le parecía?**
   `puede_fudo` nació bien, para un empuje masivo de jefatura. Cada camino
   nuevo lo copió *"igual que el resto"* sin que nadie decidiera que
   correspondía, y terminó impidiendo que llegara el pan. **Lo que importa no
   es qué toca una acción, sino si decide algo.**
6. **¿Se puede apagar y volver a como estaba?** Es §2.2. Es la red que hace
   que equivocarse en las cinco anteriores no sea fatal.

### La pregunta que hay que BORRAR de la lista

*"¿Tengo evidencia de que esta regla necesita ser obligatoria?"* Suena
rigurosa y es trampa: **casi siempre hay evidencia a favor** —un caso real
donde el candado habría ayudado— y esa evidencia no dice **nada** sobre los
casos que va a romper. Había evidencia para "todo nace en bodega": evita
duplicados. Era cierta. Y aun así estaba mal.

La versión útil es la pregunta 3, y funciona porque obliga a **encontrar** la
excepción en vez de preguntarse si existe.

---

## 0.9 REGLA DURA — LLAMITA STOCK NO SE TOCA mientras se construye LAMA

> Jhon, 2026-08-27, al abrir el chat que construye el área de ventas:
> *"lo más importante es que no se toque nada de Llamita Stock."*

**El proyecto tiene ahora DOS mitades, y una está en producción.**

| | |
|---|---|
| **Llamita Stock** | el inventario. **Lo usa el equipo todos los días.** Terminado y funcionando |
| **Llamita Lama** | el área de ventas —mesas y comandas—. **En construcción, escondida** |

### La regla, y no admite matices

> **Mientras se construya Lama, no se toca NADA de Stock.** Ni una pantalla,
> ni una función, ni una tabla, ni un `.sql` que ya corrió. Nada.

Eso incluye lo que parece inofensivo: renombrar una variable, mover una
función de sitio, "aprovechar y arreglar" algo que se ve mal al pasar.
**Un cambio que no se pidió es un riesgo que nadie aceptó.**

### Por qué es tan dura, y no es paranoia

Es la lección de §0.6 llevada a su forma general. El 9 de agosto Angamos
quedó en cero porque se escribió sobre una sede viva sin red. Acá el riesgo
es el mismo con otra cara: **Stock está en producción y Lama no**. Si algo se
rompe mientras se construye lo nuevo, el daño cae sobre gente que está
trabajando, y encima nadie sabría cuál de los dos lo causó.

Y hay una razón de método: **si Stock no se toca, cualquier cosa que falle
en Stock NO puede ser culpa de este chat.** Eso es lo que hace que el trabajo
sea diagnosticable. En el momento que Lama edite algo de Stock, esa certeza
se pierde para siempre.

### Lo que SÍ se puede tocar

- `sql/2026-08-lama-*.sql` y cualquier `.sql` nuevo de Lama.
- Las tablas de Lama: `mesas`, `cuentas`, `cuenta_items`, `comandas`.
- En `index.html`, **solo** lo que está dentro de la vista `view-lama` y las
  funciones que empiezan por `lama`.
- `pruebas/lama-*.mjs`.
- Esta sección del archivo madre, para anotar lo que se aprenda.

### Los cuatro puntos donde Lama TOCA la app de Stock, y por qué no cuentan

Estos ya están escritos y **no se vuelven a modificar**:

| Dónde | Qué hace | Por qué es seguro |
|---|---|---|
| la pestaña `tabLama` | un botón más en la barra | nace `display:none` |
| `TITULOS.lama` | el subtítulo | una entrada en un mapa |
| `pickTab` / `pickSede` | muestra y esconde `view-lama` | una línea cada uno, junto a las demás |
| `permisosDeLaSede` | lee `puede_lama` | un campo más, `false` si no existe |

Si Lama necesitara **otro** enganche en Stock, eso **se pregunta primero**.
No se agrega y se avisa después.

### Las conexiones entre Stock y Lama van AL FINAL

> Jhon: *"las conexiones no las vamos a hacer hasta que el proyecto esté
> totalmente acabado."*

Lo más tentador es lo primero que hay que NO hacer: **que cerrar una mesa
descuente el inventario.** Es la razón de fondo del proyecto entero y aun así
va al final, después de que las comandas sean confiables. Hoy Lama **no toca
el stock**, y eso es lo que permite abrir y cerrar mesas veinte veces
mientras se prueba, sin descuadrar nada.

Lo mismo vale para: escribirle a Fudo desde Lama, leer recetas, y cualquier
otra cosa que cruce las dos mitades.

---

## 1. Qué es esto y para quién

> **El proyecto tiene DOS mitades desde el 2026-08-27.** Esta sección describe
> la primera, **Llamita Stock** — el inventario, terminado y en producción. La
> segunda es **Llamita Lama**, el área de ventas, en construcción y escondida:
> está en **§12**, y mientras se construya rige **§0.9** (Stock no se toca).

Sistema de **inventario multi-sede** para una cadena de cafés ("Café del Desierto"),
integrado con el POS **Fudo**. Lo usa el personal del café (no técnicos): jefas de
local, baristas, jefatura. Debe sentirse tan simple y confiable como para que
**reemplace las planillas de Excel** que usaban antes. Si el equipo no confía en
él, vuelven al Excel — esa es la vara.

**Objetivo final:** que cada venta en Fudo descuente automáticamente los insumos
del inventario, sin que nadie tenga que anotar nada a mano, y que jefatura vea el
stock real de las 3 sedes en tiempo real desde el teléfono.

**Sedes actuales:**
- `plaza` — Café Mall Plaza
- `angamos` — Parque Angamos
- `central` — **la bodega. En pantalla dice "Bodega"** (§0.7)
- `bodega` — ⚠️ **la bodega VIEJA.** Sigue en la base con todo su historial pero
  **ya no se ofrece en el portal**. Una fila que diga `bodega` es la vieja.
  Siempre. No se toca (§0.7)

---

## 2. Estética — REGLAS DURAS (no negociables)

La estética es **la de Fudo**: limpia, sobria, funcional. NO inventar estilos nuevos.

- **Color primario:** naranja Fudo `--orange:#DC4405`. **Se reserva para acción y
  alerta** (botón +, urgentes, activos). Las cabeceras de sección van en **azul
  pizarra `--sec-bg:#2F4A6D`**: en naranja competían con las alertas reales y
  todo se leía como urgente.
- **Fondo oscuro / topbar:** navy `--navy:#0F1E31`.
- **Paleta completa** (ya definida en `:root` de `index.html`, NO cambiar sin permiso):
  - Naranja: `#DC4405` / `#B93A04`
  - Navy: `#0F1E31` / `#16283F`
  - Rojo (crítico): `#C0392B` sobre `#FDECEA`
  - Verde (ok): `#2E7D32` sobre `#E6F4E6`
  - Ámbar (aviso): `#B26A00` sobre `#FFF3E0`
  - Grises: texto `#1C2733`, muted `#6B7684`, borde `#E3E5E8`
- **Formas:** esquinas redondeadas (`border-radius` 10–12px en tarjetas, 999px en
  píldoras/botones), sombras muy suaves. Nada de bordes duros ni colores fuera de paleta.

### 2.0 REGLA DURA — que sea bella, no solo que funcione

> Jhon, 2026-07-27: "necesito que no solo sea funcional, sino estéticamente
> bella para que incentive su uso."

- **La estética no es un extra que se agrega al final: es parte del encargo.**
  Una pantalla correcta pero fea la gente la usa a regañadientes y termina
  volviendo al Excel — esa es la vara del proyecto (sección 1). Entregar algo
  "que ya funciona" con la intención de embellecerlo después es entregarlo a
  medias.
- **Toda acción que cambia lo que se ve en pantalla lleva su transición.**
  Nada aparece o desaparece de golpe. Duraciones cortas (0,15–0,3 s) y curvas
  suaves; si se nota que "hay una animación", está de más.
- **La animación tiene que salir de donde ocurrió el gesto.** Al tocar una
  píldora de tipo, la lista brota *desde esa píldora* (`brotarDesde()` fija el
  `transform-origin` en la posición real del botón). Una animación centrada en
  la pantalla se siente desconectada de lo que uno tocó.
- **El desenfoque de fondo es del proyecto** (`.overlay` lleva `backdrop-filter`).
  Cualquier ventana nueva lo lleva; ninguna vuelve al negro plano del navegador.
- **El botón responde al dedo.** Un `:active` que encoge un poco (`scale(.94)`)
  hace que el toque se sienta; sin eso la pantalla parece trabada en el mesón.
- **Siempre respetar `prefers-reduced-motion: reduce`**: con eso activado, las
  animaciones se apagan y la app sigue funcionando igual.
- Esto NO contradice el texto mínimo (2.1): se cuida la forma, el movimiento y
  el color — no se agregan palabras.

### 2.1 Regla del texto mínimo (la que más se me olvida)

> **Si hay que explicarlo con un párrafo, es que la forma o el símbolo no está
> bien resuelto.** Jhon NO quiere textos explicativos en la interfaz.

- **Prohibido:** párrafos que expliquen cómo funciona algo ("cuando se venda un
  producto en Fudo se descuenta…"). Eso va en la documentación, no en la app.
- **Permitido:** etiquetas cortas de campo, nombres de botón claros, y
  **feedback transitorio** ("✓ 12 productos sincronizados", "Actualizando…").
- Un botón bien nombrado + un ícono valen más que dos frases. Cuando dudes,
  quita texto, no lo agregues.
- El ícono de la app es el logo de Jhon (llama en perfil dentro de un anillo de
  partículas azul/vino). **Nunca redibujarlo por código** — solo usar el archivo
  que él entrega y redimensionarlo.

### 2.2 REGLA DURA — todo se tiene que poder APAGAR sin romper nada

> Jhon, 2026-08-15: *"quiero que esta sea una opción que se pueda deshabilitar
> en el área de ajustes… la gran mayoría de cosas deben poder deshabilitarse sin
> romper nada."*

**Toda función nueva nace con interruptor.** No es una mejora que se agrega
después: es parte de construirla, igual que la estética (§2.0).

**Y "apagar" significa volver al comportamiento anterior, no dejar un hueco.**
Es la mitad que se olvida. El ejemplo que lo dice todo, y es el suyo: si se
apaga "las tortas piden fecha", una torta tiene que poder recibir **cantidad a
secas**, como cualquier producto. Si al apagarlo quedara sin campo de fecha y
sin campo de cantidad, no está apagado: está roto.

Entonces, para cada interruptor:

| | |
|---|---|
| Encendido | lo nuevo |
| Apagado | **exactamente** lo que había antes, funcionando |
| A medio camino | no existe — si un producto ya tiene fechas cargadas y se apaga la opción, esas fechas **no se borran**; dejan de pedirse |

**Por qué esto vale una regla dura y no una preferencia:** un interruptor es lo
que convierte "hay que llamar a Claude" en "lo apago y sigo trabajando". Es la
misma razón por la que el `prueba`/`real` entra al panel (§6.2): *"necesito
entregar un sistema que sea completamente manejable"*. Una función sin
interruptor le agrega una dependencia de mí a un sistema que tiene que poder
funcionar sin mí.

**El patrón ya existe y es `FLAGS`** (§6.2): hoy se enciende cambiando una línea
del código, y el día que exista el panel pasa a ser un botón. Lo que NO se hace
es dejar la función comentada o en una rama — eso no es un interruptor, es un
borrador.

**La excepción, y son pocas:** los candados que protegen datos no se apagan
—el tope en cero (§0.2), que un perecedero entre por fechas (§0.4), que el
reparto no descuente dos veces—. Ahí el "apagado" sería corromper el
inventario, no volver al estado anterior.

---

## 2.3 LA IMPRESORA — lo medido, para cuando se construya Llamita Lama

> Datos del 2026-08-26, sacados de la propia pantalla de configuración de
> Fudo y del cable de verdad. **No son suposiciones: es lo que se ve.**
> Esta sección existe para que el chat que construya el área de ventas no
> vuelva a averiguar lo que ya se sabe.

### El hallazgo que decide la arquitectura

**La impresora está conectada al computador por USB.** Jhon lo comprobó
mirando los cables: hay dos, corriente y PC. No hay cable de red.

**Consecuencia dura: el navegador NO le puede hablar directo.** Una página web
no puede abrir un puerto USB. Entonces hace falta un programa chico corriendo
en ese computador que reciba por red local e imprima.

**Y eso no es un rodeo nuestro: es exactamente lo que hace Fudo.** Su pantalla
de configuración pide instalar DOS cosas antes de imprimir:

| | |
|---|---|
| Una **extensión de Chrome** | *"permite que el navegador pueda encontrar impresoras conectadas"* |
| Una **aplicación de Windows** | *"permite que Fudo acceda a las impresoras conectadas"* |

Esto **corrige** lo que decía §7, que daba por hecho que Fudo no instala nada
en el computador del local. Sí instala. Lo que corre 100% en el navegador es
la parte de vender; imprimir necesita el puente.

### Lo que ya está resuelto y no hay que volver a hacer

- **La impresora está instalada y funcionando.** No hay que configurarla, ni
  averiguar su IP, ni el truco del FEED al encender.
- **Habla ESC/POS**, que es el estándar que el propio Fudo exige. Nuestro
  código le hablaría el mismo idioma.
- Modelo: **Xprinter XP-N160II**, térmica de 80 mm.

### Marcas que Fudo desaconseja, y por qué importa

**DINON** y **OCOM** — por *"problemas de compatibilidad, cortes erróneos y
fallas en la impresión de comandas"*. Vale anotarlo porque el día que haya que
comprar una impresora para otro local, esa lista es experiencia ajena gratis.
Las recomendadas: EPSON TM-T20 II/III, EPSON TM-T88, Bixolon SRP 350,
3nStar RPT0008.

### Y una que ahorra un problema legal, para Chile

Para **boletas con código PDF417** —el formato chileno— Fudo solo lista
**EPSON TM-T20 II/III** y **3nStar RPT0008**. No toda térmica sirve para eso.
Igual §7 ya dice que la boleta sale por Mercado Pago y esa línea no se cruza,
así que hoy no aplica; se anota por si algún día cambia.

### El orden de trabajo cuando se construya

**El puente de impresión va PRIMERO y AISLADO**, sin tocar la app ni la base.
Es la lección de §0.5 aplicada antes de escribir: si falla, que falle solo, y
que se sepa en dos días en vez de en dos meses. Es una pieza chica —recibe
texto por red local e imprime— y no tiene por qué saber nada de inventario.

---

## 3. Arquitectura (cómo está montado)

| Pieza | Dónde vive | Cómo se despliega |
|-------|-----------|-------------------|
| **App** (`index.html`) | Una sola página, HTML+JS puro, sin build | **Vercel**, publica la rama **`master`** |
| **PWA** (`manifest.json`, `sw.js`, `icons/`) | raíz del repo | con `master` en Vercel |
| **Base de datos** | Supabase (PostgreSQL + Auth + RLS) | SQL corrido a mano desde el panel |
| **Edge Functions** | `supabase/functions/*` | **manual**: copiar/pegar en el panel de Supabase y "Deploy" |

**Puntos que SIEMPRE me olvido:**
1. **Vercel publica `master`, no la rama de trabajo.** Si el cambio no llega al
   teléfono, casi siempre es porque quedó en la rama de feature sin fusionar a `master`.
2. **Las Edge Functions NO se despliegan desde git.** Editar el `.ts` en el repo no
   basta: hay que pegar el código en Supabase → Edge Functions → Deploy. Siempre
   entregarle a Jhon el código completo para pegar.
3. **El service worker no cachea** (pasa todo a la red) — así la app nunca queda
   pegada en una versión vieja. Los datos viven en Supabase, no en el dispositivo.
4. **iOS cachea el ícono** al momento de "Agregar a pantalla de inicio". Para ver un
   ícono nuevo hay que borrar el acceso directo y volver a agregarlo.
5. **El editor SQL de Supabase es el límite real, no Postgres.** Un script
   puede ser perfectamente válido y aun así el panel responde
   **"No se pudo obtener"** (`Failed to fetch`) sin llegar a ejecutarlo. Pasó
   dos veces: con `2026-07-stock-para-fudo.sql` (hubo que partirlo en `-CORTO`
   y `-COMPROBAR`) y con el bloque 0 del chequeo de salud el 2026-07-30. Las
   dos causas conocidas:
   - **Comillas de dólar** (`$$`, `$q$`) — confunden al separador de sentencias
     del editor. En SQL dinámico son casi inevitables; entonces ese script hay
     que entregarlo corto, o reescribirlo sin SQL dinámico.
   - **Largo**: por encima de ~5.000 caracteres en UNA sola sentencia empieza
     a fallar. Sentencias cortas encadenadas aguantan más que una larga.

   Cómo se reconoce: **el error nombra la API de Supabase, no habla de sintaxis
   ni de tablas.** Si dijera "relation does not exist" sería SQL; si dice "no
   se pudo obtener", es el editor. No hay que rediagnosticar el SQL.

   Entonces: **todo script que se le entregue a Jhon va corto y sin `$$`**, y
   si no hay más remedio, se entrega ya partido en dos con las dos mitades
   listas para pegar — no se le pide a él que lo parta.

   **⚠️ Y una regla de PRUEBAS que salió de un bug real (2026-08-06):
   si hay dos caminos a la misma pantalla, se prueban LOS DOS.**

   La portada de Recetas se abre de dos formas: el botón grande y tocar una
   barra de sección. Una función (`nombreCola`) quedó **usada pero sin
   definir**, y solo se ejecuta al entrar por la barra. Resultado: la pantalla
   quedaba **en blanco** — un `ReferenceError` en pleno pintado — y las 22
   comprobaciones seguían en verde, porque todas entraban por el botón.

   Es la falla silenciosa de siempre en versión chica: no se cayó nada, solo
   apareció vacío. Y lo encontró Jhon usándolo, no las pruebas.

   La comprobación que faltaba ahora existe y es de una línea: **entrar por la
   barra y verificar que el contenedor no quedó vacío**, más que no haya
   ningún error de JavaScript en la sesión. Ese segundo chequeo es el que
   convierte un `ReferenceError` mudo en una prueba roja.

   **Y una tercera, del 2026-08-05: no crear una tabla y usarla en el mismo
   Run.** Un bloque que hacía `create table` y después `insert ... join` sobre
   ella respondió `relation "..." does not exist`. Si de verdad hace falta una
   tabla de apoyo, va en un paso aparte; casi siempre se puede evitar con un
   `with ... as (values ...)` o con la condición escrita directo.

6. **Jhon NO trabaja con una copia del repositorio en su computador.** Trabaja
   en el panel de Supabase, en Notion y en el teléfono. Entonces: **nunca
   entregar una instrucción que suponga `git`, una terminal o una carpeta
   local** ("guarda el archivo en `respaldos/`" fue un consejo mal calibrado el
   2026-07-30, y por eso no encontraba la carpeta). Lo que él tiene que hacer
   siempre tiene que ser: copiar un texto, pegarlo en Supabase, apretar Run, y
   guardar el resultado donde ya guarda las cosas. Si algo hay que dejarlo en
   el repo, lo hace Claude en un commit — no él.

---

## 4. Cómo funciona el motor de inventario

1. **Catálogo de productos de Fudo** → tabla `fudo_productos` (una copia local).
   Se actualiza con la Edge Function `fudo-sync-productos`. **No es en tiempo real:**
   si crean un producto nuevo en Fudo, hay que correr esta sync para que aparezca.
   En la app: va incluido en el botón ⟳ de la barra (paso `productos`).
2. **Recetas** (`recetas` + `receta_items`): cada producto de Fudo se asocia a los
   insumos del inventario que descuenta por unidad vendida.
   - Campo **`aplica`** en cada insumo: `siempre` / `llevar` / `servir`. Permite que
     un insumo se descuente solo si la venta fue "para llevar" o "servir en local"
     (ej.: el vaso desechable solo aplica en "llevar").
3. **Ventas** → Edge Function `fudo-sync-ventas` lee las ventas CERRADAS de Fudo y
   pasa cada ítem por el motor SQL `fudo_procesar_item()`, que descuenta el stock
   según la receta y el `saleType` (EAT-IN / TAKEAWAY / DELIVERY).
   - **Idempotente:** aunque relea una venta, nunca descuenta dos veces (buffer de 2h
     + `ON CONFLICT`).
   - Respeta el **modo** de cada sede (`fudo_sync.modo`): `prueba` (solo registra,
     no toca stock) o `real` (descuenta de verdad).
   - En la app: **un solo botón ⟳** en la barra superior, que corre todos los pasos
     de `PASOS_SYNC` (catálogo + ventas) y relee la pantalla.
4. **Casos especiales** resueltos en `emparejador-segunda-pasada.sql`:
   - Bebidas de barra / pulpas / tés de hoja → NO descuentan (no cuantificables).
   - Combo "Llamita KIDS" → descuenta 3 ítems fijos (selladito + mini muffin + juguete).

---

## 5. Flujo de trabajo con git (para Claude)

- Rama de trabajo: `claude/inventory-permission-issue-520xhr` (desarrollar aquí).
- Para que un cambio llegue a producción: **fusionar a `master` y push** (Vercel despliega).
- Mensajes de commit claros, en español, describiendo el porqué.
- Nunca push a `master` sin que el cambio esté probado/confirmado.

---

## 6. Estado actual y pendientes

### 6.0 DÓNDE QUEDAMOS EN STOCK — al 2026-08-10

> ⚠️ **Esto es el estado de Llamita STOCK.** El de Llamita Lama está en §12.

> **Se está construyendo la BODEGA (`central`).** El plan de fondo está en
> `docs/plan-bodega.html`, pero **la etapa 3 de ese documento quedó al revés**:
> el descuento va al aceptar, no al enviar (§0.7). Las reglas duras de esta
> etapa también están en §0.7 y se leen antes de tocar nada.

**El orden de trabajo acordado con Jhon**, y el estado:

| | Qué | Estado |
|---|---|---|
| a | Catálogo maestro de insumos | 🔵 **Es trabajo humano.** 234 productos, **todos en 0**. Adriana está contando. Todo lo real depende de esto |
| b | Tarjetas de crítico por sede | ✅ hecho |
| d | **Mermas** | ✅ hecho · SQL corrido y probado de punta a punta |
| — | Los gemelos (`producto_enlace`) | ✅ **290 escritos** · 144 con Angamos, 146 con Plaza |
| — | **Enlaces** (la pantalla) | ✅ hecha · emparejar y crear productos en las sedes, sin SQL |
| — | **Los ID, cerrados** | ✅ bodega copió los dos catálogos · Plaza 219/219 · Angamos 222/222 |
| f | **Reparto desde bodega** (armar) | ✅ hecho · escribe lo mismo que el local, así que el jefe lo recibe igual |
| c | El descuento en bodega al aceptar | ⬜ **lo siguiente** · la columna ya está, falta `reparto_recibir()` |
| f | Relleno automático | ⬜ usa el crítico, que ya está |
| e | Aviso de reparto en Angamos | ⬜ lo único fuera de `central` |
| g | Seguridad y usuarios nuevos | ⬜ al final, por decisión suya |

**Lo que ya corrió en la base:** los cimientos (`unidad`, `producto_enlace`,
`movimientos`), la bodega nueva, y las mermas (`mermar` + `deshacer_merma`).
**`central` ya tiene foto en `historial`** — se cumple §0.6.

**Pendientes del encargo que todavía no están, anotados para que no se
pierdan:** llenar la unidad de medida por producto, las estadísticas de bodega
leídas del libro de movimientos, y crear/desactivar productos en Fudo desde
bodega (medido en §8, decidido que vive acá).

**Dos cosas de método que salieron caras esta semana y valen para cualquier
sesión:**

1. **El editor de Supabase muestra solo el resultado de la ÚLTIMA consulta.**
   Un bloque con dos `select` entrega uno solo y el otro se pierde en silencio.
   **Un resultado por Run.**
2. **Un nombre repetido en `index.html` mata la app entera.** Declarar un
   `const` que ya existía dejó el archivo sin ejecutar: la pantalla se dibujaba
   igual y no hacía nada, y las pruebas de pantalla pasaban en verde porque
   miraban el HTML y no el guion. Ahora `pruebas/pantalla-sana.mjs` intenta
   leer el guion y lo atrapa.

---

### 6.0.1 Lo anterior — al 2026-08-05, fin del día

> Esto es lo que un chat nuevo necesita saber antes que nada. **Actualizar
> esta sección cada vez que se cierre una etapa**, y borrar lo que ya no
> aplique — si envejece, engaña.

## ✅ ANGAMOS QUEDÓ ENCENDIDA (2026-08-05)

**Lo que está hecho y no hay que volver a hacer:**

| | |
|---|---|
| Credenciales de Fudo Angamos | ✅ secrets creados, la conexión anda |
| Catálogo de Fudo | ✅ ~670 productos, 437 activos |
| Modo | ✅ **`real`** por decisión de Jhon (§9.5) |
| Inventario | ✅ 189 productos · los 14 duplicados de Congelador apagados |
| **Recetas** | ✅ **de 1 a ~85 en una tarde** (§9.7) |
| Cron | ❌ **apagado a propósito** — se enciende cuando la sede se empiece a usar (§9.1 fase 5) |
| Empuje de stock a Fudo | ❌ **no se enciende** — primero descontar, y solo cuando eso sea confiable (§9.2) |

**Lo que queda pendiente y NO es mío:**
- **El conteo.** Todo Angamos está en 0 salvo Pizza Capresse Azapa. Lo hace el
  personal de la sede. Guía de capacitación en `docs/guia-angamos.html`.
- **Los ~40 combos.** Los ve administración. **Atajo que ya se sabe:** Jhon ya
  los armó a mano en Mall Plaza, así que esas recetas son el molde (§9.7).
- **Productos que faltan crear:** `Sandwich Selladito` (5 recetas de Plaza
  dependen de él), `Miel`, `Agua Bosqua sin gas`, Fanta, Pepsi.
- **Preguntas de carta sin contestar:** si `Croissant Jamón Queso` es el
  `Sandwich Jamón Queso`, qué es exactamente `Cocacola mini sprite`, cuál de
  los tres galletones es `Galleton Vainilla Chips`, y si `matilda` (id 677) y
  `Manjar Bolsa` (id 773) se venden solos.

**Lo único que falta comprobar de verdad:** que una venta real en el Fudo de
Angamos descuente. En Plaza se probó con una pizza y es la única prueba que
vale. No bloquea nada porque la sede todavía no se usa.

**Lo siguiente, y ya está decidido (2026-08-05):**

1. **Rediseñar Recetas** → §6.3, con la propuesta aprobada y las decisiones
   tomadas. Es la primera pieza de lo que viene.
2. **La zona de configuración** → §6.2. Es una etapa completa, no una pantalla.

**Bugs y estética de esa misma tanda — cerrados el 2026-08-05:**
fechas duplicadas (era una carrera entre lecturas, no un problema de datos),
la sede siempre visible bajo el título, e Historial mudado al menú ☰.
**Fusionados a `master` con permiso de Jhon.**

**Y uno que quedó pendiente de su lado:** renombrar `Macarrons Vitrina de
dulces` (id 85) a `Macarrons Vitrina`, para que sume con el del Congelador.
`base_nombre()` sabe quitar ` Vitrina` y ` Congelador`, pero no
` Vitrina de dulces` — por eso los nombres base no calzaban y Adriana veía 6 en
vez de 30. Costó un sobre-stock que hubo que devolver.
El resto de los pares del Congelador **Jhon los revisó y NO hay que enlazarlos**:
son productos distintos.

---

**Antes de Angamos: el plan de estabilidad, cerrado.** Jhon pidió ir de a una y
con paso a paso, porque no es técnico. El estado:

| Etapa | Qué es | Estado |
|---|---|---|
| 1 | Correr el chequeo de salud | ✅ **hecho el 2026-07-30** — resultados abajo |
| 2 | Sacar el primer respaldo y guardarlo en Notion | ✅ hecho el 2026-07-30 — los 4 CSV quedaron guardados |
| 3 | Fijar `supabase-js` | ✅ hecho y en producción (2.111.0) |
| 4 | Cuaderno de migraciones (`migraciones_aplicadas`) | ✅ hecho el 2026-07-31 — 13 archivos anotados |
| 5 | Que la alarma del motor suene por proporción | ✅ hecho el 2026-07-31 — `juzgarVentas()` + prueba guardada |
| 6 | Estado del motor en la BASE (no solo en el botón ⟳) | ✅ hecho el 2026-07-31 — falta que Jhon corra el SQL y pegue la Edge Function |
| 7 | Encender el cron | ✅ **hecho el 2026-07-31 19:00** — corrió solo, `la_disparo = cron`, y el sensor quedó encendido |

**✅ EL PLAN DE ESTABILIDAD ESTÁ COMPLETO.** Mall Plaza quedó con: chequeo
mensual, respaldo probado, librería fija, cuaderno de migraciones, alarma por
proporción, estado del motor en la base, y sincronización automática cada 15
minutos vigilada.

**Cómo quedó el cron (2026-07-31):** agendado `*/15 * * * *` con el nombre
`sync-ventas-plaza`; primera corrida automática a las 19:00:05 con
`ultima_corrida_por = 'cron'`, 92 ítems, 0 errores; `cron_activo = true`.
El botón ⟳ sigue existiendo — pasó de ser la única forma de sincronizar a ser
el "actualiza ahora mismo".

**Decisión de Jhon (2026-07-31): la estabilidad primero, Angamos después.**
*"Quiero que el modelo sea bastante sólido antes de pasar a Angamos."*

**Primera corrida del chequeo (2026-07-30) — el estado REAL de Mall Plaza:**

| Qué | Resultado |
|---|---|
| Motor de descuento | **impecable: 845 aplicadas de 845 con receta**, modo `real`. Cero fallas en 7 días |
| Ítems vendidos sin receta | 840 — es cobertura que falta, no una falla |
| Cobertura de recetas | **48% en plaza** (168 recetas sobre 608 productos de Fudo) |
| Funciones duplicadas | ninguna |
| Stock vs. fechas | cuadra · sin negativos · sin fechas en cero |
| `producto_lotes` en tiempo real | **estaba SIN publicar** → arreglado ese día (ver abajo) |
| Recetas rotas | 2. **`Dona Pistacho Dubai` la arregló Jhon a mano desde la app** el 31-07 (le puso el producto correcto). **`Muffin Amapola` se mantiene por decisión de Jhon**: él borró el insumo pero quiere conservar el producto, así que esa receta sigue apuntando al vacío a propósito — el chequeo la va a seguir mostrando, y eso es esperado, no una falla |
| `historial_dias` | instalada, una sola firma → el historial está bien |
| Días guardados | 9 |

**Productos activos por sede** (importante para §9): `plaza 233 · angamos 187 ·
bodega 182`. **Angamos ya tiene sus 187 productos cargados, pero CERO recetas**
— confirma lo que dice §9.1: las recetas hay que hacerlas de nuevo.

**El hallazgo que justificó el chequeo entero:** `producto_lotes` no estaba en
`supabase_realtime`, pese a que la bitácora del 27 de julio y el catálogo §8 lo
daban por resuelto. **El `.sql` estaba en el repo y nunca se había corrido en
producción** — la regla 0.1.2, encontrada por el chequeo en vez de por un susto
en el mesón. Arreglado el 2026-07-30.

**Lo que se cerró el 2026-07-30:**
- Informe de estabilidad completo (§6 reordenada por si la falla avisa o no).
- Chequeo de salud (`sql/2026-07-salud-del-sistema.sql`) — correr **solo el
  bloque 0**, que da las 10 filas de resumen.
- Respaldo (`sql/2026-07-respaldo-para-guardar.sql`) — probado restaurando.
- Catálogo de soluciones (§8) y regla 0.1.8 (el hallazgo que no existía).
- Decisión: seguridad en mínimos (§6.1). No se vuelve a proponer.

**Lo siguiente que pidió Jhon:** llevar el sistema a **Parque Angamos** → §9.

**Cómo entregarle algo a Jhon** (§3.5 y §3.6): un texto corto para copiar y
pegar en Supabase, sin `$$`, y si es largo ya partido en dos. Nada que suponga
git, terminal ni carpeta local.

**Funcionando:**
- App instalable (PWA) con ícono real de Jhon.
- Inventario por sede, secciones, métricas (crítico / en rango / sin dato), buscador
  siempre visible que ignora los filtros.
- Recetas con buscador (no desplegables gigantes) y campo `aplica`.
- Un solo botón ⟳ que sincroniza catálogo + ventas y descuenta el stock.
- Probado en cafetería real (venta de pizza en Fudo → se descontó en la app).

**Pendiente — ordenado por CÓMO SE ANUNCIA LA FALLA, no por lo grave que suena.**

Esto sale de la regla 0.5: *un sistema que falla en silencio es peor que uno
que se cae*. El bloque **A son las fallas calladas** —la app sigue diciendo "✓"
mientras el daño se acumula— y por eso van primero aunque algunas suenen
menores. El **B son fallas ruidosas**: molestan y bloquean, pero se ven y nadie
toma una decisión equivocada por culpa de ellas. **C** son datos por corregir,
**D** velocidad y estructura, **E** mejoras. De la C en adelante es trabajo, no
riesgo.

> **Antes de tocar nada, correr `sql/2026-07-salud-del-sistema.sql`** (solo
> lectura, 10 bloques). Contesta con datos casi todo lo que acá está marcado
> como "por verificar": a cuánto está cada tabla del tope de las 1000 filas,
> si hay funciones duplicadas, si el motor descontó algo esta semana, si el
> stock cuadra con las fechas, qué recetas apuntan al vacío. Se corre una vez
> al mes y SIEMPRE antes y después de instalar un motor o un cálculo nuevo.

### 🔴 A. Fallas calladas — la app no avisa, el daño se acumula

- [x] ~~**Las recetas cruzadas.**~~ **NO EXISTÍAN.** Ver 0.1.8 — las dos
      estaban bien y el error era del análisis, no de los datos.
- [ ] **El tope de 1000 filas, en quince lecturas.** Supabase corta cualquier
      respuesta en 1000 filas **y no avisa**: la app pide 1400, recibe 1000 y
      sigue como si tuviera todo. En `index.html` hay 19 `.select()` y solo 4
      con `.limit()`. Ya costó una vez (el historial mostrando días viejos,
      2026-07-27). La que va a cruzar primero es **`receta_items`**, que crece
      con cada receta por sus insumos — justo lo que la depuración empuja hacia
      arriba; el día que pase de 1000, la pantalla de Recetas muestra recetas
      incompletas y nadie tiene motivo para sospechar. El bloque 1 del chequeo
      dice a cuánto está cada tabla. **Regla general: cualquier `select` que
      pueda devolver más de 1000 filas está truncado sin avisar** — si lo que
      se necesita es un resumen, se agrupa en la base.
- [x] ~~**La alarma del motor solo suena si falla el 100% de las ventas.**~~
      **Hecho el 2026-07-31**: `juzgarVentas()` en `index.html` mide por
      proporción — 10% de los ítems fallando ya abre la ventana. Con prueba
      guardada en `pruebas/alarma-de-ventas.mjs`, que cubre las dos
      direcciones: que suene cuando debe **y que no suene cuando no** (el caso
      real de 1685 ítems sin errores, y el de releer ventas ya procesadas, que
      da 0 movimientos y es normal).
- [x] ~~**El estado del motor tiene que vivir en la BASE.**~~ **Hecho el
      2026-07-31.** `fudo_sync` ganó 7 columnas (`ultima_corrida_at`,
      `ultimo_resultado`, `ultimos_items/errores/movimientos`,
      `ultima_corrida_por`, `cron_activo`); `fudo-sync-ventas` las escribe en
      cada corrida; y la app muestra una franja bajo las pestañas
      (`juzgarMotor()` + `#motorAviso`) solo cuando hay algo que decir.
      **Dos reglas anti-falsa-alarma, con prueba:** la corrida vieja solo
      alarma si `cron_activo` está en true —sin cron, "hace 5 horas" es
      normal—, y una sede que nunca corrió no es una sede rota, es una recién
      encendida (el caso Angamos).
      **Con esto el cron queda desbloqueado**: encenderlo es correr
      `2026-07-cron-automatico-ventas.sql` y poner `cron_activo = true`.
- [ ] **Respaldos de la base.** Revisar en Supabase → Settings → Database →
      Backups. En el plan gratuito **no hay punto de restauración**. Y el modo
      de trabajo del proyecto es copiar `update` generados y pegarlos a mano:
      un `where` que se quedó fuera al copiar cambia 200 nombres de una vez y
      no hay marcha atrás. **Es el único riesgo de la lista que no se puede
      reparar después de que ocurra.** Plan Pro (~25 USD/mes) trae respaldo
      diario; mientras tanto, exportar `productos`, `recetas` y `receta_items`
      a CSV antes de cada tanda de renombres.
- [ ] **`supabase-js` sin versión fija.** `index.html:15` carga
      `@supabase/supabase-js@2`, o sea **la última 2.x que publiquen**. Un
      cambio de la librería puede romper la app sin que nadie toque el código
      — la misma clase de sorpresa que el motor v5, pero desde afuera y sin un
      commit al cual mirar. Al 2026-07-27 la última era **2.110.9**, la que
      corre hoy; fijarla ahí no cambia nada. **Antes de cambiarla, comprobar
      que la URL fijada de verdad sirve la librería** (abrirla en el navegador):
      si se escribe mal, la app deja de cargar entera.
- [ ] **Registro de lo que se aplicó de verdad.** Hay 40 archivos en `sql/` y
      ninguna forma de saber cuáles se corrieron; 5 Edge Functions y ninguna
      forma de saber qué versión está desplegada. La regla 0.1.2 ya dice
      "consultarlo con un SELECT", y funciona — pero **depende de que alguien
      se acuerde**, que es exactamente lo que falló en julio. Mismo criterio
      que el stock negativo: ahí la solución no fue acordarse, fue un `CHECK`
      en la base. Acá el equivalente son dos cosas chicas:
      (a) tabla `migraciones_aplicadas` (archivo, fecha, quién, nota) y una
      línea al final de cada script que se registre sola;
      (b) que cada Edge Function devuelva su versión en la respuesta, para
      poder ver qué está vivo sin entrar al panel.
- [ ] **Pruebas guardadas: empezado el 2026-07-31.** Existe `pruebas/` con la
      primera (`alarma-de-ventas.mjs`, 9 casos, corre con `node` y sin
      dependencias). **La regla que la hace servir: lee el código de verdad**,
      extrayendo la función de `index.html` en vez de copiarla — una prueba
      contra una copia no prueba el código que corre. Falta cubrir la pantalla,
      y eso hay que tenerlo **antes** de partir `index.html` en varias páginas.
- [ ] **El cron, cuando se active.** Si deja de correr, hoy nadie se entera.
      Mismo patrón que todo este bloque.

### 🟠 B. Fallas ruidosas — se ven, molestan, no mienten

- [x] ~~**Revisar quién puede escribir en la base.**~~ **DECIDIDO por Jhon el
      2026-07-30: la seguridad se mantiene en mínimos.** Ver 6.1 — no volver
      a proponerlo.
- [ ] **Las cuentas de administración se desloguean solas** (`session_not_found`:
      el navegador guarda un token bien firmado cuya sesión ya no existe en el
      servidor). **La hipótesis de las cuentas compartidas quedó descartada**:
      Jhon confirmó el 2026-07-30 que los 5 administradores ya tienen cada uno
      su cuenta propia, y que solo la de él estuvo abierta en más de dos
      dispositivos. Así que esto **no es la falla frecuente que yo anticipaba**
      — pasó una vez, en la cuenta con más dispositivos abiertos. Queda
      anotado, no priorizado: si vuelve a pasar, mirar Supabase →
      Authentication → Sessions (límite de sesiones por usuario) y anotar en
      cuántos dispositivos estaba abierta esa cuenta. El aviso "Tu sesión se
      cerró" ya es claro; el arreglo es salir y volver a entrar.

### 🟡 C. Correcciones de datos pendientes

- [ ] **Terminar de emparejar vitrina/congelador.** Van 12 pares sumando
      (2026-07-29). Correr `sql/2026-07-emparejar-vitrina-congelador.sql` de
      nuevo cada tanto: la consulta 3 muestra los del congelador que todavía no
      tienen pareja en vitrina.
- [ ] **Depurar recetas.** Plan en `docs/auditoria-recetas.md`; informe de solo
      lectura en `sql/2026-07-auditoria-recetas.sql`. La métrica de avance es
      el % de cobertura (bloque 9 del chequeo). **Al 2026-07-30 va en 48%** en
      plaza: 168 recetas sobre 608 productos de Fudo, y 840 de 1685 ítems
      vendidos en la semana salieron sin receta.
- [ ] **Terminar de clasificar los tipos**: correr los 3 pasos de
      `sql/2026-07-tipo-de-producto.sql` y ponerle tipo desde la ficha a los que
      queden en "— revisar —".
- [ ] **Las tandas 2 y 3 del empuje a Fudo**: los ~40 combos que hoy no se
      controlan por stock (cambian de comportamiento en el mesón, hay que
      avisar), y los ~10 que quedarían en 0 (revisar receta por receta antes).

### 🔵 D. Velocidad y estructura — no urge, pero se pone caro solo

> Medido el 2026-07-30 en el navegador, inventario sintético, todas las
> secciones abiertas. Con 232 productos la app va bien; el problema es **cómo
> crece**, no el número de hoy.

| Productos | Pintado |
|---|---|
| 10 | 7 ms |
| **232** (tamaño real hoy) | **146 ms** |
| 500 | 168 ms |
| 1000 | 583 ms |

- [ ] **El pintado crece al cuadrado, y la causa está aislada.** En UNA pintada
      de 232 productos la app recorre la lista completa **233 veces**, porque
      `totalProducto()` filtra todo `DATA` una vez por fila para calcular el
      total del par vitrina+congelador. De los 42 ms que toma pintar,
      **28 ms (67%) son eso**. El arreglo es calcular los totales por nombre
      base **una vez por carga** en un índice (un `Map`), no una vez por fila:
      cambio interno, misma pantalla, mismos números, misma regla de que el
      total suma vitrina y congelador.
- [ ] **`.in('producto_id', …)` con 232 identificadores.** Las fechas de
      vencimiento se piden metiendo la lista entera de ids en la dirección
      (`index.html:1497`). Funciona hoy y **falla de golpe** —no de a poco—
      cuando la URL se pasa de largo, en torno al doble o triple del inventario
      actual. Se resuelve pidiendo por sede en vez de por lista de ids.
- [ ] **`index.html` son 3169 líneas / 172 KB en un solo archivo**, con
      inventario, reparto, historial, recetas y zona de administración juntos:
      un barista carga todo el código de administración para mirar el stock.
      La separación por rol ya está prevista en la sección 7 (`/` inventario,
      `/caja`, `/panel`). **No empezar a separar antes de tener pruebas
      guardadas** (bloque A) — partir un archivo de 3000 líneas sin red es
      cómo se introducen bugs invisibles.

### 🟢 E. Mejoras que ya están desbloqueadas

- [x] ~~**Que el cálculo para Fudo use el TOTAL del par vitrina+congelador.**~~
      Hecho el 2026-07-29 (`sql/2026-07-stock-para-fudo-v3-suma-el-par.sql`).
      Al vender se sigue descontando del producto de la receta: lo que cambió
      es solo cuánto se dice que se PUEDE vender.
- [ ] **Cron automático** de `fudo-sync-ventas` cada 15 min. Reescrito el
      2026-07-31: sin `$$`, con la URL y la clave publicable **ya rellenadas**
      (nada que reemplazar a mano), y en **3 pasos con espera en el medio** —
      agendar, comprobar a los 20 min que `ultima_corrida_por` diga `cron`, y
      recién ahí encender `cron_activo`. Ese orden importa: encender el aviso
      antes de que el cron haya corrido pone la app en rojo sin motivo.
      **Ojo con el malentendido**: crear la columna `cron_activo` NO enciende
      nada — es el interruptor, y nace apagado.
- [ ] Correr la medición de demora real (bloque de `sql/2026-07-fecha-real-de-venta.sql`).
- [ ] **Al crear un producto, poder enlazarlo con uno de Fudo.** Hoy se crea
      suelto. No es peligroso —sin receta no puede escribir nada en Fudo— pero
      queda fuera del control y Fudo lo sigue vendiendo sin límite.
- [ ] Marcar "para llevar" vs "servir" en el front de Fudo para que el `aplica` sirva.
- [ ] **Combos de elección libre (ej. "3 masitas").** Sin resolver. Depende de
      si Fudo captura QUÉ eligió el cliente. Ver sección 7 — desaparece solo si
      migran a un POS propio.
- [ ] **Dashboard**: `docs/dashboard-analisis-posibles.md`. NO empezar hasta
      cerrar la depuración de recetas.
- [ ] Confirmar con jefatura que van a usar el sistema (vs. volver al Excel).
- [ ] **Decisión grande pendiente: ¿avanzar hacia un POS propio?** Ver sección 7.

### 6.1 DECISIÓN TOMADA — la seguridad se mantiene en mínimos

> Jhon, 2026-07-30: "al ser esto un inventario para una cafetería, lo mejor es
> que mantengamos la seguridad en mínimos."

Esto **no es un pendiente ni un descuido: es una decisión del dueño del
proyecto**, y por eso está acá arriba y no en la lista de arriba. Aplica la
regla 0.1.7.

- **La app lee y escribe sin sesión iniciada, y así se queda.** La clave
  publicable va en `index.html` y cualquiera la puede ver con F12 — eso es
  normal y no cambia.
- **No proponer cerrar `anon`, ni activar RLS restrictivo, ni pedir login
  obligatorio** para el inventario. Ya se evaluó y se decidió que no. Cerrarlo
  a lo bruto además rompe la app entera, porque hoy funciona sin sesión.
- **La zona de administración es la excepción, y ya está resuelta.** Escribir
  en Fudo sí exige sesión y sí se comprueba contra `app_permisos` **en el
  servidor** (las Edge Functions lo revalidan; esconder el botón es comodidad,
  no seguridad). Eso se mantiene: lo que toca un sistema externo lleva
  candado, lo que toca el inventario interno no.
- Lo que cambiaría esta decisión: que el sistema pase a manejar caja o datos
  de personas. Mientras sea stock de una cafetería, la respuesta es esta.
- `sql/2026-07-revision-seguridad.sql` se mantiene en el repo como diagnóstico
  de solo lectura — sirve para *saber* cómo está, no para cambiarlo.

### 6.2 EL PENDIENTE GRANDE — la zona de configuración

> Jhon, 2026-08-05: *"sería muy difícil que tenga que venir a ti para decir
> 'une estos dos productos por el mismo ID'… esto va a ser MUY grande, vamos a
> necesitar dedicarnos meramente a este apartado."*

**No es una pantalla más: es una etapa completa del proyecto**, y hay que
entrar a ella con tiempo dedicado, no colgarla de otra tarea.

**El diagnóstico que la justifica, y sale de mirar una sesión entera de
trabajo.** El 2026-08-05 pasaron por SQL: apagar 14 duplicados, enlazar los
macarrons, dar un permiso, poner tipos de producto, crear 81 recetas.
**Ninguna es una decisión técnica** — son decisiones del negocio que pasan por
un script solo porque nadie construyó la pantalla.

**El patrón de fondo:** *la app sabe editar productos, pero no sabe editar
relaciones.* Qué producto de Fudo descuenta cuál del inventario. Qué vitrina va
con qué congelador. Quién puede editar qué. Todas las relaciones viven en SQL.
Y el bug de los macarrons pasó **exactamente por eso**: la relación
vitrina/congelador está escondida dentro del nombre del producto, así que un
nombre mal puesto rompe una relación y nadie lo ve.

**LA CONDICIÓN, y no se negocia.** Hoy Claude es el badén: revisa el `where`,
escribe la vista previa, deja el deshacer. Si eso pasa a un botón, el badén
desaparece. Entonces **toda acción destructiva de esa zona lleva las mismas
tres cosas que llevan los scripts: vista previa antes, registro de quién lo
hizo, y deshacer.** Sin eso, la zona de configuración es una forma cómoda de
romper el inventario en silencio — la falla que este proyecto ya pagó cara
(§0.5).

**Qué SÍ va ahí:** enlazar recetas · emparejar vitrina/congelador · usuarios y
permisos · tipos y secciones · marcar un producto como "no lleva receta".

**LO QUE SE ADELANTÓ FUERA DEL PANEL, y hay que integrar cuando exista**
*(pedidos desde el local el 2026-08-06, hechos como parche en `index.html`)*:

| Qué se hizo | Dónde está hoy | Qué falta en el panel |
|---|---|---|
| **Renombrar una sección** | menú ☰ → Secciones | crear, borrar, reordenar y mover productos entre secciones |
| **"Después" se recuerda** (`fudo_pospuestos`) | la portada de Recetas | poder vaciar el montón de una, y ver quién pospuso qué |
| **Tipos de producto en Angamos** | se llenaron por SQL | editar los tipos como lista, no producto por producto |
| **Lista de conteo** | escondida tras `FLAGS` en `index.html` | **el interruptor para encenderla o apagarla por sede** |

**⚠️ PENDIENTE ANOTADO (Jhon, 2026-08-06): productos de BODEGA metidos en
Angamos.** En el inventario de angamos hay productos con la palabra *"bodega"*
en el nombre —`Bodega leche de avena` y similares— que son de la **bodega
central**, no de la sede. Jhon: *"no quiero contaminar Angamos con productos
de bodega, esto es importante… por ahora no hace daño, pero quiero que lo
recuerdes."*

**Por qué importa más de lo que parece:** esos productos cuentan en las
métricas de la sede, aparecen en el buscador de reparto y ensucian los
candidatos del taller de recetas. No rompen nada hoy porque están en cero.
Hay que decidir con él si se mueven a la sede `bodega` o se desactivan — es
una decisión suya, no una limpieza automática (§0).

**`FLAGS` es el patrón para lo que viene:** una función que hoy se enciende
cambiando una línea del código, y que el día que exista el panel pasa a ser un
interruptor. Cualquier función nueva que no esté lista para todos entra por
ahí — no comentada ni en una rama.

**Qué NO va ahí, y sigue siendo de Claude:** el motor de descuento, el esquema
de la base, y el interruptor `prueba`/`real`.

**Por dónde empieza:** por Recetas (§6.3). No es una pantalla aparte de esta
zona — es su primera pieza, y el molde del resto.

**DECISIONES DE JHON sobre el plan (2026-08-05), y mandan sobre lo de arriba:**

| | |
|---|---|
| Por dónde se parte | **Los pares vitrina/congelador.** *"fue un error real que costó dinero"* |
| Quién la usa | **Solo Jhon al principio.** Después se despliega a administración |
| Dónde vive | **Panel aparte, con su propio ícono.** No una ventana emergente |
| El interruptor `prueba`/`real` | **SÍ entra**, contra mi recomendación. Su razón, y es buena: *"existe la posibilidad de que yo un día me vaya y necesito entregar un sistema que sea completamente manejable"* — un sistema que solo Claude puede operar no es entregable |

### 6.4 LO QUE VIENE DESPUÉS — anotado a pedido de Jhon (2026-08-05)

**1. El panel de análisis.** Gráficas y tablero: a dónde se van los recursos,
qué es lo que más sale y lo que menos, y **poder ofertar lo que está en
sobre-stock**. Depende de tener la cobertura de recetas alta — un tablero sobre
datos incompletos miente con autoridad. No empezar antes de cerrar §6.3.
Análisis previo en `docs/dashboard-analisis-posibles.md`.

**2. La planilla del café.** Jhon la pidió así: *"que yo le pusiera los kilos
que tiene y la receta, es decir, los gramos de café que utilizo por cada
espresso, y el mismo calculara el descuento."*

Es §10 convertido en pantalla, y **la base ya lo soporta**: `receta_items.cantidad`
es `numeric` y `productos.stock_actual` es `double precision` (verificado en
producción el 2026-07-31), así que una receta puede descontar `0,018`. Lo que
falta es la columna de **unidad de medida** en `productos` y la pantalla que
haga la división. Dato ya corregido por Jhon: **el bulto es de 30 kg, no 60** —
son ~1.667 dosis, no 3.333.

### ✅ Lo que NO está en riesgo

### 6.3 RECETAS — el rediseño, con las decisiones ya tomadas

Propuesta navegable en `docs/propuesta-recetas.html`. Jhon la revisó el
2026-08-05 y aprobó el diseño. Lo decidido:

**El diagnóstico:** la pantalla muestra las recetas que YA existen, y el
trabajo son las que FALTAN. Por eso se ve vacía teniendo 172 filas — muestra el
lado equivocado del problema.

**El hallazgo que lo hace posible: hacen falta TRES estados, no dos.** Con solo
"con receta" / "sin receta", los 41 combos, los tés, los cafés y los productos
internos quedan en rojo **para siempre** y el contador nunca llega a cero. Una
pantalla que siempre grita se deja de mirar. El tercero es **"no lleva receta"**,
puesto a propósito por una persona.

| Decisión | Qué quedó |
|---|---|
| Dos vistas | **portada** (el puente Fudo→inventario + barras por sección) y **taller** (cola de a un producto) |
| Dónde abre | En la **portada** las primeras semanas, mientras jefatura aprende. Después se cambia al taller |
| Marca NUEVO | Sí, **con animación de color MUY sutil** — el objetivo es que den ganas de explorar, no llamar la atención |
| Agrupación de las barras | **Por NUESTRAS secciones** (`rubro`), no por las categorías de Fudo. *"Los trabajadores están más familiarizados con 'Vitrina de tortas' que con 'tortas'"* |
| Interacción | **Tocar A y después tocar B. NUNCA arrastrar** — arrastrar es lindo con mouse y peleado con el dedo, y serían dos interacciones que mantener |
| Candidatos | Vienen propuestos, ordenados por parecido. **Proponen, no deciden** (regla 0.1.4) |
| Producto que no existe | **Se puede crear ahí mismo**, y pasa a ser **la única forma en que todos pueden crear productos** — creando y enlazando en el mismo gesto |
| Combos | **Fuera de esta pantalla.** El botón actual de crear recetas **se queda donde está y como está**, solo cambia de nombre a **"Crear combos"**. Jhon: *"no debe desaparecer ni cambiar de lugar, ya están muy familiarizados con él"* |
| Sedes | **Las dos**, plaza y angamos |

**El problema que queda abierto, y hay que resolverlo antes de construir:** las
barras se agrupan por nuestras secciones, pero **un producto de Fudo sin receta
todavía no tiene sección nuestra** — la sección vive en el producto del
inventario, que es justo el que falta enlazar. Es un huevo y gallina.
La salida más limpia: **una tabla chica que traduzca cada categoría de Fudo a
una sección nuestra**, llenada una sola vez (Fudo tiene ~15-20 categorías). Así
el agrupamiento sale de un dato que existe desde el principio, y los nombres en
pantalla siguen siendo los que el equipo reconoce.

**Lo que la pantalla NO hace, a propósito:** recetas de varios insumos,
cantidades fraccionarias (los 18 g de café), ni borrar productos. Hacer bien lo
simple primero es lo que ya funcionó: 81 recetas en una tarde porque eran todas
de un insumo.

### ✅ Lo que NO está en riesgo

Vale dejarlo escrito, porque una lista de vulnerabilidades da la impresión de
que todo está frágil, y **una sesión futura que lea solo el bloque A puede
"arreglar" cosas que ya están bien** (ver regla 0.1.7).

- **El stock negativo está cerrado de verdad.** No es lógica del motor que
  alguien pueda olvidar: son restricciones `CHECK` en la tabla. Cualquier
  camino futuro que intente dejar un negativo lo rechaza la base sola.
- **Renombrar productos no rompe recetas.** La unión es por ID, no por nombre.
  Todos los renombres de vitrina/congelador que faltan son seguros.
- **El descuento no se duplica.** Aunque se relea una venta, el buffer de
  tiempo y el `on conflict` lo impiden.
- **Un producto sin receta no puede escribir nada en Fudo.** El cálculo sale
  DESDE `recetas`; crear productos sueltos no corrompe nada — es falta de
  cobertura, no un dato malo.
- **El empuje a Fudo manda valor absoluto y se comprueba releyendo** lo que
  Fudo devuelve, no el 200. Cada envío queda con su valor anterior.
- **Multi-sede ya está resuelto.** Agregar una sede es agregar filas.

---

## 7. Visión de expansión — ¿construir un POS propio?

> Esta sección es la más importante para no perder el hilo si se retoma después de
> un tiempo. Administración vio el inventario funcionando y pidió algo mucho más
> grande: un clon de Fudo hecho a medida para Café del Desierto (mesas, comandas,
> cierre de caja, análisis de ventas). Jhon tiene dudas razonables — esto NO se
> decide solo, es una conversación con administración todavía en curso.

### Postura recomendada (no clonar Fudo entero)

**No construir un clon completo.** Construir la **capa de inteligencia que Fudo no
tiene** — que es justo lo que ya impresionó a administración: inventario real,
recetas, vencimientos, análisis a medida. Eso es el ~80% del valor con una fracción
del riesgo. Fudo se queda con lo aburrido y regulado: vender y cobrar.

Si más adelante SÍ avanzan a un POS propio, la razón de peso no es ahorrar
suscripciones (Supabase+hosting cuesta parecido a Fudo) — es que **se acaba la
fricción de sincronizar contra un sistema externo**. Hoy toda la pelea de recetas
(emparejador, nombres que no calzan, "vendido sin descontar", combos que no capturan
la elección del cliente) existe SOLO porque Fudo y el inventario son sistemas
separados. Si el producto vendido y el insumo descontado viven en la misma base,
esa capa entera desaparece.

### Riesgos que administración debe conocer, y por qué bajaron

Evaluación inicial vs. lo que Jhon confirmó después:

| Riesgo | Evaluación inicial | Lo que se confirmó |
|---|---|---|
| Boleta electrónica / SII | El más serio: certificación, folios, contingencia | **No aplica.** Emiten con Mercado Pago, no con Fudo. Se mantiene igual. |
| Modo sin conexión | Debe seguir vendiendo sin internet | Fudo **ya falla** sin conexión hoy. La vara correcta es "no peor que hoy", no "perfecto". |
| Pagos / bancos | Integración con Transbank, etc. | **No aplica.** Fudo tampoco se integra a bancos; usan Mercado Pago aparte. Discriminar efectivo/débito es manual al cerrar mesa — un campo de formulario, no una integración. |
| Arqueo de caja | Riesgo de descuadre | Jhon conoce el proceso a mano, varianza histórica <$1.000. Replicable. |
| **Impresión a cocina** | Riesgo técnico real | Sigue siendo lo único técnico por validar (ver abajo), pero bajó de riesgo alto a acotado. |

### Hallazgo clave sobre la impresora (confirmado, no solo teoría)

- Modelo real: **Xprinter XP-N160II**, habla **ESC/POS** (estándar de la industria,
  no propietario) y tiene **puerto ethernet además de USB** — mejor que USB porque
  evita drivers de Windows.
- ~~**Fudo no tiene ningún programa instalado en el computador del local.**~~
  **ESTO ESTABA MAL, corregido el 2026-08-26 → ver §2.3.** La propia pantalla
  de configuración de Fudo pide instalar **una extensión de Chrome y una
  aplicación de Windows** para poder imprimir. Se deja tachado y no borrado
  porque el error de método es la parte útil: lo di por hecho desde *"si
  cierro la pestaña deja de imprimir"*, que es cierto **y no prueba** que no
  haya nada instalado. Un síntoma compatible con dos explicaciones no elige
  entre ellas. La respuesta estaba en la pantalla que usa la gente, no en
  razonar sobre el síntoma — igual que con el borrado del catálogo (§8).
  Lo que sí se sostiene: esa pestaña abierta hace falta y no se cierra.
- **Antes de prometer nada de POS**, el primer paso técnico es un **prototipo
  aislado de impresión**: imprimir una comanda de prueba en esa Xprinter, sin
  tocar la app existente. Si falla, se sabe en dos días y no en dos meses.
  **Ya no hace falta averiguar la conexión: es USB, y la impresora ya está
  instalada y funcionando** (§2.3). Lo que hay que construir es el puente.

### Arquitectura si se avanza (la lección de "un cerebro, varias caras")

Jhon notó solo que el Fudo del teléfono del garzón es distinto del Fudo del
computador de caja — misma base de datos, interfaces separadas por rol. Ese es
el patrón a seguir:

- **Mismo Supabase** para todo (mesas, ventas, inventario) — comparten datos y sesión.
- **Páginas separadas**, NO meter todo en `index.html`: `/` inventario (como hoy),
  `/caja` comandas y cierre, más adelante `/panel` análisis para administración.
  Cada rol carga solo lo suyo (el garzón no necesita cargar 225 productos de
  inventario) — esto también resuelve la lentitud que se sintió en el mesón.
- Si el POS falla, el inventario no debe caerse con él, y viceversa.

### Multi-sede y tiendas de apps (ya resuelto, no requiere trabajo extra)

- **Una sola construcción sirve para 2 o para 10 sedes.** Cada fila lleva su `sede`
  (como ya pasa con plaza/angamos/bodega); agregar una sede es agregar una fila, no
  construir otra app. Lo que sí se pone más exigente con más sedes: permisos por
  sede (hoy cualquiera ve/edita cualquier sede) y configuración por sede (impresora,
  horario). El verdadero desafío a esa escala es el **soporte**, no el código.
- **No hace falta publicar en App Store / Play Store.** Es una PWA — ya instalable
  como hoy, actualizaciones instantáneas (sin revisión de Apple), sin pagar cuentas
  de desarrollador, un solo código para todo. Se puede empaquetar para tiendas más
  adelante si administración insiste por imagen, pero no es necesario para operar.
- Jhon estima ~80-90% de probabilidad de que solo sean **2 sedes propias** (las
  demás son franquicias con su propio Fudo). Si eso pasa, el **puente con Fudo que
  ya existe para el inventario seguiría sirviendo** para traer los datos de las
  franquicias al panel consolidado de administración — no se bota ese trabajo.

### Costos (para la conversación con administración)

- Supabase Pro (~25 USD/mes, necesario para respaldos diarios ANTES de manejar
  caja real) + hosting. Vercel gratis es solo para uso personal — mover a
  **Cloudflare Pages** (gratis, permite uso comercial) en vez de pagar Vercel.
  Total realista: **~25-45 USD/mes para 2 o para 6 sedes** (Supabase cobra por
  proyecto, no por sede).
- El argumento correcto para administración NO es "ahorramos vs. Fudo" (el ahorro
  es marginal y durante meses pagarían las dos cosas en paralelo) — es "esto hace
  cosas que Fudo no hace". Si el argumento es solo plata, la respuesta honesta es
  quedarse con Fudo.
- Sobre cobrar por el trabajo: no cobrar pago único (deja a Jhon dando soporte
  gratis para siempre). Estructura sugerida: monto por lo ya entregado (inventario)
  + cuota mensual de mantención. **No cotizar el POS todavía** — falta validar la
  impresión. Aclarar primero si esto se hace en horario de trabajo (entonces es
  ajuste de sueldo/bono, no factura externa) o aparte.

### Próximo paso concreto si se decide avanzar

1. Prototipo de impresión aislado (arriba).
2. Cerrar la depuración de recetas (sirve en los dos escenarios, con o sin POS).
3. Mesas y comandas en paralelo con Fudo, en una sola sede, sin reemplazar nada.
4. Cierre de caja, solo después de que las comandas sean confiables.
5. La boleta sigue saliendo por Mercado Pago — esa línea no se cruza.

---

## 8. Catálogo de soluciones aplicadas

> Jhon pidió esto el 2026-07-30: *"quiero un catálogo de las soluciones que se
> han corregido"*.

**Para qué sirve y en qué se diferencia de la bitácora.** La bitácora (sección
11) cuenta *cómo se llegó* a cada cambio, en orden de tiempo — se lee para
entender por qué algo está hecho así. Este catálogo se lee al revés: **se busca
un problema y se ve si ya está resuelto y dónde**. Es lo primero que hay que
mirar antes de "arreglar" algo, para no volver a resolver lo mismo ni deshacer
una solución que ya está en producción.

**Cómo leer la columna "Dónde vive":** un `.sql` que se corre a mano en
Supabase, un `.ts` que se pega en el panel de Edge Functions, o `index.html`
que sale por Vercel al fusionar a `master`. Recordar la regla 0.1.2: **que el
archivo esté en el repo no significa que esté aplicado en producción.**

### Motor de descuento y puente con Fudo

| Qué fallaba | Cómo se resolvió | Dónde vive | Fecha |
|---|---|---|---|
| Las ventas de Fudo no descontaban nada del inventario | Motor SQL `fudo_procesar_item()` con receta + `saleType`, idempotente | `fudo-sync-ventas` + motor en la base | 2026-07 |
| Ventas que se cerraban horas después de abrir la mesa **no se descontaban nunca** (Fudo filtra por apertura, no por cierre) | Ventana ampliada a 8 h + tope corrido 1 h, y columna `venta_at` para poder medirlo | `2026-07-fecha-real-de-venta.sql` | 07-25 |
| El motor lanzaba excepción en cada venta por una columna que no existía | El script crea sus propias columnas con `add column if not exists` | `2026-07-URGENTE-falta-venta-at.sql` | 07-27 |
| Dos `fudo_procesar_item` conviviendo dejaban la llamada por API ambigua — **15 h sin descontar** | Se borró la firma vieja; desde entonces todo script lleva un `drop` por cada firma posible | `2026-07-URGENTE-dos-motores.sql` | 07-27 |
| Ese fallo era **invisible**: la app decía "✓" igual | Si la sync lee ventas y no descuenta ninguna, se abre una ventana que lo dice | `index.html` (`PASOS_SYNC`, paso `ventas`) | 07-27 |
| El stock quedaba negativo al vender más de lo que había | Tope duro en 0 en el motor **y** restricciones `CHECK` en la tabla | `2026-07-tope-cero-sin-excepcion.sql` | 07-27 |
| ~~Vitrina en 0 con el congelador lleno~~ | ~~Reposición automática de 4 unidades~~ → **APAGADO el 2026-08-01**: movía producto en los números sin que nadie lo moviera en el mesón. Pasa a conteo manual (§0.2.1) | `2026-08-apagar-reposicion-automatica.sql` | 08-01 |
| Adriana tardaba horas actualizando el stock de Fudo a mano (ponía 1.000 de todo) | Cálculo en la base + Edge Function que escribe por `PATCH` JSON:API, siempre valor absoluto | `2026-07-stock-para-fudo-v2-CORTO.sql` + `fudo-empujar-stock` | 07-28 |
| Los envases (bolsas, bandejas) limitaban la venta: "Torta Pedidos Ya" quedaba en 0 con 8 trozos | Se excluyen del `min()` por `productos.tipo = 'Envases'` | `2026-07-stock-para-fudo-v2-envases.sql` | 07-28 |
| A Fudo le llegaba solo el stock de vitrina (alfajor 2 en vez de 17) | El stock de un insumo pasa a ser la **suma de su nombre base** | `2026-07-stock-para-fudo-v3-suma-el-par.sql` | 07-29 |
| "Ya está al día" cuando no lo estaba: el espejo local de Fudo estaba viejo | Se corre la sync de catálogo **antes** de cada revisión | `index.html` (`refrescarEspejoFudo`) | 07-29 |
| Un empuje equivocado no dejaba rastro ni se podía revertir | Bitácora `fudo_stock_push` con valor anterior, agrupada por lote, y deshacer del último | `2026-07-permisos-y-deshacer.sql` + `fudo-deshacer-stock` | 07-28 |

#### Qué deja hacer la API de Fudo con el CATÁLOGO — medido, no supuesto

*(Prueba aislada `fudo-probar-catalogo`, Angamos, 2026-08-08. Antes de
proponer cualquier cosa que toque el catálogo, mirar esta tabla.)*

| Operación | ¿Se puede? | Evidencia |
|---|---|---|
| **Leer** productos | ✅ | ya se usaba (`fudo-sync-productos`) |
| **Cambiar el stock** | ✅ | ya se usaba (`fudo-empujar-stock`) |
| **CREAR un producto** | ✅ | `POST /products` → **201**, producto id 917 |
| **DESACTIVAR** (`active: false`) | ✅ | `PATCH` → **200**, el campo queda en false |
| **BORRAR** | ❌ **no existe la operación** | ver abajo |

**Cómo se supo que borrar no existe, porque el dato engaña:** `DELETE
/products/917` devolvió **404** — pero ese producto EXISTÍA (se acababa de
crear, y al releerlo contestó 200 y seguía ahí). Un producto que existe no
puede dar "no encontrado" al borrarlo: **ese 404 es de ruta, no de
registro.** La segunda huella está en la forma de la respuesta:

| Llamada | Respuesta |
|---|---|
| `PATCH` a un id inexistente | `{"status":"404","code":"not-found"}` |
| `DELETE`, a cualquier id | `{"status":404}` — pelado, sin `code` |

Son dos capas distintas contestando. **Ni el 404 ni el 405 se pueden leer
solos**: la única forma de distinguir "no está el producto" de "no está la
operación" es intentarlo sobre algo que sí exista y **releer después**.

**Por qué — CONFIRMADO el mismo día por la propia pantalla de Fudo**, y
corrige lo que yo había escrito. Jhon intentó borrar `Crema Zapallo` desde
Fudo y salió este mensaje textual:

> *"No se puede eliminar este producto. Está siendo usado en un combo o
> está adicionado en una venta. Para eliminarlo, primero desvincúlalo de
> esos lugares."*

Entonces el cuadro real es más fino que "Fudo no deja borrar":

| | |
|---|---|
| Borrar **existe** en la pantalla de Fudo | ✅ el botón está ahí |
| Pero se niega si el producto **está en un combo o ya se vendió** | ✅ ese es el candado |
| Y **no está expuesto en la API** en `/products/{id}` | ✅ medido acá |

O sea: **lo que Adriana sí puede borrar a mano son los productos vírgenes;
lo que estorba —4 años de catálogo que alguna vez se vendió— no lo puede
borrar nadie, ni ella ni nosotros.** El candado es el historial de ventas,
no un permiso que falte.

**Y de la misma pantalla sale un dato útil:** el formulario del producto
tiene una casilla **"Activo"**. Desactivar desde nuestro sistema es
destildar esa casilla — no es un rodeo nuestro, es el interruptor que Fudo
ya usa. Por eso **desactivar es la respuesta que el sistema tiene
prevista** para lo que no se puede borrar.

**Lo que esto habilita** (§6.3 y §6.0 dependían de saberlo): crear
productos en Fudo desde el taller de recetas, y apagar los duplicados que
Adriana arrastra hace 4 años. **Lo que NO**: prometerle "borrar".

**DECISIÓN DE JHON (2026-08-08): crear y desactivar se implementan en el
área nueva de BODEGA**, no ahora y no sueltos. *"dejalo en el registro que
podemos crear y desactivar cosas, lo implementaremos en toda el area nueva
que vamos a crear de bodega."* Hasta entonces esto es un hallazgo
guardado, no una función a medio hacer.

⚠️ **Quedó en el catálogo de Angamos el producto 917 "ZZZ PRUEBA CLAUDE -
ignorar", desactivado.** No se puede sacar por la API. Es el ejemplo vivo
del problema.

### Datos y lecturas

| Qué fallaba | Cómo se resolvió | Dónde vive | Fecha |
|---|---|---|---|
| Una meta de venta contaba **otro producto** en la segunda sede: el id 584 es el agua en Plaza y "Capuccino Pedidos Ya" en Angamos | `meta_productos` gana columna `sede` y `meta_avance` une por **(id, sede)**. Además cuenta una vez por línea vendida, así una receta de 3 insumos ya no multiplica por 3 | `2026-08-metas-cuentan-por-sede.sql` | 08-28 |
| El buscador de productos de una meta pedía el catálogo con `.limit(1000)` y entre las dos sedes hay ~1.280: media carta de Angamos no llegaba | Se lee por páginas hasta que una venga incompleta (`metaCartaFudo`) | `index.html` | 08-28 |
| La pestaña Historial se cortaba el 25 y ya era 28: la tarea automática había vuelto a una versión vieja que solo escribía en `historial_auto` | Se reagendó con la instrucción completa, y el 26 y el 27 se rellenaron desde el respaldo de las 22:00. Los dos archivos que la pisaban llevan **⛔ NO CORRER** | `2026-08-la-foto-volvio-a-la-pantalla.sql` | 08-28 |
| El historial ofrecía días viejos: se pedían **todas** las filas y Supabase cortaba en 1000 sin avisar | Función que agrupa por fecha en la base y devuelve una fila por día (con respaldo `order`+`limit`) | `2026-07-historial-dias.sql` | 07-27 |
| Al vender, el teléfono mostraba el stock nuevo con las fechas viejas ("Champiñón 0" + "1 vence hoy") | `producto_lotes` agregada a la publicación `supabase_realtime` | `2026-07-fechas-en-vivo-y-limpieza.sql` | 07-27 |
| Fechas fantasma: lotes en cantidad 0 que igual se mostraban y se copiaban al resumen | Se borran, con respaldo previo; y quedó la jerarquía stock/fechas de la regla 0.3.1 | mismo archivo | 07-27 |
| Buscar "azucar" no encontraba "Azúcar" | `normNombre()` — sin tildes, minúsculas, espacios de más — en los tres buscadores | `index.html` | 07-24 |
| Un producto en 2 secciones mostraba cantidades sueltas, sin el total | `totalProducto()` agrupando por `baseNombre()` | `index.html` | 07-24 |
| Vitrina y congelador no sumaban porque los nombres no calzaban | Emparejador con **dos claves**: una para encontrar candidatos, otra para decidir si suman | `2026-07-emparejar-vitrina-congelador.sql` | 07-29 |
| Al eliminar un producto, reaparecía un instante | Se quita la fila al toque y se ignoran 20 s los eventos en vivo de un id recién borrado | `index.html` (`BORRADOS`) | 07-27 |
| Crear/renombrar/eliminar no se reflejaba en otros dispositivos | Se recarga al volver del fondo (`visibilitychange`, focus, online) y se maneja el DELETE real | `index.html` | 07-24 |

### Interfaz y trabajo del mesón

| Qué fallaba | Cómo se resolvió | Dónde vive | Fecha |
|---|---|---|---|
| Las ventanas del navegador (`alert`/`confirm`/`prompt`) parecían un error del sistema | `avisar()`, `preguntar()`, `elegirProducto()` — misma paleta, fondo desenfocado | `index.html` | 07-27 |
| A un producto le cambiaron el nombre sin querer | Nombre, sección y eliminar quedan detrás del interruptor **Modo edición**, que arranca apagado siempre | `index.html` (`setModoEdicion`) | 07-27 |
| Cuatro botones para dos acciones de sincronizar | Un solo ⟳ que corre el registro `PASOS_SYNC` en orden | `index.html` | 07-25 |
| Adriana necesitaba dos pantallas: veía en Crítico, anotaba en Reparto | Deslizar la fila la manda al reparto, en cualquier dirección | `index.html` | 07-28 |
| Adriana mandaba la lista por WhatsApp y el local la **transcribía** a la app | Repartos en la app: ella arma, el local confirma ✓/cantidad/✕, y la suma ocurre en la base | `2026-07-repartos.sql` | 07-27 |
| Al armar el pedido no se veía cuánto había ni cuánto faltaba | Píldora con el estado, `hay N · máx M` releído en cada pintada, y atajo "llenar N" | `index.html` (`infoReparto`) | 07-28 |
| Los sándwiches escondían fechas detrás de "+N fechas" | Una píldora por cada fecha, siempre, con la urgencia en el color | `index.html` (regla 0.3) | 07-27 |
| Cada fila repetía su propia sección — `items.map(rowHTML)` pasaba el índice como `conSeccion` | `items.map(p => rowHTML(p))` | `index.html` | 07-27 |
| Las secciones decían *dónde* está algo, pero no *qué es* | Franja de tipos deslizable, alimentada por `productos.tipo` | `2026-07-tipo-de-producto.sql` + `index.html` | 07-27 |
| El naranja de las cabeceras competía con las alertas: todo se leía urgente | Cabeceras en azul pizarra `#2F4A6D`; el naranja queda solo para acción y urgencia | `index.html` (`:root`) | 07-27 |
| Un perecedero podía entrar al inventario sumando stock directo, rompiendo la invariante | `reparto_recibir()` lanza error si no llegan fechas — el candado está en la base | `2026-07-repartos.sql` (regla 0.4) | 07-27 |

### Prevención — lo que existe para que no vuelva a pasar

| Riesgo | Qué lo cubre hoy | Dónde vive |
|---|---|---|
| **Volver a correr un `.sql` viejo y pisar una tarea buena** | Los dos archivos superados de la foto automática llevan **⛔ NO CORRER** en la primera línea. Un archivo del repo no dice qué está instalado (§0.1.2), pero sí puede decir que no se ejecute | `2026-08-central-historial-automatico.sql` y `2026-08-respaldo-automatico-de-verdad.sql` |
| Instalar un motor suponiendo el estado de producción | Chequeo de salud: **bloque 0 da el resumen de 10 filas en una sola corrida**; los bloques 1-10 son el detalle | `2026-07-salud-del-sistema.sql` |
| **Creer que un `.sql` se corrió cuando no** (3 incidentes: las 15 h, el cálculo viejo, `producto_lotes`) | Cuaderno `migraciones_aplicadas`. **Cada script nuevo se anota solo al final** — no depende de que alguien se acuerde. Sembrado solo con lo que el chequeo COMPROBÓ, no con lo que "debería" estar | `2026-07-registro-de-migraciones.sql` |
| Perder datos sin punto de restauración | Respaldo de `productos`/`recetas`/`receta_items`/`producto_lotes`, probado restaurando. **Los archivos se guardan en Notion**, no en el repo (ver `respaldos/README.md`) | `2026-07-respaldo-para-guardar.sql` |
| Que la librería cambie sola y rompa la app | Versión fija `@2.111.0` | `index.html:15` |
| **Que el motor falle y nadie se entere** | Alarma por proporción en el botón (`juzgarVentas`) **y** franja en pantalla leída de la base (`juzgarMotor`), que funciona aunque nadie apriete ⟳ | `index.html` + `2026-07-estado-del-motor.sql` |
| No saber qué versión de una Edge Function está desplegada | `fudo-sync-ventas` devuelve `version` en cada respuesta | `supabase/functions/fudo-sync-ventas/index.ts` |
| Que alguien sin permiso escriba en Fudo | Comprobación contra `app_permisos` **en el servidor**, no solo esconder el botón | las Edge Functions de Fudo |
| Que el personal de una sede edite productos de la otra sin querer | **Construido pero apagado por decisión de Jhon** (§9.6): `app_permisos.sede` acotaría el permiso a una sede. Hoy se controla capacitando | `2026-08-permiso-por-sede.sql` (sin correr) |
| Recetas que apuntan al vacío o cobertura incompleta | Informe de solo lectura + bloques 9 y 10 del chequeo | `2026-07-auditoria-recetas.sql` |
| Revisar cómo están los permisos sin cambiarlos | Diagnóstico de solo lectura (ver 6.1: la decisión ya está tomada) | `2026-07-revision-seguridad.sql` |

---

## 9. Encender una sede nueva — el caso Angamos

> Pedido el 2026-07-30: Mall Plaza quedó funcionando y administración pide
> llevarlo a **Parque Angamos**. Esta sección es el plan; cuando se ejecute,
> se corrige acá con lo que de verdad pasó.

### 9.0 La buena noticia: casi todo ya es multi-sede

**No hay que escribir código nuevo.** Está verificado leyendo el repo:

| Pieza | Estado |
|---|---|
| `index.html` | `SEDES` ya trae `angamos: {label:'Parque Angamos'}`. Todo filtra por `SEDE` |
| Las 5 Edge Functions | Ya leen `FUDO_${sede.toUpperCase()}_APIKEY`. Ninguna tiene "plaza" escrito a mano |
| `productos`, `recetas`, `repartos`, `historial`, `fudo_productos` | Todas llevan columna `sede` |
| El motor de descuento | Recibe la sede y respeta `fudo_sync.modo` por sede |

Agregar una sede es **agregar filas y secrets**, no construir nada. Eso ya
estaba anticipado en §7 y se confirma acá.

### 9.1 El plan, en orden — y el orden IMPORTA

> Refinado el 2026-08-01 sobre un plan que armó otra sesión. Lo que sigue ya
> incorpora sus hallazgos medidos y las correcciones que les faltaban.

**Antes de todo:** correr el chequeo de salud (§6) y **sacar un respaldo**
(`2026-07-respaldo-para-guardar.sql`). La fase 4 es la primera escritura masiva
que este proyecto le hace a una sede entera; el respaldo es barato y es la
única red que hay.

#### Fase 1 — Ordenar el inventario de Angamos *(se puede hacer YA, sin credenciales)*

Es solo lectura y **no depende de Fudo**, así que avanza mientras administración
consigue las llaves.

1. **Los 14 duplicados de Angamos.** ⚠️ Hallazgo del 2026-08-01, verificado
   leyendo el archivo: `sql/2026-07-duplicar-vitrina-en-congelador.sql` tiene
   `where p.sede in ('plaza','angamos')` — corre sobre **las dos sedes**. Creó
   en Angamos una copia en `Congelador` de cada producto de vitrina.

   En Plaza el par vitrina/congelador es necesario. **En Angamos no**: esa sede
   tiene su propia bodega y ese inventario todavía no se hace. Propuesta a
   confirmar por Jhon: **desactivar** (`activo='NO'`), no borrar — deja rastro
   y se deshace.

   **Esto va PRIMERO, y no es cosmético.** Mientras existan los duplicados, cada
   insumo de Plaza tiene dos candidatos en Angamos y el emparejador no puede
   decidir. Apagándolos, buena parte de las ambigüedades desaparece sola. Y si
   se replicaran las recetas antes, quedarían apuntando a un producto que
   después se va a desactivar.

2. **Insumos de Plaza sin pareja en Angamos.** Listar con su rubro y su
   candidato más cercano. Hay dos tipos y solo Jhon los distingue: el mismo
   producto con otro nombre (`T. Cheesecake Maracuya` ↔ `T. Cheesecake Mara`)
   y los que de verdad faltan (`Miel`, `Sandwich Selladito`). Regla 0.1.8: **es
   una pregunta, no un hallazgo.**

3. **Los productos que solo existen en Angamos.** Jhon confirmó que la carta es
   la misma, así que estos **no deberían ser platos**: lo más probable es que
   sean insumos, envases o limpieza propios de esa sede. Se listan para
   confirmarlo, no para corregir nada.

#### Fase 2 — Conectar Fudo *(bloqueada hasta que lleguen las credenciales)*

4. Secrets en Supabase → Edge Functions → Secrets: **`FUDO_ANGAMOS_APIKEY`** y
   **`FUDO_ANGAMOS_APISECRET`**. El nombre no es libre — las funciones lo arman
   con `sede.toUpperCase()`.
5. **Fila de `fudo_sync` para angamos, `cron_activo = false`.**
   ⚠️ **El modo quedó en `real`, no en `prueba`** — decisión de Jhon del
   2026-08-04, ver §9.5. El plan original decía `prueba`; se cambió a pedido
   suyo y con su razón escrita.
6. **Ninguna Edge Function se toca ni se redespliega.** Ya son multi-sede.
7. Correr `fudo-sync-productos` con `sede:'angamos'` para llenar `fudo_productos`.

#### Fase 3 — MEDIR el calce de los dos catálogos de Fudo, antes de escribir nada

**Este paso no estaba en el plan original y es el que más puede doler si falta.**

El traslado de recetas tiene DOS saltos por nombre, y el plan cuidaba solo el
segundo:

```
salto 1:  Fudo plaza "Cappuccino"  →  Fudo angamos "Cappuccino"
salto 2:  insumo plaza "Leche"     →  insumo angamos "Leche"
```

El salto 1 es **igual de frágil** que el 2, y hay evidencia dura: dentro del
propio Plaza convivían `T. Cheesecake Maracuya` y `T. Cheesecake Mara` para lo
mismo. Son dos cuentas de Fudo distintas, cargadas por gente distinta, en
momentos distintos. Nada garantiza que escriban igual.

Entonces: apenas llegue el catálogo, **contar cuántos de los 168 productos de
Fudo con receta en Plaza tienen un nombre idéntico en Fudo Angamos.** Si calzan
150, adelante. Si calzan 60, el traslado automático no es el camino y hay que
saberlo ANTES de escribir 168 recetas.

#### Fase 4 — Trasladar las recetas *(la única escritura masiva)*

8. **Vista previa primero.** Por cada receta de Plaza: qué crearía en Angamos,
   con qué insumos, marcada `✓ automático` / `⚠ ambiguo` / `✗ sin pareja`. No
   escribe nada. **Jhon la revisa.**
9. **Aplicar solo los `✓`.** Conserva `cantidad` y `aplica`. Idempotente.
10. **No trasladar recetas que en Plaza ya están rotas.** `Muffin Amapola`
    apunta a un insumo borrado a propósito (§6.0). Copiar eso a Angamos sería
    exportar un problema conocido.
11. **Si dos insumos de Plaza caen en el mismo producto de Angamos**, se suman
    las cantidades en una línea — el `unique (receta_id, producto_id)` lo exige.

**Cómo se deshace, y hay que escribirlo ANTES de correrlo** (regla 0.1.3).
Hoy Angamos tiene 0 recetas, así que la vuelta atrás es limpia:

```sql
delete from public.receta_items
 where receta_id in (select id from public.recetas where sede='angamos');
delete from public.recetas where sede='angamos';
```

⚠️ Esto solo sirve **mientras nadie haya hecho recetas a mano en Angamos**. Una
vez que Jhon corrija alguna desde la app, deja de ser reversible en bloque.

#### Fase 5 — Prueba, y recién después `real`

12. Días en `modo='prueba'` mirando `fudo_movimientos` de angamos.
13. **La falsa alarma que hay que esperar:** en `prueba`, `aplicado=false` en
    todo es lo NORMAL (regla 0.1.9). Y la franja del motor **no** debe ponerse
    roja en una sede recién encendida — eso ya está cubierto y probado en
    `juzgarMotor()`.
14. El paso a `real` **lo decide Jhon**, no el plan.
15. El cron de Angamos se agenda **recién con la sede en `real`**, duplicando el
    bloque de `2026-07-cron-automatico-ventas.sql` con `?sede=angamos`, y en los
    3 pasos ya probados: agendar → comprobar a los 20 min que
    `ultima_corrida_por` diga `cron` → recién ahí `cron_activo = true`.
16. ~~**El empuje de stock hacia Fudo NO se enciende en Angamos.**~~
    ⚠️ **SUPERADO el 2026-08-06.** Angamos SÍ le escribe a Fudo: Jhon lo
    probó a mano (alfajor artesanal, de 8 a 9) y desde entonces el reparto
    empuja al confirmarlo, en las dos sedes, con `fudo-sumar-stock`. Se deja
    tachado y no borrado para que nadie "arregle" algo que ya funciona.

### 9.2 Las trampas que ya conocemos, aplicadas a Angamos

- **No copiar las recetas de plaza cambiando la sede.** Los ids de Fudo son de
  otra cuenta. Es el error más probable de esta migración.
- **El emparejador de vitrina/congelador NO se corre en Angamos.** En esa sede
  no hay par que emparejar — lo que hay son duplicados que sobran (fase 1).
- **Lo mismo con cualquier `.sql` viejo del repo.** Contado el 2026-07-30:
  **22 de los 42 archivos de `sql/` tienen `'plaza'` escrito a mano**, algunos
  seis o siete veces. Ninguno sirve tal cual. **Revisar cada aparición** — no
  reemplazar a ciegas: en varios, `plaza` es el ORIGEN a copiar (como en
  `replicar-secciones-plaza-a-angamos.sql`) y cambiarlo rompe el sentido.
- ~~**El empuje de stock hacia Fudo NO se enciende de entrada.**~~ Valió
  mientras Angamos se encendía; **desde el 2026-08-06 ya está encendido** y
  probado (ver fase 5, punto 16). El criterio de fondo sigue en pie para la
  próxima sede: primero descontar, y escribir solo cuando eso sea confiable.
- **`app_permisos` no tiene columna `sede`**, y eso es una **decisión**, no un
  descuido: la mecánica está construida (`sql/2026-08-permiso-por-sede.sql` +
  `permisosDeLaSede()`) pero **Jhon decidió el 2026-08-04 no correrla** — ver
  §9.6. Mientras tanto, quien puede empujar a Fudo puede hacerlo en cualquier
  sede. Volver a mirarlo **cuando se encienda el empuje en Angamos**, no antes.
- **Angamos arranca sin historial y sin repartos**, y eso está bien: son tablas
  por sede que se llenan solas con el uso.

### 9.3 Cómo se sabe que quedó bien

Con `sql/2026-07-salud-del-sistema.sql`, **bloque 0** para el resumen y estos
tres en particular:

| Bloque | Qué contesta para Angamos |
|---|---|
| 9 | Cobertura de recetas por sede. Angamos parte en 0% y esa es la métrica |
| **10** | **Recetas que apuntan al vacío.** Es el que atrapa un traslado mal hecho: si el emparejador se equivocó, acá salen |
| 8 | Si el motor está leyendo — recordando que en `prueba` no aplicar es lo normal |

Y en la app: elegir Parque Angamos y comprobar que el inventario y las recetas
cargan, y que **la franja del motor no da falsa alarma** en una sede recién
encendida.

### 9.4 Regla de trabajo — Mall Plaza es el patrón

*(De la sesión del 2026-08-01. Vale la pena porque evita una tentación real.)*

**La infraestructura no cambia para encender una sede.** Mismas tablas, mismo
motor, mismas Edge Functions, misma estética. Angamos se enciende **agregando
filas**. Si en el camino aparece una mejora que valdría la pena, **se propone
aparte y para las dos sedes** — no se cuela dentro de la migración, donde
nadie la va a poder distinguir de lo que había que hacer igual.

### 9.5 Angamos arranca en `real`, no en `prueba` — y el ⟳ no trae recetas

*(Jhon, 2026-08-04. Dos cosas de la misma conversación.)*

**1. El modo.** Él lo pidió así, textual: *"por ahora no quiero que el modelo
esté en modo prueba… solo lo vamos a tocar nosotros, y quiero mover todo en
modo real para que esté lo más actualizado posible, además Angamos ya tiene su
inventario antiguo de Excel todavía, así que no te preocupes."*

Los dos argumentos son buenos y hay que dejarlos escritos, porque el plan
original (§9.1 fase 5) decía lo contrario y una sesión futura podría "corregirlo"
sin saber por qué: **nadie del mesón está usando Angamos todavía** —el riesgo de
que un número raro confunda a alguien es cero— y **el Excel sigue vivo como red**.
En `prueba` habría que mirar `fudo_movimientos` a mano para saber qué habría
pasado; en `real` el inventario simplemente se mantiene al día solo.

**El matiz que hay que entender, y no es un pero:** hoy el modo **no cambia
nada**, porque Angamos tiene **0 recetas** y sin receta no hay qué descontar.
El modo empieza a importar el día que se creen las 168 recetas de una vez —
ahí un emparejamiento equivocado baja stock inmediatamente en vez de quedar
anotado. Por eso la vista previa de la fase 4 pasa de recomendable a
**obligatoria**: era la red que daba el modo `prueba`, y ahora es la única.

Archivo: `sql/2026-08-angamos-catalogo-y-modo-real.sql`.

**2. "El ⟳ no trae las recetas".** Jhon lo reportó como falla y **no lo es**.
El botón corre `PASOS_SYNC`: catálogo de productos de Fudo y lectura de ventas.
**Las recetas no viajan por ahí** — son filas nuestras, en nuestra base, y
Angamos todavía no tiene ninguna. Vale anotarlo porque el nombre del paso
(`productos`) y lo que la gente espera del botón no coinciden: **el ⟳ trae lo
que Fudo sabe, no lo que nosotros construimos.**

### 9.6 La depuración de Angamos la hace su propio personal — permiso por sede

*(Jhon, 2026-08-04.)* El inventario de Angamos hay que ordenarlo a mano: borrar
lo que allá no se vende (Muffin Amapola), agregar lo que sí (Agua Bosqua), y
**apagar los duplicados de Congelador** — porque *"Mall Plaza tiene un fenómeno
que Angamos no tiene, el producto con doble posición"*. Todo eso necesita **Modo
edición**, y lo hace la gente de esa sede, no Jhon.

**DECISIÓN DE JHON, y es la que manda: les presta su cuenta.** Yo propuse acotar
el permiso por sede y él lo evaluó y dijo que no hacía falta, con estos
argumentos: *"son máximo dos personas las que van a tener contacto con el
inventario… yo mismo los voy a capacitar… Este también fue mi sistema, y desde
que el modelo era más crudo no tuve ningún problema en que se eliminaran
productos que hicieran falta. Y en caso de que se eliminaran, se podrían volver
a crear."*

Vale dejar escrito el argumento porque es correcto y una sesión futura podría
querer "arreglarlo": **el daño acá es reversible** —un producto borrado se
vuelve a crear— y el riesgo se controla con capacitación porque el universo de
gente es dos personas, no veinte. Aplica la regla 0.1.7.

Mi objeción quedó anotada y no se vuelve a proponer: esa cuenta lleva
`puede_fudo = true`, o sea el botón que le escribe el stock a Fudo. **Él lo
sabe y decidió igual.**

**La mecánica quedó construida pero APAGADA.** `app_permisos` puede tener una
columna **`sede`**, y el código de la app ya la respeta — pero
`sql/2026-08-permiso-por-sede.sql` **no se corrió y no hay que correrlo**.
Mientras la columna no exista, `permisosDeLaSede()` devuelve el permiso
completo y todo funciona como siempre (está probado, es uno de los 11 casos).
Si algún día crecen las sedes o la gente, esto es lo que hay:

| | |
|---|---|
| `sede` vacío | todas las sedes — **así quedaron las 5 cuentas que ya existían**, no le cambió nada a nadie |
| `sede = 'angamos'` | el Modo edición y la zona de administración **no aparecen** en Mall Plaza |
| Acota los dos permisos | `puede_editar` **y** `puede_fudo`, no solo el primero |
| La cuenta nueva de Angamos | `puede_editar = true`, **`puede_fudo = false`** — para ordenar el inventario no hace falta escribirle a Fudo, y ese botón no se enciende en Angamos (§9.2) |

En la app: `permisosDeLaSede(fila, sede)`, una función aparte y pura justamente
para poder probarla. `cargarPermisos()` ya se volvía a correr al cambiar de sede
(`pickSede`), así que el permiso se re-evalúa solo. Prueba en
`pruebas/permiso-por-sede.mjs`, 11 casos, en las dos direcciones — incluido
**que las cuentas de siempre no pierdan nada**, que es el riesgo real de esta
migración, y que si la columna todavía no existe en la base todo siga como antes.

**Qué habría sido y qué no:** un **seguro contra accidentes, no seguridad**
(§6.1). Nunca habría evitado a un malintencionado, porque la app lee y escribe
sin sesión por decisión tomada. Contra el resbalón sí servía — y Jhon decidió
que contra el resbalón alcanza con capacitar a dos personas.

### 9.7 Las recetas de Angamos — cómo se armaron (2026-08-05)

Angamos pasó de **1 receta a ~85 en una tarde**. Vale escribir cómo, porque el
plan original (§9.1 fase 4, "trasladar las 168 de Plaza") resultó ser **el
camino equivocado** para la mayoría.

**El hallazgo que lo simplificó todo.** Para una receta de UN insumo no hacen
falta las recetas de Plaza. El plan cuidaba dos saltos de nombre:

```
salto 1:  Fudo plaza "Cappuccino"  ->  Fudo angamos "Cappuccino"
salto 2:  insumo plaza "Leche"     ->  insumo angamos "Leche"
```

Pero una receta 1:1 se empareja **dentro de Angamos**: catálogo de Fudo
Angamos contra inventario Angamos. **Un salto en vez de dos**, y los dos lados
los cargó la misma gente en la misma sede. El traslado desde Plaza queda solo
para lo que de verdad tiene varios insumos — los combos y los preparados.

**La evidencia de que el emparejador automático NO servía.** El calce exacto
encontró 38 de 437. Pero el candidato "más parecido" se equivocó justo en el
producto de más peso: `Croissant Jamon Queso`, insumo de **11 recetas** en
Plaza, recibió como propuesta `Croissant manjar`. Si se hubiera aplicado
automático, ese error se propagaba a once recetas de una vez. **Falla donde
sale más caro** — por eso la lista final la revisó Jhon par por par.

**Cómo quedó repartido:**

| | |
|---|---|
| 23 | el nombre calza exacto en los dos lados |
| 17 | variantes **"Pedidos Ya"** — mismo producto por delivery, misma receta |
| 41 | el mismo producto **escrito distinto** (`Torta amor` → `Trozo torta amor`, `Sandiwch jamón serrano` → `Sandwich Serrano`) |

**Lo que NO lleva receta, y son decisiones, no olvidos:**
- **Los insumos de barra** (pulpas, té de hoja, syrups, azúcar flor, naranjas,
  limones, bombillas, collarines). Jhon: *"NO se descuentan (por ahora), solo
  lo cuantificable, al igual que en Mall Plaza."* Es la regla de §4 aplicada a
  la sede nueva.
- **Los ~40 combos** (`APALTADO + CAFE`). Los ve administración. **Y ojo:
  Jhon ya las armó a mano en Mall Plaza**, así que esas recetas son el molde —
  los `fudo_product_id` no sirven (otra cuenta) pero el contenido sí.
- **Cafés, tés y jugos preparados.** Dependen de la medición de granel (§10).
- `producto prueba`, `RESERVA`, `Tostadas Admin`, `cafe mediano psicóloga`:
  productos internos o de prueba. No llevan receta nunca.

**Dos cosas que salieron mal y cómo se detectaron:**

1. **Dos recetas no se crearon** (`Torta Matilda Pedidos Ya`, `Media Luna
   Manjar`). Los productos SÍ existían: el nombre en Fudo trae un espacio de
   más que no se ve. **La lección es del método, no del bug**: el bloque de
   comprobación estaba escrito para *delatar* el nombre que no calza en vez de
   crear la receta igual. Sin ese bloque, esas dos habrían quedado en silencio.
   Al comparar nombres contra Fudo, comparar con **`ilike` y comodines** —
   nunca letra por letra, y tampoco confiando en normalizar espacios: el
   carácter invisible puede no ser un espacio corriente.

   **Y el arreglo falló a la primera por otra causa, que es la que hay que
   recordar:** creaba una tabla de trabajo y la usaba **en el mismo Run**. El
   editor de Supabase respondió `relation "public.angamos_mapa_recetas" does
   not exist`. Suma a §3.5: en una misma corrida del editor, **no crear una
   tabla y usarla** — o se parte en dos pasos, o se resuelve sin tabla.
2. **Salieron 83 recetas donde se esperaban 79.** Causa probable: nombres
   repetidos en el catálogo de Fudo de Angamos (dos productos distintos que se
   llaman igual) — no es un error, los dos se venden y los dos descuentan lo
   mismo. Se comprueba con el bloque 3 de
   `2026-08-angamos-recetas-cierre.sql`. **Un número que no cuadra se
   investiga, no se redondea.**

**El Muffin Amapola NO se trasladó.** Jhon lo borró del inventario de Angamos
porque allá no se vende. Mall Plaza arrastra su receta apuntando al vacío a
propósito (§6.0); exportar eso a la sede nueva no tenía sentido.

Archivos: `2026-08-angamos-recetas-simples-informe.sql` (solo lectura),
`2026-08-angamos-recetas-tanda-unica.sql`, `2026-08-angamos-recetas-cierre.sql`.

## 10. Insumos que no se cuentan de a uno (té, café, naranja, limpieza)

> Conversado con Jhon el 2026-07-31. **Todavía no hay nada construido** — esto
> es el marco acordado y la tarea de medición que él está haciendo en el local.

**El problema:** la mitad de lo que se vende en plaza no descuenta nada (48% de
cobertura). Buena parte de ese hueco son insumos a granel: no se sabe cuántas
naranjas lleva un zumo ni cuántos gramos de café un cappuccino.

**Cómo se resuelve, y NO es con un modelo probabilístico.** Es el estándar de
la industria — *inventario teórico contra inventario real* — y son tres piezas:

1. **Rendimiento**: cuánto rinde la unidad de compra. Pura división
   (gramos del paquete ÷ gramos por uso).
2. **Descuento fraccionario por venta**: la receta descuenta `0,018` kg, no 1.
   **Ya está soportado**: `receta_items.cantidad` es `numeric` y
   `productos.stock_actual/min/max` son `double precision` (verificado en
   producción el 2026-07-31). No hace falta migrar nada.
3. **Conteo periódico que corrige la deriva.** Ya existe: es el `historial`.
   La diferencia entre lo teórico y lo contado **es la merma**, y es
   información útil, no un fallo del cálculo.

**Decisiones tomadas en esa conversación:**

- **NO descontar "un poquito cada día".** Jhon lo propuso y se descartó con
  razón: un descuento diario fijo tira a la basura el dato que ya se tiene
  (cuánto se vendió) y acumula error sin avisar. La excepción son los productos
  de **limpieza**, que no los empuja ninguna venta — ahí lo honesto es mín/máx
  y conteo a ojo, sin automatizar nada.
- **Empezar por el té**, no por el café. Cálculo simple y error barato. El café
  mueve la plata y va después.
- **Un producto a la vez.** Si el método falla, que falle en el té.

**Dónde sí entra la estadística, y es el caso de la naranja.** Cuando un insumo
lo consumen varios productos y no se sabe el reparto, queda:

```
naranjas del día = a·(zumos) + b·(desayunos) + c·(orange coffees) + merma
```

Con varios días de datos se resuelve por **mínimos cuadrados**. **La condición
que hay que respetar: la mezcla de ventas tiene que VARIAR entre días.** Si
zumos y desayunos se venden siempre en la misma proporción, es matemáticamente
imposible separarlos (colinealidad) — no es un problema de programación y no se
arregla con más datos del mismo tipo.

**Datos que ya dio Jhon (2026-07-31):**

| Insumo | Dato |
|---|---|
| Café | Bulto de **60 kg**; **18 g** por espresso doble (o dos simples) |
| Café | → **3.333 dosis por bulto**; ~2.800-3.200 vendibles con 5-15% de merma |
| Naranja | Una caja dura **1 a 1,5 días** |
| Naranja | La usan zumo, desayunos y orange coffee |

**Lo que falta y lo está midiendo Jhon** (artefacto "Tarea para la casa",
2026-07-31): gramos por tetera de té, cuántas dosis lleva cada bebida de la
carta, shots botados por día, naranjas por caja, ml por naranja y por vaso, y
un registro de **cajas abiertas por día durante dos semanas** — solo eso, porque
las ventas de esos días ya las tiene el sistema.

**Falta una pieza en la base:** no hay columna de **unidad de medida** en
`productos`. Hoy "Café en grano 8" no dice si son 8 bultos, 8 kilos u 8
paquetes. Para lo discreto da igual; para esto es imprescindible, porque quien
cuenta en el mesón necesita saber qué está contando.

---

## 10.1 Lo que está EN MESA — el doble descuento del conteo nocturno

> Problema traído por Jhon el 2026-08-01. **Comprobado, todavía sin construir.**

**El síntoma.** Jefatura cuenta de noche con mesas abiertas. Hay 10 panes en el
estante y 2 en una mesa sin cerrar; la app dice 12. El jefe cuenta 10 y
"corrige" la app a 10. Cuando la mesa cierra, el motor descuenta 2 y queda en
**8**. El jefe concluye "esto no sirve".

**La causa, y es importante decirla bien: el sistema iba a quedar correcto solo.**
Los 12 son "10 en el estante + 2 en camino". Si nadie tocaba nada, al cerrar la
mesa quedaba en 10. **La corrección manual es la que rompe** — esos 2 se
descuentan dos veces, una a mano y otra por el motor.

La imagen que se lo explica a cualquiera: la cuenta dice $12.000 pero ya giraste
un cheque de $2.000 que no se ha cobrado. Si "corriges" el saldo a $10.000,
cuando el cheque se cobre quedas en $8.000.

**Capacitar sola no basta** (y esto ya es doctrina del proyecto): pelea contra
la operación real, le pide a alguien que no actúe sobre lo que ve con sus ojos,
y cuando falla, falla en silencio.

**COMPROBADO el 2026-08-01 con `fudo-probar-mesas-abiertas`** (prueba aislada de
solo lectura, borrable):

| Pregunta | Respuesta |
|---|---|
| ¿Fudo expone las mesas abiertas? | **Sí** |
| ¿Cómo se llama ese estado? | **`IN-COURSE`** — no es `OPEN`, que era lo que yo habría adivinado |
| ¿Traen sus productos? | **Sí**, con `include=items.product` |
| ¿Se puede filtrar por estado? | **Sí**: `filter[saleState]=in.(IN-COURSE)` |

**La decisión de diseño tomada: NO descontar por mesas abiertas.** Solo leerlas
para (a) mostrar cuánto hay en tránsito y (b) que el conteo manual cuadre solo.
Descontar al poner el producto en la mesa obligaría a detectar retiros y
anulaciones y a devolver stock — una fuente nueva de errores silenciosos, que es
lo que más caro ha salido acá. Leyendo sin descontar, **una mesa anulada no
rompe nada**.

**Pendiente de diseño** (Jhon lo marcó y tiene razón): la píldora de un sándwich
ya carga nombre, mín, máx, estado, total y una fecha por lote. **No se le agrega
información.** El camino propuesto es intervenir donde ocurre el daño —la ficha
donde se edita el stock— y no en cada fila de la lista.

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

### LO QUE FALTA PARA COMPLETAR EL ÁREA DE VENTAS

Antes del arqueo, que necesita que las mesas estén firmes:

| Pieza | Qué es |
|---|---|
| **Dividir la cuenta** | cuatro personas, cuatro pagos |
| **Mostrador** | un café para llevar **no es una mesa**. Hoy habría que cobrarlo abriendo una mesa que no existe. Anotado el 2026-08-31; no estaba en la lista |
| **Pulir precuenta y cerrar** | afinar el detalle que ve el cliente |

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
