/* Prueba de la pantalla de Recetas en un navegador de verdad, con Supabase
   simulado. Comprueba que la portada pinta, que el taller enlaza, y que lo que
   se enlaza se ESCRIBE en la base (no solo en la pantalla).

   node pruebas/recetas-en-pantalla.mjs

   Necesita Playwright. Si no está, la prueba se salta sola en vez de fallar. */
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
let chromium;
try { ({ chromium } = await import('playwright')); }
catch { console.log('\n(se salta: Playwright no está instalado)\n'); process.exit(0); }

/* ---------- la base falsa ---------- */
const FUDO = [
  {fudo_product_id:'1', nombre:'Waffle',                 code:null, precio:3200, categoria_id:'12'},
  {fudo_product_id:'2', nombre:'Torta amor Pedidos Ya',  code:null, precio:7000, categoria_id:'12'},
  {fudo_product_id:'4', nombre:'APALTADO + CAFE',        code:null, precio:9490, categoria_id:'18'},
  {fudo_product_id:'3', nombre:'ALCOHOL GEL MANOS',      code:null, precio:0,    categoria_id:'29'},
];
const PRODUCTOS = [
  {id:10, sede:'plaza', producto:'Waffles',          rubro:'Vitrina de tortas', stock_actual:4, stock_min:2, stock_max:10, activo:'SÍ'},
  {id:11, sede:'plaza', producto:'Trozo torta amor', rubro:'Vitrina de tortas', stock_actual:2, stock_min:1, stock_max:8,  activo:'SÍ'},
  {id:12, sede:'plaza', producto:'Sandwich Apaltado', rubro:'Sándwiches',        stock_actual:5, stock_min:2, stock_max:9,  activo:'SÍ'},
  {id:13, sede:'plaza', producto:'Cafe',             rubro:'Mesones',           stock_actual:9, stock_min:1, stock_max:20, activo:'SÍ'},
];
const CATS = [
  {categoria_id:'12', rubro:'Vitrina'},
  {categoria_id:'29', rubro:'Insumos e implementos'},
  {categoria_id:'18', rubro:'Combos y promociones'},
];

/* El navegador que ya viene instalado en la máquina. Si la versión de
   Playwright pide otro build, se usa este igual en vez de bajarse uno. */
const CHROME = process.env.CHROME_PATH || '/opt/pw-browsers/chromium';
const browser = await chromium.launch(
  existsSync(CHROME) ? { executablePath: CHROME } : {}
);
const page = await browser.newPage();
const escrito = [];            // lo que la app le mandó a la base

