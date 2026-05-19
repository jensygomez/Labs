---
Curso: Shell Scripts for Beginners
Modulo: Shebang
Tema: "Lab: Exit Codes"
Fecha: 2026-05-11
tags:
  - Linux
  - Linux/Shebang
  - Linux/Shebang/Exit-Codes
  - Linux/Shebang/Exit-Codes/Laboratorio
  - Linux/Shebang/Exit-Codes/Laboratorio/Dificultad/Basico-Medio
  - Linux/Shebang/Exit-Codes/Laboratorio/Time/5min
  - Linux/Shebang/Exit-Codes/Laboratorio/Tareas/4
  - Linux/Shebang/Exit-Codes/Dificultad/Calificacion/75
  - Linux/Shebang/Exit-Codes/Bash
---
### Resumen

Este laboratorio práctico consolida el entendimiento de exit codes a través de ejercicios progresivos que demuestran cómo los comandos y scripts comunican su estado de ejecución. Las primeras tareas se enfocaron en verificar y registrar exit codes de comandos comunes como `uptime` y `traceroute`, utilizando la variable `$?` para capturar los resultados. Posteriormente, se trabajó con un script existente (`create-rocket.sh`) para evaluar su exit code y entender cómo diferentes resultados de ejecución generan códigos distintos. El objetivo fue internacionalizar que cada comando devuelve información crucial sobre su desempeño, información que los scripts deben evaluar y utilizar para tomar decisiones.

La tarea final fue la más relevante: modificar un script para que devolviera un exit code personalizado (25) cuando el estado fuera "failed", después de imprimir el mensaje de error. Esta práctica demostró cómo implementar lógica de error en scripts reales, permitiendo que otros programas o administradores detecten fallos mediante los exit codes. La calificación del 75% refleja que se comprendió el concepto central, aunque posiblemente se necesite reforzar algunos detalles sobre códigos de error específicos o sintaxis de control de flujo.

### Ejemplo de comando

bash

```bash
#!/bin/bash

# Verificar exit code de un comando simple
uptime
echo "Exit code: $?"

# Ejecutar comando que puede fallar
traceroute example.com
echo "Exit code: $?"

# Script que devuelve exit code personalizado
if [ "$status" = "failed" ]; then
    echo "Debug: Rocket launch failed"
    exit 25  # Exit code personalizado
fi

# Verificar exit code de un script
/home/bob/create-rocket.sh jupiter-mission
echo "Script exit code: $?"
```