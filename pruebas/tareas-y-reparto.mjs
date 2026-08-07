/* Prueba en navegador de la lista de tareas y del nombre del reparto.
   node pruebas/tareas-y-reparto.mjs

   Lo que de verdad comprueba: que el botón se enciende SOLO en la sede que
   corresponde, que marcar una tarea la ESCRIBE en la base, que "Limpiar"
   destilda en vez de borrar, y que el nombre del reparto viaja al guardar. */
import { existsSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
let chromium;
try { ({ chromium } = await import('playwright')); }
catch { console.log('\n(se salta: Playwright no está instalado)\n'); process.exit(0); }

const PRODUCTOS = [
  {id:10, sede:'plaza',   producto:'Trozo torta amor', rubro:'Vitrina', stock_actual:4, stock_min:2, stock_max:10, activo:'SÍ'},
  {id:11, sede:'angamos', producto:'Trozo torta amor', rubro:'Vitrina', stock_actual:4, stock_min:2, stock_max:10, activo:'SÍ'},
];
const TAREAS = [
  {id:1, sede:'angamos', texto:'Revisar fechas de los sándwiches', hecha:false},
  {id:2, sede:'angamos', texto:'Botar lo vencido',                 hecha:true},
];

const CHROME = process.env.CHROME_PATH || '/opt/pw-browsers/chromium';
const browser = await chromium.launch(existsSync(CHROME) ? { executablePath: CHROME } : {});
const page = await browser.newPage();

await page.addInitScript(({PRODUCTOS, TAREAS}) => {
  window.__escrito = [];
  const SES = {user:{id:'u1', email:'prueba@cafe.cl', user_metadata:{nombre:'Prueba'}}};
  const T = n => ({productos:PRODUCTOS, tareas:TAREAS}[n] || []);
  let seq = 900;
  const q = (nombre) => {
    const filas = JSON.parse(JSON.stringify(T(nombre)));
    const api = {
      select(){ return api; }, eq(){ return api; }, in(){ return api; }, order(){ return api; },
      limit(){ return api; }, gte(){ return api; }, lte(){ return api; },
      maybeSingle(){ return Promise.resolve({data:null, error:null}); },
      single(){ return Promise.resolve({data: filas[0]||null, error:null}); },
      insert(v){
        const rows = (Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
        window.__escrito.push({tabla:nombre, op:'insert', filas:rows});
        return { select:()=>({ single:()=>Promise.resolve({data:rows[0], error:null}),
                               then:g=>Promise.resolve({data:rows, error:null}).then(g) }),
                 then:g=>Promise.resolve({data:rows, error:null}).then(g) };
      },
      update(v){ window.__escrito.push({tabla:nombre, op:'update', valores:v}); return api; },
      delete(){ window.__escrito.push({tabla:nombre, op:'delete'}); return api; },
      then(g){ return Promise.resolve({data:filas, error:null}).then(g); },
    };
    return api;
  };
  window.supabase = { createClient: () => ({
    from: q,
    auth: { getSession: async()=>({data:{session:SES}}),
            onAuthStateChange(cb){ setTimeout(()=>cb&&cb('SIGNED_IN',SES),0); return {data:{subscription:{unsubscribe(){}}}}; },
            signOut: async()=>({}) },
    channel: () => ({ on(){ return this; }, subscribe(cb){ cb&&cb('SUBSCRIBED'); return this; },
                      track: async()=>{}, presenceState: ()=>({}) }),
    removeChannel(){}, functions:{ invoke: async()=>({data:{ok:true}, error:null}) },
  })};
}, {PRODUCTOS, TAREAS});

await page.route('**/supabase-js*', r => r.fulfill({status:200, contentType:'application/javascript', body:''}));
const errores = [];
page.on('pageerror', e => errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(300);

let ok=0, mal=0;
const caso = async (nombre, fn) => {
  try { const r = await fn(); if(r===true){ ok++; console.log(`  ✓ ${nombre}`); }
        else { mal++; console.log(`  ✗ ${nombre}  → ${r}`); } }
  catch(e){ mal++; console.log(`  ✗ ${nombre}  → ${e.message}`); }
};

console.log('\nEl interruptor por sede (FLAGS):');
await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(300);
await caso('en Mall Plaza el botón NO aparece', async () =>
  !(await page.isVisible('#btnTareas')) || 'se ve y no debería');

await page.evaluate(()=>showGate());   // el botón vive en el menú, que está cerrado
await page.waitForTimeout(150);
await page.click('.gate-btn[data-sede="angamos"]');
await page.waitForTimeout(350);
await caso('en Angamos SÍ aparece', async () =>
  await page.isVisible('#btnTareas') || 'no se ve');
await caso('el puntito avisa que hay algo pendiente', async () =>
  await page.isVisible('#tareasPto') || 'no se ve el puntito');

console.log('\nLa ventana de tareas:');
await page.click('#btnTareas');
await page.waitForTimeout(280);
await caso('sale como globo y con el fondo desenfocado', async () =>
  (await page.isVisible('.tareas-caja.globo')) && (await page.isVisible('.overlay-prop.overlay-blur')) || 'no salió como globo');
await caso('muestra las 2 tareas', async () =>
  (await page.locator('.tk-fila').count()) === 2 || 'muestra otra cantidad');
await caso('la ya hecha se ve tachada', async () =>
  (await page.locator('.tk-fila.ok').count()) === 1 || 'no marcó la hecha');

await caso('marcar una la ESCRIBE en la base', async () => {
  await page.locator('.tk-fila').first().locator('.tk-box').click();
  await page.waitForTimeout(200);
  const w = await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='tareas' && x.op==='update'));
  if(!w.length) return 'no escribió nada';
  if(w[0].valores.hecha !== true) return 'guardó ' + JSON.stringify(w[0].valores);
  return true;
});

await caso('agregar una tarea la manda a la base', async () => {
  await page.fill('#tk-nueva', 'Contar el congelador');
  await page.click('[data-a="add"]');
  await page.waitForTimeout(250);
  const w = await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='tareas' && x.op==='insert'));
  if(!w.length) return 'no la insertó';
  if(w[0].filas[0].texto !== 'Contar el congelador') return 'guardó: '+w[0].filas[0].texto;
  if(w[0].filas[0].sede !== 'angamos') return 'la guardó en la sede equivocada';
  return true;
});

