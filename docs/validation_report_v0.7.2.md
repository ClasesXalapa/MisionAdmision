# Reporte de validación — Misión Admisión v0.7.2

**Fecha:** 2026-07-16

## Corrección

La prueba `test/widget_test.dart` esperaba encontrar el botón **Iniciar examen** inmediatamente después de montar la pantalla. En el viewport predeterminado de Flutter Test, ese botón está fuera del área visible de un `ListView` y todavía no se construye.

La prueba ahora:

1. monta la aplicación con almacenamiento en memoria;
2. reemplaza la red por un cliente offline determinista;
3. verifica el título inicial;
4. desplaza el listado hasta **Hacer reto de hoy**;
5. desplaza el listado hasta **Iniciar examen**;
6. comprueba ambos botones después de que hayan sido construidos.

## Versionado

- Aplicación: `0.7.2`
- Compilación: `9`
- Contratos JSON: sin cambios
- Migración de datos: no requerida

## Alcance

La corrección modifica únicamente la prueba de widgets y el versionado. No cambia la interfaz, la persistencia, la racha, los escudos, el contenido ni las notificaciones.
