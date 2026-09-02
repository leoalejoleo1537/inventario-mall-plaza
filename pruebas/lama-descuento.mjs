/* LLAMITA LAMA · C5 — el descuento desde el panel de la mesa.
   node pruebas/lama-descuento.mjs

   LA REGLA QUE SE PRUEBA, y es de arqueo antes que de pantalla:

       HAY UN SOLO DESCUENTO POR CUENTA, VISTO EN DOS LUGARES.

   El garzón lo aplica desde el panel mientras atiende, y la ventana de cobro
   lo muestra ya puesto. Si se cambia en un lado cambia en el otro, porque no
   son dos descuentos: es uno. Dos que se apilen le dejan al arqueo dos cifras
   que pueden no cuadrar, y obligan a decidir qué pasa cuando entre los dos el
   total llega a cero.

   POR ESO LO QUE MÁS SE PRUEBA ACÁ NO ES LA CAJITA, ES DÓNDE VIVE EL DATO.
   El descuento se escribe en las columnas `descuento_*` de `cuentas`. Si
   viviera en la pantalla —como vivía hasta hoy dentro de `LAMA_COB`— se
   perdería al cerrar la ventana, y aplicarlo desde el panel sería imposible.
   Las pruebas miran el `update` que sale a la base, no el HTML.

   Y se prueba el INTERRUPTOR APAGADO (§2.2), que es la mitad que se olvida:
   apagado tiene que quedar EXACTAMENTE lo que había antes —el descuento se
   sigue aplicando desde la ventana de cobro— y no un hueco.

   Los números: 2×3.200 + 1×3.600 = 10.000. Un 20 % son 2.000, y el total
   queda en 8.000.                                                          */
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

