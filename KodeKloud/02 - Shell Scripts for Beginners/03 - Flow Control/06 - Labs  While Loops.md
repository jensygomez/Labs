---
Curso: Shell Scripts for Beginners
Modulo: Flow Control
Tema: Labs --> While Loops
Typo: Laboratorio
Fecha: 2026-05-09
Estado: completado
Dificultad: Intermedio-Baja
Calificación: 0% de  aciertos
Tareas del Lab: "4"
Time: 15 min
tags:
  - Linux/Shell-Scripts-for-Beginners/Flow-Control/Laboratorio
---
**Resumen:**

Este laboratorio de While Loops en Shell Scripting presentó desafíos prácticos para implementar bucles condicionales en bash, una habilidad fundamental para cualquier administrador Linux que necesite automatizar tareas repetitivas. Las tareas variaron desde depuración de scripts existentes con errores de sintaxis hasta la creación de programas más complejos. La dificultad radicó en entender cómo los while loops pueden monitorear estados (como el status de un cohete) y mantener condiciones activas hasta que se cumpla una salida específica. Estos ejercicios refuerzan la importancia de las estructuras de control en la creación de scripts robustos y confiables.

El desafío final de crear un calculadora menu-driven ilustró cómo combinar while loops con condicionales (if/case) para construir programas interactivos. Este tipo de script es común en administración de sistemas para menús de configuración, automatización de tareas repetidas y válvulas de control de procesos. El 0% de aciertos indica oportunidad para profundizar en sintaxis de bash, manejo de entrada de usuario y validación de datos. Revisar estos conceptos es crítico antes de avanzar a scripts más complejos de administración.

**Comandos y estructura de ejemplo:**

bash

```bash
# While Loop básico - Monitorear estado
while [ "$rocket_status" = "launching" ]
do
  echo "Rocket is launching..."
  # Verificar cambio de estado
done

# Calculadora menu-driven con while loop
#!/bin/bash
while true
do
  echo "===== Calculator ====="
  echo "1. Add"
  echo "2. Subtract"
  echo "3. Multiply"
  echo "4. Divide"
  echo "5. Quit"
  read -p "Select option: " choice
  
  if [ $choice -eq 5 ]; then
    break
  fi
  
  read -p "Number1: " num1
  read -p "Number2: " num2
  
  case $choice in
    1) echo "Answer=$((num1 + num2))" ;;
    2) echo "Answer=$((num1 - num2))" ;;
    3) echo "Answer=$((num1 * num2))" ;;
    4) echo "Answer=$((num1 / num2))" ;;
    *) echo "Invalid option" ;;
  esac
done

# Hacer script ejecutable
chmod +x calculator.sh
./calculator.sh
```