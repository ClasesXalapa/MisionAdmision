#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const vm = require('node:vm');

const path = process.argv[2] || 'web/firebase_config.js';
const source = fs.readFileSync(path, 'utf8');
const context = {globalThis: {}};
vm.createContext(context);
vm.runInContext(source, context, {filename: path});

const settings = context.globalThis.MISSION_ADMISSION_FIREBASE;
if (!settings || typeof settings !== 'object') {
  throw new Error('No se definió MISSION_ADMISSION_FIREBASE.');
}
if (settings.enabled !== true) {
  console.log('Firebase Cloud Messaging desactivado: configuración opcional válida.');
  process.exit(0);
}

const required = ['apiKey', 'projectId', 'messagingSenderId', 'appId'];
for (const key of required) {
  if (typeof settings.config?.[key] !== 'string' || !settings.config[key].trim()) {
    throw new Error(`Falta config.${key}.`);
  }
}
if (typeof settings.vapidKey !== 'string' || settings.vapidKey.length < 20) {
  throw new Error('La clave VAPID pública no es válida.');
}
if (!/^\d+\.\d+\.\d+$/.test(settings.sdkVersion || '')) {
  throw new Error('sdkVersion debe tener formato X.Y.Z.');
}
console.log(`Firebase Cloud Messaging configurado para ${settings.config.projectId}.`);
