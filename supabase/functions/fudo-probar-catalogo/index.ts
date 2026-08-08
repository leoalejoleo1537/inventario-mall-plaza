// ================================================================
// Edge Function: fudo-probar-catalogo   —   PRUEBA AISLADA  ·  v2
//
// LA PREGUNTA QUE VIENE A CONTESTAR:
//   ¿Se pueden BORRAR productos del catálogo de Fudo desde la API?
//   Adriana lleva 4 años sin poder limpiar el catálogo porque la
//   pantalla de Fudo no la deja. Si la API sí deja, eso cambia todo.
//
// ---------------------------------------------------------------
// POR QUÉ HAY UNA v2, Y ES LA PARTE ÚTIL DE ESTE ARCHIVO
//
//   La v1 intentó CREAR un producto de mentira para después borrarlo.
//   Crear falló con un 400 muy concreto:
//
//     source: /data/attributes/active
//     "property '/data/attributes/active' is invalid: error_type=schema"
//
//   Eso NO es "no tienes permiso": es "ese campo no va en un alta".
//   Pero la v1, al ver que crear falló, se saltó los pasos de
//   desactivar y borrar y devolvió "no se puede tocar el catálogo".
//   Concluyó desde algo que nunca probó. Es la regla 0.1.5 del archivo
//   madre incumplida por mí, y por poco cierra la puerta más
//   importante del proyecto.
//
//   La v2 lo arregla de raíz: cada capacidad se pregunta POR SEPARADO,
//   y si una no se pudo probar dice "no se probó" — nunca "no se puede".
//
// ---------------------------------------------------------------
// EL TRUCO QUE HACE QUE ESTO NO TENGA RIESGO
//
//   Para saber si un endpoint acepta DELETE no hace falta borrar nada
//   de verdad: basta pedirle que borre un id que NO EXISTE. Lo que
//   conteste distingue las tres respuestas que nos importan, sin tocar
//   un solo producto:
//
//     405 Method Not Allowed  -> la API NO soporta borrar. Definitivo.
//     401 / 403               -> soporta borrar, pero esta cuenta no puede.
//     404 Not Found           -> soporta borrar y la cuenta puede;
//                                simplemente no encontró ese producto.
//
//   El 404 es la buena noticia: para llegar a "no lo encontré", la API
//   ya pasó por el permiso.
//
//   Lo mismo para saber si `active` se puede escribir: un PATCH a un id
//   inexistente devuelve 400 con el pointer del campo si el campo es de
//   solo lectura, y 404 si el campo pasó la validación.
//
// ---------------------------------------------------------------
// QUÉ HACE, EN ORDEN (los 4 primeros no tocan NADA):
//   1. Lee el catálogo, para copiar la forma de un producto real.
//   2. DELETE a un id inexistente   -> ¿la API deja borrar?
//   3. PATCH  a un id inexistente   -> ¿`active` se puede escribir?
//   4. Intenta CREAR, ahora sin el campo que Fudo rechazó. Si falla,
//      reintenta con lo mínimo (solo nombre y precio).
//   5. SOLO si crear funcionó: sobre ese producto de mentira hace el
//      camino completo — desactivar, borrar, y releer para comprobar.
//
// QUÉ DEJA:
//   Nada, si borrar funciona.
//   Si crear funciona pero borrar no: queda "ZZZ PRUEBA CLAUDE",
//   desactivado si se pudo, y la respuesta lo avisa.
//   Si crear no funciona: no queda absolutamente nada.
//
// Cómo se llama:  POST { sede: "angamos" }
//
// ESTA FUNCIÓN ES TEMPORAL: cuando decidamos, se borra.
// ================================================================

const VERSION = "2026-08-08-v2";
const AUTH_URL = "https://auth.fu.do/api";
const API_BASE = "https://api.fu.do/v1alpha1";
const NOMBRE_PRUEBA = "ZZZ PRUEBA CLAUDE - ignorar";
const ID_FANTASMA = "999999999"; // un id que no existe, a propósito

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

