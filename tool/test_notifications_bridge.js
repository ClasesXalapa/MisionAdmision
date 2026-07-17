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
} = {}) {
  const registrationCallbacks = [];
  const unregistrationCallbacks = [];
  const foregroundCallbacks = [];
  const shownNotifications = [];
  const serviceWorkerListeners = new Map();
  let registerCount = 0;
  let unregisterCount = 0;
  let analyticsCount = 0;
  const dailySyncCalls = [];
  const dailyDecisions = [];
  let firebaseWakeCount = 0;
  const postedWorkerMessages = [];

  const registration = {
    active: {
      postMessage(message) { postedWorkerMessages.push(message); },
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

  const notification = {
    permission: 'default',
    async requestPermission() {
      notification.permission = 'granted';
      return 'granted';
    },
  };
  let pwaEnsureCount = 0;
  const context = {
    console,
    URL,
    Date,
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
    document: {baseURI: 'https://example.test/mision-admision/'},
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
    addEventListener() {},
    missionAdmissionPwa: {
      async ensureServiceWorker(options) {
        pwaEnsureCount += 1;
        assert.equal(options.waitForActive, true);
        assert.equal(options.timeoutMs, 60000);
        return registration;
      },
    },
    __MISSION_ADMISSION_FIREBASE_MODULES__: {appModule, messagingModule, analyticsModule},
    __MISSION_ADMISSION_NOTIFICATION_STATE_STORE__: {
      async readSnapshot() {
        return {
          supported: true,
          stateInitialized: dailySyncCalls.length > 0,
          lastCompletedDateKey: dailySyncCalls.at(-1)?.lastCompletedDateKey || '',
          challengeAvailable: dailySyncCalls.at(-1)?.challengeAvailable === true,
          stateUpdatedAt: '',
          lastFirebaseReceivedAt: '',
          lastLocalReminderAt: '',
          reminderCountDateKey: '',
          reminderCountForDate: 0,
          lastDecision: dailyDecisions.at(-1) || '',
          lastDecisionAt: '',
          errorMessage: '',
        };
      },
      async syncDailyProgress(lastCompletedDateKey, challengeAvailable) {
        dailySyncCalls.push({lastCompletedDateKey, challengeAvailable});
        return true;
      },
      localDateKey() { return '2026-07-16'; },
      async recordFirebaseWake() { firebaseWakeCount += 1; },
      async recordDecision(decision) { dailyDecisions.push(decision); },
    },
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
    get registerCount() { return registerCount; },
    get unregisterCount() { return unregisterCount; },
    get analyticsCount() { return analyticsCount; },
    dailySyncCalls,
    dailyDecisions,
    postedWorkerMessages,
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
  const fixture = createContext({configured: true});
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

  const synced = await fixture.context.missionAdmissionNotifications
    .syncDailyChallengeState('2026-07-16', true);
  assert.equal(synced, true);
  assert.deepEqual(fixture.dailySyncCalls, [{
    lastCompletedDateKey: '2026-07-16',
    challengeAvailable: true,
  }]);
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

  await fixture.foregroundCallbacks[0]({
    notification: {title: 'Motivación', body: 'Sigue avanzando.'},
  });
  assert.equal(fixture.firebaseWakeCount, 1);
  assert.equal(fixture.dailyDecisions.at(-1), 'app_visible');
  assert.equal(fixture.shownNotifications.length, 2);

  await fixture.context.missionAdmissionNotifications.refreshRegistration();
  assert.equal(fixture.registerCount >= 2, true);

  const disabled = await fixture.context.missionAdmissionNotifications.disable();
  assert.equal(disabled.enabled, false);
  assert.equal(disabled.registrationAvailable, false);
  assert.equal(fixture.unregisterCount, 1);
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
    'Puente Firebase validado: Analytics opcional, FID, renovación, baja e iPhone.',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
