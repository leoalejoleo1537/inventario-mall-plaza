/* LA VENTANA DE "ACTUALIZANDO…" NO PUEDE QUEDARSE GIRANDO PARA SIEMPRE.
   node pruebas/no-se-cuelga.mjs

   El 2026-08-21, en pleno turno, Jhon apretó ⟳ y la ventana giró **más de
   siete minutos** en las dos sedes, mientras Adriana avisaba que Angamos no
   estaba descontando.

   No estaba colgada: `sb.functions.invoke` no tiene tope de tiempo, así que
   estaba esperando a Fudo, que no iba a contestar nunca. Es la regla 0.5 por
   el otro lado — un fallo no puede ser invisible, y **tampoco puede ser
   eterno**: una ventana que gira sin fin no se distingue de "está tardando",
   así que nadie sabe cuándo dejar de esperar.

   Las tres cosas que se comprueban acá, y las tres fallaban ese día:
     1 · una llamada que no vuelve termina igual, con un error que dice qué fue
     2 · la ventana se cierra y el botón se suelta
     3 · si lo que falló es la LECTURA DE VENTAS, se abre la ventana grande —
         porque eso significa que el inventario no se está descontando, y da
         lo mismo por qué                                                    */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const PRODUCTOS = [
  {id:10, sede:'plaza', producto:'Brownie Vitrina', rubro:'Vitrina de dulces', tipo:'Bollería',
   stock_actual:4, stock_min:2, stock_max:10, activo:'SÍ'},
];
const page = await browser.newPage();
await page.addInitScript(({PRODUCTOS}) => {
  window.__invocada = [];
  /* Cada función de Fudo se comporta como diga esto. 'cuelga' es el caso del
     turno: una promesa que no se resuelve nunca. */
  window.__comoContesta = {};
  const SES = {user:{id:'u1', email:'prueba@cafe.cl', user_metadata:{nombre:'Prueba'}}};
  const TABLAS = {
    productos: PRODUCTOS,
    app_permisos: [{correo:'prueba@cafe.cl', nombre:'Prueba', puede_fudo:true, puede_editar:true, puede_ajustes:true}],
    fudo_sync: [{sede:'plaza', modo:'real', cron_activo:true}],
    secciones: [], movimientos: [], ajustes: [], metas: [], historial: [],
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
    removeChannel(){},
    functions:{ invoke: (nombre) => {
      window.__invocada.push(nombre);
      const c = window.__comoContesta[nombre] || 'ok';
      if(c === 'cuelga') return new Promise(()=>{});          // el caso del turno
      if(c === 'error')  return Promise.resolve({data:null, error:{message:'Fudo dijo que no'}});
      return Promise.resolve({data:{ok:true, items:0, movimientos:0, errores:0, actualizados:0}, error:null});
    }},
  })};
}, {PRODUCTOS});
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

console.log('\nEl tope de tiempo, por sí solo:');
await caso('una promesa que nunca vuelve termina en error', async () =>
  await page.evaluate(async () => {
    try { await conTiempo(new Promise(()=>{}), 0.3, 'Fudo'); return 'no terminó nunca'; }
    catch(e){ return e.message.includes('no contestó') ? true : 'el mensaje no dice qué pasó: '+e.message; }
  }));
await caso('y dice cuántos segundos esperó', async () =>
  await page.evaluate(async () => {
    try { await conTiempo(new Promise(()=>{}), 0.3, 'Fudo'); return 'no terminó'; }
    catch(e){ return e.message.includes('0.3 s') || 'dice: '+e.message; }
  }));
await caso('una que sí contesta pasa de largo, sin esperar el tope', async () =>
  await page.evaluate(async () => {
    const t0 = Date.now();
    const v = await conTiempo(Promise.resolve(7), 30, 'Fudo');
    return (v === 7 && Date.now() - t0 < 1000) || 'devolvió '+v+' en '+(Date.now()-t0)+' ms';
  }));

await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(400);

console.log('\nEl turno del 21 de agosto: Fudo no contesta:');
/* Se acorta el tope para no esperar 90 s de verdad. Se toca SOLO la duración:
   el camino que se recorre es el mismo del botón real. */
await page.evaluate(() => {
  window.__comoContesta = {'fudo-sync-productos':'cuelga', 'fudo-sync-ventas':'cuelga', 'fudo-empujar-stock':'cuelga'};
  const orig = window.conTiempo;
  window.conTiempo = (p, s, quien) => orig(p, Math.min(s, 0.5), quien);
});
await page.click('#btnActualizar');
await page.waitForTimeout(400);
await caso('mientras trabaja, la ventana está abierta', async () =>
  await page.isVisible('#overlay-cargando') || 'no se abrió la ventana de trabajando');

await page.waitForTimeout(3000);
await caso('la ventana se cierra sola: no gira para siempre', async () =>
  !(await page.isVisible('#overlay-cargando')) || 'SIGUE GIRANDO — es el bug del turno');
await caso('el botón vuelve a estar disponible', async () =>
  await page.evaluate(()=>!document.getElementById('btnActualizar').disabled)
    || 'quedó apretado: el próximo toque no hace nada');
await caso('se avisa que el inventario NO se está descontando', async () => {
  const abierta = await page.isVisible('#overlay-ask');
  const txt = abierta ? await page.textContent('#overlay-ask') : '';
  return (abierta && txt.includes('no se está descontando'))
    || (abierta ? 'la ventana dice otra cosa: '+txt.slice(0,60) : 'no se abrió ninguna ventana');
});
await caso('y dice el motivo, no solo que falló', async () => {
  const txt = await page.textContent('#overlay-ask');
  return txt.includes('no contestó') || 'no dice por qué: '+txt.slice(0,80);
});

console.log('\nCon Fudo contestando, todo sigue igual que siempre:');
await page.click('#ask-ok').catch(()=>{});
await page.waitForTimeout(300);
await page.evaluate(()=>{ window.__comoContesta = {}; window.__invocada = []; });
await page.click('#btnActualizar');
await page.waitForTimeout(1500);
await caso('se llamó a los tres pasos, en orden', async () => {
  const v = await page.evaluate(()=>window.__invocada);
  return (v[0]==='fudo-sync-productos' && v[1]==='fudo-sync-ventas' && v[2]==='fudo-empujar-stock')
    || 'se llamó: '+v.join(', ');
});
await caso('la ventana se cerró', async () =>
  !(await page.isVisible('#overlay-cargando')) || 'quedó abierta');
await caso('no se abrió ninguna alarma', async () =>
  !(await page.isVisible('#overlay-ask')) || 'alarma con Fudo contestando bien');

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () =>
  errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
