#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function createStorage() {
  const values = new Map();
  return {
    getItem(key) { return values.has(key) ? values.get(key) : null; },
    setItem(key, value) { values.set(key, String(value)); },
    removeItem(key) { values.delete(key); },
  };
}

function createContext({
  configured = false,
  ios = false,
  analyticsSupported = true,
  analyticsThrows = false,
  nowHour = 12,
} = {}) {
  const registrationCallbacks = [];
  const unregistrationCallbacks = [];
  const foregroundCallbacks = [];
  const shownNotifications = [];
  const serviceWorkerListeners = new Map();
  const windowListeners = new Map();
  const documentListeners = new Map();
  const syncRegistrations = [];
  let registerCount = 0;
  let unregisterCount = 0;
  let analyticsCount = 0;
  const dailySyncCalls = [];
  const dailyDecisions = [];
  let firebaseWakeCount = 0;
  const postedWorkerMessages = [];
  let pendingFollowUps = 0;
  let clearFollowUpsCount = 0;

  const registration = {
    active: {
      postMessage(message) { postedWorkerMessages.push(message); },
    },
    sync: {
      async register(tag) { syncRegistrations.push(tag); },
    },
    async getNotifications() { return []; },
    async showNotification(title, options) {
      shownNotifications.push({title, options});
    },
  };
  const messagingInstance = {};
  const messagingModule = {
    async isSupported() { return true; },
    getMessaging() { return messagingInstance; },
    onRegistered(_messaging, callback) {
      registrationCallbacks.push(callback);
      return () => {
        const index = registrationCallbacks.indexOf(callback);
        if (index >= 0) registrationCallbacks.splice(index, 1);
      };
    },
    onUnregistered(_messaging, callback) {
      unregistrationCallbacks.push(callback);
      return () => {};
    },
    onMessage(_messaging, callback) {
      foregroundCallbacks.push(callback);
      return () => {
        const index = foregroundCallbacks.indexOf(callback);
        if (index >= 0) foregroundCallbacks.splice(index, 1);
      };
    },
    async register() {
      registerCount += 1;
      for (const callback of [...registrationCallbacks]) callback('fid-test-123');
    },
    async unregister() {
      unregisterCount += 1;
      for (const callback of [...unregistrationCallbacks]) callback('fid-test-123');
    },
  };
  const app = {};
  const appModule = {
    getApps() { return []; },
    initializeApp() { return app; },
  };
  const analyticsModule = {
    async isSupported() {
      if (analyticsThrows) throw new Error('analytics blocked');
      return analyticsSupported;
    },
    getAnalytics() {
      analyticsCount += 1;
      return {app};
    },
  };

  class FixedDate extends Date {
    constructor(...args) {
      if (args.length > 0) {
        super(...args);
      } else {
        super(2026, 6, 16, nowHour, 0, 0);
      }
    }

    static now() {
      return new FixedDate().getTime();
    }
  }

  const notification = {
    permission: 'default',
    async requestPermission() {
      notification.permission = 'granted';
      return 'granted';
    },
  };
  let pwaEnsureCount = 0;

  function currentProgress() {
    const latest = dailySyncCalls.at(-1);
    if (!latest) return null;
    return {
      initialized: true,
      lastCompletedDateKey: latest.lastCompletedDateKey || null,
      challengeAvailable: latest.challengeAvailable === true,
    };
  }

  const stateStore = {
    async readSnapshot() {
      const progress = currentProgress();
      return {
        supported: true,
        stateInitialized: progress?.initialized === true,
        lastCompletedDateKey: progress?.lastCompletedDateKey || '',
        challengeAvailable: progress?.challengeAvailable === true,
        stateUpdatedAt: '',
        lastFirebaseReceivedAt: '',
        lastLocalReminderAt: '',
        reminderCountDateKey: '',
        reminderCountForDate: 0,
        followUpDateKey: pendingFollowUps > 0 ? '2026-07-16' : '',
        pendingFollowUpCount: pendingFollowUps,
        followUpLastCreatedAt: '',
        followUpLastClaimedAt: '',
        lastDecision: dailyDecisions.at(-1)?.decision || '',
        lastDecisionAt: '',
        errorMessage: '',
      };
    },
    async syncDailyProgress(lastCompletedDateKey, challengeAvailable) {
      dailySyncCalls.push({lastCompletedDateKey, challengeAvailable});
      if (lastCompletedDateKey === '2026-07-16' || challengeAvailable !== true) {
        pendingFollowUps = 0;
      }
      return true;
    },
    async readDailyProgress() { return currentProgress(); },
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
        source: 'firebase_foreground',
      };
    },
    async clearFollowUps() {
      clearFollowUpsCount += 1;
      pendingFollowUps = 0;
      return true;
    },
    localDateKey() { return '2026-07-16'; },
    async recordFirebaseWake() { firebaseWakeCount += 1; },
    async recordDecision(decision, options = {}) {
      dailyDecisions.push({decision, options});
    },
  };

  const document = {
    baseURI: 'https://example.test/mision-admision/',
    visibilityState: 'visible',
    addEventListener(type, callback) { documentListeners.set(type, callback); },
  };
  const context = {
    console,
    URL,
    Date: FixedDate,
    Promise,
    setTimeout,
    clearTimeout,
    localStorage: createStorage(),
    Notification: notification,
    PushManager: function PushManager() {},
    location: {
      hostname: 'example.test',
      origin: 'https://example.test',
    },
    document,
    navigator: {
      userAgent: ios ? 'Mozilla/5.0 (iPhone)' : 'Mozilla/5.0 (Android)',
      platform: ios ? 'iPhone' : 'Linux armv8l',
      maxTouchPoints: ios ? 5 : 1,
      standalone: false,
      serviceWorker: {
        ready: Promise.resolve(registration),
        async getRegistration() { return registration; },
        addEventListener(type, callback) {
          serviceWorkerListeners.set(type, callback);
        },
      },
    },
    isSecureContext: true,
    matchMedia() { return {matches: false}; },
    addEventListener(type, callback) { windowListeners.set(type, callback); },
    missionAdmissionPwa: {
      async ensureServiceWorker(options) {
        pwaEnsureCount += 1;
        assert.equal(options.waitForActive, true);
        assert.equal(options.timeoutMs, 60000);
        return registration;
      },
    },
    __MISSION_ADMISSION_FIREBASE_MODULES__: {appModule, messagingModule, analyticsModule},
    __MISSION_ADMISSION_NOTIFICATION_STATE_STORE__: stateStore,
  };
  context.window = context;
  context.globalThis = context;
  vm.createContext(context);
  vm.runInContext(fs.readFileSync('web/firebase_config.js', 'utf8'), context);

  // Las pruebas no deben depender de la configuración real del repositorio.
  // Cada fixture fuerza explícitamente Firebase activado o desactivado.
  context.MISSION_ADMISSION_FIREBASE = Object.freeze({
    enabled: configured,
    sdkVersion: '12.16.0',
    registrationMode: 'fid',
    registrationTimeoutMs: 1000,
    defaultNotificationLink: '#/reto',
    debugLogging: false,
    analyticsEnabled: configured,
    vapidKey: configured ? 'B'.repeat(80) : '',
    config: Object.freeze({
      apiKey: configured ? 'api-key' : '',
      authDomain: configured ? 'example.firebaseapp.com' : '',
      projectId: configured ? 'example' : '',
      storageBucket: configured ? 'example.firebasestorage.app' : '',
      messagingSenderId: configured ? '123456' : '',
      appId: configured ? '1:123456:web:abc' : '',
      measurementId: configured ? 'G-TEST123456' : '',
    }),
  });
  vm.runInContext(fs.readFileSync('web/notifications_bridge.js', 'utf8'), context);

  return {
    context,
    notification,
    shownNotifications,
    foregroundCallbacks,
    serviceWorkerListeners,
    windowListeners,
    documentListeners,
    syncRegistrations,
    get registerCount() { return registerCount; },
    get unregisterCount() { return unregisterCount; },
    get analyticsCount() { return analyticsCount; },
    dailySyncCalls,
    dailyDecisions,
    postedWorkerMessages,
    get pendingFollowUps() { return pendingFollowUps; },
    get clearFollowUpsCount() { return clearFollowUpsCount; },
    get firebaseWakeCount() { return firebaseWakeCount; },
    get pwaEnsureCount() { return pwaEnsureCount; },
  };
}

