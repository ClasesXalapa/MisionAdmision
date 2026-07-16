(() => {
  'use strict';

  const INSTALLATION_ID_KEY = 'mision_admision.fcm_installation_id.v1';
  const ENABLED_KEY = 'mision_admision.notifications_enabled.v1';
  const REGISTERED_AT_KEY = 'mision_admision.fcm_registered_at.v1';
  const REGISTRATION_KIND = 'fid';

  let firebaseApp = null;
  let messaging = null;
  let modulesPromise = null;
  let registrationPromise = null;
  let foregroundUnsubscribe = null;
  let registrationObserversReady = false;
  let lastErrorCode = '';
  let lastErrorMessage = '';

  function settings() {
    return globalThis.MISSION_ADMISSION_FIREBASE || {enabled: false};
  }

  function debug(...values) {
    if (settings().debugLogging === true) {
      console.debug('[Misión Admisión / FCM]', ...values);
    }
  }

  function bridgeError(code, message) {
    const error = new Error(message);
    error.code = code;
    return error;
  }

  function rememberError(error, fallbackCode = 'unknown') {
    lastErrorCode = typeof error?.code === 'string' ? error.code : fallbackCode;
    lastErrorMessage = error instanceof Error ? error.message : String(error);
    debug(lastErrorCode, lastErrorMessage);
  }

  function clearError() {
    lastErrorCode = '';
    lastErrorMessage = '';
  }

  function isConfigured() {
    const value = settings();
    const config = value.config || {};
    return value.enabled === true &&
      value.registrationMode === REGISTRATION_KIND &&
      typeof value.vapidKey === 'string' && value.vapidKey.length > 20 &&
      ['apiKey', 'projectId', 'messagingSenderId', 'appId']
        .every((key) => typeof config[key] === 'string' && config[key].trim().length > 0);
  }

  function permissionValue() {
    if (!('Notification' in window)) return 'unsupported';
    return Notification.permission;
  }

  function isSecureContextAvailable() {
    if (window.isSecureContext === true) return true;
    return ['localhost', '127.0.0.1', '::1'].includes(window.location?.hostname || '');
  }

  function isIosLike() {
    const userAgent = navigator.userAgent || '';
    const platform = navigator.platform || '';
    return /iPad|iPhone|iPod/i.test(userAgent) ||
      (platform === 'MacIntel' && (navigator.maxTouchPoints || 0) > 1);
  }

  function isStandalone() {
    return navigator.standalone === true ||
      window.matchMedia?.('(display-mode: standalone)').matches === true;
  }

  function requiresPwaInstallation() {
    return isIosLike() && !isStandalone();
  }

  function basicBrowserSupport() {
    return isSecureContextAvailable() &&
      'Notification' in window &&
      'serviceWorker' in navigator &&
      'PushManager' in window;
  }

  function clearLocalRegistration() {
    localStorage.removeItem(INSTALLATION_ID_KEY);
    localStorage.removeItem(REGISTERED_AT_KEY);
  }

  function clearLocalEnabledState() {
    localStorage.removeItem(ENABLED_KEY);
  }

  function storeRegistration(installationId) {
    if (typeof installationId !== 'string' || installationId.trim().length === 0) {
      return;
    }
    const normalized = installationId.trim();
    localStorage.setItem(INSTALLATION_ID_KEY, normalized);
    localStorage.setItem(REGISTERED_AT_KEY, new Date().toISOString());
    globalThis.dispatchEvent?.(new CustomEvent('mission-admission-fcm-registered', {
      detail: {registrationKind: REGISTRATION_KIND},
    }));
  }

  function safeNotificationLink(value) {
    const fallback = settings().defaultNotificationLink || '#/reto';
    try {
      const scope = new URL('./', document.baseURI);
      const candidate = new URL(value || fallback, document.baseURI);
      if (candidate.origin !== scope.origin || !candidate.pathname.startsWith(scope.pathname)) {
        return new URL(fallback, document.baseURI).href;
      }
      return candidate.href;
    } catch (_) {
      return new URL(fallback, document.baseURI).href;
    }
  }

  function withTimeout(promise, milliseconds, code, message) {
    return new Promise((resolve, reject) => {
      const timeout = window.setTimeout(() => reject(bridgeError(code, message)), milliseconds);
      Promise.resolve(promise).then(
        (value) => {
          window.clearTimeout(timeout);
          resolve(value);
        },
        (error) => {
          window.clearTimeout(timeout);
          reject(error);
        },
      );
    });
  }

  async function serviceWorkerRegistration() {
    if (!('serviceWorker' in navigator)) return null;
    const scopeUrl = new URL('./', document.baseURI);
    let registration = await navigator.serviceWorker.getRegistration(scopeUrl.href);
    if (registration) return registration;

    const timeoutMs = Number(settings().registrationTimeoutMs) || 15000;
    await withTimeout(
      navigator.serviceWorker.ready,
      timeoutMs,
      'service-worker-timeout',
      'El modo PWA no terminó de prepararse a tiempo.',
    );
    registration = await navigator.serviceWorker.getRegistration(scopeUrl.href);
    return registration;
  }

  async function loadModules() {
    if (modulesPromise) return modulesPromise;
    if (globalThis.__MISSION_ADMISSION_FIREBASE_MODULES__) {
      modulesPromise = Promise.resolve(globalThis.__MISSION_ADMISSION_FIREBASE_MODULES__);
      return modulesPromise;
    }
    const version = settings().sdkVersion || '12.16.0';
    modulesPromise = Promise.all([
      import(`https://www.gstatic.com/firebasejs/${version}/firebase-app.js`),
      import(`https://www.gstatic.com/firebasejs/${version}/firebase-messaging.js`),
    ]).then(([appModule, messagingModule]) => ({appModule, messagingModule}));
    return modulesPromise;
  }

  function assertModernMessagingApi(messagingModule) {
    const requiredFunctions = [
      'getMessaging',
      'isSupported',
      'register',
      'unregister',
      'onRegistered',
      'onUnregistered',
      'onMessage',
    ];
    const missing = requiredFunctions.filter((name) => typeof messagingModule[name] !== 'function');
    if (missing.length > 0) {
      throw bridgeError(
        'sdk-incompatible',
        `La versión de Firebase no incluye la API FID requerida: ${missing.join(', ')}.`,
      );
    }
  }

  async function initializeMessaging() {
    if (!isConfigured()) {
      throw bridgeError('not-configured', 'Firebase Cloud Messaging no está configurado.');
    }
    if (!basicBrowserSupport()) {
      throw bridgeError('unsupported', 'Este navegador no admite Web Push seguro.');
    }
    if (requiresPwaInstallation()) {
      throw bridgeError(
        'pwa-install-required',
        'En iPhone o iPad primero agrega Misión Admisión a la pantalla de inicio.',
      );
    }

    const {appModule, messagingModule} = await loadModules();
    assertModernMessagingApi(messagingModule);
    const supported = await messagingModule.isSupported();
    if (!supported) {
      throw bridgeError('unsupported', 'Este navegador no admite Firebase Web Push.');
    }

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
      storeRegistration(installationId);
    });
    messagingModule.onUnregistered(messagingInstance, () => {
      clearLocalRegistration();
      clearLocalEnabledState();
      globalThis.dispatchEvent?.(new CustomEvent('mission-admission-fcm-unregistered'));
    });
  }

  async function performRegistration() {
    const registration = await serviceWorkerRegistration();
    if (!registration) {
      throw bridgeError('service-worker-missing', 'El modo PWA todavía no está preparado.');
    }
    const initialized = await initializeMessaging();
    const cachedInstallationId = localStorage.getItem(INSTALLATION_ID_KEY) || '';
    const timeoutMs = Number(settings().registrationTimeoutMs) || 15000;

    let stopListening = null;
    let confirmationPromise = null;
    if (!cachedInstallationId) {
      confirmationPromise = new Promise((resolve, reject) => {
        const timeout = window.setTimeout(() => {
          stopListening?.();
          reject(bridgeError(
            'registration-timeout',
            'Firebase no confirmó el registro a tiempo.',
          ));
        }, timeoutMs);
        stopListening = initialized.messagingModule.onRegistered(
          initialized.messaging,
          (installationId) => {
            window.clearTimeout(timeout);
            stopListening?.();
            if (!installationId) {
              reject(bridgeError(
                'empty-registration',
                'Firebase devolvió un identificador de instalación vacío.',
              ));
              return;
            }
            storeRegistration(installationId);
            resolve(installationId);
          },
        );
      });
    }

    try {
      await initialized.messagingModule.register(initialized.messaging, {
        vapidKey: settings().vapidKey,
        serviceWorkerRegistration: registration,
      });
      if (cachedInstallationId) return cachedInstallationId;
      return await confirmationPromise;
    } finally {
      if (cachedInstallationId) stopListening?.();
    }
  }

  async function registerInstallation() {
    if (registrationPromise) return registrationPromise;
    registrationPromise = performRegistration().finally(() => {
      registrationPromise = null;
    });
    return registrationPromise;
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
        const link = safeNotificationLink(
          payload.fcmOptions?.link || payload.data?.link,
        );
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

  async function sdkSupportWhenConfigured() {
    if (!isConfigured() || !basicBrowserSupport() || requiresPwaInstallation()) {
      return basicBrowserSupport();
    }
    try {
      const {messagingModule} = await loadModules();
      assertModernMessagingApi(messagingModule);
      return await messagingModule.isSupported();
    } catch (error) {
      rememberError(error, 'sdk-load-failed');
      return false;
    }
  }

  function stateObject({configured, supported, enabled}) {
    return {
      configured,
      supported,
      permission: permissionValue(),
      enabled,
      registrationAvailable: Boolean(localStorage.getItem(INSTALLATION_ID_KEY)),
      registrationKind: localStorage.getItem(INSTALLATION_ID_KEY)
        ? REGISTRATION_KIND
        : 'none',
      registrationUpdatedAt: localStorage.getItem(REGISTERED_AT_KEY) || '',
      secureContext: isSecureContextAvailable(),
      installedAsPwa: isStandalone(),
      requiresPwaInstallation: requiresPwaInstallation(),
      errorCode: lastErrorCode,
      errorMessage: lastErrorMessage,
    };
  }

  async function getState() {
    const configured = isConfigured();
    const supported = await sdkSupportWhenConfigured();
    const permission = permissionValue();

    if (permission !== 'granted') {
      clearLocalEnabledState();
      if (permission === 'denied') clearLocalRegistration();
      return stateObject({configured, supported, enabled: false});
    }

    let enabled = localStorage.getItem(ENABLED_KEY) === 'true';
    if (configured && supported && enabled && !requiresPwaInstallation()) {
      try {
        await registerInstallation();
        await ensureForegroundListener();
      } catch (error) {
        rememberError(error, 'registration-failed');
        enabled = false;
        clearLocalEnabledState();
      }
    }
    return stateObject({configured, supported, enabled});
  }

  async function enable() {
    clearError();
    if (!isConfigured()) {
      throw bridgeError('not-configured', 'Firebase Cloud Messaging no está configurado.');
    }
    if (!basicBrowserSupport()) {
      throw bridgeError('unsupported', 'Las notificaciones Web Push no están disponibles.');
    }
    if (requiresPwaInstallation()) {
      throw bridgeError(
        'pwa-install-required',
        'En iPhone o iPad primero instala la PWA desde Compartir → Agregar a pantalla de inicio.',
      );
    }

    const permission = await Notification.requestPermission();
    if (permission !== 'granted') {
      clearLocalEnabledState();
      return getState();
    }

    try {
      await registerInstallation();
      localStorage.setItem(ENABLED_KEY, 'true');
      await ensureForegroundListener();
    } catch (error) {
      clearLocalEnabledState();
      rememberError(error, 'registration-failed');
      throw error;
    }
    return getState();
  }

  async function refreshRegistration() {
    clearError();
    if (permissionValue() !== 'granted' || localStorage.getItem(ENABLED_KEY) !== 'true') {
      return getState();
    }
    try {
      await registerInstallation();
      await ensureForegroundListener();
    } catch (error) {
      rememberError(error, 'registration-refresh-failed');
    }
    return getState();
  }

  async function disable() {
    clearError();
    try {
      if (isConfigured() && basicBrowserSupport()) {
        const initialized = await initializeMessaging();
        await initialized.messagingModule.unregister(initialized.messaging);
      }
    } catch (error) {
      rememberError(error, 'unregister-failed');
    } finally {
      clearLocalRegistration();
      clearLocalEnabledState();
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
      data: {
        missionAdmission: true,
        link: safeNotificationLink(settings().defaultNotificationLink),
      },
    });
    return true;
  }

  async function getRegistrationSnapshotForBackend() {
    return {
      registrationKind: localStorage.getItem(INSTALLATION_ID_KEY)
        ? REGISTRATION_KIND
        : 'none',
      registrationId: localStorage.getItem(INSTALLATION_ID_KEY) || '',
      registrationUpdatedAt: localStorage.getItem(REGISTERED_AT_KEY) || '',
      enabled: localStorage.getItem(ENABLED_KEY) === 'true',
    };
  }

  globalThis.missionAdmissionNotifications = {
    getState,
    enable,
    disable,
    refreshRegistration,
    showLocalTest,
    getRegistrationSnapshotForBackend,
  };

  navigator.serviceWorker?.addEventListener('message', (event) => {
    if (event.data?.type === 'FCM_REGISTRATION_REFRESH_REQUIRED') {
      refreshRegistration().catch((error) => {
        rememberError(error, 'registration-refresh-failed');
      });
    }
  });

  window.addEventListener('load', () => {
    getState().catch((error) => {
      rememberError(error, 'startup-failed');
    });
  }, {once: true});
})();
