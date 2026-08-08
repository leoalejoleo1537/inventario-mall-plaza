/* Prueba de que recibir un reparto SUMA a Fudo en vez de mandarle el total.
   node pruebas/reparto-suma-a-fudo.mjs

   Lo que de verdad se comprueba, y es la regla que Jhon fijó:
     "llegan 2 cachitos, Fudo tiene 3 -> Fudo queda en 5"
   sin importar lo que diga el inventario, porque el inventario va con
   retraso (lo que hay en mesas abiertas todavía no se descontó). */
import { existsSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
let chromium;
try { ({ chromium } = await import('playwright')); }
catch { console.log('\n(se salta: Playwright no está instalado)\n'); process.exit(0); }

/* El inventario dice 4 a propósito: 3 en la vitrina + 1 en una mesa abierta.
   Si la app mandara el total, Fudo quedaría en 4 — y eso es justo el error. */
const PRODUCTOS = [
  {id:77, sede:'plaza', producto:'Cachitos', rubro:'Vitrina de dulces',
   stock_actual:4, stock_min:2, stock_max:20, activo:'SÍ'},
];
const REPARTOS = [
  {id:1, sede:'plaza', estado:'abierto', creado_por:'Adriana', nombre:'Reparto de dulces',
   created_at:new Date().toISOString()},
];
const ITEMS = [
  {id:501, reparto_id:1, producto_id:77, producto:'Cachitos',
   cantidad_pedida:2, cantidad_recibida:null, estado:'pendiente'},
];

const CHROME = process.env.CHROME_PATH || '/opt/pw-browsers/chromium';
const browser = await chromium.launch(existsSync(CHROME) ? { executablePath: CHROME } : {});
const page = await browser.newPage();

await page.addInitScript(({PRODUCTOS, REPARTOS, ITEMS}) => {
  window.__fudo = [];      // lo que se le mandó a la Edge Function
  const SES = {user:{id:'u1', email:'jefe@cafe.cl', user_metadata:{nombre:'Jefe'}}};
  const T = n => ({productos:PRODUCTOS, repartos:REPARTOS, reparto_items:ITEMS}[n] || []);
  /* El stub RESPETA eq() e in(). Sin eso, la misma fila salía como reparto
     abierto y como cerrado a la vez, y la pantalla no mostraba los botones. */
  const q = (nombre) => {
    let filas = JSON.parse(JSON.stringify(T(nombre)));
    const api = {
      select(){ return api; },
      eq(col, val){ filas = filas.filter(f => String(f[col]) === String(val)); return api; },
      in(col, vals){ filas = filas.filter(f => vals.map(String).includes(String(f[col]))); return api; },
      order(){ return api; }, limit(){ return api; }, gte(){ return api; }, lte(){ return api; },
      maybeSingle(){ return Promise.resolve({data: filas[0]||null, error:null}); },
      single(){ return Promise.resolve({data: filas[0]||null, error:null}); },
      insert(){ return { select:()=>({single:()=>Promise.resolve({data:{id:1},error:null})}),
                         then:g=>Promise.resolve({data:[],error:null}).then(g) }; },
      update(){ return api; }, delete(){ return api; },
      then(g){ return Promise.resolve({data:filas, error:null}).then(g); },
    };
    return api;
  };
  window.supabase = { createClient: () => ({
    from: q,
    rpc: async (fn, args) => { window.__rpc = {fn, args}; return {data:null, error:null}; },
    auth: { getSession: async()=>({data:{session:SES}}),
            onAuthStateChange(cb){ setTimeout(()=>cb&&cb('SIGNED_IN',SES),0); return {data:{subscription:{unsubscribe(){}}}}; },
            signOut: async()=>({}) },
    channel: () => ({ on(){ return this; }, subscribe(cb){ cb&&cb('SUBSCRIBED'); return this; },
                      track: async()=>{}, presenceState: ()=>({}) }),
    removeChannel(){},
    functions:{ invoke: async(nombre, opt) => {
      window.__fudo.push({nombre, body: opt && opt.body});
      if(window.__fudoFalla) return {data:null, error:{message:'Failed to send a request'}};
      return {data:{ok:true, actualizados:1}, error:null};
    }},
  })};
}, {PRODUCTOS, REPARTOS, ITEMS});

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

await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(300);
await page.evaluate(()=>{ PERMISOS.correo='jefe@cafe.cl'; PERMISOS.puede_fudo=true; });
await page.click('.tab[data-tab="reparto"]');
await page.waitForTimeout(400);

console.log('\nEl botón dice lo que va a hacer:');
await caso('la etiqueta avisa que suma a Fudo', async () => {
  const t = await page.textContent('[data-recibir]');
  return t.toLowerCase().includes('fudo') || 'dice: '+t;
});
await caso('el nombre del reparto se ve en la cabecera', async () => {
  const t = await page.textContent('#repartos-abiertos');
  return t.includes('Reparto de dulces') || 'no aparece el nombre';
});

console.log('\nAl recibir:');
await page.click('[data-recibir]');
await page.waitForTimeout(400);

await caso('suma primero al inventario, en la base', async () => {
  const r = await page.evaluate(()=>window.__rpc);
  return (r && r.fn === 'reparto_recibir') || 'llamó a: '+(r&&r.fn);
});

await caso('manda a Fudo SOLO lo que llegó, no el total del inventario', async () => {
  const f = await page.evaluate(()=>window.__fudo.filter(x=>x.nombre==='fudo-sumar-stock'));
  if(!f.length) return 'no llamó a fudo-sumar-stock';
  const b = f[0].body;
  if(b.cantidad === 4) return 'MANDÓ EL TOTAL DEL INVENTARIO (4) en vez de lo que llegó';
  if(b.cantidad !== 2) return 'mandó '+b.cantidad+', esperaba 2';
  if(b.producto_id !== 77) return 'mandó el producto equivocado';
  if(b.sede !== 'plaza')  return 'mandó la sede equivocada';
  return true;
});

await caso('usa la función que SUMA, no la que reemplaza', async () => {
  const f = await page.evaluate(()=>window.__fudo);
  const mala = f.find(x=>x.nombre==='fudo-empujar-stock');
  return !mala || 'llamó a fudo-empujar-stock, que manda el total del inventario';
});

await caso('no salió ninguna ventana de confirmación', async () =>
  !(await page.isVisible('#overlay-ask')) || 'apareció un "¿seguro?" y Jhon pidió que fluyera');

console.log('\nSi Fudo no contesta:');
await page.evaluate(()=>{ window.__fudoFalla = true; window.__fudo.length = 0; });
await page.evaluate(()=>sumarAFudo(77, 3, 502));
await page.waitForTimeout(300);
await caso('avisa suave, sin alarmar', async () => {
  const t = await page.textContent('#toast');
  return (t.toLowerCase().includes('reconect') || t.toLowerCase().includes('conexión'))
    || 'el aviso dice: '+t;
});
await caso('lo guarda para reintentarlo', async () =>
  (await page.evaluate(()=>FUDO_PENDIENTE.length)) === 1 || 'no quedó en la cola');
await caso('y al volver la señal lo manda solo', async () => {
  await page.evaluate(()=>{ window.__fudoFalla = false; window.dispatchEvent(new Event('online')); });
  await page.waitForTimeout(350);
  const f = await page.evaluate(()=>window.__fudo.filter(x=>x.nombre==='fudo-sumar-stock'));
  const quedan = await page.evaluate(()=>FUDO_PENDIENTE.length);
  if(f.length < 2) return 'no reintentó';
  if(quedan !== 0) return 'quedaron '+quedan+' en la cola';
  return true;
});

await caso('ningún error de JavaScript en toda la sesión', async () =>
  errores.length === 0 || errores.join(' | '));

await browser.close();
console.log(`\n${ok} bien · ${mal} mal\n`);
process.exit(mal ? 1 : 0);
