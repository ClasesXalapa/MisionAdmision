# Historial de cambios

## 0.9.6 — 2026-07-16

- Corregida la inscripción fantasma sin `active`, `waiting` ni `installing` dejada por la migración v0.9.5.
- `register()` actualiza directamente el mismo alcance sin desregistrar workers funcionales.
- Recuperación limitada únicamente a inscripciones vacías.
- La espera consulta periódicamente el registro actual para no depender de un objeto obsoleto.
- `index.html` solicita el puente PWA con versión para evitar conservar el script defectuoso en la caché HTTP.
- No cambia Firebase, Analytics, el contenido ni el progreso local.

## 0.9.4 — 2026-07-16

- Corregida la carrera entre el registro de la PWA y la activación de notificaciones.
- El service worker comienza a registrarse al cargar la página, sin esperar `window.load`.
- El cliente de notificaciones reutiliza el puente PWA como única fuente de registro.
- Espera de activación ampliada a 60 segundos con mensajes de error más precisos.
- `register()` crea o actualiza de forma segura el worker del alcance de GitHub Pages.
- Nueva prueba Node para el registro temprano del puente PWA.
- No cambia la configuración Firebase ni el almacenamiento local.

## 0.9.3 — 2026-07-16

- Inicialización opcional y tolerante a fallos de Google Analytics para campañas de Firebase Console.
- Analytics no bloquea el registro FCM si el SDK está bloqueado o no es compatible.
- Diagnóstico de estado de Analytics sin incluir identificadores privados.
- Validación de `measurementId` y configuración separada mediante `analyticsEnabled`.
- Aviso de privacidad actualizado: el progreso y las respuestas permanecen locales.
- Incluye los hotfix de análisis y pruebas con Firebase activado.

## 0.9.1 — 2026-07-16

- Arquitectura cerrada para envíos desde Firebase Console, sin backend propio.
- Eliminadas referencias funcionales a Cloudflare, D1 y snapshots para servidor.
- Copia controlada del Firebase Installation ID para pruebas dirigidas.
- `notificationclick` registrado antes de importar las bibliotecas de Firebase.
- Clic seguro compatible con notificaciones automáticas FCM y mensajes de datos.
- Botones y textos simplificados para usuarios finales.
- Documentación de conexión y operación mediante Firebase Console.

## 0.9.0 — 2026-07-16

- Cliente Web Push auditado contra Firebase JavaScript SDK 12.16.0.
- Registro moderno mediante Firebase Installation ID.
- Deduplificación de solicitudes concurrentes de registro.
- Renovación explícita del registro desde la interfaz.
- Detección de PWA obligatoria en iPhone y iPad.
- Validación de contexto HTTPS y compatibilidad real del SDK.
- Enlaces de notificación limitados al mismo origen y ruta de GitHub Pages.
- Manejo de mensajes de datos y clic seguro en el service worker.
- Aviso de renovación ante `pushsubscriptionchange`.
- Diagnóstico ampliado sin revelar el FID.
- Pruebas Node del ciclo FID y del service worker FCM.

## 0.8.1 — 2026-07-16

- Nueva pantalla de ayuda y diagnóstico.
- Versión, navegador, sistema y tamaño de pantalla visibles.
- Estado de conexión, HTTPS, PWA, service worker y modo offline.
- Estimación de uso y cuota de almacenamiento del navegador.
- Versiones activas de preguntas, retos, recursos y rangos.
- Estado general de notificaciones sin exponer el registro privado.
- Resumen local de racha, escudos y reto pendiente sin incluir respuestas.
- Copia del reporte técnico al portapapeles.
- Descarga del diagnóstico como JSON versionado.
- Plantilla integrada para reportar errores.
- Puente JavaScript de diagnóstico y pruebas automatizadas.

## 0.8.0 — 2026-07-16

- Plantilla editable con el contenido demostrativo completo.
- Administración de preguntas, retos, cards, rangos y versiones mediante Excel o Google Sheets.
- Cinco CSV UTF-8 de ejemplo compatibles con el generador.
- Generador Python sin dependencias externas.
- Validación conjunta antes de reemplazar cualquier JSON.
- Publicación mediante archivos temporales y restauración ante fallos de escritura.
- Detección de encabezados incorrectos, valores activos inválidos y referencias rotas.
- Modo `--check-only` para validar sin modificar contenido.
- Apps Script opcional con validación y exportación a una estructura `content/` en Drive.
- Pruebas automatizadas del generador y verificación en GitHub Actions.

## 0.7.2 — 2026-07-16

- Corregida la prueba de la pantalla inicial para desplazarse por el `ListView` antes de buscar acciones fuera del viewport de pruebas.
- Aislada la sincronización remota durante el widget test para evitar solicitudes HTTP reales.
- Sin cambios en la aplicación, el almacenamiento local ni los contratos JSON.

