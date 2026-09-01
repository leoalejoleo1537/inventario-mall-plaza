# Atlas de Fudo — cómo se comporta el sistema que estamos replicando

> **Para qué existe.** Llamita Lama copia a Fudo a propósito: el equipo ya sabe
> usar esa pantalla, y copiarla hace que no tengan que aprender nada. Pero
> hasta hoy *cómo es Fudo* no estaba escrito en ninguna parte — vivía en la
> cabeza de Jhon y llegaba al chat en fotos sueltas, una por tarea.
>
> **Eso es lo que hacía lento el trabajo.** Cada tarea empezaba de cero,
> reconstruyendo el modelo a partir de una captura. Este archivo lo escribe
> una vez.

---

## ⚠️ LO QUE ESTE ARCHIVO NO CONTIENE, Y ES LA MITAD

El atlas tiene dos mitades y **dos fuentes distintas**. Confundirlas es lo que
hacía que preguntar no rindiera:

| Mitad | De dónde sale | Dónde vive |
|---|---|---|
| **Cómo se comporta** — estados, reglas, qué pasa si… | el manual · NotebookLM | **este archivo** |
| **Cómo se ve** — disposición, medidas, colores, orden | solo de la pantalla corriendo | capturas + Inspeccionar en Chrome |

**Ningún manual dice cuántos píxeles de aire lleva un panel ni de qué naranja
es un botón.** Eso se mide con el botón derecho → Inspeccionar, sobre Fudo
abierto. Si una tarea necesita una medida y acá no está, **no se adivina: se
mide**.

## Cómo se usa

**Jhon:** copia la pregunta tal cual a NotebookLM, y pega la respuesta debajo,
donde dice `⬜ PENDIENTE`. No hace falta ordenarla ni resumirla — pégala como
venga. Se puede hacer de a una, a ratos, desde el teléfono.

**El chat de Lama:** esto se lee **antes** de construir cualquier pantalla del
área de ventas. Una pregunta que siga en `⬜ PENDIENTE` es un hueco conocido:
se pregunta, no se inventa.

**Y la regla que manda sobre todo lo de acá:** el manual va detrás del
producto. **Si el atlas contradice lo que se ve en pantalla, gana la
pantalla.** Cuando pase, se corrige acá y se anota la fecha.

## Cómo sacarle más a NotebookLM

- **Pídele tablas.** Una respuesta en prosa hay que volver a masticarla; una
  tabla se pega y ya sirve.
- **Una pregunta por vez.** Dos juntas se contestan a medias las dos.
- **Pídele que cite la fuente.** Sirve para saber qué es del manual y qué está
  rellenando.
- Si contesta con generalidades, insiste con: *"enumera, no expliques"*.

---

# LA PREGUNTA CERO — el plano de la mina

> Esta va **primero**, y contesta la pregunta que Jhon no sabía hacer: cuáles
> son las preguntas. No hay que adivinar dónde está el oro — el índice del
> material lo dice.

`
Hazme el índice completo de todo el material: cada sección y subsección, con
una línea de qué cubre. No expliques nada todavía, solo el índice.
`

⬜ Aquí tienes el índice completo y estructurado de todo el material que se encuentra en las fuentes, organizado por secciones y subsecciones, detallando en una línea el contenido de cada una:
1. ¡Primeros Pasos! (Configuración Inicial)
Creación y validación de la cuenta: Pasos iniciales para crear el usuario, validar el correo electrónico y completar el formulario de bienvenida
.
Configuración inicial de salón: Configuración física de salas, distribución de mesas y definición de áreas de impresión de comandas
.
Gestión básica de usuarios: Creación de las cuentas de acceso iniciales para el personal del restaurante
.
2. Sección 'Mi Cuenta' y Suscripciones
Seguridad y resguardo de la información: Creación de contraseñas seguras, administración de perfiles del personal y políticas de respaldo de datos
.
Planes y módulos de Fudo: Características técnicas de los planes Inicial, Avanzado y Pro, y el funcionamiento del Portal Multisucursal
.
Facturación del servicio y medios de pago: Configuración de los datos fiscales de cobro de suscripción y pasarelas de pago para Argentina, Chile y México
.
3. Sección 'Restaurante' (Operación del Salón)
Flujo de mesas: Procesos para abrir, adicionar consumos, aplicar descuentos, mover comandas y cerrar mesas
.
Operaciones rápidas de mostrador: Métodos de venta rápida mediante la interfaz de "Mostrador/Mesón" y "Mostrador Express"
.
Despacho a domicilio: Gestión, asignación y control de pedidos en modalidad de delivery tradicional
.
4. Sección 'Ventas' y Gestión de Caja
Movimientos de caja: Registros manuales de entradas o salidas de efectivo y asignación de cajas físicas a usuarios
.
Arqueos de caja: Guías operativas para realizar la apertura, cierre e impresión del arqueo de turno contable
.
Arqueo de caja 'Ciego': Herramientas para restringir y ocultar a ciertos usuarios la visualización del saldo teórico del sistema
.
Diferencias de caja: Diagnóstico y motivos frecuentes por los cuales el dinero físico no coincide con el balance del sistema
.
Administración de propinas: Activación, recepción digital (ej. Mercado Pago) y posterior liquidación para los camareros
.
5. Sección 'Gastos' y Cuentas de Proveedores
Registro de compras y gastos: Procesos para registrar pagos en efectivo o crédito por insumos o servicios operativos
.
Gastos con productos e ingredientes: Asociación de compras a inventario físico con discriminación de tasas impositivas
.
Gastos recurrentes e importación IA: Configuración de compras periódicas y carga digital de facturas mediante foto o archivos PDF
.
Cuentas corrientes de proveedores: Seguimiento de créditos, saldos pendientes y pagos a proveedores de insumos
.
6. Sección 'Productos', Recetas y Control de Stock
Administración de productos: Carga del menú de forma manual, importación masiva por Excel, y visualización de markup o ganancias
.
Opcionales y modificadores: Creación de ingredientes adicionales, especificaciones de preparación y grupos de modificadores
.
Fichas técnicas y recetas: Creación de recetas vinculadas a productos para el descuento proporcional de materias primas
.
Control automático de stock: Funcionamiento automático de stock frente a ventas, desperdicios, mermas y alertas de existencias bajas
.
Conteo de inventarios: Realización de conteos tradicionales y "ciegos" para conciliar el stock físico con el del sistema
.
Listas de precios: Gestión de tarifas alternativas o recargos según el canal de venta o tipo de cliente
.
7. Sección 'Clientes'
Fichero de clientes: Carga de perfiles, importación de bases de datos externas y borrado masivo de registros
.
Cuentas corrientes de clientes: Configuración de límites de crédito para consumo "en confianza" y registro de abonos
.
8. Sección 'Indicadores' (Métricas y Finanzas)
Evolución y Reporte de ventas: Análisis de ventas por turno, días, medios de pago y canales comerciales de origen
.
Reportes de consumo: Rankings de productos más o menos vendidos y estadísticas de rotación de mesas
.
Balances y Estado de Resultados: Herramientas de visualización de ingresos contra gastos para calcular la utilidad neta
.
9. Hardware e Impresoras Locales
Instalación de controladores: Drivers y manuales de configuración para impresoras térmicas USB, Ethernet y Bluetooth
.
Emisión de comandas: Lógica de envío automático de comandas de platos a la cocina y emisión de precuentas
.
Cajón de dinero: Conectividad física para la apertura automática del cajón de billetes ante ventas en efectivo
.
10. Módulo de Facturación Electrónica
Sincronización fiscal: Proceso de alta del módulo de facturación local en el sistema para la emisión de comprobantes
.
Documentos recibidos (ARG/MX): Gestión, descarga y conciliación contable de facturas fiscales emitidas por tus proveedores
.
11. Módulo 'Tu Delivery' y Tienda Online
Tienda Online Plus: Creación de la página web propia del local, menú interactivo, horarios y pasarelas de pago integradas
.
Logística de envío automatizada: Integración directa con flotas de repartidores de plataformas aliadas (Uber Direct, Rapiboy, PedidosYa Envíos)
.
Asistentes y automatizaciones por WhatsApp: Agente de reservas de mesas y bot de toma de pedidos con Inteligencia Artificial
.
12. Módulo de Integraciones de Software
Delivery Apps Externas: Integración directa de catálogos y comandas con Rappi, Uber Eats, PedidosYa y DiDi Food
.
Cobros digitales con Mercado Pago: Configuración de pagos rápidos con código QR físico (estático) o dinámico en el punto de venta
.
API Pública de Propósito General: Habilitación de tokens y documentación de endpoints para desarrolladores de integraciones personalizadas
.
13. Terminales de Cobro Físicas (Fudo Pagos)
Operación presencial con tarjeta: Registro técnico, cobro físico con chip/contactless, división de cuentas y reembolsos
.
Vínculo con arqueos y depósitos: Sincronización automática de cobros electrónicos con el arqueo diario y la cuenta bancaria
.
14. Arquitectura de Software y Base de Datos POS
Esquema lógico de datos: Almacenamiento, relaciones y restricciones de bases de datos para restaurantes, mesas, productos y arqueos
.
Motor de cálculo financiero: Algoritmo matemático para determinar subtotales, recargos de adicionales, descuentos e impuestos
.

> **Cuando esté:** toda sección de ese índice que tenga que ver con vender y
> que no esté cubierta más abajo, **se agrega como pregunta nueva a este
> archivo**. Este documento crece; no es una lista cerrada.

---

# A · EL MAPA

### A1 · El recorrido completo

`
Lista todas las pantallas del área de ventas, en el orden en que un garzón las
recorre desde que llega un cliente hasta que paga. Tabla: pantalla · para qué
sirve · desde dónde se llega.
`

