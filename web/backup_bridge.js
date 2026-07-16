(() => {
  'use strict';

  function safeFileName(value) {
    const candidate = String(value || 'mision-admision-progreso.json')
      .replace(/[^A-Za-z0-9._-]/g, '-');
    return candidate.endsWith('.json') ? candidate : `${candidate}.json`;
  }

  async function downloadText(fileName, content) {
    const blob = new Blob([String(content)], {
      type: 'application/json;charset=utf-8',
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = safeFileName(fileName);
    anchor.rel = 'noopener';
    anchor.style.display = 'none';
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    window.setTimeout(() => URL.revokeObjectURL(url), 1000);
    return true;
  }

  function pickJsonFile(maximumBytes) {
    return new Promise((resolve) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = 'application/json,.json';
      input.multiple = false;
      input.style.display = 'none';
      document.body.appendChild(input);
      let settled = false;

      function finish(result) {
        if (settled) return;
        settled = true;
        window.removeEventListener('focus', onFocus);
        input.remove();
        resolve(result);
      }

      function cancelled() {
        finish({
          cancelled: true,
          fileName: '',
          content: '',
          errorMessage: '',
        });
      }

      function onFocus() {
        window.setTimeout(() => {
          if (!settled && (!input.files || input.files.length === 0)) {
            cancelled();
          }
        }, 500);
      }

      input.addEventListener('cancel', cancelled, {once: true});
      input.addEventListener('change', async () => {
        const file = input.files?.[0];
        if (!file) {
          cancelled();
          return;
        }
        if (!file.name.toLowerCase().endsWith('.json')) {
          finish({
            cancelled: false,
            fileName: file.name,
            content: '',
            errorMessage: 'Selecciona un archivo con extensión .json.',
          });
          return;
        }
        if (file.size > Number(maximumBytes)) {
          finish({
            cancelled: false,
            fileName: file.name,
            content: '',
            errorMessage: 'El archivo de respaldo supera 512 KB.',
          });
          return;
        }
        try {
          const content = await file.text();
          finish({
            cancelled: false,
            fileName: file.name,
            content,
            errorMessage: '',
          });
        } catch (error) {
          finish({
            cancelled: false,
            fileName: file.name,
            content: '',
            errorMessage: error instanceof Error
              ? error.message
              : 'No fue posible leer el archivo.',
          });
        }
      }, {once: true});

      window.addEventListener('focus', onFocus);
      input.click();
    });
  }

  globalThis.missionAdmissionBackupFiles = {
    downloadText,
    pickJsonFile,
  };
})();