async function montar({conMigracion = true, archivo = 'index.html'} = {}){
  await page.addInitScript(({MESAS, CUENTAS, ITEMS, CARTA, MEDIOS, MOTIVOS, conMigracion}) => {
    window.__rpc = [];
    window.__upd = [];
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
        update(v){ window.__upd.push({tabla:n, datos:v});
          const e={eq:()=>e,in:()=>e,select:()=>e,
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

const abrirMesa = async () => {
  await page.click('[data-lamamesa="101"]'); await page.waitForTimeout(500);
};
const limpiar = () => page.evaluate(()=>{ window.__upd = []; });
/* `avisar()` NO es un toast: abre la ventana modal de la app, que tapa el
   panel hasta que alguien la cierra. Costó media prueba descubrirlo — todos
   los clics siguientes daban timeout, y parecía un bug de la caja del
   descuento cuando en realidad era el aviso haciendo bien su trabajo.
   Así que se cierra, y de paso se comprueba que HAYA aparecido: que avise es
   parte de lo que se está probando. */
async function cerrarAviso(){
  const abierto = await page.isVisible('#overlay-ask');
  if(abierto){ await page.click('#ask-ok'); await page.waitForTimeout(250); }
  return abierto;
}
const ultimoUpd = () => page.evaluate(()=>window.__upd[window.__upd.length-1] || null);

await montar({});
await abrirMesa();

console.log('\nLa caja nace cerrada y está DEBAJO de "Cerrar mesa":');
await caso('no se ve la caja hasta que se toca', async () =>
  !(await page.isVisible('#lama-desc')) || 'la caja nace abierta');
await caso('ofrece aplicar un descuento', async () =>
  (await page.textContent('[data-lamaacc="desc-p-abrir"]')).includes('Aplicar un descuento')
  || 'no ofrece el descuento');
/* Debajo, no encima: se compara con los rectángulos de verdad, no con el CSS. */
await caso('está por debajo del botón de cerrar la mesa', async () => {
  const r = await page.evaluate(()=>{
    const b = document.querySelector('[data-lamaacc="cobrar"]').getBoundingClientRect();
    const d = document.querySelector('[data-lamaacc="desc-p-abrir"]').getBoundingClientRect();
    return {abajo: d.top >= b.bottom - 1};
  });
  return r.abajo || 'la caja quedó arriba del botón';
});

console.log('\nSe despliega HACIA ABAJO, nunca superpuesta:');
await caso('al abrirla, "Cerrar mesa" NO se mueve', async () => {
  const antes = await page.evaluate(()=>
    Math.round(document.querySelector('[data-lamaacc="cobrar"]').getBoundingClientRect().top));
  await page.click('[data-lamaacc="desc-p-abrir"]'); await page.waitForTimeout(350);
  const despues = await page.evaluate(()=>
    Math.round(document.querySelector('[data-lamaacc="cobrar"]').getBoundingClientRect().top));
  return antes === despues || `el botón saltó de ${antes} a ${despues}`;
});
await caso('y la caja no se monta sobre nada', async () => {
  const r = await page.evaluate(()=>{
    const b = document.querySelector('[data-lamaacc="cobrar"]').getBoundingClientRect();
    const d = document.querySelector('#lama-desc').getBoundingClientRect();
    return {pos: getComputedStyle(document.querySelector('#lama-desc')).position,
            encima: d.top < b.bottom - 1};
  });
  return (!r.encima && r.pos !== 'absolute' && r.pos !== 'fixed')
    || 'se superpone: ' + JSON.stringify(r);
});

console.log('\nNo deja aplicar un descuento a medias:');
await limpiar();
await caso('sin motivo no escribe nada, y lo dice', async () => {
  await page.fill('[data-descampo="valor"]', '20');
  await page.click('[data-lamaacc="desc-p-aplicar"]'); await page.waitForTimeout(300);
  const aviso = await cerrarAviso();
  if(!aviso) return 'no avisó: se quedó callado';
  return (await page.evaluate(()=>window.__upd.length)) === 0 || 'guardó sin motivo';
});
await caso('sin valor tampoco, y también lo dice', async () => {
  await page.selectOption('[data-descampo="motivo"]', 'empleado');
  await page.fill('[data-descampo="valor"]', '0');
  await page.click('[data-lamaacc="desc-p-aplicar"]'); await page.waitForTimeout(300);
  const aviso = await cerrarAviso();
  if(!aviso) return 'no avisó: se quedó callado';
  return (await page.evaluate(()=>window.__upd.length)) === 0 || 'guardó sin valor';
});

console.log('\nAplicar lo escribe EN LA CUENTA, no en la pantalla:');
await caso('guarda motivo, formato y valor en cuentas', async () => {
  await page.fill('[data-descampo="valor"]', '20');
  await page.click('[data-lamaacc="desc-p-aplicar"]'); await page.waitForTimeout(500);
  const u = await ultimoUpd();
  return (u && u.tabla === 'cuentas' && u.datos.descuento_motivo === 'empleado'
          && u.datos.descuento_formato === 'pct' && +u.datos.descuento_valor === 20)
    || 'escribió ' + JSON.stringify(u);
});
await caso('la caja se cierra sola al aplicar', async () =>
  !(await page.isVisible('#lama-desc')) || 'quedó abierta');

console.log('\nSe refleja en la suma del panel:');
await caso('aparece la línea "Descuento 20 % · −$2.000"', async () => {
  const t = (await page.textContent('.lama-desc-linea')).replace(/\s+/g,' ').trim();
  return (t.includes('20') && t.includes('2.000')) || 'la línea dice: ' + t;
});
await caso('y el total baja de 10.000 a 8.000', async () => {
  const t = await page.textContent('.lama-total');
  return t.includes('8.000') || 'el total dice: ' + t;
});
await caso('el botón ahora nombra el descuento puesto', async () => {
  const t = await page.textContent('[data-lamaacc="desc-p-abrir"]');
  return (t.includes('Descuento') && t.includes('2.000')) || 'dice: ' + t;
});

console.log('\nCancelar NO borra lo que ya estaba guardado:');
await caso('cancelar no escribe en la base', async () => {
  await page.click('[data-lamaacc="desc-p-abrir"]'); await page.waitForTimeout(300);
  await limpiar();
  await page.click('[data-lamaacc="desc-p-cancelar"]'); await page.waitForTimeout(300);
  return (await page.evaluate(()=>window.__upd.length)) === 0 || 'cancelar borró el descuento';
});
await caso('y el descuento sigue puesto', async () =>
  (await page.textContent('.lama-total')).includes('8.000') || 'se perdió el descuento');

console.log('\nQuitar sí lo saca:');
await caso('escribe los tres campos en null', async () => {
  await page.click('[data-lamaacc="desc-p-abrir"]'); await page.waitForTimeout(300);
  await limpiar();
  await page.click('[data-lamaacc="desc-p-quitar"]'); await page.waitForTimeout(500);
  const u = await ultimoUpd();
  return (u && u.datos.descuento_motivo === null && u.datos.descuento_formato === null
          && u.datos.descuento_valor === null) || 'escribió ' + JSON.stringify(u);
});
await caso('y el total vuelve a 10.000', async () =>
  (await page.textContent('.lama-total')).includes('10.000') || 'no volvió el total');

console.log('\nLA VENTANA DE COBRO LO VE PUESTO — es la mitad que importa:');
await caso('se aplica un 20 % desde el panel', async () => {
  await page.click('[data-lamaacc="desc-p-abrir"]'); await page.waitForTimeout(300);
  await page.selectOption('[data-descampo="motivo"]', 'cumple');
  await page.fill('[data-descampo="valor"]', '20');
  await page.click('[data-lamaacc="desc-p-aplicar"]'); await page.waitForTimeout(500);
  return (await page.textContent('.lama-total')).includes('8.000') || 'no se aplicó';
});
await caso('el cobro nace con el descuento ya puesto', async () => {
  await page.click('[data-lamaacc="cobrar"]'); await page.waitForTimeout(600);
  const t = await page.textContent('.lama-cob-caja');
  return (t.includes('Cumpleaños') && t.includes('2.000')) || 'el cobro no lo muestra';
});
/* Es lo que de verdad se toca en el mesón: si el monto no viniera descontado,
   el garzón cobraría 10.000 con un descuento aplicado. */
/* OJO CON EL SELECTOR: desde que la propina del 10 % nace puesta, el PRIMER
   `[data-cobmonto]` del DOM es la propina, no el pago. Hay que pedir el pago
   por su nombre o se lee el número equivocado. */
await caso('y el monto a cobrar ya viene descontado: 8.000 + 800 de propina', async () => {
  const v = await page.evaluate(()=>{
    const i = document.querySelector('[data-cobmonto="pago"]'); return i ? i.value : null; });
  return (v && String(v).replace(/\./g,'') === '8800') || 'el monto precargado es ' + v;
});

console.log('\nEL INTERRUPTOR APAGADO deja lo de antes, no un hueco (§2.2):');
await caso('sin la caja en el panel, pero el cobro la sigue teniendo', async () => {
  const fs = await import('node:fs');
  const apagado = join(raiz, 'index-desc-apagado.html');
  fs.writeFileSync(apagado, fs.readFileSync(join(raiz,'index.html'),'utf8')
    .replace('const LAMA_DESC_EN_PANEL = true;', 'const LAMA_DESC_EN_PANEL = false;'));
  try{
    await montar({archivo:'index-desc-apagado.html'});
    await abrirMesa();
    const hayPanel = await page.isVisible('[data-lamaacc="desc-p-abrir"]');
    await page.click('[data-lamaacc="cobrar"]'); await page.waitForTimeout(600);
    const hayCobro = await page.isVisible('[data-lamaacc="desc-abrir"]');
    if(hayPanel) return 'apagado y la caja del panel sigue ahí';
    if(!hayCobro) return 'apagado dejó un hueco: el cobro se quedó SIN descuento';
    return true;
  } finally { try{ fs.unlinkSync(apagado); }catch{} }
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', async () =>
  errores.length === 0 || errores.join(' · '));

console.log(`\n${ok} bien \u00b7 ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
