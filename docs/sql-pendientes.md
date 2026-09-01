# SQL pendientes de pegar en Supabase

> **Para qué existe.** El SQL llegaba en mensajes de chat, y entre varios se
> te confundía cuál ya habías corrido y cuál no. Este es **el único lugar**
> donde se sabe qué falta. Si algo no está acá, no está pendiente.
>
> **Las dos sesiones (Stock y Lama) agregan acá** apenas dejan un `.sql`
> nuevo listo para correr. Vos marcás `[x]` y la fecha cuando lo pegás — así
> ninguna de las dos vuelve a insistir en algo que ya hiciste.
>
> **El orden de la lista importa.** Si dos items dependen uno del otro, van
> en el orden en que hay que correrlos, y se dice por qué.

---

## Pendientes ahora

- [ ] **`sql/2026-08-lama-cierre.sql`** — el cierre de mesa: medios de pago,
  propina, descuento. **Va primero de los tres de Lama.**
- [ ] **`sql/2026-09-lama-anulacion.sql`** — anular un producto ya comandado.
  Depende del anterior: reemplaza una función que el de cierre crea.
- [ ] **`sql/2026-08-metas-cuentan-por-sede.sql`** — arregla el conteo de las
  metas de venta por sede (el error del agua Bosqua/Angamos). Es
  independiente de los dos de arriba, se puede correr cuando quieras.

## Cómo se marca uno como hecho

Cambiás el `[ ]` por `[x]` y agregás la fecha al final de la línea. Por
ejemplo:

```
- [x] `sql/2026-08-lama-cierre.sql` — el cierre de mesa… — corrido 2026-09-02
```

No hace falta que lo hagas vos a mano si no querés: decile a cualquiera de
las dos sesiones "ya corrí tal archivo" y ella lo marca acá.

## Historial (lo que ya se corrió y se sacó de la lista de arriba)

_(vacío por ahora — acá van quedando, para que la lista de pendientes no
crezca para siempre)_
