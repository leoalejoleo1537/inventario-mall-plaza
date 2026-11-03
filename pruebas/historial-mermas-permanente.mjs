/* El libro de mermas es histórico: se puede analizar dentro de meses o años.
   Esta prueba evita dos regresiones muy fáciles de cometer:
   - volver a limpiar las mermas junto con los movimientos transitorios;
   - volver a leer/exportar solo una primera página de 500 filas. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');
const migracion = readFileSync(join(raiz, 'sql/2026-11-conservar-historial-mermas.sql'), 'utf8');
const prototipo = readFileSync(join(raiz, 'docs/propuesta-mermas-dashboard.html'), 'utf8');

let mal = 0;
const caso = (nombre, condicion) => {
  if (condicion) console.log('  ✓ ' + nombre);
  else { mal++; console.log('  ✗ ' + nombre); }
};

const inicio = html.indexOf('async function loadMermas()');
const fin = html.indexOf('const MOT_MERMA_TXT', inicio);
const carga = inicio >= 0 && fin > inicio ? html.slice(inicio, fin) : '';

console.log('\nHistorial permanente de mermas:');
caso('la limpieza excluye explícitamente las mermas',
  migracion.includes("tipo is distinct from 'merma'"));
caso('hay índice para leer el libro histórico por fecha',
  migracion.includes('movimientos_merma_created_at_idx'));
caso('la pantalla lee todas las páginas, no una sola',
  html.includes('.range(offset,offset+porPagina-1)') && html.includes('todas.push(...pagina)'));
caso('la pantalla no vuelve al tope de 500', !carga.includes('.limit(500)'));
caso('el prototipo muestra el producto más mermado',
  prototipo.includes('PRODUCTO MÁS MERMADO'));

console.log(`\n${mal ? '✗' : '✓'} ${mal ? mal + ' fallo(s)' : 'sin fallos'}\n`);
process.exit(mal ? 1 : 0);
