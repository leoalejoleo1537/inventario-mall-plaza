/* EL AVISO "LA FOTO AUTOMÁTICA NUNCA CORRIÓ" — EL BUG DEL 2026-08-25.
   node pruebas/red-de-respaldo.mjs

   Jhon corrió el SQL que instala la foto automática, `historial_auto` ya
   tenía fotos de verdad, y el aviso seguía en rojo diciendo "nunca corrió".
   No era una falsa alarma del negocio: el camino de respaldo de
   `ajCargarDias()` —el que se usa cuando la función `fotos_por_dia` todavía
   no está instalada— contaba SI había fotos, pero nunca guardaba CUÁNTAS.
   El aviso mira `d.auto`, y ese campo nunca se llenaba en ese camino: daba
   "nunca corrió" aunque hubiera fotos automáticas guardadas.

   Se prueban las DOS rutas: con la función instalada (el camino bueno de
   siempre) y sin ella (el camino de respaldo que tenía el defecto).      */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const hoy = () => new Date().toISOString().slice(0,10);
const haceDias = n => new Date(Date.now() - n*86400000).toISOString().slice(0,10);

// Plaza: fotos automáticas de HOY y AYER guardadas de verdad.
const HISTORIAL_AUTO = [
  {id:1, sede:'plaza', fecha:hoy()},
  {id:2, sede:'plaza', fecha:haceDias(1)},
];
// Angamos: nunca se instaló nada. Ahí el aviso SÍ tiene que seguir en rojo.
const HISTORIAL = [];

const page = await browser.newPage();
await page.setViewportSize({width:390, height:900});

async function montar({conFuncion}){
  await page.addInitScript(({HISTORIAL, HISTORIAL_AUTO, conFuncion}) => {
    const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
    const T = {
      productos:[], producto_enlace:[], fudo_stock_push:[],
      app_permisos:[{correo:'jhon@cafe.cl', nombre:'Jhon', puede_ajustes:true, puede_editar:true, puede_fudo:true, fudo_bloqueos:[]}],
      fudo_sync:[], secciones:[], movimientos:[], ajustes:[], metas:[],
      historial:HISTORIAL, historial_auto:HISTORIAL_AUTO,
      restauraciones:[], fusiones:[], recetas:[], receta_items:[],
      fudo_productos:[], producto_lotes:[], repartos:[], reparto_items:[], mermas:[],
      tareas:[], fudo_categorias:[], envios_franquicia:[], envios_franquicia_items:[]};
    let seq = 7000;
    const q = (n) => {
      let filas = JSON.parse(JSON.stringify(T[n]||[]));
      const api = {
        select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
        in(c,vs){ filas=filas.filter(f=>vs.map(String).includes(String(f[c]))); return api;},
        neq(){return api;},
        order(c,o){ const asc = !o || o.ascending !== false;
          filas.sort((a,b)=>String(a[c]??'').localeCompare(String(b[c]??''))*(asc?1:-1)); return api;},
        limit(){return api;}, gte(){return api;}, lte(){return api;}, is(){return api;},
        not(){return api;}, or(){return api;}, ilike(){return api;},
        maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},
        single(){return Promise.resolve({data:filas[0]||null,error:null});},
        insert(v){ const rows=(Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
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
      from:q,
      /* Simula el estado real: la función existe o no, según el caso. */
      rpc:(nombre, args)=>{
        if(nombre === 'fotos_por_dia'){
          if(conFuncion === 'no-existe') return Promise.resolve({data:null, error:{message:'function public.fotos_por_dia(text) does not exist'}});
          const sede = args.p_sede;
          const porFecha = {};
          (T.historial.filter(h=>h.sede===sede)||[]).forEach(h=>{
            (porFecha[h.fecha] ||= {man:0,aut:0}).man++; });
          (T.historial_auto.filter(h=>h.sede===sede)||[]).forEach(h=>{
            (porFecha[h.fecha] ||= {man:0,aut:0}).aut++; });
          const filas = Object.keys(porFecha).sort().reverse().map(f=>({
            fecha:f, cuantos:porFecha[f].man+porFecha[f].aut,
            tipo: porFecha[f].man>0 && porFecha[f].aut>0 ? 'contada a mano + automática'
                : porFecha[f].man>0 ? 'contada a mano' : 'automática',
            a_mano:porFecha[f].man, automatica:porFecha[f].aut}));
          /* LA VERSIÓN VIEJA que vive en producción: 3 columnas, sin
             `a_mano` ni `automatica`. Es el caso real del 2026-08-26. */
          if(conFuncion === 'vieja')
            return Promise.resolve({error:null,
              data: filas.map(({fecha, cuantos, tipo})=>({fecha, cuantos, tipo}))});
          return Promise.resolve({data:filas, error:null});
        }
        return Promise.resolve({data:[], error:null});
      },
      auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
             onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
             signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
      channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
      removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
    })};
  }, {HISTORIAL, HISTORIAL_AUTO, conFuncion});
  await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
  await page.goto(pathToFileURL(join(raiz,'index.html')).href);
  await page.waitForTimeout(400);
}

