/* DE DÓNDE SALE CADA PRODUCTO.  node pruebas/origen-del-reparto.mjs
   ---------------------------------------------------------------------------
   POR QUÉ EXISTE. Jhon lo encontró razonando el modelo, no viéndolo fallar:
   hay productos que llegan al local directo del PROVEEDOR y nunca pasan por
   bodega —las medialunas—. Adriana igual arma esa línea desde Bodega, porque
   es ella quien organiza el envío. Y hasta hoy Llamita daba por hecho que
   todo lo que sale de esa pantalla sale de bodega.

   Hoy no se nota porque bodega recién se está contando. Dentro de un mes, con
   el conteo cuadrado, bodega diría 0 medialunas donde hay 7. Es un fallo
   silencioso de los caros: nadie lo vería hasta que Adriana pidiera de más.

   Lo que se comprueba acá es una sola idea, en las dos direcciones:
     · una línea DE BODEGA viaja con `producto_bodega_id`  -> bodega baja
     · una línea DE PROVEEDOR viaja SIN ese número         -> bodega no se toca
   El motor (`reparto_recibir`) ya funcionaba así. Nunca faltó lógica:
   faltaba una forma de decirle que no.                                     */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

/* Bodega tiene las medialunas cargadas (existen ahí), y por eso el enlace
   existe y el error era posible: nada delataba que ESAS venían de fuera. */
const BODEGA = [
  {id:900, sede:'central', producto:'Medialuna', rubro:'Bodega', stock_actual:7,  stock_min:2, stock_max:40, activo:'SÍ'},
  {id:901, sede:'central', producto:'Alfajor',   rubro:'Bodega', stock_actual:20, stock_min:2, stock_max:60, activo:'SÍ'},
];
const PLAZA = [
  {id:10, sede:'plaza', producto:'Medialuna', rubro:'Vitrina de dulces', stock_actual:1, stock_min:6, stock_max:12, activo:'SÍ'},
  {id:11, sede:'plaza', producto:'Alfajor',   rubro:'Vitrina de dulces', stock_actual:0, stock_min:4, stock_max:10, activo:'SÍ'},
  {id:12, sede:'plaza', producto:'Cachito',   rubro:'Vitrina de dulces', stock_actual:9, stock_min:3, stock_max:12, activo:'SÍ'},
];
const ENLACES = [
  {sede:'plaza', producto_bodega_id:900, producto_sede_id:10},
  {sede:'plaza', producto_bodega_id:901, producto_sede_id:11},
];

