/* TRES PULIDOS DEL 2026-08-25.
   node pruebas/limpieza-y-planilla.mjs

   1 · El historial de Fudo es de PERSONAS. Jhon: "esta área es más para
       trazabilidad, ver qué usuarios empujaron a Fudo de forma manual".
       El reloj llenaba la lista de líneas que nadie decidió.

   2 · Y con eso apareció una trampa que hay que dejar probada: el DESHACER
       lo decide el servidor (`fudo_ultimo_empuje`), que no sabe de este
       filtro. Si la pantalla describiera el último empuje MANUAL mientras
       el servidor va a deshacer el AUTOMÁTICO, el botón diría una cosa y
       haría otra. Se prueba que lo dice.

   3 · La planilla de Adrián: sus cuatro columnas primero y en su orden.   */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const hace = h => new Date(Date.now() - h*3600000).toISOString();

/* El reloj empujó hace una hora; la última persona, hace seis. Y hay un
   empuje de hace CUATRO DÍAS que no tiene que aparecer: son 2 días. */
const PUSH = [
  {id:1, sede:'plaza', lote:'L-auto', quien:'sistema (automático)', created_at:hace(1)},
  {id:2, sede:'plaza', lote:'L-auto', quien:'sistema (automático)', created_at:hace(1)},
  {id:3, sede:'plaza', lote:'L-jhon', quien:'jhon@cafe.cl',          created_at:hace(6)},
  {id:4, sede:'plaza', lote:'L-jhon', quien:'jhon@cafe.cl',          created_at:hace(6)},
  {id:5, sede:'plaza', lote:'L-jhon', quien:'jhon@cafe.cl',          created_at:hace(6)},
  {id:6, sede:'plaza', lote:'L-viejo',quien:'valentina@cafe.cl',     created_at:hace(96)},
];

const ENVIOS = [
  {id:70, franquicia:'Franquicia Iquique', estado:'despachado', creado_por:'Adriana',
   despachado_por:'Adriana', created_at:hace(30)},
];
const ENV_ITEMS = [
  {id:1, envio_id:70, producto:'Medialuna', cantidad_pedida:12, cantidad_enviada:10, estado:'listo'},
  {id:2, envio_id:70, producto:'Alfajor',   cantidad_pedida:6,  cantidad_enviada:0,  estado:'no_hay'},
];

