// Service Worker for FOC - Future Operators Course
// Caches all self-contained HTML pages for offline use
const CACHE_NAME = 'foc-v2';
const PAGES = [
  './',
  './index.html',
  './404.html',
  './instructor.html',
  '../courses/scripting/python/Challenges1.html',
  '../courses/scripting/powershell/Challenges2.html',
  '../courses/scripting/batch/Challenges3.html',
  '../courses/scripting/bash/Challenges4.html',
  '../courses/scripting/data-apis/Challenges5.html',
  '../courses/scripting/bash/BashTerminal.html',
  '../courses/scripting/python/PythonTerminal.html',
  '../courses/networking-fundamentals/subnetting.html',
  '../courses/networking-fundamentals/syntax-drill.html',
  '../courses/networking-fundamentals/hex.html',
  '../courses/networking-fundamentals/bitflip.html',
  '../courses/networking-fundamentals/invaders.html',
  '../courses/networking-fundamentals/quest.html',
  '../courses/networking-fundamentals/tower.html',
  '../courses/networking-fundamentals/pcap-challenge.html',
  '../courses/networking-fundamentals/SubnettingSheet.html',
];

// Install: pre-cache all self-contained pages
self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PAGES))
      .then(() => self.skipWaiting())
  );
});

// Activate: clean up old caches
self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// Fetch: network-first for HTML, cache-first for CDN assets
self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);

  // For same-origin HTML pages: network first, fall back to cache
  if (url.origin === location.origin) {
    e.respondWith(
      fetch(e.request)
        .then(res => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
          return res;
        })
        .catch(() => caches.match(e.request))
    );
    return;
  }

  // For CDN resources (fonts, xterm, pyodide): cache first, fall back to network
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        if (res.ok) {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        }
        return res;
      });
    })
  );
});
