/* LLAMITA LAMA · anular un producto que ya salió a la cocina.
   node pruebas/lama-anular.mjs

   ES UN SOLO CONCEPTO, y de él salen las tres cosas que se prueban acá:

     C7 · sumar un producto ya enviado NO cambia esa línea: crea una línea
          nueva pendiente, con su Confirmar
     C9 · quitarlo NO lo borra: lo tacha, lo apaga y pide el motivo
     C10 · y por eso la mesa entera tampoco se vacía de un golpe

   LA RAZÓN ES DE NEGOCIO, no de pantalla: lo que salió de la cocina existió.
   Costó insumos y alguien lo preparó. Si desaparece de la lista, el arqueo
   pierde el rastro y nadie puede responder por qué el inventario no cuadra al
   final del turno. Por eso la prueba que más importa es una sola: que el
   producto anulado SIGA EN LA LISTA.                                        */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const MESAS = Array.from({length:8}, (_,i)=>({
  id:100+i, sede:'plaza', salon:'Salón', numero:i+1, orden:i+1, activa:true }));
const CUENTAS = [
  {id:900, sede:'plaza', mesa_id:101, estado:'abierta', total:9400, abierta_por:'jhon@cafe.cl'},
];
/* Uno ya enviado, uno todavía pendiente y uno ya anulado: los tres estados
   se ven de entrada, sin tener que provocarlos. */
const ITEMS = [
  {id:1, cuenta_id:900, fudo_product_id:'F-40', nombre:'Café Cortado', cantidad:1,
   precio:3000, estado:'confirmado', comentario:null, anulado_at:null},
  {id:2, cuenta_id:900, fudo_product_id:'F-38', nombre:'Café Latte', cantidad:1,
   precio:3400, estado:'confirmado', comentario:null, anulado_at:null},
  {id:3, cuenta_id:900, fudo_product_id:'F-33', nombre:'Americano', cantidad:1,
   precio:3000, estado:'nuevo', comentario:null, anulado_at:null},
];
const CARTA = [
  {fudo_product_id:'F-33', sede:'plaza', nombre:'Americano',    precio:3000, activo:true},
  {fudo_product_id:'F-38', sede:'plaza', nombre:'Café Latte',   precio:3400, activo:true},
  {fudo_product_id:'F-40', sede:'plaza', nombre:'Café Cortado', precio:3000, activo:true},
];
const MOTIVOS_ANU = [
  {codigo:'error_registro', nombre:'Error de registro',      orden:1, pide_comentario:false, activo:true},
  {codigo:'no_disponible',  nombre:'Producto no disponible', orden:2, pide_comentario:false, activo:true},
  {codigo:'cambio',         nombre:'Cambio de producto',     orden:3, pide_comentario:false, activo:true},
  {codigo:'cliente',        nombre:'Cancelado por cliente',  orden:4, pide_comentario:false, activo:true},
  {codigo:'prueba',         nombre:'Prueba',                 orden:5, pide_comentario:false, activo:true},
  {codigo:'otro',           nombre:'Otro',                   orden:9, pide_comentario:true,  activo:true},
];

const page = await browser.newPage();
await page.setViewportSize({width:1280, height:900});