⬜ A continuación, se detallan las pantallas y vistas de la sección de ventas (dentro del módulo de Restaurante) que recorre un garzón (camarero) durante el flujo de atención a un cliente en el salón, desde su llegada hasta la liquidación de la cuenta:
Pantalla o Vista
Para qué sirve
Desde dónde se llega
1. Mapa de Mesas (o Pantalla Principal de Mesas)
Permite visualizar la distribución física de las mesas del salón, identificar cuáles están libres, ocupadas o con precuentas impresas, e iniciar un nuevo servicio
.
Al iniciar sesión en el sistema o al ingresar al módulo de "Restaurante" (apartado "Mesas")
.
2. Apertura de Mesa
Formulario en el que se especifica la cantidad de comensales (dato clave para estadísticas) y campos opcionales como el nombre del cliente, camarero asignado y comentarios del pedido
.
Desde el Mapa de Mesas, al tocar cualquier mesa que se encuentre libre (en color gris)
.
3. Adición de Productos (o Menú de Pedidos)
Interfaz interactiva donde el garzón busca y selecciona los platos o bebidas que solicita el cliente, ya sea navegando por categorías, favoritos o usando la barra buscadora. Aquí también se configuran opcionales o modificadores de preparación
.
Se abre de forma automática inmediatamente después de presionar "Abrir mesa"
 o al seleccionar una mesa ocupada y presionar "Adicionar"
.
4. Detalle de la Mesa Activa
Permite visualizar el acumulado de consumos de la mesa, agregar nuevas adiciones o gestionar subdivisiones de cuentas utilizando etiquetas para comensales que pagan por separado
.
Desde el Mapa de Mesas, al presionar sobre una mesa que ya está ocupada
.
5. Cierre de Mesa / Cobro
Pantalla de liquidación final donde se procesa el pago. Permite especificar uno o múltiples medios de pago (efectivo, tarjeta de débito, crédito o cuenta corriente), registrar propinas y cerrar definitivamente la transacción
.
Desde el detalle de la Mesa Activa, al presionar el botón "Cerrar mesa" o "Cerrar venta"
.
6. Cierre Parcial (dentro de Cobro)
Modal o sección especial que permite seleccionar productos específicos de la comanda para cobrarlos de forma independiente (ideal cuando un comensal se retira antes o quiere pagar solo lo suyo)
.
Desde la pantalla de Cierre de Mesa / Cobro, al activar la casilla de verificación llamada "Cierre parcial"
.
Nota: Si el local opera bajo la modalidad de venta rápida para llevar (mostrador) o despacho a domicilio (delivery), el flujo omite el mapa de mesas y las comandas se inician directamente desde las respectivas interfaces de pedidos de mostrador o delivery
.

### A2 · Quién puede hacer qué

`
¿Qué roles o perfiles de usuario existen y qué puede hacer cada uno en el área
de ventas? Tabla: rol · qué puede · qué no puede.
`

⬜ En la plataforma de gestión gastronómica de Fudo, el control de acceso y las acciones dentro del área de ventas se administran a través de un esquema de Roles de usuario y permisos basados en roles (RBAC)
.
A continuación, se detallan los perfiles principales que operan en el área de ventas, especificando sus capacidades y limitaciones dentro del sistema:
Rol
Qué puede hacer
Qué no puede hacer
Administrador / Superusuario
• Configurar la totalidad del sistema, definir roles, crear o eliminar usuarios y habilitar el PIN de autorización
.<br>• Visualizar alertas automáticas cuando los productos alcancen su stock mínimo
.<br>• Ver saldos lógicos teóricos ("Según sistema") en arqueos abiertos o cerrados
.<br>• Autorizar operaciones sensibles de caja o salón, como la anulación de ventas ya cerradas o la aplicación de descuentos extraordinarios por encima de ciertos umbrales
.
• No posee restricciones operativas ni técnicas dentro del sistema gastronómico.
Cajero
• Realizar la apertura, control y cierre de los turnos de arqueo de caja
.<br>• Procesar cobros de ventas (efectivo, tarjetas, cuenta corriente, etc.)
.<br>• Registrar movimientos extraordinarios de dinero (ingresos y egresos) y compras o gastos de mercadería directamente en el arqueo
.
• Visualizar el saldo teórico del arqueo ("Según sistema") si el Administrador le ha configurado un Arqueo de caja ciego (en este caso, solo puede declarar el efectivo físico manualmente)
.<br>• Anular ventas cerradas o aplicar descuentos excepcionales (por ejemplo, superiores al 20%) por sí solo sin la debida autorización jerárquica
.
Camarero / Mesero / Garzón
• Iniciar sesión en la App Móvil para tomar pedidos directamente en las mesas de salón
.<br>• Abrir mesas (que se asignan automáticamente a su usuario)
, adicionar productos, gestionar modificadores de platos y aplicar descuentos básicos
.<br>• Imprimir comandas hacia la cocina y emitir tickets de precuenta (control de mesa)
.
• Eliminar adiciones confirmadas o anular ventas de mesas por cuenta propia sin requerir un PIN de autorización de un administrador
.<br>• Ver las alertas de stock bajo de insumos o productos
.<br>• Visualizar la información contable de tesorería o arqueo del sistema
.

> Ojo al leer esto: en Llamita **la seguridad se mantiene en mínimos** por
> decisión de Jhon (§6.1), y el único candado es la puerta de Ajustes. Que
> Fudo tenga cinco roles **no es motivo para copiarlos** — es información
> sobre qué acciones ellos consideran delicadas.

---

# B · LAS MESAS

### B1 · Los estados

`
Lista todos los estados posibles de una mesa, qué acción la lleva a cada
estado y qué acción la saca. Tabla: estado · cómo se entra · cómo se sale ·
cómo se ve en pantalla.
`

⬜ A continuación se detallan los estados posibles de una mesa en Fudo, las acciones que permiten ingresar y salir de cada uno, y su representación visual en la interfaz:

| Estado | Cómo se entra (Acción que la lleva al estado) | Cómo se sale (Acción que la saca de este estado) | Cómo se ve en pantalla |
| :--- | :--- | :--- | :--- |
| **Libre / Habilitada** | Se entra al realizar el cobro y cierre de todas las ventas asociadas a la mesa (ya sea cobrando el total o completando la última de las ventas individuales en el caso de cuentas divididas). | Se sale al seleccionar la mesa en el mapa, indicar la cantidad obligatoria de comensales y presionar el botón **"Abrir mesa"**. | Se muestra como disponible / habilitada en el mapa digital del salón para iniciar un nuevo servicio. |
| **Abierta / Ocupada (Venta en curso)** | Se entra tras completar el formulario de apertura ingresando la cantidad de personas y haciendo clic en **"Abrir mesa"**. | Se sale al presionar el botón **"Imprimir pre-cuenta"** (o "Imprimir control de mesa"), o bien al efectuar directamente el cobro y cierre de la cuenta sin precuenta previa. | La mesa cambia y aparece en color **rojo** en el mapa digital, indicando que hay una venta en curso. |
| **Pagando (Precuenta impresa)** | Se entra seleccionando la mesa ocupada y presionando el botón **"Imprimir pre-cuenta"** (o "Imprimir control de mesa"). | Se sale al presionar **"Cerrar mesa"** (o "Cerrar venta"), especificar el o los medios de pago, ingresar opcionalmente la propina y confirmar la transacción haciendo clic en **"Cobrar"** o **"Cerrar"**. | La mesa cambia a color **celeste**. En el caso del uso de etiquetas (ventas individuales dentro de una misma mesa), la etiqueta específica que tiene la precuenta impresa cambia a color **azul**. |

> Lama hoy tiene tres —libre, ocupada, cobrando—. Si Fudo tiene más, hay que
> saber si son estados de verdad o adornos.

### B2 · Abrir una mesa

`
¿Qué datos se piden al abrir una mesa? De cada uno: ¿es obligatorio u
opcional, y para qué se usa después?
`

⬜ Al abrir una mesa en el sistema, se solicitan los siguientes datos:

*   **Cantidad de personas (comensales):**
    *   **Carácter:** **Obligatorio** (es el único dato requerido obligatoriamente para poder abrir la mesa).
    *   **Uso posterior:** Se utiliza principalmente para alimentar las estadísticas de negocio y calcular las **métricas de consumo promedio** por cliente.

*   **Cliente:**
    *   **Carácter:** **Opcional**.
    *   **Uso posterior:** Permite asociar e identificar la venta con una persona específica. Esto es de gran utilidad si el cliente consume bajo la modalidad de **cuenta corriente** (pago diferido "en confianza"), o si se desea llevar un historial de sus visitas.

*   **Camarero (Mozo o Garzón):**
    *   **Carácter:** **Opcional**.
    *   **Uso posterior:** Sirve para asignar visualmente un responsable de servicio a la mesa. No obstante, el sistema cuenta con una lógica particular para sus reportes: al calcular el ranking de ventas por camarero, Fudo atribuye la venta directamente al **usuario que registra cada adición** de producto en la comanda, y no a la persona seleccionada en este desplegable al momento de la apertura.

*   **Comentario:**
    *   **Carácter:** **Opcional**.
    *   **Uso posterior:** Permite registrar notas de texto aclaratorias o especificaciones particulares sobre el servicio de la mesa en curso.

*   **Etiqueta de venta (visto en el módulo opcional de Ventas Individuales):**
    *   **Carácter:** **Opcional**.
    *   **Uso posterior:** Se utiliza cuando los comensales de una misma mesa física solicitan pagar con cuentas separadas. Al asignar etiquetas (por ejemplo, "Etiqueta 1", "Etiqueta 2"), el camarero puede segmentar la adición de platos y bebidas para cada grupo o comensal y, posteriormente, emitir precuentas y realizar cobros de manera totalmente independiente.

