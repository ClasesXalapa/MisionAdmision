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

async function cacheFiles(cacheName, paths, {required = []} = {}) {
  const cache = await caches.open(cacheName);
  const requiredSet = new Set(required);
  const failures = [];
  const batchSize = 12;

  for (let index = 0; index < paths.length; index += batchSize) {
    const batch = paths.slice(index, index + batchSize);
    const results = await Promise.allSettled(batch.map(async (path) => {
      const url = scopedUrl(path);
      const response = await fetch(url, {cache: 'reload'});
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      await cache.put(url, response);
    }));

    results.forEach((result, offset) => {
      if (result.status === 'fulfilled') return;
      const path = batch[offset];
      failures.push({path, reason: String(result.reason)});
    });
  }

  const requiredFailures = failures.filter((failure) =>
    requiredSet.has(failure.path));
  if (requiredFailures.length > 0) {
    throw new Error(
      `No se pudo preparar la PWA: ${requiredFailures.map((failure) =>
        failure.path).join(', ')}`,
    );
  }
  if (failures.length > 0) {
    console.warn('Recursos opcionales no almacenados:', failures);
  }
  return failures;
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    await cacheFiles(APP_CACHE, APP_SHELL, {
      required: [
        'index.html',
        'offline.html',
        'manifest.json',
        'flutter_bootstrap.js',
        'main.dart.js',
        'pwa_bridge.js',
        'firebase_config.js',
        'notifications_bridge.js',
      ],
    });
    await cacheFiles(CONTENT_CACHE, CONTENT_ASSETS);
    await self.skipWaiting();
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
let missionAdmissionNotificationSettings = null;

function safeNotificationDestination(value) {
  const fallback = missionAdmissionNotificationSettings?.defaultNotificationLink || '#/reto';
  try {
    const scope = new URL(self.registration.scope);
    const candidate = new URL(value || fallback, scope);
    if (candidate.origin !== scope.origin || !candidate.pathname.startsWith(scope.pathname)) {
      return new URL(fallback, scope).toString();
    }
    return candidate.toString();
  } catch (_) {
    return new URL(fallback, self.registration.scope).toString();
  }
}

function missionAdmissionNotificationOptions(payload) {
  const data = payload?.data || {};
  return {
    body: payload?.notification?.body || data.body || 'Completa el reto de hoy.',
    icon: scopedUrl('icons/Icon-192.png'),
    badge: scopedUrl('icons/Icon-192.png'),
    tag: data.tag || 'mision-admision-reminder',
    renotify: false,
    data: {
      missionAdmission: true,
      link: safeNotificationDestination(
        payload?.fcmOptions?.link || data.link,
      ),
    },
  };
}

// Debe registrarse antes de importar Firebase. De otro modo, FCM puede
// reemplazar el comportamiento personalizado del clic.
self.addEventListener('notificationclick', (event) => {
  const notificationData = event.notification.data || {};
  const fcmMessage = notificationData.FCM_MSG || null;
  const belongsToMissionAdmission =
    notificationData.missionAdmission === true || fcmMessage !== null;
  if (!belongsToMissionAdmission) return;

  event.stopImmediatePropagation?.();
  event.notification.close();
  const destination = safeNotificationDestination(
    notificationData.link ||
    fcmMessage?.fcmOptions?.link ||
    fcmMessage?.data?.link,
  );
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    });
    for (const client of windows) {
      const clientUrl = new URL(client.url);
      const destinationUrl = new URL(destination);
      if (clientUrl.origin === destinationUrl.origin &&
          clientUrl.pathname.startsWith(new URL(self.registration.scope).pathname)) {
        await client.focus();
        if ('navigate' in client) await client.navigate(destination);
        return;
      }
    }
    await self.clients.openWindow(destination);
  })());
});

try {
  importScripts(new URL('firebase_config.js', self.location.href).toString());
  missionAdmissionNotificationSettings = self.MISSION_ADMISSION_FIREBASE;
  if (missionAdmissionNotificationSettings?.enabled === true) {
    const sdkVersion = missionAdmissionNotificationSettings.sdkVersion || '12.16.0';
    importScripts(
      `https://www.gstatic.com/firebasejs/${sdkVersion}/firebase-app-compat.js`,
      `https://www.gstatic.com/firebasejs/${sdkVersion}/firebase-messaging-compat.js`,
    );
    firebase.initializeApp(missionAdmissionNotificationSettings.config);
    missionAdmissionMessaging = firebase.messaging();
    missionAdmissionMessaging.onBackgroundMessage(async (payload) => {
      // Los mensajes que ya incluyen payload notification son mostrados
      // automáticamente por FCM. Para mensajes exclusivamente de datos,
      // este worker crea una notificación con enlace limitado al sitio.
      if (payload.notification) return;
      const title = payload.data?.title || 'Misión Admisión';
      await self.registration.showNotification(
        title,
        missionAdmissionNotificationOptions(payload),
      );
    });
  }
} catch (error) {
  console.warn('FCM no fue inicializado:', error);
}

self.addEventListener('pushsubscriptionchange', (event) => {
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    });
    for (const client of windows) {
      client.postMessage({type: 'FCM_REGISTRATION_REFRESH_REQUIRED'});
    }
  })());
});

