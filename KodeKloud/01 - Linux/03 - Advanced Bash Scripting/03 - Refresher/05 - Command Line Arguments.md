---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Command Line Arguments
Fecha: 2004-05-15
Estado: completado
Type: Video
Dificultad: Básico Bajo
tags:
---
Los argumentos de línea de comandos son valores que se pasan a un script cuando se ejecuta, accesibles mediante variables posicionales como `$1`, `$2`, `$3`, etc., donde `$0` representa el nombre del script mismo. Estos argumentos permiten que los scripts sean flexibles y reutilizables, aceptando diferentes parámetros sin necesidad de modificar el código. El comando `getconf ARG_MAX` permite verificar el número máximo de argumentos que un sistema puede procesar, lo que es útil para entender los límites del entorno.

El comando `shift` es una herramienta poderosa para desplazar los argumentos posicionales dentro del script, eliminando el primer argumento y corriendo el resto hacia abajo (es decir, `$2` se convierte en `$1`, `$3` en `$2`, etc.). Esto es especialmente útil cuando necesitas procesar una lista variable de argumentos en un bucle, permitiendo iterar sobre cada uno sin necesidad de conocer el número exacto de parámetros de antemano. Comprender estos conceptos es fundamental para crear scripts profesionales que manejen entrada dinámica.

**Ejemplo de comando:**

bash

```bash
#!/bin/bash

echo "Primer argumento: $1"
echo "Segundo argumento: $2"
echo "Total de argumentos: $#"

# Verificar límite máximo de argumentos
getconf ARG_MAX

# Ejemplo con shift
while [ $# -gt 0 ]; do
    echo "Procesando: $1"
    shift
done
```