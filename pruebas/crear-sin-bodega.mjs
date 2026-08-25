/* CREAR UN PRODUCTO SIN QUE NAZCA TAMBIÉN EN BODEGA.
   node pruebas/crear-sin-bodega.mjs

   EL CASO REAL (Jhon, 2026-08-24). "Alfajor Brownie" ya existe en bodega y en
   las dos sedes. En Mall Plaza le pusieron el apellido "congelador", porque
   allá tiene los dos muebles. Falta crear el gemelo de VITRINA, y solo en
   Mall Plaza.

   La pantalla no dejaba: Bodega era un cartel que decía "siempre" y no se
   podía apagar. Peor todavía —comprobado contra Postgres local antes de
   tocar nada— la función NO fallaba: creaba en bodega un "Alfajor Brownie
   vitrina" duplicado y sin sección, ensuciando justo la sede que se está
   tratando de mantener limpia.

   Lo que se prueba acá es la mitad de pantalla. La mitad de la base está
   probada aparte, contra un Postgres con el esquema copiado del DDL del
   repo: 7 escenarios, incluidos los que tienen que SEGUIR fallando.        */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const BODEGA = [
  {id:900, sede:'central', producto:'Alfajor Brownie', rubro:'Bodega', stock_actual:5, stock_min:2, stock_max:40, activo:'SÍ'},
];
const PLAZA = [
  {id:10, sede:'plaza', producto:'Alfajor Brownie congelador', rubro:'Congelador', stock_actual:3, stock_min:2, stock_max:20, activo:'SÍ'},
];
const ANGAMOS = [
  {id:20, sede:'angamos', producto:'Alfajor Brownie', rubro:'Vitrina', stock_actual:1, stock_min:2, stock_max:20, activo:'SÍ'},
];
const ENLACES = [
  {id:1, sede:'plaza', producto_bodega_id:900, producto_sede_id:10},
  {id:2, sede:'angamos', producto_bodega_id:900, producto_sede_id:20},
];

