#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function main() {
  const context = {
    console,
    URL,
    Intl,
    document: {baseURI: 'https://example.test/mision-admision/'},
    navigator: {
      userAgent: 'Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 Chrome/150.0.0.0 Mobile Safari/537.36',
      platform: 'Linux armv8l',
      language: 'es-MX',
      onLine: true,
      cookieEnabled: true,
      connection: {effectiveType: '4g'},
      storage: {
        async estimate() { return {usage: 1024, quota: 4096}; },
        async persisted() { return false; },
      },
      serviceWorker: {
        controller: {state: 'activated'},
        async getRegistration() {
          return {active: {state: 'activated'}};
        },
      },
    },
    screen: {width: 390, height: 844},
    innerWidth: 390,
    innerHeight: 700,
    devicePixelRatio: 3,
    isSecureContext: true,
    matchMedia() { return {matches: true}; },
  };
  context.window = context;
  context.globalThis = context;
  vm.createContext(context);
  vm.runInContext(fs.readFileSync('web/diagnostics_bridge.js', 'utf8'), context);

  const source = await context.missionAdmissionDiagnostics.getReportJson();
  const report = JSON.parse(source);
  assert.equal(report.supported, true);
  assert.equal(report.browser_name, 'Chrome');
  assert.equal(report.operating_system, 'Android 16');
  assert.equal(report.display_mode, 'standalone');
  assert.equal(report.service_worker_controlled, true);
  assert.equal(report.storage_usage_bytes, 1024);
  assert.equal(report.connection_type, '4g');
  console.log('Puente de diagnóstico validado.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
