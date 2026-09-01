# Inventario Café del Desierto — Archivo Madre

> **Para Claude:** este archivo se carga solo, entero, en cada sesión. Es el hilo
> conductor del proyecto. Si algo que vas a hacer contradice lo que dice acá,
> detente y confírmalo con Jhon antes.

---

## ⚠️ ANTES DE PLANIFICAR: los archivos que NO se cargan solos

Este archivo tenía 4.114 líneas y se cargaba entero, siempre: **69.000 tokens
por sesión**, la mayoría historia que casi nunca hacía falta. El 2026-08-31 se
partió. Lo que quedó acá son **las reglas duras**, que sí se leen siempre.

**Lo demás vive en `docs/` y NO llega solo. Hay que abrirlo a mano.**

| Si vas a… | Leé ESTO antes, completo | Líneas |
|---|---|---|
| **tocar cualquier cosa de Llamita Lama** | **[`docs/LAMA.md`](docs/LAMA.md)** | 427 |
| **replicar una pantalla de Fudo** | **[`docs/atlas-fudo.md`](docs/atlas-fudo.md)** — cómo se comporta lo que estamos copiando. Lo que siga en `⬜ PENDIENTE` **se pregunta, no se inventa** | — |
| **dejar un `.sql` nuevo listo para Jhon** | agregarlo a **[`docs/sql-pendientes.md`](docs/sql-pendientes.md)** — es el único lugar donde se sabe qué falta correr | — |
| tocar la pantalla | [`docs/DECISIONES-ESTETICA.md`](docs/DECISIONES-ESTETICA.md) | — |
| entender por qué algo quedó como quedó | [`docs/bitacora.md`](docs/bitacora.md) | 981 |
| arreglar algo que huele a ya resuelto | [`docs/soluciones.md`](docs/soluciones.md) | 153 |
| abrir una sede nueva | [`docs/angamos.md`](docs/angamos.md) | 837 |

> **Un índice adentro de un `CLAUDE.md` no ahorra nada**, porque el archivo ya
> está cargado cuando lo leés. El ahorro está en que estos cinco archivos **no**
> son `CLAUDE.md` y por eso no se cargan solos. El precio es que hay que
> acordarse de abrirlos: **si el trabajo es de Lama y no leíste `docs/LAMA.md`,
> estás planificando a ciegas.** Ya pasó una vez, con la §9 de Angamos.

**Y al cerrar un cambio importante, la bitácora se actualiza en
`docs/bitacora.md`, no acá.**

---

## ÍNDICE

> **Las secciones 0 a 0.9 se leen SIEMPRE** — son duras, salen de fallas
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
| **8** | Catálogo de soluciones → **`docs/soluciones.md`** | antes de "arreglar" algo |
| 9 | Encender una sede nueva → **`docs/angamos.md`** | otra sede |
| 9.7 | Cómo se armaron las recetas de Angamos → **`docs/angamos.md`** | armar recetas |
| 10 | Insumos a granel (té, café, naranja) | el trabajo de medición |
| 10.1 | El doble descuento del conteo nocturno | mesas abiertas |
| **11** | Bitácora → **`docs/bitacora.md`** | entender una decisión vieja |
| **12** | **LLAMITA LAMA → `docs/LAMA.md`** (su archivo madre) | **empezar una sesión de Lama** |

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

### MEDIDO EN EL LOCAL — 2026-09-01. El puente es obligatorio

Hasta acá lo de arriba era razonamiento. Esto es la prueba, hecha con
`impresora-prueba.html` en el Chrome del computador del local.

| Pregunta | Respuesta medida |
|---|---|
| ¿El navegador VE la impresora? | **Sí.** `Printer-80`, fabricante `Printer` |
| Su identidad | **vendorId `0x1FC9` · productId `0x2016`** |
| ¿Puede abrirla por USB? | **NO.** `SecurityError — Access denied` en `open()` |
| ¿Aparece como puerto serie? | **NO.** Ningún COM de la máquina es la impresora — se abrieron, se escribió, y **el papel no se movió** |

**Las dos puertas del navegador están cerradas, y con datos.** El USB falló
**antes de intentar imprimir**, al abrir el dispositivo. Y por serie se probó
lo mínimo posible —despertar y avanzar papel, diez bytes, sin texto ni corte—
justamente para que un resultado en blanco no admitiera dos lecturas: si el
rollo no se mueve, no le estamos hablando.

**Todo esto costó un rato en el local, no dos meses de puente a medio hacer**
(§0.5).

### ⚠️ NO es Fudo el que no suelta la impresora — es Windows, y nunca la suelta

Jhon lo interpretó así al medirlo, y es la conclusión natural: *"Fudo no ha
terminado de soltar la impresora"*. **No es eso**, y la diferencia decide el
diseño entero:

- Windows toma la impresora con su driver **al instalarla**, y se queda con
  ella. No es un préstamo temporal.
- **Fudo no se apodera del aparato**: le pide a Windows que imprima. Por eso
  su programa convive con el driver en vez de pelearlo.
