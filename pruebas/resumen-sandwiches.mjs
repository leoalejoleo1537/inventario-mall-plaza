/* EL RESUMEN DE SÁNDWICHES QUE SE PEGA EN WHATSAPP.
   node pruebas/resumen-sandwiches.mjs

   POR QUÉ EXISTE. Jhon, 2026-08-22: "el resumen generado en el área de
   sándwiches es demasiado complejo para tomar decisiones rápidas en Wapp".
   El formato viejo gastaba DOS renglones por cada fecha, así que nueve
   productos con tres fechas cada uno pasaban de cincuenta líneas — hay que
   hacer scroll para leer una sola cosa.

   Esta es la sección más delicada de la cafetería (§0.3): de acá sale que se
   bote comida buena o se venda comida vencida. Así que la prueba no mira
   solo que el texto "se vea bien": comprueba que NINGUNA unidad con stock
   desaparezca del mensaje, y que lo vencido siga marcado.

   Lee las funciones del index.html de verdad, no una copia (§0.5).        */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz,'index.html'),'utf8');
const saca = (re, que) => { const m = html.match(re);
  if(!m) throw new Error('no se encontró en index.html: '+que); return m[0]; };

const fuente = [
  saca(/const NOMBRES_RESUMEN=[\s\S]*?\n\}/,        'nombreResumen'),
  saca(/const URGE = [\s\S]*?\n\}/,                 'marcaUrgencia'),
  saca(/function resumenSeccionNuevo\(sec\)\{[\s\S]*?\n\}/, 'resumenSeccionNuevo'),
  saca(/function resumenSeccionViejo\(sec\)\{[\s\S]*?\n\}/, 'resumenSeccionViejo'),
  saca(/const fmtDiaMes = [^\n]*/,                  'fmtDiaMes'),
  saca(/const fmtCorta   = [^\n]*/,                 'fmtCorta'),
].join('\n');

const HOY = '2026-08-24';
const DATA = [
  {id:1, rubro:'Sándwiches', producto:'Croissant JQ',          stock_actual:12},
  {id:2, rubro:'Sándwiches', producto:'Pan masa madre blanco', stock_actual:38},
  {id:3, rubro:'Sándwiches', producto:'Sandwich Apaltado',     stock_actual:10},
  {id:4, rubro:'Sándwiches', producto:'Sandwich Mechada',      stock_actual:4},
  {id:5, rubro:'Sándwiches', producto:'Sandwich Vencido',      stock_actual:2},
  {id:6, rubro:'Sándwiches', producto:'Se acabó',              stock_actual:0},
  {id:7, rubro:'Vitrina',    producto:'Torta de otra sección', stock_actual:9},
];
const LOTES = {
  /* A propósito DESORDENADOS: en la base las fechas salen en el orden en que
     se cargaron, y el mensaje tiene que mostrarlas de la más próxima a la
     más lejana. Si esta prueba los diera ya ordenados, no probaría nada. */
  1:[{cantidad:7,vencimiento:'2026-08-26'},{cantidad:1,vencimiento:'2026-08-24'},{cantidad:4,vencimiento:'2026-08-25'}],
  3:[{cantidad:5,vencimiento:'2026-08-24'},{cantidad:5,vencimiento:'2026-08-26'}],
  4:[{cantidad:4,vencimiento:'2026-08-26'}],
  5:[{cantidad:2,vencimiento:'2026-08-22'}],
};
const ctx = {
  DATA, hasVenc:true,
  lotesDe: id => LOTES[id] || [],
  hoyISO: () => HOY,
  fmt: n => { const x=+n||0; return Number.isInteger(x)?String(x):String(x).replace('.',','); },
  normNombre: t => String(t||'').toLowerCase().normalize('NFD')
    .replace(/[̀-ͯ]/g,'').replace(/\s+/g,' ').trim(),
};
const mk = nombre => new Function(...Object.keys(ctx), fuente + `\nreturn ${nombre};`)(...Object.values(ctx));
const nuevo = mk('resumenSeccionNuevo')('Sándwiches');
const viejo = mk('resumenSeccionViejo')('Sándwiches');

let ok=0, mal=0;
const caso = (n, fn) => {
  try { const r = fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message); }
};

console.log('\nEl formato nuevo, tal como lo pidió Jhon:');
caso('lleva la cabecera con la fecha de hoy', () =>
  nuevo.startsWith('**Stock / Vencimientos 24/08**') || 'empieza: '+nuevo.slice(0,40));
caso('un renglón por producto, con viñeta', () =>
  nuevo.includes('\n- Croissant JQ: ') || 'no encontré la línea del croissant');
caso('las fechas van en fila, separadas por ·', () =>
  nuevo.includes('**1** (24/08 ⚠️) · **4** (25/08) · **7** (26/08)')
  || 'la línea salió: ' + (nuevo.split('\n').find(l=>l.includes('Croissant'))||''));
