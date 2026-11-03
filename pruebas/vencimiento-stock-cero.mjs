/* Un producto sin stock no puede aparecer como vencido.
   node pruebas/vencimiento-stock-cero.mjs

   El caso real fue Brownie Vitrina: stock_actual 0 y una fecha residual. La
   fecha debe seguir guardada para auditoría/edición, pero no puede mostrarse
   en la tarjeta ni alimentar el resumen de vencimientos. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz=join(dirname(fileURLToPath(import.meta.url)),'..');
const html=readFileSync(join(raiz,'index.html'),'utf8');
const saca=(re,n)=>{const m=html.match(re);if(!m)throw new Error('no se encontró '+n);return m[0]};
const fuente=[
  saca(/const tieneStock = [^\n]+/,'tieneStock'),
  saca(/function vencsHTML\(p\)\{[\s\S]*?\n\}/,'vencsHTML'),
  saca(/function invResumenVencimientos\(\)\{[\s\S]*?\n\}/,'invResumenVencimientos'),
].join('\n');

const producto={id:663,producto:'Brownie Vitrina',rubro:'Vitrina de tortas',perecedero:true,stock_actual:0,vencimiento:'2026-11-01'};
const lotes={663:[{cantidad:1,vencimiento:'2026-11-01'}]};
const ctx={
  DATA:[producto],hasVenc:true,
  esPerec:p=>!!p.perecedero,
  lotesDe:id=>lotes[id]||[],
  hoyISO:()=> '2026-11-03',
  etiquetaVenc:iso=>({cls:'venc vencido',txt:iso}),
  fmt:n=>String(n),esc:s=>String(s),
};
const api=new Function(...Object.keys(ctx),fuente+'\nreturn {tieneStock,vencsHTML,invResumenVencimientos};')(...Object.values(ctx));

let fallos=0;
const caso=(nombre,ok)=>{if(ok)console.log('  ✓ '+nombre);else{fallos++;console.log('  ✗ '+nombre)}};

caso('stock 0 no pinta la fecha residual en la tarjeta',api.vencsHTML(producto)==='');
const cero=api.invResumenVencimientos();
caso('stock 0 no entra al resumen de vencidos',cero.vencidos.length===0&&cero.hoy.length===0);

producto.stock_actual=1;
caso('la misma fecha vuelve a mostrarse cuando existe stock',api.vencsHTML(producto).includes('2026-11-01'));
const uno=api.invResumenVencimientos();
caso('con stock sí alimenta el resumen',uno.vencidos.length===1&&uno.vencidos[0].producto==='Brownie Vitrina');

console.log(fallos?`\n${fallos} fallo(s)\n`:'\nla fecha sólo aparece cuando hay stock\n');
process.exit(fallos?1:0);
