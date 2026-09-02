/* LLAMITA LAMA · B1 — el ancho del panel, medido.
   node pruebas/lama-ancho.mjs

   POR QUÉ EXISTE ESTA PRUEBA, y es la parte que importa.

   B1 pedía "el panel más ancho y el plano más angosto, que hoy los nombres se
   cortan en 'selladito + Sprite z…'". El 2026-08-31 se subió el panel de 400px
   a 40% y se dio por cerrado. NO LO ESTABA: a 1440 el nombre entraba justo
   —y por eso pareció resuelto—, pero a 1280, que es el portátil del mesón,
   seguía cortado. Pedía 290px y tenía 248.

   El error no fue el cambio, fue darlo por bueno sin medirlo en el ancho donde
   dolía. Es la misma forma del C6 ("se dio por arreglado y no lo estaba") y de
   la falla de las 15 horas (§0.5): probar contra un mundo cómodo.

   Entonces esta prueba NO mira el CSS ni el porcentaje. Mira UNA cosa, la
   única que le importa a quien usa la pantalla:

       ¿el nombre más largo de la carta se lee entero, o se corta?

   Se mide con scrollWidth > clientWidth, que es el navegador diciendo "esto no
   me cupo". Un porcentaje puede cambiar; la pregunta no.                    */
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const MESAS = Array.from({length:12}, (_,i)=>({
  id:100+i, sede:'plaza', salon:'Salón', numero:i+1, orden:i+1, activa:true }));

/* La 3 es la que se mueve. La 7 nace OCUPADA porque mover productos solo
   puede ir a una mesa ya abierta, y la 8 en precuenta para comprobar que
   esa no se ofrece: quien está pagando no puede recibir más productos. */
const CUENTAS = [
  {id:900, sede:'plaza', mesa_id:102, estado:'abierta',   total:12200, abierta_por:'adriana@cafe.cl'},
  {id:901, sede:'plaza', mesa_id:106, estado:'abierta',   total:2500,  abierta_por:'marcela@cafe.cl'},
  {id:902, sede:'plaza', mesa_id:107, estado:'precuenta', total:6800,  abierta_por:'adriana@cafe.cl'},
];
const ITEMS = [
  {id:11, cuenta_id:900, nombre:'Selladito jamón queso + Sprite zero 350cc', cantidad:2, precio:3400, estado:'confirmado', comentario:null},
  {id:12, cuenta_id:900, nombre:'Medialuna manjar', cantidad:1, precio:2900, estado:'confirmado', comentario:null},
  {id:13, cuenta_id:900, nombre:'Americano',        cantidad:1, precio:2500, estado:'nuevo',      comentario:'sin azúcar'},
];
const CARTA = [
  {fudo_product_id:'F-33', sede:'plaza', nombre:'Americano',        precio:2500, activo:true},
  {fudo_product_id:'F-38', sede:'plaza', nombre:'Selladito jamón queso + Sprite zero 350cc', precio:3400, activo:true},
  {fudo_product_id:'F-99', sede:'plaza', nombre:'Medialuna manjar', precio:2900, activo:true},
];

const page = await browser.newPage();
await page.setViewportSize({width:1100, height:900});   // computador: dos columnas

