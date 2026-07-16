# Misión Admisión — Contexto v10.0

**Versión técnica:** 0.7.0  
**Plataforma actual:** Flutter Web / PWA en GitHub Pages  
**Estado:** núcleo funcional listo para pruebas de beta controlada.

## Funciones acumuladas

- examen libre;
- reto diario programado y automático;
- reanudación del intento;
- racha, escudos y rangos;
- cards con filtros y seguimiento;
- sincronización remota con última copia válida;
- instalación y funcionamiento offline;
- integración opcional con Firebase Cloud Messaging;
- exportación, importación y reinicio del progreso;
- base de accesibilidad y documentos para beta.

## Decisiones del respaldo

El respaldo contiene solamente datos de progreso. No contiene caché, contenido educativo ni credenciales de notificaciones. Los archivos usan un contrato versionado, se limitan a 512 KB y se validan completamente antes de escribir.

Un intento diario solo se restaura si corresponde al día local actual. Los intentos vencidos se descartan y los intentos futuros se rechazan.

## Próximo bloque recomendado

1. Ejecutar compilación y pruebas reales con Flutter mediante GitHub Actions.
2. Sustituir contenido demostrativo por contenido real.
3. Configurar el proyecto Firebase definitivo.
4. Realizar una beta cerrada con varios teléfonos y navegadores.
5. Corregir problemas de experiencia, accesibilidad y rendimiento detectados.
