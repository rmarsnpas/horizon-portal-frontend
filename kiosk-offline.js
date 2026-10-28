/*
 * kiosk-offline.js
 * Transparent offline support for the Horizon House kiosk sign-in/out pages.
 *
 * What it does:
 *  - Monkey-patches window.fetch so that calls to the sign-in/out backend
 *    (horizon-portal-backend-production-...up.railway.app) keep working even
 *    when the iPad loses WiFi:
 *      - POST /api/signInOut/in  and  /api/signInOut/out
 *          -> if the network call fails, the action is queued in
 *             localStorage and a synthetic "success" response is returned so
 *             the existing page code (unchanged) proceeds normally.
 *      - GET /api/signInOut/current
 *          -> response is cached; if offline, the last cached snapshot is
 *             returned, merged with any actions still waiting to sync so the
 *             status board / sign-in-out check stays accurate.
 *      - GET /api/members, /api/getMember
 *          -> response is cached; if offline, the last cached data is
 *             returned so member lookups still work after the first
 *             successful load.
 *  - Automatically retries queued actions once the network is back
 *    (on the 'online' event and on a periodic interval).
 *  - Shows a small banner at the top of the page while offline or while
 *    there are records waiting to sync.
 *
 * No changes are required to the existing page logic — just include this
 * script BEFORE the page's own <script> block.
 */
