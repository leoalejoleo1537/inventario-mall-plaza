/* Prueba de permisosDeLaSede() — que el Modo edición del personal de Angamos
   NO se encienda en Mall Plaza.
   node pruebas/permiso-por-sede.mjs

   Lee la función DE VERDAD desde index.html, no una copia: una prueba contra
   una copia no prueba el código que corre (regla del bloque A). */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');
const ini = html.indexOf('function permisosDeLaSede');
const fin = html.indexOf('let PERMISOS =');
if (ini < 0 || fin < 0) { console.error('✗ no encontré permisosDeLaSede en index.html'); process.exit(1); }
const { permisosDeLaSede } =
  new Function(html.slice(ini, fin) + '; return {permisosDeLaSede};')();

let ok = 0, fallos = 0;
const caso = (nombre, fila, sede, esperado) => {
  const r = permisosDeLaSede(fila, sede);
  const dio = `${r.puede_editar?'edita':'—'}/${r.puede_fudo?'fudo':'—'}`;
  const esp = `${esperado.editar?'edita':'—'}/${esperado.fudo?'fudo':'—'}`;
  if (dio === esp) { ok++; console.log(`  ✓ ${nombre}`); }
  else { fallos++; console.log(`  ✗ ${nombre}\n      esperaba ${esp}, dio ${dio}`); }
};

/* Las 5 cuentas que ya existían: sin sede = todas. Agregar la columna no le
   puede cambiar nada a nadie — si esto falla, la migración rompe a Adriana. */
console.log('\nLas cuentas de siempre (sede vacía) siguen igual en las dos sedes:');
const jhon = { correo:'jhon', puede_fudo:true, puede_editar:true, sede:null };
caso('Jhon en plaza',   jhon, 'plaza',   {editar:true, fudo:true});
caso('Jhon en angamos', jhon, 'angamos', {editar:true, fudo:true});
caso('columna que todavía no existe en la base (sede undefined)',
     { puede_fudo:true, puede_editar:true }, 'plaza', {editar:true, fudo:true});

console.log('\nLa cuenta de Angamos edita SOLO en Angamos:');
const ang = { correo:'angamos', puede_fudo:false, puede_editar:true, sede:'angamos' };
caso('en su sede: puede editar',        ang, 'angamos', {editar:true,  fudo:false});
caso('en Mall Plaza: NO puede editar',  ang, 'plaza',   {editar:false, fudo:false});
caso('en bodega: tampoco',              ang, 'bodega',  {editar:false, fudo:false});

console.log('\nEl otro candado, el de escribir en Fudo, se acota igual:');
const soloPlaza = { correo:'x', puede_fudo:true, puede_editar:true, sede:'plaza' };
caso('acotada a plaza, mirando plaza',   soloPlaza, 'plaza',   {editar:true,  fudo:true});
caso('acotada a plaza, mirando angamos', soloPlaza, 'angamos', {editar:false, fudo:false});

console.log('\nCasos borde:');
caso('sin fila en app_permisos (no está autorizada)', null, 'angamos', {editar:false, fudo:false});
caso('fila con los dos permisos apagados',
     { puede_fudo:false, puede_editar:false, sede:'angamos' }, 'angamos', {editar:false, fudo:false});
caso('sin sede elegida todavía, permiso acotado', ang, null, {editar:false, fudo:false});

/* El permiso nuevo de Ajustes: un solo nivel para toda la zona de
   administración (Jhon, 2026-08-17). Se prueba aparte porque tiene que
   respetar la sede igual que los otros dos, y porque su default seguro es
   NO: mientras la columna no exista en la base, nadie ve la tuerca. */
console.log('\nEl permiso de entrar a Ajustes:');
const ajCaso = (nombre, fila, sede, esperado) => {
  const dio = !!permisosDeLaSede(fila, sede).puede_ajustes;
  if (dio === esperado) { ok++; console.log(`  \u2713 ${nombre}`); }
  else { fallos++; console.log(`  \u2717 ${nombre}\n      esperaba ${esperado}, dio ${dio}`); }
};
ajCaso('la columna todavía no existe en la base: NO entra',
       { puede_fudo:true, puede_editar:true }, 'plaza', false);
ajCaso('encendido y sin sede: entra en todas',
       { puede_ajustes:true }, 'angamos', true);
ajCaso('acotado a plaza: entra en plaza',
       { puede_ajustes:true, sede:'plaza' }, 'plaza', true);
ajCaso('acotado a plaza: NO entra en angamos',
       { puede_ajustes:true, sede:'plaza' }, 'angamos', false);
ajCaso('sin fila (sin sesión): NO entra', null, 'plaza', false);
ajCaso('poder empujar a Fudo NO abre Ajustes',
       { puede_fudo:true, puede_editar:true, puede_ajustes:false }, 'plaza', false);

console.log(`\n${ok} bien · ${fallos} mal\n`);
process.exit(fallos ? 1 : 0);
