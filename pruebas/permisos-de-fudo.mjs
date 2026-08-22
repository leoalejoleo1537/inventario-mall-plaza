/* LOS PERMISOS DE ACTUALIZACIÓN A FUDO.  node pruebas/permisos-de-fudo.mjs
   ---------------------------------------------------------------------------
   POR QUÉ EXISTE. El 2026-08-21 el reparto dejó de subir a Fudo. No fue un
   error de código: fue que las cuentas NACÍAN sin el permiso y había que
   acordarse de dárselo. El resultado era el peor posible — inventario bien,
   Fudo mal, y nadie enterado.

   El sistema nuevo guarda **lo que NO se puede** en vez de lo que sí. Por
   eso la mitad de esta prueba se dedica a una sola idea: que TODO lo que
   pueda salir mal —cuenta nueva, fila que falta, columna que no existe,
   lectura que no llegó, ninguna sesión— signifique "puede todo".

   Eso es lo que hace que el incidente no se pueda repetir, y por eso se
   comprueba caso por caso en vez de confiar en un valor por defecto.      */
import { readFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(raiz,'index.html'),'utf8');

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

/* ---------- 1 · la función, leída del archivo de verdad ---------- */
console.log('\nNace abierto · todo lo que puede fallar significa "puede todo":');
const fuente = html.match(/function puedeEnFudo\(clave\)\{[\s\S]*?\n\}/);
if(!fuente){ console.log('  ✗ no se encontró puedeEnFudo en index.html'); process.exit(1); }
const puedeEnFudo = new Function('PERMISOS', 'clave',
  fuente[0].replace(/^function puedeEnFudo\(clave\)\{/, '').replace(/\}$/, ''));

const P = (b) => ({correo:'x@y.cl', fudo_bloqueos:b});
await caso('una cuenta sin ningún bloqueo puede', () => puedeEnFudo(P([]), 'boton') === true || 'dijo que no');
await caso('la columna que todavía no existe (undefined) → puede', () =>
  puedeEnFudo(P(undefined), 'reparto') === true || 'un despliegue a medias dejaría a Fudo atrás');
await caso('la fila que no está (null) → puede', () =>
  puedeEnFudo(P(null), 'reparto') === true || 'dijo que no');
await caso('sin sesión → puede', () =>
  puedeEnFudo({correo:null, fudo_bloqueos:[]}, 'reparto') === true || 'dijo que no');
await caso('PERMISOS entero sin llegar → puede', () =>
  puedeEnFudo(null, 'merma') === true || 'una lectura que falla no puede quitar permisos');
await caso('un valor raro en la base (texto) → puede', () =>
  puedeEnFudo(P('boton'), 'boton') === true || 'un dato malo no puede cerrar un camino');
console.log('\nY se apaga solo lo que está apagado:');
await caso('lo bloqueado NO puede', () => puedeEnFudo(P(['boton']), 'boton') === false || 'no lo bloqueó');
await caso('lo demás sigue pudiendo', () => puedeEnFudo(P(['boton']), 'reparto') === true || 'bloqueó de más');

/* ---------- 2 · el catálogo cubre todos los caminos ---------- */
console.log('\nEl catálogo nombra TODOS los caminos que escriben en Fudo:');
const claves = [...html.matchAll(/clave:'([a-z_]+)'/g)].map(m=>m[1]);
for(const c of ['boton','ficha','todo','reparto','merma','crear','apagar','deshacer'])
  await caso(`está "${c}"`, () => claves.includes(c) || 'falta en FUDO_ACCIONES');
