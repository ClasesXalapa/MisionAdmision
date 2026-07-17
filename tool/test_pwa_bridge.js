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
  let updateCount = 0;
  const worker = {...eventTarget(), state: 'activated'};
  const registration = {
    ...eventTarget(),
    active: worker,
    waiting: null,
    installing: null,
    async update() { updateCount += 1; },
  };
  const serviceWorkerEvents = eventTarget();
  const media = {...eventTarget(), matches: false};

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
    document: {baseURI: 'https://example.test/mision-admision/'},
    navigator: {
      onLine: true,
      userAgent: 'Mozilla/5.0 (Android)',
      platform: 'Linux armv8l',
      maxTouchPoints: 1,
      standalone: false,
      serviceWorker: {
        ...serviceWorkerEvents,
        async register(url, options) {
          registerCount += 1;
          assert.equal(
            String(url),
            'https://example.test/mision-admision/app_service_worker.js',
          );
          assert.equal(options.scope, '/mision-admision/');
          assert.equal(options.updateViaCache, 'none');
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
  assert.equal(registerCount, 1);
  assert.equal(updateCount, 1);

  const state = await context.missionAdmissionPwa.getState();
  assert.equal(state.workerState, 'active');
  assert.equal(state.online, true);
  assert.equal(state.updateAvailable, false);

  console.log('Puente PWA validado: registro temprano y espera de activación.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