async function montar({conMigracion = true} = {}){
  await page.addInitScript(({MESAS, CUENTAS, ITEMS, CARTA, MOTIVOS_ANU, conMigracion}) => {
    window.__rpc = [];
    const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
    /* La base de mentira guarda los items en vivo: anular tiene que poder
       marcar la fila y que la siguiente lectura la traiga marcada. Sin eso no
       se estaría probando nada. */
    const VIVOS = JSON.parse(JSON.stringify(ITEMS));
    const T = {
      productos:[], mesas:MESAS, cuentas:CUENTAS, cuenta_items:VIVOS, comandas:[],
      fudo_productos:CARTA,
      lama_medios_pago:[], lama_motivos_descuento:[],
      /* Sin la migración corrida esta tabla NO existe: es el estado real de
         la base hasta que Jhon pegue el .sql. */
      lama_motivos_anulacion: conMigracion ? MOTIVOS_ANU : null,
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
        delete(){ let cond=null;
          const e={eq:(c,v)=>{cond={c,vs:[String(v)]};return e;},
                   in:(c,vs)=>{cond={c,vs:vs.map(String)};return e;},
                   then:f=>{ if(n==='cuenta_items' && cond){
                       for(let k=VIVOS.length-1;k>=0;k--)
                         if(cond.vs.includes(String(VIVOS[k][cond.c]))) VIVOS.splice(k,1);
                     }
                     return Promise.resolve({data:[],error:null}).then(f); }};
          return e; },
        then(f){return Promise.resolve({data: falta?null:filas, error:err, count:filas.length}).then(f);},
      };
      return api;
    };
    window.supabase = { createClient: () => ({
      from:q,
      rpc:(nombre, args)=>{
        window.__rpc.push({nombre, args});
        if(nombre === 'item_anular'){
          if(!conMigracion)
            return Promise.resolve({data:null,
              error:{message:'function public.item_anular(...) does not exist', code:'42883'}});
          const it = VIVOS.find(x => x.id === args.p_item_id);
          if(!it) return Promise.resolve({data:null, error:{message:'no existe'}});
          it.anulado_at = new Date().toISOString();
          it.anulado_por = args.p_quien;
          it.anulado_motivo = args.p_motivo;
          it.anulado_comentario = args.p_comentario;
          return Promise.resolve({data:JSON.parse(JSON.stringify(it)), error:null});
        }
        if(nombre === 'cuenta_agregar'){
          const fila = {id:++seq, cuenta_id:args.p_cuenta_id, fudo_product_id:args.p_fudo_id,
                        nombre:args.p_nombre, cantidad:1, precio:args.p_precio,
                        estado:'nuevo', comentario:args.p_comentario, anulado_at:null};
          VIVOS.push(fila);
          return Promise.resolve({data:JSON.parse(JSON.stringify(fila)), error:null});
        }
        if(nombre === 'cuenta_recalcular') return Promise.resolve({data:0, error:null});
        return Promise.resolve({data:null, error:null});
      },
      auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
             onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
             signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
      channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
      removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
    })};
  }, {MESAS, CUENTAS, ITEMS, CARTA, MOTIVOS_ANU, conMigracion});
  await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
  await page.goto(pathToFileURL(join(raiz,'index.html')).href);
  await page.waitForTimeout(400);
  await page.click('.gate-btn[data-sede="plaza"]');
  await page.waitForTimeout(700);
  await page.click('#tabLama'); await page.waitForTimeout(500);
  await page.click('[data-lamamesa="101"]'); await page.waitForTimeout(450);
}

const errores = [];
page.on('pageerror', e=>errores.push(String(e)));

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};
const cuantasLineas = async () =>
  await page.evaluate(() => document.querySelectorAll('.lama-linea').length);

await montar();

console.log('\nC10 · LA MESA NO SE VACÍA DE UN GOLPE:');
await caso('ya no está el botón que borraba todo lo pendiente', async () =>
  !(await page.isVisible('[data-lamaacc="cancelar"]')) || 'sigue ahí');
await caso('pero Confirmar sí sigue, que es lo que manda a la cocina', async () =>
  await page.isVisible('[data-lamaacc="confirmar"]') || 'se perdió Confirmar');
/* Sacar productos se hace de a uno: el ✕ de cada línea pendiente. */
await caso('cada línea pendiente conserva su ✕ para sacarla de a una', async () =>
  await page.isVisible('[data-lamaquitar="3"]') || 'la línea pendiente no tiene ✕');

console.log('\nC7 · SUMAR EN UNA LÍNEA YA ENVIADA CREA UNA LÍNEA NUEVA:');
/* EL CAMINO CAMBIÓ EL 2026-09-02, la regla NO. Los botones − + se fueron de la
   línea porque se comían el ancho y el nombre quedaba en "C…" — y Fudo tampoco
   los tiene ahí. Para sumar otro de algo ya enviado se usa el buscador o su
   píldora, que es lo que hace el equipo en Fudo. Lo que esta prueba protege
   sigue siendo lo mismo: que se cree una línea NUEVA y que la ya enviada no se
   toque. */
