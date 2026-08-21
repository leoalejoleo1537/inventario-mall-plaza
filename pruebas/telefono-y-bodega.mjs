/* Tres arreglos del 2026-08-21, con su prueba.
   node pruebas/telefono-y-bodega.mjs

   1 · AJUSTES SE SALÍA DEL TELÉFONO. Jhon: "en productos y en actividad
       cuando se ve desde el teléfono, esta área no se adapta al teléfono y se
       ve todo en formato grande, sacando de proporción todo".
       La causa no se ve leyendo el CSS de a una línea: `.aj` lleva
       `align-items:flex-start` para que el riel no se estire a lo alto cuando
       va AL LADO, y en el teléfono esa misma regla —ya en columna— dejaba que
       cada hijo se anchara lo que pidiera su contenido. Las filas de Actividad
       y de Productos llevan una línea sin cortes, así que pedían 470 px dentro
       de una pantalla de 390 y toda la app se corría.
       Por eso la comprobación de acá NO es "¿se ve bien?" sino **cuánto mide
       el documento**: un número contra otro número.

   2 · EL BOTÓN ACTUALIZAR EN BODEGA. Bodega no tiene cuenta de Fudo, así que
       ese botón prometía algo que no puede pasar. Se esconden los dos —el de
       la barra y el atajo del menú— y NINGUNO de los de Ajustes.

   3 · LA ETIQUETA "TIPO" CORRIDA. La fila se mostraba con `display:flex`,
       que pone la etiqueta AL LADO del campo en vez de encima. Se comprueba
       midiendo: la etiqueta tiene que estar por encima del campo.            */
import { pathToFileURL } from 'node:url';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

/* Nombres largos a propósito: el bug solo aparece con texto que no cabe. */
const PRODUCTOS = [
  {id:10, sede:'plaza', producto:'Sandwich Jamón Serrano Congelador', rubro:'Sándwiches', tipo:'Sándwiches', stock_actual:4, stock_min:2, stock_max:10, activo:'SÍ'},
  {id:11, sede:'plaza', producto:'Brownie Congelador', rubro:'Congelador', tipo:'Bollería', stock_actual:9, stock_min:2, stock_max:20, activo:'SÍ'},
  {id:20, sede:'central', producto:'Café en grano bulto', rubro:'Bodega', tipo:'Café', stock_actual:3, stock_min:1, stock_max:6, activo:'SÍ'},
];
const MOVS = Array.from({length:10}, (_,i)=>({
  id:i+1, created_at:new Date(Date.now()-i*3600000).toISOString(), sede:'plaza',
  quien:'adriana@cafedeldesierto.cl', tipo:'merma',
  producto:'Sandwich Jamón Serrano Congelador', cantidad:-3, motivo:'vencido'}));

const page = await browser.newPage();
await page.setViewportSize({width:390, height:844});
await page.addInitScript(({PRODUCTOS, MOVS}) => {
  const SES = {user:{id:'u1', email:'prueba@cafe.cl', user_metadata:{nombre:'Prueba'}}};
  const TABLAS = {
    productos: PRODUCTOS,
    app_permisos: [{correo:'prueba@cafe.cl', nombre:'Prueba', puede_fudo:true, puede_editar:true, puede_ajustes:true}],
    fudo_sync: [{sede:'plaza', modo:'real', cron_activo:true}],
    secciones: [], movimientos: MOVS, ajustes: [], metas: [], historial: [],
    restauraciones: [], fusiones: [], fudo_stock_push: [], recetas: [], receta_items: [],
    fudo_productos: [], producto_lotes: [], repartos: [], reparto_items: [],
    mermas: [], producto_enlace: [], tareas: [], fudo_categorias: [],
  };
  const q = (nombre) => {
    const filas = JSON.parse(JSON.stringify(TABLAS[nombre] || []));
    const api = {
      select(){ return api; }, eq(){ return api; }, in(){ return api; }, neq(){ return api; },
      order(){ return api; }, limit(){ return api; }, gte(){ return api; }, lte(){ return api; },
      is(){ return api; }, not(){ return api; }, or(){ return api; }, ilike(){ return api; },
      maybeSingle(){ return Promise.resolve({data: filas[0]||null, error:null}); },
      single(){ return Promise.resolve({data: filas[0]||null, error:null}); },
      insert(){ const e={select:()=>e, single:()=>Promise.resolve({data:null,error:null}), then:f=>Promise.resolve({data:[],error:null}).then(f)}; return e; },
      update(){ const e={eq:()=>e, select:()=>e, then:f=>Promise.resolve({data:[],error:null}).then(f)}; return e; },
      upsert(){ const e={select:()=>e, then:f=>Promise.resolve({data:[],error:null}).then(f)}; return e; },
      delete(){ return api; },
      then(f){ return Promise.resolve({data:filas, error:null, count:filas.length}).then(f); },
    };
    return api;
  };
  window.supabase = { createClient: () => ({
    from: q,
    rpc: ()=>Promise.resolve({data:[], error:null}),
    auth: { getSession: async()=>({data:{session:SES}}), getUser: async()=>({data:{user:SES.user}}),
            onAuthStateChange(cb){ setTimeout(()=>cb&&cb('SIGNED_IN',SES),0); return {data:{subscription:{unsubscribe(){}}}}; },
            signInWithPassword: async()=>({data:{session:SES}, error:null}), signOut: async()=>({}) },
    channel: () => ({ on(){return this;}, subscribe(cb){cb&&cb('SUBSCRIBED');return this;},
                      track: async()=>{}, presenceState: ()=>({}) }),
    removeChannel(){}, functions:{ invoke: async()=>({data:{ok:true}, error:null}) },
  })};
}, {PRODUCTOS, MOVS});
await page.route('**/supabase-js*', r => r.fulfill({status:200, contentType:'application/javascript', body:'/* simulado */'}));

