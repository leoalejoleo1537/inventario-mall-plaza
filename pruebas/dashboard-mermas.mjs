/* Dashboard de mermas: cálculo, interacción y auditoría.
   Se corre con CHROME_PATH=/usr/bin/chromium node pruebas/dashboard-mermas.mjs
   y usa la pantalla real con Supabase simulado. */
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { abrirNavegador } from './navegador.mjs';

const raiz=join(dirname(fileURLToPath(import.meta.url)),'..');
const html=readFileSync(join(raiz,'index.html'),'utf8');
let ok=0,mal=0;
const caso=async(nombre,fn)=>{
  try{const r=await fn();if(r===true){ok++;console.log('  ✓ '+nombre);}
    else{mal++;console.log('  ✗ '+nombre+' → '+r);}}
  catch(e){mal++;console.log('  ✗ '+nombre+' → '+e.message.split('\n')[0]);}
};

console.log('\nLa arquitectura queda protegida incluso sin navegador:');
await caso('ignora respuestas viejas al cambiar rápido de período',()=>
  html.includes('if(carga!==MERMAS_CARGA_ID)return;')||'falta el identificador de carga');
await caso('Excel pide todo el historial y no reutiliza el período visible',()=>
  html.includes("const {data,error}=await merLeer('all')")||'Excel quedó atado al filtro');
await caso('el dashboard compara todas las sedes aunque se entre desde un local',()=>
  html.includes("merLeer(periodo,'central')")&&html.includes("resumirMermas(MERMAS,'central',periodo)")||'la vista quedó acotada a la sede activa');
await caso('no depende de una librería de gráficos',()=>
  !/chart\.js|highcharts|apexcharts/i.test(html)||'apareció una dependencia de gráficos');
await caso('las líneas se construyen como curvas y no como segmentos angulosos',()=>
  html.includes('camino+=` C${c1x.toFixed(2)}')||'falta la curva cúbica');
await caso('respeta reducir movimiento',()=>
  html.includes('@media(prefers-reduced-motion:reduce)')||'falta la regla de movimiento reducido');

const browser=await abrirNavegador();
if(!browser){console.log('\n(se salta la pantalla: no hay navegador instalado)\n');process.exit(mal?1:0);}

const hace=d=>new Date(Date.now()-d*86400000).toISOString();
const MOVIMIENTOS=[
  {id:1,sede:'plaza',producto_id:11,producto:'Producto A',tipo:'merma',cantidad:-3,motivo:'vencimiento',quien:'Ana',created_at:hace(0),deshecha_at:null},
  {id:2,sede:'plaza',producto_id:11,producto:'Producto A',tipo:'merma',cantidad:-2,motivo:'daño',quien:'Ana',created_at:hace(1),deshecha_at:null},
  {id:3,sede:'angamos',producto_id:21,producto:'Producto B',tipo:'merma',cantidad:-4,motivo:'vencimiento',quien:'Beto',created_at:hace(2),deshecha_at:null},
  {id:4,sede:'plaza',producto_id:12,producto:'Producto C',tipo:'merma',cantidad:-1,motivo:'otro',quien:'Ana',created_at:hace(3),deshecha_at:null},
  {id:5,sede:'plaza',producto_id:13,producto:'Producto D',tipo:'merma',cantidad:-1,motivo:'daño',quien:'Ana',created_at:hace(4),deshecha_at:null},
  {id:6,sede:'plaza',producto_id:14,producto:'Producto E',tipo:'merma',cantidad:-1,motivo:'daño',quien:'Ana',created_at:hace(5),deshecha_at:null},
  {id:7,sede:'plaza',producto_id:15,producto:'Producto F',tipo:'merma',cantidad:-1,motivo:'otro',quien:'Ana',created_at:hace(6),deshecha_at:null},
  {id:8,sede:'plaza',producto_id:16,producto:'Producto G',tipo:'merma',cantidad:-2,motivo:'vencimiento',quien:'Ana',created_at:hace(6),deshecha_at:null},
  {id:9,sede:'plaza',producto_id:17,producto:'Producto H',tipo:'merma',cantidad:-1,motivo:'otro',quien:'Ana',created_at:hace(6),deshecha_at:null},
  {id:10,sede:'plaza',producto_id:18,producto:'Producto I',tipo:'merma',cantidad:-1,motivo:'daño',quien:'Ana',created_at:hace(6),deshecha_at:null},
  {id:11,sede:'plaza',producto_id:19,producto:'Producto J',tipo:'merma',cantidad:-1,motivo:'otro',quien:'Ana',created_at:hace(6),deshecha_at:null},
  {id:12,sede:'plaza',producto_id:20,producto:'Producto K',tipo:'merma',cantidad:-1,motivo:'daño',quien:'Ana',created_at:hace(10),deshecha_at:null},
  {id:13,sede:'plaza',producto_id:30,producto:'Producto antiguo',tipo:'merma',cantidad:-50,motivo:'vencimiento',quien:'Ana',created_at:hace(40),deshecha_at:null},
  {id:14,sede:'plaza',producto_id:31,producto:'Merma deshecha',tipo:'merma',cantidad:-99,motivo:'vencimiento',quien:'Ana',created_at:new Date(Date.now()+60000).toISOString(),deshecha_at:hace(0)},
];

