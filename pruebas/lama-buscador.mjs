/* LLAMITA LAMA · el buscador dentro del panel de la mesa.
   node pruebas/lama-buscador.mjs

   POR QUÉ EXISTE ESTA PANTALLA: el garzón toma la orden mientras el cliente
   está hablando. Abrir una pantalla entera, buscar, elegir y volver es un
   viaje por producto, y en el mesón eso se nota. La barra tiene que estar ahí
   apenas se abre la mesa.

   LO QUE SE PRUEBA, y las dos primeras son pedidos textuales de Jhon:

     · la barra aparece sola al abrir la mesa, sin tocar "Agregar"
     · la lista de resultados FLOTA: no empuja ni deforma nada de atrás
     · escribir NO le saca el foco al campo — si no, en el teléfono el
       teclado se cierra en la primera letra
     · agregar un producto no vacía el buscador: se sigue escribiendo
     · las píldoras de lo más comandado son cuatro y agregan de un toque      */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const MESAS = Array.from({length:12}, (_,i)=>({
  id:100+i, sede:'plaza', salon:'Salón', numero:i+1, orden:i+1, activa:true }));
const CUENTAS = [
  {id:900, sede:'plaza', mesa_id:101, estado:'abierta', total:2900, abierta_por:'jhon@cafe.cl'},
];
const ITEMS = [
  {id:1, cuenta_id:900, nombre:'Medialuna manjar', cantidad:1, precio:2900,
   estado:'confirmado', comentario:null},
];
/* Una carta larga a propósito: así se comprueba que la lista flotante tiene su
   propio scroll y no estira la ventana. */
const CARTA = [
  {fudo_product_id:'F-33', sede:'plaza', nombre:'Americano',        precio:2500, activo:true},
  {fudo_product_id:'F-38', sede:'plaza', nombre:'Café Latte',       precio:3400, activo:true},
  {fudo_product_id:'F-40', sede:'plaza', nombre:'Café Cortado',     precio:3000, activo:true},
  {fudo_product_id:'F-41', sede:'plaza', nombre:'Café Mocaccino',   precio:3900, activo:true},
  {fudo_product_id:'F-99', sede:'plaza', nombre:'Medialuna manjar', precio:2900, activo:true},
  ...Array.from({length:30}, (_,i)=>({
    fudo_product_id:'F-2'+i, sede:'plaza', nombre:'Sándwich '+(i+1), precio:5200, activo:true})),
];

const page = await browser.newPage();
await page.setViewportSize({width:1280, height:900});

