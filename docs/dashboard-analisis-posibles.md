# Dashboard — análisis posibles con los datos que ya tenemos

> Lista de trabajo, **no construida todavía**. Se hizo el 2026-07-25 después de
> revisar qué guarda cada tabla. Antes de construir esto hay que cerrar la
> depuración de **recetas** (ver `docs/auditoria-recetas.md`).

## Datos disponibles

| Tabla | Qué guarda | Habilita |
|---|---|---|
| `productos` | stock actual, mínimo, máximo, sección, sede, perecedero, `updated_at` | la foto de ahora |
| `producto_lotes` | cantidad + fecha de vencimiento | todo lo de vencimientos |
| `historial` | fotos diarias del stock (guardadas a mano) | tendencias |
| `fudo_movimientos` | cada descuento: insumo, cantidad, venta de origen | demanda y consumo |
| `fudo_productos` | catálogo de Fudo **con precio de venta** | ingresos aproximados |
| `recetas` / `receta_items` | qué insumo descuenta cada producto | cruces receta↔consumo |
| `fudo_pendientes` | lo que llegó y falta subir a Fudo | salud operativa |

## Límites conocidos (leer antes de diseñar)

1. **La fecha de las ventas no es exacta.** `fudo_movimientos.created_at` es cuándo
   se corrió la sincronización, no cuándo ocurrió la venta. Con el botón manual,
   dos días sin sincronizar amontonan todo el consumo en un instante.
   → Arreglo: guardar el `createdAt` real que Fudo ya manda + activar el cron.
2. **No hay costo de insumos.** `fudo_productos.precio` es precio de VENTA del
   producto de Fudo, no el costo del insumo. Por eso **no** se puede calcular
   "plata inmovilizada" ni el valor de la merma. Faltaría una columna de costo.
3. **El historial es manual.** Sin el hábito de guardarlo a diario, las tendencias
   tienen huecos. Se necesitan varias semanas acumuladas.
4. **El `saleType` no se guarda.** El motor lo usa para decidir el descuento, pero
   no queda registrado, así que hoy no se puede analizar "para llevar vs servir".

---

## A. Foto de ahora — se puede hoy

1. % del total en crítico, por sede.
2. **% en crítico por sección** ("40% de Sándwiches, 18% de Congelador").
3. % en sobre-stock, total y por sección.
4. Ranking de secciones de peor a mejor salud.
5. Productos en cero (quiebre real, distinto de "bajo el mínimo").
6. Productos sin dato (nunca contados).
7. Las 3 sedes lado a lado con la misma métrica.
8. Calidad del inventario: cuántos productos tienen mínimo definido y cuántos no
   (un mínimo vacío hace que el semáforo mienta).

## B. Vencimientos — se puede al correr el SQL de lotes

9. Qué vence hoy / mañana / esta semana, con cantidad y sección.
10. Vencidos que siguen en stock.
11. Unidades en riesgo a 3 y 7 días.
12. Secciones con más urgencia de vencimiento.

## C. Demanda y consumo — con la salvedad del límite 1

13. Producto más vendido en 24 h / 7 días / 30 días.
14. Insumo más descontado (≠ producto más vendido: un insumo vive en varias recetas).
15. Consumo promedio diario por insumo — base de casi todo lo demás.
16. ⭐ **Días de cobertura**: stock ÷ consumo diario ("quedan 2,3 días de vasos").
17. Productos de Fudo vendidos SIN receta — fugas del motor.
18. Ingresos aproximados por producto (cantidad × precio de Fudo; sin promociones).

## D. Tendencia — necesita historial acumulado

19. Evolución del stock de un producto en el tiempo.
20. ⭐ Días en crítico por producto ("el vaso 12 oz estuvo en rojo 9 de 30 días").
21. Crónicamente en crítico → el mínimo está mal puesto o se pide poco.
22. Crónicamente en sobre-stock → se pide de más.
23. Rotación: cuántas veces se renovó el stock.

## E. Operación — mide si el sistema se está usando

24. Días sin guardar historial.
25. Productos sin tocar hace X días (`updated_at`).
26. Pendientes de actualizar en Fudo acumulados.
27. Recetas vacías / productos de Fudo sin receta.
28. Sedes en modo prueba vs real (una en prueba = su stock no se descuenta).

## F. Reposición — lo más valioso para Adriana

29. Qué pedir y cuánto (bajo el mínimo → completar hasta el máximo).
    Mockup en `propuesta-dashboard/calendario.html`.
30. ⭐ Cuándo va a tocar el mínimo, proyectando el consumo.
31. Pedido agrupado por total entre secciones (Brownie = 14, no 9 + 5).

---

## Orden sugerido

1. **A + B** — datos confiables hoy, responden lo que se preguntó.
2. **#16 y #30** — los que de verdad cambian una decisión.
3. **C y D** — después de guardar la fecha real de la venta y activar el cron.
   Sin eso, un gráfico de "ventas por hora" se vería bien pero mentiría.
