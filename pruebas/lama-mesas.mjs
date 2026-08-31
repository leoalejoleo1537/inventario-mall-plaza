/* LLAMITA LAMA · el área de ventas.
   node pruebas/lama-mesas.mjs

   LA COMPROBACIÓN MÁS IMPORTANTE DE TODAS es la primera: que la pestaña NO
   exista para una cuenta del equipo. Jhon: "si algo falla aquí, podríamos
   perder o entorpecer todo un día de ventas, necesito trabajar tranquilo".
   Si esa prueba se pone roja, no importa lo demás.

   Y se prueba EN LAS DOS DIRECCIONES —que no aparezca sin permiso y que sí
   aparezca con él—, porque una puerta que nunca se abre pasa por segura sin
   serlo. Es la misma regla que salió de la alarma del motor.               */
import { pathToFileURL, fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { abrirNavegador } from './navegador.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const browser = await abrirNavegador();
if (!browser) { console.log('\n(se salta: no hay navegador instalado)\n'); process.exit(0); }

const MESAS = Array.from({length:12}, (_,i)=>({
  id:100+i, sede:'plaza', salon:'Salón', numero:i+1, orden:i+1, activa:true }));

/* La mesa 2 nace ocupada y la 3 cobrando: así los tres colores se ven sin
   tener que abrir nada, y se prueba que el estado manda sobre el color. */
const CUENTAS = [
  {id:900, sede:'plaza', mesa_id:101, estado:'abierta',   total:2900, abierta_por:'adriana@cafe.cl'},
  {id:901, sede:'plaza', mesa_id:102, estado:'precuenta', total:6800, abierta_por:'adriana@cafe.cl'},
];
const ITEMS = [
  {id:1, cuenta_id:900, nombre:'Medialuna manjar', cantidad:1, precio:2900, estado:'confirmado', comentario:null},
];
const CARTA = [
  {fudo_product_id:'F-33', sede:'plaza', nombre:'Americano',        precio:2500, activo:true},
  {fudo_product_id:'F-38', sede:'plaza', nombre:'Café Latte',       precio:3400, activo:true},
  {fudo_product_id:'F-99', sede:'plaza', nombre:'Medialuna manjar', precio:2900, activo:true},
  /* Sin precio: NO tiene que aparecer en la carta. Un producto a $0 en una
     comanda es una venta que nadie cobra. */
  {fudo_product_id:'F-00', sede:'plaza', nombre:'Producto interno', precio:0,    activo:true},
];

const page = await browser.newPage();
await page.setViewportSize({width:390, height:900});

async function montar({puedeLama}){
  await page.addInitScript(({MESAS, CUENTAS, ITEMS, CARTA, puedeLama}) => {
    window.__rpc = [];
    const SES = {user:{id:'u1', email:'jhon@cafe.cl', user_metadata:{nombre:'Jhon'}}};
    const T = {
      productos:[{id:1, sede:'plaza', producto:'Medialuna manjar', rubro:'Vitrina', stock_actual:20, activo:'SÍ'}],
      mesas:MESAS, cuentas:CUENTAS, cuenta_items:ITEMS, comandas:[],
      fudo_productos:CARTA,
      app_permisos:[{correo:'jhon@cafe.cl', nombre:'Jhon', puede_ajustes:true,
                     puede_editar:true, puede_fudo:true, puede_lama:puedeLama, fudo_bloqueos:[]}],
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
        update(){const e={eq:()=>e,in:()=>e,select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        upsert(){const e={select:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        delete(){const e={eq:()=>e,in:()=>e,then:f=>Promise.resolve({data:[],error:null}).then(f)};return e;},
        then(f){return Promise.resolve({data:filas,error:null,count:filas.length}).then(f);},
      };
      return api;
    };
    window.supabase = { createClient: () => ({
      from:q,
      /* Se anota QUÉ se le pidió a la base. Lo que se prueba es que la
         pantalla llame a la función correcta con los datos correctos — la
         lógica de las funciones ya está probada contra Postgres. */
      rpc:(nombre, args)=>{
        window.__rpc.push({nombre, args});
        if(nombre === 'mesa_abrir')
          return Promise.resolve({data:{id:950, sede:'plaza', mesa_id:args.p_mesa_id,
                                        estado:'abierta', total:0, abierta_por:'Jhon'}, error:null});
        if(nombre === 'cuenta_agregar')
          return Promise.resolve({data:{id:++seq, cuenta_id:args.p_cuenta_id, nombre:args.p_nombre,
                                        cantidad:1, precio:args.p_precio, estado:'nuevo'}, error:null});
        if(nombre === 'cuenta_confirmar')
          return Promise.resolve({data:{id:1, cuenta_id:args.p_cuenta_id, numero:1, quien:'Jhon',
                                        created_at:new Date().toISOString(),
                                        contenido:[{nombre:'Café Latte', cantidad:1, precio:3400, comentario:null}]}, error:null});
        if(nombre === 'cuenta_precuenta')
          return Promise.resolve({data:{id:args.p_cuenta_id, mesa_id:101, sede:'plaza',
                                        estado:'precuenta', total:2900}, error:null});
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
  }, {MESAS, CUENTAS, ITEMS, CARTA, puedeLama});
  await page.route('**/supabase-js*', r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
  await page.goto(pathToFileURL(join(raiz,'index.html')).href);
  await page.waitForTimeout(400);
  await page.click('.gate-btn[data-sede="plaza"]');
  await page.waitForTimeout(700);
}

const errores = [];
page.on('pageerror', e=>errores.push(String(e)));

let ok=0, mal=0;
const caso = async (n, fn) => {
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};

console.log('\nLA PUERTA · sin permiso, la pestaña NO existe:');
await montar({puedeLama:false});
await caso('una cuenta del equipo no ve "Mesas"', async () =>
  !(await page.isVisible('#tabLama')) || 'LA VE — el equipo se va a enterar del proyecto');
await caso('y la pantalla tampoco', async () =>
  !(await page.isVisible('#view-lama')) || 'la vista está abierta sin permiso');

console.log('\nCON permiso, sí aparece:');
await montar({puedeLama:true});
await caso('la pestaña "Mesas" está', async () =>
  await page.isVisible('#tabLama') || 'no aparece ni teniendo el permiso');

/* Bodega no vende: no tiene mesas ni cuenta de Fudo. Una pestaña que promete
   algo que no puede pasar es peor que una que no está (la lección del botón
   Actualizar en bodega, 21 de agosto). */
await caso('pero en Bodega no, porque bodega no vende', async () => {
  await page.evaluate(()=>pickSede('central'));
  await page.waitForTimeout(700);
  const v = await page.isVisible('#tabLama');
  await page.evaluate(()=>pickSede('plaza'));
  await page.waitForTimeout(700);
  return !v || 'aparece en bodega, y ahí no hay mesas';
});

console.log('\nEl plano del salón:');
await page.click('#tabLama'); await page.waitForTimeout(700);
await caso('las 12 mesas están', async () =>
  (await page.$$('[data-lamamesa]')).length === 12
  || 'hay '+(await page.$$('[data-lamamesa]')).length);
await caso('los tres colores salen del estado de la cuenta', async () => {
  const l = (await page.$$('.lama-mesa.libre')).length;
  const o = (await page.$$('.lama-mesa.ocupada')).length;
  const c = (await page.$$('.lama-mesa.cobrando')).length;
  return (l===10 && o===1 && c===1) || `libres ${l}, ocupadas ${o}, cobrando ${c}`;
});
/* Un selector de una sola opción es ruido: hoy solo existe "Salón". */
await caso('con un solo salón no se pinta el selector', async () =>
  (await page.textContent('#lama-salones')).trim() === '' || 'pinta un selector de una opción');

/* El cuadrito dice el NÚMERO y nada más. Llegó a mostrar debajo el nombre de
   quien abrió la mesa —"leoalejoleo12" en cada una— y era ruido: no ayuda a
   decidir nada y tapa lo único que importa de un vistazo, que es el color.
   Quién la abrió sigue guardado en la fila, solo no se pinta. */
await caso('el cuadrito NO muestra quién abrió la mesa', async () =>
  !(await page.textContent('[data-lamamesa="101"]')).includes('adriana')
  || 'pinta el correo de quien la abrió, y eso es ruido');

/* Los tres colores son SÓLIDOS y el número va en blanco, como en Fudo. Con
   los tonos pálidos de la paleta el azul de "cobrando" no se despegaba del
   fondo de la app: había que adivinar cuál mesa se estaba cobrando. */
await caso('las mesas son sólidas, no un tono pálido del fondo', async () => {
  const c = await page.evaluate(()=>{
    const e = document.querySelector('[data-lamamesa="102"]');   // la que está cobrando
    const s = getComputedStyle(e);
    return {fondo:s.backgroundColor, texto:s.color};
  });
  return (c.fondo === 'rgb(44, 90, 160)' && c.texto === 'rgb(255, 255, 255)')
    || 'quedó '+JSON.stringify(c);
});
/* El glosario de colores se sacó: tres cuadritos de colores no necesitan pie
   de página, y ocupaba una franja de la pantalla en cada carga. */
await caso('ya no hay glosario de colores', async () =>
  !(await page.isVisible('.lama-leyenda')) || 'sigue el "libre / ocupada / cobrando"');
/* Apilar el plano y la cuenta dentro de 900px dejaba media pantalla en blanco
   con el panel apretado. Es lo único que view-lama le cambia a .wrap. */
await caso('la pantalla ocupa todo el ancho', async () => {
  const w = await page.evaluate(()=>getComputedStyle(document.getElementById('view-lama')).maxWidth);
  return w === 'none' || 'sigue acotada a '+w;
});
console.log('\nLos colores, con la lógica de Fudo y la paleta de Stock:');
/* Medido de las capturas de Fudo el 31-08: libre #D2F1C0 con el número en
   #3D741C, ocupada #EF4444 sólida con blanco. Lo que se copia es la LÓGICA:
   lo libre no grita —es el estado normal— y lo ocupado sí. Los valores salen
   de la paleta de Stock. El primer intento pintó el verde también sólido y
   quedó pesado; el borde es lo que hace que un relleno pálido se lea como un
   cuadro sobre el fondo gris de la app. */
await caso('la mesa LIBRE es pálida, con el número oscuro', async () => {
  const c = await page.evaluate(()=>{
    const s = getComputedStyle(document.querySelector('[data-lamamesa="103"]'));
    return {f:s.backgroundColor, t:s.color};
  });
  return (c.f === 'rgb(228, 241, 229)' && c.t === 'rgb(46, 125, 50)') || 'quedó '+JSON.stringify(c);
});
/* NADA CON REBORDE. Es regla de la casa —docs/DECISIONES-ESTETICA.md: "Filas:
   sin borde. Lo que separa es la sombra"— y Jhon la dijo textual: "ya sabes
   que no me gustan los rebordes, eso sí que no". Se comprueba el ANCHO, no el
   color: con `border:none` el color calculado sigue devolviendo un valor, así
   que mirarlo deja pasar un borde que sí existe. */
await caso('ninguna mesa tiene reborde, y todas tienen sombra', async () => {
  const r = await page.evaluate(()=>{
    const malas = [], sinSombra = [];
    for(const e of document.querySelectorAll('.lama-mesa')){
      const s = getComputedStyle(e);
      if(parseFloat(s.borderTopWidth) > 0) malas.push(e.textContent.trim());
      if(s.boxShadow === 'none') sinSombra.push(e.textContent.trim());
    }
    return {malas, sinSombra};
  });
  return (!r.malas.length && !r.sinSombra.length)
    || 'con reborde: '+r.malas.join(',')+' · sin sombra: '+r.sinSombra.join(',');
});
/* La elegida se ENCIENDE, no se enmarca: un halo difuso, no un anillo duro. */
await caso('la mesa elegida se marca con un halo, no con un anillo', async () => {
  await page.click('[data-lamamesa="103"]'); await page.waitForTimeout(300);
  const s = await page.evaluate(()=>getComputedStyle(document.querySelector('.lama-mesa.sel')).boxShadow);
  return (/rgba\(220, 68, 5/.test(s) && /px/.test(s) && !/0px 0px 0px 3px rgb/.test(s))
    || 'la marca no es un halo: '+s;
});
await caso('la OCUPADA es sólida, con el número en blanco', async () => {
  const c = await page.evaluate(()=>{
    const s = getComputedStyle(document.querySelector('[data-lamamesa="101"]'));
    return {f:s.backgroundColor, t:s.color};
  });
  return (c.f === 'rgb(192, 57, 43)' && c.t === 'rgb(255, 255, 255)') || 'quedó '+JSON.stringify(c);
});
/* Jhon: "en el teléfono quiero que siempre las mesas estén apiladas a la
   izquierda y a la derecha la información". Sostenerlo siempre evita que la
   pantalla cambie de forma cada vez que se toca una mesa. */
await caso('en el teléfono el riel está SIEMPRE, no solo con mesa elegida', async () => {
  const cols = await page.evaluate(()=>getComputedStyle(document.querySelector('.lama')).gridTemplateColumns);
  return /^\d/.test(cols) && cols.split(' ').length === 2 || 'no está partido: '+cols;
});


console.log('\nAbrir una mesa es MANUAL, y se abre con el +:');
/* Tocar el plano no puede crear nada. Antes tocar una mesa verde ya llamaba a
   mesa_abrir, así que un roce dejaba una cuenta abierta que después alguien
   tenía que ir a cerrar. Abrir y cerrar son actos de la persona. */
await caso('tocar una mesa libre NO la abre: solo la elige', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.click('[data-lamamesa="104"]'); await page.waitForTimeout(400);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='mesa_abrir'));
  return !r || 'la abrió de solo tocarla, y eso deja cuentas que nadie pidió';
});
await caso('el panel dice qué mesa es y que está libre', async () => {
  const t = await page.textContent('.lama-caja');
  return (t.includes('Mesa 5') && t.includes('Libre')) || 'no dice el estado: '+t.slice(0,120);
});
/* El botón de texto "Abrir mesa 5" se cambió por el + de abajo a la derecha:
   el gesto es el mismo —agregar algo— tanto para abrir como para poner
   productos, y no hace falta nombrarlo dos veces. */
await caso('el + está abajo a la derecha', async () =>
  await page.isVisible('.lama-fab') || 'no hay botón +');
await caso('y llama a mesa_abrir con su id', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.click('[data-lamaacc="mas"]'); await page.waitForTimeout(500);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='mesa_abrir'));
  return (r && r.args.p_mesa_id === 104) || 'llamó con '+JSON.stringify(r);
});

console.log('\nLa carta: EN LISTA, con el precio al lado:');
await caso('el + de una mesa abierta abre la carta', async () => {
  await page.click('[data-lamaacc="mas"]'); await page.waitForTimeout(400);
  return await page.isVisible('.lama-carta') || 'no se abrió la carta';
});
/* Las píldoras de dos columnas cortaban los nombres ("Cannolis Pist…") y no
   tenían dónde poner el precio: había que tocar a ciegas. */
await caso('cada producto es UNA fila, no una píldora', async () => {
  const n = await page.evaluate(()=>{
    const filas = [...document.querySelectorAll('.lama-prod')];
    if(filas.length < 2) return -1;
    // dos filas seguidas tienen que estar una DEBAJO de la otra, no al lado
    const a = filas[0].getBoundingClientRect(), b = filas[1].getBoundingClientRect();
    return b.top >= a.bottom - 1 ? 1 : 0;
  });
  return n === 1 || (n === -1 ? 'hay menos de dos productos' : 'están en dos columnas');
});
await caso('y muestra el precio a la derecha del nombre', async () => {
  const r = await page.evaluate(()=>{
    const f = document.querySelector('.lama-prod');
    if(!f) return null;
    const nm = f.querySelector('.nm'), pr = f.querySelector('.pr');
    if(!nm || !pr) return null;
    return {precio:pr.textContent, aLaDerecha: pr.getBoundingClientRect().left > nm.getBoundingClientRect().left};
  });
  return (r && r.aLaDerecha && /\$/.test(r.precio)) || 'no está el precio a la derecha: '+JSON.stringify(r);
});
await caso('los productos con precio aparecen', async () =>
  (await page.textContent('.lama-carta-lista')).includes('Americano') || 'no está la carta');
/* Un producto a $0 en una comanda es una venta que nadie cobra. */
await caso('el que vale $0 NO aparece', async () =>
  !(await page.textContent('.lama-carta-lista')).includes('Producto interno')
  || 'ofrece un producto sin precio');
await caso('el buscador filtra', async () => {
  await page.fill('#lama-q', 'latte'); await page.waitForTimeout(300);
  const t = await page.textContent('.lama-carta-lista');
  return (t.includes('Café Latte') && !t.includes('Americano')) || 'filtró mal: '+t;
});
/* Repintar mientras alguien escribe le saca el campo de abajo del dedo. Esa
   lección costó tres veces en el área de reparto: acá se comprueba que el
   input SOBREVIVE al filtrado. */
await caso('y el campo NO se destruye al teclear', async () =>
  (await page.evaluate(()=>document.activeElement && document.activeElement.id)) === 'lama-q'
  || 'el foco se perdió al filtrar');

console.log('\nAgregar y confirmar:');
await caso('agregar llama a cuenta_agregar con nombre y precio', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.click('[data-lamaadd="F-38"]'); await page.waitForTimeout(400);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_agregar'));
  return (r && r.args.p_nombre === 'Café Latte' && r.args.p_precio === 3400)
    || 'mandó '+JSON.stringify(r && r.args);
});
await caso('y se sale de la carta con Listo', async () => {
  await page.click('[data-lamaacc="cerrar-carta"]'); await page.waitForTimeout(300);
  return !(await page.isVisible('.lama-carta')) || 'la carta quedó abierta';
});


console.log('\nLa mesa que ya está ocupada:');
await caso('al abrirla NO llama a mesa_abrir: ya tiene cuenta viva', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.click('[data-lamamesa="101"]'); await page.waitForTimeout(500);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='mesa_abrir'));
  return !r || 'la volvió a abrir, y eso duplicaría la cuenta';
});
await caso('muestra lo que ya se pidió, y su total', async () => {
  const t = await page.textContent('.lama-cuerpo');
  return (t.includes('Medialuna manjar') && t.includes('2.900')) || 'no muestra la cuenta: '+t.slice(0,120);
});
/* Lo confirmado NO va en ámbar: el ámbar es "esto todavía no salió". */
await caso('lo que ya salió a la cocina no se marca como nuevo', async () =>
  (await page.$$('.lama-linea.nueva')).length === 0 || 'marca como nuevo algo ya confirmado');

