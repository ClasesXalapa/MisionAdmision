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
        'pwa_bridge_bootstrap.js',
        'firebase_config.js',
        'notification_state_store.js',
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

async function closeDailyChallengeReminders() {
  if (typeof self.registration.getNotifications !== 'function') return;
  const notifications = await self.registration.getNotifications();
  for (const notification of notifications) {
    if (notification.data?.kind === 'daily-challenge-reminder') {
      notification.close();
    }
  }
}

self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
    return;
  }
  if (event.data?.type === 'DAILY_CHALLENGE_COMPLETED') {
    event.waitUntil(Promise.all([
      closeDailyChallengeReminders(),
      missionAdmissionDailyStateStore?.clearFollowUps?.('completed_today'),
    ]));
    return;
  }
  if (event.data?.type === 'PROCESS_DAILY_FOLLOW_UP') {
    event.waitUntil(processPendingDailyFollowUp('app_message'));
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
    // El código JavaScript debe comprobar la red antes que la caché. De otro
    // modo una PWA instalada puede conservar main.dart.js de una versión
    // anterior aunque index.html ya se haya actualizado.
    if (relativePath.endsWith('.js')) {
      event.respondWith(networkFirstAppAsset(request));
    } else {
      event.respondWith(cacheFirst(request, APP_CACHE));
    }
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

async function networkFirstAppAsset(request) {
  try {
    const response = await fetch(request, {cache: 'reload'});
    if (response.ok) {
      const cache = await caches.open(APP_CACHE);
      await cache.put(request, response.clone());
    }
    return response;
  } catch (_) {
    return (await caches.match(request, {ignoreSearch: true})) || Response.error();
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
// con la caché offline de la PWA. IndexedDB conserva solo la fecha mínima
// necesaria para comprobar si el reto diario sigue pendiente y una cola de
// seguimientos. Cada señal Firebase puede producir un aviso inmediato y deja
// un segundo aviso para la próxima oportunidad útil del navegador.
let missionAdmissionMessaging = null;
let missionAdmissionNotificationSettings = null;
let missionAdmissionDailyStateStore = null;
let missionAdmissionReminderSequence = 0;

const DAILY_FOLLOW_UP_SYNC_TAG = 'mision-admision-daily-follow-up';
const DAILY_FOLLOW_UP_PERIODIC_TAG = 'mision-admision-daily-follow-up-periodic';

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

function dailyChallengeReminderOptions(evaluation, {followUp = false} = {}) {
  return {
    body: followUp
      ? 'El reto continúa pendiente. Complétalo para cuidar tu racha.'
      : 'Completa las preguntas de hoy y protege tu racha.',
    icon: scopedUrl('icons/Icon-192.png'),
    badge: scopedUrl('icons/Icon-192.png'),
    tag: `mision-admision-daily-${followUp ? 'follow-up' : 'firebase'}-${evaluation.todayDateKey}-${Date.now()}-${missionAdmissionReminderSequence += 1}`,
    renotify: false,
    data: {
      missionAdmission: true,
      kind: 'daily-challenge-reminder',
      reminderStage: followUp ? 'follow-up' : 'immediate',
      link: safeNotificationDestination('#/daily'),
    },
  };
}

async function showDailyChallengeReminder(evaluation, {followUp = false} = {}) {
  await self.registration.showNotification(
    followUp
      ? 'Tu reto sigue esperando ⏳'
      : 'Tu reto diario sigue pendiente 🔥',
    dailyChallengeReminderOptions(evaluation, {followUp}),
  );
}

async function registerDailyFollowUpWake() {
  try {
    if (typeof self.registration.sync?.register === 'function') {
      await self.registration.sync.register(DAILY_FOLLOW_UP_SYNC_TAG);
      return true;
    }
  } catch (error) {
    console.debug('No se pudo registrar Background Sync para el seguimiento:', error);
  }
  return false;
}

async function recordDailyDecisionBestEffort(decision, options = {}) {
  try {
    await missionAdmissionDailyStateStore?.recordDecision?.(decision, options);
  } catch (_) {
    // El diagnóstico nunca debe alterar la entrega de una notificación.
  }
}

async function processPendingDailyFollowUp(trigger = 'unknown') {
  const store = missionAdmissionDailyStateStore;
  if (!store || typeof store.claimFollowUp !== 'function') return false;

  let claim = null;
  try {
    claim = await store.claimFollowUp(new Date());
    if (!claim?.claimed) return false;

    const progress = await store.readDailyProgress();
    const evaluation = store.evaluateDailyProgress(progress, new Date());
    if (!evaluation.shouldShow) {
      await recordDailyDecisionBestEffort(`follow_up_${evaluation.decision}`);
      if (['completed_today', 'challenge_unavailable'].includes(evaluation.decision)) {
        try {
          await store.clearFollowUps?.(evaluation.decision);
        } catch (_) {
          // La cola también se limpia cuando Flutter sincroniza el progreso.
        }
      }
      return false;
    }

    await showDailyChallengeReminder(evaluation, {followUp: true});
    await recordDailyDecisionBestEffort('follow_up_pending', {reminderShown: true});

    if (Number(claim.remainingCount) > 0) {
      await registerDailyFollowUpWake();
    }
    return true;
  } catch (error) {
    try {
      if (claim?.claimed) {
        await store.scheduleFollowUp?.(`retry_${trigger}`);
        await registerDailyFollowUpWake();
      }
      await recordDailyDecisionBestEffort('follow_up_error', {
        errorMessage: error instanceof Error ? error.message : String(error),
      });
    } catch (_) {
      // El diagnóstico no debe impedir futuros eventos del service worker.
    }
    return false;
  }
}

async function handleFirebaseDailyCheck(source = 'firebase_background') {
  const store = missionAdmissionDailyStateStore;
  if (!store) return false;

  try {
    try {
      await store.recordFirebaseWake();
    } catch (_) {
      // Es solo diagnóstico; la comprobación del reto debe continuar.
    }
    const progress = await store.readDailyProgress();
    const evaluation = store.evaluateDailyProgress(progress, new Date());
    if (!evaluation.shouldShow) {
      await recordDailyDecisionBestEffort(evaluation.decision);
      return false;
    }

    await showDailyChallengeReminder(evaluation);
    await store.scheduleFollowUp?.(source);
    await recordDailyDecisionBestEffort('pending', {reminderShown: true});
    await registerDailyFollowUpWake();
    return true;
  } catch (error) {
    try {
      await recordDailyDecisionBestEffort('storage_error', {
        errorMessage: error instanceof Error ? error.message : String(error),
      });
    } catch (_) {
      // El error de diagnóstico no debe afectar la recepción de Firebase.
    }
    return false;
  }
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
  importScripts(
    new URL('notification_state_store.js', self.location.href).toString(),
  );
  missionAdmissionDailyStateStore = self.missionAdmissionNotificationStateStore;
} catch (error) {
  console.warn('El estado inteligente no fue inicializado:', error);
}

self.addEventListener('sync', (event) => {
  if (event.tag !== DAILY_FOLLOW_UP_SYNC_TAG) return;
  event.waitUntil(processPendingDailyFollowUp('background_sync'));
});

// Algunos navegadores pueden ofrecer un despertar periódico. No se registra
// como requisito, pero si el navegador ya entrega este evento se aprovecha.
self.addEventListener('periodicsync', (event) => {
  if (event.tag !== DAILY_FOLLOW_UP_PERIODIC_TAG) return;
  event.waitUntil(processPendingDailyFollowUp('periodic_sync'));
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
      // Una señal posterior es una oportunidad válida para entregar un
      // seguimiento anterior. Se procesa antes de crear el seguimiento del
      // mensaje actual, evitando dos avisos locales en el mismo primer evento.
      await processPendingDailyFollowUp('next_firebase_background');

      // Firebase muestra automáticamente la notificación original cuando la
      // campaña incluye notification. Cada mensaje comprueba además el reto y,
      // si está pendiente, muestra un aviso inmediato y encola un seguimiento.
      await handleFirebaseDailyCheck('firebase_background');

      // Los mensajes exclusivamente de datos todavía reciben una notificación
      // básica. Las campañas de Firebase Console ya incluyen notification y no
      // entran en esta rama.
      if (!payload.notification) {
        const title = payload.data?.title || 'Misión Admisión';
        await self.registration.showNotification(
          title,
          missionAdmissionNotificationOptions(payload),
        );
      }
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
