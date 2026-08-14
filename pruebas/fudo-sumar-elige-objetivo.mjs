/* Prueba de elegirObjetivos() — a qué producto de Fudo se le avisa cuando
   llega un reparto.
   node pruebas/fudo-sumar-elige-objetivo.mjs

   EL CASO QUE LA MOTIVA (2026-08-14): los Cannolis de Mall Plaza se
   aceptaron en el reparto y Fudo no cambió. El reparto entra al Congelador
   y la receta descuenta de la Vitrina — dos fichas distintas, así que la
   búsqueda por id exacto no encontraba a quién avisarle y devolvía
   "sumados 0" en silencio.

   Se prueba en LAS DOS DIRECCIONES, que es lo que importa acá: que
   encuentre por la gemela cuando corresponde, y que NO invente un objetivo
   cuando no corresponde — sumarle a Fudo un producto que no es sería peor
   que no sumarle nada.

   Lee la función DE VERDAD desde el .ts, no una copia. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const ts = readFileSync(join(raiz, 'supabase/functions/fudo-sumar-stock/index.ts'), 'utf8');

/* Se recortan las dos funciones puras y se les quitan los tipos de
   TypeScript, que es lo único que Node no entiende. */
const recorte = (desde, hasta) => {
  const i = ts.indexOf(desde);
  const j = ts.indexOf(hasta, i);
  if (i < 0 || j < 0) { console.error(`✗ no encontré ${desde} en index.ts`); process.exit(1); }
  return ts.slice(i, j);
};
const fuente = (recorte('export function elegirObjetivos', '\n/* Nombre base')
              + recorte('function base(s: unknown)', '\nfunction json'))
  .replace(/^export /gm, '')
  .replace(/: any\[\]/g, '').replace(/: any/g, '')
  .replace(/: number/g, '').replace(/: unknown/g, '').replace(/: string/g, '')
  .replace(/ as string \| null/g, '');
const { elegirObjetivos } = new Function(fuente + '; return {elegirObjetivos};')();

let ok = 0, fallos = 0;
const caso = (nombre, recetas, productoId, productos, esperado) => {
  const r = elegirObjetivos(recetas, productoId, productos);
  const dio = r.objetivos.map(o => o.fudo_product_nombre).sort().join(',') + '|' + (r.porGemelo ?? '—');
  const esp = [...esperado.fudo].sort().join(',') + '|' + (esperado.gemelo ?? '—');
  if (dio === esp) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}\n      esperaba ${esp}\n      dio      ${dio}`); }
};

/* ---------- el mundo de la prueba ---------- */
const productos = [
  { id: 1, producto: 'Cannoli Congelador' },
  { id: 2, producto: 'Cannoli Vitrina' },
  { id: 3, producto: 'Alfajor artesanal' },
  { id: 4, producto: 'Bolsa kraft m' },
  { id: 5, producto: 'Sandwich Azapa' },
  { id: 6, producto: 'Macarrons Congelador' },
  { id: 7, producto: 'Macarrons Vitrina de dulces' },
];
const receta = (nombre, lineas) => ({ id: nombre, fudo_product_nombre: nombre, receta_items: lineas });
const recetas = [
  receta('Cannoli',        [{ producto_id: 2, cantidad: 1 }]),          // vive en la vitrina
  receta('Alfajor',        [{ producto_id: 3, cantidad: 1 }]),          // 1:1 normal
  receta('AZAPA + CAFE',   [{ producto_id: 5, cantidad: 1 }, { producto_id: 3, cantidad: 1 }]), // combo
  receta('Torta entera',   [{ producto_id: 3, cantidad: 12 }]),         // 1 línea pero cantidad 12
];

console.log('\nLo que ya funcionaba tiene que seguir igual:');
caso('ficha con su propia receta 1:1', recetas, 3, productos, { fudo: ['Alfajor'], gemelo: null });
caso('producto sin receta en ninguna ficha', recetas, 4, productos, { fudo: [], gemelo: null });
caso('producto que solo está en un combo · no se toca',
     recetas, 5, productos, { fudo: [], gemelo: null });
caso('receta de 1 línea pero cantidad 12 · no es 1:1',
     [receta('Torta entera', [{ producto_id: 9, cantidad: 12 }])], 9, productos,
     { fudo: [], gemelo: null });

console.log('\nEL CASO CANNOLI · llega al congelador, la receta vive en la vitrina:');
caso('encuentra por la gemela', recetas, 1, productos,
     { fudo: ['Cannoli'], gemelo: 'Cannoli Vitrina' });
caso('y desde la vitrina sigue siendo el camino directo, sin gemelo',
     recetas, 2, productos, { fudo: ['Cannoli'], gemelo: null });

console.log('\nLo que NO debe pasar (acá es donde un arreglo se vuelve un bug):');
/* Si CADA ficha del par tiene su propia receta, son dos productos distintos
   en Fudo y hay que tocar solo el que corresponde. Buscar gemelas igual
   sumaría el reparto dos veces. */
const cadaUnaLaSuya = [
  receta('Cannoli',          [{ producto_id: 1, cantidad: 1 }]),
  receta('Cannoli en caja',  [{ producto_id: 2, cantidad: 1 }]),
];
caso('cada ficha con SU receta · solo se toca la suya',
     cadaUnaLaSuya, 1, productos, { fudo: ['Cannoli'], gemelo: null });
caso('y la otra igual, sin contagiarse',
     cadaUnaLaSuya, 2, productos, { fudo: ['Cannoli en caja'], gemelo: null });

/* El nombre base es el MISMO criterio que la app y la base de datos, ni más
   ni menos. "Vitrina de dulces" no lo entiende ninguno de los tres — es el
   renombre que quedó pendiente con los macarrons (§6.0). Que esta prueba lo
   deje escrito evita que alguien "arregle" solo este lado y lo desalinee. */
caso('"Vitrina de dulces" NO empareja · igual que en la app y en la base',
     [receta('Macarrons', [{ producto_id: 7, cantidad: 1 }])], 6, productos,
     { fudo: [], gemelo: null });

caso('producto que no está en la lista de la sede', recetas, 999, productos,
     { fudo: [], gemelo: null });
caso('sin recetas todavía · sede recién encendida', [], 1, productos,
     { fudo: [], gemelo: null });
caso('sin la lista de productos · primera pasada, antes de pedirla',
     recetas, 1, [], { fudo: [], gemelo: null });

console.log(`\n${fallos ? '✗' : '✓'} ${ok} bien, ${fallos} mal\n`);
process.exit(fallos ? 1 : 0);