await caso('cada acción dice qué pasa si se apaga', () => {
  const n = (html.match(/apagado:'/g)||[]).length;
  return n >= 8 || 'solo '+n+' de 8 lo dicen';
});

/* ---------- 3 · los caminos están de verdad enganchados ---------- */
console.log('\nCada camino consulta su llave (no es un catálogo decorativo):');
for(const [c, donde] of [['boton','el paso fudo del ⟳'], ['ficha','la ficha del producto'],
                         ['reparto','sumarAFudo'], ['merma','bajarEnFudo'],
                         ['todo','adm-empujar'], ['deshacer','adm-deshacer'],
                         ['crear','crear en Fudo'], ['apagar','activar producto']])
  await caso(`${c} · ${donde}`, () =>
    html.includes(`puedeEnFudo('${c}')`) || `nadie pregunta por "${c}": el interruptor no haría nada`);

/* ---------- 4 · el reloj automático nunca pregunta ---------- */
console.log('\nEl reloj automático no pasa por acá (punto 2 de la doctrina):');
const ciclo = readFileSync(join(raiz,'supabase/functions/fudo-ciclo/index.ts'),'utf8');
await caso('el ciclo usa el token del sistema, no una cuenta', () =>
  ciclo.includes('SISTEMA_TOKEN') || 'el ciclo depende de una cuenta: un permiso lo puede detener de noche');
await caso('y no consulta fudo_bloqueos', () =>
  !ciclo.includes('fudo_bloqueos') || 'el reloj quedó sujeto a los permisos de alguien');

/* ---------- 5 · la pantalla ---------- */
const browser = await abrirNavegador();
if (!browser) { console.log(`\n${ok} bien · ${mal} mal  (la parte de pantalla se salta: no hay navegador)\n`);
                process.exit(mal ? 1 : 0); }
const page = await browser.newPage();
await page.addInitScript(() => {
  window.__escrito = [];
  const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
  const PERS = [
    {correo:'jhon@cafe.cl',  nombre:'Jhon',  puede_ajustes:true,  puede_editar:true, puede_fudo:true, fudo_bloqueos:[]},
    {correo:'leidy@cafe.cl', nombre:'Leidy', puede_ajustes:false, puede_editar:true, puede_fudo:false, fudo_bloqueos:['boton','ficha']},
  ];
  const T = {productos:[{id:1,sede:'plaza',producto:'Brownie',rubro:'Vitrina de dulces',stock_actual:3,stock_min:1,stock_max:9,activo:'SÍ',tipo:'Bollería'}],
             app_permisos:PERS, fudo_sync:[{sede:'plaza',modo:'real',cron_activo:true}],
             secciones:[], movimientos:[], ajustes:[], metas:[], historial:[], restauraciones:[],
             fusiones:[], fudo_stock_push:[], recetas:[], receta_items:[], fudo_productos:[],
             producto_lotes:[], repartos:[], reparto_items:[], mermas:[], producto_enlace:[],
             tareas:[], fudo_categorias:[]};
  const q = (n) => {
    let filas = JSON.parse(JSON.stringify(T[n]||[]));
    const api = {
      select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
      in(){return api;}, neq(){return api;}, order(){return api;}, limit(){return api;},
      gte(){return api;}, lte(){return api;}, is(){return api;}, not(){return api;},
      or(){return api;}, ilike(){return api;},
      maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},
      single(){return Promise.resolve({data:filas[0]||null,error:null});},
      insert(){const e={select:()=>e,single:()=>Promise.resolve({data:null,error:null}),then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      update(v){ window.__escrito.push({tabla:n, valor:v});
        const e={eq:()=>e, select:()=>e, then:f=>Promise.resolve({data:[{...v}],error:null}).then(f)}; return e; },
      upsert(){const e={select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      delete(){return api;},
      then(f){return Promise.resolve({data:filas,error:null,count:filas.length}).then(f);},
    };
    return api;
  };
  window.supabase = { createClient: () => ({
    from:q, rpc:()=>Promise.resolve({data:[],error:null}),
    auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
           onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
           signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
    channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
    removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
  })};
});
await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
const errores = [];
page.on('pageerror', e=>errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(350);
await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(400);

console.log('\nAjustes → Fudo → Permisos de actualización:');
await page.click('#btnMenu'); await page.waitForTimeout(200);
await page.click('[data-accion="ajustes"]'); await page.waitForTimeout(400);
await page.click('#aj-rail [data-aj="fudo"]'); await page.waitForTimeout(700);

await caso('aparece el bloque', async () =>
  (await page.textContent('#aj-pane')).includes('Permisos de actualización a Fudo') || 'no está');
await caso('lista a las dos personas', async () => {
  const t = await page.textContent('#aj-pane');
  return (t.includes('Jhon') && t.includes('Leidy')) || 'falta alguien';
});
await caso('a quien puede todo se le ve 8/8', async () => {
  const t = await page.textContent('[data-fperm="jhon@cafe.cl"]');
  return t.includes('8/8') || 'dice: '+t.trim().slice(0,60);
});
await caso('y a quien tiene dos apagadas, 6/8', async () => {
  const t = await page.textContent('[data-fperm="leidy@cafe.cl"]');
  return t.includes('6/8') || 'dice: '+t.trim().slice(0,60);
});

console.log('\nAl tocar una persona se abre su ventana:');
await page.click('[data-fperm="leidy@cafe.cl"]'); await page.waitForTimeout(350);
await caso('se abre', async () => await page.isVisible('#overlay-fperm') || 'no se abrió');
await caso('trae los 8 interruptores', async () =>
  (await page.$$('[data-fpsw]')).length === 8 || 'trae '+(await page.$$('[data-fpsw]')).length);
await caso('los apagados se ven apagados', async () => {
  const c = await page.getAttribute('[data-fpsw="boton"]','class');
  return !c.includes('on') || 'el botón ⟳ figura encendido y está bloqueado';
});
await caso('y los demás encendidos', async () => {
  const c = await page.getAttribute('[data-fpsw="reparto"]','class');
  return c.includes('on') || 'el reparto figura apagado sin estarlo';
});
/* La línea de abajo cuenta el estado ACTUAL, no el hipotético: encendido
   dice qué hace, apagado dice qué se está perdiendo. La consecuencia de
   apagarlo se dice en el aviso de confirmación, que se prueba más abajo. */
await caso('el encendido explica qué hace', async () =>
  (await page.textContent('#fperm-cuerpo')).includes('Le SUMA a Fudo lo que llegó')
  || 'no describe el reparto, que está encendido');
await caso('y el apagado dice qué se está perdiendo', async () =>
  (await page.textContent('#fperm-cuerpo')).includes('La ficha deja de mostrar ese botón')
  || 'un interruptor apagado no dice qué falta por estarlo');
await caso('los tres grupos están rotulados', async () => {
  const t = await page.textContent('#fperm-cuerpo');
  return (t.includes('Actualizar el stock') && t.includes('Solo, sin apretar nada')
       && t.includes('El catálogo de Fudo')) || 'faltan rótulos';
});

console.log('\nEncender uno no pregunta nada; apagar sí avisa:');
await page.evaluate(()=>{window.__escrito=[];});
await page.click('[data-fpsw="boton"]'); await page.waitForTimeout(400);
await caso('encender guarda sin preguntar', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='app_permisos'));
  return (w && Array.isArray(w.valor.fudo_bloqueos) && !w.valor.fudo_bloqueos.includes('boton'))
    || 'guardó: '+JSON.stringify(w && w.valor);
});
await caso('y queda encendido en la pantalla', async () =>
  (await page.getAttribute('[data-fpsw="boton"]','class')).includes('on') || 'no se actualizó');

await page.evaluate(()=>{window.__escrito=[];});
await page.click('[data-fpsw="reparto"]'); await page.waitForTimeout(350);
await caso('apagar abre un aviso antes', async () => await page.isVisible('#overlay-ask') || 'apagó sin avisar');
await caso('y el aviso dice la consecuencia', async () =>
  (await page.textContent('#ask-detalle')).includes('Fudo no se entera') || 'no la dice');
await page.click('#ask-no'); await page.waitForTimeout(300);
await caso('si se cancela, no se guarda nada', async () => {
  const w = await page.evaluate(()=>window.__escrito.length);
  return w === 0 || 'escribió igual';
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno', () => errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
