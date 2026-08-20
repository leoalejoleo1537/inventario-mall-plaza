# 03 · Manual de administración

> La zona de **Ajustes**: menú ☰ → Ajustes. Solo la ven las cuentas con permiso.
>
> Todo lo que antes había que pedirle a un programador vive acá.

---

## Quién entra

Es **un solo permiso**: se entra a Ajustes o no se entra. Quien entra tiene todo
lo administrativo, incluido escribirle a Fudo.

Se da desde **Ajustes → Personas y acceso**. Dos candados, y los dos son contra
el accidente:

- **Nadie puede quitarse el acceso a sí mismo.** Si el único que entra se apaga
  por error, hay que ir a Supabase a arreglarlo — o sea, el problema que esta
  pantalla viene a resolver.
- **No se puede dejar la lista en cero.**

> Si el interruptor dice que guardó y al recargar volvió a estar apagado, ver
> **04 · Reparaciones, caso 4**.

---

## Las diez secciones

### Interruptores

Encender y apagar funciones sin tocar código. **Apagar siempre devuelve lo que
había antes**, no deja un hueco.

Lo que **no** se puede apagar, a propósito: el respaldo de las 15:00 y 22:00, el
tope en cero del stock, y que un perecedero entre por fechas. Ahí "apagar" sería
quitar la red.

### Productos

- **Encender y apagar productos.** Lo que se apaga desaparece de la app **y de
  Fudo** — pero solo se apaga en Fudo lo que ya no se podría hacer: si el
  producto tiene su gemelo en otro mueble y ese sigue activo, el mesón lo puede
  seguir vendiendo.
- **Juntar duplicados.** Propone los pares por nombre y muestra qué va a pasar
  antes de hacerlo. Se puede deshacer.

> **Apagar no borra.** Un producto apagado conserva su historial y se vuelve a
> encender cuando se quiera.

### Secciones y turnos

Crear, borrar y reordenar secciones con flechas, mover productos entre ellas, y
decidir cuáles se cuentan en la mañana y cuáles en la tarde.

> Una sección **solo se puede borrar cuando está vacía**. Si tiene productos, la
> app dice cuántos y no la borra: dejarlos sin sección los escondería del conteo.

### Relaciones

Las tres relaciones que la app no sabía editar:

| | |
|---|---|
| **Pares vitrina / congelador** | Cuando el mismo producto vive en dos muebles, el sistema los suma. Lo deduce del **nombre**: le quita "Vitrina" o "Congelador" del final, y si lo que queda coincide, suman. Un nombre mal puesto rompe la suma sin que se note |
| **Bodega ↔ local** | Qué producto del local recibe lo que sale de bodega |
| **Categorías de Fudo** | Qué sección nuestra corresponde a cada categoría de Fudo. Sirve **solo** para que en la portada de Recetas los productos sin receta salgan agrupados con los nombres que el equipo reconoce |

### Metas de venta

Un objetivo con premio y fecha. Las dos sedes compiten en una barra que se ve
arriba del inventario.

**Cerrar** una meta la saca del inventario y se puede reabrir. **Eliminar** la
borra para siempre.

### Personas y acceso

Ver arriba.

### Fudo

Las dos perillas del puente, por sede:

| | |
|---|---|
| **Descuenta de verdad** | `real` = cada venta baja el stock. `prueba` = las ventas se anotan pero el stock no se toca |
| **Vigilar el reloj** | Si está encendido y el reloj deja de correr, la app avisa. **No es el reloj**: es la alarma |

Y abajo, cuándo corrió la última vez, cuántos ítems leyó y cuántos fallaron.

> **Bajar de real a prueba es lo único de esta pantalla que apaga algo que está
> funcionando**, y por eso pregunta nombrando la consecuencia.

### Respaldos

Ver los días con foto y **volver una sede a como estaba ese día**.

Muestra **producto por producto** qué cambiaría antes de tocar nada, y se puede
deshacer.

> Antes de restaurar, guarda una foto de hoy. Restaurar sobre un estado sin
> respaldar es cómo un incidente se convierte en dos.

### Actividad

Quién hizo qué y cuándo, de los últimos 30 días: mermas, empujes a Fudo,
fusiones, restauraciones. **Solo lectura**, a propósito: un registro donde se
puede borrar una línea no sirve de registro.

### Salud del sistema

- **El motor, por sede** — si dice "revisar", Fudo puede estar vendiendo con
  números viejos
- **Recetas** — cuántas hay y cuántas apuntan a un producto que ya no existe
- **El tope de las 1.000 filas** — cuánto le falta a cada tabla para cruzarlo

---

## Empujar el stock a Fudo a mano

Dentro de **Ajustes → Fudo**, la zona con la franja roja. Es la única parte de
la app donde el rojo manda: lo que se hace ahí sale del sistema y toca Fudo.

**Nada se escribe de un toque.** El botón abre una revisión que muestra qué
sube y qué baja, y el botón que aplica **dice el número**: "Sí, actualizar 58
productos", no "Confirmar". Cancelar va abajo y en gris — el camino peligroso
nunca es el más cómodo.

Todo queda anotado con el valor anterior, y **el último envío se puede
deshacer**.

---

## Lo que sigue viviendo en SQL

No todo está en la app, y es a propósito:

| | Por qué |
|---|---|
| El motor de descuento | Un botón que cambia cómo se descuenta es un botón que puede romper el inventario en silencio |
| La estructura de la base | Crear tablas y columnas |
| Los relojes | Se agendan una vez |

Para todo eso está la carpeta `sql/` en GitHub, con su índice.
