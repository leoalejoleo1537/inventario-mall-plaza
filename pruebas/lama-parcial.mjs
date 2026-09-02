/* LLAMITA LAMA · A1 — el pago parcial por producto.
   node pruebas/lama-parcial.mjs

   Cuatro personas, una se va antes. Se eligen SUS productos, se cobran, y la
   mesa sigue abierta con lo que falta.

   LO QUE SE PRUEBA ACÁ ES PLATA, y por eso pesa más que cualquier otra suite:

     · que NUNCA se pida dos veces lo mismo — al reabrir el cobro, lo que se
       precarga es lo que FALTA, no el total. Si esto falla, la mesa se cobra
       de más y se descubre al final del turno, o nunca
     · que el descuento se reparta proporcionalmente, y que el número que
       muestra la pantalla sea el mismo que va a calcular la base
     · que no se pueda elegir más unidades de las que quedan
     · que lo ya cobrado se vea, y se pueda deshacer

   Y la primera de todas, que es de otra clase: SIN LA MIGRACIÓN CORRIDA el
   botón no existe. No se prueba y se ve si falla — eso confunde "esta función
   no existe" con "la base rechazó el cobro", y con la segunda se cobraría mal.

   Los números: 2×3.200 + 1×3.600 = 10.000.                                 */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const MESAS = Array.from({length:12}, (_,i)=>({
  id:100+i, sede:'plaza', salon:'Salón', numero:i+1, orden:i+1, activa:true }));

/* Los números son los del ejemplo que dictó Jhon, para poder comprobar el
   caso completo: subtotal 10.000, propina del 10% = 1.000, total 11.000, el
   cliente paga 12.000 y el excedente se manda a propina. */
const CUENTAS = [
  {id:900, sede:'plaza', mesa_id:101, estado:'abierta', total:10000, abierta_por:'jhon@cafe.cl'},
  /* La 103 queda abierta y VACÍA: una mesa sin nada no abre la ventana. */
  {id:902, sede:'plaza', mesa_id:103, estado:'abierta', total:0,     abierta_por:'jhon@cafe.cl'},
];
const ITEMS = [
  {id:1, cuenta_id:900, nombre:'Café Latte',         cantidad:2, precio:3200, estado:'confirmado', comentario:null, cantidad_pagada:0},
  {id:2, cuenta_id:900, nombre:'Torta de zanahoria', cantidad:1, precio:3600, estado:'confirmado', comentario:null, cantidad_pagada:0},
];
const CARTA = [
  {fudo_product_id:'F-38', sede:'plaza', nombre:'Café Latte', precio:3400, activo:true},
];
const MEDIOS = [
  {codigo:'efectivo', nombre:'Efectivo',           orden:1, es_cobro:true,  activo:true},
  {codigo:'debito',   nombre:'Tarjeta de débito',  orden:2, es_cobro:true,  activo:true},
  {codigo:'admin',    nombre:'Consumo administrativo', orden:8, es_cobro:false, activo:true},
];
const MOTIVOS = [
  {codigo:'empleado', nombre:'Descuento de empleado', orden:1, activo:true},
  {codigo:'cumple',   nombre:'Cumpleaños',            orden:2, activo:true},
];

const page = await browser.newPage();
await page.setViewportSize({width:1280, height:900});