const page=await browser.newPage({viewport:{width:1440,height:1000}});
const servidor=createServer((req,res)=>{
  if(req.url==='/'||req.url==='/index.html'){
    res.writeHead(200,{'content-type':'text/html; charset=utf-8'});res.end(html);return;
  }
  res.writeHead(404);res.end('no encontrado');
});
await new Promise(resolve=>servidor.listen(0,'127.0.0.1',resolve));
const puerto=servidor.address().port;
await page.addInitScript(({MOVIMIENTOS})=>{
  const SES={user:{id:'u1',email:'prueba@cafe.cl',user_metadata:{nombre:'Prueba'}}};
  const T={
    movimientos:MOVIMIENTOS,productos:[],producto_lotes:[],producto_enlace:[],fudo_stock_push:[],
    app_permisos:[{correo:'prueba@cafe.cl',nombre:'Prueba',puede_ajustes:true,puede_editar:true,puede_fudo:true,fudo_bloqueos:[]}],
    fudo_sync:[],secciones:[],ajustes:[],metas:[],historial:[],restauraciones:[],fusiones:[],recetas:[],receta_items:[],
    fudo_productos:[],repartos:[],reparto_items:[],tareas:[],fudo_categorias:[],envios_franquicia:[],envios_franquicia_items:[]
  };
  window.__tables=T;window.__rpcs=[];window.__xlsx=null;window.__failMermas=false;
  const q=nombre=>{
    let filas=JSON.parse(JSON.stringify(T[nombre]||[]));
    const api={
      select(){return api;},eq(c,v){filas=filas.filter(f=>String(f[c])===String(v));return api;},
      neq(c,v){filas=filas.filter(f=>String(f[c])!==String(v));return api;},
      in(c,vs){filas=filas.filter(f=>vs.map(String).includes(String(f[c])));return api;},
      gte(c,v){filas=filas.filter(f=>String(f[c])>=String(v));return api;},
      lte(c,v){filas=filas.filter(f=>String(f[c])<=String(v));return api;},
      lt(c,v){filas=filas.filter(f=>String(f[c])<String(v));return api;},
      is(c,v){filas=filas.filter(f=>(f[c]??null)===v);return api;},not(){return api;},or(){return api;},ilike(){return api;},
      order(c,o){const asc=!o||o.ascending!==false;filas.sort((a,b)=>String(a[c]??'').localeCompare(String(b[c]??''))*(asc?1:-1));return api;},
      limit(n){filas=filas.slice(0,n);return api;},
      range(a,b){return Promise.resolve(window.__failMermas&&nombre==='movimientos'
        ?{data:null,error:{message:'falla simulada'}}:{data:filas.slice(a,b+1),error:null,count:filas.length});},
      maybeSingle(){return Promise.resolve({data:filas[0]||null,error:null});},single(){return Promise.resolve({data:filas[0]||null,error:null});},
      insert(){return api;},update(){return api;},upsert(){return api;},delete(){return api;},
      then(fn){return Promise.resolve({data:filas,error:null,count:filas.length}).then(fn)}
    };return api;
  };
  window.supabase={createClient:()=>({
    from:q,rpc:(nombre,args)=>{window.__rpcs.push({nombre,args});return Promise.resolve({data:{},error:null});},
    auth:{getSession:async()=>({data:{session:SES}}),getUser:async()=>({data:{user:SES.user}}),
      onAuthStateChange(cb){setTimeout(()=>cb&&cb('SIGNED_IN',SES),0);return{data:{subscription:{unsubscribe(){}}}};},
      signInWithPassword:async()=>({data:{session:SES},error:null}),signOut:async()=>({})},
    channel:()=>({on(){return this;},subscribe(cb){cb&&cb('SUBSCRIBED');return this;},track:async()=>{},presenceState:()=>({})}),
    removeChannel(){},functions:{invoke:async()=>({data:{},error:null})}
  })};
  window.XLSX={utils:{json_to_sheet:filas=>({filas}),book_new:()=>({Sheets:{},SheetNames:[]}),
    book_append_sheet:(wb,ws,n)=>{wb.Sheets[n]=ws;wb.SheetNames.push(n);}},
    writeFile:wb=>{window.__xlsx=wb.Sheets[wb.SheetNames[0]].filas;}};
},{MOVIMIENTOS});
await page.route('**/supabase-js*',r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
await page.route('**/xlsx.full.min.js',r=>r.fulfill({status:200,contentType:'application/javascript',body:''}));
const errores=[];page.on('pageerror',e=>errores.push(String(e)));
await page.goto(`http://127.0.0.1:${puerto}/index.html`);
await page.waitForTimeout(350);
await page.click('.gate-btn[data-sede="plaza"]');
await page.waitForTimeout(700);
await page.click('#tabMermas');
await page.waitForFunction(()=>document.querySelectorAll('#mermas-kpis .mer-kpi').length===5);

console.log('\nResumen de 30 días:');
await caso('cinco indicadores y 19 unidades activas',async()=>{
  const t=await page.locator('#mermas-kpis').innerText();return (t.includes('19')&&await page.locator('#mermas-kpis .mer-kpi').count()===5)||t;
});
await caso('la merma deshecha no infla los indicadores',async()=>
  !(await page.locator('#mermas-kpis').innerText()).includes('99')||'contó la deshecha');
await caso('Producto A gana por 5 unidades y 2 registros',async()=>{
  const t=await page.locator('#mermas-productos .mer-producto').first().innerText();return (t.includes('Producto A')&&t.includes('5 un.')&&t.includes('2 reg.'))||t;
});
await caso('el desempate prioriza la merma más reciente y luego el nombre',async()=>await page.evaluate(()=>{
  const base={sede:'plaza',tipo:'merma',cantidad:-2,motivo:'otro',deshecha_at:null};
  const r=resumirMermas([
    {...base,id:90,producto:'Alpha',producto_id:90,created_at:'2026-10-01T12:00:00Z'},
    {...base,id:91,producto:'Beta',producto_id:91,created_at:'2026-10-02T12:00:00Z'},
  ],'plaza');
  return r.productos[0].nombre==='Beta';
})||'orden incorrecto');
await caso('la auditoría conserva la deshecha y limita la lista a diez',async()=>{
  const n=await page.locator('#mermas-list .mer-fila').count(),t=await page.locator('#mermas-list').innerText();
  return (n===10&&t.includes('Merma deshecha')&&t.includes('Deshecha'))||`${n} filas · ${t}`;
});

console.log('\nGráficas y detalle:');
await caso('las barras muestran Plaza, Angamos y Bodega',async()=>{
  const t=await page.locator('#mermas-sedes').innerText();return ['Mall Plaza','Angamos','Bodega'].every(x=>t.includes(x))||t;
});
await page.hover('#mermas-sedes [data-mer-key="plaza"]');
await caso('hover de sede muestra sus productos recientes',async()=>{
  const t=await page.locator('#mermas-tooltip').innerText();return (t.includes('Mall Plaza')&&t.includes('Producto A'))||t;
});
await caso('el anillo tiene segmentos y cantidades visibles',async()=>{
  const n=await page.locator('.mer-anillo-seg').count(),t=await page.locator('.mer-leyenda').innerText();return (n>=3&&t.includes('Vencimiento'))||`${n} · ${t}`;
});
await caso('el historial separa Mall Plaza y Parque Angamos en dos líneas',async()=>{
  const n=await page.locator('#mermas-historia .mer-historia-linea').count();
  const r=await page.evaluate(()=>MERMAS_RESUMEN.historialVencimientos.reduce((a,d)=>({plaza:a.plaza+d.plaza,angamos:a.angamos+d.angamos,total:a.total+d.total}),{plaza:0,angamos:0,total:0}));
  return (n===2&&r.plaza===5&&r.angamos===4&&r.total===9)||`${n} líneas · ${JSON.stringify(r)}`;
});
await caso('abre en Semana para que la tendencia histórica sea legible',async()=>
  (await page.getAttribute('[data-mer-historia-escala="semana"]','aria-pressed'))==='true'||'no abrió en Semana');
await caso('las dos sedes usan líneas continuas y suavizadas',async()=>{
  const rutas=await page.locator('#mermas-historia .mer-historia-linea').evaluateAll(xs=>xs.map(x=>({d:x.getAttribute('d'),clase:x.className.baseVal})));
  return (rutas.length===2&&rutas.every(x=>x.d.includes(' C')&&!x.clase.includes('trazos')))||JSON.stringify(rutas);
});
await caso('la merma vencida deshecha tampoco entra a la línea histórica',async()=>{
  const r=await page.evaluate(()=>MERMAS_RESUMEN.historialVencimientos.reduce((a,d)=>a+d.total,0));return r===9||r;
});
await page.hover('#mermas-historia .mer-historia-punto');
await caso('el detalle diario muestra ambas sedes y el total',async()=>{
  const t=await page.locator('#mermas-tooltip').innerText();return (t.includes('Mall Plaza')&&t.includes('Parque Angamos')&&t.includes('Total'))||t;
});
await page.click('[data-mer-historia-modo="total"]');
await caso('el botón Total fusiona ambas sedes en una línea',async()=>{
  const n=await page.locator('#mermas-historia .mer-historia-linea').count(),p=await page.getAttribute('[data-mer-historia-modo="total"]','aria-pressed');
  return (n===1&&p==='true')||`${n} líneas · pressed ${p}`;
});
await page.click('[data-mer-historia-modo="sedes"]');
await page.click('[data-mer-historia-escala="semana"]');
await caso('Semana agrupa sin perder unidades',async()=>await page.evaluate(()=>
  MERMAS_HISTORIA_VISIBLE.length===5&&MERMAS_HISTORIA_VISIBLE.reduce((a,d)=>a+d.total,0)===9
)||'agrupación semanal incorrecta');
await page.click('[data-mer-historia-escala="mes"]');
await caso('Mes agrupa octubre y noviembre',async()=>await page.evaluate(()=>
  MERMAS_HISTORIA_VISIBLE.length===2&&MERMAS_HISTORIA_VISIBLE.reduce((a,d)=>a+d.total,0)===9
)||'agrupación mensual incorrecta');
await page.click('[data-mer-historia-escala="año"]');
await caso('Año permanece disponible aunque sólo exista un punto',async()=>await page.evaluate(()=>
  MERMAS_HISTORIA_VISIBLE.length===1&&MERMAS_HISTORIA_VISIBLE[0].total===9
)||'agrupación anual incorrecta');
await page.click('[data-mer-historia-escala="dia"]');
await caso('Día recupera los treinta puntos del período',async()=>await page.evaluate(()=>
  MERMAS_HISTORIA_VISIBLE.length===30&&MERMAS_HISTORIA_VISIBLE.reduce((a,d)=>a+d.total,0)===9
)||'agrupación diaria incorrecta');
await page.click('[data-mer-historia-escala="semana"]');
if(process.env.CAPTURAR_MERMAS){
  await page.waitForTimeout(500);
  await page.screenshot({path:'/tmp/dashboard-mermas-desktop.png',fullPage:true});
}
await page.hover('.mer-leyenda [data-mer-key="vencimiento"]');
await caso('hover del anillo entrega unidades y porcentaje',async()=>{
  const t=await page.locator('#mermas-tooltip').innerText();return (t.includes('Vencimiento')&&t.includes('Participación'))||t;
});
await page.focus('.mer-leyenda [data-mer-key="daño"]');
await caso('el teclado abre el detalle del motivo enfocado',async()=>{
  const t=await page.locator('#mermas-tooltip').innerText();return t.includes('Daño')||t;
});
await page.click('#mermas-productos .mer-producto');
await caso('el toque abre el desglose del producto',async()=>{
  const t=await page.locator('#mermas-tooltip').innerText();return (t.includes('Producto A')&&t.includes('Mall Plaza'))||t;
});

console.log('\nPeríodos, alcance y fallos:');
await page.click('[data-mer-periodo="7"]');
await page.waitForFunction(()=>document.querySelector('[data-mer-periodo="7"]').getAttribute('aria-pressed')==='true'&&document.querySelector('#mermas-kpis').innerText.includes('18'));
await caso('siete días excluye la fila de hace diez días',async()=>
  (await page.locator('#mermas-kpis').innerText()).includes('18')||'no dio 18');
await page.click('[data-mer-periodo="all"]');
await page.waitForFunction(()=>document.querySelector('#mermas-productos .mer-producto')?.innerText.includes('Producto antiguo'));
await caso('Todo incluye las 50 unidades antiguas',async()=>
  (await page.locator('#mermas-kpis').innerText()).includes('69')||'no dio 69');
await caso('Todo incorpora también el vencimiento antiguo a la historia',async()=>{
  const n=await page.evaluate(()=>MERMAS_RESUMEN.historialVencimientos.reduce((a,d)=>a+d.total,0));return n===59||n;
});
await caso('el alcance local sólo resume las filas de su cafetería',async()=>await page.evaluate(async()=>{
  const r=await merLeer('all','plaza'),s=resumirMermas(r.data,'plaza');
  return s.sedes.length===1&&s.sedes[0].clave==='plaza'&&s.unidades===65;
})||'mezcló sedes');
await caso('los límites de siete días empiezan y terminan en Santiago',async()=>await page.evaluate(()=>{
  const r=merRango('7'),hoy=merHoySantiago();
  const local=iso=>new Intl.DateTimeFormat('en-CA',{timeZone:'America/Santiago',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(iso));
  const inicio=new Date(hoy+'T12:00:00Z');inicio.setUTCDate(inicio.getUTCDate()-6);
  return local(r.desde)===inicio.toISOString().slice(0,10)&&local(new Date(Date.parse(r.hasta)-1).toISOString())===hoy;
})||'límites incorrectos');
await page.evaluate(()=>{window.__failMermas=true});
await page.click('[data-mer-periodo="30"]');await page.waitForTimeout(180);
await caso('si falla, vuelve al último período correcto y conserva los datos',async()=>{
  const on=await page.getAttribute('[data-mer-periodo="all"]','aria-pressed');
  const t=await page.locator('#mermas-kpis').innerText();return (on==='true'&&t.includes('69'))||`${on} · ${t}`;
});
await page.evaluate(()=>{window.__failMermas=false});

console.log('\nExcel y acción esencial:');
await page.click('#btnMermasExcel');await page.waitForFunction(()=>Array.isArray(window.__xlsx));
await caso('Excel descarga las 13 operaciones de Mall Plaza, incluida la antigua y la deshecha',async()=>{
  const r=await page.evaluate(()=>window.__xlsx);return (r.length===13&&r.some(x=>x.Producto==='Producto antiguo')&&r.some(x=>x.Deshecha==='SÍ'))||r.length;
});
await page.evaluate(()=>{window.preguntar=async()=>true});
await page.click('#mermas-list [data-desmerma]');await page.waitForTimeout(150);
await caso('Deshacer sigue llamando la misma función de base',async()=>{
  const r=await page.evaluate(()=>window.__rpcs);return r.some(x=>x.nombre==='deshacer_merma')||JSON.stringify(r);
});
await caso('un período vacío produce ceros reales',async()=>await page.evaluate(()=>{
  const r=resumirMermas([],'plaza','7');return r.unidades===0&&r.registros===0&&r.productos.length===0&&r.recientes.length===0
    &&r.historialVencimientos.length===7&&r.historialVencimientos.every(d=>d.total===0);
})||'estado vacío incorrecto');

console.log('\nResponsive, movimiento y salud:');
await page.setViewportSize({width:768,height:900});
if(process.env.CAPTURAR_MERMAS){
  await page.evaluate(()=>document.querySelector('#toast')?.classList.remove('open'));
  await page.waitForTimeout(500);
  await page.screenshot({path:'/tmp/dashboard-mermas-tableta.png',fullPage:true});
}
await caso('en tableta no aparece desplazamiento horizontal',async()=>await page.evaluate(()=>{
  const ok=document.documentElement.scrollWidth<=document.documentElement.clientWidth;
  if(ok)return true;
  const bad=[...document.querySelectorAll('#view-mermas *')].filter(e=>e.getBoundingClientRect().right>innerWidth+1).slice(0,5)
    .map(e=>`${e.tagName.toLowerCase()}${e.id?'#'+e.id:''}${e.className&&typeof e.className==='string'?'.'+e.className.trim().replaceAll(' ','.'):''}:${Math.round(e.getBoundingClientRect().right)}`);
  return bad.join(', ')||`${document.documentElement.scrollWidth}/${innerWidth}`;
}));
await page.setViewportSize({width:390,height:844});
if(process.env.CAPTURAR_MERMAS){
  await page.evaluate(()=>document.querySelector('#toast')?.classList.remove('open'));
  await page.waitForTimeout(500);
  await page.screenshot({path:'/tmp/dashboard-mermas-telefono.png',fullPage:true});
}
await caso('en teléfono no aparece desplazamiento horizontal',async()=>
  await page.evaluate(()=>document.documentElement.scrollWidth<=document.documentElement.clientWidth)||'hay desborde');
await page.emulateMedia({reducedMotion:'reduce'});
await caso('movimiento reducido deja el anillo quieto',async()=>{
  const n=await page.locator('.mer-anillo-seg').first().evaluate(e=>getComputedStyle(e).animationName);return n==='none'||n;
});
await caso('movimiento reducido dibuja la línea sin transición',async()=>{
  const t=await page.locator('.mer-historia-linea').first().evaluate(e=>getComputedStyle(e).transitionDuration);return t==='0s'||t;
});
await caso('sin errores JavaScript',()=>errores.length===0||errores.slice(0,3).join(' · '));

console.log(`\n${ok} bien · ${mal} mal\n`);
await browser.close();
await new Promise(resolve=>servidor.close(resolve));
process.exit(mal?1:0);
