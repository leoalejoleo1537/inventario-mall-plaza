/* ANGAMOS LE MANDA A MALL PLAZA.  node pruebas/angamos-a-plaza.mjs
   ---------------------------------------------------------------------------
   Jhon, 2026-08-22: "cuando una torta está a punto de vencerse o un
   sandwichito, este es enviado a mall plaza". Angamos vende poco y Plaza tiene
   alto flujo, así que Angamos hace de bodega chica.

   LO QUE IMPORTA COMPROBAR, y no es la pantalla: que la línea viaje con los
   DOS números — a quién se le suma (Plaza) y a quién se le resta (Angamos)—.
   Si faltara el segundo, Plaza sumaría y en Angamos no bajaría nada: producto
   duplicado dentro del sistema. Es el error de las medialunas al revés.

   El descuento en sí lo hace la base y está probado en SQL contra un Postgres
   local; acá se prueba que la app le mande lo que necesita.                 */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const ANGAMOS = [
  {id:20, sede:'angamos', producto:'Torta amor',   rubro:'Vitrina de tortas', stock_actual:6, stock_min:2, stock_max:10, activo:'SÍ'},
  {id:21, sede:'angamos', producto:'Sandwich Azapa',rubro:'Sándwiches',       stock_actual:4, stock_min:2, stock_max:8,  activo:'SÍ'},
  /* Este NO existe en Plaza: no se tiene que poder mandar, porque allá no
     habría a qué producto sumarle. */
  {id:22, sede:'angamos', producto:'Empanada de pino', rubro:'Vitrina', stock_actual:9, stock_min:1, stock_max:12, activo:'SÍ'},
];
const PLAZA = [
  {id:10, sede:'plaza', producto:'Torta amor',     rubro:'Vitrina de tortas', stock_actual:1, stock_min:3, stock_max:8, activo:'SÍ'},
  {id:11, sede:'plaza', producto:'Sandwich Azapa', rubro:'Sándwiches',        stock_actual:0, stock_min:2, stock_max:6, activo:'SÍ'},
];

const page = await browser.newPage();
await page.addInitScript(({ANGAMOS, PLAZA}) => {
  window.__escrito = [];
  const SES = {user:{id:'u1', email:'jefe@ang.cl', user_metadata:{nombre:'Jefe Angamos'}}};
  const T = {productos:[...ANGAMOS, ...PLAZA],
    app_permisos:[{correo:'jefe@ang.cl', nombre:'Jefe Angamos', puede_ajustes:false, puede_editar:true, puede_fudo:true, fudo_bloqueos:[]}],
    fudo_sync:[], secciones:[], movimientos:[], ajustes:[], metas:[], historial:[],
    restauraciones:[], fusiones:[], fudo_stock_push:[], recetas:[], receta_items:[],
    fudo_productos:[], producto_lotes:[], repartos:[], reparto_items:[], mermas:[],
    producto_enlace:[], tareas:[], fudo_categorias:[]};
  let seq = 8000;
  const q = (n) => {
    let filas = JSON.parse(JSON.stringify(T[n]||[]));
    const api = {
      select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
      in(){return api;}, neq(){return api;}, order(){return api;}, limit(){return api;},
      gte(){return api;}, lte(){return api;}, is(){return api;}, not(){return api;},
      or(){return api;}, ilike(){return api;},
      maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},
      single(){return Promise.resolve({data:filas[0]||null,error:null});},
      insert(v){ const rows=(Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
        window.__escrito.push({tabla:n, filas:rows});
        const e={select:()=>e, single:()=>Promise.resolve({data:rows[0],error:null}),
                 then:f=>Promise.resolve({data:rows,error:null}).then(f)}; return e; },
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
    removeChannel(){}, functions:{invoke:async(nombre,opt)=>{ window.__escrito.push({fn:nombre, body:opt&&opt.body});
      return {data:{ok:true, actualizados:1}, error:null}; }},
  })};
}, {ANGAMOS, PLAZA});
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

console.log('\nLa pestaña vive SOLO en Angamos:');
await page.click('.gate-btn[data-sede="plaza"]'); await page.waitForTimeout(500);
await caso('en Mall Plaza no aparece', async () =>
  !(await page.isVisible('#tabAPlaza')) || 'aparece donde no corresponde');
