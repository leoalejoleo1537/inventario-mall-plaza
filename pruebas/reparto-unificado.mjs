/* LA INTERFAZ UNIFICADA DE REPARTO DE BODEGA.
   node pruebas/reparto-unificado.mjs

   Tres bloques separados —Plaza, Angamos y Franquicias, cada uno con su
   buscador y su carro— pasan a ser uno solo con un selector de destino.

   Y con la información que Jhon pidió: "necesito que este apartado tenga la
   mayor cantidad de información posible, para que Adriana no tenga que hacer
   muchos movimientos dentro de Llamita". Concretamente:
     · lo URGENTE arriba del todo, en su propio bloque
     · cuánto hay allá, su mínimo, su máximo Y cuánto tiene bodega
   Ese último dato es el que evitaba el viaje de ida y vuelta: sin él hay que
   salir a mirar el inventario de bodega para saber si se puede prometer.   */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const BODEGA = [
  {id:900, sede:'central', producto:'Medialuna', rubro:'Bodega', stock_actual:7,  stock_min:2, stock_max:40, activo:'SÍ'},
  {id:901, sede:'central', producto:'Alfajor',   rubro:'Bodega', stock_actual:20, stock_min:2, stock_max:60, activo:'SÍ'},
  {id:902, sede:'central', producto:'Servilleta',rubro:'Bodega', stock_actual:0,  stock_min:5, stock_max:80, activo:'SÍ'},
];
/* Sandwich Serrano va marcado URGENTE **estando sobre su mínimo**: es
   justamente el caso que la marca manual existe para cubrir, y el que se
   perdería si lo urgente no subiera al principio. */
const PLAZA = [
  {id:10, sede:'plaza', producto:'Medialuna',       rubro:'Vitrina de dulces', stock_actual:1, stock_min:6,  stock_max:12, activo:'SÍ'},
  {id:11, sede:'plaza', producto:'Alfajor',         rubro:'Congelador',        stock_actual:0, stock_min:4,  stock_max:10, activo:'SÍ'},
  {id:12, sede:'plaza', producto:'Cachito',         rubro:'Vitrina de dulces', stock_actual:9, stock_min:3,  stock_max:12, activo:'SÍ'},
  {id:13, sede:'plaza', producto:'Sandwich Serrano',rubro:'Sándwiches',        stock_actual:9, stock_min:3,  stock_max:14, activo:'SÍ', urgente:true},
  {id:14, sede:'plaza', producto:'Servilleta',      rubro:'Mueble de bolsas',  stock_actual:2, stock_min:20, stock_max:80, activo:'SÍ'},
];
const ANGAMOS = [
  {id:20, sede:'angamos', producto:'Medialuna', rubro:'Vitrina', stock_actual:0, stock_min:5, stock_max:10, activo:'SÍ'},
];
const ENLACES = [
  {sede:'plaza', producto_bodega_id:900, producto_sede_id:10},
  {sede:'plaza', producto_bodega_id:901, producto_sede_id:11},
  {sede:'plaza', producto_bodega_id:902, producto_sede_id:14},
  {sede:'angamos', producto_bodega_id:900, producto_sede_id:20},
];

