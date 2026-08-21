/* Que el cambio de estética no haya roto lo que funcionaba.
   node pruebas/estetica-no-rompio-nada.mjs

   POR QUÉ EXISTE. Jhon lo dijo al aprobar el rediseño: "espero esto no genere
   bugs en la barra de búsqueda ni en la gráfica de meta de ventas". Un cambio
   de paleta y de formas toca CSS de toda la app, y las dos cosas que él nombró
   son justamente las que dependen de colores y medidas escritas a mano.

   Así que esto no mira si se ve bonito —eso no se prueba— sino lo que sí se
   puede comprobar: que el buscador siga filtrando, que la barra de metas siga
   pintando sus dos lados, y que ninguna regla nueva haya dejado un color
   colgando de una variable que ya no existe.                                */
import { readFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');

let ok = 0, mal = 0;
const caso = (nombre, r) => {
  if (r === true) { ok++; console.log(`  ✓ ${nombre}`); }
  else { mal++; console.log(`  ✗ ${nombre}  → ${r}`); }
};

/* ─── 1. sin variables de color huérfanas ─────────────────────────────────
   Una regla que use var(--algo) que no existe no da error: el navegador
   simplemente no pinta ese color, y el elemento queda transparente o negro.
   Es la forma más silenciosa de romper una paleta.                        */
console.log('\nNingún color apunta a una variable que no existe:');
const definidas = new Set([...html.matchAll(/(--[a-z0-9-]+)\s*:/g)].map(m => m[1]));
const usadas = [...new Set([...html.matchAll(/var\((--[a-z0-9-]+)/g)].map(m => m[1]))];
const huerfanas = usadas.filter(v => !definidas.has(v));
caso(`las ${usadas.length} variables usadas están definidas`,
  huerfanas.length === 0 || 'faltan: ' + huerfanas.join(', '));

/* ─── 2. la paleta completa sigue estando ────────────────────────────────── */
console.log('\nLa paleta no perdió ninguna pieza:');
for (const v of ['--bg','--card','--border','--text','--muted','--orange','--orange-dark',
                 '--red-bg','--red-fg','--green-bg','--green-fg','--amber-bg','--amber-fg',
                 '--navy','--sec-bg','--sec-tx','--sec-filo','--sombra','--r-card']) {
  caso(v, definidas.has(v) || 'no está definida');
}

const browser = await abrirNavegador();
if (!browser) { console.log('\n(el resto se salta: no hay navegador)\n'); process.exit(mal ? 1 : 0); }

const PRODUCTOS = [
  {id:10, sede:'plaza', producto:'Croasán jamón queso', rubro:'Sándwiches', stock_actual:4, stock_min:6, stock_max:20, activo:'SÍ'},
  {id:11, sede:'plaza', producto:'Cheesecake maracuyá', rubro:'Vitrina de tortas', stock_actual:8, stock_min:3, stock_max:10, activo:'SÍ'},
  {id:12, sede:'plaza', producto:'Azúcar morena',       rubro:'Mesones',    stock_actual:1, stock_min:3, stock_max:10, activo:'SÍ'},
];
const METAS = [{
  id:1, titulo:'Agua Bosqua', objetivo:100, premio:'Hotel y spa',
  desde:'2026-08-01', hasta:'2026-08-31', cerrada_at:null, meta_productos:[],
}];

const page = await browser.newPage();
await page.addInitScript(({PRODUCTOS, METAS}) => {
  const SES = {user:{id:'u1', email:'p@c.cl', user_metadata:{nombre:'Prueba'}}};
  const T = {productos:PRODUCTOS, metas:METAS, secciones:[], ajustes:[], app_permisos:[],
             fudo_sync:[], producto_lotes:[], repartos:[], reparto_items:[], recetas:[],
             receta_items:[], historial:[], tareas:[], fudo_productos:[]};
  const q = n => {
    const filas = JSON.parse(JSON.stringify(T[n] || []));
    const api = {select:()=>api, eq:()=>api, in:()=>api, order:()=>api, limit:()=>api,
      gte:()=>api, lte:()=>api, is:()=>api, not:()=>api, or:()=>api, ilike:()=>api, neq:()=>api,
      maybeSingle:()=>Promise.resolve({data:filas[0]||null,error:null}),
      single:()=>Promise.resolve({data:filas[0]||null,error:null}),
      insert:()=>api, update:()=>api, upsert:()=>api, delete:()=>api,
      then:f=>Promise.resolve({data:filas,error:null}).then(f)};
    return api;
  };
  window.supabase = {createClient: () => ({
    from:q,
    rpc:(n)=>Promise.resolve({data: n==='meta_avance'
      ? [{sede:'plaza',vendido:53},{sede:'angamos',vendido:2}] : [], error:null}),
    auth:{getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
      onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
      signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({})},
    channel:()=>({on(){return this;}, subscribe(cb){cb&&cb('SUBSCRIBED');return this;},
      track:async()=>{}, presenceState:()=>({})}),
    removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
  })};
}, {PRODUCTOS, METAS});
await page.route('**/supabase-js*', r => r.fulfill({status:200, contentType:'application/javascript', body:'/* simulado */'}));

const errores = [];
page.on('pageerror', e => errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz, 'index.html')).href);
await page.waitForTimeout(300);
await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(500);

