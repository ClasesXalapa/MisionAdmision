#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function main() {
  const listeners = new Map();
  const shown = [];
  let backgroundHandler = null;
  const clients = [{
    url: 'https://example.test/mision-admision/#/inicio',
    async focus() {},
    async navigate(url) { this.url = url; },
    postMessage() {},
  }];
  const context = {
    console,
    URL,
    Response,
    Set,
    Promise,
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
      async showNotification(title, options) { shown.push({title, options}); },
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
  await backgroundHandler({
    data: {
      title: 'Protege tu racha',
      body: 'Completa el reto.',
      link: 'https://evil.example/phishing',
    },
  });
  assert.equal(shown.length, 1);
  assert.equal(
    shown[0].options.data.link,
    'https://example.test/mision-admision/#/reto',
  );

  await backgroundHandler({notification: {title: 'Automática'}});
  assert.equal(shown.length, 1);

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

  console.log('Service worker FCM validado: datos, enlaces seguros, orden y clic.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
