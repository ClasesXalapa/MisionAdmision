# Changelog

## 0.10.13+39 — 19 de julio de 2026

- Recursos fuerza siempre la composición móvil grande, sin depender de breakpoints o de la plataforma reportada por el navegador.
- Los filtros por tipo ocupan una fila completa y tienen controles táctiles de 150 px.
- Búsqueda, selector, cards, títulos, descripciones y botones aumentan nuevamente de escala.
- Las cards de recursos tienen un contenido mínimo de 920 px y acciones de hasta 142 px.
- Se añade `build_guard.js` para limpiar únicamente la caché del código al cambiar de versión y recargar una vez antes de iniciar Flutter.

## 0.10.12+38 — 2026-07-19

### Recursos: escala móvil grande real

- La sección Recursos ya no depende únicamente de la detección de plataforma: activa la composición grande en cualquier viewport de hasta 960 px.
- Título, descripción, buscador y selector de materia aumentados de forma considerable.
- Los tipos de recurso se muestran en una cuadrícula táctil de dos columnas en lugar de chips horizontales pequeños.
- Las cards usan iconos, títulos, descripciones, etiquetas y acciones mucho más grandes.
- Cada recurso ocupa una sección vertical amplia y el desplazamiento largo es parte normal de la experiencia.
- Se conserva intacta la lógica de búsqueda, filtrado, apertura y seguimiento local.

## 0.10.11+37 — 2026-07-18

- La pantalla de Recursos adopta la misma escala grande y desplazable de Inicio.
- La cabecera, descripción, buscador, filtros y selector de materia aumentan su tamaño y altura táctil.
- Cada card de recurso usa una altura mínima amplia, icono de 118 px, título de 42 px y descripción completa de 30 px.
- Las acciones para abrir y completar recursos crecen a 106 px y 98 px, respectivamente.
- Las imágenes de portada usan una proporción 4:3 en celulares para aprovechar mejor la pantalla.
- Se conservan sin cambios la búsqueda, los filtros, la apertura externa y el seguimiento local.

## 0.10.10+36 — 2026-07-18

- El modal de configuración ahora ocupa todo el ancho del celular y el 94 % de la altura útil.
- Cabecera, botón de cierre, textos, iconos y tarjetas usan la misma escala amplia de Inicio.
- Instalación, notificaciones y contenido se presentan en cards verticales con acciones táctiles grandes.
- Las herramientas técnicas permanecen plegadas, pero sus botones ya son cómodos en celular.
- La actualización de contenido deja de depender de un botón circular pequeño y usa una acción de ancho completo.

## 0.10.9+35 — 2026-07-18

- Inicio deja de intentar caber en una sola vista y adopta una escala móvil deliberadamente grande.
- Se duplicó aproximadamente la altura útil de progreso, reto diario, accesos principales y navegación inferior.
- Los textos principales usan líneas más estrechas para permitir tipografías grandes y lectura cómoda.
- Mejor racha, escudos y retos permanecen en filas completas de gran altura.
- Biblioteca de recursos y Examen libre usan cards verticales de al menos 500 px lógicos.
- La PWA actualiza JavaScript con estrategia network-first para evitar conservar una interfaz anterior.
- Se añadió `pwa_bridge_bootstrap.js` para migrar instalaciones atrapadas en una caché antigua y recargar al cambiar el controlador.

## 0.10.8+34 — 2026-07-18

- La pantalla de Inicio deja de intentar concentrar todo el contenido en una sola vista y adopta desplazamiento vertical como comportamiento normal.
- Se amplían la cabecera, la tarjeta de progreso, la racha principal, el reto diario, Biblioteca de recursos y Examen libre.
- Mejor racha, escudos y retos completados pasan de tres columnas comprimidas a tres filas completas y legibles.
- Las cards de Biblioteca y Examen aumentan a una altura mínima de 236 px, con iconos, títulos, descripciones y flechas mayores.
- La barra inferior aumenta su altura, iconos y etiquetas para mejorar el uso táctil en celulares.
- La prueba de Inicio verifica que exista desplazamiento vertical, que las acciones mantengan ancho completo y que no haya desbordamientos.

## 0.10.7+33 — 2026-07-18

### Hotfix de versiones de prueba para sincronización

- Los tres escenarios que simulan una actualización del banco de preguntas dejan de fijar `questions_002`.
- La versión remota de prueba ahora se calcula a partir de la versión actual (`questions_002` → `questions_003`).
- Se evita que el servicio omita la descarga por considerar que la versión simulada ya estaba almacenada.
- La corrección cubre intento pendiente, intento vencido y retos existentes con referencias protegidas.
- Se coordinan la versión de la aplicación y la revisión del service worker en el build 33.