await page.click('#btnMenu'); await page.waitForTimeout(200);
await page.click('[data-accion="cambiar-sede"]'); await page.waitForTimeout(300);
await page.click('.gate-btn[data-sede="angamos"]'); await page.waitForTimeout(600);
await caso('en Parque Angamos sí', async () =>
  await page.isVisible('#tabAPlaza') || 'no aparece');
await caso('y se llama por su destino, no "Reparto"', async () => {
  const t = await page.textContent('#tabAPlaza');
  return t.includes('Plaza') || 'dice: '+t;
});

console.log('\nSe arma el envío:');
await page.click('#tabAPlaza'); await page.waitForTimeout(700);
await caso('se abre la pantalla', async () => await page.isVisible('#view-aplaza') || 'no se abrió');
await page.fill('#ap-q','torta'); await page.waitForTimeout(400);
await caso('busca en MI inventario', async () =>
  (await page.textContent('#ap-results')).includes('acá hay 6') || 'no muestra mi stock');
await caso('y dice a qué producto de Plaza va', async () =>
  (await page.textContent('#ap-results')).includes('va a: Torta amor') || 'no dice el destino');
await caso('mostrando cuánto hay allá', async () =>
  (await page.textContent('#ap-results')).includes('allá hay 1') || 'no muestra el stock de Plaza');

await caso('lo que NO existe en Plaza no se puede mandar', async () => {
  await page.fill('#ap-q','empanada'); await page.waitForTimeout(400);
  const t = await page.textContent('#ap-results');
  const desactivado = await page.getAttribute('[data-apadd="22"]','disabled');
  return (t.includes('no existe en Mall Plaza') && desactivado !== null)
    || 'deja mandar algo que allá no existe: no habría a qué sumarle';
});

await page.fill('#ap-q','torta'); await page.waitForTimeout(400);
await page.click('[data-apadd="20"]'); await page.waitForTimeout(300);
await caso('se agrega al carro', async () =>
  (await page.evaluate(()=>apCarrito.length)) === 1 || 'no se agregó');
await caso('la línea dice de dónde sale y cuánto queda', async () =>
  (await page.textContent('#ap-carrito')).includes('Sale de Angamos · 6 → 5') || 'no lo dice');

console.log('\nSe puede escribir la cantidad sin perder el campo:');
await caso('escribir 22 de corrido deja 22', async () => {
  await page.click('[data-apidx="0"]');
  await page.keyboard.press('Control+a');
  await page.keyboard.type('22', {delay:60});
  await page.waitForTimeout(300);
  return (await page.evaluate(()=>apCarrito[0].cantidad)) === 22
    || 'quedó en '+(await page.evaluate(()=>apCarrito[0].cantidad))+': el campo se pierde al teclear';
});
await caso('y el foco sigue en el mismo campo', async () =>
  (await page.evaluate(()=>document.activeElement && document.activeElement.dataset.apidx)) === '0'
  || 'el foco se fue a otro lado');

console.log('\nAL ENVIAR — los dos números, que es lo que evita duplicar producto:');
await page.evaluate(()=>{ apCarrito[0].cantidad = 2; apPintarCarrito(); window.__escrito=[]; });
await page.click('#ap-enviar'); await page.waitForTimeout(900);
await caso('el reparto se crea para PLAZA', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='repartos'));
  return (w && w.filas[0].sede === 'plaza') || 'lo creó para '+(w && w.filas[0].sede);
});
await caso('y dice que viene de Parque Angamos', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='repartos'));
  return (w && w.filas[0].origen === 'Parque Angamos') || 'origen: '+(w && w.filas[0].origen);
});
await caso('la línea le SUMA al producto de Plaza', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='reparto_items'));
  return (w && w.filas[0].producto_id === 10) || 'apunta a '+(w && w.filas[0].producto_id);
});
await caso('y le RESTA al de Angamos', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='reparto_items'));
  return (w && w.filas[0].producto_origen_id === 20)
    || 'sin producto_origen_id: Plaza sumaria y Angamos no bajaria — producto duplicado';
});
await caso('NO usa la columna de bodega', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='reparto_items'));
  return !w.filas[0].producto_bodega_id
    || 'metió el origen en producto_bodega_id: bodega bajaría sin haber mandado nada';
});
await caso('el carro queda vacío', async () =>
  (await page.evaluate(()=>apCarrito.length)) === 0 || 'quedó lleno');

console.log('\nSin errores de JavaScript:');
await caso('ninguno', () => errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
