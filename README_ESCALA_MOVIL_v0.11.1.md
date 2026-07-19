# Ajuste de escala móvil real — v0.11.1+42

> **Hotfix vigente:** `v0.11.1+44` conserva la corrección del encabezado y garantiza que las dos acciones de Inicio se construyan también fuera del viewport inicial, sin cambiar la escala visual.

Esta entrega corrige el problema observado en las capturas reales del teléfono:
el rediseño v0.11.0 tenía una composición moderna, pero Android PWA reportaba un
viewport de 720 px y hacía que texto, botones, cards e iconos se vieran demasiado
pequeños.

## Cambio principal

`HandsetViewport` normaliza viewports móviles altos de 560–1000 px a una
superficie lógica de 430 px. A diferencia del ajuste anterior, ahora se escalan
de forma coordinada:

- tipografía;
- iconos;
- paddings y separaciones;
- cards;
- botones y áreas táctiles;
- barra inferior;
- modales y hojas inferiores.

No se aplica a escritorio ni a viewports móviles que ya reportan un ancho lógico
normal.

## Ajustes complementarios

- Tipografía base y botones ligeramente mayores.
- Navegación inferior más alta y legible.
- Opciones de respuesta con mayor altura táctil.
- La card de la pregunta siempre ocupa todo el ancho disponible.
- Recursos recupera una acción secundaria con texto completo para marcar un
  elemento como completado.
- `viewport-fit=cover` e `interactive-widget=resizes-content` en la PWA.

## Validación visual esperada en el teléfono de las capturas

- En Inicio, el contenido principal debe ocupar casi toda la primera pantalla y
  requerir desplazamiento para ver las acciones inferiores.
- En Recursos ya no deben caber seis cards completas en una sola pantalla.
- En Reto y Examen, pregunta y opciones deben verse claramente mayores.
- La pregunta corta del Examen debe ocupar todo el ancho, no una card estrecha
  centrada.
- La barra inferior debe ser claramente táctil y legible.
