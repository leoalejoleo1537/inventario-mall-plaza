/* Prueba de motivoDeFuncion() — que el aviso diga POR QUÉ falló.
   node pruebas/motivo-de-funcion.mjs

   EL CASO QUE LA MOTIVA (2026-08-17): Jhon intentó crear una pizza y la
   pantalla dijo "Edge Function returned a non-2xx status code". Ese es el
   mensaje genérico de la librería: dice que el servidor contestó un
   código de fallo, y nada más. El motivo real —"Falta el precio", "Esta
   cuenta no puede crear productos en Fudo"— viajaba dentro de la
   respuesta y nadie lo abría.

   Lee la función DE VERDAD desde index.html, no una copia. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');
const ini = html.indexOf('async function motivoDeFuncion');
const fin = html.indexOf('/* reintenta una operación de Supabase');
if (ini < 0 || fin < 0) { console.error('✗ no encontré motivoDeFuncion en index.html'); process.exit(1); }
const { motivoDeFuncion } = new Function(html.slice(ini, fin) + '; return {motivoDeFuncion};')();

let ok = 0, fallos = 0;
const caso = async (nombre, r, esperado) => {
  const dio = await motivoDeFuncion(r);
  const bien = esperado === null ? dio === null : String(dio).includes(esperado);
  if (bien) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}\n      esperaba que dijera "${esperado}"\n      dijo "${dio}"`); }
};

/* Una respuesta como la que entrega la librería cuando el código no es 2xx */
const respuesta = (status, cuerpo) => ({
  message: 'Edge Function returned a non-2xx status code',
  context: {
    status,
    clone(){ return this; },
    async text(){ return typeof cuerpo === 'string' ? cuerpo : JSON.stringify(cuerpo); },
  },
});

console.log('\nEl motivo de verdad sale a la pantalla:');
await caso('falta el precio (400)',
  { error: respuesta(400, { error: 'Falta el precio. Un producto en 0 se vendería gratis.' }) },
  'Falta el precio');
await caso('la cuenta no tiene permiso (403)',
  { error: respuesta(403, { error: 'Esta cuenta no puede crear productos en Fudo.' }) },
  'no puede crear productos');
await caso('la sesión caducó (401)',
  { error: respuesta(401, { error: 'Tu sesión caducó. Sal y vuelve a entrar.' }) },
  'Sal y vuelve a entrar');
await caso('Fudo rechazó, y se ve el detalle',
  { error: respuesta(502, { error: 'Fudo no aceptó crear el producto (422).', detalle: 'name is invalid' }) },
  'name is invalid');
await caso('el código va al final, para poder decírmelo',
  { error: respuesta(403, { error: 'x' }) }, 'código 403');

console.log('\nY cuando no hay nada que traducir, no se inventa:');
await caso('sin error: devuelve null', { data: { ok: true } }, null);
await caso('error en el cuerpo con respuesta 200',
  { data: { error: 'ese producto no es el único insumo de ninguna receta' } },
  'único insumo');

console.log('\nLos casos raros no pueden dejar la pantalla muda:');
await caso('el cuerpo no es JSON', { error: respuesta(500, 'Internal Server Error') },
  'Internal Server Error');
await caso('cuerpo vacío: al menos el código', { error: respuesta(504, '') }, '504');
await caso('sin context: queda el mensaje de la librería',
  { error: { message: 'Failed to send a request to the Edge Function' } },
  'Failed to send');
await caso('leer el cuerpo revienta: no se propaga el fallo',
  { error: { message: 'algo', context: { status: 500, clone(){ return this; },
      async text(){ throw new Error('ya se leyó'); } } } },
  'algo');

console.log(`\n${fallos ? '✗' : '✓'} ${ok} bien, ${fallos} mal\n`);
process.exit(fallos ? 1 : 0);
