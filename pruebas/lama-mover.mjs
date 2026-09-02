/* LLAMITA LAMA · mover una mesa, y mover algunos productos.
   node pruebas/lama-mover.mjs

   Esta pantalla existe porque el garzón se equivoca: anota en la 3 lo que
   era de la 7, o el grupo se cambia de mesa a mitad de comida.

   LO QUE SE PRUEBA ACÁ es que la pantalla llame a la función correcta con
   los datos correctos, y que NO ofrezca un camino que la base va a negar.
   Las reglas duras viven en la base y ya están probadas: `cuenta_mover` se
   niega si la destino está ocupada, e `items_mover` necesita una cuenta viva.

   Y una que no es de mover pero se comprueba de paso, porque es la que se
   olvida: el COMENTARIO tiene que llegar a la comanda. Es lo que la cocina
   lee — "sin azúcar", "sin tomate" —, y si se pierde sale un plato que hay
   que rehacer.                                                            */
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
  {id:11, cuenta_id:900, nombre:'Café Latte',       cantidad:2, precio:3400, estado:'confirmado', comentario:null},
  {id:12, cuenta_id:900, nombre:'Medialuna manjar', cantidad:1, precio:2900, estado:'confirmado', comentario:null},
  {id:13, cuenta_id:900, nombre:'Americano',        cantidad:1, precio:2500, estado:'nuevo',      comentario:'sin azúcar'},
];
const CARTA = [
  {fudo_product_id:'F-33', sede:'plaza', nombre:'Americano',        precio:2500, activo:true},
  {fudo_product_id:'F-38', sede:'plaza', nombre:'Café Latte',       precio:3400, activo:true},
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
  try { const r = await fn(); if(r===true){ok++;console.log('  ✓ '+n);}
        else {mal++;console.log('  ✗ '+n+'  → '+r);} }
  catch(e){ mal++; console.log('  ✗ '+n+'  → '+e.message.split('\n')[0]); }
};
/* Contesta el sí/no de la app sin esperar a que alguien toque. `preguntar`
   devuelve una promesa; acá se la reemplaza para poder llegar a la llamada. */
const contestar = async (v) => page.evaluate((v)=>{
  window.__preg = [];
  window.preguntar = (titulo, detalle) => { window.__preg.push({titulo, detalle}); return Promise.resolve(v); };
}, v);

console.log('\nEN COMPUTADOR, el panel NO se puede pisar con el plano:');
/* Pasó el 31 de agosto: el panel quedaba encima de la última columna de
   mesas. Con grid —una pista fija y otra `minmax(0,1fr)`— no puede volver a
   pasar, y esto lo comprueba con los rectángulos de verdad. */
await caso('el plano termina antes de donde empieza el panel', async () => {
  await page.click('[data-lamamesa="102"]'); await page.waitForTimeout(400);
  const plano = await page.evaluate(()=>{
    const r = document.querySelector('.lama-plano').getBoundingClientRect();
    return {der: Math.round(r.right)}; });
  const panel = await page.evaluate(()=>{
    const r = document.querySelector('.lama-panel').getBoundingClientRect();
    return {izq: Math.round(r.left), ancho: Math.round(r.width)}; });
  return plano.der <= panel.izq
    || `el plano llega a ${plano.der} y el panel empieza en ${panel.izq}: se pisan`;
});
await caso('y las 12 mesas se ven, ninguna tapada', async () => {
  const tapadas = await page.evaluate(()=>{
    const p = document.querySelector('.lama-panel').getBoundingClientRect();
    return [...document.querySelectorAll('[data-lamamesa]')].filter(m=>{
      const r = m.getBoundingClientRect();
      return r.right > p.left && r.left < p.right && r.bottom > p.top && r.top < p.bottom;
    }).length;
  });
  return tapadas === 0 || `${tapadas} mesa(s) quedan debajo del panel`;
});

console.log('\nEL LÁPIZ abre un menú CHICO, no cambia el panel entero:');
await caso('el menú no está hasta que se toca el lápiz', async () =>
  !(await page.isVisible('#lama-menu')) || 'el menú nace abierto');
await caso('el lápiz lo abre, con sus dos opciones', async () => {
  await page.click('[data-lamaacc="menu"]'); await page.waitForTimeout(300);
  const t = await page.textContent('#lama-menu');
  return (t.includes('Mover la mesa') && t.includes('Mover productos'))
    || 'no ofrece los dos caminos: '+t;
});
/* Lo que importa del menú chico: el cuerpo del panel SIGUE ahí detrás. Antes
   esto reemplazaba la pantalla entera y se perdía de vista la cuenta. */
