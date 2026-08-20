# Cómo pasar esto a Notion

> Ocho páginas listas para pegar. Notion entiende este formato: al pegar, los
> títulos, las tablas, los bloques de código y las casillas se convierten solos.

---

## El orden

1. En Notion, abre tu página **Inventario**.
2. Pega el contenido de **`00-INDICE.md`**. Esa pasa a ser la portada.
3. Por cada uno de los otros siete archivos:
   - escribe `/page` y crea una subpágina,
   - ponle de título la primera línea del archivo (por ejemplo *04 · 🚑 Reparaciones*),
   - abre el archivo, **copia todo menos esa primera línea**, y pega adentro.
4. En la portada, enlaza las siete con `@` y el nombre.

> **Truco:** si pegas y Notion te pregunta cómo pegarlo, elige
> **"Pegar como texto enriquecido"** o simplemente `Ctrl/Cmd + V` normal.
> Con `Ctrl/Cmd + Shift + V` pega en crudo y pierde el formato.

---

## Las ocho páginas

| Archivo | Página | Para quién |
|---|---|---|
| `00-INDICE.md` | 🦙 Llamita — Central de conocimiento | portada |
| `01-que-es-llamita.md` | Qué es Llamita | todos |
| `02-manual-de-uso.md` | Manual de uso | el mesón |
| `03-manual-de-administracion.md` | Manual de administración | administración |
| `04-reparaciones.md` | 🚑 Reparaciones | quien tenga que arreglar algo |
| `05-levantar-desde-cero.md` | 🔥 Levantar Llamita desde cero | el peor caso |
| `06-las-llaves.md` | Las llaves y las cuentas | quien recibe el proyecto |
| `07-las-reglas.md` | Las reglas que no se tocan | quien vaya a programar |
| `08-registro-de-respaldos.md` | Registro de respaldos | administración |

---

## Lo que hay que llenar a mano, porque yo no lo sé

Estas son las únicas cosas que quedan en blanco. Son datos tuyos:

### En **06 · Las llaves**
- El nombre del proyecto de Supabase y quién es dueño de la organización
- La dirección web de la app
- El dueño y el nombre del repositorio de GitHub
- El usuario de cada panel de Fudo

> **Las contraseñas no van escritas en Notion.** Van en un gestor de
> contraseñas. En Notion va solo *dónde* está cada cosa.

### En **08 · Registro de respaldos**
- Crear la tabla de Notion con las columnas que indica
- Correr `sql/2026-07-respaldo-para-guardar.sql` una vez y **adjuntar los cuatro
  CSV a la primera fila**. Ese es el respaldo del día cero

---

## Un consejo sobre cómo mantenerlo

**Actualiza el mismo día que cambies algo importante.** Una página de estado que
envejece engaña más que no tenerla: alguien la va a leer con toda confianza y va
a planificar sobre algo que ya no existe.

Eso ya pasó una vez en este proyecto y costó una jornada.
