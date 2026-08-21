/* Los envíos a franquicias, de punta a punta en un navegador de verdad.
   node pruebas/franquicias.mjs

   QUÉ SON. Cafés que le compran a bodega y NO tienen Llamita (Jhon,
   2026-08-21). Del otro lado no hay nadie que confirme nada: la lista se arma
   acá, alguien de bodega la prepara marcando línea por línea, y lo que sale se
   descuenta acá mismo. El envío viaja con una hoja impresa, porque allá no hay
   ninguna pantalla donde mirarlo.

   LO QUE MÁS IMPORTA COMPROBAR, y es la razón de que estén en tablas propias:
   que **no toquen el reparto de los locales**. Un reparto normal obliga a
   apuntar cada línea a un producto de la sede que recibe; forzarlo con una
   franquicia haría que al confirmar se SUMARA en bodega en vez de restar.  */
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const BODEGA = [
  {id:501, sede:'central', producto:'Alfajor artesanal', rubro:'Vitrina de dulces', stock_actual:10, stock_min:4, stock_max:20, activo:'SÍ'},
  {id:502, sede:'central', producto:'Café en grano',     rubro:'Mesones',           stock_actual:3,  stock_min:2, stock_max:8,  activo:'SÍ'},
  {id:503, sede:'central', producto:'Bolsa kraft M',     rubro:'Mueble de bolsas',  stock_actual:0,  stock_min:5, stock_max:30, activo:'SÍ'},
];

const page = await browser.newPage();
await page.addInitScript(({BODEGA}) => {
  window.__escrito = [];
  window.__rpc = [];
  const SES = {user:{id:'u1', email:'p@c.cl', user_metadata:{nombre:'Adriana'}}};
  const T = {
    productos: BODEGA, envios_franquicia: [], envios_franquicia_items: [],
    secciones: [], ajustes: [], app_permisos: [], fudo_sync: [], producto_lotes: [],
    repartos: [], reparto_items: [], recetas: [], receta_items: [], historial: [],
    tareas: [], fudo_productos: [], producto_enlace: [], metas: [], movimientos: [],
  };
  let seq = 900;
  const q = nombre => {
    const filas = JSON.parse(JSON.stringify(T[nombre] || []));
    const api = {
      select:()=>api, eq:()=>api, in:()=>api, order:()=>api, limit:()=>api, neq:()=>api,
      gte:()=>api, lte:()=>api, is:()=>api, not:()=>api, or:()=>api, ilike:()=>api,
      maybeSingle:()=>Promise.resolve({data:filas[0]||null,error:null}),
      single:()=>Promise.resolve({data:filas[0]||null,error:null}),
      insert(v){
        /* Los valores por defecto de la base, por tabla. Ponerle `estado:'abierto'`
       a TODO —que fue el primer intento— le daba ese estado también a las
       líneas, que nacen en 'pendiente', y entonces la pantalla las pintaba
       como ya resueltas. Una base de mentira que no imita los defaults reales
       hace fallar cosas que están bien. */
    const porDefecto = {
      envios_franquicia:       {estado:'abierto',   created_at:new Date().toISOString()},
      envios_franquicia_items: {estado:'pendiente', cantidad_enviada:null},
    }[nombre] || {};
    const rows = (Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...porDefecto, ...r}));
        (T[nombre] = T[nombre] || []).push(...rows);
        window.__escrito.push({tabla:nombre, op:'insert', filas:rows});
        const enc = {select:()=>enc, single:()=>Promise.resolve({data:rows[0],error:null}),
                     then:f=>Promise.resolve({data:rows,error:null}).then(f)};
        return enc;
      },
      update(v){ window.__escrito.push({tabla:nombre, op:'update', valor:v});
        const enc = {eq:()=>enc, select:()=>enc, then:f=>Promise.resolve({data:[v],error:null}).then(f)};
        return enc; },
      upsert:()=>api, delete:()=>api,
      then:f=>Promise.resolve({data:filas,error:null}).then(f),
    };
    return api;
  };
  window.supabase = {createClient: () => ({
    from: q,
    rpc: (n, args) => {
      window.__rpc.push({fn:n, args});
      /* La base de mentira imita a la de verdad en lo único que importa acá:
         marcar una línea baja el stock de bodega y deja la línea resuelta. */
      if(n === 'franquicia_linea_lista' || n === 'franquicia_linea_no_hay'){
        const it = (T.envios_franquicia_items||[]).find(x=>x.id === args.p_item);
        if(it && it.estado === 'pendiente'){
          const cant = n === 'franquicia_linea_lista' ? (+args.p_cant||0) : 0;
          it.estado = n === 'franquicia_linea_lista' ? 'listo' : 'no_hay';
          it.cantidad_enviada = cant;
          const p = T.productos.find(x=>x.id === it.producto_id);
          if(p && cant) p.stock_actual = Math.max(0, (+p.stock_actual||0) - cant);
        }
        return Promise.resolve({data:{ok:true}, error:null});
      }
      return Promise.resolve({data:[], error:null});
    },
    auth:{getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
      onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
      signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({})},
    channel:()=>({on(){return this;}, subscribe(cb){cb&&cb('SUBSCRIBED');return this;},
      track:async()=>{}, presenceState:()=>({})}),
    removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
  })};
}, {BODEGA});
await page.route('**/supabase-js*', r => r.fulfill({status:200, contentType:'application/javascript', body:'/* simulado */'}));

