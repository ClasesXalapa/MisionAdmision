# Hotfix v0.11.1+44

Este hotfix corrige la prueba de widgets `muestra la pantalla inicial`.

## Causa

Inicio utilizaba un `ListView`. Aunque la lista de widgets se declaraba completa, Flutter solo montaba los hijos próximos al viewport. Con la normalización móvil a 430 px, la sección final podía quedar fuera del área inicial y la key `home_exam_action` todavía no existía en el árbol de elementos durante la prueba.

## Corrección

La pantalla de Inicio, cuyo contenido es corto y fijo, ahora utiliza:

```dart
SingleChildScrollView(
  physics: const AlwaysScrollableScrollPhysics(),
  child: Column(...),
)
```

Esto conserva el desplazamiento y `RefreshIndicator`, pero construye las acciones de Recursos y Examen desde el primer frame. No se modificaron las keys ni se relajó la prueba.