async function testDisabledConfiguration() {
  const fixture = createContext();
  const state = await fixture.context.missionAdmissionNotifications.getState();
  assert.equal(state.configured, false);
  assert.equal(state.supported, true);
  assert.equal(state.enabled, false);
  assert.equal(state.permission, 'default');
  assert.equal(state.registrationKind, 'none');
  assert.equal(state.analyticsConfigured, false);
  assert.equal(state.analyticsState, 'not-configured');
}

async function testRegistrationLifecycle() {
  const fixture = createContext({configured: true, nowHour: 21});
  const initial = await fixture.context.missionAdmissionNotifications.getState();
  assert.equal(initial.configured, true);
  assert.equal(initial.supported, true);
  assert.equal(initial.enabled, false);
  assert.equal(initial.analyticsConfigured, true);
  assert.equal(initial.analyticsState, 'active');
  assert.equal(fixture.analyticsCount, 1);

  const enabled = await fixture.context.missionAdmissionNotifications.enable();
  assert.equal(enabled.permission, 'granted');
  assert.equal(enabled.enabled, true);
  assert.equal(enabled.registrationAvailable, true);
  assert.equal(enabled.registrationKind, 'fid');
  assert.match(enabled.registrationUpdatedAt, /^\d{4}-\d{2}-\d{2}T/);
  assert.equal(fixture.registerCount >= 1, true);
  assert.equal(fixture.pwaEnsureCount >= 1, true);

  assert.equal(
    typeof fixture.context.missionAdmissionNotifications
      .getRegistrationSnapshotForBackend,
    'undefined',
  );
  const testingId = await fixture.context.missionAdmissionNotifications
    .getTestingInstallationId();
  assert.equal(testingId, 'fid-test-123');

  const completedSync = await fixture.context.missionAdmissionNotifications
    .syncDailyChallengeState('2026-07-16', true);
  assert.equal(completedSync, true);
  assert.equal(fixture.postedWorkerMessages.length, 1);
  assert.equal(
    fixture.postedWorkerMessages[0].type,
    'DAILY_CHALLENGE_COMPLETED',
  );

  const shown = await fixture.context.missionAdmissionNotifications.showLocalTest();
  assert.equal(shown, true);
  assert.equal(fixture.shownNotifications.length, 1);
  assert.equal(
    fixture.shownNotifications[0].options.data.link,
    'https://example.test/mision-admision/#/reto',
  );

  // El reto vuelve a estar pendiente para probar la recepción en primer plano.
  await fixture.context.missionAdmissionNotifications
    .syncDailyChallengeState('2026-07-15', true);

  await fixture.foregroundCallbacks[0]({
    notification: {title: 'Motivación', body: 'Sigue avanzando.'},
  });
  assert.equal(fixture.firebaseWakeCount, 1);
  assert.equal(fixture.shownNotifications.length, 3);
  assert.equal(
    fixture.shownNotifications[1].title,
    'Tu reto diario sigue pendiente 🔥',
  );
  assert.equal(fixture.shownNotifications[2].title, 'Motivación');
  assert.equal(fixture.pendingFollowUps, 1);
  assert.equal(fixture.dailyDecisions.at(-1).decision, 'pending');
  assert.equal(
    fixture.syncRegistrations.includes('mision-admision-daily-follow-up'),
    true,
  );

  // La siguiente oportunidad útil, en este caso recuperar conexión, entrega el
  // segundo aviso sin depender de un intervalo exacto.
  await fixture.windowListeners.get('online')();
  assert.equal(fixture.shownNotifications.length, 4);
  assert.equal(fixture.shownNotifications[3].title, 'Tu reto sigue esperando ⏳');
  assert.equal(fixture.pendingFollowUps, 0);
  assert.equal(fixture.dailyDecisions.at(-1).decision, 'follow_up_pending');

  // Sin una cola pendiente, abrir la app después de las 8 p. m. ejecuta el
  // plan B local. No hay bloqueo por "ya mostrado hoy".
  await fixture.windowListeners.get('load')();
  assert.equal(fixture.shownNotifications.length, 5);
  assert.equal(
    fixture.shownNotifications[4].title,
    'Aún puedes proteger tu racha 🌙',
  );
  assert.equal(
    fixture.shownNotifications[4].options.data.reminderStage,
    'evening',
  );

  fixture.context.document.visibilityState = 'hidden';
  await fixture.documentListeners.get('visibilitychange')();
  fixture.context.document.visibilityState = 'visible';
  await fixture.documentListeners.get('visibilitychange')();
  assert.equal(fixture.shownNotifications.length, 6);
  assert.equal(fixture.dailyDecisions.at(-1).decision, 'evening_pending');

  await fixture.context.missionAdmissionNotifications.refreshRegistration();
  assert.equal(fixture.registerCount >= 2, true);

  const disabled = await fixture.context.missionAdmissionNotifications.disable();
  assert.equal(disabled.enabled, false);
  assert.equal(disabled.registrationAvailable, false);
  assert.equal(fixture.unregisterCount, 1);
  assert.equal(fixture.clearFollowUpsCount >= 1, true);
}

