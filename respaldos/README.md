# Respaldos

Acá van las copias de los datos que **no se pueden volver a generar**.

## Por qué existe esta carpeta

En el plan gratuito de Supabase no hay punto de restauración. Y el modo de
trabajo del proyecto es generar líneas `update` y pegarlas a mano en el editor:
un `where` que se quedó fuera al copiar cambia 200 filas de una vez y no hay
marcha atrás.

Esto **no reemplaza** al respaldo diario del plan Pro. Es el piso: si un día se
pierde todo, en vez de partir de cero se parte de acá.

## Dónde se guardan de verdad

**En Notion, en la página del proyecto.** Esta carpeta del repositorio existe
como espejo opcional, no como el lugar principal.

La razón es práctica: Jhon trabaja en Notion y en el panel de Supabase, no con
una copia del repositorio en su computador. Un respaldo que hay que subir a
GitHub para guardarlo es un respaldo que no se va a hacer todos los meses, y
uno que se hace en Notion sí. Para lo que tiene que cumplir un respaldo —estar
fuera de Supabase, tener fecha, y poder encontrarlo dentro de seis meses—
Notion cumple igual.

Si algún día el proyecto pasa a trabajarse desde un clon local, subirlos acá
también es mejor, porque quedan junto a las instrucciones de restauración y con
historial de versiones.

## Cómo se hace uno

Correr `sql/2026-07-respaldo-para-guardar.sql` en Supabase → SQL Editor. Está
todo explicado adentro, paso por paso. Son unos 5 minutos.

Salen 4 archivos, que se guardan con la fecha en el nombre:

```
productos-2026-07-30.csv
recetas-2026-07-30.csv
receta-items-2026-07-30.csv
producto-lotes-2026-07-30.csv
```

El bloque 6 del mismo archivo da, además, un `restaurar-AAAA-MM-DD.sql` con
todo en un solo texto listo para volver a cargar.

## Cuándo

- **Una vez al mes**, junto con el chequeo de salud.
- **Antes de cada tanda de renombres** o de cualquier `update` masivo pegado a
  mano. Esa es la operación que puede perder datos, y es la única que se hace
  sin red.

## Qué se respalda y qué no

| Tabla | Se respalda | Por qué |
|---|---|---|
| `productos` | Sí | El catálogo y el stock del momento |
| `recetas` | Sí | El enlace con Fudo |
| `receta_items` | Sí | **Lo más caro de rehacer**: qué descuenta cada venta |
| `producto_lotes` | Sí | Las fechas de vencimiento |
| `fudo_movimientos`, `historial`, `fudo_stock_push` | No | Son registro. Se pueden perder sin que el sistema deje de funcionar |
| `fudo_productos` | No | Se vuelve a traer con la sync de catálogo |

## Dos cosas que hay que saber al restaurar

1. **Los identificadores van incluidos, y tienen que ir.** Las recetas se unen
   con los productos por ID, no por nombre. Restaurar sin los ids deja todas las
   recetas apuntando al vacío.
2. **El archivo reajusta los contadores al final.** Sin eso, el siguiente
   producto que alguien cree en la app choca con un id ya usado.

## Comprobado

El generador se probó contra un Postgres local: se respaldó, se vaciaron las
tablas, se restauró, y quedó todo igual — incluidos nombres con tildes, comillas
y símbolos, los enlaces receta → producto por id, y el contador, que después de
restaurar sigue entregando ids nuevos sin chocar.

Eso valida el mecanismo. **Lo que no valida es el contenido**: al terminar un
respaldo hay que abrir `receta-items` y mirar que las dos columnas de nombre
vengan llenas. Una vacía es una receta apuntando a un producto que ya no existe
— eso se arregla ahora, no el día del incendio.
