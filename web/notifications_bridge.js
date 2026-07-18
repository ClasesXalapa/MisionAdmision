(() => {
  'use strict';

  const INSTALLATION_ID_KEY = 'mision_admision.fcm_installation_id.v1';
  const ENABLED_KEY = 'mision_admision.notifications_enabled.v1';
  const REGISTERED_AT_KEY = 'mision_admision.fcm_registered_at.v1';
  const REGISTRATION_KIND = 'fid';
  const SERVICE_WORKER_RELEASE = '31';

  let firebaseApp = null;
  let messaging = null;
  let analytics = null;
  let modulesPromise = null;
  let analyticsModulePromise = null;
  let analyticsInitializationPromise = null;
  let analyticsState = 'not-configured';
  let analyticsErrorMessage = '';
  let registrationPromise = null;
  let foregroundUnsubscribe = null;
  let registrationObserversReady = false;
  let lastErrorCode = '';
  let lastErrorMessage = '';

  function settings() {
    return globalThis.MISSION_ADMISSION_FIREBASE || {enabled: false};
  }


  function dailyStateStore() {
    return globalThis.__MISSION_ADMISSION_NOTIFICATION_STATE_STORE__ ||
      globalThis.missionAdmissionNotificationStateStore || null;
  }

  async function dailyStateSnapshot() {
    const store = dailyStateStore();
    if (typeof store?.readSnapshot !== 'function') {
      return {
        supported: false,
        stateInitialized: false,
        lastCompletedDateKey: '',
        challengeAvailable: false,
        stateUpdatedAt: '',
        lastFirebaseReceivedAt: '',
        lastLocalReminderAt: '',
        reminderCountDateKey: '',
        reminderCountForDate: 0,
        lastDecision: 'unsupported',
        lastDecisionAt: '',
        errorMessage: '',
      };
    }
    return store.readSnapshot();
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

  function isAnalyticsConfigured() {
    const value = settings();
    const measurementId = value.config?.measurementId;
    return value.enabled === true &&
      value.analyticsEnabled === true &&
      typeof measurementId === 'string' && /^G-[A-Z0-9]+$/i.test(measurementId.trim());
  }

  function rememberAnalyticsUnavailable(error) {
    analyticsState = 'unavailable';
    analyticsErrorMessage = error instanceof Error ? error.message : String(error);
    debug('analytics-unavailable', analyticsErrorMessage);
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

    // El puente PWA es la única fuente responsable de crear y actualizar el
    // service worker. Esto elimina la carrera entre window.load y el botón de
    // notificaciones, especialmente en la primera visita desde un celular.
    const pwaBridge = globalThis.missionAdmissionPwa;
    if (typeof pwaBridge?.ensureServiceWorker === 'function') {
      return pwaBridge.ensureServiceWorker({
        waitForActive: true,
        timeoutMs: 60000,
      });
    }

    // Respaldo defensivo para pruebas o páginas antiguas que todavía no tengan
    // el método ensureServiceWorker.
    const serviceWorkerUrl = new URL(`app_service_worker.js?v=${SERVICE_WORKER_RELEASE}`, document.baseURI);
    const scopeUrl = new URL('./', document.baseURI);
    const registration = await navigator.serviceWorker.register(serviceWorkerUrl, {
      scope: scopeUrl.pathname,
      updateViaCache: 'none',
    });
    if (registration.active) return registration;

    return withTimeout(
      navigator.serviceWorker.ready,
      60000,
      'service-worker-timeout',
      'El modo PWA continúa preparándose. Recarga la página y vuelve a intentarlo.',
    );
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

  async function loadAnalyticsModule() {
    if (analyticsModulePromise) return analyticsModulePromise;
    const injected = globalThis.__MISSION_ADMISSION_FIREBASE_MODULES__;
    if (injected?.analyticsModule) {
      analyticsModulePromise = Promise.resolve(injected.analyticsModule);
      return analyticsModulePromise;
    }
    const version = settings().sdkVersion || '12.16.0';
    analyticsModulePromise = import(
      `https://www.gstatic.com/firebasejs/${version}/firebase-analytics.js`
    );
    return analyticsModulePromise;
  }

  async function initializeFirebaseApp() {
    const {appModule} = await loadModules();
    if (!firebaseApp) {
      firebaseApp = appModule.getApps().length > 0
        ? appModule.getApps()[0]
        : appModule.initializeApp(settings().config);
    }
    return firebaseApp;
  }

  async function initializeAnalyticsBestEffort() {
    if (!isAnalyticsConfigured()) {
      analyticsState = 'not-configured';
      analyticsErrorMessage = '';
      return;
    }
    if (analyticsState === 'active' || analyticsInitializationPromise) {
      return analyticsInitializationPromise;
    }

    analyticsState = 'loading';
    analyticsErrorMessage = '';
    analyticsInitializationPromise = (async () => {
      try {
        const app = await initializeFirebaseApp();
        const analyticsModule = await loadAnalyticsModule();
        if (typeof analyticsModule.isSupported !== 'function' ||
            typeof analyticsModule.getAnalytics !== 'function') {
          throw bridgeError(
            'analytics-sdk-incompatible',
            'La versión de Firebase no incluye el módulo Analytics esperado.',
          );
        }
        const supported = await analyticsModule.isSupported();
        if (!supported) {
          analyticsState = 'unsupported';
          return;
        }
        analytics = analyticsModule.getAnalytics(app);
        analyticsState = analytics ? 'active' : 'unavailable';
      } catch (error) {
        rememberAnalyticsUnavailable(error);
      }
    })();
    return analyticsInitializationPromise;
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

    const {messagingModule} = await loadModules();
    assertModernMessagingApi(messagingModule);
    const supported = await messagingModule.isSupported();
    if (!supported) {
      throw bridgeError('unsupported', 'Este navegador no admite Firebase Web Push.');
    }

    await initializeFirebaseApp();
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
        const store = dailyStateStore();
        try {
          await store?.recordFirebaseWake?.();
          await store?.recordDecision?.('app_visible');
        } catch (_) {
          // El diagnóstico inteligente nunca debe bloquear el mensaje de Firebase.
        }

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
          tag: payload.data?.tag || `mision-admision-firebase-${Date.now()}`,
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

  function stateObject({configured, supported, enabled, dailyState}) {
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
      analyticsConfigured: isAnalyticsConfigured(),
      analyticsState,
      analyticsErrorMessage,
      smartReminderSupported: dailyState.supported === true,
      smartReminderStateInitialized: dailyState.stateInitialized === true,
      smartReminderLastCompletedDateKey: dailyState.lastCompletedDateKey || '',
      smartReminderChallengeAvailable: dailyState.challengeAvailable === true,
      smartReminderStateUpdatedAt: dailyState.stateUpdatedAt || '',
      smartReminderLastFirebaseReceivedAt:
        dailyState.lastFirebaseReceivedAt || '',
      smartReminderLastLocalAt: dailyState.lastLocalReminderAt || '',
      smartReminderCountDateKey: dailyState.reminderCountDateKey || '',
      smartReminderCountForDate: String(Number(dailyState.reminderCountForDate) || 0),
      smartReminderLastDecision: dailyState.lastDecision || '',
      smartReminderLastDecisionAt: dailyState.lastDecisionAt || '',
      smartReminderErrorMessage: dailyState.errorMessage || '',
      errorCode: lastErrorCode,
      errorMessage: lastErrorMessage,
    };
  }

  async function getState() {
    await initializeAnalyticsBestEffort();
    const configured = isConfigured();
    const supported = await sdkSupportWhenConfigured();
    const permission = permissionValue();
    const dailyState = await dailyStateSnapshot();

    if (permission !== 'granted') {
      clearLocalEnabledState();
      if (permission === 'denied') clearLocalRegistration();
      return stateObject({configured, supported, enabled: false, dailyState});
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
    return stateObject({configured, supported, enabled, dailyState});
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
    await registration.showNotification('Notificaciones activadas 🔔', {
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

  async function closeDailyChallengeReminders() {
    const registration = await serviceWorkerRegistration();
    if (!registration) return false;

    registration.active?.postMessage?.({type: 'DAILY_CHALLENGE_COMPLETED'});
    if (typeof registration.getNotifications === 'function') {
      const notifications = await registration.getNotifications();
      for (const notification of notifications) {
        if (notification.data?.kind === 'daily-challenge-reminder') {
          notification.close();
        }
      }
    }
    return true;
  }

  async function syncDailyChallengeState(
    lastCompletedDateKey,
    challengeAvailable,
  ) {
    const store = dailyStateStore();
    if (typeof store?.syncDailyProgress !== 'function') return false;
    const normalized = typeof lastCompletedDateKey === 'string'
      ? lastCompletedDateKey.trim()
      : '';
    const saved = await store.syncDailyProgress(
      normalized,
      challengeAvailable === true,
    );
    const today = store.localDateKey?.(new Date()) || '';
    if (normalized && normalized === today) {
      try {
        await closeDailyChallengeReminders();
      } catch (error) {
        debug('close-daily-reminders-failed', error);
      }
    }
    return saved === true;
  }

  async function getTestingInstallationId() {
    if (localStorage.getItem(ENABLED_KEY) !== 'true') return '';
    return localStorage.getItem(INSTALLATION_ID_KEY) || '';
  }

  globalThis.missionAdmissionNotifications = {
    getState,
    enable,
    disable,
    refreshRegistration,
    showLocalTest,
    getTestingInstallationId,
    syncDailyChallengeState,
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
