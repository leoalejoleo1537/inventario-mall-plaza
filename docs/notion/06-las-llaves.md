# 06 · Las llaves y las cuentas

> El sistema no es un programa que se instala: son **cinco cuentas**. Quien sea
> dueño de estas cinco es dueño de Llamita.

---

## Las cinco

| Cuenta | Qué guarda | Si se pierde |
|---|---|---|
| **Supabase** | Los productos, el stock, las recetas, los repartos, el historial y los permisos | **Es lo irreemplazable.** Sin respaldo, se pierde el inventario entero |
| **Vercel** | Publica la app en internet | Se vuelve a conectar al repositorio en 10 minutos |
| **GitHub** | El código y la historia de cada cambio, con su explicación | Se pierde el porqué de las decisiones |
| **Fudo · 2 cuentas** | El punto de venta de cada local | Sin ellas el inventario no se entera de las ventas |
| **Notion** | Esta central de conocimiento y los respaldos en CSV | Se pierde el manual y la última copia |

---

## Qué anotar de cada una

> Las contraseñas **no van escritas acá**. Van en un gestor de contraseñas o en
> un sobre cerrado. Acá va solo dónde está cada cosa.

### Supabase

| Dato | Dónde se saca |
|---|---|
| Nombre del proyecto | Panel principal |
| **Contraseña de la base** | Se define al crear el proyecto y **no se puede recuperar** |
| Project URL | Settings → API |
| Publishable key | Settings → API |
| Quién es dueño de la organización | Settings → Team |

### Vercel

| Dato | |
|---|---|
| A qué repositorio está conectado | |
| Qué rama publica | **`master`**, y ninguna otra |
| La dirección web de la app | |

### GitHub

| Dato | |
|---|---|
| Dueño del repositorio | |
| Nombre del repositorio | |
| Rama principal | `master` |

### Fudo

| Dato | Dónde |
|---|---|
| Usuario y clave del panel, por local | |
| API key y API secret, por local | Se piden en el panel de Fudo |

> Las claves de API ya están cargadas dentro de Supabase como *secrets*. Ahí
> **no se pueden volver a leer**: solo reemplazar. Por eso conviene tenerlas
> anotadas aparte.

---

## La lista del traspaso

Esto es lo que convierte "funciona" en "es de ustedes". Hasta que esté hecho, el
sistema depende de cuentas personales.

- [ ] **Pasar el proyecto de Supabase a una cuenta de la empresa**
- [ ] **Transferir el repositorio de GitHub** a la organización de la empresa
- [ ] **Reconectar Vercel** al repositorio nuevo — o mudarse a Cloudflare Pages
- [ ] **Anotar las claves de Fudo** fuera de Supabase
- [ ] **Nombrar quién entra a Ajustes** — desde la app, Personas y acceso
- [ ] **Guardar un respaldo el día del traspaso** — la foto del día cero
- [ ] **Decidir si se paga el plan Pro de Supabase**

---

## Lo que cuesta mantenerlo

| Servicio | Hoy | Lo que conviene |
|---|---|---|
| **Supabase** | Plan gratuito | **Pro, ~25 USD/mes.** El gratuito **no tiene punto de restauración**: si se pierde algo, no hay a dónde volver salvo las fotos del inventario |
| **Publicación web** | Vercel gratuito | **Cloudflare Pages, gratis.** El plan gratuito de Vercel es para uso personal; para una empresa corresponde pagarlo o mudarse |
| **Fudo** | Ya se paga | No cambia |

**Total realista: entre 25 y 45 dólares al mes.** Ese número **no sube al
agregar sedes**: Supabase cobra por proyecto, no por local. Una sede nueva son
filas nuevas, no otro sistema.

---

## Quién puede seguir esto

No hace falta el equipo original. Hace falta alguien que sepa **JavaScript y
SQL** — no frameworks: la app es un solo archivo HTML sin compilar, y la base es
PostgreSQL corriente.

Lo que sí hay que exigirle: **que lea `CLAUDE.md` antes de tocar nada**. Ese
archivo no es documentación de cortesía. Cada regla dura viene con la falla real
que la produjo.
