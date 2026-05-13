---
Curso: Advanced Bash Scripting
Modulo: Shell Script Introduction
Tema: Shell scripting vs Bash scripting
Typo: Video
Fecha: 04/05/2026
Estado: completado
Dificultad:
Calificación:
Time: 5 min
tags:
  - Linux
  - Linux/Advanced-Bash-Scripting
  - Linux/Advanced-Bash-Scripting/Introduction
  - Linux/Advanced-Bash-Scripting/Introduction/Shell-Vs-Bash
  - Linux/Advanced-Bash-Scripting/Introduction/Shell-Vs-Bash/Shell-Script
  - Linux/Advanced-Bash-Scripting/Introduction/Shell-Vs-Bash/Bash
  - Linux/Advanced-Bash-Scripting/Introduction/Shell-Vs-Bash/Scripting
  - Linux/Advanced-Bash-Scripting/Introduction/Shell-Vs-Bash/Portabilidad
---

## Shell Scripting vs Bash Scripting

Existen múltiples shells en Linux (sh, bash, zsh, ksh, fish, etc.), cada uno con sus propias características y sintaxis específica. Shell scripting es un término genérico que se refiere a la escritura de scripts para cualquier shell disponible en el sistema. Sin embargo, Bash scripting es más específico: se refiere a scripts escritos específicamente para el intérprete Bash (Bourne Again Shell), aprovechando sus características particulares y extensiones que no están presentes en otros shells.

La recomendación profesional es utilizar Bash para la mayoría de tus scripts, especialmente si necesitas portabilidad entre diferentes sistemas Linux y Unix. Bash es el shell estándar en la mayoría de distribuciones Linux modernas (incluyendo Rocky Linux 9.7 que usas), lo que garantiza que tus scripts funcionen sin problemas en diferentes entornos sin depender de shells específicos. Además, Bash ofrece características avanzadas como arrays, funciones mejoradas, expansión de parámetros y control de errores más robusto, fundamentales para escribir scripts de administración de sistemas de calidad profesional.

### Ejemplo: Identificar el Shell

```bash
#!/bin/bash
# Mostrar el shell actual
echo "Shell actual: $SHELL"
echo "Bash version: $BASH_VERSION"

# Verificar si estamos en bash
if [ -n "$BASH_VERSION" ]; then
    echo "✓ Ejecutando en Bash"
else
    echo "✗ No estamos en Bash"
fi
```

