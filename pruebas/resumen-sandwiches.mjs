/* EL RESUMEN DE SÁNDWICHES QUE SE PEGA EN WHATSAPP.
   node pruebas/resumen-sandwiches.mjs

   POR QUÉ EXISTE. El texto se copia para leerlo en WhatsApp durante el turno.
   Cada lote debe quedar junto a su cantidad y su estado, aun cuando un mismo
   producto tenga fechas vencidas, de hoy y futuras.

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
  {id:8, rubro:'Sándwiches', producto:'Con fecha antigua',     stock_actual:3, vencimiento:'2026-08-27'},
];
const LOTES = {
  /* A propósito DESORDENADOS: en la base las fechas salen en el orden en que
     se cargaron, y el mensaje tiene que mostrarlas de la más próxima a la
     más lejana. Si esta prueba los diera ya ordenados, no probaría nada. */
  1:[{cantidad:7,vencimiento:'2026-08-26'},{cantidad:1,vencimiento:'2026-08-24'},{cantidad:4,vencimiento:'2026-08-25'}],
  3:[{cantidad:5,vencimiento:'2026-08-26'},{cantidad:2,vencimiento:'2026-08-23'},{cantidad:3,vencimiento:'2026-08-24'}],
  4:[{cantidad:4,vencimiento:'2026-08-26'}],
  5:[{cantidad:2,vencimiento:'2026-08-22'}],
};
const ctx = {
  DATA, hasVenc:true,
  lotesDe: id => LOTES[id] || [],
  tieneStock: p => Number(p&&p.stock_actual) > 0,
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

console.log('\nEl formato aprobado para WhatsApp:');
caso('lleva la cabecera con la fecha de hoy', () =>
  nuevo.startsWith('PANES Y SÁNDWICHES · 24 AGO\n\n') || 'empieza: '+nuevo.slice(0,40));
caso('un bloque por producto, separado del siguiente', () =>
  nuevo.includes('Croissant JQ · Stock 12\n🟡 1 u. vence hoy\n🟢 4 u. vencen · 25 ago\n🟢 7 u. vencen · 26 ago\n\n')
  || 'no encontré el bloque completo del croissant');
caso('de la fecha más próxima a la más lejana', () => {
  const bloque = nuevo.split('\n\n').find(l=>l.includes('Croissant'));
  return (bloque.indexOf('hoy') < bloque.indexOf('25 ago') && bloque.indexOf('25 ago') < bloque.indexOf('26 ago'))
    || 'salieron desordenadas: '+bloque;
});
caso('stock sin fecha no se pinta de verde', () =>
  nuevo.includes('Pan masa madre blanco · Stock 38\nSin fecha: 38 u.') || 'no salió sin fecha');
caso('sin asteriscos, paréntesis ni fechas que WhatsApp subraye', () =>
  !/[*(]/.test(nuevo) && !/\d{2}\/\d{2}/.test(nuevo) || 'quedó formato ambiguo');

console.log('\nLo que NO puede perderse (§0.3):');
caso('lo que vence HOY va marcado', () => {
  const bloque = nuevo.split('\n\n').find(l=>l.includes('Apaltado'));
  return bloque.includes('🟡 3 u. vencen hoy') || 'no marcó lo de hoy: '+bloque;
});
caso('un producto puede tener los tres estados a la vez', () => {
  const bloque = nuevo.split('\n\n').find(l=>l.includes('Apaltado'));
  return bloque.includes('🔴 2 u. vencidas · 23 ago\n🟡 3 u. vencen hoy\n🟢 5 u. vencen · 26 ago')
    || 'los estados no corresponden a cada fecha: '+bloque;
});
caso('lo YA VENCIDO va marcado', () => {
  const bloque = nuevo.split('\n\n').find(l=>l.includes('Vencido'));
  return bloque.includes('🔴 2 u. vencidas · 22 ago') || 'no marcó lo vencido: '+bloque;
});
caso('cada fecha futura lleva su propio círculo verde', () => {
  const bloque = nuevo.split('\n\n').find(l=>l.includes('Croissant'));
  return bloque.includes('🟢 4 u. vencen · 25 ago\n🟢 7 u. vencen · 26 ago')
    || 'falta un lote futuro: '+bloque;
});
caso('también funciona el vencimiento único antiguo', () => {
  const bloque = nuevo.split('\n\n').find(l=>l.includes('Con fecha antigua'));
  return bloque.includes('🟢 3 u. vencen · 27 ago') || 'no salió el vencimiento: '+bloque;
});
caso('ninguna unidad con stock se pierde en el camino', () => {
  /* Los renglones de stock deben coincidir con el inventario; las fechas
     desglosan ese mismo número y no se suman dos veces. */
  const enMensaje = [...nuevo.matchAll(/ · Stock (\d+(?:,\d+)?)/g)]
    .reduce((n,m)=>n+parseFloat(m[1].replace(',','.')),0);
  const enInventario = DATA.filter(p=>p.rubro==='Sándwiches')
    .reduce((n,p)=>n+(+p.stock_actual||0),0);
  return enMensaje === enInventario
    || 'el mensaje suma '+enMensaje+' y el inventario '+enInventario;
});
caso('un producto en 0 no ocupa espacio', () =>
  !nuevo.includes('Se acabó') || 'metió un producto sin stock');
caso('una fecha residual no revive un producto con stock 0', () => {
  LOTES[6] = [{cantidad:1,vencimiento:'2026-08-24'}];
  const conResidual = mk('resumenSeccionNuevo')('Sándwiches');
  const conResidualViejo = mk('resumenSeccionViejo')('Sándwiches');
  delete LOTES[6];
  return (!conResidual.includes('Se acabó') && !conResidualViejo.includes('Se acabó'))
    || 'algún formato copió una fecha sin stock';
});
caso('no se cuela otra sección', () =>
  !nuevo.includes('otra sección') || 'trajo productos de otra sección');
caso('"Mechada" se copia como "Plateada", como siempre', () =>
  (nuevo.includes('Plateada') && !nuevo.includes('Mechada')) || 'no renombró');

console.log('\nApagar el interruptor devuelve EXACTAMENTE lo de antes (§2.2):');
caso('vuelve el formato de dos renglones por fecha', () =>
  viejo.includes('Croissant JQ 1') && viejo.includes('Fv. 24/08/26')
  || 'el formato viejo cambió: ' + viejo.split('\n').slice(0,2).join(' / '));
caso('y no queda un hueco: sigue trayendo todo', () => {
  /* 8 lotes con fecha + 1 fecha antigua + 1 "Fv. sin fecha" del pan. */
  const n = viejo.split('\n').filter(l=>l.startsWith('Fv.')).length;
  return n === 10 || 'trae '+n+' renglones de fecha, esperaba 10';
});
caso('los dos formatos cuentan las MISMAS unidades', () => {
  const a = [...nuevo.matchAll(/ · Stock (\d+(?:,\d+)?)/g)]
    .reduce((n,m)=>n+parseFloat(m[1].replace(',','.')),0);
  const b = [...viejo.matchAll(/^.+ (\d+(?:,\d+)?)(?:\s⚠️)?$/gm)]
    .reduce((n,m)=>n+parseFloat(m[1].replace(',','.')),0);
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
