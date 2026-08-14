/* Prueba de los números de crítico de Bodega — hoy son las ALARMAS del tablero.
   Las tarjetas por sede se quitaron el 2026-08-13: repetían en la misma
   pantalla lo que ya dice la fila de alarmas. La regla no cambió ni un poco, y
   numeroTarjeta() ahora recibe también un número ya contado —los vencidos, que
   son una suma de cantidades y no un largo de lista— con el mismo criterio.
   Se corre con:  node pruebas/critico-por-sede.mjs
   No necesita navegador ni base de datos: extrae las funciones de index.html
   y las evalúa. Si index.html cambia, esta prueba sigue leyendo las de verdad.

   Qué protege, en orden de importancia:

   1. Que una lectura fallida muestre "—" y NUNCA 0. Un 0 diría "a esa sede no
      le falta nada" justo cuando no lo sabemos, y Adriana armaría el reparto
      dejando ese local afuera. Es la falla callada de §0.5 en versión chica, y
      es lo único de esta pantalla que puede hacer daño de verdad.

   2. Que la regla de "crítico" siga siendo LA MISMA que usa la pantalla del
      local. La tarjeta no tiene una copia de la regla: usa estado(). Esta
      prueba extrae estado() del archivo real, así que si alguien la cambia en
      un lado y no en el otro, esto se pone rojo.

   3. Que el orden de la lista sea por lo que más falta, que es el orden en que
      se decide qué mandar. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');

const trozo = (desde, hasta, comoSeLlama) => {
  const i = html.indexOf(desde), f = html.indexOf(hasta);
  if (i < 0 || f < 0 || f <= i) {
    console.error(`✗ no encontré ${comoSeLlama} en index.html`);
    console.error(`   (buscaba desde "${desde}" hasta "${hasta}")`);
    process.exit(1);
  }
  return html.slice(i, f);
};

/* Se arma un solo trozo con las dos partes que se necesitan: el semáforo y la
   regla de qué entra en Crítico. `hasUrgente` se declara acá porque en la app
   es una variable de la sede abierta y no viene en estos trozos. */
const { estado, entraEnCritico, urgenteDe } = new Function(
  'let hasUrgente = true;\n'
  + trozo('function maxOk(p)', 'const CFG =', 'estado()')
  + trozo('function esUrgente(p)', 'const $ = id =>', 'entraEnCritico()')
  + '; return {estado, entraEnCritico, urgenteDe};')();
const faltaPara = new Function(
  trozo('const faltaPara =', 'function abrirCriticos', 'faltaPara()') + '; return faltaPara;')();
const numeroTarjeta = new Function(
  trozo('function numeroTarjeta(', '/* Cuánto le falta', 'numeroTarjeta()') + '; return numeroTarjeta;')();

let ok = 0, fallos = 0;
const caso = (nombre, dio, esperado) => {
  const bien = JSON.stringify(dio) === JSON.stringify(esperado);
  if (bien) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}\n      esperaba ${JSON.stringify(esperado)}, dio ${JSON.stringify(dio)}`); }
};

console.log('\nLo que NO puede pasar nunca: que un error se vea como un cero');
caso('la lectura falló → raya, no 0', numeroTarjeta(null, false), '—');
caso('todavía no llega → punto, no 0', numeroTarjeta(undefined, false), '·');
caso('leyó bien y no falta nada → 0 de verdad', numeroTarjeta([], false), '0');
caso('leyó bien y faltan 3', numeroTarjeta([1, 2, 3], false), '3');
caso('chocó con el tope de 1000 → el número lleva "+"', numeroTarjeta([1, 2], true), '2+');
caso('un error con tope igual muestra raya, el tope no lo tapa', numeroTarjeta(null, true), '—');
caso('un número ya contado pasa igual (los vencidos)', numeroTarjeta(7, false), '7');
caso('cero vencidos de verdad sí es 0',                numeroTarjeta(0, false), '0');

console.log('\nLa regla de crítico es la misma que la del local (estado())');
const p = (stock, min, max) => ({ stock_actual: stock, stock_min: min, stock_max: max });
caso('en 0 es crítico aunque el mínimo sea 0',   estado(p(0, 0, 10)),    'critico');
caso('en 0 es crítico aunque no tenga mínimo',   estado(p(0, null, 10)), 'critico');
caso('justo en el mínimo es crítico',            estado(p(5, 5, 20)),    'critico');
caso('por debajo del mínimo es crítico',         estado(p(2, 5, 20)),    'critico');
caso('uno por encima del mínimo NO es crítico',  estado(p(6, 5, 20)),    'ok');
caso('sin dato no es crítico, es sin dato',      estado(p(null, 5, 20)), 'sindato');
caso('por encima del máximo es sobre-stock',     estado(p(30, 5, 20)),   'sobre');

console.log('\nLo URGENTE viaja de la sede a la tarjeta de Bodega');
const u = (stock, min, urgente) => ({ producto: 'x', stock_actual: stock, stock_min: min, urgente });
caso('marcado urgente entra aunque el número esté sano', entraEnCritico(u(20, 5, true)),  true);
caso('urgente Y crítico entra igual',                    entraEnCritico(u(1, 5, true)),   true);
caso('crítico sin marcar entra por el semáforo',         entraEnCritico(u(1, 5, false)),  true);
caso('sano y sin marcar NO entra',                       entraEnCritico(u(20, 5, false)), false);
caso('sin la columna urgente manda solo el semáforo',    entraEnCritico(p(20, 5, 50)),    false);
caso('lo reconoce como urgente',                         urgenteDe(u(20, 5, true)),       true);

console.log('\nEl número grande NO se infla con los urgentes que están sanos');
const sede = [u(0, 5, false), u(2, 5, false), u(30, 5, true)];
caso('a la lista entran los 3', sede.filter(entraEnCritico).length, 3);
caso('pero el número de la tarjeta dice 2, igual que en el local',
     numeroTarjeta(sede.filter(x => estado(x) === 'critico'), false), '2');
caso('y la píldora naranja cuenta 1 urgente', sede.filter(urgenteDe).length, 1);

console.log('\nEl orden: primero lo que más falta');
const bandeja = { producto: 'Bandeja', stock_actual: 0, stock_min: 50 };
const leche   = { producto: 'Leche',   stock_actual: 2, stock_min: 6 };
const vaso    = { producto: 'Vaso',    stock_actual: 0, stock_min: null };
caso('a la bandeja le faltan 50', faltaPara(bandeja), 50);
caso('a la leche le faltan 4',    faltaPara(leche),   4);
caso('sin mínimo y en 0, la distancia es 0 (lo desempata el stock)', faltaPara(vaso), 0);
caso('ordenados, la bandeja va primera',
     [leche, vaso, bandeja].sort((a, b) => faltaPara(b) - faltaPara(a)).map(x => x.producto),
     ['Bandeja', 'Leche', 'Vaso']);

console.log(`\n${fallos ? '✗' : '✓'} ${ok} bien, ${fallos} mal\n`);
process.exit(fallos ? 1 : 0);