(function () {
    'use strict';

    var BACKEND_HOST_RE = /horizon-portal-backend-production-3532\.up\.railway\.app/;
    var QUEUE_KEY = 'kioskOfflineQueue_v1';
    var CACHE_PREFIX = 'kioskOfflineCache_v1:';

    var originalFetch = window.fetch ? window.fetch.bind(window) : null;
    var changeListeners = [];
    var flushing = false;

    function uid() {
        return 'xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            var r = (Math.random() * 16) | 0;
            var v = c === 'x' ? r : (r & 0x3) | 0x8;
            return v.toString(16);
        });
    }

    function getQueue() {
        try {
            return JSON.parse(localStorage.getItem(QUEUE_KEY) || '[]');
        } catch (e) {
            return [];
        }
    }

    function setQueue(q) {
        try {
            localStorage.setItem(QUEUE_KEY, JSON.stringify(q));
        } catch (e) { /* storage full / unavailable - ignore */ }
        changeListeners.forEach(function (fn) {
            try { fn(q); } catch (e) { /* ignore listener errors */ }
        });
    }

    function cacheGet(url) {
        try {
            return JSON.parse(localStorage.getItem(CACHE_PREFIX + url) || 'null');
        } catch (e) {
            return null;
        }
    }

    function cacheSet(url, data) {
        try {
            localStorage.setItem(CACHE_PREFIX + url, JSON.stringify(data));
        } catch (e) { /* ignore */ }
    }

    function jsonResponse(obj, status) {
        return new Response(JSON.stringify(obj), {
            status: status || 200,
            headers: { 'Content-Type': 'application/json' }
        });
    }

    // Merge any queued-but-not-yet-synced sign-in/out actions into a
    // /api/signInOut/current style payload so the status board and the
    // "is this member currently out?" check stay correct while offline.
    function applyQueueToStatus(data) {
        var membersOut = (data && Array.isArray(data.membersOut)) ? data.membersOut.slice() : [];
        var queue = getQueue();
        queue.forEach(function (action) {
            var actionId = String(action.body && action.body.memberId);
            var idx = -1;
            for (var i = 0; i < membersOut.length; i++) {
                var m = membersOut[i];
                var mid = String((m && (m.memberId != null ? m.memberId : (m.ID != null ? m.ID : m.id))) || '');
                if (mid === actionId) { idx = i; break; }
            }
            if (action.endpoint === 'out') {
                if (idx === -1) {
                    membersOut.push({
                        memberId: action.body.memberId,
                        memberName: action.body.memberName,
                        destination: action.body.destination,
                        timeOut: action.body.timeOut,
                        estimatedReturn: action.body.estimatedReturn,
                        isOverdue: false,
                        pendingSync: true
                    });
                }
            } else if (action.endpoint === 'in') {
                if (idx !== -1) membersOut.splice(idx, 1);
            }
        });
        var merged = {};
        for (var k in data) { if (Object.prototype.hasOwnProperty.call(data, k)) merged[k] = data[k]; }
        merged.membersOut = membersOut;
        return merged;
    }

    function fetchWithTimeout(input, init, ms) {
        if (typeof AbortController === 'undefined') {
            return originalFetch(input, init);
        }
        var ctrl = new AbortController();
        var merged = {};
        for (var k in init) { if (Object.prototype.hasOwnProperty.call(init, k)) merged[k] = init[k]; }
        merged.signal = ctrl.signal;
        var timer = setTimeout(function () { ctrl.abort(); }, ms);
        return originalFetch(input, merged).then(
            function (res) { clearTimeout(timer); return res; },
            function (err) { clearTimeout(timer); throw err; }
        );
    }

    function queueSignInOutAction(url, init) {
        var body = {};
        try { body = JSON.parse((init && init.body) || '{}'); } catch (e) { /* ignore */ }
        var endpoint = /\/api\/signInOut\/in\b/.test(url) ? 'in' : 'out';
        var q = getQueue();
        q.push({ id: uid(), endpoint: endpoint, body: body, queuedAt: new Date().toISOString() });
        setQueue(q);
        return jsonResponse({ success: true, queued: true, offline: true, message: 'Saved on device - will sync when connection is restored.' });
    }

    if (originalFetch) {
        window.fetch = function (input, init) {
            var url = typeof input === 'string' ? input : (input && input.url) || '';
            var method = ((init && init.method) || 'GET').toUpperCase();
            var isBackendCall = BACKEND_HOST_RE.test(url);

            if (!isBackendCall) {
                return originalFetch(input, init);
            }

            var isSignInOutPost = method === 'POST' && /\/api\/signInOut\/(in|out)\b/.test(url);
            var isStatusGet = method === 'GET' && /\/api\/signInOut\/current\b/.test(url);
            var isMembersGet = method === 'GET' && /\/api\/(members|getMember)\b/.test(url);

            if (isSignInOutPost) {
                if (typeof navigator !== 'undefined' && navigator.onLine === false) {
                    return Promise.resolve(queueSignInOutAction(url, init));
                }
                return fetchWithTimeout(input, init, 6000).catch(function () {
                    return queueSignInOutAction(url, init);
                });
            }

            if (isStatusGet) {
                var runStatus = function () {
                    return fetchWithTimeout(input, init, 5000).then(function (res) {
                        if (!res.ok) return res;
                        return res.clone().json().then(function (data) {
                            cacheSet(url, data);
                            return jsonResponse(applyQueueToStatus(data), res.status);
                        }).catch(function () { return res; });
                    }).catch(function () {
                        var cached = cacheGet(url) || { membersOut: [] };
                        return jsonResponse(applyQueueToStatus(cached));
                    });
                };
                if (typeof navigator !== 'undefined' && navigator.onLine === false) {
                    var cached = cacheGet(url) || { membersOut: [] };
                    return Promise.resolve(jsonResponse(applyQueueToStatus(cached)));
                }
                return runStatus();
            }

            if (isMembersGet) {
                var runMembers = function () {
                    return fetchWithTimeout(input, init, 6000).then(function (res) {
                        if (res.ok) {
                            res.clone().json().then(function (data) { cacheSet(url, data); }).catch(function () {});
                        }
                        return res;
                    }).catch(function () {
                        var cached = cacheGet(url);
                        if (cached !== null) return jsonResponse(cached);
                        throw new Error('offline and no cached data for ' + url);
                    });
                };
                if (typeof navigator !== 'undefined' && navigator.onLine === false) {
                    var cachedM = cacheGet(url);
                    if (cachedM !== null) return Promise.resolve(jsonResponse(cachedM));
                }
                return runMembers();
            }

            return originalFetch(input, init);
        };
    }

    function flushQueue() {
        if (flushing) return Promise.resolve({ flushed: 0, remaining: getQueue().length });
        flushing = true;
        var flushed = 0;

        function step() {
            var queue = getQueue();
            if (!queue.length) return Promise.resolve();
            if (typeof navigator !== 'undefined' && navigator.onLine === false) return Promise.resolve();

            var apiBase = window.KIOSK_API_URL;
            if (!apiBase) return Promise.resolve();

            var action = queue[0];
            var endpointPath = action.endpoint === 'in' ? '/api/signInOut/in' : '/api/signInOut/out';

            return originalFetch(apiBase + endpointPath, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(action.body)
            }).then(function (res) {
                if (!res.ok) return; // stop; keep item queued, try again later
                return res.json().catch(function () { return { success: true }; }).then(function (result) {
                    if (result && result.success === false) return; // stop, keep queued
                    var q = getQueue();
                    q.shift();
                    setQueue(q);
                    flushed++;
                    return step(); // continue with next item
                });
            }).catch(function () { /* network error mid-flush - stop for now */ });
        }

        return step().then(function () {
            flushing = false;
            return { flushed: flushed, remaining: getQueue().length };
        }, function () {
            flushing = false;
            return { flushed: flushed, remaining: getQueue().length };
        });
    }

    function startAutoSync(intervalMs) {
        window.addEventListener('online', function () { flushQueue(); updateBanner(); });
        window.addEventListener('offline', updateBanner);
        setInterval(flushQueue, intervalMs || 15000);
        setInterval(updateBanner, 5000);
        changeListeners.push(updateBanner);
        setTimeout(flushQueue, 1500);
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', updateBanner);
        } else {
            updateBanner();
        }
    }

    function updateBanner() {
        var q = getQueue();
        var offline = typeof navigator !== 'undefined' && navigator.onLine === false;
        var el = document.getElementById('kioskOfflineBanner');

        if (!offline && q.length === 0) {
            if (el) el.parentNode.removeChild(el);
            return;
        }

        if (!el) {
            el = document.createElement('div');
            el.id = 'kioskOfflineBanner';
            el.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:99998;' +
                'padding:10px 14px;font:bold 15px/1.3 "Segoe UI",Arial,sans-serif;' +
                'text-align:center;color:#fff;box-shadow:0 2px 8px rgba(0,0,0,0.25);';
            document.body.appendChild(el);
        }

        if (offline) {
            el.style.background = '#dc3545';
            el.textContent = '\u26A0 No internet connection \u2014 sign-ins/outs are being saved on this iPad' +
                (q.length ? ' (' + q.length + ' pending)' : '') + '.';
        } else {
            el.style.background = '#ffc107';
            el.style.color = '#333';
            el.textContent = 'Reconnected \u2014 syncing ' + q.length + ' saved record' + (q.length !== 1 ? 's' : '') + '\u2026';
        }
    }

    function onChange(fn) { changeListeners.push(fn); }

    window.KioskOffline = {
        getQueue: getQueue,
        flushQueue: flushQueue,
        startAutoSync: startAutoSync,
        onChange: onChange,
        updateBanner: updateBanner
    };
})();
