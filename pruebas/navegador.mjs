/* Encontrar el navegador, sin bajarse uno.
   ---------------------------------------------------------------------------
   Las pruebas de pantalla necesitan un Chromium. La máquina ya trae uno, pero
   Playwright espera encontrarlo en una carpeta con el número de SU versión
   (`chromium_headless_shell-1234`), y si la instalada es otra —acá era la
   1194— falla diciendo que el ejecutable no existe.

   Antes la ruta estaba escrita a mano como `/opt/pw-browsers/chromium`, que
   es una CARPETA y no el programa: `existsSync` decía que sí, se le pasaba
   igual, y reventaba. Un chequeo que mira la carpeta en vez del ejecutable no
   comprueba nada.

   Acá se busca el ejecutable de verdad, y si no aparece se dice y la prueba
   se salta en vez de fallar por algo que no es del código.                  */
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

export function rutaChrome(){
  if (process.env.CHROME_PATH && existsSync(process.env.CHROME_PATH)) return process.env.CHROME_PATH;
  const base = process.env.PLAYWRIGHT_BROWSERS_PATH || '/opt/pw-browsers';
  if (!existsSync(base)) return null;
  const candidatos = [];
  for (const d of readdirSync(base)) {
    for (const sub of ['chrome-linux/chrome', 'chrome-linux/headless_shell',
                       'chrome-linux64/chrome', 'chrome-headless-shell-linux64/chrome-headless-shell']) {
      const p = join(base, d, sub);
      if (existsSync(p)) candidatos.push(p);
    }
  }
  /* El chrome completo antes que el headless_shell: el shell no sabe abrir
     ventanas ni descargar, y alguna prueba futura lo va a necesitar. */
  return candidatos.sort((a,b) => (a.includes('headless') ? 1 : 0) - (b.includes('headless') ? 1 : 0))[0] || null;
}

/* Abre el navegador ya configurado. Devuelve null si no hay ninguno, para que
   quien llame decida si se salta o falla. */
export async function abrirNavegador(){
  let chromium;
  try { ({ chromium } = await import('playwright')); }
  catch { return null; }
  const exe = rutaChrome();
  if (!exe) return null;
  return chromium.launch({ executablePath: exe, args: ['--no-sandbox'] });
}