console.log('\nLa mesa cobrando:');
await caso('se ve azul, no roja', async () =>
  (await page.getAttribute('[data-lamamesa="102"]','class')).includes('cobrando')
  || 'no distingue "cobrando" de "ocupada"');

console.log('\nUna mesa SIN NADA se puede cerrar:');
/* Es lo que faltaba y lo pidió Jhon el 31 de agosto: "abrir una mesa es más
   fácil pero cerrarla no". El botón Cerrar solo existía si había productos,
   así que una mesa abierta por error quedaba abierta para siempre — y eso
   descuadra el arqueo antes de que el arqueo exista. */
await caso('el botón Cerrar está aunque no haya productos', async () => {
  await page.click('[data-lamamesa="105"]'); await page.waitForTimeout(300);
  await page.click('[data-lamaacc="mas"]');  await page.waitForTimeout(500);  // abre la mesa 6
  const t = await page.textContent('.lama-caja');
  return t.includes('Cerrar mesa 6') || 'no ofrece cerrarla: '+t.slice(0,140);
});
/* Y se cierra de una, sin preguntar: no hay nada que perder, y preguntar
   "se guarda la cuenta por $0" no protege de nada. */
await caso('y se cierra de una, sin preguntar', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await page.click('[data-lamaacc="cobrar"]'); await page.waitForTimeout(600);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_cerrar'));
  const preguntando = await page.isVisible('#overlay-ask.open');
  return (r && !preguntando) || (preguntando ? 'preguntó por una mesa vacía' : 'no llamó a cuenta_cerrar');
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () => errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
