/* Prueba de la portada y el emparejador de Recetas.
   node pruebas/recetas-portada.mjs

   Lee el código DE VERDAD desde index.html, no una copia: una prueba contra
   una copia no prueba el código que corre. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');

const ini = html.indexOf('const MOTIVOS = {');
const fin = html.indexOf('function abrirTaller');
if (ini < 0 || fin < 0) { console.error('✗ no encontré el bloque de Recetas en index.html'); process.exit(1); }
const codigo = html.slice(ini, fin);

const normNombre = s => (s==null?'':String(s)).toLowerCase().normalize('NFD')
  .replace(/[̀-ͯ]/g,'').replace(/\s+/g,' ').trim();

/* Arma una instancia con el estado que quiera cada escenario. */
function montar({DATA=[], RECETAS=[], NOLLEVA={}, CATS={}, FUDOPROD=[]}={}){
  const stub = () => ({ textContent:'', innerHTML:'', disabled:false, style:{} });
  return new Function(
    'normNombre','DATA','RECETAS','NOLLEVA','CATS','FUDOPROD','$','fmt','esc',
    codigo + '; return {resumenRecetas, candidatos, limpiaFudo, estadoFudo, seccionDe};'
  )(normNombre, DATA, RECETAS, NOLLEVA, CATS, FUDOPROD, stub, n=>n, s=>s);
}

let ok=0, mal=0;
const caso=(nombre, real, esperado)=>{
  const a=JSON.stringify(real), b=JSON.stringify(esperado);
  if(a===b){ ok++; console.log(`  ✓ ${nombre}`); }
  else { mal++; console.log(`  ✗ ${nombre}\n      esperaba ${b}\n      dio      ${a}`); }
};

// ---------------------------------------------------------------- los apellidos
console.log('\nLos apellidos de Fudo se quitan antes de comparar:');
{
  const { limpiaFudo } = montar();
  caso('"Torta amor Pedidos Ya" -> "torta amor"', limpiaFudo('Torta amor Pedidos Ya'), 'torta amor');
  caso('"Sandwich Apaltado Nuevo" -> sin el Nuevo',  limpiaFudo('Sandwich Apaltado Nuevo'), 'sandwich apaltado');
  caso('"Brownie - solo" -> "brownie"',              limpiaFudo('Brownie - solo'), 'brownie');
  caso('quita tildes y mayúsculas',                  limpiaFudo('PIZZA CHAMPIÑÓN'), 'pizza champinon');
  // Y lo que NO debe pasar: comerse una palabra que es parte del nombre.
  caso('NO se come "Vegano" si no está al final',    limpiaFudo('Vegano especial'), 'vegano especial');
}

// ---------------------------------------------------------------- los candidatos
console.log('\nLos candidatos proponen, y el bueno va primero:');
{
  const DATA = [
    {id:1, producto:'Trozo torta amor',      rubro:'Vitrina', stock_actual:3},
    {id:2, producto:'Trozo torta hojarasca', rubro:'Vitrina', stock_actual:1},
    {id:3, producto:'Sandwich Apaltado',     rubro:'Sándwiches', stock_actual:0},
    {id:4, producto:'Pizza Champiñón',       rubro:'Congelador', stock_actual:2},
  ];
  const { candidatos } = montar({DATA});
  const c1 = candidatos({nombre:'Torta amor Pedidos Ya'});
  caso('"Torta amor Pedidos Ya" propone el trozo de amor primero',
       c1[0] && c1[0].p.producto, 'Trozo torta amor');
  const c2 = candidatos({nombre:'Sandwich Apaltado Nuevo'});
  caso('"Sandwich Apaltado Nuevo" calza exacto tras quitar el apellido',
       c2[0] && Math.round(c2[0].pt), 100);
  const c3 = candidatos({nombre:'Pizza Champiñon'});
  caso('encuentra pese a la tilde que falta en Fudo',
       c3[0] && c3[0].p.producto, 'Pizza Champiñón');
  // El caso que costó caro: el candidato "más parecido" no debe inventar.
  const c4 = candidatos({nombre:'Croissant nutella'});
  caso('sin nada parecido, NO propone cualquier cosa', c4.length, 0);
  caso('nunca propone más de 4', candidatos({nombre:'Trozo torta'}).length <= 4, true);
}

// ---------------------------------------------------------------- los 3 estados
console.log('\nLos tres estados, que son lo que hace que el contador llegue a cero:');
{
  const FUDOPROD = [
    {fudo_product_id:'1', nombre:'Waffle',        categoria_id:'12'},
    {fudo_product_id:'2', nombre:'Torta amor',    categoria_id:'12'},
    {fudo_product_id:'3', nombre:'ALCOHOL GEL',   categoria_id:'29'},
    {fudo_product_id:'4', nombre:'APALTADO+CAFE', categoria_id:'18'},
    {fudo_product_id:'5', nombre:'Sin categoría', categoria_id:null},
  ];
  const CATS = {'12':'Vitrina', '29':'Insumos e implementos', '18':'Combos'};
  const RECETAS = [{fudo_product_id:'1', activo:true}];
  const NOLLEVA = {'3':'no se vende', '4':'es combo'};
  const { resumenRecetas, estadoFudo, seccionDe } = montar({FUDOPROD, CATS, RECETAS, NOLLEVA});

  caso('el que tiene receta descuenta',        estadoFudo(FUDOPROD[0]), 'ok');
  caso('el marcado no cuenta como pendiente',  estadoFudo(FUDOPROD[2]), 'no');
  caso('el que no tiene nada, falta',          estadoFudo(FUDOPROD[1]), 'falta');
  caso('sin categoría no se pierde',           seccionDe(FUDOPROD[4]), 'Sin clasificar');

  const r = resumenRecetas();
  caso('cuenta 1 ok · 2 falta · 2 no', [r.ok, r.falta, r.no], [1,2,2]);
  caso('los tres estados suman el total', r.ok+r.falta+r.no, FUDOPROD.length);
  caso('la barra con más pendientes va primero', r.barras[0].sec, 'Vitrina');
  caso('las que no tienen pendientes se hunden',
       r.barras[r.barras.length-1].falta, 0);
}

// ---------------------------------------------------------------- sin las tablas
console.log('\nSi las tablas nuevas todavía no existen, la pantalla NO se rompe:');
{
  const FUDOPROD=[{fudo_product_id:'1', nombre:'Waffle', categoria_id:'12'}];
  const { resumenRecetas } = montar({FUDOPROD});   // sin CATS ni NOLLEVA
  const r = resumenRecetas();
  caso('todo cae en "Sin clasificar"', r.barras[0].sec, 'Sin clasificar');
  caso('y queda como pendiente, no como error', [r.ok,r.falta,r.no], [0,1,0]);
}

// ---------------------------------------------------------------- receta apagada
console.log('\nUna receta desactivada no cuenta como enlazada:');
{
  const FUDOPROD=[{fudo_product_id:'1', nombre:'Waffle', categoria_id:'12'}];
  const RECETAS=[{fudo_product_id:'1', activo:false}];
  const { resumenRecetas } = montar({FUDOPROD, RECETAS, CATS:{'12':'Vitrina'}});
  caso('vuelve a la lista de pendientes', resumenRecetas().falta, 1);
}

console.log(`\n${ok} bien · ${mal} mal\n`);
process.exit(mal ? 1 : 0);