const errores = [];
page.on('pageerror', e => errores.push(String(e)));
await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(300);

let ok=0, mal=0;
const caso = async (nombre, fn) => {
  try { const r = await fn(); if(r===true){ ok++; console.log(`  ✓ ${nombre}`); }
        else { mal++; console.log(`  ✗ ${nombre}  → ${r}`); } }
  catch(e){ mal++; console.log(`  ✗ ${nombre}  → ${e.message.split('\n')[0]}`); }
};

await page.click('.gate-btn[data-sede="central"]');
await page.waitForTimeout(500);
await page.click('.tab[data-tab="envios"]');
await page.waitForTimeout(600);

console.log('\nEl bloque de franquicias está en Bodega → Enviar:');
await caso('se ve, junto a los envíos a los locales', async () =>
  await page.isVisible('#repc-franq') || 'no aparece');
await caso('con las cinco franquicias en el selector', async () => {
  const n = await page.$$eval('#fr-sede option', o => o.map(x => x.textContent));
  return n.length === 5 && n.some(x => x.includes('Portada')) && n.some(x => x.includes('Easton'))
    || 'salieron: ' + n.join(' | ');
});
await caso('y NO se mezcla con Mall Plaza ni Angamos', async () => {
  /* Ojo con el falso positivo: una de las franquicias se llama "Mall Plaza
     Calama", así que buscar "Mall Plaza" a secas encuentra su propio nombre.
     Lo que hay que comprobar es que no aparezcan los BOTONES de los locales. */
  const dentro = await page.$$eval('#repc-franq [data-repcir]', b => b.length);
  return dentro === 0 || 'el bloque de franquicias trae los botones de los locales';
});

console.log('\nAdriana arma la lista:');
await page.fill('#fr-q', 'alfajor');
await page.waitForTimeout(300);
await caso('busca en el inventario de bodega y muestra cuánto hay', async () =>
  (await page.textContent('#fr-results')).includes('bodega: 10') || 'no dice cuánto hay');
await page.click('[data-fradd="501"]');
await page.waitForTimeout(250);
await page.fill('#fr-q', 'café');
await page.waitForTimeout(300);
await page.click('[data-fradd="502"]');
await page.waitForTimeout(250);
await caso('los productos entran a la lista', async () =>
  (await page.$$('[data-frquitar]')).length === 2 || 'no quedaron dos');
await caso('cada uno dice cuánto hay al lado del campo', async () =>
  (await page.textContent('#fr-carrito')).includes('hay 3') || 'no muestra el stock de bodega');
await page.fill('[data-frcant="0"]', '4');
await page.waitForTimeout(150);
await page.click('#fr-enviar');
await page.waitForTimeout(800);
/* Al crear la lista sale un aviso explicando el paso siguiente. Hay que
   cerrarlo antes de seguir: mientras está abierto tapa toda la pantalla. */