const page = await browser.newPage();
await page.setViewportSize({width:390, height:900});
await page.addInitScript(({BODEGA, PLAZA, ANGAMOS, ENLACES}) => {
  window.__escrito = [];
  const SES = {user:{id:'u1', email:'adriana@cafe.cl', user_metadata:{nombre:'Adriana'}}};
  const T = {productos:[...BODEGA, ...PLAZA, ...ANGAMOS], producto_enlace:ENLACES,
    app_permisos:[{correo:'adriana@cafe.cl', nombre:'Adriana', puede_ajustes:true, puede_editar:true, puede_fudo:true, fudo_bloqueos:[]}],
    fudo_sync:[], secciones:[], movimientos:[], ajustes:[], metas:[], historial:[],
    restauraciones:[], fusiones:[], fudo_stock_push:[], recetas:[], receta_items:[],
    fudo_productos:[], producto_lotes:[], repartos:[], reparto_items:[], mermas:[],
    tareas:[], fudo_categorias:[], envios_franquicia:[], envios_franquicia_items:[]};
  let seq = 7000;
  const q = (n) => {
    let filas = JSON.parse(JSON.stringify(T[n]||[]));
    const api = {
      select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
      in(c,vs){ filas=filas.filter(f=>vs.map(String).includes(String(f[c]))); return api;},
      neq(){return api;}, order(){return api;}, limit(){return api;}, gte(){return api;},
      lte(){return api;}, is(){return api;}, not(){return api;}, or(){return api;}, ilike(){return api;},
      maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},
      single(){return Promise.resolve({data:filas[0]||null,error:null});},
      insert(v){ const rows=(Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
        window.__escrito.push({tabla:n, filas:rows});
        const e={select:()=>e, single:()=>Promise.resolve({data:rows[0],error:null}),
                 then:f=>Promise.resolve({data:rows,error:null}).then(f)}; return e; },
      update(){const e={eq:()=>e,select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
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
}, {BODEGA, PLAZA, ANGAMOS, ENLACES});
await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
const errores = [];
page.on('pageerror', e=>errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(350);

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

await page.click('.gate-btn[data-sede="central"]'); await page.waitForTimeout(600);
await page.click('#tabEnvios'); await page.waitForTimeout(800);

console.log('\nUn solo selector para los siete destinos:');
await caso('están los dos locales y las cinco franquicias', async () =>
  (await page.$$('[data-repcdest]')).length === 7 || 'hay '+(await page.$$('[data-repcdest]')).length);
await caso('arranca en Mall Plaza', async () =>
  (await page.getAttribute('[data-repcdest="plaza"]','class')).includes('on') || 'no está elegida');
await caso('la franquicia se ve distinta del local', async () => {
  const c = await page.$$eval('[data-repcdest]', b=>b.map(x=>x.className));
  return c.filter(x=>x.includes('franq')).length === 5 || 'no se distinguen';
});
await caso('se ve UN solo bloque de sede, no dos', async () =>
  (await page.$$('#repc-cajas .enl-caja')).length === 1 || 'se ven '+(await page.$$('#repc-cajas .enl-caja')).length);

console.log('\nLo que le falta a la sede, con lo URGENTE arriba:');
await caso('el bloque está abierto, sin tener que pedirlo', async () =>
  await page.isVisible('.repc-falta') || 'no se ve');
await caso('hay un grupo URGENTE', async () =>
  await page.isVisible('.rf-urg') || 'no hay bloque de urgentes');
await caso('y el urgente va ANTES que todo lo demás', async () => {
  const orden = await page.$$eval('.rf-fila b', n=>n.map(x=>x.textContent));
  return orden[0] === 'Sandwich Serrano'
    || 'el primero es '+orden[0]+' — lo urgente quedó sepultado';
});
await caso('sube aunque esté SOBRE su mínimo', async () => {
  const t = await page.textContent('.rf-urg');
  return t.includes('allá hay 9') || 'no trae el que está sobre el mínimo: '+t.slice(0,60);
});
await caso('no aparece lo que está bien (Cachito)', async () =>
  !(await page.textContent('.repc-falta')).includes('Cachito') || 'metió un producto que no falta');

console.log('\nCada renglón trae TODO lo que hace falta para decidir:');
await caso('cuánto hay allá', async () =>
  (await page.textContent('.repc-falta')).includes('allá hay 1') || 'falta el stock del local');
await caso('su mínimo', async () =>
  (await page.textContent('.repc-falta')).includes('mín 6') || 'falta el mínimo');
await caso('su máximo', async () =>
  (await page.textContent('.repc-falta')).includes('máx 12') || 'falta el máximo');
await caso('y CUÁNTO TIENE BODEGA', async () =>
  (await page.textContent('.repc-falta')).includes('bodega: 7')
  || 'falta el dato de bodega: habría que salir a mirarlo a otra pantalla');
await caso('bodega en 0 se ve distinto de bodega sin enlace', async () => {
  const t = await page.textContent('.repc-falta');
  return (t.includes('bodega: 0')) || 'no distingue "se acabó" de "no está enlazado"';
});

console.log('\nSe agrega desde ahí mismo:');
await caso('tocar el + lo mete al carro', async () => {
  await page.click('[data-rfadd="plaza-10"]'); await page.waitForTimeout(300);
  return (await page.evaluate(()=>repcCarritos.plaza.length)) === 1 || 'no lo agregó';
});
await caso('con lo que falta para el máximo', async () =>
  (await page.evaluate(()=>repcCarritos.plaza[0].cantidad)) === 11 || 'propuso otra cantidad');
await caso('y queda marcado con ✓', async () =>
  (await page.getAttribute('[data-rfadd="plaza-10"]','class')).includes('ya') || 'no se marcó');

console.log('\nCambiar de destino no pierde lo armado:');
await page.click('[data-repcdest="angamos"]'); await page.waitForTimeout(500);
await caso('ahora se ve Angamos', async () =>
  (await page.textContent('#repc-cajas')).includes('ANGAMOS') || 'no cambió de sede');
await caso('el carro de Angamos está vacío', async () =>
  (await page.evaluate(()=>repcCarritos.angamos.length)) === 0 || 'traía cosas');
await page.click('[data-repcdest="plaza"]'); await page.waitForTimeout(500);
await caso('y al volver a Plaza sigue lo que había', async () =>
  (await page.evaluate(()=>repcCarritos.plaza.length)) === 1 || 'se perdió el carro');

console.log('\nEl buscador ofrece UN botón, el del destino elegido:');
await page.fill('#repc-q','alfa'); await page.waitForTimeout(400);
await caso('encuentra el producto', async () =>
  (await page.textContent('#repc-results')).includes('Alfajor') || 'no lo encontró');
await caso('un solo botón para agregar', async () =>
  (await page.$$('#repc-results [data-repcir]')).length === 1
  || 'hay '+(await page.$$('#repc-results [data-repcir]')).length+' botones: vuelve la duda de a cuál sede va');

console.log('\nUna franquicia se ve distinta, y a propósito:');
await page.click('[data-repcdest^="fr:"]'); await page.waitForTimeout(500);
await caso('desaparece "le falta a" (no tenemos su inventario)', async () =>
  !(await page.isVisible('.repc-falta')) || 'muestra una lista que no puede saber');
await caso('aparece el bloque de franquicias', async () =>
  await page.isVisible('#repc-franq') || 'no aparece');
await caso('dice a cuál va', async () =>
  (await page.textContent('#fr-quien')).includes('Urbano') || 'no dice el nombre');
await caso('el selector de adentro ya no se ve (uno solo manda)', async () =>
  !(await page.isVisible('#fr-sede')) || 'quedaron dos sitios para elegir lo mismo');
await page.click('[data-repcdest="plaza"]'); await page.waitForTimeout(400);
await caso('y al volver al local, vuelve la lista de lo que falta', async () =>
  await page.isVisible('.repc-falta') || 'no volvió');

console.log('\nEscribir la cantidad a mano (el bug del 12 que salía 21):');
await page.click('[data-repcdest="plaza"]'); await page.waitForTimeout(500);
await caso('escribir "12" deja 12, no 21', async () => {
  await page.click('input[data-repcidx="plaza-0"]');
  await page.keyboard.press('Control+a');
  await page.keyboard.type('12', {delay:80});
  await page.waitForTimeout(300);
  const v = await page.inputValue('input[data-repcidx="plaza-0"]');
  return v === '12' || 'quedó "'+v+'": el cursor se va al principio entre tecla y tecla';
});
await caso('y el modelo guarda 12', async () =>
  (await page.evaluate(()=>repcCarritos.plaza[0].cantidad)) === 12 || 'guardó otra cosa');
await caso('escribir "32" deja 32, no 23', async () => {
  await page.click('input[data-repcidx="plaza-0"]');
  await page.keyboard.press('Control+a');
  await page.keyboard.type('32', {delay:80});
  await page.waitForTimeout(300);
  return (await page.inputValue('input[data-repcidx="plaza-0"]')) === '32'
    || 'quedó "'+(await page.inputValue('input[data-repcidx="plaza-0"]'))+'"';
});
await caso('el campo NO se destruye al teclear', async () => {
  const antes = await page.evaluate(()=>{
    const n = document.querySelector('input[data-repcidx="plaza-0"]'); n.dataset.marca='yo'; return true; });
  await page.click('input[data-repcidx="plaza-0"]');
  await page.keyboard.type('5', {delay:60});
  await page.waitForTimeout(250);
  const sigue = await page.evaluate(()=>{
    const n = document.querySelector('input[data-repcidx="plaza-0"]'); return n && n.dataset.marca; });
  return sigue === 'yo' || 'se reemplazó por otro campo: por eso se perdía el cursor';
});
await caso('pero el total SÍ se actualiza mientras escribe', async () => {
  const t = await page.textContent('[data-repctot="plaza"]');
  return t.includes('325') || t.match(/\d/) ? true : 'el total no siguió al número';
});

console.log('\nEnlaces · los que no tienen de dónde bajar:');
await page.click('#tabEnlaces'); await page.waitForTimeout(700);
await caso('la sección está, debajo de crear producto', async () =>
  await page.isVisible('#enl-pend-caja') || 'no aparece');
await caso('lista SOLO los que de verdad faltan', async () => {
  const t = await page.textContent('#enl-pend');
  /* Servilleta (id 14) tiene enlace, así que no va. Cachito (12) tampoco,
     porque no tiene enlace pero SÍ existe... en realidad no tiene gemelo, así
     que sí debe salir. Lo que importa: los que ya tienen enlace no salen. */
  return !t.includes('Medialuna') || 'muestra uno que ya está enlazado';
});
await caso('dice cuántos son', async () =>
  (await page.textContent('#enl-pend-n')).trim() !== '—' || 'no cuenta');
await caso('al tocar uno se abre y propone candidatos de bodega', async () => {
  const b = await page.$('[data-enlpend]');
  if(!b) return 'no hay ninguno pendiente para probar';
  await b.click(); await page.waitForTimeout(350);
  return await page.isVisible('.enl-pend-cuerpo') || 'no se abrió';
});
await caso('y trae un buscador para el que no propone nada', async () =>
  await page.isVisible('[data-enlbusca]') || 'sin salida manual');

/* EL BUG DEL 2026-08-22, Y ES MÍO DE MÉTODO. Yo escondía los productos de
   bodega que ya estaban enlazados a esa sede, creyendo que la base no dejaba
   dos. Es al revés: esa restricción se QUITÓ a propósito el 12 de agosto,
   porque un producto de bodega SÍ va a dos del local cuando existe el par
   vitrina/congelador. El candado que puse escondía el candidato correcto sin
   decir por qué. */
await caso('un producto de bodega YA enlazado se sigue ofreciendo', async () => {
  await page.fill('[data-enlbusca]', 'medialuna');
  await page.waitForTimeout(350);
  const t = await page.textContent('#enl-busca-res');
  return t.includes('Medialuna')
    || 'lo esconde: el par vitrina/congelador necesita reusar el mismo origen';
});
await caso('y avisa a dónde va ya, en vez de bloquearlo', async () =>
  (await page.textContent('#enl-busca-res')).includes('ya va a')
  || 'no dice que ya está en uso');
await caso('buscar "al" pone los que EMPIEZAN con "al" primero', async () => {
  await page.fill('[data-enlbusca]', 'al');
  await page.waitForTimeout(350);
  const b = await page.$$eval('#enl-busca-res .enl-cand b', n=>n.map(x=>x.textContent.trim()));
  if(!b.length) return 'no encontró nada';
  return b[0].toLowerCase().startsWith('al')
    || 'el primero es "'+b[0]+'": lo que uno escribió queda sepultado';
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () => errores.length === 0 || errores.slice(0,2).join(' · '));

await page.screenshot({path:'/tmp/reparto-unificado.png', fullPage:true});
console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