## 0.7.1 — 2026-07-16

- Eliminada una variable de excepción no utilizada en la sincronización de contenido.
- Migrado `DropdownButtonFormField.value` a `initialValue` para Flutter 3.44.
- Corregido el paso `flutter analyze` de GitHub Actions sin silenciar diagnósticos.
- Sin cambios en los datos locales ni en los contratos JSON.

## 0.7.0 — 2026-07-15

- Exportación del progreso a un archivo JSON versionado.
- Importación con validación estricta y confirmación previa.
- Restauración del reto pendiente únicamente durante la fecha vigente.
- Descarte seguro de intentos vencidos y rechazo de intentos futuros.
- Rollback de datos cuando una escritura local falla.
- Reinicio selectivo del progreso sin borrar contenido ni notificaciones.
- Puente Web para descarga y selección de archivos sin dependencias nuevas.
- Pantalla de datos y respaldo accesible desde el inicio.
- Tema de alto contraste y mejoras de semántica y tamaño táctil.
- Ruta de error para direcciones desconocidas.
- Lista de preparación para beta pública.

## 0.6.0 — 2026-07-15

- Integración opcional con Firebase Cloud Messaging para Web.
- Un único service worker para caché offline y notificaciones en segundo plano.
- Configuración pública desacoplada en `web/firebase_config.js`.
- Solicitud de permiso iniciada únicamente por acción del alumno.
- Registro FCM con clave VAPID y service worker existente.
- Recepción de mensajes en primer y segundo plano.
- Prueba local de notificación desde la pantalla de inicio.
- Desactivación y eliminación del registro del navegador.
- Estados para configuración ausente, navegador incompatible y permiso bloqueado.
- Guía completa para configurar Firebase y enviar mensajes de prueba.
- Pruebas para el controlador de notificaciones.

## 0.5.0 — 2026-07-15

- Service worker propio para Flutter Web 3.44.
- Cachés separadas para aplicación, contenido y recursos de ejecución.
- Versión de caché derivada del contenido real de cada compilación.
- Fallback de navegación a la aplicación guardada y página offline mínima.
- Estrategias network-first para navegación y JSON.
- Estrategia cache-first para archivos versionados de la aplicación.
- Puente JavaScript encapsulado mediante `dart:js_interop` y imports condicionales.
- Detección de conexión, instalación y estado del service worker.
- Botón de instalación cuando el navegador expone `beforeinstallprompt`.
- Instrucciones manuales para iPhone y iPad.
- Detección y activación explícita de versiones nuevas.
- Atajos instalables para reto, recursos y examen.
- Herramienta Python para generar el service worker después del build.
- Pruebas para controlador PWA y generador de caché.

## 0.4.0 — 2026-07-15

- Sincronización remota desde `content/index.json`.
- Descarga selectiva según versión.
- Caché local versionada de última copia válida.
- Validación completa antes de activar contenido remoto.
- Activación coordinada mediante un único cambio de metadatos.
- Protección de retos y del intento diario vigente ante bancos incompatibles.
- Revisión automática limitada a una vez cada 30 minutos.
- Actualización manual y estados visuales de sincronización.

## 0.3.0 — 2026-07-15

- Escudos obtenidos cada 7 días de racha, con máximo de 3.
- Consumo automático de uno o varios escudos por días omitidos.
- Aviso cuando un escudo protege la racha.
- Migración compatible del progreso guardado en 0.2.0.
- Rangos configurables mediante `rangos.json`.
- Rango permanente calculado a partir de la mejor racha.
- Biblioteca de recursos mediante cards JSON.
- Filtros por tipo y etiqueta.
- Apertura segura de enlaces HTTPS externos.
- Seguimiento local de cards vistas y completadas.
- Validación de cards, rangos e índice de contenido.
- Pruebas para escudos, rangos, cards y persistencia.

## 0.2.0 — 2026-07-15

- Reto diario programado desde JSON.
- Reto automático estable para fechas sin programación.
- Persistencia local del intento y progreso.
- Reanudación durante la misma fecha local.
- Expiración segura al cruzar medianoche.
- Racha actual, mejor racha y total completado.
- Recurso externo de resolución.
- Validación cruzada de IDs entre retos y preguntas.
- Pruebas para fechas, persistencia, racha, motor diario y controlador.

## 0.1.0 — 2026-07-14

- Proyecto Flutter Web inicial.
- Banco global de preguntas.
- Validador de contenido.
- Examen libre de 10 preguntas.
- Pantalla de resultado.
- GitHub Pages y pruebas básicas.
