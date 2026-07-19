#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function eventTarget() {
  const listeners = new Map();
  return {
    addEventListener(type, callback) {
      if (!listeners.has(type)) listeners.set(type, []);
      listeners.get(type).push(callback);
    },
    removeEventListener(type, callback) {
      const values = listeners.get(type) || [];
      const index = values.indexOf(callback);
      if (index >= 0) values.splice(index, 1);
    },
    emit(type) {
      for (const callback of [...(listeners.get(type) || [])]) callback();
    },
  };
}

function activeRegistration(scope, scriptUrl) {
  const worker = {
    ...eventTarget(),
    state: 'activated',
    scriptURL: scriptUrl,
  };
  return {
    ...eventTarget(),
    scope,
    active: worker,
    waiting: null,
    installing: null,
    async unregister() { return true; },
  };
}

function createContext({onRegister, onGetRegistration}) {
  const scope = 'https://example.test/mision-admision/';
  const expectedScript = `${scope}app_service_worker.js?v=41`;
  const serviceWorkerEvents = eventTarget();
  const media = {...eventTarget(), matches: false};

  const context = {
    console,
    URL,
    Date,
    Promise,
    setTimeout(callback) { return setTimeout(callback, 0); },
    clearTimeout,
    setInterval(callback) { return setInterval(callback, 1); },
    clearInterval,
    fetch: async () => ({
      ok: true,
      status: 200,
      async text() { return "const APP_SHELL = ['index.html'];"; },
    }),
    document: {baseURI: scope},
    navigator: {
      onLine: true,
      userAgent: 'Mozilla/5.0 (Android)',
      platform: 'Linux armv8l',
      maxTouchPoints: 1,
      standalone: false,
      serviceWorker: {
        ...serviceWorkerEvents,
        async getRegistration(url) {
          assert.equal(String(url), scope);
          return onGetRegistration();
        },
        async register(url, options) {
          assert.ok(String(url).startsWith(expectedScript));
          assert.equal(options.scope, '/mision-admision/');
          assert.equal(options.updateViaCache, 'none');
          return onRegister(String(url));
        },
      },
    },
    matchMedia() { return media; },
    addEventListener() {},
    location: {reload() {}},
  };
  context.window = context;
  context.globalThis = context;
  return {context, scope, expectedScript};
}

async function testUpdatesExistingRegistrationWithoutUnregistering() {
  let registerCount = 0;
  let unregisterCount = 0;
  const scope = 'https://example.test/mision-admision/';
  const expectedScript = `${scope}app_service_worker.js?v=41`;
  const old = activeRegistration(scope, `${scope}flutter_service_worker.js`);
  old.unregister = async () => {
    unregisterCount += 1;
    return true;
  };
  const updated = activeRegistration(scope, expectedScript);
  let current = old;

  const {context} = createContext({
    onGetRegistration: () => current,
    onRegister: () => {
      registerCount += 1;
      current = updated;
      return updated;
    },
  });

  vm.createContext(context);
  vm.runInContext(fs.readFileSync('web/pwa_bridge.js', 'utf8'), context);
  const ready = await context.missionAdmissionPwa.ensureServiceWorker({
    waitForActive: true,
    timeoutMs: 10000,
  });

  assert.equal(ready, updated);
  assert.equal(registerCount, 1);
  assert.equal(unregisterCount, 0);
}

async function testRepairsEmptyRegistrationLeftByPreviousVersion() {
  let registerCount = 0;
  let unregisterCount = 0;
  const scope = 'https://example.test/mision-admision/';
  const expectedScript = `${scope}app_service_worker.js?v=41`;
  let current;
  const ghost = {
    ...eventTarget(),
    scope,
    active: null,
    waiting: null,
    installing: null,
    async unregister() {
      unregisterCount += 1;
      current = null;
      return true;
    },
  };
  const recovered = activeRegistration(scope, expectedScript);
  current = ghost;

  const {context} = createContext({
    onGetRegistration: () => current,
    onRegister: (url) => {
      registerCount += 1;
      if (registerCount === 1) return ghost;
      assert.ok(url.includes('recovery=1'));
      current = recovered;
      return recovered;
    },
  });

  vm.createContext(context);
  vm.runInContext(fs.readFileSync('web/pwa_bridge.js', 'utf8'), context);
  const ready = await context.missionAdmissionPwa.ensureServiceWorker({
    waitForActive: true,
    timeoutMs: 10000,
  });

  assert.equal(ready, recovered);
  assert.equal(registerCount, 2);
  assert.equal(unregisterCount, 1);

  const state = await context.missionAdmissionPwa.getState();
  assert.equal(state.workerState, 'active');
  assert.equal(state.online, true);
  assert.equal(state.updateAvailable, false);
}

async function main() {
  await testUpdatesExistingRegistrationWithoutUnregistering();
  await testRepairsEmptyRegistrationLeftByPreviousVersion();
  console.log(
    'Puente PWA validado: actualización directa y recuperación de inscripción vacía.',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