await caso('"Limpiar" DESTILDA, no borra', async () => {
  const antes = await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='tareas' && x.op==='delete').length);
  await page.click('[data-a="limpiar"]');
  await page.waitForTimeout(200);
  await page.click('#ask-ok');                       // confirmar
  await page.waitForTimeout(250);
  const borrados = await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='tareas' && x.op==='delete').length);
  if(borrados > antes) return 'BORRÓ tareas en vez de destildarlas';
  const ups = await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='tareas' && x.op==='update'));
  const ultimo = ups[ups.length-1];
  return (ultimo && ultimo.valores.hecha === false) || 'no destildó: '+JSON.stringify(ultimo);
});

await caso('se cierra tocando fuera', async () => {
  await page.click('.overlay-prop', {position:{x:5,y:5}});
  await page.waitForTimeout(300);
  return !(await page.isVisible('.tareas-caja')) || 'siguió abierta';
});

console.log('\nEl nombre del reparto:');
await page.click('.tab[data-tab="reparto"]');
await page.waitForTimeout(300);
await caso('hay un campo para ponerle nombre', async () =>
  (await page.locator('#rep-nombre').count()) === 1 || 'no existe el campo');
await caso('y dice que es opcional', async () => {
  const ph = await page.getAttribute('#rep-nombre', 'placeholder');
  return (ph||'').toLowerCase().includes('opcional') || 'dice: '+ph;
});

await caso('ningún error de JavaScript en toda la sesión', async () =>
  errores.length === 0 || errores.join(' | '));

await browser.close();
console.log(`\n${ok} bien · ${mal} mal\n`);
process.exit(mal ? 1 : 0);