await caso('y la cuenta se sigue viendo detrás', async () =>
  (await page.textContent('.lama-cuerpo')).includes('Café Latte')
  || 'el menú tapó la cuenta en vez de colgarse del botón');
/* `position` NO es un detalle: sin él Playwright toca el CENTRO de
   .lama-cuerpo, y ahí vive un botón. El manejador de la app atiende ese botón
   y hace `return` antes de llegar al cierre del menú, así que la prueba
   fallaba midiendo otra cosa. "Tocar fuera" es tocar donde no hay nada — la
   esquina del cuerpo—, que es lo que hace un dedo cuando descarta un menú. */
await caso('tocar fuera lo cierra', async () => {
  await page.click('.lama-cuerpo', {position:{x:5, y:5}}); await page.waitForTimeout(300);
  return !(await page.isVisible('#lama-menu')) || 'queda abierto y traba la pantalla';
});

console.log('\nMOVER LA MESA ENTERA:');
await caso('solo las LIBRES quedan tocables', async () => {
  await page.click('[data-lamaacc="menu"]'); await page.waitForTimeout(250);
  await page.click('[data-lamaacc="mover-mesa"]'); await page.waitForTimeout(350);
  const vivas = await page.evaluate(()=>[...document.querySelectorAll('.lama-mesa.viva')]
    .map(m=>m.dataset.lamamesa).sort());
  /* Ocupadas: 102 (origen), 106 y 107. Libres: las otras nueve. */
  return (vivas.length === 9 && !vivas.includes('106') && !vivas.includes('107'))
    || 'ofrece '+JSON.stringify(vivas);
});
await caso('la mesa de origen se marca y no se puede tocar', async () => {
  const c = await page.getAttribute('[data-lamamesa="102"]','class');
  const d = await page.evaluate(()=>document.querySelector('[data-lamamesa="102"]').disabled);
  return (c.includes('origen') && d === true) || 'origen="'+c+'" disabled='+d;
});
await caso('la banda dice de dónde sale y cómo salir', async () => {
  const t = await page.textContent('#lama-banda');
  return (t.includes('Mesa 3') && t.includes('Salir')) || 'la banda dice: '+t;
});
/* La confirmación dice los NOMBRES. Un sí/no sin sujeto es el que se aprieta
   sin leer, y mover la mesa equivocada deja a alguien pagando la cuenta de
   otro. */
/* Ojo con el destino que se elige acá: tiene que ser una mesa LIBRE. Si se
   apunta a una ocupada, el botón está `disabled` —que es lo correcto— y el
   clic no hace nada: la prueba pasaría en verde sin haber probado nada. */
/* Y ojo con CÓMO se comprueba, que acá se cayó una vez: `page.click` sobre un
   botón `disabled` no "no hace nada" — Playwright se queda esperando a que se
   habilite hasta agotar el tiempo. Lo que hay que afirmar es el candado mismo,
   que es lo que de verdad impide el toque: el botón está deshabilitado, y
   nadie preguntó nada. Intentar atravesarlo probaría un camino que en la
   pantalla no existe. */
await caso('una mesa OCUPADA no acepta el toque', async () => {
  await contestar(false);
  const d = await page.getAttribute('[data-lamamesa="107"]', 'disabled');
  const n = await page.evaluate(()=>window.__preg.length);
  if(d === null) return 'la mesa en precuenta quedó tocable, y la base la va a rechazar';
  return n === 0 || 'preguntó por una mesa que la base va a rechazar';
});
await caso('confirma con los dos nombres y el total', async () => {
  await page.click('[data-lamamesa="104"]'); await page.waitForTimeout(350);
  const p = await page.evaluate(()=>window.__preg[0]);
  return (p && p.titulo === 'Mesa 3 pasa a Mesa 5' && p.detalle.includes('12.200'))
    || 'preguntó: '+JSON.stringify(p);
});
await caso('si se cancela NO llama a la base', async () => {
  const r = await page.evaluate(()=>window.__rpc.filter(x=>x.nombre==='cuenta_mover').length);
  return r === 0 || 'movió igual, con '+r+' llamada(s)';
});
await caso('al aceptar llama a cuenta_mover con la cuenta y la mesa', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await contestar(true);
  await page.click('[data-lamamesa="103"]'); await page.waitForTimeout(500);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='cuenta_mover'));
  return (r && r.args.p_cuenta_id === 900 && r.args.p_mesa_id === 103)
    || 'mandó '+JSON.stringify(r && r.args);
});
await caso('y sale del modo mover al terminar', async () => {
  const t = (await page.textContent('#lama-banda')) || '';
  return t.trim() === '' || 'la banda sigue puesta: '+t;
});

