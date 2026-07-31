/* Prueba de juzgarVentas() — la alarma del motor de descuento.
   Se corre con:  node pruebas/alarma-de-ventas.mjs
   No necesita navegador ni base de datos: extrae la función de index.html
   y la evalúa. Si index.html cambia, esta prueba sigue leyendo la de verdad.  */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');

const ini = html.indexOf('const UMBRAL_GRAVE');
const fin = html.indexOf('const PASOS_SYNC');
if (ini < 0 || fin < 0) { console.error('✗ no encontré juzgarVentas en index.html'); process.exit(1); }
const juzgarVentas = new Function(html.slice(ini, fin) + '; return juzgarVentas;')();

let ok = 0, fallos = 0;
const caso = (nombre, datos, esperado) => {
  const r = juzgarVentas(datos);
  const bien = r.grave === esperado;
  if (bien) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}\n      esperaba grave=${esperado}, dio ${r.grave} → "${r.texto}"`); }
};

console.log('\nLa alarma TIENE que sonar:');
caso('la falla de julio: todo falla, nada se descontó',
     {ventas_leidas:9, items_procesados:0, errores:20, movimientos_generados:0}, true);
caso('fallo parcial grande: 8 de 20 ítems (40%)',
     {ventas_leidas:9, items_procesados:12, errores:8, movimientos_generados:30}, true);
caso('justo en el umbral: 2 de 20 ítems (10%)',
     {ventas_leidas:9, items_procesados:18, errores:2, movimientos_generados:40}, true);

console.log('\nLa alarma NO debe sonar:');
caso('semana real de Mall Plaza: 1685 ítems, cero errores',
     {ventas_leidas:600, items_procesados:1685, errores:0, movimientos_generados:1685}, false);
caso('sin ventas nuevas', {ventas_leidas:0, items_procesados:0, errores:0, movimientos_generados:0}, false);
caso('releer ventas ya procesadas: 0 movimientos y 0 errores es NORMAL',
     {ventas_leidas:9, items_procesados:20, errores:0, movimientos_generados:0}, false);
caso('un error aislado: 1 de 200 ítems (0,5%)',
     {ventas_leidas:60, items_procesados:199, errores:1, movimientos_generados:400}, false);
caso('respuesta vacía o rara no debe reventar', {}, false);

console.log('\nEl texto explica el problema:');
const g = juzgarVentas({ventas_leidas:9, items_procesados:12, errores:8, movimientos_generados:30});
if (/8 de 20/.test(g.texto) && /40%/.test(g.texto)) { ok++; console.log('  ✓ dice cuántos fallaron y el porcentaje'); }
else { fallos++; console.log('  ✗ el texto no dice el número:', g.texto); }

console.log(`\n${ok} bien · ${fallos} mal`);
process.exit(fallos ? 1 : 0);
