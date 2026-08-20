# La carpeta `sql/` — qué es cada cosa

> **Lee esto antes de correr nada.** Son 105 archivos y **la mayoría ya no se
> vuelve a correr**: son el registro de cómo se construyó el sistema, no una
> lista de tareas.

## La regla que evita el peor error

**Que un archivo esté acá NO significa que esté aplicado en la base**, y al
revés: la base cambió muchas veces desde la app, sin dejar rastro acá. Antes
de afirmar algo sobre el estado de los datos, **se consulta con un SELECT**.

Eso no es teoría: en julio el sistema estuvo **15 horas leyendo ventas sin
descontar nada**, mostrando "✓" en la pantalla, porque se dio por corrido un
archivo que estaba en el repo y nunca se había ejecutado.

Para saber qué se corrió de verdad existe la tabla **`migraciones_aplicadas`**:
cada script se anota solo al final. No es perfecta —hay cosas viejas sin
anotar— así que **sirve para saber qué SÍ se hizo, nunca para concluir que
algo no se hizo**.

---

## 1. Los que se corren UNA VEZ AL MES o cuando hace falta

Son de **solo lectura** salvo el respaldo. Estos cuatro son los que un dueño
nuevo va a usar de verdad:

| Archivo | Qué contesta | Cuándo |
|---|---|---|
| `2026-07-salud-del-sistema.sql` | **Corre solo el bloque 0**: 10 filas con el estado de todo — si el motor descuenta, si el stock cuadra con las fechas, si hay funciones duplicadas, a cuánto está cada tabla del tope de las 1000 filas | una vez al mes, y **siempre antes y después** de tocar el motor |
| `2026-07-respaldo-para-guardar.sql` | Saca los 4 CSV de respaldo (productos, recetas, receta_items, producto_lotes) | antes de cualquier tanda de cambios grande |
| `2026-07-auditoria-recetas.sql` | Qué productos de Fudo no tienen receta y cuáles apuntan al vacío | cuando la cobertura de recetas importe |
| `2026-07-revision-seguridad.sql` | Cómo están los permisos hoy. **Solo mira, no cambia nada** | curiosidad o auditoría |

## 2. Los cimientos — la base no existe sin ellos

Ya están corridos. Se listan porque **si algún día hay que levantar el sistema
en un Supabase nuevo, este es el orden**:

1. `2026-07-fase1-recetas-modo-prueba.sql` — recetas, `fudo_sync`, `fudo_movimientos` y el motor
2. `2026-07-fase3a-tabla-fudo-productos.sql` — el espejo del catálogo de Fudo
3. `2026-07-lotes-vencimiento.sql` — las fechas de vencimiento
4. `2026-07-secciones-inventario.sql` · `2026-07-tipo-de-producto.sql` · `2026-07-productos-urgentes.sql`
5. `2026-07-repartos.sql` — los repartos entre sedes
6. `2026-07-historial-dias.sql` — el historial agrupado por día
7. `2026-07-permisos-y-deshacer.sql` — `app_permisos` y la bitácora de empujes a Fudo
8. `2026-07-stock-para-fudo-v3-suma-el-par.sql` — el cálculo de cuánto se puede vender
9. `2026-07-tope-cero-sin-excepcion.sql` — **el stock nunca puede ser negativo**
10. `2026-07-registro-de-migraciones.sql` — el cuaderno
11. `2026-08-bodega-cimientos.sql` · `2026-08-bodega-nueva-desde-cero.sql` — la bodega
12. `2026-08-central-mermas.sql` · `2026-08-central-enlaces.sql` · `2026-08-central-reparto-descuenta.sql`
13. `2026-08-interruptores.sql` · `2026-08-ajustes-quien-entra.sql` · `2026-08-permisos-desde-la-app.sql` — la zona de Ajustes
14. `2026-08-metas-de-venta.sql` · `2026-08-secciones-y-fudo-desde-ajustes.sql`
15. `2026-08-respaldo-automatico-de-verdad.sql` — la foto de las 15:00 y las 22:00
16. `2026-08-ciclo-fudo-automatico.sql` — el reloj que sincroniza con Fudo

## 3. Los de emergencia — están acá porque el problema puede volver

| Archivo | Para cuándo |
|---|---|
| `2026-08-restaurar-una-sede.sql` | una sede quedó mal y hay que devolverla a como estaba un día |
| `2026-08-fusionar-duplicados.sql` | el mismo producto cargado dos veces |
| `2026-07-URGENTE-dos-motores.sql` | quedaron dos versiones del motor conviviendo |
| `2026-07-URGENTE-falta-venta-at.sql` | el motor lanza excepción por una columna que falta |
| `2026-07-fechas-en-vivo-y-limpieza.sql` | el stock y las fechas no cuadran |
| `2026-08-apagar-reposicion-automatica.sql` | dejar apagado el traslado automático congelador→vitrina |

## 4. Todo lo demás — historia

Los `*-diagnostico-*`, `*-informe-*`, `*-angamos-*`, `*-central-*`,
`*-emparejador-*`, `*-probar-*` y las versiones viejas (`-v2`, `-CORTO`) son el
registro de una migración, una investigación o un incidente que ya pasó.
**No hay que correrlos.** Se guardan porque explican por qué algo está como
está, y porque el mismo problema puede volver con otra sede.

Dos que vale la pena leer aunque no se corran:

- `2026-08-angamos-INCIDENTE-diagnostico.sql` — el 9 de agosto Angamos quedó en
  cero y no se pudo recuperar porque **nunca se le había sacado una foto**. De
  ahí sale la regla más importante del proyecto.
- `2026-08-ciclo-por-que-no-responde.sql` — cómo se averigua si el reloj está
  corriendo de verdad.

---

## Cómo se corre uno

Supabase → **SQL Editor** → **New query** → pegar → **Run**.

Cada archivo empieza con cinco líneas que dicen dónde va, en cuántos bloques,
cuánto tarda, qué hace y qué hay que mirar del resultado. **Los bloques se
corren de a uno**, en orden, salvo que el archivo diga otra cosa.

Tres cosas del editor de Supabase que no son evidentes y ya costaron tiempo:

1. **Muestra solo el resultado de la ÚLTIMA consulta.** Un bloque con dos
   `select` entrega uno solo y el otro se pierde en silencio.
2. **No se puede crear una tabla y usarla en la misma corrida.**
3. **Un script muy largo, o con `$$`, falla sin llegar a ejecutarse** y el
   error habla de la API de Supabase, no de SQL. No hay que rediagnosticar el
   SQL: hay que partir el script.
