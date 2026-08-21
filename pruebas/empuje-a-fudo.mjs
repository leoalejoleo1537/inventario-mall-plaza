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
let TOPE_MS = '60000';     // el presupuesto de tiempo de la función

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
  })[k] },
};
const respuesta = (obj, status=200) =>
  new Response(JSON.stringify(obj), {status, headers:{'Content-Type':'application/json'}});

globalThis.fetch = async (url, opt={}) => {
  const u = String(url);
  if (u.includes('/rpc/fudo_stock_calculado')) return respuesta(productos);
  if (u.includes('auth.fu.do'))                return respuesta({token:'t'});
  if (u.includes('/rest/v1/fudo_stock_push')) {
    BITACORAZOS.push(JSON.parse(opt.body).length);
    return respuesta({});
  }
  if (u.includes('api.fu.do') && opt.method === 'PATCH') {
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
const reset = () => { PATCHES=0; MAX_VIVOS=0; vivos=0; BITACORAZOS=[]; };

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

console.log(`\n${ok} bien · ${mal} mal\n`);
process.exit(mal ? 1 : 0);
