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

async function main() {
  const context = {
    console,
    URL,
    localStorage: createStorage(),
    Notification: {permission: 'default'},
    PushManager: function PushManager() {},
    navigator: {},
    addEventListener() {},
  };
  context.window = context;
  context.globalThis = context;
  vm.createContext(context);
  vm.runInContext(fs.readFileSync('web/firebase_config.js', 'utf8'), context);
  vm.runInContext(fs.readFileSync('web/notifications_bridge.js', 'utf8'), context);

  const state = await context.missionAdmissionNotifications.getState();
  assert.equal(state.configured, false);
  assert.equal(state.supported, false);
  assert.equal(state.enabled, false);
  assert.equal(state.permission, 'default');

  const installationId = await context.missionAdmissionNotifications.getInstallationIdForTesting();
  assert.equal(installationId, '');
  console.log('Puente de notificaciones validado en modo desactivado.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
