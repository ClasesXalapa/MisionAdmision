# Misión Admisión — Contexto v4.0 Web-first

**Fecha:** 14 de julio de 2026  
**Estado:** primer bloque funcional preparado.  
**Documento anterior:** v3.0.

Este documento conserva las decisiones funcionales de la versión 3.0 y modifica la plataforma de lanzamiento. Cuando exista un conflicto, las decisiones de este documento tienen prioridad.

## Decisión principal

La primera versión de Misión Admisión será una PWA desarrollada con Flutter Web y publicada en GitHub Pages. La aplicación Android se evaluará después de validar el producto con usuarios reales.

## Arquitectura inicial

```text
Flutter Web / PWA
    ↓
GitHub Pages
    ├── aplicación compilada
    ├── content/index.json
    └── content/preguntas/banco_global.json
    ↓
Navegador
    └── almacenamiento local en etapas posteriores
```

## Stack del MVP web

- Flutter 3.44.6.
- Dart 3.10 o posterior.
- Riverpod para dependencias y estado escalable.
- go_router para navegación.
- GitHub Actions para pruebas y despliegue.
- GitHub Pages para alojamiento.
- Firebase Cloud Messaging en una fase posterior para el recordatorio diario.

## Primer bloque entregado

- Estructura por capas.
- Tema claro y navegación.
- Contrato JSON del banco global.
- DTO y validador de preguntas.
- Modelos de dominio.
- Motor puro de exámenes.
- Examen libre de 10 preguntas.
- Resultado simple.
- Banco de 20 preguntas de demostración.
- Pruebas unitarias y de widget.
- Validación de contenido sin dependencias externas.
- Despliegue automático en GitHub Pages.

## Próxima etapa

Implementar persistencia local para guardar configuración, intentos y progreso; después construir el reto diario programado y su fallback automático.

## Reglas que continúan vigentes

- Sin cuentas de alumno.
- Sin Firestore ni backend propio para el núcleo.
- Progreso local.
- JSON como fuente de contenido.
- Preguntas de opción múltiple, cuatro opciones y sin explicación.
- Reto diario programado o automático.
- Racha por completar, no por calificación.
- Máximo tres escudos.
- Tema claro único.
- Videos y documentos externos representados como cards.
