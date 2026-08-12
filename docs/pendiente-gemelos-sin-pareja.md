# Pendiente — los productos de bodega que quedaron sin gemelo

*Escrito el 2026-08-12 para poder llevarlo a otra conversación sin arrastrar
todo el contexto. Autocontenido a propósito.*

---

## El problema, en cuatro frases

La bodega (sede interna **`central`**) tiene 234 productos activos. Cada uno
necesita saber cuál es "el mismo producto" en Mall Plaza (`plaza`) y en Parque
Angamos (`angamos`), para que un reparto sepa a qué producto sumarle al llegar.

Esa equivalencia vive en la tabla **`producto_enlace`**, que guarda
`producto_bodega_id` + `sede` + `producto_sede_id`. **Son ids, no nombres.**

Ya están escritos **290 pares**: 144 con Angamos y 146 con Plaza. Se
propusieron comparando nombres exactos (sin tildes, mayúsculas ni espacios de
más) y se escribieron por id.

**Falta emparejar el resto**, y esos ya no se pueden adivinar por nombre.

---

## Qué falta exactamente

### 1. Los que se llaman distinto en bodega y en el local

Unos 76 productos de bodega no calzan por nombre con ninguno de los dos
locales. Buena parte **no son productos exclusivos de bodega**: son el mismo
producto escrito de otra forma. Ejemplos reales:

| En bodega | Probablemente es |
|---|---|
| `Cinnamon rolls` · `Rollos de canela` | `Cinnamon rolls vitrina` en Plaza |
| `Muffin chips de vainilla` | `Muffin vainilla chips` |
| `Macarones` · `Macarrons` | `Macarrons Vitrina de dulces` |
| `T. Cheesecake Mara` | `T. Cheesecake Maracuya` |
| `Jarabe Almendra`, `Jarabe Canela`, `Jarabe de coco`… | los `Syrup …` |
| `Pizza peperoni` | `Pizza pepperoni` |
| `Pan Foccacia Aceituna` | `Pan Focaccia Aceituna` |

Ojo: **varios de estos son duplicados dentro de la propia bodega** — la misma
cosa escrita dos veces, donde una grafía ya quedó emparejada y la otra sobró.
Antes de emparejarlos hay que decidir cuál nombre se queda. **Eso lo decide el
equipo, no un script.**

### 2. Los dos que se perdieron entre el informe y la escritura

El informe propuso **148** pares para Plaza y se escribieron **146**. Los dos
que faltan no se rompieron: **nunca llegaron a escribirse**, porque entre que
se propusieron y que se escribieron alguien renombró esos productos en Plaza
(el 11 de agosto se renombró una veintena, agregando los sufijos `Vitrina` y
`Congelador`), y dejaron de calzar por nombre.

**No están identificados por nombre**, y averiguar exactamente cuáles eran es
arqueología: el informe no se guardó. **Lo útil no es encontrar esos dos, sino
la lista completa de lo que hoy sigue sin gemelo** — que los incluye.

### 3. Los pares vitrina / congelador

En Mall Plaza varios productos están duplicados a propósito: uno en el
Congelador y su gemelo en la Vitrina (`Mini muffin Congelador` / `Mini muffin
Vitrina`). Bodega tiene uno solo, con el nombre plano.

**REGLA DE JHON (2026-08-12): lo que viene de bodega entra SIEMPRE al
congelador.** `producto_enlace` solo admite un gemelo por sede, y ese gemelo
es el del congelador. Apuntar a la vitrina sumaría stock a un estante que
nadie llenó.

Ya se corrigió el único par escrito que apuntaba mal: `Alfajor artesanal`
apuntaba a la vitrina (#76) y debía apuntar al congelador (#687).

---

## La consulta que da la lista de trabajo

Solo lectura. Devuelve, por sede, los productos de bodega que todavía no
tienen gemelo, junto a los candidatos que existen en ese local con un nombre
parecido — incluidas las variantes `Vitrina` / `Congelador`.

```sql
with faltan as (
  select p.id, p.producto, p.rubro
  from public.productos p
  where p.sede='central' and p.activo='SÍ'
),
locales as (select unnest(array['plaza','angamos']) as sede)
select l.sede,
       f.producto as en_bodega,
       f.id       as bodega_id,
       coalesce(string_agg(s.producto || ' [#' || s.id || ']', '  |  '
                  order by s.producto), '(ningún candidato)') as candidatos_en_el_local
from faltan f
cross join locales l
left join public.productos s
       on s.sede = l.sede and s.activo='SÍ'
      and public.clave_nombre(regexp_replace(s.producto,'\s+(vitrina|congelador)$','','i'))
          like '%' || left(public.clave_nombre(f.producto), 6) || '%'
      and not exists (select 1 from public.producto_enlace e2
                       where e2.sede = l.sede and e2.producto_sede_id = s.id)
where not exists (select 1 from public.producto_enlace e
                   where e.producto_bodega_id = f.id and e.sede = l.sede)
group by l.sede, f.id, f.producto
order by l.sede, f.producto;
```

> El `like` con las primeras 6 letras es a propósito **flojo**: acá sí se
> quiere ver candidatos de más, porque el que decide es una persona. Lo que no
> se hace nunca es escribir un par por parecido sin que alguien lo confirme.

---

## Las reglas que hay que respetar al resolverlo

1. **El enlace se guarda por id.** El nombre solo sirve para proponer, una vez.
   Renombrar un producto no rompe un enlace ya escrito.
2. **No se toca nada en `plaza` ni en `angamos`.** Ni apagar, ni renombrar, ni
   crear. La depuración de esos catálogos la hace Jhon. Lo único que se escribe
   es `producto_enlace`, que es la libreta de bodega.
3. **La bodega vieja (`sede = 'bodega'`) no se toca.** Es otra sede, oculta del
   portal, con el historial del incidente del 9 de agosto.
4. **Nunca emparejar por parecido sin confirmación humana.** Ya falló donde más
   caro salía: se propuso `Croissant manjar` para `Croissant Jamon Queso`, que
   era insumo de once recetas.
5. **Un producto de bodega tiene un solo gemelo por sede**, y un producto del
   local viene de un solo producto de bodega. La base lo impone con dos
   restricciones únicas.
