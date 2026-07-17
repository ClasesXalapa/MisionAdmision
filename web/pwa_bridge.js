(() => {
  'use strict';

  let deferredInstallPrompt = null;
  let registration = null;
  let registrationPromise = null;
  let workerState = 'unsupported';
  let errorMessage = '';
  let reloadWhenControlled = false;

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

  async function waitForActiveWorker(value, timeoutMs = 60000) {
    if (value?.active) return value;

    return new Promise((resolve, reject) => {
      let settled = false;
      let timeout = null;
      const cleanups = [];

      const cleanup = () => {
        if (timeout !== null) window.clearTimeout(timeout);
        while (cleanups.length > 0) cleanups.pop()();
      };
      const finish = (result) => {
        if (settled) return;
        settled = true;
        cleanup();
        resolve(result);
      };
      const fail = (error) => {
        if (settled) return;
        settled = true;
        cleanup();
        reject(error);
      };
      const inspect = () => {
        updateWorkerState();
        if (value?.active) {
          finish(value);
          return;
        }
        const candidate = value?.installing || value?.waiting;
        if (candidate?.state === 'redundant') {
          fail(new Error(
            'El service worker fue descartado durante su instalación. Recarga la página e inténtalo de nuevo.',
          ));
        }
      };
      const observe = (target, eventName) => {
        if (!target?.addEventListener) return;
        target.addEventListener(eventName, inspect);
        cleanups.push(() => target.removeEventListener?.(eventName, inspect));
      };
      const observeCandidate = (candidate) => {
        if (!candidate) return;
        observe(candidate, 'statechange');
      };

      observe(value, 'updatefound');
      observeCandidate(value?.installing);
      observeCandidate(value?.waiting);
      if (navigator.serviceWorker?.addEventListener) {
        navigator.serviceWorker.addEventListener('controllerchange', inspect);
        cleanups.push(() => navigator.serviceWorker.removeEventListener?.(
          'controllerchange',
          inspect,
        ));
      }
      value?.addEventListener?.('updatefound', () => {
        observeCandidate(value.installing);
        inspect();
      }, {once: true});

      timeout = window.setTimeout(() => {
        const current = value?.installing?.state || value?.waiting?.state || 'sin estado';
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
          const serviceWorkerUrl = new URL('app_service_worker.js', document.baseURI);
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

          // register() crea o actualiza la inscripción del mismo alcance. Es seguro
          // invocarlo de nuevo y evita depender de una carrera con window.load.
          registration = await navigator.serviceWorker.register(serviceWorkerUrl, {
            scope: scopeUrl.pathname,
            updateViaCache: 'none',
          });

          updateWorkerState();
          observeInstallingWorker(registration.installing);
          registration.addEventListener('updatefound', () => {
            observeInstallingWorker(registration.installing);
          });

          try {
            await registration.update();
          } catch (error) {
            if (!registration.active) throw error;
          }
          updateWorkerState();
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
    return waitForActiveWorker(value, timeoutMs);
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
      if (reloadWhenControlled) {
        reloadWhenControlled = false;
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