type Rta = { ok: boolean; status: number; txt: string };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const url = new URL(req.url);
    let bodySede: string | null = null;
    if (req.method === "POST") {
      const b = await req.json().catch(() => ({}));
      bodySede = b?.sede ?? null;
    }
    const sede = (url.searchParams.get("sede") ?? bodySede ?? "angamos").toLowerCase();

    const apiKey = Deno.env.get(`FUDO_${sede.toUpperCase()}_APIKEY`);
    const apiSecret = Deno.env.get(`FUDO_${sede.toUpperCase()}_APISECRET`);
    if (!apiKey || !apiSecret) return json({ error: `Faltan las credenciales de Fudo para "${sede}".` }, 400);

    const authRes = await fetch(AUTH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ apiKey, apiSecret }),
    });
    if (!authRes.ok) return json({ error: `Fudo rechazó la autenticación (${authRes.status}).` }, 502);
    const token = (await authRes.json())?.token;
    if (!token) return json({ error: "Fudo no devolvió token." }, 502);
    const H = { "Authorization": `Bearer ${token}`, "Accept": "application/json" };
    const HJ = { ...H, "Content-Type": "application/json" };

    const pasos: Record<string, unknown>[] = [];
    const pedir = async (ruta: string, init?: RequestInit): Promise<Rta> => {
      const r = await fetch(`${API_BASE}${ruta}`, init);
      const txt = await r.text();
      return { ok: r.ok, status: r.status, txt };
    };

    // ============================================================
    // 1) Copiar la forma de un producto que ya existe. NO lo toca.
    // ============================================================
    const lista = await pedir(`/products?page[size]=50&page[number]=1`, { headers: H });
    if (!lista.ok) {
      return json({ version: VERSION, sede, error: "No se pudo leer el catálogo.",
                    detalle: lista.txt.slice(0, 300) }, 502);
    }
    const datos = JSON.parse(lista.txt)?.data ?? [];
    const base = datos[0];
    if (!base) return json({ version: VERSION, sede, error: "El catálogo vino vacío." }, 404);
    const categoria = base.relationships?.productCategory?.data?.id ?? null;
    pasos.push({
      paso: "1 · leer un producto de ejemplo",
      toca_algo: false,
      funciona: true,
      producto: base.attributes?.name,
      categoria_id: categoria,
    });

    // ============================================================
    // 2) ¿La API acepta DELETE? Se lo preguntamos con un id que no
    //    existe, así la pregunta no puede romper nada.
    // ============================================================
    const delFantasma = await pedir(`/products/${ID_FANTASMA}`, { method: "DELETE", headers: H });
    const borrarSoportado =
      delFantasma.status === 405 ? "NO — la API no tiene borrar"
      : delFantasma.status === 401 || delFantasma.status === 403 ? "SÍ existe, pero esta cuenta no tiene permiso"
      : delFantasma.status === 404 ? "SÍ — existe y la cuenta pasa el permiso"
      : delFantasma.ok ? "SÍ (contestó que borró algo que no existía, raro pero permisivo)"
      : `sin clasificar (HTTP ${delFantasma.status})`;
    pasos.push({
      paso: "2 · ¿existe BORRAR? (pregunta sobre un id inventado)",
      toca_algo: false,
      http: delFantasma.status,
      lectura: borrarSoportado,
      respuesta: delFantasma.txt.slice(0, 300),
    });

    // ============================================================
    // 3) ¿El campo `active` se puede escribir? Misma técnica.
    //    Si el campo fuera de solo lectura, Fudo contesta 400 con el
    //    pointer del campo ANTES de fijarse en que el id no existe.
    // ============================================================
    const patchFantasma = await pedir(`/products/${ID_FANTASMA}`, {
      method: "PATCH", headers: HJ,
      body: JSON.stringify({ data: { type: "Product", id: ID_FANTASMA, attributes: { active: false } } }),
    });
    const activeEscribible =
      patchFantasma.status === 404 ? "SÍ — el campo pasó la validación"
      : patchFantasma.status === 400 && patchFantasma.txt.includes("/attributes/active")
        ? "NO — Fudo rechaza escribir `active`"
      : patchFantasma.status === 401 || patchFantasma.status === 403 ? "la cuenta no tiene permiso"
      : `sin clasificar (HTTP ${patchFantasma.status})`;
    pasos.push({
      paso: "3 · ¿se puede escribir `active`? (id inventado)",
      toca_algo: false,
      http: patchFantasma.status,
      lectura: activeEscribible,
      respuesta: patchFantasma.txt.slice(0, 300),
    });

    // ============================================================
    // 4) CREAR — ahora sin `active`, que es el campo que Fudo rechazó
    //    en la v1. Si igual falla, se reintenta con lo mínimo.
    // ============================================================
    const intentosCrear: { como: string; cuerpo: Record<string, unknown> }[] = [
      {
        como: "sin `active`, con categoría",
        cuerpo: { data: { type: "Product",
          attributes: { name: NOMBRE_PRUEBA, price: 1 },
          ...(categoria ? { relationships: { productCategory: { data: { type: "ProductCategory", id: categoria } } } } : {}) } },
      },
      {
        como: "solo nombre y precio",
        cuerpo: { data: { type: "Product", attributes: { name: NOMBRE_PRUEBA, price: 1 } } },
      },
    ];

    let idPrueba: string | null = null;
    let crearOk = false;
    for (const intento of intentosCrear) {
      const r = await pedir(`/products`, { method: "POST", headers: HJ, body: JSON.stringify(intento.cuerpo) });
      let id: string | null = null;
      try { id = JSON.parse(r.txt)?.data?.id ?? null; } catch { /* no-JSON */ }
      pasos.push({
        paso: `4 · CREAR (${intento.como})`,
        toca_algo: true,
        funciona: r.ok && !!id,
        http: r.status,
        respuesta: r.txt.slice(0, 300),
      });
      if (r.ok && id) { idPrueba = id; crearOk = true; break; }
    }

    // ============================================================
    // 5) El camino completo, SOLO sobre el producto de mentira.
    // ============================================================
    let desactivar: Rta | null = null;
    let borrar: Rta | null = null;
    let seguiaAhi: boolean | null = null;

    if (idPrueba) {
      desactivar = await pedir(`/products/${idPrueba}`, {
        method: "PATCH", headers: HJ,
        body: JSON.stringify({ data: { type: "Product", id: idPrueba, attributes: { active: false } } }),
      });
      pasos.push({ paso: "5a · DESACTIVAR el producto de mentira", toca_algo: true,
                   funciona: desactivar.ok, http: desactivar.status,
                   respuesta: desactivar.txt.slice(0, 300) });

      borrar = await pedir(`/products/${idPrueba}`, { method: "DELETE", headers: H });
      pasos.push({ paso: "5b · BORRAR el producto de mentira", toca_algo: true,
                   funciona: borrar.ok, http: borrar.status,
                   respuesta: borrar.txt.slice(0, 300) });

      // La comprobación que importa: releer. Un 200 no prueba nada.
      const rele = await pedir(`/products/${idPrueba}`, { headers: H });
      seguiaAhi = rele.ok;
      pasos.push({ paso: "5c · releer para COMPROBAR", toca_algo: false,
                   http: rele.status,
                   resultado: rele.ok ? "SIGUE EXISTIENDO" : "ya no está" });
    }

    // ============================================================
    // VEREDICTO — con la distinción que le faltaba a la v1:
    // "no se pudo probar" NO es lo mismo que "no se puede".
    // ============================================================
    const borrarProbado = borrar !== null;
    const sePuedeBorrar = borrarProbado && !!borrar?.ok && seguiaAhi === false;
    const sePuedeDesactivar = desactivar !== null ? !!desactivar.ok : null;

    const veredicto = sePuedeBorrar
      ? "✅ SÍ SE PUEDE BORRAR, comprobado de punta a punta. La limpieza definitiva del catálogo es posible."
      : borrarProbado
        ? "🟡 Se creó el producto de prueba pero NO se pudo borrar. Mira el paso 5b."
        : delFantasma.status === 405
          ? "❌ La API NO tiene borrar productos (405). Esto sí es definitivo: no depende de permisos."
          : delFantasma.status === 401 || delFantasma.status === 403
            ? "🟠 Borrar EXISTE en la API, pero esta cuenta no tiene el permiso. Hay a quién pedírselo."
            : delFantasma.status === 404
              ? "🟢 Borrar EXISTE y la cuenta pasa el permiso — pero no pude crear un producto de prueba para comprobarlo de verdad. Falta probarlo sobre un producto real."
              : "❓ No concluyente. Mira el paso 2.";

    const queHacer = sePuedeBorrar
      ? "Se puede construir la limpieza de verdad. Va con vista previa, registro y respaldo de lo borrado — un producto borrado por error no se recupera de otra forma."
      : delFantasma.status === 404 && !crearOk
        ? "El siguiente paso es probar el borrado sobre UN producto de basura elegido por Adriana. Y antes hay que saber si ella puede volver a crearlo a mano desde la pantalla de Fudo: si puede, el error es reversible y la prueba es barata."
        : activeEscribible.startsWith("SÍ")
          ? "Aunque no se pueda borrar, `active` sí se puede escribir: apagar un producto lo saca de la venta. No es 'borrar', pero en el mesón el efecto es el mismo."
          : "Hay que preguntarle a Fudo qué permisos tiene esta cuenta sobre el catálogo.";

    return json({
      version: VERSION, sede,
      veredicto,
      que_hacer: queHacer,
      // Lo que de verdad quedó comprobado, sin mezclar con lo que no se probó:
      borrar_existe_en_la_api: borrarSoportado,
      active_se_puede_escribir: activeEscribible,
      se_pudo_crear_un_producto: crearOk,
      se_probo_borrar_de_verdad: borrarProbado,
      se_puede_borrar: borrarProbado ? sePuedeBorrar : "no se probó",
      se_puede_desactivar: sePuedeDesactivar === null ? "no se probó" : sePuedeDesactivar,
      ...(crearOk && !sePuedeBorrar
        ? { ojo: `Quedó el producto "${NOMBRE_PRUEBA}" en el catálogo${desactivar?.ok ? ", desactivado" : ""}. Hay que sacarlo a mano desde Fudo.` }
        : {}),
      detalle_paso_a_paso: pasos,
      recordatorio: "Los pasos 1, 2 y 3 no tocan nada: preguntan sobre un id inventado. Del 4 en adelante solo se toca un producto de mentira, nunca uno de la carta.",
    });
  } catch (e) {
    return json({ error: "Error inesperado.", detalle: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj, null, 2), {
    status, headers: { "Content-Type": "application/json", ...CORS },
  });
}
