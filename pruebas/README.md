# Pruebas

Cerrar el pendiente "cero pruebas guardadas en el repo" (§6, bloque A).

## Por qué existe esta carpeta

Cada cambio del proyecto se probó — el reparto, el deslizador, los tipos, el
motor. Pero ninguna de esas pruebas quedó: se escribían, se corrían y se
borraban con la sesión. El costo no es teórico: el bug de `items.map(rowHTML)`
—cada fila repitiendo su propia sección— vivió semanas en producción, en toda
la app, y se encontró de casualidad.

Una prueba guardada vale más que una prueba buena que ya no existe.

## Cómo se corren

```
node pruebas/alarma-de-ventas.mjs
```

Sin dependencias: Node y nada más. Si una falla, el comando termina con error y
dice qué caso falló.

## Qué hay

| Archivo | Qué protege |
|---|---|
| `alarma-de-ventas.mjs` | Que la alarma del motor suene cuando tiene que sonar, y **que no suene cuando no** — que es la mitad que suele no probarse. Incluye el caso real de Mall Plaza (1685 ítems, cero errores) y el de releer ventas ya procesadas, que da 0 movimientos y es normal. |

## La regla que hace que esto sirva

Las pruebas **leen el código de verdad**, no una copia. `alarma-de-ventas.mjs`
extrae `juzgarVentas()` de `index.html` y la evalúa. Si alguien cambia la
función, la prueba prueba la nueva — no una versión congelada que ya no
corre en producción.

Eso viene de la lección más cara del proyecto (§0.5): *una prueba contra algo
que uno mismo construyó no valida nada.* Aplica igual acá: una prueba contra
una copia del código no prueba el código.

## Lo que estas pruebas NO cubren

- **El encaje con la base real.** Eso lo contesta `sql/2026-07-salud-del-sistema.sql`.
- **Que un `.sql` esté aplicado en producción.** Eso lo contesta el cuaderno
  `migraciones_aplicadas`.
- **La pantalla.** Todavía no hay pruebas de interfaz guardadas; se corren a
  mano con un navegador y un Supabase simulado. Es lo siguiente que conviene
  guardar acá, sobre todo antes de partir `index.html` en varias páginas.