console.log('\nMOVER ALGUNOS PRODUCTOS:');
await caso('elegir cuáles no toca el plano todavía', async () => {
  await page.click('[data-lamamesa="102"]'); await page.waitForTimeout(400);
  await page.click('[data-lamaacc="menu"]'); await page.waitForTimeout(250);
  await page.click('[data-lamaacc="mover-items"]'); await page.waitForTimeout(350);
  const n = (await page.$$('.lama-mesa.viva')).length;
  const c = (await page.$$('[data-lamaelegir]')).length;
  return (n === 0 && c === 3) || `mesas vivas ${n}, productos para elegir ${c}`;
});
/* Sin nada elegido la barra no tiene qué decir, y un botón apagado es ruido.
   Es la misma regla del taller de recetas. */
await caso('sin nada elegido no hay barra de confirmar', async () =>
  (await page.$$('.lama-barra')).length === 0 || 'muestra la barra sin nada elegido');
await caso('al marcar uno aparece, y dice cuántos', async () => {
  await page.click('[data-lamaelegir="11"]'); await page.waitForTimeout(300);
  const t = await page.textContent('.lama-barra');
  return t.includes('1 elegido') || 'la barra dice: '+t;
});
await caso('se puede desmarcar', async () => {
  await page.click('[data-lamaelegir="11"]'); await page.waitForTimeout(300);
  return (await page.$$('.lama-barra')).length === 0 || 'no se pudo desmarcar';
});
await caso('el que ya salió a la cocina se distingue del que no', async () => {
  const t = await page.textContent('[data-lamaelegir="13"]');
  return t.includes('todavía no salió') || 'no dice en qué estado está: '+t;
});
/* Y el comentario se ve acá también: si se va a mover, hay que saber que
   lleva instrucción para la cocina. */
await caso('y muestra el comentario del producto', async () =>
  (await page.textContent('[data-lamaelegir="13"]')).includes('sin azúcar')
  || 'no muestra el comentario al elegir qué mover');

console.log('\n  el destino: solo mesas YA abiertas');
await caso('las LIBRES quedan apagadas: abrir es manual', async () => {
  await page.click('[data-lamaelegir="11"]'); await page.waitForTimeout(250);
  await page.click('[data-lamaacc="a-destino"]'); await page.waitForTimeout(350);
  const vivas = await page.evaluate(()=>[...document.querySelectorAll('.lama-mesa.viva')]
    .map(m=>m.dataset.lamamesa).sort());
  return (vivas.length === 2 && vivas.includes('106') && vivas.includes('107'))
    || 'ofrece '+JSON.stringify(vivas)+' (debía ofrecer solo las abiertas)';
});
await caso('confirma con los nombres y con lo que queda', async () => {
  await contestar(false);
  await page.click('[data-lamamesa="106"]'); await page.waitForTimeout(350);
  const p = await page.evaluate(()=>window.__preg[0]);
  return (p && p.titulo.includes('de Mesa 3') && p.titulo.includes('a Mesa 7')
          && p.detalle.includes('queda con')) || 'preguntó: '+JSON.stringify(p);
});
await caso('al aceptar llama a items_mover con los ids y la cuenta destino', async () => {
  await page.evaluate(()=>{ window.__rpc = []; });
  await contestar(true);
  await page.click('[data-lamamesa="106"]'); await page.waitForTimeout(500);
  const r = await page.evaluate(()=>window.__rpc.find(x=>x.nombre==='items_mover'));
  return (r && JSON.stringify(r.args.p_items) === '[11]' && r.args.p_cuenta_id === 901)
    || 'mandó '+JSON.stringify(r && r.args);
});
/* Que NO abra la mesa destino sola es la mitad de la regla: abrir es manual
   en todo momento, también acá. */
await caso('y NUNCA llamó a mesa_abrir por su cuenta', async () => {
  const r = await page.evaluate(()=>window.__rpc.filter(x=>x.nombre==='mesa_abrir').length);
  return r === 0 || 'abrió una mesa sola: '+r+' llamada(s)';
});

