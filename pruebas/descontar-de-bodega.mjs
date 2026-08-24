/* EL BOTÓN "DESCONTAR DE BODEGA" DE CADA LISTA.
   node pruebas/descontar-de-bodega.mjs

   POR QUÉ EXISTE. Jhon, 2026-08-22: Adriana armó varios repartos desde la
   pantalla de la SEDE en vez de desde Bodega -> Enviar, creyendo que igual
   se iba a descontar de bodega. No se descontó: el local sumó de verdad y
   bodega nunca se enteró.

   La solución es de él y es mejor que un script retroactivo: un botón en
   cada lista, con vista previa, una por una y a la vista.

   Lo que de verdad se comprueba acá es CUÁNDO NO aparece el botón, que es
   la mitad difícil: una lista bien armada no lo muestra, una ya descontada
   tampoco, y en el local no se ve nunca — el jefe de turno no tiene por qué
   mover el stock de otra sede.                                            */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const PRODUCTOS = [
  {id:900, sede:'central', producto:'Alfajor',   rubro:'Bodega', stock_actual:20, stock_min:2, stock_max:60, activo:'SÍ'},
  {id:10,  sede:'plaza',   producto:'Alfajor',   rubro:'Congelador', stock_actual:9, stock_min:4, stock_max:10, activo:'SÍ'},
  {id:11,  sede:'plaza',   producto:'Servilleta',rubro:'Mueble de bolsas', stock_actual:2, stock_min:20, stock_max:80, activo:'SÍ'},
];
const ENLACES = [{id:1, sede:'plaza', producto_bodega_id:900, producto_sede_id:10}];

/* 1 · armado en el local, recibido, CON enlace  -> el botón tiene que salir
   2 · armado desde bodega (trae producto_bodega_id) -> NO
   3 · armado en el local pero SIN enlace (Servilleta) -> NO
   4 · todavía pendiente, nadie lo recibió -> NO                            */
const REPARTOS = [
  {id:1, sede:'plaza', estado:'cerrado', creado_por:'Adriana', origen:'Bodega', created_at:new Date().toISOString()},
  {id:2, sede:'plaza', estado:'cerrado', creado_por:'Adriana', origen:'Bodega', created_at:new Date().toISOString()},
  {id:3, sede:'plaza', estado:'cerrado', creado_por:'Adriana', origen:'Bodega', created_at:new Date().toISOString()},
  {id:4, sede:'plaza', estado:'abierto', creado_por:'Adriana', origen:'Bodega', created_at:new Date().toISOString()},
];
const ITEMS = [
  {id:501, reparto_id:1, producto_id:10, producto:'Alfajor', cantidad_pedida:15, cantidad_recibida:15,
   estado:'recibido', producto_bodega_id:null, producto_origen_id:null, resuelto_por:'Jefe'},
  {id:502, reparto_id:2, producto_id:10, producto:'Alfajor', cantidad_pedida:5, cantidad_recibida:5,
   estado:'recibido', producto_bodega_id:900, producto_origen_id:null, resuelto_por:'Jefe'},
  {id:503, reparto_id:3, producto_id:11, producto:'Servilleta', cantidad_pedida:12, cantidad_recibida:12,
   estado:'recibido', producto_bodega_id:null, producto_origen_id:null, resuelto_por:'Jefe'},
  {id:504, reparto_id:4, producto_id:10, producto:'Alfajor', cantidad_pedida:3, cantidad_recibida:null,
   estado:'pendiente', producto_bodega_id:null, producto_origen_id:null},
];

