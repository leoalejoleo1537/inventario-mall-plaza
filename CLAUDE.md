# Inventario Café del Desierto — Archivo Madre

> **Para Claude:** Lee este archivo completo al inicio de cada sesión. Es el hilo
> conductor del proyecto. Si algo que vas a hacer contradice lo que dice aquí,
> detente y confírmalo con Jhon antes. Cuando cerremos un cambio importante,
> **actualiza este archivo** (sección "Bitácora").

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
   En la app: botón **"↻ Productos de Fudo"** en la vista Recetas.
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
   - En la app: botón **"Actualizar inventario"** (barra naranja fija).
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
- Inventario por sede, secciones, métricas (crítico / en rango / sin dato).
- Recetas con buscador (no desplegables gigantes) y campo `aplica`.
- Sync de ventas y de productos desde botones en la app.

**Pendiente / en veremos:**
- [ ] **Cron automático** de `fudo-sync-ventas` cada 15 min (SQL listo en
      `sql/2026-07-cron-automatico-ventas.sql`, falta activarlo en Supabase → Cron).
- [ ] **Push de stock a Fudo** para combos: calcular el mínimo entre insumos y
      empujarlo a Fudo cuando cambie el inventario.
- [ ] Marcar "para llevar" vs "servir" en el front de Fudo para que el `aplica` sirva.
- [ ] **Depurar recetas (PRIORIDAD — va antes del dashboard).** Plan en
      `docs/auditoria-recetas.md`; informe de solo lectura en
      `sql/2026-07-auditoria-recetas.sql`. La métrica de avance es el % de
      cobertura (bloque 9): anotarlo antes y después de cada tanda.
- [ ] **Dashboard**: lista de análisis posibles en `docs/dashboard-analisis-posibles.md`.
      NO empezar hasta cerrar la depuración de recetas.
- [ ] Guardar la fecha REAL de la venta en `fudo_movimientos` (hoy se guarda cuándo
      corrió la sync, no cuándo se vendió). Bloquea los análisis de demanda.
- [ ] Confirmar con jefatura que van a usar el sistema (vs. volver al Excel).

---

## 7. Bitácora (cambios importantes, lo más reciente arriba)

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
