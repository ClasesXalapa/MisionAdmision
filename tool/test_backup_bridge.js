#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function main() {
  let clicked = false;
  let downloadedName = '';
  const anchor = {
    href: '',
    rel: '',
    style: {},
    set download(value) { downloadedName = value; },
    get download() { return downloadedName; },
    click() { clicked = true; },
    remove() {},
  };
  const context = {
    console,
    Blob,
    URL: {
      createObjectURL() { return 'blob:test'; },
      revokeObjectURL() {},
    },
    document: {
      body: {appendChild() {}},
      createElement(tag) {
        if (tag === 'a') return anchor;
        throw new Error(`Elemento inesperado: ${tag}`);
      },
    },
    setTimeout(callback) { callback(); },
    removeEventListener() {},
    addEventListener() {},
  };
  context.window = context;
  context.globalThis = context;
  vm.createContext(context);
  vm.runInContext(fs.readFileSync('web/backup_bridge.js', 'utf8'), context);

  assert.equal(typeof context.missionAdmissionBackupFiles.pickJsonFile, 'function');
  const saved = await context.missionAdmissionBackupFiles.downloadText(
    'progreso inválido.json',
    '{}',
  );
  assert.equal(saved, true);
  assert.equal(clicked, true);
  assert.equal(downloadedName, 'progreso-inv-lido.json');
  console.log('Puente de respaldo validado.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
