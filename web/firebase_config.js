(() => {
  'use strict';

  // Esta configuración es pública y puede vivir en GitHub Pages.
  // Nunca agregues cuentas de servicio ni claves privadas aquí.
  globalThis.MISSION_ADMISSION_FIREBASE = Object.freeze({
    enabled: true,

    // Conserva la versión incluida en el proyecto.
    sdkVersion: '12.16.0',

    // No cambiar: la aplicación utiliza Firebase Installation ID.
    registrationMode: 'fid',

    registrationTimeoutMs: 15000,

    // Ruta que se abrirá al pulsar una notificación.
    defaultNotificationLink: '#/reto',

    // Déjalo en false para producción.
    debugLogging: false,

    // Clave pública obtenida en Certificados Web Push.
    vapidKey: 'BGpJpxa1GEspwaHTJF2AUc0At_v4EvVpEexMamtsuZwZdbOeHbk1bwqjlA2lyPx2GGnGQggdADdhW5mljfyb1vg',

    config: Object.freeze({
      apiKey: 'AIzaSyAEk2h4ZOlwkMJj8Zk5CFMLaKbkrkgPJGs',
      authDomain: 'mision-admision.firebaseapp.com',
      projectId: 'mision-admision',
      storageBucket: 'mision-admision.firebasestorage.app',
      messagingSenderId: '136898498886',
      appId: '1:136898498886:web:2fd8c63a294c61148b9547',
    }),
  });
})();
