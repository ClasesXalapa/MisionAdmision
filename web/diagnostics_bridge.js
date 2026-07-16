(() => {
  'use strict';

  function parseBrowser(userAgent) {
    const rules = [
      [/Edg\/([\d.]+)/, 'Edge'],
      [/OPR\/([\d.]+)/, 'Opera'],
      [/CriOS\/([\d.]+)/, 'Chrome iOS'],
      [/Chrome\/([\d.]+)/, 'Chrome'],
      [/FxiOS\/([\d.]+)/, 'Firefox iOS'],
      [/Firefox\/([\d.]+)/, 'Firefox'],
      [/Version\/([\d.]+).*Safari\//, 'Safari'],
    ];
    for (const [pattern, name] of rules) {
      const match = userAgent.match(pattern);
      if (match) return {name, version: match[1] || ''};
    }
    return {name: 'Desconocido', version: ''};
  }

  function parseOperatingSystem(userAgent) {
    if (/Windows NT 10\.0/i.test(userAgent)) return 'Windows';
    if (/Windows/i.test(userAgent)) return 'Windows';
    if (/Android ([\d.]+)/i.test(userAgent)) {
      const match = userAgent.match(/Android ([\d.]+)/i);
      return `Android ${match?.[1] || ''}`.trim();
    }
    if (/iPhone|iPad|iPod/i.test(userAgent)) {
      const match = userAgent.match(/OS ([\d_]+)/i);
      return `iOS ${(match?.[1] || '').replaceAll('_', '.')}`.trim();
    }
    if (/Mac OS X/i.test(userAgent)) {
      const match = userAgent.match(/Mac OS X ([\d_]+)/i);
      return `macOS ${(match?.[1] || '').replaceAll('_', '.')}`.trim();
    }
    if (/Linux/i.test(userAgent)) return 'Linux';
    return 'Desconocido';
  }

  function displayMode() {
    if (window.matchMedia?.('(display-mode: standalone)').matches ||
        navigator.standalone === true) {
      return 'standalone';
    }
    if (window.matchMedia?.('(display-mode: minimal-ui)').matches) {
      return 'minimal-ui';
    }
    return 'browser';
  }

  async function readServiceWorkerState() {
    if (!('serviceWorker' in navigator)) {
      return {
        supported: false,
        controlled: false,
        state: 'unsupported',
      };
    }
    try {
      const registration = await navigator.serviceWorker.getRegistration(
        new URL('./', document.baseURI).href,
      );
      let state = 'missing';
      if (registration?.waiting) state = 'waiting';
      else if (registration?.installing) state = 'installing';
      else if (registration?.active) state = registration.active.state || 'active';
      return {
        supported: true,
        controlled: Boolean(navigator.serviceWorker.controller),
        state,
      };
    } catch (error) {
      return {
        supported: true,
        controlled: Boolean(navigator.serviceWorker.controller),
        state: 'error',
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async function readStorage() {
    const estimateSupported = Boolean(navigator.storage?.estimate);
    const persistentSupported = Boolean(navigator.storage?.persisted);
    let usage = null;
    let quota = null;
    let persistent = null;
    if (estimateSupported) {
      try {
        const estimate = await navigator.storage.estimate();
        usage = Number.isFinite(estimate.usage) ? Math.round(estimate.usage) : null;
        quota = Number.isFinite(estimate.quota) ? Math.round(estimate.quota) : null;
      } catch (_) {
        usage = null;
        quota = null;
      }
    }
    if (persistentSupported) {
      try {
        persistent = await navigator.storage.persisted();
      } catch (_) {
        persistent = null;
      }
    }
    return {
      estimateSupported,
      persistentSupported,
      usage,
      quota,
      persistent,
    };
  }

  async function getReportJson() {
    try {
      const userAgent = navigator.userAgent || '';
      const browser = parseBrowser(userAgent);
      const worker = await readServiceWorkerState();
      const storage = await readStorage();
      const connection = navigator.connection || navigator.mozConnection ||
        navigator.webkitConnection;
      const report = {
        supported: true,
        browser_name: browser.name,
        browser_version: browser.version,
        operating_system: parseOperatingSystem(userAgent),
        platform: navigator.userAgentData?.platform || navigator.platform || '',
        user_agent: userAgent,
        language: navigator.language || '',
        time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone || '',
        screen_width: Math.round(window.screen?.width || 0),
        screen_height: Math.round(window.screen?.height || 0),
        viewport_width: Math.round(window.innerWidth || 0),
        viewport_height: Math.round(window.innerHeight || 0),
        device_pixel_ratio: Number(window.devicePixelRatio || 1),
        online: navigator.onLine !== false,
        secure_context: window.isSecureContext === true,
        cookies_enabled: navigator.cookieEnabled === true,
        display_mode: displayMode(),
        service_worker_supported: worker.supported,
        service_worker_controlled: worker.controlled,
        service_worker_state: worker.state,
        storage_estimate_supported: storage.estimateSupported,
        storage_usage_bytes: storage.usage,
        storage_quota_bytes: storage.quota,
        persistent_storage_supported: storage.persistentSupported,
        persistent_storage_granted: storage.persistent,
        connection_type: connection?.effectiveType || connection?.type || null,
        error_message: worker.error || '',
      };
      return JSON.stringify(report);
    } catch (error) {
      return JSON.stringify({
        supported: false,
        error_message: error instanceof Error ? error.message : String(error),
      });
    }
  }

  globalThis.missionAdmissionDiagnostics = {getReportJson};
})();