/* ─── 3. el buscador ─── */
console.log('\nLa barra de búsqueda sigue funcionando:');
caso('se ve sin tener que abrirla', await page.isVisible('#q') || 'no está visible');
await page.fill('#q', 'croasan');
await page.waitForTimeout(250);
caso('encuentra sin tildes y filtra el resto', await page.evaluate(() => {
  const t = document.getElementById('list').textContent;
  return t.includes('Croasán') && !t.includes('Cheesecake');
}) || 'no filtró');
await page.fill('#q', 'AZUCAR');
await page.waitForTimeout(250);
caso('ignora mayúsculas y tildes al revés', await page.evaluate(() =>
  document.getElementById('list').textContent.includes('Azúcar')) || 'no encontró Azúcar');
await page.fill('#q', '');
await page.waitForTimeout(250);
caso('al vaciarlo vuelven todos', await page.evaluate(() =>
  document.querySelectorAll('.sec').length >= 3) || 'no volvieron las secciones');

/* ─── 4. la barra de metas ─── */
console.log('\nLa gráfica de metas de venta sigue pintando:');
caso('la meta viva aparece en el inventario', await page.isVisible('#metaPortada') || 'no se ve');
caso('con su nombre y su objetivo', await page.evaluate(() => {
  const t = document.getElementById('metaPortada').textContent;
  return t.includes('Agua Bosqua') && t.includes('100');
}) || 'falta el nombre o el objetivo');
caso('los dos lados tienen ancho, y distinto', await page.evaluate(() => {
  const b = document.querySelectorAll('#metaPortada .barra');
  if (b.length !== 2) return false;
  const a = parseFloat(b[0].style.width), c = parseFloat(b[1].style.width);
  return a > c && a > 0;
}) || 'las barras no se pintaron como corresponde');
caso('mientras se busca, la meta se va de la pantalla', await (async () => {
  await page.fill('#q', 'croasan');
  await page.waitForTimeout(200);
  const fuera = !(await page.isVisible('#metaPortada'));
  await page.fill('#q', '');
  await page.waitForTimeout(200);
  const vuelve = await page.isVisible('#metaPortada');
  return (fuera && vuelve) || (fuera ? 'no volvió al vaciar el buscador' : 'siguió estorbando');
})());
caso('el número de cada sede se lee (no es del color del fondo)', await page.evaluate(() => {
  const v = document.querySelector('#metaPortada .meta-lado.izq .val');
  const c = getComputedStyle(v).color;
  const f = getComputedStyle(document.querySelector('#metaPortada .meta-pista')).backgroundColor;
  return !!v && v.textContent.trim() === '53' && c !== f;
}) || 'el número no está o se confunde con la pista');

/* ─── 5. lo que se rediseñó, que de verdad quedó ─── */
console.log('\nY lo nuevo está donde tiene que estar:');
caso('el botón dice Actualizar', await page.evaluate(() =>
  document.getElementById('btnActualizar').textContent.includes('Actualizar')) || 'no dice nada');
