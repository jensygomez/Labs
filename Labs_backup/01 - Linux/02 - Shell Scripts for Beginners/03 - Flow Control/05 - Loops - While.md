---
Curso: Shell Scripts for Beginners
Modulo: Flow Control
Tema: "Lab: For Loops"
Typo: Video
Fecha: 04/05/2026
Estado: completado
Dificultad:
Calificación:
Time: 10 min
tags:
---

## Resumen

El `while statement` es una estructura de control que garantiza la ejecución repetida de un bloque de código mientras una condición sea verdadera. Su construcción es similar al `for statement`, pero con la ventaja de ser más flexible para casos donde no conoces el número exacto de iteraciones. Es especialmente útil para crear menús interactivos, bucles infinitos controlados y procesos que dependen de condiciones dinámicas.

El uso de palabras clave como `break` y `continue` es fundamental para controlar el flujo del bucle. `break` permite salir completamente del `while`, mientras que `continue` salta a la siguiente iteración sin ejecutar el resto del código del ciclo actual. Esta combinación es perfecta para crear menús robustos donde el usuario puede intentar múltiples opciones hasta seleccionar una válida.

## Ejemplo de comando

```bash
#!/bin/bash

# Menú interactivo con while
while true; do
  echo "=== MENÚ PRINCIPAL ==="
  echo "1) Opción 1"
  echo "2) Opción 2"
  echo "3) Salir"
  read -p "Selecciona una opción: " opcion
  
  case $opcion in
    1) echo "Has seleccionado opción 1" ;;
    2) echo "Has seleccionado opción 2" ;;
    3) echo "Saliendo..."; break ;;
    *) echo "Opción no válida"; continue ;;
  esac
done
```