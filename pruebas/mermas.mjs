/* Prueba de la vista previa de la merma.
   Se corre con:  node pruebas/mermas.mjs
   No necesita navegador ni base de datos: extrae la función de index.html.

   Qué protege: el renglón que la persona lee JUSTO ANTES de apretar "Mermar".
   Es la vista previa que pide §6.2 para toda acción que destruye, y si miente
   —o si deja apretar cuando no se puede— el daño ya está hecho cuando se nota.

   La regla dura que se prueba acá es la 0.2: no se puede mermar más de lo que
   hay, porque el stock nunca puede quedar negativo. La base lo vuelve a
   comprobar dentro de mermar(); esto es para que la pantalla no llegue
   siquiera a pedírselo. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');

const i = html.indexOf('function textoPrevio(');
const f = html.indexOf('function abrirMerma');
if (i < 0 || f < 0 || f <= i) { console.error('✗ no encontré textoPrevio en index.html'); process.exit(1); }
/* `fmt` viene de la app y también se saca del archivo, para que el número se
   redondee igual acá que en la pantalla. */
const fi = html.indexOf('const fmt = n =>');
const textoPrevio = new Function(
  html.slice(fi, html.indexOf('const hoyISO')) + html.slice(i, f) + '; return textoPrevio;')();

let ok = 0, fallos = 0;
const caso = (nombre, dio, esperado) => {
  const bien = JSON.stringify(dio) === JSON.stringify(esperado);
  if (bien) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}\n      esperaba ${JSON.stringify(esperado)}, dio ${JSON.stringify(dio)}`); }
};

console.log('\nNo se puede mermar más de lo que hay (regla 0.2)');
caso('10 disponibles, merma 99 → avisa y NO deja apretar',
     textoPrevio(10, 99), { txt: 'Solo hay 10', mal: true, puede: false });
caso('10 disponibles, merma exactamente 10 → deja, y queda en 0',
     textoPrevio(10, 10), { txt: 'Quedan 0 de 10', mal: false, puede: true });
caso('10 disponibles, merma 10.5 → no deja',
     textoPrevio(10, 10.5), { txt: 'Solo hay 10', mal: true, puede: false });
caso('0 disponibles, merma 1 → no deja',
     textoPrevio(0, 1), { txt: 'Solo hay 0', mal: true, puede: false });

console.log('\nSin cantidad no se puede apretar');
caso('todavía no escribe nada', textoPrevio(10, 0), { txt: '¿Cuánto se merma?', mal: false, puede: false });
caso('un negativo tampoco',     textoPrevio(10, -3), { txt: '¿Cuánto se merma?', mal: false, puede: false });

console.log('\nLa cuenta que se muestra es la correcta');
caso('de 10 merma 3, quedan 7',   textoPrevio(10, 3),   { txt: 'Quedan 7 de 10', mal: false, puede: true });
caso('decimales, como el café',   textoPrevio(2.5, 0.5), { txt: 'Quedan 2 de 2.5', mal: false, puede: true });
caso('no arrastra colas de coma', textoPrevio(0.3, 0.1), { txt: 'Quedan 0.2 de 0.3', mal: false, puede: true });

console.log(`\n${fallos ? '✗' : '✓'} ${ok} bien, ${fallos} mal\n`);
process.exit(fallos ? 1 : 0);
