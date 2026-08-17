/* Prueba de juzgarMotor() — el aviso que NO depende de que alguien apriete ⟳.
   node pruebas/aviso-del-motor.mjs                                            */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');
const ini = html.indexOf('const MOTOR_SIN_NOTICIAS_MIN');
const fin = html.indexOf('async function revisarMotor');
if (ini < 0 || fin < 0) { console.error('✗ no encontré juzgarMotor en index.html'); process.exit(1); }
const { juzgarMotor, haceCuanto } =
  new Function(html.slice(ini, fin) + '; return {juzgarMotor, haceCuanto};')();

const AHORA = new Date('2026-07-31T12:00:00Z').getTime();
const haceMin = m => new Date(AHORA - m*60000).toISOString();

let ok = 0, fallos = 0;
const caso = (nombre, sync, esperado) => {
  const r = juzgarMotor(sync, AHORA);
  const nivel = r ? r.nivel : null;
  if (nivel === esperado) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}\n      esperaba ${esperado}, dio ${nivel}${r?' → "'+r.texto+'"':''}`); }
};

console.log('\nTiene que avisar:');
caso('el motor falló en la última corrida',
     {ultimo_resultado:'falla', ultima_corrida_at:haceMin(10), cron_activo:false}, 'grave');
/* Baja de 'grave' a 'tibio' a propósito (2026-08-15). Que el reloj no haya
   corrido NO es una avería: el inventario está bien, solo Fudo quedó
   atrasado, y cualquiera lo arregla con un toque al ⟳. En rojo, la gente
   del mesón lo leía como "la app se rompió" y lo escribía en el grupo de
   jefatura. El rojo se reserva para lo que de verdad está roto. */
caso('cron encendido y lleva 3 h sin correr',
     {ultimo_resultado:'ok', ultima_corrida_at:haceMin(180), cron_activo:true}, 'tibio');
caso('fallo parcial: avisa, pero en ámbar',
     {ultimo_resultado:'parcial', ultimos_errores:3, ultimos_items:20,
      ultima_corrida_at:haceMin(5), cron_activo:false}, 'tibio');

console.log('\nNO debe avisar (los avisos falsos son el peor enemigo):');
caso('todo bien y recién corrido',
     {ultimo_resultado:'ok', ultima_corrida_at:haceMin(3), cron_activo:true}, null);
caso('SIN cron: 5 h sin correr es normal, depende del botón',
     {ultimo_resultado:'ok', ultima_corrida_at:haceMin(300), cron_activo:false}, null);
caso('sede recién encendida: nunca ha corrido (el caso Angamos)',
     {ultimo_resultado:null, ultima_corrida_at:null, cron_activo:false}, null);
caso('cron encendido pero recién activado, sin corridas todavía',
     {ultimo_resultado:null, ultima_corrida_at:null, cron_activo:true}, null);
caso('justo antes del umbral: 44 min con cron',
     {ultimo_resultado:'ok', ultima_corrida_at:haceMin(44), cron_activo:true}, null);
caso('la fila no existe todavía', null, null);

console.log('\nJusto en el umbral (45 min) sí avisa:');
caso('45 min con cron encendido',
     {ultimo_resultado:'ok', ultima_corrida_at:haceMin(45), cron_activo:true}, 'tibio');

console.log('\nEl "hace cuánto" se lee bien:');
const esperado = {0:'recién', 1:'recién', 20:'hace 20 min', 90:'hace 1 h', 3000:'hace 2 días'};
for (const [m, txt] of Object.entries(esperado)) {
  const r = haceCuanto(Number(m));
  if (r === txt) { ok++; console.log(`  ✓ ${m} min → "${r}"`); }
  else { fallos++; console.log(`  ✗ ${m} min → "${r}", esperaba "${txt}"`); }
}

console.log(`\n${ok} bien · ${fallos} mal`);
process.exit(fallos ? 1 : 0);
