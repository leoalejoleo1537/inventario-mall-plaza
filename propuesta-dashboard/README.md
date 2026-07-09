# Propuesta de dashboard (en construcción)

Mockups con **datos de ejemplo** para el nuevo apartado de análisis del inventario.
Aún no conectados a Supabase — sirven para decidir qué construir.

## Archivos
- `dashboard.html` — Panel de tendencias (podado): "Dónde se pierde plata"
  (quiebre + plata inmovilizada) y "Sándwiches por vencer". Con selector de
  ventana de tiempo (7/14/30 días) y toggle por producto/rubro.
- `calendario.html` — Agenda de pedidos "¿Qué pedir y para cuándo?": calcula
  qué pedir (bajo el mínimo), cuánto (hasta el máximo) y qué día (antes de
  tocar el mínimo), con anticipación configurable.

## Pendiente para seguir más tarde
- Conectar a datos reales (tabla `historial` + `fudo_pendientes`).
- Definir la anticipación real por proveedor (hoy es un supuesto simple).
- Recordar: las tendencias necesitan varias semanas de historial guardado.