> Contexto: Jhon ya decidió **dejar fuera** personas, cliente y comentario de
> mesa, porque nadie los mira después. Esta respuesta sirve para confirmar que
> no se está perdiendo nada que Fudo use más adelante.

### B3 · Todo lo que se le puede hacer a una mesa

`
¿Qué se puede hacer con una mesa ya abierta? Lista todas las acciones,
incluidas las poco usadas.
`

⬜ Una vez que una mesa se encuentra abierta en Fudo, el sistema permite realizar una amplia gama de acciones, que van desde la operación diaria de servicio hasta funciones avanzadas y de reestructuración de la comanda:

### **Acciones Comunes de Servicio**
*   **Adicionar productos de forma incremental:** El garzón puede seguir sumando platos o bebidas a la orden a medida que el cliente los solicita. Al confirmar la adición, se genera y envía de forma automática el ticket de comanda a las impresoras de la cocina o barra.
*   **Agregar comentarios a productos específicos:** Al seleccionar un ítem en la comanda (antes de confirmarlo), se pueden ingresar notas o especificaciones de preparación para la cocina.
*   **Aplicar descuentos:** Permite aplicar deducciones y descuentos sobre la venta en curso (esta acción suele estar restringida por permisos de usuario).
*   **Imprimir precuenta o control de mesa:** Emite un ticket físico para que los comensales verifiquen su consumo antes de pagar. Al hacerlo, la mesa cambia a color celeste y **se bloquea temporalmente la adición de nuevos productos** para evitar discrepancias entre lo impreso y lo registrado en el sistema.
*   **Cerrar mesa (Cobrar todo):** Procesa la liquidación total de la comanda, donde se selecciona el o los medios de pago (efectivo, tarjetas, etc.) y se registra el monto de la propina.

---

### **Acciones Especiales o Poco Usadas**
*   **Dividir la cuenta con etiquetas (Ventas Individuales):** Mediante este módulo opcional, si los clientes de una misma mesa física desean pagar por separado, el garzón puede "Añadir ventas" adicionales dentro de la misma mesa física utilizando etiquetas (ej. Pareja 1, Pareja 2). Esto permite que cada etiqueta tenga su propia comanda, se le imprima su precuenta por separado y se cobre de manera totalmente independiente.
*   **Realizar un cierre o cobro parcial:** Si no se configuró previamente el módulo de ventas individuales pero uno de los comensales se tiene que retirar antes, se puede activar la opción de "Cierre parcial" al momento de cobrar. Esto permite **seleccionar productos específicos para cobrarlos de forma aislada**, dejando el resto de los consumos todavía activos en la mesa.
*   **Mover consumos o reubicar clientes:** El garzón puede trasladar platos específicos ya adicionados de una mesa a otra, o bien mudar a un grupo de comensales completo de mesa física, directamente desde la interfaz web o desde la App Móvil.
*   **Unificar cuentas:** Permite fusionar dos cuentas o comandas independientes que se abrieron en mesas separadas para unificarlas en un solo cobro.
*   **Editar la información de la mesa:** Es posible modificar sobre la marcha datos de la mesa abierta como el número de personas (comensales), el camarero asignado o asociar un cliente específico (necesario si se va a enviar la venta a su cuenta corriente).
*   **Monitorear el estado de preparación:** Permite hacer un seguimiento visual en tiempo real de en qué etapa de producción se encuentra cada plato adicionado (*Pendiente de preparación*, *En preparación*, *Terminado* o *Entregado*).
*   **Reimprimir tickets:** El sistema permite reimprimir tanto los tiquets de comandas dirigidos a la cocina como los comprobantes de precuenta de la mesa en caso de extravío o corrección.

### B4 · Unir, dividir, trasladar

`
¿Qué pasa exactamente al unir dos mesas, al dividir una y al trasladar
productos de una a otra? ¿Qué se conserva, qué se pierde y qué queda
registrado?
`

⬜ Esto es lo que ocurre exactamente en el sistema de Fudo al realizar cada una de estas tres acciones operativas en el salón:

---

### **1. Unir dos mesas (Unificar cuentas / comandas)**

*   **Qué pasa exactamente**: Fudo permite fusionar dos o más cuentas o comandas independientes que se abrieron en mesas separadas para consolidarlas en una sola comanda receptora y realizar un único cobro final.
*   **Qué se conserva**:
    *   Se conservan **todas las líneas de adición de productos de ambas mesas**, manteniendo intacto el estado detallado de preparación de cada plato (*pendiente de preparación, en preparación, terminado o entregado*).
    *   Se conserva la **atribución original del camarero** en los reportes: el ranking de ventas de Fudo se calcula según el usuario que adicionó físicamente el producto y no según quién abrió o cerró la mesa.
*   **Qué se pierde o unifica**: Se pierde la independencia de las cuentas originales de salón. Pasan de ser dos registros separados en el mapa digital a conformar un único ticket unificado de venta con un solo subtotal.
*   **Qué queda registrado**: En la base de datos relacional del sistema, las líneas de pedido (`detalles_venta`) de la mesa que se unifica se reasocian bajo el identificador de venta (`venta_id` o `mesa_id`) de la mesa de destino. Al momento del cobro, el total unificado impactará en el arqueo de caja abierto como una única transacción de venta.

---

### **2. Dividir una mesa**

Se puede realizar de dos maneras según las herramientas operativas del sistema:

#### **A. Módulo opcional de Ventas Individuales (por comensal)**
*   **Qué pasa exactamente**: Permite segmentar una misma mesa física en diferentes "ventas" independientes mediante etiquetas (ej. Etiqueta 1, Etiqueta 2). Cada etiqueta opera con su propia comanda, lo que permite imprimir precuentas y realizar cobros por separado.
*   **Qué se conserva**: La mesa física permanece en estado **Abierta/Ocupada (color rojo)** en el mapa digital del salón mientras existan etiquetas de venta pendientes de cobro. Cada etiqueta activa conserva su propio acumulado de productos sin mezclarse con los demás.
*   **Qué se pierde**: Se pierde la cuenta única y global de la mesa, convirtiéndose en registros fragmentados pero ordenados.
*   **Qué queda registrado**: Cada etiqueta cobrada se asienta como una **transacción independiente en el arqueo de caja en curso**. En la base de datos se genera un registro de venta individual (`ventas` y `pagos`) con su propio ID de transacción y desglose de medios de pago.

#### **B. Cierre o Cobro Parcial (dentro de una comanda única)**
*   **Qué pasa exactamente**: Al momento de cobrar una comanda unificada, se activa la opción de "Cierre parcial" para **seleccionar ítems, montos o personas específicas** y cobrarlos de forma aislada, dejando el resto de los consumos todavía activos en la mesa.
*   **Qué se conserva**: El sistema calcula automáticamente el saldo restante y mantiene activos en la mesa únicamente los productos que faltan por abonar.
*   **Qué se pierde o cambia**: Los ítems ya cobrados de forma parcial cambian a color verde en la interfaz (indicando que ya fueron pagados) y **se bloquea la posibilidad de editarlos, cancelarlos o volverlos a cobrar**.
*   **Qué queda registrado**: El cobro parcial genera un pago registrado en la caja activa. Al final, cuando se cobra el último producto restante, la mesa se libera en el mapa y la venta global queda asentada con múltiples registros de pago detallados (`pagos`) vinculados a esa misma orden de venta.

---

### **3. Trasladar productos (Mover consumos de una mesa a otra)**

*   **Qué pasa exactamente**: Permite traspasar platos, bebidas o líneas completas de comanda que ya han sido adicionadas desde una mesa de origen hacia otra mesa abierta o libre del salón.
*   **Qué se conserva**:
    *   Se conservan **todas las propiedades del ítem**: el precio unitario bruto capturado al momento del pedido original (para evitar fluctuaciones por herencia de listas de precios), la cantidad y los modificadores o notas que se enviaron a la cocina (`precio_unitario`, `cantidad` y `modificadores_json`).
    *   Se conserva la autoría de la adición en la base de datos para la comisión o estadística del camarero que originalmente tomó el pedido.
*   **Qué se pierde o cambia**: Se desvincula la relación física que tenían los productos con la mesa original. Su valor total se resta de forma inmediata del subtotal de la mesa emisora y se suma de manera automática al de la mesa receptora.
*   **Qué queda registrado**: En la base de datos central, Fudo actualiza la asociación de las líneas de pedido seleccionadas reasignando su clave externa hacia el identificador (`venta_id` o `mesa_id`) de la nueva mesa. El estado de preparación que tenía el ítem en la cocina o pantallas KDS se traslada con él. Si hay una cancelación posterior al traslado, esto se registrará en el historial de cancelaciones bajo el usuario que la ejecute.

---

# C · LA COMANDA

### C1 · De la pantalla a la cocina

`
Describe paso a paso qué ocurre desde que se agrega un producto hasta que sale
impreso en la cocina. ¿Qué estados atraviesa ese producto?
`

⬜ El proceso que ocurre desde que un camarero añade un producto en el sistema hasta que este se imprime físicamente en la cocina involucra una serie de pasos lógicos, arquitectónicos y de hardware, interactuando de forma coordinada a través de los siguientes pasos:

### **El Flujo Paso a Paso hacia la Cocina**