const errores = [];
page.on('pageerror', e=>errores.push(String(e)));
page.on('console', m=>{ if(m.type()==='error') errores.push('console: '+m.text()); });

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

/* Ajustes no es una pestaña de la barra: se entra desde el menú, y el riel
   de módulos está oculto hasta entonces. Se abre por código, que es lo que
   hace el propio menú. */
const abrirRespaldos = async (sede) => {
  /* El gate de sede solo aparece la primera vez. Volver a tocarlo cuando ya
     se pasó deja la prueba esperando un botón que no existe. */
  if(await page.isVisible('.gate-btn[data-sede="central"]')){
    await page.click('.gate-btn[data-sede="central"]'); await page.waitForTimeout(500);
  }
  await page.evaluate(()=>pickTab('ajustes'));  await page.waitForTimeout(400);
  await page.click('[data-aj="respaldos"]');    await page.waitForTimeout(300);
  await page.click(`[data-ajsede="${sede}"]`);  await page.waitForTimeout(600);
};

console.log('\nCON la función fotos_por_dia instalada (el camino de siempre):');
await montar({conFuncion:'nueva'});
await caso('Plaza, con fotos automáticas de verdad: la red dice "puesta"', async () => {
  await abrirRespaldos('plaza');
  const t = await page.textContent('.aj-red');
  return (t.includes('La red está puesta')) || 'dice: "'+t+'"';
});
await caso('Angamos, sin ninguna foto: lo dice, no inventa una red', async () => {
  await abrirRespaldos('angamos');
  const t = await page.textContent('#aj-pane');
  return t.includes('No hay ninguna foto de esta sede') || 'dice: "'+t.slice(0,120)+'"';
});

console.log('\nSIN la función instalada (el camino de respaldo — acá estaba el bug):');
await montar({conFuncion:'no-existe'});
await caso('Plaza, con fotos automáticas de verdad: YA NO dice "nunca corrió"', async () => {
  await abrirRespaldos('plaza');
  const t = await page.textContent('.aj-red');
  return (t.includes('La red está puesta') && !t.includes('nunca corrió'))
    || 'sigue mintiendo: "'+t+'"';
});
await caso('Angamos, sin ninguna foto: lo dice, no inventa una red', async () => {
  await abrirRespaldos('angamos');
  const t = await page.textContent('#aj-pane');
  return t.includes('No hay ninguna foto de esta sede') || 'dice: "'+t.slice(0,120)+'"';
});
/* El MISMO campo `d.auto` que alimenta el semáforo pinta el "· sin foto
   automática" de cada día. Un solo bug, dos síntomas: si uno se arregla y el
   otro no, es que se parchó el síntoma y no la causa. */
await caso('y cada día deja de decir "sin foto automática" cuando sí la hay', async () => {
  await abrirRespaldos('plaza');
  const t = await page.textContent('#aj-pane');
  return !t.includes('sin foto automática') || 'los días siguen mintiendo';
});

console.log('\nCON LA VERSIÓN VIEJA DE LA FUNCIÓN (el caso real del 26 de agosto):');
/* Devuelve (fecha, cuantos, tipo) y nada más. `d.automatica` llega undefined,
   y antes ese undefined se volvía 0 y la pantalla AFIRMABA "nunca corrió"
   teniendo fotos guardadas. No sé ≠ no hay. */
await montar({conFuncion:'vieja'});
await caso('NO afirma que la red nunca corrió', async () => {
  await abrirRespaldos('plaza');
  const t = await page.textContent('.aj-red');
  return !t.includes('nunca corrió') || 'sigue acusando en falso: "'+t+'"';
});
await caso('dice que no se puede saber, y cómo arreglarlo', async () => {
  const t = await page.textContent('.aj-red');
  return (t.includes('No se puede saber') && t.includes('dias-con-foto'))
    || 'no explica qué hacer: "'+t+'"';
});
await caso('y en ámbar, no en rojo: falta un dato, no está roto', async () =>
  (await page.getAttribute('.aj-red','class')).includes('aviso')
  || 'sigue pintado como error');
await caso('los días tampoco dicen "sin foto automática"', async () => {
  const t = await page.textContent('#aj-pane');
  return !t.includes('sin foto automática') || 'los días siguen acusando en falso';
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () =>
  errores.filter(e=>!/ERR_TUNNEL|Failed to load resource/.test(e)).length === 0
  || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
