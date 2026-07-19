# Misión Admisión v0.11.3+46 — sistema visual fluido

Esta entrega elimina la simulación de teléfonos de 375, 390 o 430 px y deja de seleccionar tamaños mediante breakpoints asociados a anchos concretos.

## Principio de diseño

La interfaz usa las dimensiones reales de `MediaQuery` en cada reconstrucción:

- tipografía como proporción del ancho visual disponible;
- paddings y separaciones como proporciones del viewport;
- alturas táctiles como proporciones del ancho;
- iconos, badges, radios y barras de progreso derivados de la misma escala;
- ancho completo en orientación vertical;
- límite de lectura únicamente en ventanas apaisadas o de escritorio.

Las cotas mínimas no representan modelos de celular. Son protecciones de accesibilidad para evitar texto ilegible o controles táctiles demasiado pequeños cuando la app se abre en una ventana excepcionalmente estrecha.

## Archivos principales

```text
lib/app/responsive.dart
lib/app/theme.dart
lib/app/app.dart
lib/app/design_system.dart
```

Las pantallas de Inicio, Configuración, Reto, Recursos y Examen consumen el mismo sistema, por lo que ya no necesitan versiones separadas para 360, 540 o 720 px.

## Validación recomendada

Probar al menos:

```text
360 × 800
390 × 844
540 × 1200
720 × 1600
orientación horizontal
escala de texto del sistema aumentada
```

La interfaz debe conservar jerarquía, ancho útil, legibilidad y áreas táctiles sin `RenderFlex overflow`.
