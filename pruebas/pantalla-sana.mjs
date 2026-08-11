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

// ---------- 3. que el guion se pueda leer entero ----------
/* Agregado el 2026-08-10 después de romper la app entera con una línea.
   Se declaró `const MOTIVOS` para las mermas sin ver que Recetas ya tenía uno.
   Dos `const` con el mismo nombre no son un error de esa línea: el navegador
   se niega a leer el archivo COMPLETO, así que no se ejecutó ni una función.
   La pantalla se dibujaba igual —el HTML está sano— y no hacía nada.

   Las dos comprobaciones de arriba pasaron en verde con la app muerta, porque
   miran el HTML y no el guion. Esta lo intenta leer de verdad: no lo ejecuta
   (necesitaría un navegador), pero un nombre repetido, una llave sin cerrar o
   un paréntesis de más aparecen al intentar interpretarlo. */
const guiones = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map(m => m[1]);
let malos = 0;
guiones.forEach((codigo, i) => {
  try { new Function(codigo); }
  catch (e) {
    malos++; fallos++;
    console.log(`  ✗ el guion ${i + 1} no se puede leer: ${e.message}`);
    console.log('      con esto el navegador NO ejecuta nada del archivo: la app se abre y no responde.');
  }
});
if (!malos) console.log(`  ✓ los ${guiones.length} guiones se leen sin error de sintaxis`);

console.log(fallos ? `\n${fallos} problema(s)` : '\nla pantalla está sana');
process.exit(fallos ? 1 : 0);
