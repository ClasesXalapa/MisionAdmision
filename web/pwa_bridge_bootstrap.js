(() => {
  'use strict';

  let deferredInstallPrompt = null;
  let registration = null;
  let registrationPromise = null;
  let workerState = 'unsupported';
  let errorMessage = '';
  let reloadWhenControlled = false;
  let automaticControllerReloadDone = false;

  const SERVICE_WORKER_RELEASE = '35';

  const standaloneQuery = window.matchMedia('(display-mode: standalone)');
  const isIos = /iphone|ipad|ipod/i.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  function isInstalled() {
    return standaloneQuery.matches || navigator.standalone === true;
  }

  function resolveInstallMode() {
    if (isInstalled()) return 'installed';
    if (deferredInstallPrompt) return 'prompt';
    if (isIos) return 'manual';
    return 'unavailable';
  }

  function updateWorkerState() {
    if (!('serviceWorker' in navigator)) {
      workerState = 'unsupported';
      return;
    }
    if (registration?.waiting) {
      workerState = 'waiting';
      return;
    }
    if (registration?.active) {
      workerState = 'active';
      return;
    }
    if (registration?.installing) {
      workerState = 'registering';
      return;
    }
    workerState = registration ? 'registering' : 'unsupported';
  }

  function observeInstallingWorker(worker) {
    if (!worker) return;
    workerState = 'registering';
    worker.addEventListener('statechange', () => {
      updateWorkerState();
    });
  }

  function timeoutError(message) {
    const error = new Error(message);
    error.code = 'service-worker-timeout';
    return error;
  }

  function hasWorker(value) {
    return Boolean(value?.installing || value?.waiting || value?.active);
  }

  async function registrationForScope(scopeUrl) {
    if (typeof navigator.serviceWorker.getRegistration === 'function') {
      const value = await navigator.serviceWorker.getRegistration(scopeUrl.href);
      if (value) return value;
    }
    if (typeof navigator.serviceWorker.getRegistrations === 'function') {
      const values = await navigator.serviceWorker.getRegistrations();
      return values.find((value) => value.scope === scopeUrl.href) || null;
    }
    return null;
  }

  function delay(milliseconds) {
    return new Promise((resolve) => window.setTimeout(resolve, milliseconds));
  }

  async function waitForRegistrationRemoval(scopeUrl, timeoutMs = 5000) {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      const current = await registrationForScope(scopeUrl);
      if (!current) return true;
      if (hasWorker(current)) return false;
      await delay(100);
    }
    return !(await registrationForScope(scopeUrl));
  }

  async function createServiceWorkerRegistration(serviceWorkerUrl, scopeUrl) {
    const options = {
      scope: scopeUrl.pathname,
      updateViaCache: 'none',
    };

    // register() crea o actualiza la inscripción del mismo alcance. No se elimina
    // una inscripción activa solo porque su script anterior tenga otro nombre.
    let value = await navigator.serviceWorker.register(serviceWorkerUrl, options);
    if (hasWorker(value)) return value;

    // Versiones anteriores podían dejar una inscripción vacía mientras
    // flutter_bootstrap y el puente propio competían por el mismo alcance.
    // Primero se vuelve a consultar porque el navegador puede completar la tarea
    // en segundo plano y exponer el worker en un objeto de registro nuevo.
    for (let attempt = 0; attempt < 30; attempt += 1) {
      await delay(100);
      const current = await registrationForScope(scopeUrl);
      if (hasWorker(current)) return current;
      if (!current) break;
      value = current;
    }

    // Solo se elimina una inscripción fantasma sin installing/waiting/active.
    // Nunca se desregistra un worker funcional ni se toca el almacenamiento local.
    if (value && !hasWorker(value)) {
      const unregistered = await value.unregister();
      if (!unregistered) {
        throw new Error('Chrome no permitió eliminar la inscripción PWA incompleta.');
      }
      const removed = await waitForRegistrationRemoval(scopeUrl, 10000);
      if (!removed) {
        throw new Error('Chrome no terminó de eliminar la inscripción PWA incompleta.');
      }
    }

    const recoveryUrl = new URL(serviceWorkerUrl.href);
    recoveryUrl.searchParams.set('recovery', '1');
    return navigator.serviceWorker.register(recoveryUrl, options);
  }

  async function waitForActiveWorker(initialValue, scopeUrl, timeoutMs = 60000) {
    if (initialValue?.active) return initialValue;

    return new Promise((resolve, reject) => {
      let settled = false;
      let timeout = null;
      let poll = null;
      let currentValue = initialValue;
      const cleanups = [];
      const observedWorkers = new Set();

      const cleanup = () => {
        if (timeout !== null) window.clearTimeout(timeout);
        if (poll !== null) window.clearInterval(poll);
        while (cleanups.length > 0) cleanups.pop()();
      };
      const finish = (result) => {
        if (settled) return;
        settled = true;
        registration = result;
        updateWorkerState();
        cleanup();
        resolve(result);
      };
      const fail = (error) => {
        if (settled) return;
        settled = true;
        cleanup();
        reject(error);
      };
      const observe = (target, eventName, callback) => {
        if (!target?.addEventListener) return;
        target.addEventListener(eventName, callback);
        cleanups.push(() => target.removeEventListener?.(eventName, callback));
      };
      const observeCandidate = (candidate) => {
        if (!candidate || observedWorkers.has(candidate)) return;
        observedWorkers.add(candidate);
        observe(candidate, 'statechange', inspect);
      };
      const adopt = (value) => {
        if (!value) return;
        currentValue = value;
        registration = value;
        observeCandidate(value.installing);
        observeCandidate(value.waiting);
      };
      const inspect = async () => {
        try {
          const latest = await registrationForScope(scopeUrl);
          if (latest) adopt(latest);
          updateWorkerState();
          if (currentValue?.active) {
            finish(currentValue);
            return;
          }
          const candidate = currentValue?.installing || currentValue?.waiting;
          observeCandidate(candidate);
          if (candidate?.state === 'redundant') {
            fail(new Error(
              'El service worker fue descartado durante su instalación. Recarga la página e inténtalo de nuevo.',
            ));
          }
        } catch (error) {
          fail(error);
        }
      };

      adopt(initialValue);
      observe(currentValue, 'updatefound', inspect);
      if (navigator.serviceWorker?.addEventListener) {
        observe(navigator.serviceWorker, 'controllerchange', inspect);
      }

      // Los objetos ServiceWorkerRegistration pueden quedar obsoletos tras una
      // migración. El sondeo recupera el objeto actual del navegador.
      poll = window.setInterval(inspect, 250);
      timeout = window.setTimeout(() => {
        const current = currentValue?.installing?.state ||
          currentValue?.waiting?.state ||
          currentValue?.active?.state ||
          'sin estado';
        fail(timeoutError(
          `El modo PWA continúa preparándose (${current}). Recarga la página y vuelve a intentarlo.`,
        ));
      }, Math.max(10000, Number(timeoutMs) || 60000));

      inspect();
    });
  }

  async function registerServiceWorker({waitForActive = false, timeoutMs = 60000} = {}) {
    if (!('serviceWorker' in navigator)) {
      workerState = 'unsupported';
      return null;
    }

    if (!registrationPromise) {
      registrationPromise = (async () => {
        try {
          workerState = 'registering';
          errorMessage = '';
          const serviceWorkerUrl = new URL(
            `app_service_worker.js?v=${SERVICE_WORKER_RELEASE}`,
            document.baseURI,
          );
          const scopeUrl = new URL('./', document.baseURI);

          const response = await fetch(serviceWorkerUrl, {cache: 'no-store'});
          if (!response.ok) {
            throw new Error(
              `No se pudo descargar el módulo PWA: HTTP ${response.status}.`,
            );
          }
          const source = await response.text();
          const isUnpreparedTemplate = source.includes('__APP_SHELL__') ||
            source.includes('__CONTENT_ASSETS__');
          if (isUnpreparedTemplate) {
            throw new Error(
              'El service worker publicado no fue preparado por GitHub Actions.',
            );
          }

          // register() ya crea o actualiza la inscripción del mismo alcance. No se
          // llama update() inmediatamente: una inscripción recién creada puede no tener
          // todavía un worker activo y Chrome intentaría actualizar un script desconocido.
          registration = await createServiceWorkerRegistration(
            serviceWorkerUrl,
            scopeUrl,
          );

          updateWorkerState();
          observeInstallingWorker(registration.installing);
          registration.addEventListener('updatefound', () => {
            observeInstallingWorker(registration.installing);
          });
          return registration;
        } catch (error) {
          workerState = 'error';
          errorMessage = error instanceof Error ? error.message : String(error);
          registrationPromise = null;
          throw error;
        }
      })();
    }

    const value = await registrationPromise;
    if (!waitForActive) return value;
    const scopeUrl = new URL('./', document.baseURI);
    try {
      return await waitForActiveWorker(value, scopeUrl, timeoutMs);
    } catch (error) {
      registrationPromise = null;
      throw error;
    }
  }

  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    deferredInstallPrompt = event;
  });

  window.addEventListener('appinstalled', () => {
    deferredInstallPrompt = null;
  });

  standaloneQuery.addEventListener?.('change', () => {
    if (isInstalled()) deferredInstallPrompt = null;
  });

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      updateWorkerState();
      if (reloadWhenControlled || !automaticControllerReloadDone) {
        reloadWhenControlled = false;
        automaticControllerReloadDone = true;
        window.location.reload();
      }
    });

    navigator.serviceWorker.addEventListener('message', (event) => {
      if (event.data?.type === 'CACHE_READY') {
        workerState = 'active';
      }
    });
  }

  window.missionAdmissionPwa = {
    async getState() {
      updateWorkerState();
      return {
        online: navigator.onLine,
        installMode: resolveInstallMode(),
        workerState,
        updateAvailable: Boolean(registration?.waiting),
        errorMessage,
      };
    },

    async ensureServiceWorker(options = {}) {
      return registerServiceWorker({
        waitForActive: options.waitForActive !== false,
        timeoutMs: options.timeoutMs || 60000,
      });
    },

    async requestInstall() {
      if (!deferredInstallPrompt) return false;
      const prompt = deferredInstallPrompt;
      deferredInstallPrompt = null;
      await prompt.prompt();
      const choice = await prompt.userChoice;
      return choice.outcome === 'accepted';
    },

    async activateUpdate() {
      if (!registration?.waiting) return false;
      reloadWhenControlled = true;
      registration.waiting.postMessage({type: 'SKIP_WAITING'});
      return true;
    },
  };

  // Comienza a preparar la PWA en cuanto se carga el puente, sin esperar a que
  // el usuario pulse el botón de notificaciones.
  registerServiceWorker().catch(() => {});
})();
