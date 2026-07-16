'use strict';

const BUILD_VERSION = '__BUILD_VERSION__';
const APP_CACHE = `mision-admision-app-${BUILD_VERSION}`;
const CONTENT_CACHE = `mision-admision-content-${BUILD_VERSION}`;
const RUNTIME_CACHE = `mision-admision-runtime-${BUILD_VERSION}`;
const CACHE_PREFIXES = [
  'mision-admision-app-',
  'mision-admision-content-',
  'mision-admision-runtime-',
];

const APP_SHELL = __APP_SHELL__;
const CONTENT_ASSETS = __CONTENT_ASSETS__;
const APP_SHELL_SET = new Set(APP_SHELL);
const CONTENT_ASSET_SET = new Set(CONTENT_ASSETS);

function scopedUrl(path) {
  return new URL(path, self.registration.scope).toString();
}

async function cacheFiles(cacheName, paths) {
  const cache = await caches.open(cacheName);
  const batchSize = 12;
  for (let index = 0; index < paths.length; index += batchSize) {
    const batch = paths.slice(index, index + batchSize);
    await Promise.all(batch.map(async (path) => {
      const url = scopedUrl(path);
      const response = await fetch(url, {cache: 'reload'});
      if (!response.ok) {
        throw new Error(`No se pudo guardar ${path}: HTTP ${response.status}`);
      }
      await cache.put(url, response);
    }));
  }
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    await cacheFiles(APP_CACHE, APP_SHELL);
    await cacheFiles(CONTENT_CACHE, CONTENT_ASSETS);
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const cacheNames = await caches.keys();
    await Promise.all(
      cacheNames
        .filter((name) => CACHE_PREFIXES.some((prefix) =>
          name.startsWith(prefix)) &&
          ![APP_CACHE, CONTENT_CACHE, RUNTIME_CACHE].includes(name))
        .map((name) => caches.delete(name)),
    );
    await self.clients.claim();
    const clients = await self.clients.matchAll({type: 'window'});
    for (const client of clients) {
      client.postMessage({type: 'CACHE_READY', version: BUILD_VERSION});
    }
  })());
});

self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || request.headers.has('range')) return;

  const url = new URL(request.url);
  const scope = new URL(self.registration.scope);
  if (url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname)) {
    return;
  }

  const relativePath = decodeURIComponent(url.pathname.slice(scope.pathname.length)) ||
    'index.html';

  if (request.mode === 'navigate') {
    event.respondWith(networkFirstNavigation(request));
    return;
  }

  if (CONTENT_ASSET_SET.has(relativePath) || relativePath.startsWith('content/')) {
    event.respondWith(networkFirst(request, CONTENT_CACHE));
    return;
  }

  if (APP_SHELL_SET.has(relativePath)) {
    event.respondWith(cacheFirst(request, APP_CACHE));
    return;
  }

  event.respondWith(cacheFirst(request, RUNTIME_CACHE));
});

async function networkFirstNavigation(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(APP_CACHE);
      await cache.put(scopedUrl('index.html'), response.clone());
    }
    return response;
  } catch (_) {
    return (await caches.match(scopedUrl('index.html'))) ||
      (await caches.match(scopedUrl('offline.html'))) ||
      Response.error();
  }
}

async function networkFirst(request, cacheName) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(cacheName);
      await cache.put(request, response.clone());
    }
    return response;
  } catch (_) {
    return (await caches.match(request, {ignoreSearch: true})) || Response.error();
  }
}

async function cacheFirst(request, cacheName) {
  const cached = await caches.match(request, {ignoreSearch: true});
  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(cacheName);
      await cache.put(request, response.clone());
    }
    return response;
  } catch (_) {
    return Response.error();
  }
}

// Firebase Cloud Messaging comparte este mismo service worker para no competir
// con la caché offline de la PWA.
let missionAdmissionMessaging = null;
try {
  importScripts(new URL('firebase_config.js', self.location.href).toString());
  const notificationSettings = self.MISSION_ADMISSION_FIREBASE;
  if (notificationSettings?.enabled === true) {
    const sdkVersion = notificationSettings.sdkVersion || '12.16.0';
    importScripts(
      `https://www.gstatic.com/firebasejs/${sdkVersion}/firebase-app-compat.js`,
      `https://www.gstatic.com/firebasejs/${sdkVersion}/firebase-messaging-compat.js`,
    );
    firebase.initializeApp(notificationSettings.config);
    missionAdmissionMessaging = firebase.messaging();
    missionAdmissionMessaging.onBackgroundMessage(async (payload) => {
      // Los mensajes con payload notification ya son mostrados por FCM.
      // Solo creamos una notificación para mensajes exclusivamente de datos.
      if (payload.notification) return;
      const title = payload.data?.title || 'Misión Admisión';
      const body = payload.data?.body || 'Completa el reto de hoy.';
      const link = payload.data?.link || './';
      await self.registration.showNotification(title, {
        body,
        icon: scopedUrl('icons/Icon-192.png'),
        badge: scopedUrl('icons/Icon-192.png'),
        tag: payload.data?.tag || 'mision-admision-reminder',
        renotify: false,
        data: {missionAdmission: true, link},
      });
    });
  }
} catch (error) {
  console.warn('FCM no fue inicializado:', error);
}

self.addEventListener('notificationclick', (event) => {
  if (event.notification.data?.missionAdmission !== true) return;
  event.notification.close();
  const destination = new URL(
    event.notification.data?.link || './',
    self.registration.scope,
  ).toString();
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    });
    for (const client of windows) {
      if (new URL(client.url).origin === new URL(destination).origin) {
        await client.focus();
        if ('navigate' in client) await client.navigate(destination);
        return;
      }
    }
    await self.clients.openWindow(destination);
  })());
});
