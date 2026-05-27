---
Curso: Shell Scripts for Beginners
Modulo: Flow Control
Tema: "Lab: Conditional Logic"
Typo: Laboratorio
Fecha: 03/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación: 0%
Time: 15 min
tags:
---
## Resumen

Este laboratorio se enfoca en dominar las **estructuras condicionales (if/else/elif)** en Bash, piedra angular para escribir scripts que tomen decisiones basadas en condiciones. A través de cuatro ejercicios progresivos, aprendimos a validar estados de procesos, verificar existencia de directorios, comparar valores numéricos y usar case statements para mapear entrada con salida. La capacidad de escribir condicionales robustos es esencial para escribir scripts de administración de sistemas que manejen errores y flujos diferentes automáticamente.

Las técnicas practicadas aquí (validación de argumentos, manejo de errores, conversión de entrada) son fundamentales cuando escribes scripts para troubleshooting en producción, monitoreo de servicios o automatización de tareas repetitivas en un entorno NOC/Sysadmin. El uso de `[[ ]]` en lugar de `[ ]` proporciona mayor flexibilidad y es la práctica recomendada en scripts modernos.

## Comandos de Ejemplo

bash

```bash
# Validar estado de variable
if [[ $rocket_status == "failed" ]]; then
  rocket-debug
fi

# Validar existencia de directorio
if [[ -d /home/bob/caleston ]]; then
  echo "Directory exists"
else
  echo "Directory not found"
fi

# Comparar números
if [[ $1 -gt $2 ]]; then
  echo "$1 is greater"
else
  echo "$2 is greater"
fi

# Case statement para mes (Q4)
case $1 in
  1) echo "January" ;;
  2) echo "May" ;;
  3) echo "December" ;;
  *) echo "Invalid month number given" ;;
esac
```