1.  **Selección y Personalización:** El camarero selecciona el producto en la App Móvil o en la interfaz web, configura las variantes o grupos modificadores (como términos de cocción o adicionales) e ingresa comentarios descriptivos manuales (ej. "sin cebolla").
2.  **Confirmación de la Adición:** Al presionar **"Confirmar"**, el sistema crea de inmediato un registro de línea de pedido (`detalles_venta` o `order_items`) asociado a la cuenta de la mesa abierta. En este punto, el motor de Fudo calcula el precio final del ítem considerando la lista de precios activa o tarifa base.
3.  **Procesamiento en la Nube:** La orden se inyecta en el servidor cloud de Fudo, el cual asigna marcas temporales precisas a la comanda. Posteriormente, el servidor cloud envía el payload de la comanda en formato estructurado JSON de vuelta a la aplicación que visualiza el usuario.
4.  **Bucle de Mensajería Local (Loopback Gateway):** La aplicación web o cloud delega la instrucción de impresión a la **Extensión del Navegador** instalada en la computadora del local. Esta extensión realiza un envío HTTP POST interno (`http://localhost:[puerto_agente]`) hacia el **Agente de Impresión Local** (un programa nativo ligero que corre en segundo plano en el sistema operativo del local).
5.  **Traducción a Comandos de Bajo Nivel:** El agente de impresión local intercepta el payload JSON y, gracias a sus permisos nativos, lo traduce a comandos binarios estándar de impresión térmica, conocidos como **ESC/POS**.
6.  **Inyección y Despacho Físico:** El agente inyecta estas instrucciones binarias directamente en el puerto correspondiente (USB, serial o red Ethernet). En el caso de que la comanda se mande directamente desde la App Móvil, la impresión se canaliza hacia impresoras Bluetooth o de red Ethernet vinculadas.
7.  **Impresión en Cocina:** La tiquetera de la cocina o barra recibe los comandos binarios y emite físicamente el **"ticket de comanda"** con el detalle de los productos que el personal debe elaborar. *(Alternativamente, si el restaurante cuenta con el módulo **Monitor de Cocina (KDS)**, la comanda se despacha digitalmente y aparece de inmediato en la pantalla instalada en la cocina).*

---

### **Estados que atraviesa el producto**

A lo largo de este flujo de producción en el local, cada ítem individual de la comanda puede ser monitoreado y transiciona de forma dinámica por los siguientes estados dentro del sistema:

*   **Pendiente de preparación:** Es el estado inicial. El producto ha sido confirmado por el camarero, la comanda ya se imprimió en papel (o ingresó al KDS) y está a la espera de que el personal de cocina inicie su elaboración.
*   **En preparación:** El personal de cocina ha seleccionado el producto y se encuentra activamente elaborándolo en su respectiva estación de trabajo.
*   **Terminado ("Listo para servir"):** El plato ha salido de la cocina y se encuentra listo en el mostrador de despacho para que el camarero lo recoja.
*   **Entregado:** El camarero sirve el producto en la mesa del cliente y lo marca bajo este estado en la App Móvil o web para finalizar el seguimiento operativo de producción.

### C2 · Modificar lo ya enviado

`
¿Se puede modificar o eliminar un producto ya enviado a cocina? ¿Bajo qué
condiciones, qué queda registrado, y qué ve la cocina?
`

⬜ Sí, un producto ya enviado a la cocina se puede modificar o eliminar (cancelar) en Fudo
. Sin embargo, esta acción está sujeta a condiciones estrictas de seguridad para evitar fraudes y desajustes de inventario.
A continuación, se detalla el funcionamiento del sistema ante esta situación:
1. Condiciones para realizar la modificación o eliminación
PIN de autorización o permisos de rol (RBAC): Por motivos de seguridad, los camareros no pueden eliminar de manera libre adiciones que ya han sido confirmadas y enviadas a producción
. Para hacerlo, el usuario debe tener el permiso específico habilitado en su rol o se debe ingresar un PIN de autorización de un administrador o superusuario para validar la acción
.
Estado de la venta: El producto solo se puede eliminar o modificar si la comanda o mesa permanece en estado Abierto
. Una vez que la venta se cobra y se cierra, el sistema bloquea cualquier modificación retrospectiva para garantizar la inmutabilidad financiera del arqueo de caja
.
Uso del canal (API pública): Si la orden fue inyectada mediante integraciones de software externo o chats automatizados, el conector API de Fudo no permite anular o corregir líneas ya cargadas por cuestiones de seguridad; cualquier cambio de este tipo debe realizarse manualmente por el personal en la aplicación de Fudo
.
2. ¿Qué queda registrado en el sistema?
Historial de cancelaciones: Fudo cuenta con una sección específica en su reporte de ventas que registra de manera inmutable el usuario que realizó la cancelación, la cantidad de adiciones anuladas y el monto ($) acumulado que representaban esos productos
.
Motivos de la cancelación: Al eliminar la adición, el sistema exige (o asocia) un motivo de cancelación
. En los reportes estadísticos de ventas, el administrador puede visualizar un gráfico de distribución con los motivos más recurrentes para auditar mermas o errores de digitación
.
Reversión automática de stock: Si el producto o sus ingredientes (en el caso de platos con recetas) tienen activo el control de stock, al cancelar la adición el sistema revierte el descuento y hace subir el stock automáticamente
. Este reajuste queda registrado con fecha, hora y responsable en el historial de Movimientos de Stock
.
3. ¿Qué ve la cocina?
En tiqueteras físicas tradicionales: Las fuentes no especifican la emisión automática de un ticket físico de "anulación" o "resta" impreso en papel térmico tradicional.
En el Monitor de Cocina (KDS): Si el restaurante utiliza comandas digitales en una pantalla de cocina, la cancelación o modificación de los productos se actualiza directamente en el KDS
. El personal de cocina con el permiso de "Actualizar estados" puede interactuar con el monitor para marcar las adiciones como Pendiente, En preparación, Terminado o Entregado, manteniendo al salón y a la cocina sincronizados en tiempo real sobre el estado de cada plato
.

> **Esta es la más importante del bloque C.** Lama ya tomó una decisión acá
> —*lo que salió a la cocina no se edita, se anula*— y conviene saber si Fudo
> hace lo mismo. Si el equipo está acostumbrado a otra cosa, hay que saberlo
> antes y no después.

### C3 · Lo que lleva un producto

`
¿Qué opciones tiene un producto dentro de una comanda: comentarios, variantes,
agregados, cantidades, media porción? Lista todas.
`

⬜ De acuerdo con el material disponible, estas son todas las opciones y configuraciones aplicables a un producto individual al momento de adicionarlo en una comanda:

*   **Cantidades (incluyendo Fracciones/Decimales):** Es posible definir el volumen físico o cantidad del ítem. El sistema soporta el registro de cantidades con valores decimales (el campo de la base de datos es de tipo `DECIMAL(8,3)`). Esto permite procesar fracciones decimales en pedidos de productos vendidos por peso o integrados directamente con balanzas.
    *   *Nota sobre "Media porción":* Las fuentes **no mencionan una función o botón nativo específico para "media porción"**, pero operativamente se puede resolver utilizando las cantidades decimales (ej. 0.5 unidades) o mediante la configuración de variantes/modificadores.
*   **Comentarios:** Se pueden ingresar notas o especificaciones de texto manuales y descriptivas sobre un producto específico antes de confirmar la adición (por ejemplo, escribir *"sin cebolla"* o aclarar detalles para guiar al personal de cocina).
*   **Variantes (Grupos Modificadores):** Si el producto tiene configurados grupos modificadores, se abren las opciones para seleccionar variantes de preparación al tocar el plato (por ejemplo, elegir el tipo de pan o el término de cocción de una hamburguesa). Si se adicionan dos o más unidades de un mismo producto en la comanda, el sistema permite configurar las variantes de cada una de manera independiente.
*   **Agregados o Adicionales (Modificadores con costo):** Permite añadir ingredientes extras o especificaciones que incrementan el valor monetario base del producto (por ejemplo, agregar queso extra o agrandar una bebida). El sistema calcula el total de la línea sumando automáticamente el costo de estos agregados al precio base resuelto. Los modificadores sin costo adicional se almacenan únicamente como instrucciones descriptivas sin alterar el cálculo financiero.
*   **Listas de Precios contextuales:** Al momento de seleccionar los productos (antes de confirmar la adición), se puede abrir un desplegable con las listas de precios configuradas (por ejemplo, tarifas específicas para salón, delivery, promociones o "Happy Hour") y cambiar la lista correspondiente para que el ítem tome el valor correcto.

---

# D · EL COBRO ← *lo que se está construyendo ahora*

### D1 · La pantalla entera

`
Describe la pantalla de cobro completa: cada zona, cada campo y cada botón, en
el orden en que aparecen.
`

⬜ La pantalla de cobro de Fudo (que se habilita al presionar "Cerrar mesa", "Cerrar venta" o "Cerrar pedido") está organizada de forma lógica para que el usuario procese el pago de manera ágil. A continuación, se describen detalladamente cada una de sus zonas, campos y botones en el orden en que se visualizan de arriba a abajo:

### **1. Zona Superior: Resumen Financiero (Cabecera)**
Esta zona muestra los datos económicos globales calculados de la venta activa en curso:
*   **Subtotal:** Campo informativo no editable que muestra el importe bruto acumulado por todos los productos adicionados.
*   **Descuento:** Campo que indica las reducciones o deducciones totales en valor neto o porcentual aplicadas sobre el ticket.
*   **Total:** Campo informativo que calcula el costo final neto de la venta que el cliente debe saldar.

---

### **2. Zona de División de Cuenta: Cierre Parcial**
Esta sección se utiliza únicamente cuando los clientes no desean realizar un pago único:
*   **Casilla de verificación "Cierre parcial" (o "Cobro parcial"):** Casilla que al ser seleccionada despliega un menú con tres botones opcionales para fragmentar la cuenta:
    *   **Botón "Por monto":** Habilita un campo numérico para ingresar un valor de dinero exacto y aislado a cobrar.
    *   **Botón "Por persona":** Abre un selector numérico para ingresar la cantidad de personas, calculando de manera automática la división del total en partes iguales.
    *   **Botón "Por ítem":** Despliega el listado completo de productos adicionados con selectores individuales para que el camarero marque con un visto qué platos o bebidas específicas pagará el cliente en ese turno.

