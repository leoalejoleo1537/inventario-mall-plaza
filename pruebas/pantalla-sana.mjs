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

// ---------- 4. dos funciones con el mismo nombre ----------
/* Agregado el 2026-08-12, y sale de un bug peor que el de la comprobación 3.
   Se escribió `function candidatos()` para Enlaces sin ver que Recetas ya
   tenía una. Dos `const` iguales al menos revientan el archivo y se notan;
   dos `function` iguales NO dan ningún error: la última gana en silencio y
   la primera deja de existir. La pantalla de Enlaces mostraba "no hay ningún
   candidato" para productos que sí tenían, y nada en la consola.

   Solo mira las declaraciones de primer nivel (las que empiezan en la columna
   0). Las de adentro de otra función pueden repetirse sin problema. */
const nivel1 = [...html.matchAll(/^function\s+([A-Za-z_$][\w$]*)\s*\(/gm)].map(m => m[1]);
const cuenta = new Map();
nivel1.forEach(n => cuenta.set(n, (cuenta.get(n) || 0) + 1));
const dobles = [...cuenta].filter(([, n]) => n > 1).map(([f]) => f);
if (dobles.length) {
  fallos++;
  console.log('  ✗ dos funciones con el mismo nombre: ' + dobles.join(', '));
  console.log('      no da error en ninguna parte: la última gana y la primera se pierde.');
} else {
  console.log(`  ✓ las ${nivel1.length} funciones tienen nombres distintos`);
}

// ---------- 5. una pestaña que no lleva a ninguna parte ----------
/* Agregado el 2026-08-18. Jhon lo dijo así: "los presiono y no pasa nada".
   Un botón de pestaña sin su rama en pickTab() no da ningún error: se pinta
   como activo y la pantalla se queda igual. Es la falla callada de siempre en
   su forma más chica, y la atrapa una comparación de dos listas.

   Se comprueban las dos direcciones: que cada pestaña del HTML tenga título y
   que pickTab() la nombre. */
const pestanas = [...new Set([...html.matchAll(/class="tab[^"]*"[^>]*data-tab="([a-z]+)"/g)].map(m => m[1]))];
const titulos = (html.match(/const TITULOS = \{([^}]*)\}/) || [, ''])[1];
const ini = html.indexOf('function pickTab(');
const cuerpo = ini < 0 ? '' : html.slice(ini, html.indexOf('\ndocument.querySelectorAll(\'.tab\')', ini));
const huerfanas = pestanas.filter(t => !new RegExp(`['"]${t}['"]`).test(cuerpo));
const sinTitulo = pestanas.filter(t => !new RegExp(`\\b${t}\\s*:`).test(titulos));
if (huerfanas.length || sinTitulo.length) {
  fallos++;
  if (huerfanas.length) console.log('  ✗ pestañas que pickTab() no nombra: ' + huerfanas.join(', '));
  if (sinTitulo.length) console.log('  ✗ pestañas sin título en TITULOS: ' + sinTitulo.join(', '));
  console.log('      se pintan como activas y no pasa nada: no da error en ninguna parte.');
} else {
  console.log(`  ✓ las ${pestanas.length} pestañas llevan a una pantalla y tienen título`);
}

console.log(fallos ? `\n${fallos} problema(s)` : '\nla pantalla está sana');
process.exit(fallos ? 1 : 0);