await caso('sumar otro de lo ya enviado, desde el buscador', async () => {
  const antes = await page.evaluate(() => window.__rpc.length);
  await page.fill('#lama-qp', 'Cortado'); await page.waitForTimeout(350);
  await page.click('.lama-qp-lista .lama-prod'); await page.waitForTimeout(700);
  const r = await page.evaluate(() => window.__rpc.map(x => x.nombre).slice(-3));
  return r.includes('cuenta_agregar') || 'llamó a: ' + r.join(' · ') + ' (antes ' + antes + ')';
});
/* Lo que NO puede pasar es que la línea que ya salió pase de 1 a 2: la cocina
   preparó una, y esa segunda hay que mandarla. */
await caso('y la línea que ya salió sigue en 1, sin tocar', async () => {
  const n = await page.evaluate(() => {
    const l = [...document.querySelectorAll('.lama-linea')]
      .find(x => !x.closest('.lama-pend') && x.textContent.includes('Café Cortado'));
    return l ? l.querySelector('.q').textContent.trim() : null; });
  return n === '1' || 'la línea ya enviada quedó en ' + n;
});
await caso('la nueva aparece en Pendiente, esperando Confirmar', async () => {
  const t = await page.textContent('.lama-pend');
  return t.includes('Café Cortado') || 'Pendiente dice: ' + t.replace(/\s+/g,' ').slice(0,120);
});

console.log('\nC9 · ANULAR: el motivo, y que el producto NO desaparezca:');
await caso('el ✕ de un producto ya enviado abre la ventana del motivo', async () => {
  await page.click('[data-lamaquitar="2"]'); await page.waitForTimeout(450);
  return await page.isVisible('.lama-anu-caja') || 'no se abrió la ventana';
});
await caso('ofrece los seis motivos', async () => {
  const n = await page.evaluate(() => document.querySelectorAll('[data-anumotivo]').length);
  return n === 6 || 'hay ' + n + ' motivos';
});
await caso('no deja anular sin elegir un motivo', async () =>
  await page.evaluate(() =>
    document.querySelector('[data-lamaacc="anu-confirmar"]').disabled)
  || 'se puede anular sin decir por qué');
/* "Otro" sin detalle es un dato que no sirve para nada. */
await caso('con "Otro" exige el detalle escrito', async () => {
  await page.click('[data-anumotivo="otro"]'); await page.waitForTimeout(300);
  return await page.evaluate(() =>
    document.querySelector('[data-lamaacc="anu-confirmar"]').disabled)
    || '"Otro" se puede anular sin escribir nada';
});
await caso('y con el detalle escrito ya deja', async () => {
  await page.fill('#lama-anu-com', 'se cayó la bandeja'); await page.waitForTimeout(300);
  return !(await page.evaluate(() =>
    document.querySelector('[data-lamaacc="anu-confirmar"]').disabled))
    || 'sigue sin dejar';
});
await caso('con un motivo que se explica solo, el detalle es opcional', async () => {
  await page.click('[data-anumotivo="no_disponible"]'); await page.waitForTimeout(300);
  await page.fill('#lama-anu-com', ''); await page.waitForTimeout(250);
  return !(await page.evaluate(() =>
    document.querySelector('[data-lamaacc="anu-confirmar"]').disabled))
    || 'pide detalle donde no hace falta';
});
await caso('le manda a la base el item y el motivo', async () => {
  await page.click('[data-lamaacc="anu-confirmar"]'); await page.waitForTimeout(700);
  const a = await page.evaluate(() =>
    (window.__rpc.filter(x => x.nombre === 'item_anular').pop() || {}).args);
  if(!a) return 'no llamó a item_anular';
  return (a.p_item_id === 2 && a.p_motivo === 'no_disponible')
    || 'mandó: ' + JSON.stringify(a);
});

