// Service worker mínimo: existe solo para que la app sea instalable.
// NO guarda caché — todo va siempre a la red, así la app nunca queda
// "pegada" en una versión vieja y las actualizaciones llegan al instante.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', () => { /* passthrough: sin caché */ });