## 0.10.7+32 — 2026-07-18

### Hotfix de sincronización de contenido en pruebas

- Las pruebas de `ContentSyncService` dejan de usar el build fijo 4 y toman `AppConstants.appBuildNumber`.
- El fixture de sincronización vuelve a ser compatible con `min_app_version: 31` y con futuras actualizaciones del build.
- Se conserva `min_app_version: 31` porque ese es el primer build que entiende el esquema 2 de preguntas.
- Se coordinan la versión de la aplicación y la revisión del service worker en el build 32.

## 0.10.7+31 — 2026-07-17

### Reto y examen optimizados para celular e imágenes en reactivos

- Reto diario y Examen libre usan casi todo el ancho del teléfono, con cabeceras, progreso, preguntas, incisos y controles inferiores de mayor tamaño.
- La pregunta se separa de los incisos para mejorar la jerarquía visual y cada respuesta tiene un área táctil mínima de 108 px.
- Los botones Anterior, Siguiente y Finalizar crecen a 74 px y permanecen fijos sobre el área segura.
- Las imágenes principales se muestran a gran tamaño y pueden ampliarse con zoom.
- Cada inciso admite texto, imagen o ambos mediante `imagenes_opciones`.
- El banco de preguntas pasa al esquema 2; la aplicación mantiene compatibilidad de lectura con bancos de esquema 1.
- Excel, Google Sheets, CSV, generadores, validadores y documentación administrativa incorporan una URL de imagen independiente para A, B, C y D.

## 0.10.6+30 — 2026-07-17

### Biblioteca de recursos optimizada para celulares

- La pantalla usa 12 px de margen lateral y aprovecha mejor el ancho útil del teléfono.
- La cabecera, búsqueda, filtros y contador aumentan su tamaño y jerarquía visual.
- Los tipos de recurso se muestran como controles táctiles de 54 px con estado seleccionado de alto contraste.
- Las cards amplían iconos, títulos, descripciones, etiquetas y separación interna.
- Cada tipo utiliza una acción principal contextual: ver video, abrir PDF, abrir formulario, abrir simulacro, leer publicación o ver anuncio.
- El estado de finalización se convierte en una acción secundaria amplia y claramente diferenciada.
- Se conservan búsqueda, filtros, seguimiento de visto/completado y apertura externa sin cambiar su lógica.

## 0.10.5+29 — 2026-07-17

### Accesos principales de Inicio ampliados

- Biblioteca de recursos y Examen libre aumentan su altura mínima de 148 a 188 px.
- Los iconos pasan a contenedores de 94 px con símbolos de 54 px.
- Títulos y descripciones usan una escala mayor para lectura cómoda en celular.
- Se amplían padding, separación interna y distancia entre ambas cards.
- La flecha de navegación se convierte en un control circular más visible.
- Toda la superficie de cada card continúa siendo pulsable.

## 0.10.4+28 — 2026-07-17

### Hotfix de prueba y navegación inferior

- Corrige un desbordamiento vertical de la opción seleccionada en la navegación inferior al aplicar la escala tipográfica móvil de 1.24.
- Aumenta ligeramente la altura disponible de la barra y reduce su padding interno para conservar iconos y etiquetas grandes.
- Las cards de Biblioteca y Examen eliminan el margen implícito de `Card` y ocupan realmente todo el ancho útil de Inicio.
- La prueba de Inicio valida el ancho proporcional al viewport en lugar de depender de un valor absoluto frágil.
- La prueba comprueba explícitamente que no existan excepciones de renderizado.

## 0.10.4+27 — 2026-07-17

### Inicio ampliado para celulares

- Se aprovecha mejor la altura disponible sin agregar funciones ni contenido artificial.
- La cabecera, el progreso, la misión diaria y las acciones rápidas usan una escala visual mayor.
- La tarjeta de progreso aumenta el protagonismo de la racha y la legibilidad de las métricas secundarias.
- El reto diario incorpora más espacio, texto mayor, progreso más visible y un botón principal de 78 px.
- Biblioteca y Examen pasan a cards de 148 px con iconos, títulos y descripciones más grandes.
- La navegación inferior aumenta iconos, etiquetas, altura y área táctil.
- La estructura permanece preparada para añadir futuras funciones como nuevas cards.

## 0.10.3+26 — 2026-07-17

### Inicio móvil refinado