caso('arriba se lee la SEDE, no "Inventario"', await page.evaluate(() =>
  document.getElementById('topTitle').textContent.includes('Mall Plaza')) || 'sigue el título viejo');
/* Las secciones arrancan CERRADAS —que es como se abre la app todos los
   días—, así que para mirar una fila primero hay que abrir una. Eso también
   comprueba que el acordeón sigue funcionando después del rediseño. */
caso('las secciones arrancan cerradas', await page.evaluate(() =>
  document.querySelectorAll('.row').length === 0) || 'ya había filas a la vista');
await page.click('.sec-btn');
await page.waitForTimeout(400);
caso('al tocar una, se abre con sus filas', await page.evaluate(() =>
  document.querySelectorAll('.row').length > 0) || 'no se abrió');
caso('la cabecera ya no es un bloque relleno', await page.evaluate(() => {
  const h = document.querySelector('.sec-head'), r = document.querySelector('.row');
  return !!h && !!r && getComputedStyle(h).backgroundColor === getComputedStyle(r).backgroundColor;
}) || 'la cabecera no usa el fondo de tarjeta');
caso('y las filas no llevan borde', await page.evaluate(() => {
  const r = document.querySelector('.row');
  return !!r && getComputedStyle(r).borderTopWidth === '0px';
}) || 'siguen con borde');
caso('la cabecera lleva el filo de color a la izquierda', await page.evaluate(() => {
  const h = document.querySelector('.sec-head');
  return !!h && getComputedStyle(h).boxShadow.includes('inset');
}) || 'no tiene el filo');
/* ─── EL GESTO DE DESLIZAR ─────────────────────────────────────────────────
   Esta prueba nace de un bug real (2026-08-20). La animación de entrada de
   las filas se puso con `animation-fill-mode: both`, y eso deja pegado el
   último fotograma para siempre — un fotograma que dice `transform:none`.
   Como una animación le gana a un estilo puesto a mano, la fila quedaba
   clavada: al deslizarla asomaba el símbolo, pero **la fila no se movía**.

   Jhon lo reportó así: "si bien ahí deslizó sí sale para mermar y para
   agregar a reparto, pero no se mueve literalmente el producto".

   Por eso lo que se comprueba NO es que el símbolo aparezca —eso seguía
   funcionando con el bug— sino que la fila **se haya movido de verdad**. */
console.log('\nDeslizar mueve la fila, no solo el símbolo:');
{
  const fila = await page.$('.sec-body .row');
  const caja = await fila.boundingBox();
  const y = caja.y + caja.height / 2;
  await page.mouse.move(caja.x + 40, y);
  await page.mouse.down();
  await page.mouse.move(caja.x + 140, y, {steps: 12});
  await page.waitForTimeout(120);

  const movida = await page.evaluate(() => {
    const r = document.querySelector('.sec-body .row.desliza') || document.querySelector('.sec-body .row');
    const t = getComputedStyle(r).transform;
    if (!t || t === 'none') return 0;
    return Math.abs(parseFloat(t.split(',')[4] || 0));   // el desplazamiento en X
  });
  caso('la fila se corre con el dedo', movida > 40 || `solo se movió ${movida}px — algo le está pisando el transform`);
  caso('y el símbolo asoma detrás', await page.isVisible('#swipe-icono') || 'no apareció');
  caso('hacia la derecha dice Mermar, no "+"', await page.evaluate(() =>
    document.getElementById('swipe-icono').textContent.trim() === 'Mermar')
    || 'dice: ' + await page.textContent('#swipe-icono'));

  await page.mouse.up();
  await page.waitForTimeout(600);
  caso('al soltar, se abre la ventana de mermar', await page.evaluate(() =>
    [...document.querySelectorAll('.overlay.open h2')].some(h => h.textContent.includes('Mermar')))
    || 'no se abrió');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);
}

caso('el carril de las pestañas se colocó', await page.evaluate(() => {
  const c = document.getElementById('tabCarril');
  return !!c && c.classList.contains('listo') && parseFloat(c.style.width) > 0;
}) || 'el carril no se midió');
caso('ningún error de JavaScript en toda la sesión',
  errores.length === 0 || errores.join(' | ').slice(0, 300));

console.log(`\n${mal ? '✗' : '✓'} ${ok} bien, ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
