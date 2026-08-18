/* Prueba de la detección de pares vitrina/congelador.
   node pruebas/pares-de-mueble.mjs

   POR QUÉ EXISTE: la relación entre "Brownie Vitrina" y "Brownie
   Congelador" no está escrita en ninguna parte — el sistema la deduce del
   nombre. Un apellido que no reconoce rompe el par y NO se nota: pasó con
   `Macarrons Vitrina de dulces`, que nunca sumó con su congelador y dejó a
   Adriana viendo 6 donde había 30.

   Se prueban las dos funciones y su relación entre ellas:
     · baseEstricta = lo que el sistema entiende HOY. Tiene que decir
       exactamente lo mismo que base_nombre() en la base y baseNombre() en
       la lista. Si acá se ampliara, la pantalla diría que un par suma
       cuando en realidad no — mentiría en la dirección peligrosa.
     · baseAmplia = lo que una persona diría. Solo sirve para DETECTAR
       rotos, nunca para dar un par por bueno.

   Lee las funciones DE VERDAD desde index.html, no una copia. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');

const trozo = (desde, hasta) => {
  const i = html.indexOf(desde), j = html.indexOf(hasta, i);
  if (i < 0 || j < 0) { console.error('✗ no encontré ' + desde); process.exit(1); }
  return html.slice(i, j);
};
const fuente =
  trozo('const normNombre =', '\n/* Escapa texto') +
  trozo('const MUEBLES =', '\nasync function ajCargarPares');
const { baseEstricta, baseAmplia, muebleDe } =
  new Function(fuente + '; return {baseEstricta, baseAmplia, muebleDe};')();

let ok = 0, fallos = 0;
const caso = (nombre, dio, esp) => {
  if (String(dio) === String(esp)) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}\n      esperaba "${esp}"\n      dio      "${dio}"`); }
};
/* ¿Estos dos suman de verdad, con la regla que corre en producción? */
const suman = (a, b) => baseEstricta(a) === baseEstricta(b);
/* ¿Una persona diría que son el mismo producto? */
const mismo = (a, b) => baseAmplia(a) === baseAmplia(b);

console.log('\nLos pares que SÍ suman hoy:');
caso('Brownie Vitrina + Brownie Congelador', suman('Brownie Vitrina','Brownie Congelador'), true);
caso('aguanta tildes y mayúsculas', suman('Volcán Vitrina','volcan  CONGELADOR'), true);
caso('el caso nuevo: Brownie alfajor en dos muebles',
     suman('Brownie alfajor Vitrina','Brownie alfajor Congelador'), true);

console.log('\nEl bug de los macarrons, que es lo que esta pantalla destapa:');
caso('“Vitrina de dulces” NO suma con su congelador',
     suman('Macarrons Vitrina de dulces','Macarrons Congelador'), false);
caso('pero una persona sí diría que son el mismo',
     mismo('Macarrons Vitrina de dulces','Macarrons Congelador'), true);
caso('y renombrando queda arreglado',
     suman('Macarrons Vitrina','Macarrons Congelador'), true);

console.log('\nLo que NO puede pasar: juntar cosas distintas');
caso('Brownie y Brownie alfajor son productos distintos',
     mismo('Brownie Vitrina','Brownie alfajor Vitrina'), false);
caso('Torta amor y Torta matilda, distintas',
     mismo('Torta amor Vitrina','Torta matilda Vitrina'), false);
caso('un producto sin apellido no se recorta',
     baseEstricta('Bolsa kraft m'), 'bolsa kraft m');
caso('“Vitrina” a secas no se queda en vacío', baseAmplia('Vitrina'), 'vitrina');
caso('“Congelador de prueba” no es un apellido', baseAmplia('Congelador de prueba'), 'congelador de prueba');

console.log('\nDe qué mueble habla cada nombre:');
caso('Brownie Vitrina', muebleDe('Brownie Vitrina'), 'vitrina');
caso('Mini muffin Congelador', muebleDe('Mini muffin Congelador'), 'congelador');
caso('Macarrons Vitrina de dulces', muebleDe('Macarrons Vitrina de dulces'), 'vitrina');
caso('Pizza Congelados', muebleDe('Pizza Congelados'), 'congelador');
caso('Bolsa kraft m · ninguno', muebleDe('Bolsa kraft m'), null);

console.log('\nLa regla que sostiene todo lo demás:');
caso('baseEstricta NUNCA agrupa más que baseAmplia',
     ['Macarrons Vitrina de dulces','Brownie Vitrina','Torta amor Vitrina de tortas']
       .every(n => baseAmplia(n).length <= baseEstricta(n).length), true);

console.log(`\n${fallos ? '✗' : '✓'} ${ok} bien, ${fallos} mal\n`);
process.exit(fallos ? 1 : 0);
