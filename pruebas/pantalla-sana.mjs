/* Revisa index.html sin abrir un navegador:
     1. que no haya dos elementos con el mismo id
     2. que todo $('algo') del código apunte a un id que existe
   node pruebas/pantalla-sana.mjs

   Por qué existe: el 2026-07-31 había dos botones con id="rec-cancelar". Como
   getElementById devuelve solo el primero, los dos addEventListener caían en
   el mismo elemento y el Cancelar del editor de recetas quedó SIN nada. No dio
   error en ninguna parte: simplemente no cerraba, y así vivió semanas.        */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');

let fallos = 0;

// ---------- 1. ids repetidos ----------
const ids = [...html.matchAll(/\sid="([A-Za-z0-9_-]+)"/g)].map(m => m[1]);
const vistos = new Map();
const repes = [];
for (const id of ids) {
  vistos.set(id, (vistos.get(id) || 0) + 1);
  if (vistos.get(id) === 2) repes.push(id);
}
if (repes.length) {
  fallos++;
  console.log('  ✗ ids repetidos: ' + repes.join(', '));
  console.log('      getElementById devuelve solo el primero: el segundo se queda sin manejador.');
} else {
  console.log(`  ✓ los ${ids.length} ids son únicos`);
}

// ---------- 2. $('algo') que no existe ----------
const usados = new Set([...html.matchAll(/\$\('([A-Za-z0-9_-]+)'\)/g)].map(m => m[1]));
const existen = new Set(ids);
const fantasmas = [...usados].filter(u => !existen.has(u));
if (fantasmas.length) {
  fallos++;
  console.log('  ✗ el código busca ids que no están en el HTML: ' + fantasmas.join(', '));
} else {
  console.log(`  ✓ los ${usados.size} elementos que busca el código existen`);
}

console.log(fallos ? `\n${fallos} problema(s)` : '\nla pantalla está sana');
process.exit(fallos ? 1 : 0);
