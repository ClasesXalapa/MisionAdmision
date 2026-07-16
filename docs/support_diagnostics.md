# Ayuda y diagnóstico

La versión 0.8.1 incorpora una pantalla local para reunir información técnica cuando un usuario encuentra un problema.

## Acceso

Desde Inicio:

```text
Ayuda y diagnóstico
```

También está disponible en la ruta:

```text
/help
```

## Información incluida

- versión y número de compilación;
- navegador y sistema operativo aproximados;
- tamaño de pantalla y área visible;
- idioma y zona horaria;
- estado de conexión y contexto HTTPS;
- instalación de la PWA;
- service worker y modo offline;
- uso y cuota estimada de almacenamiento;
- versiones activas de preguntas, retos, recursos y rangos;
- fecha y resultado de la última sincronización;
- estado general de notificaciones;
- resumen de racha, escudos y existencia de un reto pendiente.

## Información excluida

El reporte no contiene:

- nombre;
- correo;
- teléfono;
- respuestas seleccionadas;
- respuestas correctas del banco;
- token o identificador privado de notificaciones;
- contenido completo del respaldo.

## Acciones

### Copiar reporte

Copia una versión en texto plano para pegarla en un mensaje o formulario de soporte.

### Descargar JSON

Genera un archivo con nombre semejante a:

```text
mision-admision-diagnostico-2026-07-16.json
```

El JSON usa `schema_version: 1` para permitir futuras migraciones.

### Actualizar

Vuelve a consultar el navegador, el almacenamiento, el service worker, las notificaciones y el contenido local. Debe utilizarse inmediatamente después de reproducir un problema.

## Reporte recomendado

```text
Pantalla:
Qué hiciste:
Qué esperabas:
Qué ocurrió:
¿Se repite al recargar?:
Captura o video:
Diagnóstico técnico:
```