await page.addInitScript(({MESAS, CUENTAS, ITEMS, CARTA}) => {
  window.__rpc = [];
  const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
  const T = {
    productos:[{id:1, sede:'plaza', producto:'Medialuna manjar', rubro:'Vitrina', stock_actual:20, activo:'SÍ'}],
    mesas:MESAS, cuentas:CUENTAS, cuenta_items:ITEMS, comandas:[],
    fudo_productos:CARTA,
    app_permisos:[{correo:'jhon@cafe.cl', nombre:'Jhon', puede_ajustes:true,
                   puede_editar:true, puede_fudo:true, puede_lama:true, fudo_bloqueos:[]}],
    producto_enlace:[], fudo_stock_push:[], fudo_sync:[], secciones:[], movimientos:[],
    ajustes:[], metas:[], historial:[], historial_auto:[], restauraciones:[], fusiones:[],
    recetas:[], receta_items:[], producto_lotes:[], repartos:[], reparto_items:[],
    mermas:[], tareas:[], fudo_categorias:[], envios_franquicia:[], envios_franquicia_items:[]};
  let seq = 7000;
  const q = (n) => {
    let filas = JSON.parse(JSON.stringify(T[n]||[]));
    const api = {
      select(){return api;}, eq(c,v){ filas=filas.filter(f=>String(f[c])===String(v)); return api;},
      neq(c,v){ filas=filas.filter(f=>String(f[c])!==String(v)); return api;},
      in(c,vs){ filas=filas.filter(f=>vs.map(String).includes(String(f[c]))); return api;},
      order(){return api;}, limit(){return api;}, gte(){return api;}, lte(){return api;},
      is(){return api;}, not(){return api;}, or(){return api;}, ilike(){return api;},
      maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},
      single(){return Promise.resolve({data:filas[0]||null,error:null});},
      insert(v){ const rows=(Array.isArray(v)?v:[v]).map(r=>({id:++seq, ...r}));
        const e={select:()=>e, single:()=>Promise.resolve({data:rows[0],error:null}),
                 then:f=>Promise.resolve({data:rows,error:null}).then(f)}; return e; },
      /* update sí escribe: el comentario se guarda con un update directo, y
         hay que poder comprobar que después viaja a la comanda. */
      update(vals){
        const e={ _c:null, _v:null,
          eq(c,v){ e._c=c; e._v=v; return e; }, in(){return e;}, select(){return e;},
          then(f){
            if(e._c) for(const fila of (T[n]||[])) if(String(fila[e._c])===String(e._v)) Object.assign(fila, vals);
            return Promise.resolve({data:[],error:null}).then(f);
          }};
        return e;
      },
      upsert(){const e={select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      delete(){const e={eq:()=>e,in:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
      then(f){return Promise.resolve({data:filas,error:null,count:filas.length}).then(f);},
    };
    return api;
  };
  window.supabase = { createClient: () => ({
    from:q,
    rpc:(nombre, args)=>{
      window.__rpc.push({nombre, args});
      if(nombre === 'mesa_abrir')
        return Promise.resolve({data:{id:++seq, sede:'plaza', mesa_id:args.p_mesa_id,
                                      estado:'abierta', total:0, abierta_por:'Jhon'}, error:null});
      if(nombre === 'cuenta_mover')
        return Promise.resolve({data:{id:args.p_cuenta_id, sede:'plaza', mesa_id:args.p_mesa_id,
                                      estado:'abierta', total:12200}, error:null});
      if(nombre === 'items_mover')
        return Promise.resolve({data:(args.p_items||[]).length, error:null});
      if(nombre === 'cuenta_confirmar'){
        /* La comanda es lo que la base devuelve: nombre, cantidad, precio y
           COMENTARIO de los que estaban en `nuevo`. Se arma acá igual que
           allá para poder comprobar que la pantalla lo pinta. */
        const nuevos = T.cuenta_items.filter(i=>i.cuenta_id===args.p_cuenta_id && i.estado==='nuevo');
        return Promise.resolve({data:{id:1, cuenta_id:args.p_cuenta_id, numero:1, quien:'Jhon',
          created_at:new Date().toISOString(),
          contenido:nuevos.map(i=>({nombre:i.nombre, cantidad:i.cantidad,
                                    precio:i.precio, comentario:i.comentario}))}, error:null});
      }
      return Promise.resolve({data:null, error:null});
    },
    auth:{ getSession:async()=>({data:{session:SES}}), getUser:async()=>({data:{user:SES.user}}),
           onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return {data:{subscription:{unsubscribe(){}}}};},
           signInWithPassword:async()=>({data:{session:SES},error:null}), signOut:async()=>({}) },
    channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
    removeChannel(){}, functions:{invoke:async()=>({data:{ok:true},error:null})},
  })};
}, {MESAS, CUENTAS, ITEMS, CARTA});

await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));

const errores = [];
page.on('pageerror', e=>errores.push(String(e)));

await page.goto(pathToFileURL(join(raiz,'index.html')).href);
await page.waitForTimeout(400);
await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(700);
await page.click('#tabLama');
await page.waitForTimeout(700);