if(await page.isVisible('#overlay-ask')){ await page.click('#ask-ok'); await page.waitForTimeout(350); }
await caso('al crearla se guarda con su franquicia', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='envios_franquicia'));
  return (w && w.filas[0].franquicia && w.filas[0].creado_por === 'Adriana')
    || 'no guardó la franquicia';
});
await caso('y sus líneas apuntan al producto de BODEGA', async () => {
  const w = await page.evaluate(()=>window.__escrito.find(x=>x.tabla==='envios_franquicia_items'));
  return (w && w.filas.length === 2 && w.filas[0].producto_id === 501)
    || 'las líneas no salieron bien';
});
await caso('NO tocó repartos ni reparto_items', async () =>
  (await page.evaluate(()=>window.__escrito.filter(x=>
    x.tabla==='repartos' || x.tabla==='reparto_items').length)) === 0
  || 'escribió en el reparto de los locales');

console.log('\nBodega la prepara, línea por línea:');
await caso('la lista aparece en "por preparar", con el nombre de la franquicia', async () => {
  const t = await page.textContent('#fr-abiertos');
  return (t.includes('Portada') || t.includes('Urbano')) && t.includes('por preparar')
    || 'no aparece: ' + t.slice(0,80);
});
const idItem = await page.evaluate(()=>{
  const b = document.querySelector('[data-frlisto]'); return b ? +b.dataset.frlisto : null;
});
await caso('hay un botón para marcar que salió', () => idItem !== null || 'no hay botón');
await page.click(`[data-frlisto="${idItem}"]`);
await page.waitForTimeout(700);
await caso('marcarla llama a la función que descuenta', async () => {
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.fn==='franquicia_linea_lista'));
  return (r && r.args.p_cant === 4 && r.args.p_quien === 'Adriana')
    || 'no llamó bien: ' + JSON.stringify(r);
});
await caso('y el stock de bodega baja en la pantalla', async () => {
  const t = await page.textContent('#fr-abiertos');
  return t.includes('salieron 4') || 'la línea no quedó resuelta';
});
const otro = await page.evaluate(()=>{
  const b = document.querySelector('[data-frnohay]'); return b ? +b.dataset.frnohay : null;
});
if(otro !== null){
  await page.click(`[data-frnohay="${otro}"]`);
  await page.waitForTimeout(600);
  await caso('"no había" NO descuenta nada', async () => {
    const r = await page.evaluate(()=>window.__rpc.filter(x=>x.fn==='franquicia_linea_lista').length);
    return r === 1 || 'llamó a descontar ' + r + ' veces';
  });
}
await caso('con todo preparado, se puede cerrar el envío', async () =>
  !(await page.getAttribute('[data-frcerrar]','disabled')) || 'el botón sigue bloqueado');

console.log('\nLa hoja que viaja con el envío:');
await caso('el botón de imprimir está', async () =>
  await page.isVisible('[data-frhoja]') || 'no está');
const hoja = await page.evaluate(()=>{
  /* Se intercepta la ventana en vez de abrirla: lo que importa es QUÉ dice
     el papel, no que el navegador sepa imprimir. */
  let capturado = '';
  const real = window.open;
  window.open = () => ({ document:{ write(h){ capturado = h; }, close(){} }, focus(){}, print(){} });
  document.querySelector('[data-frhoja]').click();
  window.open = real;
  return capturado;
});
await caso('lleva el nombre de la franquicia', () =>
  /Portada|Urbano|Viña|Calama|Easton/.test(hoja) || 'no la nombra');
await caso('dice qué va y cuánto', () =>
  (hoja.includes('Lo que va') && hoja.includes('Alfajor artesanal')) || 'no lista los productos');
await caso('separa lo que no se pudo enviar', () =>
  hoja.includes('No se pudo enviar') || 'no distingue lo que faltó');
await caso('y trae las dos firmas', () =>
  (hoja.includes('Entrega') && hoja.includes('Recibe')) || 'sin firmas');

await caso('ningún error de JavaScript en todo el recorrido', () =>
  errores.length === 0 || errores.join(' | ').slice(0,300));

console.log(`\n${mal ? '✗' : '✓'} ${ok} bien, ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
