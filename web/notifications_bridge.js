(() => {
  'use strict';

  const INSTALLATION_ID_KEY = 'mision_admision.fcm_installation_id.v1';
  const ENABLED_KEY = 'mision_admision.notifications_enabled.v1';
  let firebaseApp = null;
  let messaging = null;
  let modulesPromise = null;
  let foregroundUnsubscribe = null;
  let registrationObserversReady = false;
  let lastError = '';

  function settings() {
    return globalThis.MISSION_ADMISSION_FIREBASE || {enabled: false};
  }

  function isConfigured() {
    const value = settings();
    const config = value.config || {};
    return value.enabled === true &&
      typeof value.vapidKey === 'string' && value.vapidKey.length > 20 &&
      ['apiKey', 'projectId', 'messagingSenderId', 'appId']
        .every((key) => typeof config[key] === 'string' && config[key].length > 0);
  }

  function permissionValue() {
    if (!('Notification' in window)) return 'unsupported';
    return Notification.permission;
  }

  async function serviceWorkerRegistration() {
    if (!('serviceWorker' in navigator)) return null;
    const scopeUrl = new URL('./', document.baseURI);
    let registration = await navigator.serviceWorker.getRegistration(scopeUrl.href);
    if (!registration) {
      await navigator.serviceWorker.ready;
      registration = await navigator.serviceWorker.getRegistration(scopeUrl.href);
    }
    return registration;
  }

  async function loadModules() {
    if (modulesPromise) return modulesPromise;
    const version = settings().sdkVersion || '12.16.0';
    modulesPromise = Promise.all([
      import(`https://www.gstatic.com/firebasejs/${version}/firebase-app.js`),
      import(`https://www.gstatic.com/firebasejs/${version}/firebase-messaging.js`),
    ]).then(([appModule, messagingModule]) => ({appModule, messagingModule}));
    return modulesPromise;
  }

  async function initializeMessaging() {
    if (!isConfigured()) throw new Error('Firebase Cloud Messaging no está configurado.');
    const {appModule, messagingModule} = await loadModules();
    const supported = await messagingModule.isSupported();
    if (!supported) throw new Error('Este navegador no admite Web Push.');

    if (!firebaseApp) {
      firebaseApp = appModule.getApps().length > 0
        ? appModule.getApps()[0]
        : appModule.initializeApp(settings().config);
    }
    if (!messaging) messaging = messagingModule.getMessaging(firebaseApp);
    ensureRegistrationObservers(messagingModule, messaging);
    return {messagingModule, messaging};
  }

  function ensureRegistrationObservers(messagingModule, messagingInstance) {
    if (registrationObserversReady) return;
    registrationObserversReady = true;
    messagingModule.onRegistered(messagingInstance, (installationId) => {
      if (installationId) {
        localStorage.setItem(INSTALLATION_ID_KEY, installationId);
      }
    });
    messagingModule.onUnregistered(messagingInstance, () => {
      localStorage.removeItem(INSTALLATION_ID_KEY);
      localStorage.removeItem(ENABLED_KEY);
    });
  }

  async function registerInstallation() {
    const registration = await serviceWorkerRegistration();
    if (!registration) throw new Error('El modo PWA todavía no está preparado.');
    const initialized = await initializeMessaging();

    let stopListening = null;
    const installationIdPromise = new Promise((resolve, reject) => {
      const timeout = window.setTimeout(() => {
        stopListening?.();
        reject(new Error('Firebase no confirmó el registro a tiempo.'));
      }, 15000);
      stopListening = initialized.messagingModule.onRegistered(
        initialized.messaging,
        (installationId) => {
          window.clearTimeout(timeout);
          stopListening?.();
          if (!installationId) {
            reject(new Error('Firebase devolvió un identificador vacío.'));
            return;
          }
          localStorage.setItem(INSTALLATION_ID_KEY, installationId);
          resolve(installationId);
        },
      );
    });

    await initialized.messagingModule.register(initialized.messaging, {
      vapidKey: settings().vapidKey,
      serviceWorkerRegistration: registration,
    });
    return installationIdPromise;
  }

  async function ensureForegroundListener() {
    if (foregroundUnsubscribe || permissionValue() !== 'granted') return;
    const initialized = await initializeMessaging();
    foregroundUnsubscribe = initialized.messagingModule.onMessage(
      initialized.messaging,
      async (payload) => {
        const registration = await serviceWorkerRegistration();
        if (!registration) return;
        const title = payload.notification?.title ||
          payload.data?.title || 'Misión Admisión';
        const body = payload.notification?.body || payload.data?.body ||
          'Tienes un nuevo recordatorio.';
        const link = payload.fcmOptions?.link || payload.data?.link || './';
        await registration.showNotification(title, {
          body,
          icon: new URL('icons/Icon-192.png', document.baseURI).href,
          badge: new URL('icons/Icon-192.png', document.baseURI).href,
          tag: payload.data?.tag || 'mision-admision-reminder',
          renotify: false,
          data: {missionAdmission: true, link},
        });
      },
    );
  }

  async function getState() {
    const configured = isConfigured();
    const supported = 'Notification' in window &&
      'serviceWorker' in navigator && 'PushManager' in window;
    const permission = permissionValue();
    let enabled = permission === 'granted' &&
      localStorage.getItem(ENABLED_KEY) === 'true';

    if (configured && supported && enabled) {
      try {
        await registerInstallation();
        await ensureForegroundListener();
      } catch (error) {
        lastError = error instanceof Error ? error.message : String(error);
        enabled = false;
      }
    }

    return {
      configured,
      supported,
      permission,
      enabled,
      registrationAvailable: Boolean(localStorage.getItem(INSTALLATION_ID_KEY)),
      errorMessage: lastError,
    };
  }

  async function enable() {
    lastError = '';
    if (!isConfigured()) throw new Error('Firebase Cloud Messaging no está configurado.');
    if (!('Notification' in window)) throw new Error('Las notificaciones no están disponibles.');

    const permission = await Notification.requestPermission();
    if (permission !== 'granted') {
      localStorage.removeItem(ENABLED_KEY);
      return getState();
    }

    await registerInstallation();
    localStorage.setItem(ENABLED_KEY, 'true');
    await ensureForegroundListener();
    return getState();
  }

  async function disable() {
    lastError = '';
    try {
      if (isConfigured()) {
        const initialized = await initializeMessaging();
        await initialized.messagingModule.unregister(initialized.messaging);
      }
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error);
    } finally {
      localStorage.removeItem(INSTALLATION_ID_KEY);
      localStorage.removeItem(ENABLED_KEY);
      if (foregroundUnsubscribe) {
        foregroundUnsubscribe();
        foregroundUnsubscribe = null;
      }
    }
    return getState();
  }

  async function showLocalTest() {
    if (permissionValue() !== 'granted') return false;
    const registration = await serviceWorkerRegistration();
    if (!registration) return false;
    await registration.showNotification('Recordatorio activado 🔔', {
      body: 'Misión Admisión puede mostrarte el recordatorio diario.',
      icon: new URL('icons/Icon-192.png', document.baseURI).href,
      badge: new URL('icons/Icon-192.png', document.baseURI).href,
      tag: 'mision-admision-local-test',
      data: {missionAdmission: true, link: './'},
    });
    return true;
  }

  async function getInstallationIdForTesting() {
    return localStorage.getItem(INSTALLATION_ID_KEY) || '';
  }

  globalThis.missionAdmissionNotifications = {
    getState,
    enable,
    disable,
    showLocalTest,
    getInstallationIdForTesting,
  };

  window.addEventListener('load', () => {
    getState().catch((error) => {
      lastError = error instanceof Error ? error.message : String(error);
    });
  }, {once: true});
})();
