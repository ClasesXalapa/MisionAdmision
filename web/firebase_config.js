(() => {
  'use strict';

  // La configuración Web de Firebase y la clave VAPID pública identifican el
  // proyecto, pero no conceden permisos administrativos. No agregues aquí
  // cuentas de servicio, claves privadas ni credenciales de la API HTTP v1.
  globalThis.MISSION_ADMISSION_FIREBASE = Object.freeze({
    enabled: false,
    sdkVersion: '12.16.0',
    registrationMode: 'fid',
    registrationTimeoutMs: 15000,
    defaultNotificationLink: '#/reto',
    debugLogging: false,
    vapidKey: '',
    config: Object.freeze({
      apiKey: '',
      authDomain: '',
      projectId: '',
      storageBucket: '',
      messagingSenderId: '',
      appId: '',
    }),
  });
})();