async function testAnalyticsFailureDoesNotBreakMessaging() {
  const fixture = createContext({configured: true, analyticsThrows: true});
  const initial = await fixture.context.missionAdmissionNotifications.getState();
  assert.equal(initial.configured, true);
  assert.equal(initial.analyticsConfigured, true);
  assert.equal(initial.analyticsState, 'unavailable');
  assert.match(initial.analyticsErrorMessage, /blocked/);

  const enabled = await fixture.context.missionAdmissionNotifications.enable();
  assert.equal(enabled.enabled, true);
  assert.equal(enabled.registrationAvailable, true);
}

async function testIosRequiresInstalledPwa() {
  const fixture = createContext({configured: true, ios: true});
  const state = await fixture.context.missionAdmissionNotifications.getState();
  assert.equal(state.requiresPwaInstallation, true);
  await assert.rejects(
    () => fixture.context.missionAdmissionNotifications.enable(),
    (error) => error.code === 'pwa-install-required',
  );
}

async function main() {
  await testDisabledConfiguration();
  await testRegistrationLifecycle();
  await testAnalyticsFailureDoesNotBreakMessaging();
  await testIosRequiresInstalledPwa();
  console.log(
    'Puente Firebase validado: cada mensaje comprueba el reto y encola un seguimiento posterior.',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
