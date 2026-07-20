#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function main() {
  const listeners = new Map();
  const shown = [];
  const decisions = [];
  const syncRegistrations = [];
  let wakeCount = 0;
  let backgroundHandler = null;
  let pendingFollowUps = 0;
  let clearFollowUpsCount = 0;
  let dailyProgress = {
    initialized: true,
    challengeAvailable: true,
    lastCompletedDateKey: null,
  };
  const visibleNotifications = [];
  const clients = [{
    url: 'https://example.test/mision-admision/#/inicio',
    async focus() {},
    async navigate(url) { this.url = url; },
    postMessage() {},
  }];
  const stateStore = {
    async recordFirebaseWake() { wakeCount += 1; },
    async readDailyProgress() { return dailyProgress; },
    evaluateDailyProgress(progress) {
      if (!progress?.initialized) {
        return {
          shouldShow: false,
          decision: 'state_not_initialized',
          todayDateKey: '2026-07-16',
        };
      }
      if (!progress.challengeAvailable) {
        return {
          shouldShow: false,
          decision: 'challenge_unavailable',
          todayDateKey: '2026-07-16',
        };
      }
      if (progress.lastCompletedDateKey === '2026-07-16') {
        return {
          shouldShow: false,
          decision: 'completed_today',
          todayDateKey: '2026-07-16',
        };
      }
      return {
        shouldShow: true,
        decision: 'pending',
        todayDateKey: '2026-07-16',
      };
    },
    async scheduleFollowUp() {
      pendingFollowUps += 1;
      return true;
    },
    async claimFollowUp() {
      if (pendingFollowUps <= 0) {
        return {
          claimed: false,
          dateKey: '2026-07-16',
          remainingCount: 0,
          source: '',
        };
      }
      pendingFollowUps -= 1;
      return {
        claimed: true,
        dateKey: '2026-07-16',
        remainingCount: pendingFollowUps,
        source: 'firebase',
      };
    },
    async clearFollowUps() {
      clearFollowUpsCount += 1;
      pendingFollowUps = 0;
      return true;
    },
    async recordDecision(decision, options = {}) {
      decisions.push({decision, options});
    },
  };
  const context = {
    console,
    URL,
    Response,
    Set,
    Promise,
    Date,
    fetch: async () => new Response('{}', {status: 200}),
    caches: {
      async open() { return {put: async () => {}}; },
      async keys() { return []; },
      async delete() { return true; },
      async match() { return null; },
    },
    firebase: {
      initializeApp() {},
      messaging() {
        return {
          onBackgroundMessage(callback) { backgroundHandler = callback; },
        };
      },
    },
  };
  context.self = {
    location: {href: 'https://example.test/mision-admision/app_service_worker.js'},
    registration: {
      scope: 'https://example.test/mision-admision/',
      sync: {
        async register(tag) { syncRegistrations.push(tag); },
      },
      async showNotification(title, options) {
        const notification = {
          title,
          data: options.data,
          closed: false,
          close() { this.closed = true; },
        };
        shown.push({title, options, notification});
        visibleNotifications.push(notification);
      },
      async getNotifications() {
        return visibleNotifications.filter((notification) => !notification.closed);
      },
    },
    clients: {
      async claim() {},
      async matchAll() { return clients; },
      async openWindow(url) { clients.push({url}); },
    },
    MISSION_ADMISSION_FIREBASE: {
      enabled: true,
      sdkVersion: '12.16.0',
      defaultNotificationLink: '#/reto',
      config: {projectId: 'example'},
    },
    missionAdmissionNotificationStateStore: stateStore,
    addEventListener(type, callback) { listeners.set(type, callback); },
    skipWaiting() {},
  };
  context.importScripts = () => {};
  context.globalThis = context;

  let source = fs.readFileSync('web/app_service_worker.js', 'utf8');
  source = source
    .replace('__BUILD_VERSION__', 'test-build')
    .replace('__APP_SHELL__', '[]')
    .replace('__CONTENT_ASSETS__', '[]');
  vm.createContext(context);
  vm.runInContext(source, context);

  assert.equal(typeof backgroundHandler, 'function');
  assert.equal(typeof listeners.get('sync'), 'function');

  // Cada Firebase genera un aviso inmediato. El siguiente despertar entrega el
  // seguimiento pendiente del mensaje anterior.
  await backgroundHandler({notification: {title: 'Motivación 1'}});
  assert.equal(shown.length, 1);
  assert.equal(pendingFollowUps, 1);
  assert.equal(shown[0].title, 'Tu reto diario sigue pendiente 🔥');

  await backgroundHandler({notification: {title: 'Motivación 2'}});
  assert.equal(shown.length, 3);
  assert.equal(shown[1].title, 'Tu reto sigue esperando ⏳');
  assert.equal(shown[2].title, 'Tu reto diario sigue pendiente 🔥');
  assert.equal(pendingFollowUps, 1);

  await backgroundHandler({notification: {title: 'Motivación 3'}});
  assert.equal(shown.length, 5);
  assert.equal(pendingFollowUps, 1);
  assert.equal(wakeCount, 3);

  // Background Sync entrega el seguimiento del tercer Firebase sin un tiempo
  // exacto definido por la aplicación.
  const sync = listeners.get('sync');
  let syncPromise = null;
  sync({
    tag: 'mision-admision-daily-follow-up',
    waitUntil(promise) { syncPromise = promise; },
  });
  await syncPromise;
  assert.equal(shown.length, 6);
  assert.equal(shown.at(-1).title, 'Tu reto sigue esperando ⏳');
  assert.equal(pendingFollowUps, 0);
  assert.equal(
    syncRegistrations.every((tag) => tag === 'mision-admision-daily-follow-up'),
    true,
  );
  assert.equal(
    shown.filter((entry) => entry.options.data?.reminderStage === 'immediate').length,
    3,
  );
  assert.equal(
    shown.filter((entry) => entry.options.data?.reminderStage === 'follow-up').length,
    3,
  );

  dailyProgress = {
    initialized: true,
    challengeAvailable: true,
    lastCompletedDateKey: '2026-07-16',
  };
  await backgroundHandler({notification: {title: 'Motivación 4'}});
  assert.equal(shown.length, 6);
  assert.equal(decisions.at(-1).decision, 'completed_today');
  assert.equal(pendingFollowUps, 0);

  dailyProgress = {
    initialized: false,
    challengeAvailable: true,
    lastCompletedDateKey: null,
  };
  await backgroundHandler({notification: {title: 'Motivación 5'}});
  assert.equal(shown.length, 6);
  assert.equal(decisions.at(-1).decision, 'state_not_initialized');

  dailyProgress = {
    initialized: true,
    challengeAvailable: true,
    lastCompletedDateKey: null,
  };
  await backgroundHandler({
    data: {
      title: 'Protege tu racha',
      body: 'Completa el reto.',
      link: 'https://evil.example/phishing',
    },
  });
  assert.equal(shown.length, 8);
  assert.equal(shown[6].title, 'Tu reto diario sigue pendiente 🔥');
  assert.equal(shown[7].title, 'Protege tu racha');
  assert.equal(
    shown[7].options.data.link,
    'https://example.test/mision-admision/#/reto',
  );
  assert.equal(pendingFollowUps, 1);

  syncPromise = null;
  sync({
    tag: 'mision-admision-daily-follow-up',
    waitUntil(promise) { syncPromise = promise; },
  });
  await syncPromise;
  assert.equal(shown.length, 9);
  assert.equal(pendingFollowUps, 0);

  const message = listeners.get('message');
  let completionPromise = null;
  message({
    data: {type: 'DAILY_CHALLENGE_COMPLETED'},
    waitUntil(promise) { completionPromise = promise; },
  });
  await completionPromise;
  assert.equal(clearFollowUpsCount >= 1, true);
  assert.equal(
    visibleNotifications
      .filter((notification) =>
        notification.data?.kind === 'daily-challenge-reminder')
      .every((notification) => notification.closed),
    true,
  );

  const click = listeners.get('notificationclick');
  let clickPromise = null;
  let stopped = false;
  click({
    notification: {
      data: {
        FCM_MSG: {
          data: {link: 'https://evil.example/'},
        },
      },
      close() {},
    },
    stopImmediatePropagation() { stopped = true; },
    waitUntil(promise) { clickPromise = promise; },
  });
  await clickPromise;
  assert.equal(stopped, true);
  assert.equal(clients[0].url, 'https://example.test/mision-admision/#/reto');

  const notificationClickPosition = source.indexOf("addEventListener('notificationclick'");
  const firebaseImportPosition = source.indexOf("importScripts(new URL('firebase_config.js'");
  assert.equal(notificationClickPosition >= 0, true);
  assert.equal(firebaseImportPosition > notificationClickPosition, true);

  console.log(
    'Service worker FCM validado: aviso inmediato y seguimiento en un despertar posterior.',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
