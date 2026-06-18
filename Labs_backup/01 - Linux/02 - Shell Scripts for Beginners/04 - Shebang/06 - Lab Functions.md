---
Curso: Shell Scripts for Beginners
Modulo: Shebang
Tema: Lab Functions
Fecha: 2026-05-12
tags:
---
Este laboratorio práctico se enfoca en dominar la creación y uso de funciones en bash a través de 7 ejercicios progresivos. Los primeros ejercicios trabajan sobre identificar y corregir errores de sintaxis en definiciones de funciones, luego avanza hacia la identificación de código duplicado y su refactorización. Los ejercicios finales requieren extraer bloques de código completos (como secuencias de lanzamiento de cohetes o cálculos matemáticos) y convertirlos en funciones reutilizables, mejorando significativamente la mantenibilidad y legibilidad del código.

El laboratorio culmina con tareas más complejas como pasar argumentos de línea de comandos a funciones, identificar líneas de código duplicadas específicas para consolidarlas, y resolver problemas lógicos dentro de funciones existentes. Todo esto se realiza en scripts ubicados en `/home/bob/`, incluyendo archivos como `create-directories.sh`, `sum.sh`, `calculator.sh` y `create-and-launch-rocket`. La evaluación final fue de 42/42, demostrando el dominio completo de la creación, sintaxis y uso de funciones en shell scripts.

**Ejemplo de refactorización (Pregunta 7):**

bash

```bash
#!/bin/bash

function launch_rocket() {
    local mission=$1
    echo "Preparing launch sequence for $mission..."
    echo "Ignition sequence started"
    echo "Lifting off..."
    echo "Mission $mission is now in orbit!"
}

# Llamar la función con argumento
launch_rocket $1
```