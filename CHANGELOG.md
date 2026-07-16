# Historial de cambios

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
