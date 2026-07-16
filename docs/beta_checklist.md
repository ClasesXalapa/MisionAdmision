# Lista de preparación para beta pública

## Contenido

- [ ] Sustituir todas las URLs de demostración.
- [ ] Revisar ortografía de preguntas y cards.
- [ ] Confirmar respuestas correctas del banco global.
- [ ] Publicar al menos un reto real con recurso de resolución.
- [ ] Incrementar versiones internas y `content_version`.
- [ ] Ejecutar `python3 tool/validate_content.py`.

## Firebase y notificaciones

- [ ] Crear el proyecto Firebase definitivo.
- [ ] Agregar la aplicación Web.
- [ ] Generar la clave VAPID pública.
- [ ] Completar `web/firebase_config.js`.
- [ ] Probar una notificación en Android, escritorio e iPhone instalado.
- [ ] Confirmar el texto y horario del recordatorio diario.

## PWA y GitHub Pages

- [ ] Publicar desde GitHub Actions.
- [ ] Confirmar HTTPS.
- [ ] Instalar la PWA en Android e iPhone.
- [ ] Abrir la aplicación sin conexión después de la primera carga.
- [ ] Publicar una segunda compilación y probar “Aplicar actualización”.
- [ ] Verificar rutas del repositorio normal y del dominio personalizado.

## Progreso local

- [ ] Completar un reto y recargar la página.
- [ ] Abandonar un reto y reanudarlo el mismo día.
- [ ] Confirmar expiración al cambiar de fecha.
- [ ] Exportar un respaldo.
- [ ] Reiniciar el progreso.
- [ ] Importar el respaldo y verificar racha, escudos y cards.
- [ ] Importar un archivo inválido y confirmar que no cambie el progreso.

## Accesibilidad y dispositivos

- [ ] Chrome Android, 360 px.
- [ ] Safari iPhone, PWA instalada.
- [ ] Chrome y Edge de escritorio.
- [ ] Navegación con teclado.
- [ ] Texto aumentado al 200 %.
- [ ] TalkBack o VoiceOver.

## Privacidad y comunicación

- [ ] Publicar aviso breve de que el progreso es local.
- [ ] Explicar que borrar datos del navegador elimina el avance sin respaldo.
- [ ] Explicar qué recibe Firebase al activar notificaciones.
- [ ] Habilitar un canal para reportar errores de contenido.