const page = await browser.newPage();
await page.addInitScript(({BODEGA, PLAZA, ENLACES}) => {
  window.__escrito = [];
  const SES = {user:{id:'u1', email:'adriana@cafe.cl', user_metadata:{nombre:'Adriana'}}};
  const T = {productos:[...BODEGA, ...PLAZA], producto_enlace:ENLACES,
    app_permisos:[{correo:'adriana@cafe.cl', nombre:'Adriana', puede_ajustes:true, puede_editar:true, puede_fudo:true, fudo_bloqueos:[]}],
    fudo_sync:[], secciones:[], movimientos:[], ajustes:[], metas:[], historial:[],
    restauraciones:[], fusiones:[], fudo_stock_push:[], recetas:[], receta_items:[],
    fudo_productos:[], producto_lotes:[], repartos:[], reparto_items:[], mermas:[],
    tareas:[], fudo_categorias:[], envios_franquicia:[], envios_franquicia_items:[]};
  let seq = 7000;
  const q = (n) => {
    let filas = JSON.parse(JSON.stringify(T[n]||[]));
    const api = {
      select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
      in(c,vs){ filas=filas.filter(f=>vs.map(String).includes(String(f[c]))); return api;},
      neq(){return api;}, order(){return api;}, limit(){return api;}, gte(){return api;},
      lte(){return api;}, is(){return api;}, not(){return api;}, or(){return api;}, ilike(){return api;},
      maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},
      single(){return Promise.resolve({data:filas[0]||null,error:null});},
      insert(v){ const rows=(Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
        window.__escrito.push({tabla:n, filas:rows});
        const e={select:()=>e, single:()=>Promise.resolve({data:rows[0],error:null}),
                 then:f=>Promise.resolve({data:rows,error:null}).then(f)};
        return e; },
      update(){const e={eq:()=>e,select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      upsert(){const e={select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      delete(){return api;},
      then(f){return Promise.resolve({data:filas,error:null,count:filas.length}).then(f);},
    };
    return api;
  };
  window.supabase = { createClient: () => ({
    from:q, rpc:()=>Promise.resolve({data:[],error:null}),
    auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
           onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
           signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
    channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
    removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
  })};
}, {BODEGA, PLAZA, ENLACES});
await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
const errores = [];
page.on('pageerror', e=>errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(350);

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

await page.click('.gate-btn[data-sede="central"]');
await page.waitForTimeout(600);
await page.click('#tabEnvios').catch(()=>{});
await page.waitForTimeout(600);

/* Desde el 2026-08-22 la lista de lo que falta vive ABIERTA dentro de la
   pantalla, no detrás de un "ver lista". Que esté completa y ordenada se
   comprueba en pruebas/reparto-unificado.mjs; acá solo se usa para armar el
   carro, que es lo que esta prueba necesita. */
console.log('\nSe arma el reparto desde la lista de lo que falta:');
await caso('la lista está a la vista', async () =>
  await page.isVisible('.repc-falta') || 'no se ve el panel de lo que falta');
await caso('agregar la medialuna', async () => {
  await page.click('[data-rfadd="plaza-10"]'); await page.waitForTimeout(300);
  return (await page.evaluate(()=>repcCarritos.plaza.length)) === 1 || 'no la agregó';
});
await caso('con lo que le falta para el máximo', async () =>
  (await page.evaluate(()=>repcCarritos.plaza[0].cantidad)) === 11
  || 'propuso '+(await page.evaluate(()=>repcCarritos.plaza[0].cantidad)));
await caso('y el alfajor', async () => {
  await page.click('[data-rfadd="plaza-11"]'); await page.waitForTimeout(300);
  return (await page.evaluate(()=>repcCarritos.plaza.length)) === 2 || 'no lo agregó';
});

console.log('\nEl origen de cada línea:');
await caso('las dos nacen "de bodega"', async () => {
  const c = await page.evaluate(()=>repcCarritos.plaza.map(x=>x.origen));
  return c.every(x=>x==='bodega') || 'nacieron: '+c.join(', ');
});
await caso('la píldora dice de dónde sale', async () => {
  const t = await page.textContent('#repc-cajas');
  return t.includes('de bodega') || 'no lo dice';
});
await caso('se puede marcar una como "de proveedor"', async () => {
  const b = await page.$$('[data-repcorigen]');
  if(!b.length) return 'no hay dónde tocar el origen';
  await b[0].click(); await page.waitForTimeout(300);
  const c = await page.evaluate(()=>repcCarritos.plaza[0].origen);
  return c === 'proveedor' || 'quedó en '+c;
});
await caso('y se ve distinto en pantalla', async () =>
  (await page.textContent('#repc-cajas')).includes('de proveedor') || 'se ve igual que la de bodega');

console.log('\nAL ENVIAR — esto es lo que evita el error de las medialunas:');
await page.evaluate(()=>{window.__escrito=[];});
await page.click('[data-repcenviar="plaza"]'); await page.waitForTimeout(700);
await caso('la línea DE PROVEEDOR viaja sin producto_bodega_id', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='reparto_items'));
  if(!w) return 'no se escribieron líneas';
  const l = w.filas.find(f=>f.producto_id===10);
  return (l && l.producto_bodega_id === null)
    || 'viajó con producto_bodega_id='+(l && l.producto_bodega_id)+': bodega descontaría de más';
});
await caso('la línea DE BODEGA sí lo lleva', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='reparto_items'));
  const l = w.filas.find(f=>f.producto_id===11);
  return (l && l.producto_bodega_id === 901)
    || 'viajó con '+(l && l.producto_bodega_id)+': bodega no bajaría cuando debe';
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno', () => errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