console.log('\nLA QUE MÁS IMPORTA · el producto anulado NO desaparece:');
await caso('sigue en la lista', async () => {
  const t = await page.textContent('.lama-cuerpo');
  return t.includes('Café Latte') || 'se borró de la lista';
});
await caso('y se ve tachado y apagado', async () => {
  const r = await page.evaluate(() => {
    const l = [...document.querySelectorAll('.lama-linea')]
      .find(x => x.textContent.includes('Café Latte'));
    if(!l) return null;
    const nb = l.querySelector('.nm b');
    return {anulada:l.classList.contains('anulada'),
            tachado:getComputedStyle(nb).textDecorationLine,
            op:parseFloat(getComputedStyle(l).opacity)};
  });
  if(!r) return 'no encontré la línea';
  return (r.anulada && r.tachado.includes('line-through') && r.op < 1)
    || JSON.stringify(r);
});
await caso('dice por qué no salió', async () => {
  const t = await page.textContent('.lama-motivo');
  return t.includes('Producto no disponible') || 'el motivo dice: ' + t;
});
await caso('y ya no se le puede cambiar la cantidad ni volver a quitar', async () => {
  /* Desde que los − + se fueron de la línea, "no se puede cambiar la cantidad"
     se comprueba de otra forma y más fuerte: la línea anulada NO abre la
     ventana del producto (no lleva `data-lamaprod`) y no tiene ✕. */
  const r = await page.evaluate(() => {
    const l = [...document.querySelectorAll('.lama-linea')]
      .find(x => x.textContent.includes('Café Latte'));
    if(!l) return null;
    return {tocable:!!l.querySelector('[data-lamaprod]'), x:!!l.querySelector('button.x')};
  });
  if(!r) return 'no encontré la línea';
  return (r.tocable === false && r.x === false) || JSON.stringify(r);
});

console.log('\nY DEJA DE COBRARSE:');
/* La plata es lo que no puede quedar mal: el total de la pantalla y el que
   calcula la base tienen que decir lo mismo. */
await caso('el total del panel baja: ya no cuenta el anulado', async () => {
  const t = await page.textContent('.lama-suma');
  /* La cuenta, para poder seguirla: empezo en 9.400 (Cortado 3.000 + Latte
     3.400 + Americano 3.000). El + de C7 agrego otro Cortado (+3.000) y
     anular el Latte lo saca (-3.400). Quedan 9.000. Lo que NO puede pasar
     es que el total siga contando el Latte. */
  return (!t.includes('9.400') && t.includes('9.000'))
    || 'el total dice: ' + t.replace(/\s+/g,' ');
});
await caso('y la ventana de cobro tampoco lo lista', async () => {
  await page.click('[data-lamaacc="cobrar"]'); await page.waitForTimeout(600);
  const t = await page.textContent('.lama-cob-cuerpo');
  return !t.includes('Café Latte') || 'aparece para cobrar algo que no salió';
});
await caso('Escape cierra la de anular antes que la de cobro', async () => {
  await page.evaluate(()=>document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape'})));
  await page.waitForTimeout(400);
  return !(await page.isVisible('.lama-cob-caja')) || 'no se cerró el cobro';
});

console.log('\nLO PENDIENTE ES OTRA COSA: se quita y ya, sin motivo:');
await caso('el ✕ de una línea pendiente no abre ninguna ventana', async () => {
  const antes = await cuantasLineas();
  await page.click('[data-lamaquitar="3"]'); await page.waitForTimeout(700);
  const vent = await page.isVisible('.lama-anu-caja');
  const ahora = await cuantasLineas();
  return (!vent && ahora < antes)
    || `ventana:${vent} lineas antes:${antes} ahora:${ahora}`;
});

console.log('\nSIN LA MIGRACIÓN CORRIDA:');
await montar({conMigracion:false});
await caso('la ventana igual se abre, con los motivos de fábrica', async () => {
  await page.click('[data-lamaquitar="2"]'); await page.waitForTimeout(500);
  const n = await page.evaluate(() => document.querySelectorAll('[data-anumotivo]').length);
  return n === 6 || 'hay ' + n + ' motivos';
});
/* Lo que NO puede pasar es caer al camino viejo y borrar la línea: perder el
   motivo es exactamente lo que se vino a arreglar. */
await caso('pero NO anula ni borra: avisa que falta correr el .sql', async () => {
  const antes = await cuantasLineas();
  await page.click('[data-anumotivo="prueba"]'); await page.waitForTimeout(300);
  await page.click('[data-lamaacc="anu-confirmar"]'); await page.waitForTimeout(600);
  const t = await page.textContent('body');
  const ahora = await cuantasLineas();
  return (t.includes('Todavía no se puede anular') && ahora === antes)
    || `aviso:${t.includes('Todavía no se puede anular')} lineas ${antes}→${ahora}`;
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () =>
  errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