const page = await browser.newPage();
await page.setViewportSize({width:390, height:900});
await page.addInitScript(({PUSH, ENVIOS, ENV_ITEMS}) => {
  window.__xlsx = null;
  const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
  const T = {
    productos:[{id:900, sede:'central', producto:'Medialuna', rubro:'Bodega', stock_actual:5, activo:'SÍ'}],
    producto_enlace:[], fudo_stock_push:PUSH,
    envios_franquicia:ENVIOS, envios_franquicia_items:ENV_ITEMS,
    app_permisos:[{correo:'jhon@cafe.cl', nombre:'Jhon', puede_ajustes:true, puede_editar:true, puede_fudo:true, fudo_bloqueos:[]}],
    fudo_sync:[], secciones:[], movimientos:[], ajustes:[], metas:[], historial:[],
    restauraciones:[], fusiones:[], recetas:[], receta_items:[],
    fudo_productos:[], producto_lotes:[], repartos:[], reparto_items:[], mermas:[],
    tareas:[], fudo_categorias:[]};
  let seq = 7000;
  const q = (n) => {
    let filas = JSON.parse(JSON.stringify(T[n]||[]));
    const api = {
      select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
      in(c,vs){ filas=filas.filter(f=>vs.map(String).includes(String(f[c]))); return api;},
      gte(c,v){ filas=filas.filter(f=>String(f[c]) >= String(v)); return api;},
      lte(){return api;}, neq(){return api;}, is(){return api;}, not(){return api;},
      or(){return api;}, ilike(){return api;}, limit(){return api;},
      order(c,o){ const asc = !o || o.ascending !== false;
        filas.sort((a,b)=>String(a[c]??'').localeCompare(String(b[c]??''))*(asc?1:-1)); return api;},
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
    from:q, rpc:()=>Promise.resolve({data:[],error:null}),
    auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
           onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
           signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
    channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
    removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
  })};
  /* XLSX viene de un CDN que la prueba no alcanza, así que se pone uno de
     mentira con lo justo que la app usa. Lo que se prueba acá es QUÉ FILAS y
     QUÉ COLUMNAS se arman —que es la decisión— y no que el navegador sepa
     guardar un archivo, que no es nuestro. */
  window.XLSX = {
    utils: {
      json_to_sheet: (filas)=>({__filas:filas}),
      book_new: ()=>({SheetNames:[], Sheets:{}}),
      book_append_sheet: (wb, ws, nom)=>{ wb.SheetNames.push(nom); wb.Sheets[nom]=ws; },
    },
    writeFile: (wb)=>{
      const ws = wb.Sheets[wb.SheetNames[0]];
      const filas = ws.__filas || [];
      window.__xlsx = filas.length
        ? [Object.keys(filas[0]), ...filas.map(f=>Object.values(f))] : [];
    },
  };
}, {PUSH, ENVIOS, ENV_ITEMS});
await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
const errores = [];
page.on('pageerror', e=>errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(400);

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

console.log('\nEl historial de Fudo muestra personas, no el reloj:');
await caso('el empuje automático NO sale en la lista', async () => {
  const r = await page.evaluate(async ()=>{
    SEDE = 'plaza'; await cargarHistorialFudo();
    return document.getElementById('adm-hist').textContent;
  });
  return !r.includes('sistema') || 'sigue apareciendo el reloj';
});
await caso('el empuje de una persona SÍ sale', async () =>
  (await page.evaluate(()=>document.getElementById('adm-hist').textContent)).includes('jhon')
  || 'no aparece quien sí lo hizo a mano');
await caso('lo de hace 4 días ya no sale (son 2 días)', async () =>
  !(await page.evaluate(()=>document.getElementById('adm-hist').textContent)).includes('valentina')
  || 'sigue mostrando más de dos días atrás');
await caso('"Última vez" nombra a la persona, no al reloj', async () => {
  const t = await page.evaluate(()=>document.getElementById('adm-ultimo').textContent);
  return (t.includes('jhon') && !t.includes('sistema')) || 'dice: "'+t+'"';
});

console.log('\nY el deshacer no miente sobre lo que va a deshacer:');
/* El servidor deshace el ÚLTIMO lote, que acá es el automático. Si la
   pantalla dijera solo "devuelve N productos", quien lo toque creería que
   está deshaciendo lo de Jhon. */
await caso('avisa que el último empuje lo hizo el reloj', async () => {
  const t = await page.evaluate(()=>document.getElementById('adm-desc-deshacer').textContent);
  return t.includes('reloj') || 'no lo dice: "'+t+'"';
});

console.log('\nLa planilla de Adrián:');
await caso('sus cuatro columnas van primero y en su orden', async () => {
  await page.click('.gate-btn[data-sede="central"]'); await page.waitForTimeout(600);
  await page.click('#tabFranquicias').catch(()=>{});
  await page.waitForTimeout(400);
  const dbg = await page.evaluate(async ()=>{
    try{ await frExcel(); }catch(e){ return 'reventó: '+e.message; }
    return window.XLSX ? 'xlsx cargado' : 'XLSX no está';
  });
  await page.waitForTimeout(600);
  const t = await page.evaluate(()=>window.__xlsx);
  if(!t) return 'no armó ninguna planilla ('+dbg+')';
  const cab = t[0].slice(0,4).join('|');
  return cab === 'FECHA|PRODUCTO|CANTIDAD|FRANQUICIA' || 'las cabeceras son: '+cab;
});
await caso('CANTIDAD es lo que SALIÓ, no lo que se pidió', async () => {
  const t = await page.evaluate(()=>window.__xlsx);
  const fila = t.find(f=>f[1]==='Medialuna');
  return (fila && fila[2] === 10) || 'puso '+(fila?fila[2]:'nada')+' y salieron 10';
});
/* Una línea que no salió NO se esconde: la franquicia sí la pidió, y
   hacerla desaparecer de la planilla es como se arma una discusión. */
await caso('lo que no había sale igual, en 0 y dicho', async () => {
  const t = await page.evaluate(()=>window.__xlsx);
  const fila = t.find(f=>f[1]==='Alfajor');
  if(!fila) return 'la escondió';
  return (fila[2] === 0 && String(fila[5]).includes('No había'))
    || 'cantidad '+fila[2]+' · estado '+fila[5];
});
await caso('y trae lo que la planilla de él no sabe', async () => {
  const t = await page.evaluate(()=>window.__xlsx);
  const cab = t[0].join('|');
  return (cab.includes('PEDIDA') && cab.includes('ESTADO') && cab.includes('N° DE ENVÍO'))
    || 'faltan columnas: '+cab;
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () => errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