const page = await browser.newPage();
await page.setViewportSize({width:390, height:900});
await page.addInitScript(({BODEGA, PLAZA, ANGAMOS, ENLACES}) => {
  window.__rpc = [];                       // lo que se le manda a la base
  const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
  const T = {productos:[...BODEGA, ...PLAZA, ...ANGAMOS], producto_enlace:ENLACES,
    app_permisos:[{correo:'jhon@cafe.cl', nombre:'Jhon', puede_ajustes:true, puede_editar:true, puede_fudo:true, fudo_bloqueos:[]}],
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
    from:q,
    rpc:(nombre, args)=>{ window.__rpc.push({nombre, args});
      return Promise.resolve({data:{bodega_id:null, detalle:[]}, error:null}); },
    auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
           onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
           signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
    channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
    removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
  })};
}, {BODEGA, PLAZA, ANGAMOS, ENLACES});
await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
const errores = [];
page.on('pageerror', e=>errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(350);

const cerrarAviso = async () => {
  if(await page.isVisible('#ask-ok')){ await page.click('#ask-ok'); await page.waitForTimeout(250); }
};

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

await page.click('.gate-btn[data-sede="central"]'); await page.waitForTimeout(600);
await page.click('#tabEnlaces'); await page.waitForTimeout(800);

console.log('\nBodega es un destino, no una obligación:');
await caso('se puede tocar (ya no dice "siempre")', async () =>
  await page.isVisible('[data-enldest="central"]') || 'Bodega no es un destino tocable');
await caso('arranca marcada: casi todo nace en bodega', async () =>
  (await page.getAttribute('[data-enldest="central"]','class')).includes('on')
  || 'no viene marcada, y debería');
await caso('y al tocarla se apaga', async () => {
  await page.click('[data-enldest="central"]'); await page.waitForTimeout(250);
  return !(await page.getAttribute('[data-enldest="central"]','class')).includes('on')
    || 'no se apagó';
});

console.log('\nCon bodega apagada, no pregunta cosas de bodega:');
await caso('se esconden sección, mínimo y máximo "en Bodega"', async () =>
  !(await page.isVisible('#enl-n-bodega-campos')) || 'sigue pidiendo datos de bodega');
await caso('y vuelven al volver a marcarla', async () => {
  await page.click('[data-enldest="central"]'); await page.waitForTimeout(250);
  const v = await page.isVisible('#enl-n-bodega-campos');
  await page.click('[data-enldest="central"]'); await page.waitForTimeout(250);
  return v || 'no volvieron';
});

console.log('\nEL CASO DE JHON · "Alfajor Brownie vitrina", solo en Mall Plaza:');
await caso('sin ningún destino, no deja crear y dice por qué', async () => {
  await page.fill('#enl-n-nombre', 'Alfajor Brownie vitrina');
  await page.waitForTimeout(250);
  const t = await page.textContent('#enl-resumen');
  return (t.includes('Elige dónde') && await page.isDisabled('#enl-crear'))
    || 'no avisa que falta elegir: "'+t+'"';
});
await caso('al elegir Mall Plaza, pide su sección', async () => {
  await page.click('[data-enldest="plaza"]'); await page.waitForTimeout(300);
  const t = await page.textContent('#enl-resumen');
  return t.includes('sección en Mall Plaza') || 'no la pide: "'+t+'"';
});
await caso('elegida la sección, el botón se enciende', async () => {
  await page.selectOption('[data-enlrubro="plaza"]', {index:1});
  await page.waitForTimeout(300);
  return !(await page.isDisabled('#enl-crear')) || 'sigue apagado';
});
/* Lo importante no es que deje crear: es que DIGA que bodega no va a bajar.
   Un enlace que falta en silencio es el error de §0.5 en versión chica. */
await caso('y dice con todas las letras que bodega no baja por él', async () => {
  const t = await page.textContent('#enl-resumen');
  return (t.includes('solo en Mall Plaza') && t.includes('bodega no baja'))
    || 'el resumen no lo explica: "'+t+'"';
});
await caso('al crear, NO manda bodega en la lista de destinos', async () => {
  await page.click('#enl-crear'); await page.waitForTimeout(500);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='crear_producto_enlazado'));
  if(!r) return 'no llamó a la base';
  const sedes = (r.args.p_destinos||[]).map(d=>d.sede);
  return (!sedes.includes('central') && sedes.includes('plaza'))
    || 'mandó '+JSON.stringify(sedes)+' y bodega no debía ir';
});
/* Crear deja abierta la ventana de "✓ creado". Si no se cierra, tapa la
   pantalla y el toque siguiente falla por eso y no por el código. */
await cerrarAviso();

console.log('\nLO DE SIEMPRE NO SE ROMPE · bodega + los dos locales:');
await caso('con bodega marcada, sí viaja en los destinos', async () => {
  await page.click('#tabEnvios'); await page.waitForTimeout(400);
  await page.click('#tabEnlaces'); await page.waitForTimeout(600);   // se reinicia el formulario
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.fill('#enl-n-nombre', 'Torta de zanahoria'); await page.waitForTimeout(250);
  await page.selectOption('#enl-n-rubro', {index:1});
  await page.click('[data-enldest="plaza"]');   await page.waitForTimeout(200);
  await page.click('[data-enldest="angamos"]'); await page.waitForTimeout(200);
  await page.selectOption('[data-enlrubro="plaza"]',   {index:1});
  await page.selectOption('[data-enlrubro="angamos"]', {index:1});
  await page.waitForTimeout(300);
  if(await page.isDisabled('#enl-crear'))
    return 'no deja crear: '+(await page.textContent('#enl-resumen'));
  await page.click('#enl-crear'); await page.waitForTimeout(500);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='crear_producto_enlazado'));
  if(!r) return 'no llamó a la base';
  const sedes = (r.args.p_destinos||[]).map(d=>d.sede);
  return (sedes.includes('central') && sedes.includes('plaza') && sedes.includes('angamos'))
    || 'mandó '+JSON.stringify(sedes);
});
await cerrarAviso();
await caso('y la sección de bodega viaja con ella', async () => {
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='crear_producto_enlazado'));
  const c = (r.args.p_destinos||[]).find(d=>d.sede==='central');
  return (c && c.rubro) ? true : 'el destino bodega fue sin sección';
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () => errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
