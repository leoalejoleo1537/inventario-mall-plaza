/* Prueba del buscador de productos de una meta.
   node pruebas/metas-cuentan-por-sede.mjs

   LO QUE CUIDA, y sale de un error real del 2026-08-28: la meta del agua
   Bosqua decía que Angamos había vendido 2 cuando había vendido 116. No
   contaba de menos — contaba OTRO PRODUCTO. El id 584 es el agua con gas
   en Plaza y "Capuccino Pedidos Ya" en Angamos, porque los ids de Fudo
   solo son únicos dentro de una cuenta (`fudo_productos` lleva
   `unique (sede, fudo_product_id)`).

   Dos cosas se prueban acá, y las dos en las dos direcciones:

   1. Que cada id viaje CON SU SEDE. Es lo que impide que un id signifique
      otra cosa al cruzar de cuenta.
   2. Que el catálogo se lea ENTERO. Antes se pedía con `.limit(1000)` y
      entre las dos sedes hay ~1.280 productos: Supabase corta ahí y no
      avisa, así que media carta de Angamos no llegaba al buscador. Esta
      prueba pone 1.280 productos a propósito y comprueba que el de la
      página 2 aparezca — es la única forma de que un tope silencioso deje
      de ser silencioso.

   Lee las funciones DE VERDAD desde index.html, no una copia.              */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');

const ini = html.indexOf('/* EL CATÁLOGO DE FUDO SE LEE ENTERO');
const fin = html.indexOf('async function metaCrear(');
if (ini < 0 || fin < 0) {
  console.error('✗ no encontré metaBuscar/metaCartaFudo en index.html'); process.exit(1);
}

/* La carta de mentira: 1.280 productos, como en la vida real. El agua de
   Angamos va DESPUÉS de la fila 1000 a propósito — es la que se perdía. */
const carta = [];
for (let i = 0; i < 640; i++) carta.push({sede:'plaza', fudo_product_id:String(i), nombre:'Relleno plaza '+i});
carta[584] = {sede:'plaza', fudo_product_id:'584', nombre:'Agua Bosqua con gas'};
for (let i = 0; i < 640; i++) carta.push({sede:'angamos', fudo_product_id:String(i), nombre:'Relleno angamos '+i});
/* En Angamos el 584 es otra cosa, igual que en producción. */
carta[640 + 584] = {sede:'angamos', fudo_product_id:'584', nombre:'Capuccino Pedidos Ya'};
carta[640 + 600] = {sede:'angamos', fudo_product_id:'901', nombre:'Agua Bosqua con gas'};

let paginasPedidas = 0;
const sb = {
  from(){ return {
    select(){ return this; },
    order(){ return this; },
    range(d, h){
      paginasPedidas++;
      return Promise.resolve({data: carta.slice(d, h + 1), error: null});
    }
  };}
};

const entorno = `
  const SEDES = {plaza:{label:'Café Mall Plaza'}, angamos:{label:'Parque Angamos'}};
  const esc = t => String(t).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/"/g,'&quot;');
  const normNombre = t => String(t||'').toLowerCase()
    .normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').replace(/\\s+/g,' ').trim();
  let META_SEL = [];
  let SALIDA = '';
  const $ = id => id === 'meta-q' ? {value: BUSCADO} : {set innerHTML(v){ SALIDA = v; }, get innerHTML(){ return SALIDA; }};
  let BUSCADO = '';
`;

const api = new Function('sb', entorno + html.slice(ini, fin) +
  `; return {metaBuscar, metaCartaFudo,
             buscar: async q => { BUSCADO = q; await metaBuscar(); return SALIDA; },
             elegidos: () => META_SEL, poner: p => META_SEL.push(p)};`)(sb);

let ok = 0, fallos = 0;
const caso = (nombre, cond) => {
  if (cond === true) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}${typeof cond === 'string' ? ' — ' + cond : ''}`); }
};

console.log('\nEl catálogo se lee entero, no los primeros 1000:');
const todo = await api.metaCartaFudo();
caso('llegaron los 1.280 productos', todo.length === 1280 || `llegaron ${todo.length}`);
caso('hizo falta más de una página', paginasPedidas > 1 || `pidió ${paginasPedidas}`);

console.log('\nEl agua aparece en las DOS sedes, incluida la que estaba pasada la fila 1000:');
const res = await api.buscar('agua bosqua');
caso('la encuentra', res.includes('Agua Bosqua con gas') || res);
caso('dice que está en las dos sedes',
  res.includes('Café Mall Plaza') && res.includes('Parque Angamos') || res);

console.log('\nCada id viaja con su sede — esto es lo que arregla el error:');
caso('guarda el par de Plaza',   res.includes('plaza:584'));
caso('guarda el par de Angamos', res.includes('angamos:901'));
caso('NO guarda el 584 de Angamos, que es un capuchino',
  !res.includes('angamos:584') || 'se coló el id equivocado');
caso('y no guarda ids pelados, sin sede',
  !/data-metaadd="[0-9]/.test(res) || 'hay un id sin sede');

console.log('\nUn producto que solo existe en una sede lo dice, y no inventa la otra:');
const solo = await api.buscar('capuccino pedidos');
caso('lo encuentra', solo.includes('Capuccino Pedidos Ya') || solo);
caso('dice solo Angamos',
  solo.includes('Parque Angamos') && !solo.includes('Café Mall Plaza') || solo);

console.log('\nLo que se guarda al crear la meta se parte en sede + id:');
/* Se repite la conversión de metaCrear, que es la que escribe en la base. */
const partir = sel => {
  const filas = [];
  for (const p of sel) for (const par of String(p.id).split(',')) {
    const c = par.indexOf(':');
    if (c < 0) continue;
    filas.push({sede: par.slice(0, c), fudo_product_id: par.slice(c + 1), nombre: p.nombre});
  }
  return filas;
};
const filas = partir([{id:'plaza:584,angamos:901', nombre:'Agua Bosqua con gas'}]);
caso('salen dos filas, una por sede', filas.length === 2 || `salieron ${filas.length}`);
caso('la de Plaza lleva el 584',
  filas.some(f => f.sede === 'plaza' && f.fudo_product_id === '584'));
caso('la de Angamos lleva el 901, no el 584',
  filas.some(f => f.sede === 'angamos' && f.fudo_product_id === '901'));
caso('ninguna queda sin sede', filas.every(f => f.sede));

console.log('\nY una fila vieja, sin sede, no se cuela como si fuera válida:');
caso('un par sin ":" se descarta en vez de guardarse a medias',
  partir([{id:'584', nombre:'Agua'}]).length === 0);

console.log(`\n${ok} bien · ${fallos} mal`);
process.exit(fallos ? 1 : 0);
