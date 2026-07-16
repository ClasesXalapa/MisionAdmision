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
if (!/^\d+\.\d+\.\d+$/.test(settings.sdkVersion || '')) {
  throw new Error('sdkVersion debe tener formato X.Y.Z.');
}
if (settings.registrationMode !== 'fid') {
  throw new Error('registrationMode debe ser fid.');
}
if (!Number.isInteger(settings.registrationTimeoutMs) ||
    settings.registrationTimeoutMs < 3000 || settings.registrationTimeoutMs > 60000) {
  throw new Error('registrationTimeoutMs debe estar entre 3000 y 60000.');
}
if (typeof settings.defaultNotificationLink !== 'string' ||
    !settings.defaultNotificationLink.trim()) {
  throw new Error('defaultNotificationLink no puede estar vacío.');
}
if (settings.defaultNotificationLink.includes('://')) {
  throw new Error('defaultNotificationLink debe ser una ruta interna, no una URL absoluta.');
}
if (settings.enabled !== true) {
  console.log('Firebase Cloud Messaging desactivado: configuración FID opcional válida.');
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
console.log(`Firebase FID configurado para ${settings.config.projectId}.`);