- Cerrar Fudo, entonces, **no libera nada**. No hay nada que esperar.

**Y acá está la salida, que es lo contrario de lo que uno intenta primero:**
si Windows no comparte la impresora pero sí imprime cuando se lo piden, el
puente **no tiene que quitarle el aparato — tiene que pedírselo**. Se le
mandan los bytes ESC/POS crudos a la cola de impresión de Windows, con el
driver que ya está puesto. Nada se desinstala y **Fudo sigue imprimiendo igual**.

⚠️ **Existe una forma de forzarlo y NO se hace:** cambiarle el driver a la
impresora en Windows (Zadig/WinUSB) dejaría que el navegador la tome — **y con
eso Fudo deja de imprimir.** Es romper el servicio del café para ganar una
comodidad nuestra. No se propone ni se prueba en el computador del local.

**Consecuencia de diseño, y hay que decirla ahora porque cambia el puente:**
si el garzón imprime desde el TELÉFONO, el puente no puede escuchar y ya está.
Una página en `https` no puede llamar a `http://192.168.x.x` — el navegador lo
bloquea por contenido mixto—, y `localhost` solo le sirve a ese mismo
computador. **La salida limpia es que el puente no reciba nada: que se
suscriba a Supabase y saque lo que aparezca.** Sin conexión entrante no hay
contenido mixto, ni firewall, ni IP fija que averiguar, y funciona desde
cualquier teléfono del local. Es el mismo tiempo real que ya usa la app.

### CÓMO QUEDA EL PUENTE, decidido con lo medido

Un programa chico en el computador del local que hace **dos cosas y ninguna
más**:

| | |
|---|---|
| **Escucha a Supabase** | se suscribe a una cola de impresión y espera. **No abre ningún puerto**: la conexión sale de él |
| **Le pide a Windows que imprima** | manda los bytes ESC/POS crudos a la cola de impresión, con el driver que ya está |

**Las tres cosas que esto evita**, y cada una era un problema real:

1. **No pelea con Windows por el aparato** — que es lo que acaba de fallar.
2. **No hay contenido mixto ni firewall**, porque nadie le habla de afuera.
3. **Funciona desde cualquier teléfono del local**, y desde fuera del local
   también, sin averiguar ninguna IP.

**Lo que cuesta, dicho sin adornos:** hay que instalarlo en ese computador y
dejarlo arrancando con Windows. Es una visita al local, y **es la misma visita
que Fudo ya te cobró** con su extensión y su aplicación. No hay una versión de
esto sin programa instalado: eso es justo lo que se acaba de medir.

**Y va aislado**, sin tocar la app ni la base, como pide el orden de trabajo de
más abajo: si falla, que falle solo.

### Lo que ya está resuelto y no hay que volver a hacer

- **La impresora está instalada y funcionando.** No hay que configurarla, ni
  averiguar su IP, ni el truco del FEED al encender.
- **Habla ESC/POS**, que es el estándar que el propio Fudo exige. Nuestro
  código le hablaría el mismo idioma.
- Modelo: **Xprinter XP-N160II**, térmica de 80 mm.
- La página de prueba queda en el repo (`impresora-prueba.html`) y sirve para
  repetir la medición en otro local o con otra impresora.

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

## ✅ Angamos quedó encendida (2026-08-05)

> **Se mudó a [`docs/angamos.md`](docs/angamos.md).** No está acá para no cargarlo en
> cada sesión. **Leelo cuando necesites el detalle de esa puesta en marcha.**

Episodio cerrado. El procedimiento reutilizable está en el mismo archivo.

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

> **Se mudó a [`docs/soluciones.md`](docs/soluciones.md).** No está acá para no cargarlo en
> cada sesión. **Leelo cuando te topes con un problema que huele a ya resuelto.**

Recetario de problemas resueltos, con el arreglo que funcionó.

## 9. Encender una sede nueva

> **Se mudó a [`docs/angamos.md`](docs/angamos.md).** No está acá para no cargarlo en
> cada sesión. **Leelo cuando haya que abrir una sede.**

El procedimiento completo, salido del caso Angamos.

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

## 11. Bitácora

> **Se mudó a [`docs/bitacora.md`](docs/bitacora.md).** No está acá para no cargarlo en
> cada sesión. **Leelo cuando necesites saber por qué algo quedó como quedó.**

Historia: qué se cambió, cuándo y con qué razón. Al cerrar un cambio importante, **se anota ahí**, no acá.

## 12. LLAMITA LAMA — el hermano grande

> **Se mudó a [`docs/LAMA.md`](docs/LAMA.md).** No está acá para no cargarlo en
> cada sesión. **Leelo cuando vayas a tocar cualquier cosa de Lama, y ANTES de planificar.**

Lama es el área de ventas —mesas, comandas, cobro—. Está escondida (`app_permisos.puede_lama`, apagada para todos menos una cuenta) y **no toca el inventario**. Su archivo madre es `docs/LAMA.md`.