const errores = [];
page.on('pageerror', e => errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(350);

let ok=0, mal=0;
const caso = async (nombre, fn) => {
  try { const r = await fn(); if(r===true){ ok++; console.log(`  ✓ ${nombre}`); }
        else { mal++; console.log(`  ✗ ${nombre}  → ${r}`); } }
  catch(e){ mal++; console.log(`  ✗ ${nombre}  → ${e.message.split('\n')[0]}`); }
};
/* Lo que de verdad delata el bug: el documento más ancho que la pantalla. */
const anchos = () => page.evaluate(()=>({
  vp: document.documentElement.clientWidth,
  doc: document.documentElement.scrollWidth,
}));

await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(350);

console.log('\nAjustes cabe en un teléfono de 390 px:');
await page.click('#btnMenu'); await page.waitForTimeout(200);
await page.click('[data-accion="ajustes"]'); await page.waitForTimeout(400);

for (const sec of ['productos','actividad','secciones','salud','respaldos','personas']) {
  await page.click(`#aj-rail [data-aj="${sec}"]`).catch(()=>{});
  await page.waitForTimeout(600);
  if (sec === 'productos') {
    await page.click('[data-ajprsede="plaza"]').catch(()=>{});
    await page.waitForTimeout(400);
    await page.fill('#aj-prq', 'o').catch(()=>{});
    await page.waitForTimeout(300);
  }
  await caso(`${sec}: el ancho del documento no pasa el de la pantalla`, async () => {
    const a = await anchos();
    return a.doc <= a.vp + 1 || `documento ${a.doc} px en una pantalla de ${a.vp} px`;
  });
}

console.log('\nEl riel sí se desliza (es un carrusel, no un desborde):');
await caso('el riel tiene más contenido del que muestra', async () =>
  await page.evaluate(()=>{ const r=document.querySelector('#aj-rail');
    return r.scrollWidth > r.clientWidth; }) || 'el riel no desborda: ¿cabe entero?');

console.log('\nEl botón Actualizar:');
await page.click('#aj-volver'); await page.waitForTimeout(400);
await caso('en Mall Plaza se ve el de la barra', async () =>
  await page.isVisible('#btnActualizar') || 'no se ve');
await page.click('#btnMenu'); await page.waitForTimeout(250);
await caso('en Mall Plaza se ve el atajo del menú', async () =>
  await page.isVisible('#drActualizar') || 'no se ve');

await page.click('[data-accion="cambiar-sede"]'); await page.waitForTimeout(300);
await page.click('.gate-btn[data-sede="central"]'); await page.waitForTimeout(500);
await caso('en Bodega el de la barra está escondido', async () =>
  !(await page.isVisible('#btnActualizar')) || 'sigue visible: promete una sincronización que no existe');
await page.click('#btnMenu'); await page.waitForTimeout(250);
await caso('en Bodega el atajo del menú está escondido', async () =>
  !(await page.isVisible('#drActualizar')) || 'sigue visible');
await caso('y Ajustes sigue en su lugar (no se tocó nada de ahí)', async () =>
  await page.isVisible('[data-accion="ajustes"]') || 'desapareció la puerta de Ajustes');

await page.click('[data-accion="cambiar-sede"]'); await page.waitForTimeout(300);
await page.click('.gate-btn[data-sede="plaza"]'); await page.waitForTimeout(500);
await caso('al volver a Mall Plaza el botón vuelve', async () =>
  await page.isVisible('#btnActualizar') || 'quedó escondido para siempre');

console.log('\nLa ficha del producto · la etiqueta "Tipo":');
await page.click('.sec-head'); await page.waitForTimeout(300);
await page.click('.row'); await page.waitForTimeout(400);
await caso('la fila del tipo se muestra', async () =>
  await page.isVisible('#m-tipo-row') || 'no aparece');
await caso('la etiqueta va ENCIMA del campo, no al lado', async () => {
  const r = await page.evaluate(()=>{
    const lab = document.querySelector('#m-tipo-row label').getBoundingClientRect();
    const inp = document.querySelector('#m-tipo').getBoundingClientRect();
    return {labBottom: lab.bottom, inpTop: inp.top, labLeft: lab.left, inpLeft: inp.left};
  });
  return (r.labBottom <= r.inpTop + 1 && Math.abs(r.labLeft - r.inpLeft) < 2)
    || `la etiqueta termina en ${Math.round(r.labBottom)} y el campo empieza en ${Math.round(r.inpTop)}`;
});
await caso('y se ve igual que las otras etiquetas de la ficha', async () => {
  const r = await page.evaluate(()=>{
    const a = getComputedStyle(document.querySelector('#m-tipo-row'));
    const b = getComputedStyle(document.querySelector('#m-min').closest('.field'));
    return a.display === b.display ? true : `tipo es ${a.display} y mínimo es ${b.display}`;
  });
  return r;
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () =>
  errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
