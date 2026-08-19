/* Prueba de la tarjeta de una meta.
   node pruebas/metas-en-pantalla.mjs

   LO QUE CUIDA, y es lo único que de verdad importa acá: la MISMA tarjeta se
   pinta en dos sitios muy distintos —el inventario, que ve todo el equipo, y
   Ajustes, que ve solo quien tiene permiso—. Los botones de cerrar y eliminar
   existen únicamente en el segundo. Si algún día alguien los pinta siempre
   "porque es la misma función", un barista se encuentra con un botón de
   eliminar al lado del stock.

   Lee la función DE VERDAD desde index.html, no una copia.                  */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');
const ini = html.indexOf('const metaVigente =');
const fin = html.indexOf('/* La meta vigente se ve en el INVENTARIO');
if (ini < 0 || fin < 0) { console.error('✗ no encontré metaBarraHTML en index.html'); process.exit(1); }

const entorno = `
  const SEDES = {plaza:{label:'Café Mall Plaza'}, angamos:{label:'Parque Angamos'}};
  const META_AVANCE = ${JSON.stringify({ 1:{plaza:31,angamos:1}, 2:{plaza:100,angamos:4} })};
  const esc = t => String(t).replace(/&/g,'&amp;').replace(/</g,'&lt;');
  const fmt = n => String(n);
  const fmtFecha = f => f;
  const hoyISO = () => '2026-08-19';
`;
const { metaBarraHTML, metaVigente } =
  new Function(entorno + html.slice(ini, fin) + '; return {metaBarraHTML, metaVigente};')();

let ok = 0, fallos = 0;
const caso = (nombre, cond) => {
  if (cond) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}`); }
};

const viva   = {id:1, titulo:'Agua boscua', objetivo:100, premio:'spa',
                desde:'2026-08-01', hasta:'2026-08-31', cerrada_at:null};
const cerrada = {...viva, id:1, cerrada_at:'2026-08-15T10:00:00Z'};
const ganada  = {...viva, id:2};

console.log('\nEn el inventario la tarjeta no ofrece ninguna acción:');
const enPortada = metaBarraHTML(viva);
caso('sin botón de eliminar', !enPortada.includes('data-metaborrar'));
caso('sin botón de cerrar',   !enPortada.includes('data-metacerrar'));
caso('pero sí muestra el avance', enPortada.includes('31') && enPortada.includes('meta 100'));

console.log('\nEn Ajustes sí, y cerrar va antes que eliminar:');
const enAjustes = metaBarraHTML(viva, true);
caso('se puede cerrar',  enAjustes.includes('data-metacerrar="1"'));
caso('se puede eliminar', enAjustes.includes('data-metaborrar="1"'));
caso('el reversible va primero',
  enAjustes.indexOf('data-metacerrar') < enAjustes.indexOf('data-metaborrar'));
caso('eliminar lleva el nombre, para poder decirlo en el aviso',
  enAjustes.includes('data-nom="Agua boscua"'));

console.log('\nUna meta cerrada ofrece REABRIR, no cerrar otra vez:');
const cer = metaBarraHTML(cerrada, true);
caso('el botón dice Reabrir', cer.includes('>Reabrir<'));
caso('y lo dice también en la fecha', cer.includes('cerrada'));
caso('cerrar es reversible: el botón manda abrir=1', cer.includes('data-abrir="1"'));
caso('en una viva, en cambio, manda abrir=0', enAjustes.includes('data-abrir="0"'));

console.log('\nY la cerrada se va del inventario, que es para lo que sirve cerrar:');
caso('una viva se muestra',   metaVigente(viva) === true);
caso('una cerrada NO',        metaVigente(cerrada) === false);
caso('una que ya pasó NO',    metaVigente({...viva, hasta:'2026-08-10'}) === false);
caso('una que no empezó NO',  metaVigente({...viva, desde:'2026-09-01'}) === false);

console.log('\nEl número se tiene que poder leer:');
/* Iba en gris sobre el gris de la pista, y encima se pintaba BLANCO desde el
   18% "porque la barra lo tapa" — pero la barra crece hacia el número desde
   el otro extremo, así que al 18% no lo tapaba nada: quedaba blanco sobre
   gris claro. Jhon: "son casi del mismo color que el fondo". */
caso('con la barra corta, el número NO se pinta blanco',
  !metaBarraHTML(viva).includes('val on'));
caso('con la barra casi llena, sí (ahí sí lo tapa)',
  metaBarraHTML({...viva, id:2}).includes('val on'));

console.log('\nLlegar a la meta se celebra:');
caso('avisa quién llegó', metaBarraHTML(ganada, true).includes('llegó a la meta'));

console.log(`\n${fallos ? '✗' : '✓'} ${ok} bien, ${fallos} mal\n`);
process.exit(fallos ? 1 : 0);
