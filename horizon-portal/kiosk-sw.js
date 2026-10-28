/*
 * kiosk-sw.js
 * App-shell service worker for the Horizon House kiosk pages.
 *
 * Purpose: let a kiosk iPad reload/boot the sign-in/out page even with
 * zero network connection, by caching the kiosk HTML + offline-helper
 * script the first time they load successfully.
 *
 * Scoped narrowly (see registration call in each kiosk-*.html file) to
 * "./kiosk-" so it never interferes with any other service worker or page
 * in this site.
 */
'use strict';

var CACHE_NAME = 'kiosk-shell-v1';
var ASSETS = [
    'kiosk-signin.html',
    'kiosk-men.html',
    'kiosk-men-RFTCPC1A.html',
    'kiosk-women.html',
    'kiosk-women-RFTCPC1A.html',
    'kiosk-offline.js'
];

self.addEventListener('install', function (event) {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(function (cache) {
                return Promise.all(
                    ASSETS.map(function (url) {
                        return cache.add(url).catch(function () { /* file may not exist in this dir - skip */ });
                    })
                );
            })
            .then(function () { return self.skipWaiting(); })
    );
});

self.addEventListener('activate', function (event) {
    event.waitUntil(
        caches.keys()
            .then(function (keys) {
                return Promise.all(
                    keys.filter(function (k) { return k !== CACHE_NAME; })
                        .map(function (k) { return caches.delete(k); })
                );
            })
            .then(function () { return self.clients.claim(); })
    );
});

self.addEventListener('fetch', function (event) {
    var req = event.request;
    var url = new URL(req.url);

    // Only manage same-origin GET requests for our own shell files.
    // Everything else (notably the cross-origin Railway API calls) is left
    // completely alone and handled by the normal network stack.
    if (req.method !== 'GET' || url.origin !== self.location.origin) {
        return;
    }

    event.respondWith(
        caches.match(req).then(function (cached) {
            var network = fetch(req).then(function (res) {
                if (res && res.ok) {
                    caches.open(CACHE_NAME).then(function (cache) { cache.put(req, res.clone()); });
                }
                return res;
            }).catch(function () { return cached; });
            // Stale-while-revalidate: serve cache instantly if we have it,
            // refresh in the background; fall back to network if not cached.
            return cached || network;
        })
    );
});