caso('de la fecha más próxima a la más lejana', () => {
  const l = nuevo.split('\n').find(l=>l.includes('Croissant'));
  return (l.indexOf('24/08') < l.indexOf('25/08') && l.indexOf('25/08') < l.indexOf('26/08'))
    || 'salieron desordenadas: '+l;
});
caso('lo que no tiene fecha va como (S/F)', () =>
  nuevo.includes('- Pan masa madre blanco: **38** (S/F)') || 'no salió el S/F');
caso('sin año: en un mensaje de hoy el año es ruido', () =>
  !/\d{2}\/\d{2}\/\d{2}/.test(nuevo) || 'quedó una fecha con año');

console.log('\nLo que NO puede perderse (§0.3):');
caso('lo que vence HOY va marcado', () => {
  const l = nuevo.split('\n').find(l=>l.includes('Apaltado'));
  return l.includes('(24/08 ⚠️)') || 'no marcó lo de hoy: '+l;
});
caso('lo YA VENCIDO va marcado', () => {
  const l = nuevo.split('\n').find(l=>l.includes('Vencido'));
  return l.includes('⚠️') || 'no marcó lo vencido: '+l;
});
caso('lo que vence más adelante NO se marca (si todo grita, nada grita)', () => {
  const l = nuevo.split('\n').find(l=>l.includes('Croissant'));
  return !l.includes('26/08 ⚠️') || 'marcó como urgente algo de pasado mañana';
});
caso('ninguna unidad con stock se pierde en el camino', () => {
  /* El total del mensaje tiene que ser el total del inventario de esa
     sección. Es la comprobación que importa: un formato más corto no puede
     lograrlo escondiendo unidades. */
  const enMensaje = [...nuevo.matchAll(/\*\*(\d+(?:,\d+)?)\*\*/g)]
    .reduce((n,m)=>n+parseFloat(m[1].replace(',','.')),0);
  const enInventario = DATA.filter(p=>p.rubro==='Sándwiches')
    .reduce((n,p)=>n+(+p.stock_actual||0),0);
  return enMensaje === enInventario
    || 'el mensaje suma '+enMensaje+' y el inventario '+enInventario;
});
caso('un producto en 0 no ocupa espacio', () =>
  !nuevo.includes('Se acabó') || 'metió un producto sin stock');
caso('no se cuela otra sección', () =>
  !nuevo.includes('otra sección') || 'trajo productos de otra sección');
caso('"Mechada" se copia como "Plateada", como siempre', () =>
  (nuevo.includes('Plateada') && !nuevo.includes('Mechada')) || 'no renombró');

console.log('\nApagar el interruptor devuelve EXACTAMENTE lo de antes (§2.2):');
caso('vuelve el formato de dos renglones por fecha', () =>
  viejo.includes('Croissant JQ 1') && viejo.includes('Fv. 24/08/26')
  || 'el formato viejo cambió: ' + viejo.split('\n').slice(0,2).join(' / '));
caso('y no queda un hueco: sigue trayendo todo', () => {
  /* 7 lotes con fecha + 1 "Fv. sin fecha" del pan, que el formato viejo
     también lista. Son 8 renglones de fecha, uno por unidad de información
     del mensaje nuevo. */
  const n = viejo.split('\n').filter(l=>l.startsWith('Fv.')).length;
  return n === 8 || 'trae '+n+' renglones de fecha, esperaba 8';
});
caso('los dos formatos cuentan las MISMAS unidades', () => {
  /* El formato viejo pega la marca ⚠️ DESPUÉS del número ("Croasan 1 ⚠️"),
     así que la cuenta tiene que aceptarla o se pierden justo las líneas
     urgentes — que son las que más importa no perder. */
  const suma = t => [...t.matchAll(/\*\*(\d+(?:,\d+)?)\*\*|\s(\d+(?:,\d+)?)(?:\s⚠️)?$/gm)]
    .reduce((n,m)=>n+parseFloat((m[1]||m[2]).replace(',','.')),0);
  const a = suma(nuevo), b = suma(viejo);
  return a === b || 'el nuevo suma '+a+' y el viejo '+b+': el formato corto perdió unidades';
});

console.log('\nEl interruptor existe en Ajustes:');
caso('está en la lista de interruptores', () =>
  html.includes("clave:'resumen_nuevo'") || 'no se puede apagar desde Ajustes');
caso('es por sede: cada local manda su propio mensaje', () =>
  /clave:'resumen_nuevo',\s*porSede:\['plaza','angamos'\]/.test(html) || 'no es por sede');
caso('y un solo sitio decide cuál se usa', () =>
  /function resumenSeccion\(sec\)\{[\s\S]{0,200}ajVal\('resumen_nuevo'/.test(html)
  || 'hay más de un dueño de esa decisión');

console.log('\n--- así se ve el mensaje ---\n');
console.log(nuevo);
console.log(`\n${ok} bien · ${mal} mal\n`);
process.exit(mal ? 1 : 0);
