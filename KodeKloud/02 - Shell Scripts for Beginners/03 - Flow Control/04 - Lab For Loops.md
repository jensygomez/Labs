---
Curso: Shell Scripts for Beginners
Modulo: Flow Control
Tema: "Lab: For Loops"
Typo: Laboratorio
Fecha: 03/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación: 20 %
Time: 20 min
tags:
  - Linux
  - Linux/Shell-Scripts-for-Beginners
  - Linux/Shell-Scripts-for-Beginners/Flow-Control
  - Linux/Shell-Scripts-for-Beginners/Flow-Control/Laboratorio
---
## Resumen

Los bucles **for** son una herramienta fundamental en bash para iterar sobre colecciones de datos (listas, archivos, directorios). En este laboratorio se practicó la creación de scripts que utilizan for loops para automatizar tareas repetitivas. Se logró completar exitosamente el primer ejercicio que consistía en desarrollar un script con un bucle for básico que llamara a otra función múltiples veces con diferentes parámetros. Los ejercicios subsecuentes involucraban lecturas desde archivos, procesamiento de logs con patrones de búsqueda, manipulación de nombres de archivos y formateo tabulado de salida.

La práctica refuerza conceptos clave como la iteración sobre listas explícitas, la lectura de archivos línea por línea, el uso de condicionales dentro de bucles y la manipulación de cadenas de texto. Estos patrones son esenciales para cualquier administrador Linux que necesite automatizar tareas del sistema, especialmente cuando se trata de procesamiento en lote de múltiples recursos o generación de reportes formateados.

## Ejemplo de Comando

bash

```bash
#!/bin/bash
# Script básico con for loop

for mission in lunar-mission mars-mission jupiter-mission saturn-mission mercury-mission; do
    create-and-launch-rocket "$mission"
done
```