---

### **3. Zona de Registro de Pagos (Medios de Pago e Importes)**
Es la sección interactiva donde se asienta la entrada de dinero en el sistema:
*   **Selector desplegable "Medio de pago":** Menú que permite definir el canal por el cual se recibe el dinero (Efectivo, Tarjeta Débito, Tarjeta Crédito, Transferencia/QR o Cuenta Corriente).
*   **Campo "Monto" (o "Valor"):** Campo numérico editable que, por defecto, se auto-completa con el total restante de la cuenta, pero permite ser editado de forma manual si el pago es parcial.
*   **Botón "+" (Añadir pago):** Botón circular con el signo más, ubicado al lado de la línea de pago, que permite agregar un segundo, tercer o cuarto medio de pago para transacciones combinadas (por ejemplo, registrar que una parte se abona en efectivo y otra con tarjeta de débito).

---

### **4. Zona de Propinas**
Permite registrar el ingreso del dinero extra destinado al personal del salón:
*   **Botones de Porcentaje Fijo:** Accesos rápidos que aplican de manera automática una tasa de propina fija calculada sobre el total de la venta (ej. 10%).
*   **Campo "Monto personalizado" (o "Propina manual"):** Campo numérico interactivo para tipear directamente el importe voluntario que el cliente decida dejar.

---

### **5. Zona Inferior: Confirmación y Cierre (Pie de Pantalla)**
Contiene la acción finalizadora del proceso:
*   **Botón "Cobrar" (o "Cerrar mesa" / "Cerrar venta"):** Botón principal que consolida y guarda de manera inmutable los pagos en el arqueo de caja abierto, cambia el estado de la mesa a "Libre" en el mapa de salón y envía la orden a la impresora para emitir el comprobante de venta correspondiente.

### D2 · Pago parcial

`
¿Cómo funciona el pago parcial o dividido? ¿Se divide por monto, por producto
o por comensal? ¿Qué queda pendiente después y cómo se ve?
`

⬜ En Fudo, el pago parcial o dividido se puede resolver a través de dos herramientas principales en el punto de venta: la opción de **Cierre parcial** y el módulo de **Ventas Individuales (por comensal)**.

### **1. Métodos de división en el "Cierre parcial"**
Al momento de cobrar una comanda unificada en la mesa, puedes activar la casilla de **"Cierre parcial"**. Esta herramienta te permite dividir la cuenta de tres maneras:
*   **Por monto:** Te permite ingresar un valor de dinero exacto y aislado a cobrar en ese turno.
*   **Por comensal (persona):** Seleccionas la cantidad de personas presentes en la mesa y el sistema calcula de manera automática la división del total en partes iguales.
*   **Por producto (ítem):** Permite seleccionar de forma interactiva en la comanda qué platos, bebidas o adicionales específicos se van a cobrar de forma aislada.

### **2. División previa mediante "Ventas Individuales"**
Si prefieres que la cuenta se mantenga separada desde el inicio del servicio, puedes utilizar el módulo de **Ventas Individuales**.
*   Esto permite al camarero asignar **etiquetas de venta** (por ejemplo, "Etiqueta 1", "Etiqueta 2") a diferentes clientes o subgrupos dentro de una misma mesa física.
*   Cada etiqueta opera con su propia comanda independiente, lo que hace posible imprimir su ticket de precuenta y realizar su cobro por separado en cualquier momento, sin mezclar los consumos.

### **3. Qué queda pendiente y cómo se visualiza**
El comportamiento visual del sistema se adapta según la modalidad que utilices:
*   **En el Cierre parcial:** Los productos que ya han sido abonados de forma parcial se muestran en la interfaz con una franja lateral de color **verde** (indicando que ya fueron pagados) y se bloquea la opción de volver a editarlos o cobrarlos. Los productos que quedan pendientes de pago permanecen marcados con una franja de color **naranja**. El sistema recalcula en tiempo real el saldo restante de la cuenta; al abrir nuevamente la pantalla de cobro de esa mesa, Fudo tomará de forma automática únicamente el monto restante que falta por liquidar.
*   **En las Ventas Individuales (etiquetas):** Cada etiqueta cobrada se cierra y se asienta como una transacción independiente en el arqueo. Sin embargo, la mesa física en el mapa digital del salón se mantendrá en estado **Abierta / Ocupada (color rojo)** mientras queden etiquetas con consumos pendientes de cobro. Solo cuando la última venta de la última etiqueta es saldada, la mesa vuelve a quedar **Libre / Habilitada** en el mapa de mesas.

> **Es el A1 de la lista de trabajo, lo más grande que falta.** Jhon ya
> decidió que en Lama **el pago parcial paga PRODUCTOS, no plata**. Esta
> respuesta confirma o corrige esa decisión con el comportamiento real.

### D3 · Descuentos

`
¿Cómo se aplica un descuento: sobre qué se calcula, se puede combinar con
otro, quién puede aplicarlo, y qué queda registrado?
`

⬜ A continuación, se detalla el funcionamiento de los descuentos en el sistema Fudo:

### **¿Cómo se aplica y sobre qué se calcula?**
*   **Formas de aplicación:** Se pueden aplicar de forma **manual** (eligiendo entre un descuento de monto fijo o porcentual) desde el sistema o la app móvil tocando el ícono **"%"** tras confirmar las adiciones. También existen descuentos **automáticos** asociados a clientes predeterminados, cupones promocionales o descuentos vinculados de manera específica a un **medio de pago**.
*   **Base de cálculo:** A nivel de producto, el descuento se calcula sobre el precio del ítem (base o resuelto por lista de precios) sumando el costo de sus modificadores o adicionales y multiplicado por la cantidad.
*   **Fórmula financiera:** El motor matemático del sistema calcula el precio final de la línea aplicando primero la tasa porcentual y restando después el valor de monto fijo:
    Total línea = [(Precio base + Σ Adicionales) × Cantidad] × (1 − Descuento% / 100) − Descuento fijo
    A nivel global, la suma de estos descuentos se resta del subtotal bruto para calcular el total neto final de la venta.

---

### **¿Se puede combinar con otro?**
El modelo matemático de Fudo permite que una misma línea de pedido reciba una **tasa de descuento porcentual** (la cual puede ser individual o heredada del descuento general de la venta) y, al mismo tiempo, se le reste un **descuento de monto fijo** directo en divisa local. Fuera de esta combinación matemática por línea, las fuentes no detallan restricciones o reglas de exclusión para aplicar múltiples descuentos manuales en una misma comanda.

---

### **¿Quién puede aplicarlo?**
*   La aplicación de descuentos está restringida por el sistema de permisos de Fudo. **Solo pueden aplicarlos los usuarios que tengan el permiso correspondiente** asignado en su rol de usuario.

---

### **¿Qué queda registrado?**
*   **En la base de datos:** Se almacena de forma persistente en la cabecera de la transacción (tabla `ventas`) el valor neto de la deducción dentro del campo `descuento`.
*   **En los reportes de indicadores:** Fudo acumula y muestra gráficamente el valor total de los descuentos aplicados de manera manual, automática y por cupones en su panel de "Ventas".
*   **Auditoría de usuarios:** En el reporte exportable de ventas, dentro de la pestaña "Descuentos", queda registrada la columna **"Creado por"**, la cual identifica con nombre y apellido exactamente al **usuario que ingresó cada descuento** en el sistema.

### D4 · Propina

`
¿Cómo se maneja la propina: se calcula sola, se puede pagar con un medio
distinto al de la cuenta, y entra al arqueo?
`

⬜ El manejo de las propinas en Fudo se realiza bajo la siguiente lógica:

### **1. ¿Se calcula sola?**
*   **Sí, puede calcularse automáticamente** si el usuario selecciona los botones de **porcentaje fijo predeterminado** (por ejemplo, un 10%) en la pantalla de cobro o en la App Móvil.
*   También se puede ingresar un **monto personalizado o manual** tipeando directamente el valor voluntario que el cliente decida dejar.
*   En terminales de pago integradas (como Mercado Pago), si se activa la función de propinas, tras confirmar el subtotal de la venta enviado por Fudo, la propia terminal le solicita de forma independiente el porcentaje al cliente.

### **2. ¿Se puede pagar con un medio distinto al de la cuenta?**
*   La propina se asocia directamente a la venta global y se suma al importe total neto a saldar. Fudo no tiene un selector de medio de pago exclusivo que se aplique únicamente a la propina de forma aislada.
*   Sin embargo, dado que el sistema permite registrar **múltiples medios de pago para una misma transacción** (pagos combinados), los clientes pueden optar por pagar una parte con tarjeta (el equivalente a la cuenta) y el resto del total en efectivo (el equivalente a la propina) o viceversa.

### **3. ¿Entra al arqueo de caja?**
*   **Sí, las propinas impactan de forma automática en el arqueo de caja** en curso, siempre y cuando la venta se encuentre cerrada dentro de la franja horaria del arqueo. El sistema permite ver el desglose detallado de las propinas recibidas por cada medio de pago (como en el apartado de cobros digitales o Fudo Pagos).
*   Al final del turno, el efectivo esperado en caja contempla los retiros de las propinas acumuladas digitalmente para su entrega física a los camareros (\\(P_{\text{retiradas}}\\)).
*   Si el comercio no desea que el dinero de las propinas afecte o impacte en el saldo de efectivo esperado del arqueo, se debe registrar de forma manual un **egreso de caja** mediante un "Movimiento de Caja" por el valor entregado.

### D5 · Medios de pago y consumos internos

