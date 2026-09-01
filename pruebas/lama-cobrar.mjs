/* LLAMITA LAMA · la ventana de cobro.
   node pruebas/lama-cobrar.mjs

   ES LA PARTE MÁS DELICADA DEL PROCESO: acá la venta queda registrada, y de
   acá se va a alimentar el arqueo de caja. Un error de pantalla en cualquier
   otro lado se corrige; uno acá cierra una mesa por el monto equivocado y
   nadie se entera hasta que la caja no cuadra al final del turno.

   LO QUE SE PRUEBA son las cinco reglas que dictó Jhon, porque son las que
   protegen la plata:

     1. el vuelto NUNCA es negativo — si falta, la mesa no se cierra
     2. en el pago va el TOTAL con la propina adentro
     3. el monto nace precargado con el total exacto
     4. cambiar el medio del pago arrastra la propina, pero se puede soltar
     5. el + de la propina absorbe el excedente

   Y una sexta que no es de plata pero es de Jhon igual: la ventana es
   EMERGENTE, no una pantalla. */
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

async function montar({conMigracion = true} = {}){
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
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

/* Abre la mesa 2 (cuenta 900, subtotal 10.000) y su ventana de cobro. */
async function abrirCobro(){
  await page.click('[data-lamamesa="101"]'); await page.waitForTimeout(350);
  await page.click('[data-lamaacc="cobrar"]'); await page.waitForTimeout(450);
}
const monto = async (tipo, i) => await page.evaluate(({tipo,i}) => {
  const el = document.querySelector(`[data-cobmonto="${tipo}"][data-i="${i}"]`);
  return el ? parseInt(el.value.replace(/[^\d]/g,''),10) || 0 : null;
}, {tipo, i});
const escribir = async (tipo, i, v) => {
  await page.fill(`[data-cobmonto="${tipo}"][data-i="${i}"]`, String(v));
  await page.waitForTimeout(250);
};

await montar();

console.log('\nQUE EXISTA, y que sea una VENTANA:');
await caso('"Cerrar mesa" con productos abre la ventana de cobro', async () => {
  await abrirCobro();
  return await page.isVisible('.lama-cob-caja') || 'no se abrió nada';
});
/* Pedido textual de Jhon: "que este apartado sea solo emergente, y no ocupe
   toda la pantalla". */
await caso('es emergente y NO ocupa toda la pantalla', async () => {
  const r = await page.evaluate(() => {
    const c = document.querySelector('.lama-cob-caja'); if(!c) return null;
    const b = c.getBoundingClientRect();
    return {an:b.width, al:b.height, vw:innerWidth, vh:innerHeight};
  });
  if(!r) return 'no está la caja';
  return (r.an < r.vw * 0.75 && r.al <= r.vh * 0.92)
    || `ocupa ${Math.round(r.an)}×${Math.round(r.al)} de ${r.vw}×${r.vh}`;
});
await caso('se sigue viendo el plano de mesas detrás', async () =>
  await page.isVisible('#lama-mesas') || 'la ventana reemplazó la pantalla');
await caso('ningún elemento de la ventana lleva reborde', async () => {
  const n = await page.evaluate(() => [...document.querySelectorAll('.lama-cob-caja *')]
    .filter(el => { const s = getComputedStyle(el);
      return parseFloat(s.borderTopWidth) > 0 || parseFloat(s.borderLeftWidth) > 0; }).length);
  return n === 0 || n + ' elementos con reborde';
});

console.log('\nREGLA 3 · el monto nace con el total exacto:');
await caso('el pago viene precargado en $10.000', async () =>
  await monto('pago', 0) === 10000 || 'vino en ' + await monto('pago', 0));
await caso('y el botón dice cuánto se va a cobrar', async () => {
  const t = await page.textContent('[data-lamaacc="cob-confirmar"]');
  return t.includes('10.000') || 'dice: ' + t;
});
await caso('el vuelto arranca en cero, o sea cuadra', async () => {
  const c = await page.getAttribute('.lama-cob-vuelto', 'class');
  return c.includes('cuadra') || 'la clase es: ' + c;
});

console.log('\nREGLA 1 · el vuelto nunca es negativo:');
await caso('pagando de menos, el botón se apaga', async () => {
  await escribir('pago', 0, 8000);
  return await page.evaluate(() =>
    document.querySelector('[data-lamaacc="cob-confirmar"]').disabled) || 'sigue habilitado';
});
/* Un botón gris y mudo no dice qué hacer. Este dice cuánto falta. */
await caso('y dice cuánto falta, en vez de quedarse mudo', async () => {
  const t = await page.textContent('[data-lamaacc="cob-confirmar"]');
  return t.includes('Faltan') && t.includes('2.000') || 'dice: ' + t;
});
await caso('el aviso de arriba también lo dice', async () => {
  const t = await page.textContent('.lama-cob-vuelto');
  return t.includes('Falta') && t.includes('2.000') || 'dice: ' + t;
});

console.log('\nREGLA 5 · el + de la propina absorbe el excedente:');
/* El caso entero que dictó Jhon: total 11.000, el cliente paga 12.000, el
   sobrante se manda a propina y el vuelto queda en 0. */
await caso('pagando de más, aparece el vuelto', async () => {
  await escribir('pago', 0, 12000);
  const t = await page.textContent('.lama-cob-vuelto');
  return t.includes('Vuelto') && t.includes('2.000') || 'dice: ' + t;
});
await caso('el + manda el excedente a la propina', async () => {
  await page.click('[data-lamaacc="cob-mas-propina"]'); await page.waitForTimeout(300);
  return await monto('propina', 0) === 2000 || 'la propina quedó en ' + await monto('propina', 0);
});
await caso('y entonces el vuelto queda en cero', async () => {
  const c = await page.getAttribute('.lama-cob-vuelto', 'class');
  return c.includes('cuadra') || 'la clase es: ' + c;
});
/* REGLA 2 — lo que se cobra incluye la propina. */
await caso('el total a cobrar ya trae la propina adentro', async () => {
  const t = await page.textContent('[data-lamaacc="cob-confirmar"]');
  return t.includes('12.000') || 'dice: ' + t;
});

console.log('\nREGLA 4 · el medio del pago arrastra la propina, y se suelta:');
await caso('cambiar el pago a débito lleva la propina a débito', async () => {
  await page.selectOption('[data-cobsel="pago"][data-i="0"]', 'debito');
  await page.waitForTimeout(300);
  const p = await page.evaluate(() =>
    document.querySelector('[data-cobsel="propina"][data-i="0"]').value);
  return p === 'debito' || 'la propina quedó en ' + p;
});
/* El caso de todos los días: cuenta en débito, propina en efectivo. */
await caso('pero tocar la propina la suelta del pago', async () => {
  await page.selectOption('[data-cobsel="propina"][data-i="0"]', 'efectivo');
  await page.waitForTimeout(250);
  await page.selectOption('[data-cobsel="pago"][data-i="0"]', 'efectivo');
  await page.waitForTimeout(250);
  await page.selectOption('[data-cobsel="pago"][data-i="0"]', 'debito');
  await page.waitForTimeout(300);
  const p = await page.evaluate(() =>
    document.querySelector('[data-cobsel="propina"][data-i="0"]').value);
  return p === 'efectivo' || 'la propina volvió a seguir al pago: ' + p;
});

console.log('\nEL DESCUENTO:');
await caso('se despliega HACIA ABAJO, no encima de nada', async () => {
  await page.click('[data-lamaacc="desc-abrir"]'); await page.waitForTimeout(300);
  const pos = await page.evaluate(() => {
    const d = document.querySelector('.lama-cob-desc'); if(!d) return null;
    return getComputedStyle(d).position;
  });
  return pos === 'static' || 'está posicionado como: ' + pos;
});
await caso('pide el motivo antes de aplicar', async () => {
  const hay = await page.evaluate(() =>
    !!document.querySelector('[data-cobdesc="motivo"]') &&
    !!document.querySelector('[data-cobdesc="formato"]') &&
    !!document.querySelector('[data-cobdesc="valor"]'));
  return hay || 'faltan campos: motivo, formato o valor';
});
await caso('un 20% sobre 10.000 descuenta 2.000', async () => {
  await page.selectOption('[data-cobdesc="motivo"]', 'empleado');
  await page.selectOption('[data-cobdesc="formato"]', 'pct');
  await page.fill('[data-cobdesc="valor"]', '20'); await page.waitForTimeout(200);
  await page.click('[data-lamaacc="desc-aplicar"]'); await page.waitForTimeout(350);
  const t = await page.textContent('.lama-cob-suma');
  return t.includes('2.000') || 'la suma dice: ' + t.replace(/\s+/g,' ').slice(0,120);
});
await caso('y el total baja a 10.000 (8.000 + 2.000 de propina)', async () => {
  const t = await page.textContent('.lama-cob-suma');
  return t.includes('10.000') || 'la suma dice: ' + t.replace(/\s+/g,' ').slice(0,120);
});

console.log('\nAL COBRAR, qué se le manda a la base:');
await caso('llama a cuenta_cobrar, no a cuenta_cerrar', async () => {
  await escribir('pago', 0, 10000);
  await page.click('[data-lamaacc="cob-confirmar"]'); await page.waitForTimeout(600);
  const r = await page.evaluate(() => window.__rpc.map(x => x.nombre));
  return (r.includes('cuenta_cobrar') && !r.includes('cuenta_cerrar'))
    || 'llamó a: ' + r.join(' · ');
});
await caso('y le manda el descuento, la propina y el pago', async () => {
  const a = await page.evaluate(() =>
    (window.__rpc.filter(x => x.nombre === 'cuenta_cobrar').pop() || {}).args);
  if(!a) return 'no hay llamada';
  return (a.p_desc_motivo === 'empleado' && a.p_desc_formato === 'pct' && +a.p_desc_valor === 20
          && a.p_propinas.length === 1 && a.p_pagos.length === 1)
    || 'mandó: ' + JSON.stringify(a).slice(0, 200);
});
await caso('la mesa vuelve a verde', async () => {
  const c = await page.getAttribute('[data-lamamesa="101"]', 'class');
  return c.includes('libre') || 'quedó como: ' + c;
});

console.log('\nLA MESA VACÍA no pasa por el cobro:');
await caso('se cierra directo, sin ventana', async () => {
  await page.click('[data-lamamesa="103"]'); await page.waitForTimeout(350);
  await page.click('[data-lamaacc="cobrar"]'); await page.waitForTimeout(500);
  const abierta = await page.isVisible('.lama-cob-caja');
  const r = await page.evaluate(() => window.__rpc.map(x => x.nombre));
  return (!abierta && r.includes('cuenta_cerrar'))
    || 'abrió la ventana para cobrar $0';
});

console.log('\nSIN LA MIGRACIÓN CORRIDA (la base de Jhon hasta que pegue el .sql):');
await montar({conMigracion:false});
await caso('la ventana igual se abre y se puede mirar', async () => {
  await abrirCobro();
  return await page.isVisible('.lama-cob-caja') || 'no se abrió';
});
await caso('los medios de pago salen igual, con los de fábrica', async () => {
  const n = await page.evaluate(() =>
    document.querySelectorAll('[data-cobsel="pago"][data-i="0"] option').length);
  return n === 12 || 'hay ' + n + ' medios, y tienen que ser los 12';
});
/* Lo que NO puede pasar es cerrar en silencio perdiendo el medio de pago:
   eso es exactamente lo que rompería el arqueo. */
await caso('al cobrar AVISA que el detalle no se va a guardar', async () => {
  await page.click('[data-lamaacc="cob-confirmar"]'); await page.waitForTimeout(500);
  const t = await page.textContent('body');
  return t.includes('no se guarda el detalle') || 'no avisó nada';
});
await caso('y no cerró la mesa sin preguntar', async () => {
  const r = await page.evaluate(() => window.__rpc.map(x => x.nombre));
  return !r.includes('cuenta_cerrar') || 'cerró igual, en silencio';
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () =>
  errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
