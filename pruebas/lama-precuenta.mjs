/* LLAMITA LAMA · F2 — con la precuenta impresa no se agrega nada.
   node pruebas/lama-precuenta.mjs

   POR QUÉ EXISTE ESTA REGLA, y es del negocio y no de la pantalla: el cliente
   tiene un papel en la mano con un total. Si la cuenta sigue creciendo por
   detrás, el papel y el sistema dicen cosas distintas — y eso se descubre al
   cobrar, discutiendo con el cliente delante de la caja.

   Sale del atlas E1: Fudo lo bloquea. Jhon eligió copiarlo, así que el equipo
   no tiene nada que aprender.

   LO QUE MÁS SE PRUEBA ACÁ NO ES EL CANDADO: ES LA SALIDA. Un candado sin
   salida visible es una pantalla trabada, y eso es peor que el problema que
   viene a resolver. Por eso se comprueba que la franja diga CÓMO volver, y que
   volviendo la mesa a Ocupada se pueda agregar de nuevo.

   Y se prueba el interruptor apagado (§2.2): tiene que quedar EXACTAMENTE lo
   de antes —se agrega con la precuenta impresa— y no un hueco.               */
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
  {id:900, sede:'plaza', mesa_id:101, estado:'precuenta', total:10000, abierta_por:'jhon@cafe.cl'},
  /* La 103 queda abierta y VACÍA: una mesa sin nada no abre la ventana. */
  {id:902, sede:'plaza', mesa_id:103, estado:'abierta', total:0,     abierta_por:'jhon@cafe.cl'},
];
const ITEMS = [
  {id:1, cuenta_id:900, nombre:'Café Latte',          cantidad:2, precio:3200, estado:'confirmado', comentario:null},
  {id:2, cuenta_id:900, nombre:'Torta de zanahoria',  cantidad:1, precio:3600, estado:'confirmado', comentario:null},
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

async function montar({conMigracion = true, archivo = 'index.html'} = {}){
  await page.addInitScript(({MESAS, CUENTAS, ITEMS, CARTA, MEDIOS, MOTIVOS, conMigracion}) => {
    window.__rpc = [];
    const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
    const T = {
      productos:[], mesas:MESAS, cuentas:CUENTAS, cuenta_items:ITEMS, comandas:[],
      fudo_productos:CARTA,
      /* Sin la migración corrida, estas dos tablas NO existen: es el estado
         real de la base de Jhon hasta que pegue el .sql. */
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
        /* EL update SIMULADO APLICA EL CAMBIO DE VERDAD. Con uno que no lo
           aplicaba, devolver la mesa a "Ocupada" no hacía nada y parecía un
           bug de la app: la prueba estaba midiendo la falta del mock. Acá el
           `.eq()` filtra Y escribe sobre la tabla en memoria, que es lo que
           haría la base. */
        update(v){
          const e = {
            eq(col, val){
              const tocadas = (T[n]||[]).filter(f => String(f[col]) === String(val));
              tocadas.forEach(f => Object.assign(f, v));
              filas = JSON.parse(JSON.stringify(tocadas));
              return e;
            },
            in:()=>e, select:()=>e,
            single:()=>Promise.resolve({data:filas[0]||null,error:null}),
            then:f=>Promise.resolve({data:filas,error:null}).then(f)};
          return e;
        },
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
  }, {MESAS, CUENTAS, ITEMS, CARTA, MEDIOS, MOTIVOS, conMigracion});
  await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
  await page.goto(pathToFileURL(join(raiz,archivo)).href);
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
const abrir = async () => {
  await page.click('[data-lamamesa="101"]'); await page.waitForTimeout(500);
};
/* OJO CON `page.evaluate(()=>lamaAgregar(...))`: la flecha DEVUELVE la promesa
   y Playwright la espera. Cuando la app abre el aviso modal, esa promesa no
   resuelve hasta que alguien lo cierra — y la prueba se cuelga para siempre.
   Con cuerpo de bloque `{ lamaAgregar(...); }` se dispara y no se espera. */
const cerrarAviso = async () => {
  const hay = await page.isVisible('#overlay-ask');
  if(hay){ await page.click('#ask-ok'); await page.waitForTimeout(250); }
  return hay;
};

await montar({});
await abrir();

console.log('\nLa mesa en precuenta no ofrece agregar:');
await caso('no está el buscador del panel', async () =>
  !(await page.isVisible('#lama-qp')) || 'sigue ofreciendo buscar');
await caso('en su lugar dice "Precuenta impresa"', async () =>
  (await page.textContent('.lama-trabada')).includes('Precuenta impresa')
  || 'no aparece la franja');
/* LO QUE DE VERDAD IMPORTA: que diga cómo salir. Un candado mudo traba la
   pantalla, y eso es peor que el problema que viene a resolver. */
await caso('y dice CÓMO volver, no solo que no se puede', async () => {
  const t = (await page.textContent('.lama-trabada')).replace(/\s+/g,' ');
  return (t.includes('Ocupada') && t.includes('volvé')) || 'la franja dice: ' + t;
});
await caso('el + de abajo se ve apagado', async () => {
  const c = await page.getAttribute('.lama-fab', 'class');
  return c.includes('trabada') || 'la clase del + es: ' + c;
});
/* Apagado, pero NO escondido: si desapareciera, quien lo busca creería que la
   app se rompió. */
await caso('pero sigue estando, no desaparece', async () =>
  (await page.isVisible('.lama-fab')) || 'el + desapareció');

console.log('\nY si igual se intenta, se niega y explica:');
await caso('el + no abre la carta: avisa', async () => {
  await page.click('.lama-fab'); await page.waitForTimeout(400);
  const aviso = await page.isVisible('#overlay-ask');
  const carta = await page.isVisible('.lama-carta');
  if(carta) return 'abrió la carta igual';
  if(!aviso) return 'no abrió la carta pero tampoco dijo nada';
  const t = await page.textContent('#overlay-ask');
  await cerrarAviso();
  return t.includes('Ocupada') || 'el aviso no dice cómo salir: ' + t;
});
/* El camino de fondo: aunque alguien llame a agregar desde donde sea —la
   carta, una píldora, el + de una línea ya confirmada— pasa por el mismo
   lugar y se niega igual. */
await caso('agregar por el camino de fondo tampoco pasa', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.evaluate(()=>{ lamaAgregar('F-38'); });   // sin await: ver la nota de arriba
  await page.waitForTimeout(400);
  await cerrarAviso();
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_agregar'));
  return !r || 'agregó igual a la cuenta';
});

console.log('\nLA SALIDA FUNCIONA — es la mitad que importa:');
await caso('volviendo la mesa a Ocupada, vuelve el buscador', async () => {
  await page.click('[data-lamaacc="precuenta"]'); await page.waitForTimeout(700);
  return (await page.isVisible('#lama-qp')) || 'no volvió el buscador';
});
await caso('y ahora sí se puede agregar', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.evaluate(()=>{ lamaAgregar('F-38'); });   // sin await: ver la nota de arriba
  await page.waitForTimeout(500);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_agregar'));
  return !!r || 'sigue sin dejar agregar con la mesa abierta';
});

console.log('\nEL INTERRUPTOR APAGADO deja lo de antes, no un hueco (§2.2):');
await caso('apagado, con la precuenta impresa se agrega igual', async () => {
  const fs = await import('node:fs');
  const off = join(raiz, 'index-precuenta-off.html');
  fs.writeFileSync(off, fs.readFileSync(join(raiz,'index.html'),'utf8')
    .replace('const LAMA_PRECUENTA_BLOQUEA = true;', 'const LAMA_PRECUENTA_BLOQUEA = false;'));
  try{
    await montar({archivo:'index-precuenta-off.html'});
    await abrir();
    if(await page.isVisible('.lama-trabada')) return 'apagado y la franja sigue ahí';
    if(!(await page.isVisible('#lama-qp'))) return 'apagado dejó un hueco: sin buscador';
    await page.evaluate(()=>{ window.__rpc = []; });
    await page.evaluate(()=>{ lamaAgregar('F-38'); });   // sin await: ver la nota de arriba
    await page.waitForTimeout(500);
    const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_agregar'));
    return !!r || 'apagado y aun así no deja agregar';
  } finally { try{ fs.unlinkSync(off); }catch{} }
});

console.log('\nEL VOCABULARIO, contra las palabras exactas de Fudo (atlas F1):');
await montar({});
await abrir();
await caso('la impresora dice "Imprimir control de mesa"', async () => {
  await page.click('[data-lamaacc="precuenta"]'); await page.waitForTimeout(700);
  const t = await page.getAttribute('[data-lamaacc="precuenta"]', 'title');
  return t === 'Imprimir control de mesa' || 'dice: ' + t;
});
await caso('el + de una mesa libre dice "Abrir mesa N"', async () => {
  await page.click('[data-lamamesa="104"]'); await page.waitForTimeout(500);
  const t = await page.getAttribute('.lama-fab', 'title');
  return t === 'Abrir mesa 5' || 'dice: ' + t;
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', async () =>
  errores.length === 0 || errores.join(' \u00b7 '));

console.log(`\n${ok} bien \u00b7 ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
