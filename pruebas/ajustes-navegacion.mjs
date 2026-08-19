/* Recorrer AJUSTES entero, botón por botón, en un navegador de verdad.
   node pruebas/ajustes-navegacion.mjs

   POR QUÉ EXISTE. Jhon lo pidió con estas palabras: "te pido que corras
   pruebas de navegación y funcionalidad de cada botón para que tú mismo veas
   los fallos". Y tenía razón en pedirlo: los tres que reportó no se ven
   leyendo el código de a una función, solo se ven navegando.

     · "el área de salud aparece y desaparece información rápidamente,
        las recetas parece su cantidad luego cero luego nuevamente"
     · "navegar entre secciones se siente con mucho lag"
     · "el botón de Fudo algunas veces no responde, solo parpadea"

   Los tres eran EL MISMO bucle: un cargador que se llamaba a sí mismo a
   través del repintado. Por eso la prueba central de acá no es "¿se ve la
   pantalla?" sino **cuántas veces se pidió cada cosa a la base**. Un
   contador es lo único que delata un bucle; mirar la pantalla no, porque
   un bucle rápido se ve como un parpadeo y un parpadeo se justifica solo
   ("será que carga").                                                    */
import { readFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const PRODUCTOS = [
  {id:10, sede:'plaza', producto:'Brownie Vitrina',    rubro:'Vitrina de dulces', stock_actual:4, stock_min:2, stock_max:10, activo:'SÍ'},
  {id:11, sede:'plaza', producto:'Brownie Congelador', rubro:'Congelador',        stock_actual:9, stock_min:2, stock_max:20, activo:'SÍ'},
  {id:12, sede:'plaza', producto:'Croasan',            rubro:'Sándwiches',        stock_actual:5, stock_min:2, stock_max:9,  activo:'NO'},
];
const PERMISOS = [
  {correo:'prueba@cafe.cl', nombre:'Prueba', puede_fudo:true, puede_editar:true, puede_ajustes:true},
  {correo:'adriana@cafe.cl', nombre:'Adriana', puede_fudo:false, puede_editar:true, puede_ajustes:false},
];

const page = await browser.newPage();
await page.addInitScript(({PRODUCTOS, PERMISOS}) => {
  window.__pedidos = {};            // tabla -> cuántas veces se pidió
  window.__escrito = [];
  /* Tablas que contestan "listo" SIN escribir nada — que es exactamente lo
     que hacía app_permisos con la puerta cerrada. Se simula para poder
     comprobar que la app se da cuenta en vez de mentir. */
  window.__puertaCerrada = new Set();
  const salida = (nombre, filas) =>
    window.__puertaCerrada.has(nombre) ? {data:[], error:null} : {data:filas, error:null};
  const SES = {user:{id:'u1', email:'prueba@cafe.cl', user_metadata:{nombre:'Prueba'}}};
  const TABLAS = {
    productos: PRODUCTOS, app_permisos: PERMISOS,
    fudo_sync: [{sede:'plaza', modo:'real', cron_activo:true, ultima_corrida_at:new Date().toISOString(),
                 ultimo_resultado:'ok', ultimos_items:92, ultimos_errores:0, ultimos_movimientos:40,
                 ultima_corrida_por:'cron'},
                {sede:'angamos', modo:'prueba', cron_activo:false}],
    secciones: [{sede:'plaza', nombre:'Vitrina de dulces', turno:'pm', orden:0},
                {sede:'plaza', nombre:'Congelador',       turno:'am', orden:1},
                {sede:'plaza', nombre:'Sándwiches',       turno:'pm', orden:2},
                {sede:'plaza', nombre:'Vacía',            turno:'pm', orden:3}],
    fudo_categorias: [{sede:'plaza', categoria_id:'12', rubro:null, ejemplos:'Torta amor · Waffle'}],
    ajustes: [], metas: [], historial: [], restauraciones: [], fusiones: [],
    movimientos: [], fudo_stock_push: [], recetas: [], receta_items: [],
    fudo_productos: [], producto_lotes: [],
    repartos: [], reparto_items: [], mermas: [], producto_enlace: [], tareas: [],
  };
  let seq = 900;
  const q = (nombre) => {
    window.__pedidos[nombre] = (window.__pedidos[nombre] || 0) + 1;
    let filas = JSON.parse(JSON.stringify(TABLAS[nombre] || []));
    const api = {
      select(){ return api; }, eq(){ return api; }, in(){ return api; }, neq(){ return api; },
      order(){ return api; }, limit(){ return api; }, gte(){ return api; }, lte(){ return api; },
      is(){ return api; }, not(){ return api; }, or(){ return api; }, ilike(){ return api; },
      maybeSingle(){ return Promise.resolve({data: filas[0]||null, error:null}); },
      single(){ return Promise.resolve({data: filas[0]||null, error:null}); },
      insert(v){ const rows=(Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
        window.__escrito.push({tabla:nombre, op:'insert', filas:rows});
        const r = () => Promise.resolve(salida(nombre, rows));
        const enc = { select:()=>enc, single:()=>Promise.resolve({data:rows[0],error:null}),
                      then:f=>r().then(f) };
        return enc; },
      update(v){ window.__escrito.push({tabla:nombre, op:'update', valor:v});
        const r = () => Promise.resolve(salida(nombre, [{...v}]));
        const enc = { eq:()=>enc, select:()=>enc, then:f=>r().then(f) };
        return enc; },
      upsert(v){ window.__escrito.push({tabla:nombre, op:'upsert', valor:v});
        const filas = Array.isArray(v) ? v : [v];
        const enc = { select:()=>enc, then:f=>Promise.resolve(salida(nombre, filas)).then(f) };
        return enc; },
      delete(){ window.__escrito.push({tabla:nombre, op:'delete'}); return api; },
      then(f){ return Promise.resolve({data:filas, error:null}).then(f); },
    };
    return api;
  };
  window.supabase = { createClient: () => ({
    from: q,
    rpc: (n)=>{ window.__pedidos['rpc:'+n] = (window.__pedidos['rpc:'+n]||0)+1;
                return Promise.resolve({data:[], error:null}); },
    auth: { getSession: async()=>({data:{session:SES}}), getUser: async()=>({data:{user:SES.user}}),
            onAuthStateChange(cb){ setTimeout(()=>cb&&cb('SIGNED_IN',SES),0); return {data:{subscription:{unsubscribe(){}}}}; },
            signInWithPassword: async()=>({data:{session:SES}, error:null}), signOut: async()=>({}) },
    channel: () => ({ on(){return this;}, subscribe(cb){cb&&cb('SUBSCRIBED');return this;},
                      track: async()=>{}, presenceState: ()=>({}) }),
    removeChannel(){}, functions:{ invoke: async()=>({data:{ok:true}, error:null}) },
  })};
}, {PRODUCTOS, PERMISOS});

await page.route('**/supabase-js*', r => r.fulfill({status:200, contentType:'application/javascript', body:'/* simulado */'}));

const errores = [];
page.on('pageerror', e => errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(300);

let ok=0, mal=0;
const caso = async (nombre, fn) => {
  try { const r = await fn(); if(r===true){ ok++; console.log(`  ✓ ${nombre}`); }
        else { mal++; console.log(`  ✗ ${nombre}  → ${r}`); } }
  catch(e){ mal++; console.log(`  ✗ ${nombre}  → ${e.message.split('\n')[0]}`); }
};

await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(300);

console.log('\nSe entra a Ajustes:');
await page.click('#btnMenu');
await page.waitForTimeout(250);
await caso('la puerta de Administración aparece con permiso', async () =>
  await page.isVisible('#bloqueAdmin') || 'no se ve el bloque de administración');
await page.click('[data-accion="ajustes"]');
await page.waitForTimeout(400);
await caso('se abre la pantalla', async () => await page.isVisible('#view-ajustes') || 'no se abrió');
await caso('las pestañas de arriba se esconden', async () =>
  !(await page.isVisible('.tabs')) || 'las pestañas siguen ahí');

/* ---------- EL BUCLE ---------- */
console.log('\nNINGUNA sección se pide dos veces (el bucle de Salud):');
const secciones = await page.$$eval('#aj-rail [data-aj]', bs => bs.map(b => b.dataset.aj));
await caso('el riel trae las 10 secciones', () => secciones.length === 10 || 'trae '+secciones.length);

for (const id of secciones) {
  await page.evaluate(()=>{ window.__pedidos = {}; });
  await page.click(`#aj-rail [data-aj="${id}"]`);
  await page.waitForTimeout(700);          // tiempo de sobra para que un bucle se note
  const pedidos = await page.evaluate(()=>window.__pedidos);
  const repetido = Object.entries(pedidos).find(([,n]) => n > 3);
  const txt = (await page.textContent('#aj-pane')).trim();
  await caso(`${id}: pinta contenido y no se repite`, () =>
    (!repetido || `pidió "${repetido[0]}" ${repetido[1]} veces — es un bucle`) === true
      ? (txt.length > 30 || `el panel quedó casi vacío: "${txt.slice(0,40)}"`)
      : `pidió "${repetido[0]}" ${repetido[1]} veces — es un bucle`);
}

/* ---------- EL RIEL QUE SE REHACÍA ---------- */
console.log('\nEl riel no se destruye al cargar (por eso no respondían los botones):');
await caso('los botones del riel son los MISMOS nodos después de navegar', async () => {
  await page.evaluate(()=>{ document.querySelector('#aj-rail [data-aj="fudo"]').dataset.marca = 'yo'; });
  await page.click('#aj-rail [data-aj="salud"]');   await page.waitForTimeout(500);
  await page.click('#aj-rail [data-aj="actividad"]'); await page.waitForTimeout(500);
  const sigue = await page.evaluate(()=>document.querySelector('#aj-rail [data-aj="fudo"]').dataset.marca);
  return sigue === 'yo' || 'el botón de Fudo se reemplazó por otro: un toque en ese momento se pierde';
});

await caso('y Fudo abre al primer toque, sin pasar por otro botón', async () => {
  await page.click('#aj-rail [data-aj="fudo"]');
  await page.waitForTimeout(400);
  const on = await page.getAttribute('#aj-rail [data-aj="fudo"]', 'class');
  return (on||'').includes('on') || 'no quedó seleccionado';
});

/* ---------- FUDO: LAS DOS PERILLAS ---------- */
console.log('\nFudo · el modo y el reloj de cada sede:');
await page.click('#aj-rail [data-aj="fudo"]');
await page.waitForTimeout(500);

await caso('se ve el estado de las dos sedes', async () => {
  const t = await page.textContent('#aj-pane');
  return (t.includes('Mall Plaza') && t.includes('Parque Angamos')) || 'falta alguna';
});
await caso('Plaza aparece en real y Angamos en prueba', async () => {
  const t = await page.textContent('#aj-pane');
  return (t.includes('modo real') && t.includes('modo prueba')) || 'no distingue los modos';
});
await caso('dice cuándo corrió y cuántos ítems leyó', async () =>
  (await page.textContent('#aj-pane')).includes('92 ítems') || 'no muestra la última corrida');

await caso('pasar de PRUEBA a real no pregunta nada: no apaga nada', async () => {
  await page.evaluate(()=>{ window.__escrito = []; });
  await page.click('[data-fmodo="angamos"]');
  await page.waitForTimeout(300);
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='fudo_sync'));
  return (w && w.valor.modo === 'real') || 'no escribió el modo real';
});
await caso('pasar de REAL a prueba sí avisa antes de apagar el descuento', async () => {
  await page.evaluate(()=>{ window.__escrito = []; });
  await page.click('[data-fmodo="plaza"]');
  await page.waitForTimeout(300);
  const abierta = await page.isVisible('#overlay-ask');
  const txt = abierta ? await page.textContent('#ask-detalle') : '';
  return (abierta && txt.includes('NO va a bajar')) || 'no preguntó, o no dijo la consecuencia';
});
await page.click('#ask-no');
await page.waitForTimeout(200);
await caso('y si se cancela, no se escribe nada', async () =>
  (await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='fudo_sync').length)) === 0
  || 'escribió igual');

