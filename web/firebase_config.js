(() => {
  'use strict';

  // La configuración web de Firebase y la clave VAPID pública no son secretos.
  // Reemplaza estos valores siguiendo docs/firebase_notifications_setup.md.
  globalThis.MISSION_ADMISSION_FIREBASE = Object.freeze({
    enabled: false,
    sdkVersion: '12.16.0',
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
