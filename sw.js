// Minimal service worker — its only real job is to exist, since Chrome/Android
// require an active service worker with a fetch handler before it will offer the
// "Install app" prompt. This also gives basic offline-shell caching for the page
// itself (not the API calls, which always need a live connection).

const CACHE_NAME = 'compass-shell-v1';
const SHELL_FILES = ['/checkin.html', '/manifest.json'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(SHELL_FILES)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  // Never cache API calls — check-ins and trip pings must always hit the network.
  if (event.request.url.includes('/api/')) return;

  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