async function montar(){
  await page.addInitScript(({MESAS, CUENTAS, ITEMS, CARTA}) => {
    window.__rpc = [];
    const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
    const T = {
      productos:[], mesas:MESAS, cuentas:CUENTAS, cuenta_items:ITEMS, comandas:[],
      fudo_productos:CARTA, lama_medios_pago:[], lama_motivos_descuento:[],
      app_permisos:[{correo:'jhon@cafe.cl', nombre:'Jhon', puede_ajustes:true,
                     puede_editar:true, puede_fudo:true, puede_lama:true, fudo_bloqueos:[]}],
      producto_enlace:[], fudo_stock_push:[], fudo_sync:[], secciones:[], movimientos:[],
      ajustes:[], metas:[], historial:[], historial_auto:[], restauraciones:[], fusiones:[],
      recetas:[], receta_items:[], producto_lotes:[], repartos:[], reparto_items:[],
      mermas:[], tareas:[], fudo_categorias:[], envios_franquicia:[], envios_franquicia_items:[]};
    let seq = 7000;
    const q = (n) => {
      let filas = JSON.parse(JSON.stringify(T[n]||[]));
      const api = {
        select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
        neq(c,v){ filas=filas.filter(f=>String(f[c])!==String(v)); return api;},
        in(c,vs){ filas=filas.filter(f=>vs.map(String).includes(String(f[c]))); return api;},
        order(){return api;}, limit(){return api;}, gte(){return api;}, lte(){return api;},
        is(){return api;}, not(){return api;}, or(){return api;}, ilike(){return api;},
        maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},
        single(){return Promise.resolve({data:filas[0]||null,error:null});},
        insert(v){ const rows=(Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
          const e={select:()=>e, single:()=>Promise.resolve({data:rows[0],error:null}),
                   then:f=>Promise.resolve({data:rows,error:null}).then(f)}; return e; },
        update(){const e={eq:()=>e,in:()=>e,select:()=>e,
                 single:()=>Promise.resolve({data:filas[0]||null,error:null}),
                 then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        upsert(){const e={select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        delete(){const e={eq:()=>e,in:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        then(f){return Promise.resolve({data:filas,error:null,count:filas.length}).then(f);},
      };
      return api;
    };
    window.supabase = { createClient: () => ({
      from:q,
      rpc:(nombre, args)=>{
        window.__rpc.push({nombre, args});
        if(nombre === 'cuenta_agregar')
          return Promise.resolve({data:{id:++seq, cuenta_id:args.p_cuenta_id, nombre:args.p_nombre,
                                        cantidad:1, precio:args.p_precio, estado:'nuevo'}, error:null});
        return Promise.resolve({data:null, error:null});
      },
      auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
             onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
             signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
      channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
      removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
    })};
  }, {MESAS, CUENTAS, ITEMS, CARTA});
  await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
  await page.goto(pathToFileURL(join(raiz,'index.html')).href);
  await page.waitForTimeout(400);
  await page.click('.gate-btn[data-sede="plaza"]');
  await page.waitForTimeout(700);
  await page.click('#tabLama'); await page.waitForTimeout(500);
  await page.click('[data-lamamesa="101"]'); await page.waitForTimeout(400);
}

const errores = [];
page.on('pageerror', e=>errores.push(String(e)));

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

const caja = async sel => await page.evaluate(s => {
  const e = document.querySelector(s); if(!e) return null;
  const r = e.getBoundingClientRect();
  return {x:Math.round(r.x), y:Math.round(r.y), w:Math.round(r.width), h:Math.round(r.height)};
}, sel);

await montar();

console.log('\nC1 · LA BARRA ESTÁ, sin tener que ir a buscarla:');
await caso('al abrir la mesa, el buscador ya se ve', async () =>
  await page.isVisible('#lama-qp') || 'hay que tocar "Agregar" para buscar');
await caso('y el botón de agregar productos sigue estando', async () =>
  await page.isVisible('[data-lamaacc="mas"]') || 'se perdió el camino a la carta completa');

console.log('\nC3 · LAS PÍLDORAS de lo que más se comanda:');
await caso('son cuatro, ni más ni menos', async () => {
  const n = await page.evaluate(() => document.querySelectorAll('.lama-pil').length);
  return n === 4 || 'hay ' + n;
});
await caso('van en dos columnas', async () => {
  const c = await page.evaluate(() => {
    const g = document.querySelector('.lama-pildoras'); if(!g) return null;
    return getComputedStyle(g).gridTemplateColumns.split(' ').length;
  });
  return c === 2 || 'tiene ' + c + ' columnas';
});
await caso('tocar una agrega el producto de una', async () => {
  const antes = await page.evaluate(() => window.__rpc.length);
  await page.click('.lama-pil'); await page.waitForTimeout(500);
  const r = await page.evaluate(() => window.__rpc.map(x => x.nombre));
  return (r.length > antes && r.includes('cuenta_agregar'))
    || 'no llamó a cuenta_agregar; llamó a: ' + r.join(' · ');
});

console.log('\nC2 · LA LISTA FLOTA — no mueve nada de lo de atrás:');
/* LA PRUEBA QUE IMPORTA. Jhon: "no quiero que se traslade todo hacia abajo…
   esta lista no puede modificar la interfaz". Si empuja, el total y el botón
   de cobrar se van saltando con cada letra que se escribe. */
await caso('escribir NO mueve el botón de cobrar ni un pixel', async () => {
  const antes = await caja('[data-lamaacc="cobrar"]');
  await page.fill('#lama-qp', 'Sánd'); await page.waitForTimeout(350);
  const despues = await caja('[data-lamaacc="cobrar"]');
  if(!antes || !despues) return 'no encontré el botón';
  return antes.y === despues.y || `se movió de y=${antes.y} a y=${despues.y}`;
});
await caso('y la lista sí apareció', async () =>
  await page.isVisible('.lama-qp-lista') || 'no salió ninguna lista');
await caso('está POR ENCIMA, no dentro del flujo', async () => {
  const p = await page.evaluate(() => {
    const l = document.querySelector('.lama-qp-lista'); if(!l) return null;
    const s = getComputedStyle(l);
    return {pos:s.position, z:s.zIndex};
  });
  if(!p) return 'no está la lista';
  return (p.pos === 'absolute' && +p.z > 0)
    || `position:${p.pos} z-index:${p.z}`;
});
await caso('tiene su propio scroll y no estira el panel', async () => {
  const r = await page.evaluate(() => {
    const l = document.querySelector('.lama-qp-lista'); if(!l) return null;
    return {ov:getComputedStyle(l).overflowY, alto:Math.round(l.getBoundingClientRect().height),
            vh:innerHeight};
  });
  if(!r) return 'no está la lista';
  return (r.ov === 'auto' && r.alto < r.vh * 0.6) || `overflow:${r.ov} alto:${r.alto}`;
});
await caso('filtra de verdad: buscando "Sánd" no aparece el Americano', async () => {
  const t = await page.textContent('.lama-qp-lista');
  return (t.includes('Sándwich') && !t.includes('Americano'))
    || 'la lista dice: ' + t.replace(/\s+/g,' ').slice(0,120);
});

console.log('\nQUE SE PUEDA ESCRIBIR DE VERDAD:');
/* Si repintar el panel entero le saca el foco al campo, en el teléfono el
   teclado se cierra en la primera letra y hay que volver a tocar la caja
   cada vez. Es la diferencia entre servir y no servir. */
await caso('escribir no le saca el foco al buscador', async () => {
  const donde = await page.evaluate(() => document.activeElement && document.activeElement.id);
  return donde === 'lama-qp' || 'el foco quedó en: ' + donde;
});
await caso('agregar desde la lista NO vacía el buscador', async () => {
  await page.click('.lama-qp-lista .lama-prod'); await page.waitForTimeout(600);
  const v = await page.evaluate(() => {
    const e = document.querySelector('#lama-qp'); return e ? e.value : null; });
  return v === 'Sánd' || 'el buscador quedó en: ' + JSON.stringify(v);
});
await caso('y el foco vuelve al campo, para seguir escribiendo', async () => {
  const donde = await page.evaluate(() => document.activeElement && document.activeElement.id);
  return donde === 'lama-qp' || 'el foco quedó en: ' + donde;
});

console.log('\nCÓMO SE CIERRA:');
await caso('Escape cierra la lista sin cerrar la mesa', async () => {
  await page.evaluate(()=>document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape'})));
  await page.waitForTimeout(350);
  const lista = await page.isVisible('.lama-qp-lista');
  const panel = await page.isVisible('[data-lamaacc="cobrar"]');
  return (!lista && panel) || `lista:${lista} panel:${panel}`;
});
await caso('tocar fuera también la cierra', async () => {
  await page.fill('#lama-qp', 'Café'); await page.waitForTimeout(300);
  if(!await page.isVisible('.lama-qp-lista')) return 'no llegó a abrirse';
  await page.click('.lama-cab'); await page.waitForTimeout(350);
  return !(await page.isVisible('.lama-qp-lista')) || 'la lista quedó abierta';
});

console.log('\nY LA ESTÉTICA DE LA CASA:');
await caso('nada del buscador lleva reborde', async () => {
  await page.fill('#lama-qp', 'Café'); await page.waitForTimeout(300);
  const n = await page.evaluate(() => [...document.querySelectorAll('.lama-buscar, .lama-buscar *, .lama-pil')]
    .filter(el => { const s = getComputedStyle(el);
      return parseFloat(s.borderTopWidth) > 0 || parseFloat(s.borderLeftWidth) > 0; }).length);
  return n === 0 || n + ' elementos con reborde';
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () =>
  errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