await page.addInitScript(({FUDO, PRODUCTOS, CATS}) => {
  window.__escrito = [];
  const SES = {user:{id:'u1', email:'prueba@cafe.cl', user_metadata:{nombre:'Prueba'}}};
  const tabla = n => ({
    productos: PRODUCTOS, fudo_productos: FUDO, fudo_categorias: CATS,
    recetas: [], receta_items: [], fudo_no_lleva_receta: [],
    producto_lotes: [], app_permisos: [], repartos: [], reparto_items: [],
    fudo_sync: [], historial: [],
  }[n] || []);
  let seq = 500;
  const q = (nombre) => {
    let filas = JSON.parse(JSON.stringify(tabla(nombre)));
    const api = {
      select(){ return api; }, eq(){ return api; }, in(){ return api; },
      order(){ return api; }, limit(){ return api; }, gte(){ return api; }, lte(){ return api; },
      maybeSingle(){ return Promise.resolve({data:null, error:null}); },
      single(){ return Promise.resolve({data: filas[0]||null, error:null}); },
      insert(v){
        const rows = (Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
        window.__escrito.push({tabla:nombre, filas:rows});
        const res = {data:rows, error:null};
        return { select:()=>({ single:()=>Promise.resolve({data:rows[0], error:null}) }),
                 then:(f)=>Promise.resolve(res).then(f) };
      },
      update(){ return api; }, delete(){ window.__escrito.push({tabla:nombre, borrado:true}); return api; },
      then(f){ return Promise.resolve({data:filas, error:null}).then(f); },
    };
    return api;
  };
  window.supabase = {
    createClient: () => ({
      from: q,
      auth: { getSession: async()=>({data:{session:SES}}), getUser: async()=>({data:{user:SES.user}}),
              onAuthStateChange(cb){ setTimeout(()=>cb&&cb('SIGNED_IN',SES),0); return {data:{subscription:{unsubscribe(){}}}}; },
              signInWithPassword: async()=>({data:{session:SES}, error:null}), signOut: async()=>({}) },
      channel: () => ({ on(){ return this; }, subscribe(cb){ cb && cb('SUBSCRIBED'); return this; },
                        track: async()=>{}, presenceState: ()=>({}) }),
      removeChannel(){}, functions:{ invoke: async()=>({data:{ok:true}, error:null}) },
    }),
  };
}, {FUDO, PRODUCTOS, CATS});

// La librería real no se descarga: ya la reemplazamos arriba.
await page.route('**/supabase-js*', r => r.fulfill({status:200, contentType:'application/javascript', body:'/* simulado */'}));

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

console.log('\nLa pantalla de Recetas:');

// entrar a la sede y a la pestaña
await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(250);
await page.click('.tab[data-tab="recetas"]');
await page.waitForTimeout(400);

await caso('la portada aparece al entrar', async () =>
  await page.isVisible('#rec-portada') || 'no se ve la portada');

await caso('el puente muestra los 4 productos de Fudo', async () =>
  (await page.textContent('#rp-fudo')) === '4' || 'dice '+(await page.textContent('#rp-fudo')));

await caso('los tres contadores parten en 0 · 4 · 0', async () => {
  const v = await page.evaluate(()=>[rpTxt('rp-ok'), rpTxt('rp-falta'), rpTxt('rp-no')].join('/'),
    ).catch(()=>null);
  const t = await page.evaluate(()=>[document.getElementById('rp-ok').textContent,
    document.getElementById('rp-falta').textContent, document.getElementById('rp-no').textContent].join('/'));
  return t === '0/4/0' || 'dio '+t;
});

await caso('las barras salen agrupadas por NUESTRAS secciones', async () => {
  const t = await page.textContent('#rp-barras');
  return (t.includes('Vitrina') && t.includes('Insumos e implementos')) || 'no veo las secciones: '+t.slice(0,80);
});

await caso('el botón dice cuántos faltan', async () =>
  (await page.textContent('#btnTaller')).includes('4') || 'dice '+(await page.textContent('#btnTaller')));

console.log('\nEl taller:');
await page.click('#btnTaller');
await page.waitForTimeout(200);

await caso('se abre y esconde la portada', async () =>
  (await page.isVisible('#rec-taller')) && !(await page.isVisible('#rec-portada')) || 'no cambió de vista');

await caso('propone "Waffles" para el "Waffle" de Fudo', async () => {
  const t = await page.textContent('#tl-cands');
  return t.includes('Waffles') || 'propuso: '+t.slice(0,80);
});

await caso('tocar un candidato lo MARCA, todavía no guarda nada', async () => {
  await page.click('.tl-cand');
  await page.waitForTimeout(150);
  const marcado = await page.isVisible('.tl-cand.on');
  const w = await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='recetas'));
  if(!marcado) return 'no se marcó';
  if(w.length)  return 'guardó antes de que apretaran Listo';
  return true;
});

await caso('aparece la barra con "Listo" y dice cuántos van', async () => {
  const t = await page.textContent('.tl-barra');
  return t.includes('1 producto') && t.includes('Listo') || 'dice: '+t;
});

await caso('volver a tocarlo lo desmarca', async () => {
  await page.click('.tl-cand');
  await page.waitForTimeout(150);
  const hay = await page.locator('.tl-barra').count();
  return hay === 0 || 'la barra siguió ahí';
});

await caso('al apretar Listo, ESCRIBE la receta en la base', async () => {
  await page.click('.tl-cand');
  await page.waitForTimeout(120);
  await page.click('.tl-barra .btn');
  await page.waitForTimeout(250);
  const w = await page.evaluate(()=>window.__escrito);
  const r = w.find(x=>x.tabla==='recetas'), it = w.find(x=>x.tabla==='receta_items');
  if(!r)  return 'no escribió en recetas';
  if(!it) return 'no escribió qué descuenta';
  if(it.filas[0].producto_id !== 10) return 'enlazó al producto equivocado';
  return true;
});

