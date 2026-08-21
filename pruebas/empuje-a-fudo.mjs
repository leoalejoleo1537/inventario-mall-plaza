/* EL EMPUJE A FUDO, CORRIENDO DE VERDAD.  (bun pruebas/empuje-a-fudo.mjs)
   ---------------------------------------------------------------------------
   Se ejecuta la Edge Function REAL —el mismo archivo que se pega en
   Supabase—, con `Deno` y `fetch` simulados. No es una copia de la lógica:
   es el archivo, y por eso sirve (§0.5: una prueba contra algo que uno mismo
   reescribe solo se valida a sí misma).

   POR QUÉ EXISTE. El 2026-08-21, en turno, el botón ⟳ devolvía **504** y la
   app se quedaba girando. La causa estaba acá: la función le mandaba a Fudo
   un producto por vez, en fila, sin tope. Con ~150 productos eso pasa de los
   dos minutos y la plataforma corta la función a la mitad — y como la
   bitácora se escribía recién al final, lo que sí se había hecho no dejaba
   rastro. Trabajo hecho, cero registro.

   Las tres cosas que se comprueban:
     1 · se mandan TODOS, y de a cinco a la vez (no de a uno)
     2 · si se acaba el tiempo, para y DICE cuántos quedaron
     3 · la bitácora se escribe en el camino, así un corte no la borra       */

/* Necesita `bun`, que sabe importar TypeScript sin compilar nada. Con node
   se salta en vez de fallar: que falte una herramienta no es un error del
   código. */
if (!globalThis.Bun) { console.log('\n(se salta: correr con `bun pruebas/empuje-a-fudo.mjs`)\n'); process.exit(0); }

let handler = null;
let PATCHES = 0, MAX_VIVOS = 0, vivos = 0;
let BITACORAZOS = [];      // cada POST a fudo_stock_push, por separado
let LENTITUD_MS = 0;       // cuánto tarda Fudo en contestar cada PATCH
let AUTHS = 0;             // cuántas veces se le pidió token a Fudo (por bloque)
let EMITIDOS = 0;          // llaves distintas emitidas (nunca se reinicia)
let CUELGA = false;        // Fudo acepta la llamada y no contesta nunca
let TROPIEZOS = 0;         // cuántas veces contestar 429 antes de aceptar
let RECHAZA_TOKEN = false; // Fudo contesta 401 la primera vez de cada PATCH
let TOPE_MS = '60000';         // el presupuesto de toda la corrida
let TOPE_LLAMADA_MS = '15000'; // el reloj de CADA llamada a Fudo

const CUANTOS = 40;
const productos = Array.from({length:CUANTOS}, (_,i)=>({
  fudo_product_id: String(i+1), producto_fudo: 'Producto '+(i+1),
  stock_en_fudo: 1, stock_calculado: 9,
  insumo_que_limita:'x', insumos:'y', ignorados:null, sumados:null, deja_en_cero:false,
}));

globalThis.Deno = {
  serve: (h) => { handler = h; },
  env: { get: (k) => ({
    SUPABASE_URL:'https://sb.local', SUPABASE_SERVICE_ROLE_KEY:'k',
    FUDO_PLAZA_APIKEY:'a', FUDO_PLAZA_APISECRET:'b',
    EMPUJE_TOPE_MS: TOPE_MS,
    EMPUJE_TOPE_LLAMADA_MS: TOPE_LLAMADA_MS,
  })[k] },
};
const respuesta = (obj, status=200) =>
  new Response(JSON.stringify(obj), {status, headers:{'Content-Type':'application/json'}});

