(() => {
  'use strict';

  let deferredInstallPrompt = null;
  let registration = null;
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
    workerState = 'registering';
  }

  function observeInstallingWorker(worker) {
    if (!worker) return;
    workerState = 'registering';
    worker.addEventListener('statechange', () => {
      updateWorkerState();
    });
  }

  async function registerServiceWorker() {
    if (!('serviceWorker' in navigator)) {
      workerState = 'unsupported';
      return;
    }

    try {
      workerState = 'registering';
      const serviceWorkerUrl = new URL('app_service_worker.js', document.baseURI);
      const scopeUrl = new URL('./', document.baseURI);
      registration = await navigator.serviceWorker.getRegistration(scopeUrl.href);

      if (!registration) {
        const response = await fetch(serviceWorkerUrl, {cache: 'no-store'});
        const source = await response.text();
        const isUnpreparedTemplate = source.includes('__APP_SHELL__') ||
          source.includes('__CONTENT_ASSETS__');
        if (isUnpreparedTemplate) {
          workerState = 'unsupported';
          return;
        }
        registration = await navigator.serviceWorker.register(serviceWorkerUrl, {
          scope: scopeUrl.pathname,
          updateViaCache: 'none',
        });
      }

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
    } catch (error) {
      workerState = 'error';
      errorMessage = error instanceof Error ? error.message : String(error);
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

  window.addEventListener('load', registerServiceWorker, {once: true});
})();