`
¿Qué medios de pago existen y cuáles no son un cobro real —consumo interno,
cortesía, invitación—? ¿Cómo los trata el sistema y cómo aparecen en los
informes?
`

⬜ En el material disponible de tus fuentes **no se mencionan de forma explícita** conceptos como "consumo interno", "cortesía" o "invitación" como medios de pago, ni se detalla cómo los trata el sistema de Fudo en particular.

No obstante, a continuación se detallan los **medios de pago que sí existen en el sistema**, cómo es su tratamiento lógico-financiero y cómo se visualizan en los informes según tus fuentes:

### **Medios de pago registrados en el sistema**
La base de datos y el flujo de caja de Fudo registran formalmente cinco canales o medios de pago principales:

1.  **Efectivo (`EFECTIVO`):** Representa el cobro físico e inmediato de dinero.
2.  **Tarjeta de Débito (`TARJETA_DEBITO`):** Cobro electrónico presencial procesado por terminales de pago.
3.  **Tarjeta de Crédito (`TARJETA_CREDITO`):** Cobro electrónico presencial procesado por terminales de pago.
4.  **Transferencias / QR (`TRANSFERENCIA`):** Cobros digitales mediante lectura de códigos QR e integraciones financieras externas (como Mercado Pago).
5.  **Cuenta Corriente (`CTA_CTE`):** Es una herramienta para administrar pagos diferidos (con antelación o con posterioridad) exclusiva para clientes que tengan este módulo activo en su perfil. **No representa un cobro real de dinero al momento de cerrar la venta**.

---

### **Tratamiento en el sistema y Arqueos de Caja**

*   **Efectivo:** Impacta de forma **inmediata** en el dinero físico esperado de la caja activa. Se suma de manera directa en la fórmula del arqueo en curso.
*   **Tarjetas y Transferencias/QR:** Tienen un impacto **nulo** en el efectivo físico del arqueo de caja (pues el dinero se acredita digitalmente en cuentas bancarias externas). Sin embargo, el sistema los registra para que el total facturado cuadre con los cupones físicos o comprobantes digitales correspondientes.
*   **Cuenta Corriente (`CTA_CTE`):** Al cerrar la venta bajo este medio, **no impacta en absoluto en el arqueo de caja en ejecución**. El sistema simplemente cierra la venta, pospone el cobro y asienta un saldo deudor (negativo) en la cuenta corriente del cliente. El dinero **solo ingresará al arqueo de caja en el momento posterior** en que el cliente se acerque a abonar su saldo pendiente en efectivo o mediante otro medio presencial.

---

### **Visualización en los Informes y Reportes**

*   **Gráfico de "Ventas por medio de pago" (en Reporte de Ventas / Indicadores):** Muestra la distribución porcentual y los montos acumulados de las ventas brutas según el método de pago utilizado en el período de tiempo seleccionado (efectivo, tarjetas, cuenta corriente, etc.). Cabe destacar que en esta sección solo aparecerán los medios de pago que hayan registrado movimientos reales en el período filtrado.
*   **Informes de Arqueos de Caja:** Al consultar un arqueo abierto o cerrado, se muestra el desglose exacto de los ingresos que el sistema calcula "según sistema" para cada medio de pago. En el caso de que un usuario opere con **"Arqueo de caja ciego"** (donde no puede ver el saldo teórico del sistema), el cajero deberá declarar físicamente el efectivo que cuenta en caja, mientras que los saldos electrónicos de tarjetas y transferencias se pueden configurar para que se autocompleten y eviten discrepancias forzadas al cerrar el turno.
*   **Fudo Pagos:** Las ventas cobradas de manera electrónica y las propinas asociadas a través de la terminal integrada se detallan específicamente en la pestaña "Fudo Pagos" del arqueo de caja.
*   **Cuentas por Cobrar (Finanzas):** Muestra una sección diseñada para visualizar los montos digitales pendientes de acreditación provenientes de pasarelas de pago, detallando las comisiones aplicadas y fechas estimadas de cobro.

### D6 · Cuando la plata no cuadra

`
¿Qué pasa si se intenta cerrar una mesa con menos plata de la que vale? ¿Y con
más? ¿Cómo se maneja el vuelto?
`

⬜ Para gestionar las situaciones en las que el dinero entregado no coincide exactamente con el total de la cuenta, el sistema de Fudo opera bajo las siguientes reglas y funciones:

### **1. Intentar cerrar una mesa con menos dinero de lo que vale**
Fudo no permite finalizar o dar por cobrada una venta de forma definitiva si el importe registrado es insuficiente, a menos que se utilicen métodos de pago dividido o diferido:
*   **Cobro o Cierre Parcial:** Al momento de pagar, se puede activar la casilla de **"Cierre parcial"**. Esto permite registrar un cobro menor dividiendo la cuenta de tres maneras: **por monto** (ingresando una cantidad exacta de dinero), **por comensal** (dividiendo el total en partes iguales) o **por ítem** (seleccionando productos específicos para cobrar de forma aislada). Al hacerlo, los productos pagados cambian a color verde y los pendientes quedan en color naranja en la comanda. El sistema calcula automáticamente el saldo restante y mantiene la mesa como abierta/ocupada hasta que se liquide lo que falta.
*   **Venta a Cuenta Corriente:** Si el cliente tiene habilitado este módulo en su perfil, se puede cerrar la mesa seleccionando **"Cta. Cte."** como medio de pago. Esto permite liberar la mesa en el salón de forma inmediata posponiendo el cobro real de la venta, lo que asienta un saldo deudor (negativo) en la cuenta del cliente. El dinero real ingresará a la caja del local posteriormente, cuando el comensal se acerque a saldar su deuda.

---

### **2. Intentar cerrar una mesa con más dinero de lo que vale**
El tratamiento del dinero excedente varía según la modalidad de la transacción:
*   **Abono en Cuentas Corrientes:** Si el cobro se realiza para saldar la deuda de una cuenta corriente activa de un cliente y este entrega más dinero del que debe, el sistema permite registrar la transacción y **cargar el excedente como saldo a crédito** (un balance a favor) en el perfil del cliente para futuras compras.
*   **Diferencias físicas en el Arqueo de Caja:** Si en el salón se acepta un pago en efectivo mayor al total de la venta y no se registra como vuelto entregado, esto generará una discrepancia entre el dinero real en caja y el balance digital. Al finalizar el turno en la sección **"Arqueos de Caja"**, el cajero debe ingresar los montos contados físicamente ("Según usuario"). Si el efectivo real supera el cálculo del sistema ("Según sistema"), Fudo registrará esta desviación contable de manera inmutable como un **sobrante de caja (que se visualizará en color verde)**.

---

### **3. Manejo del vuelto (cambio)**
*   **En la Tienda Online:** Para los pedidos de delivery o retiro procesados digitalmente, Fudo incorpora un **"Campo para indicar el vuelto"**. A través de este campo, los clientes especifican de forma exacta el monto en efectivo con el que van a pagar al momento de recibir el pedido, lo que permite al comercio calcular y enviar el vuelto exacto con el repartidor para evitar discrepancias.
*   **En el Punto de Venta (Salón/Mostrador):** Las fuentes **no mencionan** la existencia de un botón o calculadora interactiva de vuelto física integrada en la pantalla de cobro del salón para automatizar el cálculo del cambio en caja; por lo que el cajero o garzón debe entregar manualmente la diferencia correspondiente al cliente tras tipear los métodos de pago empleados en el sistema.

---

# E · LO QUE SE DESCUBRE TARDE Y CUESTA CARO

### E1 · Todo lo que el sistema NO deja hacer

`
Lista todo lo que el sistema no permite en el área de ventas: validaciones,
bloqueos y mensajes de error. Tabla: qué se intentó · qué contesta el sistema.
`

⬜ A continuación se detallan las validaciones, bloqueos y comportamientos restrictivos identificados en el área de ventas de Fudo, organizados según la acción que se intenta realizar y la respuesta o bloqueo del sistema:

| Qué se intentó | Qué contesta el sistema (Validación, bloqueo o error) |
| :--- | :--- |
| **Abrir una mesa sin indicar la cantidad de comensales** | **Bloqueo inmediato.** El sistema exige este dato de manera obligatoria para poder abrir la mesa y registrar el servicio. |
| **Adicionar productos a una mesa sin contar con los permisos de usuario correspondientes** | **Acceso denegado.** El sistema no permite cargar productos a la comanda si el rol del usuario no tiene activo el permiso de adición. |
| **Eliminar adiciones ya confirmadas o cancelar ventas (en el caso de un camarero sin permisos de edición de comanda)** | **Bloqueo de seguridad.** El sistema impide realizar la eliminación directa y **solicita un PIN de autorización** de un administrador o superusuario para poder proceder. |
| **Agregar nuevos productos o modificar la comanda de una mesa que ya tiene la precuenta (control de mesa) impresa** | **Bloqueo temporal.** Fudo **bloquea de forma automática la adición de nuevos productos** para evitar que existan diferencias entre el ticket físico entregado al cliente y el registro digital. |
| **Cerrar una mesa seleccionando el medio de pago "Cuenta Corriente" (Cta. Cte.) para un cliente que no tiene este módulo habilitado en su ficha de perfil** | **Notificación de advertencia.** El sistema no permite procesar el cierre bajo esta modalidad y muestra un mensaje de advertencia explicando que el cliente no tiene activa una cuenta corriente. |
| **Aplicar un descuento manual preexistente que no tiene un importe establecido o que se encuentra configurado como "Inactivo"** | **Bloqueo de selección.** El descuento **no aparece en la lista desplegable** de la pantalla de cobro para evitar la aplicación de promociones no válidas o erróneas. |
| **Configurar la pasarela de pagos de Mercado Pago para que funcione únicamente en "retiros" o únicamente en "deliveries" de forma separada** | **Bloqueo de configuración.** El sistema no permite segmentar esta pasarela digital; Mercado Pago **solo se puede activar o desactivar de forma conjunta** para ambas modalidades de entrega. |
| **Procesar un cobro electrónico mediante la terminal local o emitir un reporte fiscal ante una falla de conexión en el hardware** | **Mensajes de error físicos.** El sistema interrumpe la comunicación y arroja errores en pantalla como **"port is not open"** (puerto no abierto) o **"Read time out"** (tiempo de espera agotado). |
| **Registrar e impactar financieramente una comanda dentro de un arqueo de caja de turno sin haber cerrado formalmente el cobro** | **Bloqueo de reporte contable.** El sistema impide el ingreso de los valores al balance del arqueo diario si la venta permanece abierta; para que el cobro impacte, **la venta debe estar estrictamente cerrada**. |

