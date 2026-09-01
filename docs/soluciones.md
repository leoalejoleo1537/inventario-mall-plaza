# Catálogo de soluciones aplicadas

> Sale del archivo madre `CLAUDE.md`, que se cargaba entero en cada sesión.
> Se separó el 2026-08-31 para dejar de pagar 69.000 tokens por sesión.
> **Las reglas duras siguen viviendo en `CLAUDE.md`.** Esto es el recetario de problemas ya resueltos.

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
