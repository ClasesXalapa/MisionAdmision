# Respaldo e importación del progreso

Misión Admisión no utiliza cuentas. El progreso pertenece al navegador y dispositivo donde se creó. La versión 0.7.0 permite descargar un respaldo y restaurarlo posteriormente.

## Datos incluidos

- racha actual y mejor racha;
- escudos;
- fechas necesarias para reconciliar la racha;
- total de retos diarios completados;
- reto diario pendiente, si existe;
- recursos vistos y completados.

## Datos excluidos

- tokens o permisos de notificaciones;
- identificador de instalación de Firebase;
- caché de la PWA;
- copias del banco de preguntas, cards, retos o rangos;
- nombre, correo u otros datos personales.

## Formato

El archivo usa JSON y declara:

```json
{
  "format": "mision_admision_progress_backup",
  "schema_version": 1,
  "app_version": "0.7.0",
  "exported_at": "2026-07-15T20:00:00-06:00",
  "data": {}
}
```

El importador limita los archivos a 512 KB, valida todas las estructuras y rechaza fechas futuras, valores negativos, IDs duplicados y formatos incompatibles.

## Reglas de restauración

- El progreso y las marcas de recursos se reemplazan después de una confirmación explícita.
- Un reto pendiente solo se restaura si pertenece a la fecha local actual.
- Un reto vencido se descarta sin impedir la restauración del resto del progreso.
- Un reto con una fecha futura provoca el rechazo del archivo.
- Si falla una escritura, el servicio intenta restaurar el estado anterior.

## Reinicio local

La opción **Borrar progreso local** elimina únicamente avance, reto pendiente y seguimiento de recursos. No elimina el contenido educativo, el service worker ni la configuración de notificaciones.