> Esta es la que más rinde por pregunta. **Los bloqueos son las reglas del
> negocio escritas al revés**, y son justo lo que uno descubre a mitad de
> construir.

### E2 · Qué se puede deshacer

`
¿Qué acciones se pueden deshacer y cuáles no? Tabla: acción · reversible sí/no
· cómo se deshace · qué rastro deja.
`

⬜ | Acción | Reversible (Sí/No) | Cómo se deshace | Qué rastro deja |
| :--- | :--- | :--- | :--- |
| **Adición de un producto o comanda en curso** | **Sí** | Cancelando la adición o el producto desde la interfaz de comanda (los camareros requieren permisos de rol o un **PIN de autorización** de un administrador). | Registra de forma inmutable la cancelación en el **Historial de cancelaciones** (detallando usuario, cantidad, monto y motivo) y **revierte automáticamente el descuento de stock** del producto o sus ingredientes. |
| **Registro de un gasto o compra** | **Sí** | Editando o eliminando el gasto cargado en la sección correspondiente (sujeto a permisos de usuario en su rol). | **Revierte la carga de insumos en el control de stock** de forma automática (haciendo que el stock baje) y actualiza los registros asociados en el historial de **Movimientos de Stock**. |
| **Movimiento extraordinario de caja (Ingreso o Egreso)** | **Sí, bajo condiciones** | Eliminando el movimiento directamente desde el panel de caja, **siempre y cuando el arqueo de caja asociado siga abierto**. Es completamente irreversible si el arqueo ya se cerró. | Si se elimina a tiempo, se quita del balance del arqueo en curso. Si el arqueo ya cerró, el sistema bloquea cualquier petición de eliminación o modificación, requiriendo un nuevo movimiento manual de ajuste de caja para corregir saldos. |
| **Anulación de una venta ya cerrada** | **Sí, bajo condiciones** | Procesando la anulación de la venta en el sistema mediante un usuario con los permisos de rol (RBAC) adecuados. Solo es posible si ocurrió dentro de la franja horaria de un **arqueo de caja abierto**. | Si el arqueo sigue abierto, el estado de la venta cambia a **"ANULADO"** en la base de datos. Si el arqueo ya fue cerrado, el backend deniega de forma estricta cualquier modificación física del cobro, obligando a registrar un **asiento de ajuste de caja explícito** en el arqueo activo del turno actual. |
| **Cierre de un arqueo de caja** | **No** | **No se puede deshacer de ninguna manera**. Una vez que un arqueo se cierra, el sistema impide que sea reabierto. | Cambia el estado del arqueo a "CERRADO" de manera definitiva. El backend deniega cualquier inserción, actualización o eliminación en las tablas de pagos, movimientos de caja o gastos cuya marca temporal corresponda al período de ese arqueo. Envía de forma automática el reporte de cierre detallado por correo electrónico al administrador. |

### E3 · Sin internet

`
¿Qué ocurre si se pierde la conexión a internet en medio de una venta? ¿Qué se
puede seguir haciendo y qué se pierde?
`

⬜ Si se pierde la conexión a internet en medio de una venta, el sistema (bajo un modelo híbrido cloud/local como el de Fudo) activa mecanismos de contingencia para no detener la operación del salón.

Esto es lo que ocurre exactamente, lo que se puede seguir haciendo y lo que se pierde temporalmente:

### **Qué se puede seguir haciendo (Operación Offline)**
*   **Registrar pedidos y cobrar de forma local:** El frontend del sistema recurre a una base de datos embebida en el dispositivo (**IndexedDB** o **SQLite**) para retener temporalmente los consumos y pedidos en la memoria local.
*   **Encolar las transacciones:** Las ventas realizadas sin internet se colocan en colas de sincronización diferida (**Sync Queues**). Una vez que el canal de datos con la nube se restablece, el sistema sube la información de manera diferida utilizando marcas temporales (*timestamps*) para resolver cualquier conflicto de datos.
*   **Evitar duplicación de comandas por microcortes:** El sistema asigna un identificador único universal (**UUID**) a cada línea de pedido desde el dispositivo del camarero antes de enviarlo. Si hay microcortes o la conexión fluctúa al transmitir, el servidor utiliza una lógica idempotente para verificar si el UUID ya existe, impidiendo que el reenvío duplique productos en la cocina o altere las sumas de cobro.

### **Qué se pierde o se ve afectado temporalmente**
*   **Sincronización simultánea entre dispositivos:** Durante el tiempo sin conexión, los terminales operan de forma aislada. Esto significa que los cambios de stock, las mermas o las actualizaciones en el mapa de mesas no se verán reflejados en tiempo real en los demás dispositivos, almacenes o administración central hasta que todos vuelvan a conectarse.
*   **Pedidos de canales e integraciones externas:** Los endpoints que reciben pedidos automáticos de aplicaciones de delivery (como Rappi, PedidosYa, Uber Eats) o agentes de chat (como bots de WhatsApp o conectores API) dejarán de ingresar. Dado que estas herramientas externas dependen de la API en la nube y no tienen colas de reintento local en el negocio, reportarán un error de carga y el pedido no se generará de manera diferida.
*   **Estabilidad del sistema ante una sincronización masiva:** Si el período sin conexión fue muy prolongado y se acumuló un volumen masivo de transacciones offline, el retorno repentino de la conexión a internet puede sobrecargar el sistema durante el proceso de sincronización masiva de datos diferidos si la infraestructura no está optimizada para absorber picos.

> §7 ya midió la vara acá: **Fudo ya falla sin conexión hoy**, así que lo
> correcto es "no peor que hoy", no "perfecto".

---

# F · EL VOCABULARIO

### F1 · Las palabras exactas

`
Dame la lista exacta de nombres de botones, títulos de pantalla y mensajes del
área de ventas, tal como están escritos, en español.
`

⬜ Basado estrictamente en los documentos y transcripciones de tus fuentes, a continuación se detalla la lista exacta de nombres de botones, títulos de pantallas/secciones, campos y mensajes del área de ventas de Fudo en español:

### **1. Títulos de Pantalla, Secciones de la Interfaz y Módulos**
*   **"Restaurante"** (Sección principal de la interfaz)
*   **"Ventas"** (Sección principal de la interfaz)
*   **"Mostrador/Mesón"** (Subsección de venta rápida)
*   **"Mostrador Express"** (Subsección de venta rápida)
*   **"Delivery Apps /Domicilio"** (Subsección de despachos)
*   **"Movimientos de caja"** (Sección de movimientos de dinero)
*   **"Arqueos de caja"** (Sección de control de turnos de caja)
*   **"Propinas"** (Sección de administración de propinas)
*   **"Cierre/Cobro parcial"** (también referido como **"Cobro parcial"** o **"Cierre parcial de ventas"**)
*   **"Ventas Individuales"** (Módulo adicional) o **"Ventas por comensal"** (Módulo adicional)
*   **"Cuentas por Cobrar"** (Sección dentro de **Finanzas > Cuentas por Cobrar**)
*   **"Historial de cancelaciones"** (Gráfico y tabla dentro del Reporte de ventas)
*   **"Evolución de ventas"** (Gráfico dentro del Reporte de ventas)

---

### **2. Nombres de Botones y Casillas de Selección**
*   **"Abrir mesa"** / **"abrir mesa"** (Botón para iniciar el servicio en salón)
*   **"Añadir venta"** (Botón en el módulo de ventas individuales)
*   **"Confirmar"** / **"confirmar"** (Botón para registrar y comandar la adición de productos)
*   **"Imprimir control de mesa"** / **"imprimir control de mesa"** (Botón de precuenta representado por un cuadrado con un visto)
*   **"Cerrar venta"** / **"cerrar venta"** (Botón en la pantalla de cobro de comensal)
*   **"Cerrar mesa"** / **"cerrar mesa"** (Botón de cobro total en el salón)
*   **"Nuevo pedido"** (Botón para iniciar transacciones en Mostrador)
*   **"Cierre parcial"** / **"cierre parcial"** (Casilla de verificación en la pantalla de cobro)
*   **"Cobrar todo"** (Opción de cierre)
*   **"Listo para entregar"** (Botón con flecha azul para pedidos de delivery)
*   **"Enviar el cierre de arqueo de caja por mail"** (Opción de envío de arqueo)

---

