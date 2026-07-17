{{flutter_js}}
{{flutter_build_config}}

// Misión Admisión administra un único service worker propio para PWA y FCM.
// El build se genera con --pwa-strategy=none, por lo que Flutter no registra
// flutter_service_worker.js ni compite por el mismo alcance.
_flutter.loader.load();