await caso('lo hecho queda a la vista, con su deshacer', async () => {
  const t = await page.textContent('.tl-hechos');
  return (t.includes('Waffle') && t.includes('Deshacer')) || 'muestra: '+t.slice(0,80);
});

await caso('avanza al siguiente producto', async () =>
  (await page.textContent('.tl-nom')).includes('Torta amor') || 'quedó en: '+(await page.textContent('.tl-nom')));

await caso('quita el "Pedidos Ya" y propone el trozo de torta', async () => {
  const t = await page.textContent('#tl-cands');
  return t.includes('Trozo torta amor') || 'propuso: '+t.slice(0,80);
});

console.log('\nCombos: varios productos en una sola receta');
// Se resuelve la torta para llegar al combo, que es el que tiene dos candidatos.
await page.click('.tl-cand'); await page.waitForTimeout(100);
await page.click('.tl-barra .btn'); await page.waitForTimeout(250);

await caso('llegó al combo', async () =>
  (await page.textContent('.tl-nom')).includes('APALTADO') || 'quedó en: '+(await page.textContent('.tl-nom')));

await caso('se pueden marcar dos y la barra los cuenta', async () => {
  const cands = page.locator('.tl-cand');
  const n = await cands.count();
  if(n < 2) return 'solo hay '+n+' candidato(s) para probarlo';
  await cands.nth(0).click(); await page.waitForTimeout(80);
  await cands.nth(1).click(); await page.waitForTimeout(150);
  const t = await page.textContent('.tl-barra');
  return t.includes('2 productos') || 'dice: '+t;
});

await caso('guarda UNA receta con DOS líneas', async () => {
  const antes = await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='receta_items').length);
  await page.click('.tl-barra .btn');
  await page.waitForTimeout(250);
  const w = await page.evaluate(()=>window.__escrito.filter(x=>x.tabla==='receta_items'));
  const nueva = w[antes];
  if(!nueva) return 'no guardó las líneas';
  if(nueva.filas.length !== 2) return 'guardó '+nueva.filas.length+' línea(s), esperaba 2';
  const rid = nueva.filas[0].receta_id;
  return nueva.filas.every(f=>f.receta_id===rid) || 'las líneas quedaron en recetas distintas';
});

await caso('el historial acumula, no reemplaza', async () => {
  const n = await page.locator('.tl-hfila').count();
  return n === 3 || 'muestra '+n+', esperaba 3';
});

await caso('se puede deshacer el PRIMERO, no solo el último', async () => {
  await page.locator('.tl-hfila').nth(2).locator('button').click();   // el más viejo: el Waffle
  await page.waitForTimeout(300);
  const n = await page.locator('.tl-hfila').count();
  if(n !== 2) return 'quedaron '+n+' en el historial';
  const w = await page.evaluate(()=>window.__escrito.filter(x=>x.borrado).length);
  if(!w) return 'no borró nada de la base';
  // y el producto vuelve al frente de la cola, para poder corregirlo al toque
  const nom = await page.textContent('.tl-nom');
  return nom.includes('Waffle') || 'no volvió a preguntar por él, quedó en: '+nom;
});

console.log('\nLos combos siguen donde estaban:');
await page.click('.rec-modo[data-modo="combos"]');
await page.waitForTimeout(150);
await caso('el botón de siempre está, y dice "Crear combo"', async () =>
  (await page.textContent('#btnNuevaReceta')).includes('Crear combo') || 'dice '+(await page.textContent('#btnNuevaReceta')));
await caso('el buscador de recetas sigue ahí', async () =>
  await page.isVisible('#rec-q') || 'no se ve');

await caso('ningún error de JavaScript en toda la sesión', async () =>
  errores.length === 0 || errores.join(' | '));

await browser.close();
console.log(`\n${ok} bien · ${mal} mal\n`);
process.exit(mal ? 1 : 0);