globalThis.fetch = async (url, opt={}) => {
  const u = String(url);
  if (u.includes('/rpc/fudo_stock_calculado')) return respuesta(productos);
  /* El contador de tokens NO se reinicia entre bloques: si dos llaves
     distintas se llamaran igual, un reintento parecería fallar cuando en
     realidad funcionó. (Pasó, y era culpa de la prueba, no del código.) */
  if (u.includes('auth.fu.do')) { AUTHS++; EMITIDOS++; return respuesta({token:'t'+EMITIDOS}); }
  if (u.includes('/rest/v1/fudo_stock_push')) {
    BITACORAZOS.push(JSON.parse(opt.body).length);
    return respuesta({});
  }
  if (u.includes('api.fu.do')) {
    /* Se queda colgada: ni contesta ni corta. Es el caso que tumbó el
       sistema — solo la señal de aborto puede sacarnos de acá.
       Vale para CUALQUIER llamada a Fudo, no solo el PATCH: el botón de
       contingencia hace una lectura, y si esa prueba no se colgara, el
       botón estaría comprobado contra un mundo donde el bug no existe. */
    if (CUELGA) return new Promise((_, rechazar) => {
      opt.signal?.addEventListener('abort', () => {
        const e = new Error('abortado'); e.name = 'AbortError'; rechazar(e);
      });
    });
    // La lectura del pulso: un producto, nada más.
    if ((opt.method ?? 'GET') === 'GET') return respuesta({data:[{id:'1', type:'Product'}]});
  }
  if (u.includes('api.fu.do') && opt.method === 'PATCH') {
    if (TROPIEZOS > 0) { TROPIEZOS--; return respuesta({error:'calma'}, 429); }
    if (RECHAZA_TOKEN && opt.headers.Authorization === 'Bearer t1') {
      return respuesta({error:'token vencido'}, 401);   // la llave guardada ya no sirve
    }
    PATCHES++; vivos++; MAX_VIVOS = Math.max(MAX_VIVOS, vivos);
    /* Siempre se cede el turno, aunque sea 1 ms: sin un punto de espera de
       verdad no se puede observar si hay dos llamadas en vuelo. */
    await new Promise(r => setTimeout(r, LENTITUD_MS || 1));
    vivos--;
    const id = u.split('/').pop();
    return respuesta({data:{type:'Product', id, attributes:{stock:9}}});
  }
  return respuesta({});
};

await import('../supabase/functions/fudo-empujar-stock/index.ts');
if (!handler) { console.log('la función no se registró'); process.exit(1); }

const empujar = () => handler(new Request('https://x/f', {
  method:'POST', headers:{'Content-Type':'application/json'},
  body: JSON.stringify({sede:'plaza', modo:'aplicar', incluir_ceros:true}),
}));

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message); }
};
const reset = () => { PATCHES=0; MAX_VIVOS=0; vivos=0; BITACORAZOS=[]; AUTHS=0; };

console.log('\nCon Fudo contestando rápido:');
reset();
let r = await (await empujar()).json();
await caso('se mandaron los '+CUANTOS, () => PATCHES === CUANTOS || 'se mandaron '+PATCHES);
await caso('no quedó ninguno pendiente', () => r.pendientes === 0 || 'quedaron '+r.pendientes);
await caso('los '+CUANTOS+' cuentan como actualizados', () => r.actualizados === CUANTOS || 'dice '+r.actualizados);
await caso('la bitácora se guardó en tandas, no de una', () =>
  BITACORAZOS.length >= 2 || 'se guardó en '+BITACORAZOS.length+' viaje(s): un corte la borraría entera');
await caso('y quedó anotado uno por producto', () => {
  const t = BITACORAZOS.reduce((a,b)=>a+b,0);
  return t === CUANTOS || 'se anotaron '+t+' de '+CUANTOS;
});

console.log('\nLa respuesta dice en qué se fue el tiempo:');
await caso('trae el desglose', () =>
  (r.tiempos && 'calculo' in r.tiempos && 'auth' in r.tiempos && 'fudo' in r.tiempos)
  || 'no viene el desglose de tiempos');
await caso('y el promedio por producto', () =>
  typeof r.tiempos.por_producto === 'number' || 'falta por_producto');

console.log('\nLa llave de Fudo se guarda entre llamadas:');
reset();
await empujar();
const authsSegunda = AUTHS;
await caso('la segunda corrida no vuelve a pedir token', () =>
  authsSegunda === 0 || 'pidió token '+authsSegunda+' vez/veces teniendo uno guardado');

console.log('\nY si la llave guardada venció, se pide otra y se reintenta:');
reset();
RECHAZA_TOKEN = true;
r = await (await empujar()).json();
RECHAZA_TOKEN = false;
await caso('pidió una llave nueva', () => AUTHS >= 1 || 'no pidió ninguna: los empujes se perderían');
await caso('y los '+CUANTOS+' llegaron igual', () => r.actualizados === CUANTOS || 'llegaron '+r.actualizados);

console.log('\nCon Fudo lento, se ve el paralelo:');
reset();
LENTITUD_MS = 200;
const t0 = Date.now();
r = await (await empujar()).json();
const duro = Date.now() - t0;
await caso('de a varios a la vez, no de a uno', () =>
  MAX_VIVOS > 1 || 'nunca hubo dos en vuelo: sigue siendo uno por vez');
await caso('y nunca más de 5 a la vez', () =>
  MAX_VIVOS <= 5 || 'llegó a '+MAX_VIVOS+' — demasiado para la API de Fudo');
