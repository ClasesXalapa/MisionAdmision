(() => {
  'use strict';

  const RELEASE = '43';
  const STORAGE_KEY = 'mision_admision.web_release.v1';

  window.missionAdmissionBuildReady = (async () => {
    let previous = null;
    try {
      previous = window.localStorage.getItem(STORAGE_KEY);
      window.localStorage.setItem(STORAGE_KEY, RELEASE);
    } catch (_) {
      return;
    }

    if (previous === null || previous === RELEASE) return;

    // Elimina únicamente la caché del código de la aplicación. No toca el
    // progreso local, preferencias ni los documentos de contenido descargados.
    if ('caches' in window) {
      const names = await window.caches.keys();
      await Promise.all(
        names
          .filter((name) => name.startsWith('mision-admision-app-'))
          .map((name) => window.caches.delete(name)),
      );
    }

    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(
        registrations.map((registration) => registration.update().catch(() => null)),
      );
    }

    const url = new URL(window.location.href);
    if (url.searchParams.get('_ma_release') !== RELEASE) {
      url.searchParams.set('_ma_release', RELEASE);
      window.location.replace(url.toString());
      await new Promise(() => {});
    }
  })();
})();