- La racha actual pasa a ser la métrica principal de la tarjeta de progreso.
- Mejor racha, escudos y retos se muestran como indicadores secundarios más limpios.
- El mensaje inferior del progreso indica la siguiente acción del alumno.
- La tarjeta del reto usa una sola acción sólida y muestra progreso solo cuando existe un intento pendiente.
- Biblioteca y Examen eliminan enlaces pequeños; toda la tarjeta es pulsable.
- La barra inferior resalta icono y etiqueta dentro de un único indicador amplio.
- La iteración se limita a Inicio y navegación inferior; no modifica las demás pantallas.

## 0.10.2+25 — 2026-07-17

- Rediseñada únicamente la pantalla de Inicio para aprovechar casi todo el ancho del celular.
- Reducidos los márgenes laterales de Inicio a 8 px lógicos.
- Aumentados títulos, descripciones, métricas, botones e iconos de Inicio.
- Biblioteca de recursos y Examen libre ahora siempre ocupan una fila completa cada uno.
- Sustituida la barra inferior Material 3 por una navegación móvil personalizada con iconos y etiquetas más grandes.
- Añadida una prueba de widget que verifica que las dos acciones rápidas estén apiladas y ocupen todo el ancho en un viewport móvil de 720 px.

## 0.10.1+24 — 2026-07-17

- Corrige la prueba de la pantalla inicial con un viewport móvil determinista.
- Sustituye expectativas de texto dinámico por claves estables de interfaz.
- Elimina la altura rígida de las métricas de progreso para evitar desbordamientos con escalado de texto.
- Actualiza la revisión del service worker a 24.

## 0.10.1 — 2026-07-17

### Interfaz móvil corregida

- La detección móvil ya no depende únicamente de un breakpoint de 600 px.
- Se corrigen teléfonos Android/PWA que reportan un ancho lógico amplio y activaban composiciones de tableta.
- Se fuerza el ancho útil completo en Inicio, Reto, Examen y Recursos.
- Se incorpora una escala tipográfica móvil adaptativa sin reducir las preferencias de accesibilidad.
- Inicio usa métricas 2×2 y accesos secundarios en una sola columna.
- Se amplían tipografía, botones, iconos, navegación y áreas táctiles.
- La hoja de configuración adopta altura según contenido y oculta las herramientas técnicas hasta que el usuario las despliega.
- Las cards de recursos eliminan portadas genéricas vacías y priorizan título, descripción y acciones.
- Preguntas y respuestas ocupan más ancho y tienen controles inferiores más amplios.

# Historial de cambios

## 0.10.0 — 2026-07-17

- Rediseño mobile-first de la pantalla principal con jerarquía visual más clara.
- Nueva navegación inferior para Inicio, Reto, Recursos y Examen.
- Progreso reorganizado en una cuadrícula 2 × 2 con indicadores diferenciados.
- El reto diario se convierte en la acción principal y muestra el avance pendiente.
- Controles técnicos de PWA, notificaciones y contenido movidos a una hoja de configuración.
- Reto y examen con progreso legible, respuestas táctiles y acciones fijas en la parte inferior.
- Confirmación al salir de actividades para evitar pérdidas accidentales.
- Biblioteca de recursos con búsqueda, filtros horizontales, estados visibles y cards renovadas.
- Resultados con porcentaje y resumen visual de respuestas.
- Paleta, contraste, superficies, tipografía y áreas táctiles reforzados para celulares.

## 0.9.8 — 2026-07-16

- Cada mensaje de Firebase funciona como señal genérica para comprobar el reto diario local.
- IndexedDB comparte únicamente la fecha del último reto completado con el service worker.
- Recordatorio local adicional cuando el reto sigue pendiente.
- Sin límite diario: varias campañas Firebase pueden generar varios recordatorios.
- Cierre automático de los recordatorios locales al completar el reto.
- Comportamiento conservador ante estado ausente, contenido no disponible o errores de almacenamiento.
- Diagnóstico con última recepción Firebase, última decisión y conteo de avisos locales.
- Pruebas para múltiples recordatorios, reto completado, estado no inicializado y enlaces seguros.

## 0.9.7 — 2026-07-16

- Eliminada la competencia entre el service worker generado por Flutter y `app_service_worker.js`.
- El build Web usa `--pwa-strategy=none` y retira `flutter_service_worker.js` del artefacto de Pages.
- Añadido un `flutter_bootstrap.js` propio que inicia Flutter sin registrar un segundo service worker.
- El service worker propio usa una URL versionada para forzar una actualización limpia del registro.
- Recuperación reforzada de inscripciones vacías heredadas de las versiones 0.9.5 y 0.9.6.
- La precarga tolera fallos en recursos opcionales y conserva como obligatorios los archivos esenciales.
- No se modifica la configuración Firebase, Analytics, el contenido ni el progreso local.

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
