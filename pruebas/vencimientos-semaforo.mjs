/* El resumen de vencimientos siempre comunica un estado: bien, vence hoy o
   ya venció. Este contrato evita que un retoque visual invierta la gravedad. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const raiz=join(dirname(fileURLToPath(import.meta.url)),'..');
const html=readFileSync(join(raiz,'index.html'),'utf8');
const bloque=html.match(/function invEstadoVencimientos\(r\)\{[\s\S]*?\n\}/)?.[0];
if(!bloque)throw new Error('No se encontró invEstadoVencimientos');
const estado=new Function('fmt',bloque+'\nreturn invEstadoVencimientos;')(n=>String(n));
let ok=0,mal=0;
const caso=(nombre,condicion)=>{if(condicion){ok++;console.log('  ✓ '+nombre);}else{mal++;console.log('  ✗ '+nombre);}};

console.log('\nSemáforo tenue de vencimientos:');
caso('sin productos queda verde',estado({vencidos:[],hoy:[]}).estado==='verde');
caso('si sólo vencen hoy queda ámbar',estado({vencidos:[],hoy:[{cantidad:6}]}).estado==='ambar');
caso('cualquier vencido domina y queda rojo',estado({vencidos:[{cantidad:2}],hoy:[{cantidad:9}]}).estado==='rojo');
caso('el resumen rojo conserva también lo que vence hoy',estado({vencidos:[{cantidad:2}],hoy:[{cantidad:9}]}).resumen.includes('2 unidades vencidas · 9 unidades vencen hoy'));
caso('el reloj extraño desapareció',!html.includes('aria-hidden="true">◷</span>'));
caso('la cabecera usa una campana SVG',html.includes('class="inv-venc-ico" aria-hidden="true"><svg')&&html.includes('M18 8a6 6 0 0 0-12 0'));
caso('los tres estados tienen una clase visual propia',['estado-verde','estado-ambar','estado-rojo'].every(x=>html.includes('.inv-venc.'+x)));
caso('la luz permanece tenue',html.includes('rgba(var(--inv-venc-rgb),.075)'));
caso('el estado sano sigue visible',html.includes("return {estado:'verde',resumen:'Sin vencimientos pendientes'}")&&html.includes("card.style.display='block'"));

console.log(`\n${ok} bien · ${mal} mal\n`);
process.exit(mal?1:0);