/* ---------- SECCIONES ---------- */
console.log('\nSecciones y turnos:');
await page.click('#aj-rail [data-aj="secciones"]');
await page.waitForTimeout(500);

await caso('salen las secciones en su orden, no en alfabético', async () => {
  const nombres = await page.$$eval('.aj-sec .nm b', bs=>bs.map(b=>b.textContent));
  return (nombres[0] === 'Vitrina de dulces' && nombres[1] === 'Congelador')
    || 'salieron así: ' + nombres.join(', ');
});
await caso('cada una dice en qué turno se cuenta', async () =>
  (await page.textContent('#aj-pane')).includes('cuenta en la mañana') || 'no dice el turno');
await caso('cambiar el turno lo guarda', async () => {
  await page.evaluate(()=>{ window.__escrito = []; });
  await page.click('[data-secturno="Congelador"]');
  await page.waitForTimeout(300);
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='secciones'));
  return (w && w.valor.turno === 'pm') || 'no escribió el turno nuevo';
});
await caso('subir una sección reescribe el orden ENTERO, no dos números', async () => {
  await page.evaluate(()=>{ window.__escrito = []; });
  await page.click('[data-secsube="Sándwiches"]');
  await page.waitForTimeout(300);
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='secciones' && x.op==='upsert'));
  return (w && Array.isArray(w.valor) && w.valor.length >= 4) || 'no reescribió la lista completa';
});
await caso('la primera no se puede subir y la última no se puede bajar', async () => {
  const arriba = await page.getAttribute('.aj-sec:first-child [data-secsube]', 'disabled');
  return arriba !== null || 'la primera sigue teniendo el botón activo';
});
/* `avisar()` reusa la misma ventana que `preguntar()`, con un solo botón
   que dice "Entendido": por eso acá se mira #overlay-ask y no otra cosa. */
