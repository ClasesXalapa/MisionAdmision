# Misión Admisión — Contexto técnico v11

**Versión:** 0.8.0  
**Estado:** administrador de contenido terminado.

## Cambio principal

El contenido ya no necesita editarse directamente en JSON. La versión incluye una plantilla de Excel/Google Sheets, cinco CSV de ejemplo, un generador seguro y un Apps Script opcional.

## Flujo editorial recomendado

```text
Plantilla Excel / Google Sheets
→ exportar cinco CSV UTF-8
→ validar con --check-only
→ generar JSON
→ revisión de Git
→ GitHub Actions
→ GitHub Pages
```

## Garantía de seguridad

Los cinco documentos se construyen y validan juntos antes de reemplazar el contenido. Una entrada inválida no modifica los JSON existentes.

## Estado de módulos

- Aplicación web, exámenes, retos, racha, escudos y cards: terminados.
- PWA, modo offline, sincronización y respaldo: terminados.
- Administrador de contenido: terminado en 0.8.0.
- Diagnóstico para soporte: siguiente entrega.
- Firebase real y envío diario: pendientes de entregas posteriores y configuración externa.
