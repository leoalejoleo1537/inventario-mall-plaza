# Angamos — el episodio completo

> Sale del archivo madre `CLAUDE.md`, que se cargaba entero en cada sesión.
> Se separó el 2026-08-31 para dejar de pagar 69.000 tokens por sesión.
> **Las reglas duras siguen viviendo en `CLAUDE.md`.** Esto es historia cerrada: cómo se encendió la segunda sede.

---

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
