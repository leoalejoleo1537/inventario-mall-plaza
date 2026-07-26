# Inventario Café del Desierto — Archivo Madre

> **Para Claude:** Lee este archivo completo al inicio de cada sesión. Es el hilo
> conductor del proyecto. Si algo que vas a hacer contradice lo que dice aquí,
> detente y confírmalo con Jhon antes. Cuando cerremos un cambio importante,
> **actualiza este archivo** (sección "Bitácora").

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

**Checklist antes de entregar algo que toque datos:**
- [ ] ¿Verifiqué el estado real con un SELECT, o lo inferí de un archivo?
- [ ] ¿Lo que me pidieron era analizar o modificar?
- [ ] Si creo productos: ¿busqué primero si ya existen con otro nombre?
- [ ] ¿Estoy reportando algo como "bug" sin haberlo confirmado?
- [ ] ¿Alguna verificación falló en masa? → parar y decirlo.
- [ ] ¿Estoy proponiendo cambiar algo que el equipo decidió a propósito?

---

## 1. Qué es esto y para quién

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
- `bodega` — Bodega central

---

## 2. Estética — REGLAS DURAS (no negociables)

La estética es **la de Fudo**: limpia, sobria, funcional. NO inventar estilos nuevos.

- **Color primario:** naranja Fudo `--orange:#DC4405` (botones de acción, activos).
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

**Funcionando:**
- App instalable (PWA) con ícono real de Jhon.
- Inventario por sede, secciones, métricas (crítico / en rango / sin dato), buscador
  siempre visible que ignora los filtros.
- Recetas con buscador (no desplegables gigantes) y campo `aplica`.
- Un solo botón ⟳ que sincroniza catálogo + ventas y descuenta el stock.
- Probado en cafetería real (venta de pizza en Fudo → se descontó en la app).

**Pendiente / en veremos:**
- [ ] **Cron automático** de `fudo-sync-ventas` cada 15 min (SQL listo en
      `sql/2026-07-cron-automatico-ventas.sql`, falta activarlo en Supabase → Cron).
      Es lo que de verdad elimina la demora: hoy depende de apretar el botón.
- [ ] Correr la medición de demora real (bloque de `sql/2026-07-fecha-real-de-venta.sql`)
      después de unos días de uso, para saber si falta el cron o el retraso viene de Fudo.
- [ ] **Push de stock a Fudo** para combos: calcular el mínimo entre insumos y
      empujarlo a Fudo cuando cambie el inventario.
- [ ] Marcar "para llevar" vs "servir" en el front de Fudo para que el `aplica` sirva.
- [ ] **Combos de elección libre (ej. "3 masitas" a elección del cliente).** Sin
      resolver. Depende de si Fudo captura QUÉ eligió el cliente (modificadores) o
      no. Si no lo hace, la única forma de descontar exacto es cambiar el proceso
      de venta: registrar cada masita por separado en vez de un botón "combo".
      Ver sección 7 — este problema desaparece solo si migran a un POS propio.
- [ ] **Depurar recetas (PRIORIDAD — va antes del dashboard).** Plan en
      `docs/auditoria-recetas.md`; informe de solo lectura en
      `sql/2026-07-auditoria-recetas.sql`. La métrica de avance es el % de
      cobertura (bloque 9): anotarlo antes y después de cada tanda.
- [ ] **Dashboard**: lista de análisis posibles en `docs/dashboard-analisis-posibles.md`.
      NO empezar hasta cerrar la depuración de recetas.
- [ ] Confirmar con jefatura que van a usar el sistema (vs. volver al Excel).
- [ ] **Decisión grande pendiente: ¿avanzar hacia un POS propio?** Ver sección 7.

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
- **Fudo no tiene ningún programa instalado en el computador del local.** Corre
  100% en el navegador. La pestaña de Fudo abierta todo el día **ES** el mecanismo
  que mantiene la conexión con la nube y manda a imprimir — confirmado por Jhon
  ("si la cierro, deja de imprimir"). Esto valida el plan: nuestra futura interfaz
  de Caja, abierta en ese mismo navegador, cumpliría el mismo rol sin instalar nada.
  Sí es una regla operativa nueva a enseñar: esa pestaña no se cierra.
- **Antes de prometer nada de POS**, el primer paso técnico es un **prototipo
  aislado de impresión** (1-2 días): imprimir una comanda de prueba en esa Xprinter
  desde Supabase, sin tocar la app existente. Si falla, se sabe en 2 días y no en 2
  meses. Necesita: confirmar Windows en ese equipo, y si el cable de red llega hasta
  la impresora (si no, hay que sacarle la IP con el truco de FEED al encender).

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

## 8. Bitácora (cambios importantes, lo más reciente arriba)

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