await caso('los 40 tardaron lo de 8 tandas, no lo de 40', () =>
  duro < CUANTOS * 200 * 0.5 || 'tardó '+duro+' ms, o sea siguió de a uno');
await caso('igual se mandaron los '+CUANTOS, () => PATCHES === CUANTOS || 'se mandaron '+PATCHES);

console.log('\nCuando se acaba el tiempo: para y lo DICE, no muere de 504:');
reset();
TOPE_MS = '1200';                        // 1,2 s de presupuesto
LENTITUD_MS = 200;
r = await (await empujar()).json();
LENTITUD_MS = 0; TOPE_MS = '60000';
await caso('no alcanzó a mandarlos todos', () => PATCHES < CUANTOS || 'los mandó todos: el tope no cortó');
await caso('y avisa cuántos quedaron', () => r.pendientes > 0 || 'dice que no queda ninguno');
await caso('todo lo que se mandó quedó anotado', () => {
  const t = BITACORAZOS.reduce((a,b)=>a+b,0);
  return t === PATCHES || 'se mandaron '+PATCHES+' y se anotaron '+t;
});
await caso('lo hecho + lo pendiente da el total', () =>
  (r.actualizados + r.con_error + r.pendientes) === CUANTOS
  || `${r.actualizados}+${r.con_error}+${r.pendientes} no da ${CUANTOS}`);

console.log('\nSi una llamada se queda COLGADA (lo del 21 de agosto):');
reset();
CUELGA = true;
TOPE_LLAMADA_MS = '300';                 // el reloj corto, para no esperar 15 s de verdad
const t1 = Date.now();
r = await (await empujar()).json();
const duro2 = Date.now() - t1;
CUELGA = false; TOPE_LLAMADA_MS = '15000';
/* Con el reloj en 0,3 s los 40 productos se cortan en ~3 s. Sin el reloj
   por llamada, esto se comía los 60 s del presupuesto entero — que es
   justo lo que la plataforma mata con un 504. */
await caso('la función termina igual, no se queda esperando', () =>
  duro2 < 20_000 || 'tardó '+Math.round(duro2/1000)+' s: sigue colgándose');
await caso('cada producto queda marcado con error, no perdido', () =>
  r.con_error > 0 || 'no reportó ningún error habiendo fallado todo');
await caso('y el error dice que no contestó, no "AbortError"', () => {
  const e = (r.errores||[])[0];
  return (e && /no contest/i.test(e.error)) || 'dice: '+(e && e.error);
});

console.log('\nSi Fudo tropieza (429) se reintenta, no se pierde el producto:');
reset();
TROPIEZOS = 3;
r = await (await empujar()).json();
await caso('igual llegaron los '+CUANTOS, () => PATCHES === CUANTOS || 'llegaron '+PATCHES);
await caso('y queda dicho que hubo que reintentar', () =>
  r.tiempos.reintentos === 3 || 'dice '+r.tiempos.reintentos+' reintentos, esperaba 3');

console.log('\nTomarle el pulso a Fudo (el botón de contingencia):');
reset();
let p = await (await handler(new Request('https://x/f', {
  method:'POST', headers:{'Content-Type':'application/json'},
  body: JSON.stringify({sede:'plaza', modo:'probar'}),
}))).json();
await caso('no manda ni un solo producto', () => PATCHES === 0 || 'mandó '+PATCHES);
await caso('dice que Fudo responde', () => p.fudo_responde === true || 'dice '+p.fudo_responde);
await caso('mide cuánto tardó la lectura', () => typeof p.lectura_ms === 'number' || 'falta lectura_ms');
await caso('dice cuántos hay por empujar', () => p.por_empujar === CUANTOS || 'dice '+p.por_empujar);
await caso('y da un veredicto en castellano', () =>
  (p.veredicto && p.veredicto.length > 5) || 'sin veredicto');

reset();
CUELGA = true; TOPE_LLAMADA_MS = '300';
p = await (await handler(new Request('https://x/f', {
  method:'POST', headers:{'Content-Type':'application/json'},
  body: JSON.stringify({sede:'plaza', modo:'probar'}),
}))).json();
CUELGA = false; TOPE_LLAMADA_MS = '15000';
await caso('con Fudo caído lo dice, y no se cuelga', () =>
  (p.fudo_responde === false && /no está contestando/i.test(p.veredicto))
  || 'veredicto: '+p.veredicto);

console.log(`\n${ok} bien · ${mal} mal\n`);
process.exit(mal ? 1 : 0);