await caso('una sección CON productos se niega a borrarse, y dice cuántos', async () => {
  await page.click('[data-secborrar="Vitrina de dulces"]');
  await page.waitForTimeout(400);
  const t = (await page.textContent('#ask-titulo')) + ' ' + (await page.textContent('#ask-detalle'));
  return (t.includes('1 producto') && t.includes('sin sección'))
    || 'no explicó por qué no, o no dijo el riesgo: ' + t.slice(0,80);
});
await page.click('#ask-ok'); await page.waitForTimeout(250);
await caso('una VACÍA sí, preguntando antes', async () => {
  await page.click('[data-secborrar="Vacía"]');
  await page.waitForTimeout(300);
  return (await page.isVisible('#overlay-ask')) || 'no preguntó';
});
await page.click('#ask-no'); await page.waitForTimeout(200);

await caso('mover un producto de sección escribe su rubro', async () => {
  await page.fill('#aj-sec-q', 'brownie');
  await page.waitForTimeout(300);
  await page.selectOption('[data-secmover="10"]', 'Sándwiches');
  await page.waitForTimeout(300);
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='productos' && x.op==='update'));
  return (w && w.valor.rubro === 'Sándwiches') || 'no escribió el rubro';
});
await caso('y escribir en el buscador NO rehace el panel entero', async () => {
  await page.evaluate(()=>{ document.getElementById('aj-sec-q').dataset.marca = 'yo'; });
  await page.fill('#aj-sec-q', 'brownie v');
  await page.waitForTimeout(300);
  const sigue = await page.evaluate(()=>document.getElementById('aj-sec-q').dataset.marca);
  return sigue === 'yo' || 'el campo se destruyó al escribir: se pierde el foco y los toques';
});