console.log('\nSALIR DEL MODO MOVER:');
await caso('el botón Salir vuelve al panel', async () => {
  await page.click('[data-lamamesa="102"]'); await page.waitForTimeout(400);
  await page.click('[data-lamaacc="menu"]'); await page.waitForTimeout(250);
  await page.click('[data-lamaacc="mover-mesa"]'); await page.waitForTimeout(300);
  await page.click('[data-lamaacc="salir-mover"]'); await page.waitForTimeout(300);
  const t = (await page.textContent('#lama-banda')) || '';
  return t.trim() === '' || 'sigue en modo mover';
});
/* Un modo del que no se ve cómo salir es una pantalla trabada. */
await caso('Escape también', async () => {
  await page.click('[data-lamaacc="menu"]'); await page.waitForTimeout(250);
  await page.click('[data-lamaacc="mover-mesa"]'); await page.waitForTimeout(300);
  await page.evaluate(()=>document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape'})));
  await page.waitForTimeout(300);
  const t = (await page.textContent('#lama-banda')) || '';
  return t.trim() === '' || 'Escape no saca del modo mover';
});

console.log('\nEL COMENTARIO, y que llegue a la comanda:');
await caso('el que ya tiene comentario se ve en la línea', async () => {
  const t = await page.textContent('.lama-cuerpo');
  return t.includes('sin azúcar') || 'no muestra el comentario en la línea';
});
await caso('y se marca distinto del "+ comentario" vacío', async () => {
  const n = await page.evaluate(()=>document.querySelectorAll('.lama-linea .nm span.con').length);
  return n === 1 || 'marcó '+n+' comentarios escritos, y hay uno solo';
});
/* Ahora el comentario se escribe en la VENTANA del producto, junto con la
   cantidad. Escondido en una línea gris de 11px dentro de la fila quedaba
   opcional en la práctica, y es lo que la cocina lee. */
await caso('tocar el producto abre su ventana, con cantidad y comentario', async () => {
  await page.click('[data-lamaprod="11"]'); await page.waitForTimeout(400);
  const t = await page.textContent('.lama-pp-caja');
  return (t.includes('Comentario para la cocina') && await page.isVisible('.lama-pp-paso'))
    || 'la ventana no trae las dos cosas: '+String(t).slice(0,120);
});
await caso('se puede escribir uno nuevo, y se guarda', async () => {
  await page.fill('#lama-pp-com', 'sin leche'); await page.waitForTimeout(150);
  await page.click('[data-lamaacc="pp-guardar"]'); await page.waitForTimeout(600);
  return (await page.textContent('.lama-cuerpo')).includes('sin leche')
    || 'no quedó escrito en la línea';
});
/* LA QUE IMPORTA. El comentario es lo que la cocina lee; si no viaja a la
   comanda, sale un plato que hay que rehacer.

   Se mira el TEXTO de la comanda, no el papel dibujado en pantalla. El papel
   se sacó el 2026-08-31 —lo que lleva el comprobante se decide aparte y va a
   tener su propia pantalla— pero el texto se sigue armando igual, y es el que
   va a salir por la impresora. Probar el dato en vez del dibujo además hace
   que esta prueba sobreviva al próximo cambio de forma. */
await caso('y VIAJA a la comanda al confirmar', async () => {
  await page.click('[data-lamaacc="confirmar"]'); await page.waitForTimeout(600);
  /* `let` en el nivel superior NO cuelga de window, así que se lee el
     identificador directo: vive en el ámbito léxico global igual. */
  const papel = await page.evaluate(() => (typeof LAMA_PAPEL === 'undefined' ? null : LAMA_PAPEL));
  return (papel && papel.includes('sin azúcar'))
    || 'la comanda salió sin el comentario: '+String(papel).slice(0,160);
});

/* Y que el papel ya NO se dibuje: es el pedido de Jhon del 2026-08-31. */
await caso('pero el papel ya no se dibuja debajo de "Cerrar mesa"', async () => {
  const hay = await page.evaluate(() => !!document.querySelector('.lama-papel'));
  return hay === false || 'el detalle del ticket sigue en pantalla';
});

console.log('\nSin errores de JavaScript:');
await caso('ninguno en toda la vuelta', () => errores.length === 0 || errores.slice(0,2).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
process.exit(mal ? 1 : 0);
