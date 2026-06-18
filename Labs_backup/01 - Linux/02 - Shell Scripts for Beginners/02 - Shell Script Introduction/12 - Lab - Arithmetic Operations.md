---
Curso: Shell Scripts for Beginners
Modulo: Shell Script Introduction
Tema: "Lab: Arithmetic Operations"
Typo: Laboratorio
Fecha: 02/05/2026
Estado: completado
Dificultad: Básico Bajo
Calificación: 60 %
Time: 6 min
tags:
---
En este laboratorio se desarrolló un script en bash llamado `calculate-average.sh` que procesa exactamente 3 argumentos de línea de comandos y calcula el promedio entre ellos. El script debe validar que reciba exactamente tres parámetros y manejar correctamente números decimales sin redondear el resultado. Este ejercicio refuerza conceptos fundamentales de scripting como la captura de argumentos mediante `$1`, `$2` y `$3`, la validación de entrada, y la manipulación de aritmética decimal en bash. El desafío principal radica en evitar que bash redondee automáticamente los valores decimales, lo que requiere usar herramientas como `bc` (calculadora de precisión arbitraria) o `awk` para mantener los decimales en el resultado final. Este es un paso importante hacia escribir scripts más robustos que manejen datos numéricos con precisión, una habilidad esencial para un sysadmin que necesita procesar datos y generar reportes. Ejemplo de uso: 

```bash 
#!/bin/bash 
# Validar exactamente 3 argumentos 
if [ $# -ne 3 ]; then 
    echo "Error: Se requieren exactamente 3 argumentos" 
    exit 1 
fi 
# Calcular promedio sin redondear (usando bc)
average=$(echo "scale=2; ($1 + $2 + $3) / 3" | bc) echo "Promedio: $average" ``` 
Ejecución: 
```bash 
./calculate-average.sh 10 20 30 
# Output: Promedio: 20.00 ./calculate-average.sh 7 8 9 # Output: Promedio: 8.00 
```