const page = await browser.newPage();
await page.addInitScript(({PRODUCTOS, ENLACES, REPARTOS, ITEMS}) => {
  window.__rpc = [];
  const SES = {user:{id:'u1', email:'a@c.cl', user_metadata:{nombre:'Adriana'}}};
  const T = {productos:PRODUCTOS, producto_enlace:ENLACES, repartos:REPARTOS, reparto_items:ITEMS,
    app_permisos:[{correo:'a@c.cl', nombre:'Adriana', puede_ajustes:true, puede_editar:true, puede_fudo:true, fudo_bloqueos:[]}],
    fudo_sync:[], secciones:[], movimientos:[], ajustes:[], metas:[], historial:[], restauraciones:[],
    fusiones:[], fudo_stock_push:[], recetas:[], receta_items:[], fudo_productos:[], producto_lotes:[],
    mermas:[], tareas:[], fudo_categorias:[], envios_franquicia:[], envios_franquicia_items:[]};
  const q = (n) => {
    let filas = JSON.parse(JSON.stringify(T[n]||[]));
    const api = {
      select(){ if(n==='repartos') filas = filas.map(r=>({...r, reparto_items:(T.reparto_items||[]).filter(i=>i.reparto_id===r.id)})); return api; },
      eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api; },
      in(c,vs){ filas=filas.filter(f=>vs.map(String).includes(String(f[c]))); return api; },
      neq(){return api;}, order(){return api;}, limit(){return api;}, gte(){return api;},
      lte(){return api;}, is(){return api;}, not(){return api;}, or(){return api;}, ilike(){return api;},
      maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},
      single(){return Promise.resolve({data:filas[0]||null,error:null});},
      insert(){const e={select:()=>e,single:()=>Promise.resolve({data:null,error:null}),then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      update(){const e={eq:()=>e,select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      upsert(){const e={select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      delete(){return api;},
      then(f){return Promise.resolve({data:filas,error:null,count:filas.length}).then(f);},
    };
    return api;
  };
  window.supabase = { createClient: () => ({
    from:q,
    rpc:(nombre,args)=>{ window.__rpc.push({nombre,args});
      return Promise.resolve({data:{lineas:1, unidades:15, falto:0}, error:null}); },
    auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
           onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
           signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
    channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
    removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
  })};
}, {PRODUCTOS, ENLACES, REPARTOS, ITEMS});
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

/* EL BOTÓN VIVE EN EL LOCAL, y esto es lo que la primera versión de esta
   prueba destapó: un reparto vive en la sede que RECIBE, así que desde
   Bodega estas listas ni siquiera se cargan. El botón puesto solo en
   central no aparecía nunca. */
console.log('\nEn la sede que recibió, solo en las listas que lo necesitan:');
await page.click('.gate-btn[data-sede="plaza"]'); await page.waitForTimeout(600);
await page.click('.tab[data-tab="reparto"]'); await page.waitForTimeout(700);
/* "Repartos cerrados" está plegado por defecto: es historial. Se abre la
   sección y cada lista de adentro, que es lo que haría Adriana. */
await page.click('[data-caja="cerrados"]'); await page.waitForTimeout(300);
await page.evaluate(()=>{ [1,2,3].forEach(id=>cajasAbiertas.add('cerr'+id)); renderRepartos(); });
await page.waitForTimeout(400);

await caso('sale en la lista armada desde el local, con enlace', async () =>
  await page.isVisible('[data-descbodega="1"]') || 'no aparece donde hace falta');
await caso('y dice cuántas líneas va a tocar', async () =>
  (await page.textContent('[data-descbodega="1"]')).includes('1 línea') || 'no dice cuántas');
await caso('NO sale en la armada desde Bodega (ya descontó al confirmarse)', async () =>
  (await page.$$('[data-descbodega="2"]')).length === 0 || 'ofrece descontar dos veces');
await caso('NO sale si el producto no tiene enlace', async () =>
  (await page.$$('[data-descbodega="3"]')).length === 0
  || 'ofrece descontar algo que no sabe de dónde bajar');
await caso('NO sale en una lista que nadie recibió todavía', async () => {
  await page.evaluate(()=>{ cajasAbiertas.add('rep4'); renderRepartos(); });
  await page.waitForTimeout(300);
  return (await page.$$('[data-descbodega="4"]')).length === 0
    || 'ofrece descontar algo que todavía no llegó';
});

console.log('\nAl apretarlo: vista previa antes de tocar nada:');
await page.click('[data-descbodega="1"]'); await page.waitForTimeout(400);
await caso('se abre la ventana de confirmación', async () =>
  await page.isVisible('#overlay-ask') || 'descontó sin preguntar');
await caso('dice qué producto de bodega baja y a cuánto queda', async () => {
  const t = await page.textContent('#ask-detalle');
  return t.includes('Alfajor: 20 → 5') || 'dice: '+t.slice(0,80);
});
await caso('avisa que apretar dos veces no descuenta dos veces', async () =>
  (await page.textContent('#ask-detalle')).includes('dos veces') || 'no lo dice');
await caso('si se cancela, no llama a la base', async () => {
  await page.click('#ask-no'); await page.waitForTimeout(300);
  return (await page.evaluate(()=>window.__rpc.length)) === 0 || 'llamó igual';
});

console.log('\nAl confirmar:');
await page.click('[data-descbodega="1"]'); await page.waitForTimeout(400);
await page.click('#ask-ok'); await page.waitForTimeout(800);
await caso('llama a la función de la base con esa lista', async () => {
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='reparto_descontar_bodega'));
  return (r && r.args.p_reparto_id === 1) || 'llamó con: '+JSON.stringify(r);
});
await caso('y firma quién lo hizo', async () => {
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='reparto_descontar_bodega'));
  return (r && r.args.p_quien) ? true : 'no dice quién fue';
});
await caso('el botón desaparece: ya no hay nada que descontar ahí', async () =>
  (await page.$$('[data-descbodega="1"]')).length === 0
  || 'sigue ofreciendo descontar lo mismo otra vez');

console.log('\nSin errores de JavaScript:');
await caso('ninguno', () => errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