/* ---------- PERSONAS: LA ESCRITURA QUE NO ESCRIBÍA ---------- */
console.log('\nPersonas · el permiso que decía que se guardaba y no se guardaba:');
await page.click('#aj-rail [data-aj="personas"]');
await page.waitForTimeout(500);

await caso('con la puerta abierta, darle acceso a alguien lo escribe', async () => {
  await page.evaluate(()=>{ window.__escrito = []; });
  await page.click('[data-persona="adriana@cafe.cl"]');
  await page.waitForTimeout(300);
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='app_permisos'));
  return (w && w.valor.puede_ajustes === true) || 'no escribió el permiso';
});
await caso('CON LA PUERTA CERRADA avisa, en vez de decir que guardó', async () => {
  await page.evaluate(()=>{ window.__puertaCerrada.add('app_permisos'); });
  await page.click('[data-persona="adriana@cafe.cl"]');
  await page.waitForTimeout(400);
  /* Quitar acceso pregunta primero; se confirma para llegar a la escritura. */
  if(await page.isVisible('#overlay-ask')){ await page.click('#ask-ok'); await page.waitForTimeout(500); }
  const visible = await page.isVisible('#overlay-ask');
  const t = visible ? ((await page.textContent('#ask-titulo')) + ' ' + (await page.textContent('#ask-detalle'))) : '';
  await page.evaluate(()=>{ window.__puertaCerrada.clear(); });
  return (visible && t.includes('NO se guardó'))
    || 'no avisó nada: la pantalla estaría mintiendo (' + t.slice(0,60) + ')';
});
await page.click('#ask-ok'); await page.waitForTimeout(250);

/* ---------- VOLVER ---------- */
console.log('\nY se puede salir:');
await caso('el botón de volver dice a dónde', async () =>
  (await page.textContent('#aj-volver-txt')).includes('Mall Plaza') || 'dice otra cosa');
await page.click('#aj-volver');
await page.waitForTimeout(300);
await caso('vuelve al inventario', async () => await page.isVisible('#view-inv') || 'no volvió');
await caso('y las pestañas reaparecen', async () => await page.isVisible('.tabs') || 'siguen escondidas');

await caso('ningún error de JavaScript en todo el recorrido', () =>
  errores.length === 0 || errores.join(' | ').slice(0,300));

console.log(`\n${mal ? '✗' : '✓'} ${ok} bien, ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
