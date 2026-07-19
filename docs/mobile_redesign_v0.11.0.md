# Rediseño móvil v0.11.0

## Objetivo

Transformar Misión Admisión en una experiencia móvil más profesional, juvenil y eficiente sin modificar la lógica de dominio, el almacenamiento local, los contratos JSON, la sincronización, Firebase o la PWA.

## Identidad visual

- Primario índigo: `#5B4BDB`.
- Violeta de apoyo: `#8B5CF6`.
- Turquesa para aprendizaje y recursos: `#12A594`.
- Ámbar para racha y logros: `#FFB648`.
- Fondo general: `#F5F6FC`.
- Superficies blancas, bordes suaves y sombras discretas.

Los tokens se concentran en `lib/app/design_system.dart` y el tema global en `lib/app/theme.dart`.

## Cambios por pantalla

### Inicio

- Hero de misión con rango, racha y estado del día.
- Tres métricas compactas en una sola fila.
- Reto diario destacado con gradiente y progreso.
- Biblioteca y Examen como accesos rápidos de alta densidad.

### Recursos

- Hero compacto.
- Búsqueda visible sin ocupar una pantalla completa.
- Tipos en una fila horizontal desplazable.
- Materia en selector compacto.
- Cards con identidad por tipo, descripción limitada, etiquetas y acciones claras.

### Reto y Examen

- Progreso más legible.
- Pregunta contenida en una superficie limpia.
- Opciones compactas con selección visual fuerte.
- Barra inferior reducida y consistente.
- Resultados con cabecera de gradiente.

### Navegación y configuración

- Barra inferior de 82 px en lugar de 186 px.
- Indicador seleccionado tipo píldora.
- Modal y tarjetas de configuración con densidad equilibrada.

## Compatibilidad preservada

No se modificaron:

- rutas públicas;
- providers y controllers;
- progreso, racha, escudos o rangos;
- contenido y esquemas JSON;
- sincronización local-first;
- service worker único;
- Firebase Cloud Messaging;
- claves de almacenamiento local.
