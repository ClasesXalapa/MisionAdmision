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

async function main() {
  let registerCount = 0;
  let staleUnregisterCount = 0;
  const expectedScript =
    'https://example.test/mision-admision/app_service_worker.js';
  const scope = 'https://example.test/mision-admision/';

  const staleWorker = {
    ...eventTarget(),
    state: 'activated',
    scriptURL: 'https://example.test/mision-admision/flutter_service_worker.js',
  };
  const staleRegistration = {
    ...eventTarget(),
    scope,
    active: staleWorker,
    waiting: null,
    installing: null,
    async unregister() {
      staleUnregisterCount += 1;
      return true;
    },
  };

  const worker = {
    ...eventTarget(),
    state: 'activated',
    scriptURL: expectedScript,
  };
  const registration = {
    ...eventTarget(),
    scope,
    active: worker,
    waiting: null,
    installing: null,
    async unregister() { return true; },
    async update() {
      throw new Error('update() no debe ejecutarse inmediatamente después de register().');
    },
  };

  const serviceWorkerEvents = eventTarget();
  const media = {...eventTarget(), matches: false};
  let currentRegistration = staleRegistration;

  const context = {
    console,
    URL,
    Promise,
    setTimeout,
    clearTimeout,
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
          return currentRegistration;
        },
        async register(url, options) {
          registerCount += 1;
          assert.equal(String(url), expectedScript);
          assert.equal(options.scope, '/mision-admision/');
          assert.equal(options.updateViaCache, 'none');
          currentRegistration = registration;
          return registration;
        },
      },
    },
    matchMedia() { return media; },
    addEventListener() {},
    location: {reload() {}},
  };
  context.window = context;
  context.globalThis = context;

  vm.createContext(context);
  vm.runInContext(fs.readFileSync('web/pwa_bridge.js', 'utf8'), context);

  const ready = await context.missionAdmissionPwa.ensureServiceWorker({
    waitForActive: true,
    timeoutMs: 10000,
  });
  assert.equal(ready, registration);
  assert.equal(staleUnregisterCount, 1);
  assert.equal(registerCount, 1);

  const state = await context.missionAdmissionPwa.getState();
  assert.equal(state.workerState, 'active');
  assert.equal(state.online, true);
  assert.equal(state.updateAvailable, false);

  console.log(
    'Puente PWA validado: migración de inscripción antigua sin update() redundante.',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