async function montar({conMigracion = true, conParcial = true} = {}){
  await page.addInitScript(({MESAS, CUENTAS, ITEMS, CARTA, MEDIOS, MOTIVOS, conMigracion, conParcial}) => {
    window.__rpc = [];
    const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
    const T = {
      productos:[], mesas:MESAS, cuentas:CUENTAS, cuenta_items:ITEMS, comandas:[],
      fudo_productos:CARTA,
      /* Sin la migración corrida, estas dos tablas NO existen: es el estado
         real de la base de Jhon hasta que pegue el .sql. */
      /* La tabla que delata si la migración del PAGO PARCIAL está puesta.
         `null` = no existe, que es el estado real hasta que Jhon pegue el .sql. */
      cuenta_pago_items:      conParcial ? [] : null,
      cuenta_pagos:           [],
      lama_medios_pago:       conMigracion ? MEDIOS  : null,
      lama_motivos_descuento: conMigracion ? MOTIVOS : null,
      app_permisos:[{correo:'jhon@cafe.cl', nombre:'Jhon', puede_ajustes:true,
                     puede_editar:true, puede_fudo:true, puede_lama:true, fudo_bloqueos:[]}],
      producto_enlace:[], fudo_stock_push:[], fudo_sync:[], secciones:[], movimientos:[],
      ajustes:[], metas:[], historial:[], historial_auto:[], restauraciones:[], fusiones:[],
      recetas:[], receta_items:[], producto_lotes:[], repartos:[], reparto_items:[],
      mermas:[], tareas:[], fudo_categorias:[], envios_franquicia:[], envios_franquicia_items:[]};
    let seq = 7000;
    const q = (n) => {
      const falta = T[n] === null;
      let filas = falta ? [] : JSON.parse(JSON.stringify(T[n]||[]));
      const err = falta
        ? {message:'relation "public.'+n+'" does not exist', code:'42P01'} : null;
      const api = {
        select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
        neq(c,v){ filas=filas.filter(f=>String(f[c])!==String(v)); return api;},
        in(c,vs){ filas=filas.filter(f=>vs.map(String).includes(String(f[c]))); return api;},
        order(){return api;}, limit(){return api;}, gte(){return api;}, lte(){return api;},
        is(){return api;}, not(){return api;}, or(){return api;}, ilike(){return api;},
        maybeSingle(){return Promise.resolve({data:filas[0]||null,error:err});},
        single(){return Promise.resolve({data:filas[0]||null,error:err});},
        insert(v){ const rows=(Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
          const e={select:()=>e, single:()=>Promise.resolve({data:rows[0],error:null}),
                   then:f=>Promise.resolve({data:rows,error:null}).then(f)}; return e; },
        update(){const e={eq:()=>e,in:()=>e,select:()=>e,
                 single:()=>Promise.resolve({data:filas[0]||null,error:null}),
                 then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        upsert(){const e={select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        delete(){const e={eq:()=>e,in:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        then(f){return Promise.resolve({data: falta?null:filas, error:err, count:filas.length}).then(f);},
      };
      return api;
    };
    window.supabase = { createClient: () => ({
      from:q,
      rpc:(nombre, args)=>{
        window.__rpc.push({nombre, args});
        if(nombre === 'cuenta_cobrar'){
          if(!conMigracion)
            return Promise.resolve({data:null,
              error:{message:'function public.cuenta_cobrar(...) does not exist', code:'42883'}});
          return Promise.resolve({data:{id:args.p_cuenta_id, estado:'cerrada'}, error:null});
        }
        if(nombre === 'cuenta_cobrar_parcial'){
          /* Se mueve la tabla de verdad: así al recargar, la pantalla ve lo
             que vería contra la base, y no una fantasía del mock. */
          let sub = 0;
          for(const x of (args.p_items || [])){
            const it = T.cuenta_items.find(i => i.id === x.item_id);
            if(it){ it.cantidad_pagada = (+it.cantidad_pagada||0) + (+x.cantidad||0);
                    sub += (+x.cantidad||0) * (+it.precio||0); }
          }
          const c = T.cuentas.find(y => y.id === args.p_cuenta_id) || {};
          const subVenta = T.cuenta_items.filter(i => i.cuenta_id === args.p_cuenta_id && !i.anulado_at)
            .reduce((z,i)=> z + (+i.cantidad||0)*(+i.precio||0), 0);
          let dv = 0;
          if(c.descuento_formato === 'pct')  dv = Math.round(subVenta * (+c.descuento_valor||0)/100);
          if(c.descuento_formato === 'fijo') dv = +c.descuento_valor || 0;
          const monto = sub - (subVenta > 0 ? Math.round(dv * sub / subVenta) : 0);
          const fila = {id:++seq, cuenta_id:args.p_cuenta_id, medio:args.p_medio,
                        monto, parcial:true};
          T.cuenta_pagos.push(fila);
          return Promise.resolve({data:fila, error:null});
        }
        if(nombre === 'cuenta_pago_parcial_deshacer'){
          const i = T.cuenta_pagos.findIndex(x => x.id === args.p_pago_id);
          if(i >= 0) T.cuenta_pagos.splice(i,1);
          return Promise.resolve({data:1, error:null});
        }
        if(nombre === 'cuenta_cerrar')
          return Promise.resolve({data:{id:args.p_cuenta_id, estado:'cerrada'}, error:null});
        return Promise.resolve({data:null, error:null});
      },
      auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
             onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
             signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
      channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
      removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
    })};
  }, {MESAS, CUENTAS, ITEMS, CARTA, MEDIOS, MOTIVOS, conMigracion, conParcial});
  await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
  await page.goto(pathToFileURL(join(raiz,'index.html')).href);
  await page.waitForTimeout(400);
  await page.click('.gate-btn[data-sede="plaza"]');
  await page.waitForTimeout(700);
  await page.click('#tabLama'); await page.waitForTimeout(500);
}

const errores = [];
page.on('pageerror', e=>errores.push(String(e)));


let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  \u2713 '+n);}
        else {mal++;console.log('  \u2717 '+n+'  \u2192 '+r);} }
  catch(e){ mal++; console.log('  \u2717 '+n+'  \u2192 '+e.message.split('\n')[0]); }
};
const abrirCobro = async () => {
  await page.click('[data-lamamesa="101"]'); await page.waitForTimeout(500);
  await page.click('[data-lamaacc="cobrar"]'); await page.waitForTimeout(600);
};
const pie = () => page.textContent('.lama-cob-pie');

console.log('\nSIN la migración corrida, el botón NO existe:');
await montar({conParcial:false});
await abrirCobro();
await caso('no ofrece pago parcial', async () =>
  !(await page.isVisible('[data-lamaacc="par-entrar"]')) || 'lo ofrece sin la migración');
await caso('y el cobro entero sigue funcionando igual', async () =>
  (await pie()).includes('Cobrar') || 'se rompió el cobro normal');

console.log('\nCon la migración, aparece y cambia la pantalla:');
await montar({});
await abrirCobro();
await caso('ofrece el pago parcial', async () =>
  (await page.isVisible('[data-lamaacc="par-entrar"]')) || 'no aparece el botón');
await caso('al entrar, cada producto trae su − n +', async () => {
  await page.click('[data-lamaacc="par-entrar"]'); await page.waitForTimeout(350);
  return (await page.$$('[data-parmas]')).length === 2 || 'no hay un − n + por producto';
});
await caso('el pie muestra Total Seleccionado', async () =>
  (await pie()).includes('Total Seleccionado') || 'el pie dice: ' + (await pie()));
await caso('y arranca en cero, sin nada elegido', async () =>
  (await pie()).includes('$0') || 'no arranca en cero: ' + (await pie()));

console.log('\nElegir cantidades:');
await caso('un café son 3.200', async () => {
  await page.click('[data-parmas="1"]'); await page.waitForTimeout(300);
  return (await pie()).includes('3.200') || 'el pie dice: ' + (await pie());
});
await caso('dos cafés son 6.400', async () => {
  await page.click('[data-parmas="1"]'); await page.waitForTimeout(300);
  return (await pie()).includes('6.400') || 'el pie dice: ' + (await pie());
});
/* Pedir más de lo que hay es lo que la base rechazaría. Mejor que el botón
   no lo ofrezca a que el garzón se lleve un error en la cara. */
await caso('el + NO deja pasar de lo que hay', async () => {
  await page.click('[data-parmas="1"]'); await page.waitForTimeout(300);
  return (await pie()).includes('6.400') || 'dejó elegir 3 de 2 cafés: ' + (await pie());
});
await caso('el − vuelve atrás', async () => {
  await page.click('[data-parmenos="1"]'); await page.waitForTimeout(300);
  return (await pie()).includes('3.200') || 'el pie dice: ' + (await pie());
});

console.log('\nCobrar lo elegido manda lo correcto a la base:');
await caso('llama a cuenta_cobrar_parcial con el producto y la cantidad', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.click('[data-lamaacc="par-cobrar"]'); await page.waitForTimeout(800);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_cobrar_parcial'));
  return (r && r.args.p_items.length === 1 && r.args.p_items[0].item_id === 1
          && r.args.p_items[0].cantidad === 1 && r.args.p_medio === 'efectivo')
    || 'mandó ' + JSON.stringify(r && r.args);
});
await caso('la mesa NO se cierra: no llama a cuenta_cobrar', async () =>
  !(await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_cobrar')))
  || 'cerró la mesa en un cobro parcial');

console.log('\nY LA CUENTA QUEDA BIEN — es lo que protege la plata:');
await caso('la ventana muestra "Ya cobrado −$3.200"', async () => {
  const t = (await page.textContent('.lama-cob-mitad')).replace(/\s+/g,' ');
  return (t.includes('Ya cobrado') && t.includes('3.200')) || 'dice: ' + t.slice(0,200);
});
await caso('y "Falta $6.800"', async () => {
  const t = (await page.textContent('.lama-cob-mitad')).replace(/\s+/g,' ');
  return (t.includes('Falta') && t.includes('6.800')) || 'dice: ' + t.slice(0,200);
});
/* EL CASO QUE MÁS IMPORTA DE TODA LA SUITE. Si el monto precargado volviera a
   ser el total, la mesa se cobraría dos veces. */
await caso('el pago del cierre se precarga con lo que FALTA, no con el total', async () => {
  const v = await page.evaluate(()=>{
    const i = document.querySelector('[data-cobmonto]'); return i ? i.value : null; });
  return (v && String(v).replace(/\./g,'') === '6800') || 'precargó ' + v + ' (tendría que ser 6.800)';
});
await caso('y el botón dice "Cobrar $6.800"', async () =>
  (await pie()).includes('6.800') || 'el botón dice: ' + (await pie()));

console.log('\nLo ya cobrado se ve y se puede deshacer:');
await caso('aparece la fila del cobro, con su medio', async () => {
  const t = (await page.textContent('.lama-cob-pagados')).replace(/\s+/g,' ');
  return (t.includes('Efectivo') && t.includes('3.200')) || 'dice: ' + t;
});
await caso('el café muestra "1 ya cobrado"', async () => {
  const t = (await page.textContent('.lama-cob-mitad')).replace(/\s+/g,' ');
  return t.includes('1 ya cobrado') || 'no lo marca: ' + t.slice(0,200);
});
await caso('deshacer llama a cuenta_pago_parcial_deshacer', async () => {
  await page.evaluate(()=>{ window.__rpc = [];
    window.preguntar = () => Promise.resolve(true); });
  await page.click('[data-pardeshacer]'); await page.waitForTimeout(800);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_pago_parcial_deshacer'));
  return !!r || 'no lo llamó';
});
await caso('y el pago vuelve a pedir los 10.000 completos', async () => {
  const v = await page.evaluate(()=>{
    const i = document.querySelector('[data-cobmonto]'); return i ? i.value : null; });
  return (v && String(v).replace(/\./g,'') === '10000') || 'quedó en ' + v;
});

console.log('\nEL DESCUENTO SE REPARTE, y la pantalla dice lo mismo que la base:');
await caso('con 20 % puesto, un café de 3.200 se cobra 2.560', async () => {
  await montar({});
  await page.evaluate(()=>{
    /* el descuento vive en la cuenta (C5) */
    const c = window.__T && window.__T.cuentas; });
  await page.click('[data-lamamesa="101"]'); await page.waitForTimeout(500);
  /* se aplica desde el panel, que es el camino real */
  await page.click('[data-lamaacc="desc-p-abrir"]'); await page.waitForTimeout(300);
  await page.selectOption('[data-descampo="motivo"]', 'empleado');
  await page.fill('[data-descampo="valor"]', '20');
  await page.click('[data-lamaacc="desc-p-aplicar"]'); await page.waitForTimeout(500);
  await page.click('[data-lamaacc="cobrar"]'); await page.waitForTimeout(600);
  await page.click('[data-lamaacc="par-entrar"]'); await page.waitForTimeout(350);
  await page.click('[data-parmas="1"]'); await page.waitForTimeout(300);
  const t = await pie();
  return t.includes('2.560') || 'el Total Seleccionado dice: ' + t;
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', async () =>
  errores.length === 0 || errores.join(' \u00b7 '));

console.log(`\n${ok} bien \u00b7 ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