let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  \u2713 '+n);}
        else {mal++;console.log('  \u2717 '+n+'  \u2192 '+r);} }
  catch(e){ mal++; console.log('  \u2717 '+n+'  \u2192 '+e.message.split('\n')[0]); }
};

/* La mesa 3 (id 102) es la que tiene la cuenta con el nombre largo. */
await page.setViewportSize({width:1280, height:900});
await page.waitForTimeout(300);
await page.click('[data-lamamesa="102"]');
await page.waitForTimeout(600);

/* Lo que devuelve el navegador para un ancho dado. */
async function medir(w){
  await page.setViewportSize({width:w, height:900});
  await page.waitForTimeout(350);
  return page.evaluate(()=>{
    const plano = document.querySelector('.lama-plano');
    const panel = document.querySelector('.lama-panel');
    const cuerpo = document.querySelector('.lama-cuerpo');
    if(!plano || !panel || !cuerpo) return null;
    const rp = plano.getBoundingClientRect(), rq = panel.getBoundingClientRect();
    /* scrollWidth > clientWidth es el navegador diciendo "no me cupo". */
    const cortados = [...cuerpo.querySelectorAll('b')]
      .map(el => ({txt: el.textContent.trim(), sw: el.scrollWidth, cw: el.clientWidth}))
      .filter(x => x.sw > x.cw + 1);
    const mesas = document.querySelector('.lama-mesas');
    return {plano: Math.round(rp.width), panel: Math.round(rq.width),
            sePisan: rq.left < rp.right - 1,
            columnasDeMesas: mesas ? getComputedStyle(mesas).gridTemplateColumns.split(' ').length : 0,
            cortados};
  });
}

/* LOS TRES ANCHOS QUE IMPORTAN. 1280 es el portátil del mesón y es el que
   fallaba; 1440 es el que engañó al arreglo anterior; 1920 es la pantalla de
   la oficina. */
console.log('\nEl nombre largo entra entero:');
for (const w of [1280, 1440, 1920]) {
  await caso(`a ${w}px no se corta ningún nombre de la cuenta`, async () => {
    const m = await medir(w);
    if(!m) return 'no se pudo medir: falta el panel o la cuenta';
    return m.cortados.length === 0
      || 'se corta ' + JSON.stringify(m.cortados.map(c=>c.txt+' ('+c.sw+'>'+c.cw+')'));
  });
}

/* El piso. Sin esto, alguien puede volver a angostar el panel y la prueba de
   arriba seguiría verde en una pantalla grande, que es justo lo que pasó. */
console.log('\nEl panel no vuelve a angostarse:');
await caso('a 1280px el panel mide al menos 540px', async () => {
  const m = await medir(1280);
  return m.panel >= 540 || 'el panel quedó en ' + m.panel + 'px';
});

/* Grid y no flex: dos pistas no se pueden pisar (lección del 31 de agosto).
   Se comprueba con los rectángulos de verdad, no leyendo el CSS. */
console.log('\nY sigue sin pisarse con el plano:');
for (const w of [1024, 1280, 1920]) {
  await caso(`a ${w}px el panel no se monta sobre el plano`, async () => {
    const m = await medir(w);
    return m.sePisan === false || 'el panel arranca antes de que termine el plano';
  });
}

/* El plano se angosta, que es la otra mitad de B1 — pero tiene que SEGUIR
   siendo un plano. Si quedara en una sola columna dejó de serlo. */
console.log('\nEl plano se angosta pero sigue siendo un plano:');
await caso('a 1280px las mesas siguen en varias columnas', async () => {
  const m = await medir(1280);
  return m.columnasDeMesas >= 4
    || 'el plano quedó en ' + m.columnasDeMesas + ' columna(s): dejó de leerse como salón';
});

/* El teléfono no se toca: sigue partido en riel + cuenta. */
console.log('\nEl teléfono queda como estaba:');
await caso('a 390px sigue partido en dos columnas', async () => {
  await page.setViewportSize({width:390, height:900});
  await page.waitForTimeout(350);
  const n = await page.evaluate(()=>
    getComputedStyle(document.querySelector('.lama')).gridTemplateColumns.split(' ').length);
  return n === 2 || 'el teléfono quedó en ' + n + ' columna(s)';
});

console.log(`\n${ok} bien \u00b7 ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
