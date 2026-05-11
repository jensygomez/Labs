---
Curso: Shell Scripts for Beginners
Modulo: Shell Script Introduction
Tema: Arithmetic Operations
Typo: Video
Fecha: 02/05/2026
Estado: completado
Dificultad: Básico Bajo
Calificación:
Time: 6 min
tags:
  - Linux/Shell-Scripts-for-Beginners/Arithmetic-Operations
---
Las operaciones aritméticas en shell scripts se pueden realizar de varias formas. La más tradicional es utilizar el comando `expr`, que evalúa expresiones matemáticas simples. Sin embargo, existen alternativas más modernas y eficientes que son preferibles en scripts actuales. El uso de doble paréntesis precedido del símbolo `$` permite realizar operaciones aritméticas directamente sin necesidad de comandos externos, mejorando el rendimiento del script.

Para operaciones que requieran resultados en punto decimal, `expr` resulta insuficiente ya que solo maneja números enteros. En estos casos, la herramienta `bc` (basic calculator) es la solución ideal, permitiendo realizar cálculos con precisión decimal y especificar la cantidad de decimales a mostrar mediante el parámetro de escala.

**Ejemplos de comandos:**

bash

```bash
# Usando expr
result=$(expr 10 + 5)
echo $result  # Output: 15

# Usando doble paréntesis
A=10
B=5
echo $((A + B))      # Output: 15
echo $((A - B))      # Output: 5
echo $((++A))        # Incrementa A y muestra el resultado

# Usando bc para decimales
A=10
B=3
echo "scale=2; $A / $B" | bc    # Output: 3.33
```