### **3. Campos de Entrada, Filtros e Indicadores**
*   **"número de personas"** (Campo obligatorio al abrir mesa)
*   **"etiqueta de venta"** (Campo en ventas individuales)
*   **"etiqueta uno"** y **"etiqueta dos"** (Opciones del selector de etiquetas de comensales)
*   **"cliente"** (Campo para asignar un perfil)
*   **"camarero"** (Selector de mesero asignado)
*   **"vuelto"** (Campo de vuelto para delivery)
*   **"Creado por"** (Columna y filtro en las pestañas de propinas y descuentos)
*   **"Cerrado por"** (Filtro en la sección de Ventas)
*   **"Total de ventas brutas (\$)"** (Tarjeta de indicador en reportes)
*   **"Total de ventas netas (\$)"** (Tarjeta de indicador en reportes)
*   **"Descuentos (\$)"** (Tarjeta de indicador en reportes)
*   **"Cantidad de ventas"** (Tarjeta de indicador en reportes)
*   **"Promedio por venta"** (Tarjeta de indicador en reportes)
*   **"Posición"**, **"Usuario"**, **"Cantidad"**, y **"Monto (\$)"** (Columnas del ranking de cancelaciones)

---

### **4. Estados de Pedidos, Ventas, Transacciones y Mensajes de Error**
*   **"Dirección inválida"** (Mensaje de error en el buscador de la Tienda Online)
*   **"Activo"** (Estado de un descuento para que aparezca en el panel)
*   **"ABIERTO"** (Estado del pedido/mesa en la base de datos)
*   **"COBRADO"** (Estado del pedido/mesa cerrado)
*   **"ANULADO"** (Estado del pedido cancelado tras haber sido cobrado)
*   **"SALON"**, **"MOSTRADOR"** y **"DELIVERY"** (Orígenes o canales registrados en la base de datos)
*   **"enviado"** (Estado de pedido delivery transportado por repartidor)
*   **"entregados"** / **"entregado"** (Estado final del pedido delivery cobrado)
*   **"EFECTIVO"** (Medio de pago)
*   **"TARJETA_DEBITO"** (Medio de pago)
*   **"TARJETA_CREDITO"** (Medio de pago)
*   **"TRANSFERENCIA"** (Medio de pago)
*   **"CTA_CTE"** (Medio de pago de cuenta corriente de clientes)
*   **"port is not open"** (Mensaje de error físico de impresora fiscal)
*   **"Read time out"** (Mensaje de error de comunicación con impresora fiscal)

> **La más barata y la más rentable de todas.** Si Lama dice *"Anular"* donde
> Fudo dice *"Cancelar producto"*, el equipo tiene que reaprender palabras — y
> la razón entera de copiar a Fudo era que no tuvieran que aprender nada.
>
> Cuando esta llegue, **se revisa contra los textos que Lama ya tiene puestos**
> y se corrigen los que no calcen.

---

# G · LOS HUECOS

### G1 · Lo que el manual no cuenta

`
¿Qué aspectos del área de ventas NO están documentados, o se mencionan solo de
pasada?
`

⬜ Al contrastar las guías de uso, las especificaciones técnicas y el esquema de base de datos relacional de Fudo, se identifican varios aspectos críticos del área de ventas que **no están documentados** en detalle o se **mencionan únicamente de pasada** en las comparativas de planes:

### **1. Conceptos de Cortesía, Invitación y Consumo Interno**
*   **Ausencia total de registro:** No existe ninguna documentación ni campos en la base de datos para registrar transacciones que no representen un cobro monetario real, tales como consumos de cortesía para clientes, invitaciones especiales, pérdidas por platos devueltos que no califican como desperdicio de stock, o consumos internos del personal del restaurante. Los únicos medios de pago reales contemplados en la estructura son efectivo, tarjetas, transferencia/QR y cuenta corriente.

### **2. Configuración e Impacto de "Vender sin Stock"**
*   **Mencionado solo de pasada:** En la tabla comparativa de planes de Fudo se incluye el ítem **"Restricciones para vender sin stock"** como una característica exclusiva de los planes Avanzado y Pro. Sin embargo, no se detalla en las guías operativas cómo funciona exactamente esta restricción en el punto de venta (por ejemplo, si el sistema emite un mensaje de error específico, si oculta el producto de la carta de adición automáticamente, o si permite forzar la adición mediante un PIN de autorización).

### **3. Lógica Física de Anulación de Comandas Impresas**
*   **Vacío de impresión en papel:** Aunque se explica con precisión que al cancelar un producto o comanda en curso el stock se revierte y que los cambios se reflejan digitalmente si se utiliza el Monitor de Cocina (KDS), las guías **no detallan el comportamiento de las tiqueteras físicas tradicionales**. No se especifica si el agente de impresión de Fudo envía de manera automática un tiquet físico de "ANULACIÓN" a la cocina o si el camarero debe dar aviso verbalmente para frenar la preparación.

### **4. Sincronización de Clientes (Online vs. Físico)**
*   **Falta de integración operativa:** Los lanzamientos documentan el **"Registro de clientes de Tienda Online"** para almacenar datos de contacto y la posibilidad de buscar y asignar clientes desde la pantalla de pedidos en el local. Sin embargo, las guías no aclaran si ambas bases de datos se unifican automáticamente o si operan de forma separada (es decir, si un cliente que hace un pedido online queda de inmediato habilitado en el salón con su historial respectivo).

### **5. Reglas de Exclusión y Combinación de Descuentos**
*   **Detalle matemático pero no lógico:** Se documenta la fórmula financiera para aplicar descuentos manuales de monto fijo y porcentajes a nivel de línea de pedido, y se menciona la existencia de la pestaña "Descuentos". No obstante, no se detalla si el sistema permite combinar múltiples descuentos en una misma venta (por ejemplo, si se puede aplicar un descuento general por "Happy Hour" a toda la mesa y, de forma simultánea, un descuento manual de camarero a un plato específico).

### **6. Operación Operativa del Vuelto en Salón/Mostrador**
*   **Lógica manual:** Para la Tienda Online se detalla la configuración del **"campo de vuelto"** para que el cliente declare con cuánto dinero pagará. Sin embargo, para la operación presencial en el local (salón o mostrador), no se documenta si la interfaz de cobro tiene una calculadora integrada de vuelto o si el cajero debe calcularlo externamente y entregar la diferencia de manera manual.

### **7. Funcionamiento de "Media Porción"**
*   **Manejo solo por decimales:** El sistema de base de datos admite cantidades con fracciones decimales para productos vendidos por peso o integrados con balanzas. A pesar de esto, no se documenta ninguna función nativa de "media porción" (por ejemplo, que divida el precio estándar a la mitad de forma automática), dejando esta operatoria a la edición manual del precio o de la cantidad por parte del camarero.

### **8. Reparto y Liquidación de Propinas**
*   **Vacío en la distribución:** Las guías enseñan a activar, registrar e incluir la propina en el arqueo de caja e incluso cómo visualizar el reporte detallado. Sin embargo, no documentan cómo resolver la entrega física o reparto de estas propinas digitales (por ejemplo, propinas cobradas con tarjeta o Mercado Pago) para liquidarlas a los camareros de forma interna al finalizar el turno.

> Lo que salga acá **es la lista de lo que hay que ir a mirar a la pantalla**.
> Tenerla antes de empezar evita descubrirlo a mitad de construir.

---

# H · EL ARQUEO DE CAJA — para cuando lleguemos ahí

> Agregada el 2026-09-02, al leer lo que ya contestó NotebookLM. Es el punto
> **3 de "DESPUÉS, en orden"** en `docs/LAMA.md` — *"el cierre de caja: arqueo,
> efectivo/débito, cuadratura del turno"*. No hace falta contestar esto ahora
> mientras se termina el cobro; se deja lista para cuando toque.

### H1 · El ciclo completo del arqueo

```
Describe paso a paso el ciclo de un arqueo de caja: cómo se abre, qué pasa
mientras está abierto, y cómo se cierra. ¿Puede haber más de uno abierto a la
vez, y qué pasa con las ventas de un turno que aún no se abre arqueo?
```

⬜ PENDIENTE

### H2 · Cuando el efectivo no cuadra

```
Al cerrar un arqueo, ¿cómo se comparan el efectivo contado y el que el sistema
calculó? ¿Qué pasa si sobra plata y qué pasa si falta? ¿Eso queda registrado
en algún lado que un administrador pueda revisar después?
```

⬜ PENDIENTE

### H3 · El arqueo "ciego"

```
¿Qué es exactamente el arqueo ciego, quién lo activa, y qué ve el cajero que
no vería en un arqueo normal? ¿Para qué lo usan los locales que lo activan?
```

⬜ PENDIENTE

> Fudo ya reveló solo (E1, D6) que existe el concepto de "sobrante de caja en
> verde" y de declarar el efectivo a mano cuando el arqueo es ciego. Estas tres
> preguntas piden el resto del cuadro completo.

---

# I · LO VISUAL — no va acá, pero se anota dónde va

Esto **no** sale de NotebookLM. Se mide sobre Fudo abierto, con botón derecho
→ Inspeccionar, y se guarda junto a la captura de cada pantalla.

De cada pantalla que Lama vaya a replicar:

- [ ] captura en **computador** y en **teléfono**
- [ ] los **colores** de fondo, texto, botones y de cada estado de mesa
- [ ] el **tamaño de letra** de título, de producto y de total
- [ ] el **orden** de los elementos, de arriba abajo
- [ ] qué **crece y qué se queda fijo** al agrandar la ventana
- [ ] qué pasa al **tocar** cada cosa

> **Adjetivos no sirven.** *"Se ve apretado"* deja al que construye eligiendo
> entre veinte versiones válidas; `padding: 14px` no deja ninguna. Esa
> diferencia es la que hace que un mismo pedido salga bien o salga a medias.

---

## Registro

| Fecha | Qué se agregó |
|---|---|
| 2026-09-02 | Se cargan las respuestas de A a G (16 preguntas), sacadas del manual completo de Fudo vía NotebookLM. Se agrega la sección **H · El arqueo de caja**, tres preguntas nuevas, para cuando llegue ese punto de la lista |
| 2026-09-01 | Se crea el archivo con las preguntas. Ninguna respondida todavía |
