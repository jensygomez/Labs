---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Keywords-builtins
Fecha: 2004-05-17
Estado: completado
Type: Video
Dificultad: Básico Medio
tags:
  - Linux
  - Linux/Advanced-Bash-Scripting
  - Linux/Advanced-Bash-Scripting/Refresher
  - Linux/Advanced-Bash-Scripting/Refresher/Keywords-builtins
---


---

Los keywords en bash son construcciones del lenguaje como loops (`for`, `while`, `if`, `case`) que no generan un PID nuevo, a diferencia de los comandos binarios. Esta es una distinción importante: mientras que los built-in commands se ejecutan dentro del shell pero podrían tener cierta overhead, los keywords son parte de la sintaxis del shell y se procesan directamente sin overhead adicional. Los keywords se construyen con estructuras de control y no requieren un proceso hijo, lo que los hace extremadamente eficientes en términos de recursos.

La diferencia principal entre usar un solo bracket `[ ]` y dobles brackets `[[ ]]` en condicionales es importante: el single bracket `[ ]` es más portátil (POSIX compatible) pero tiene menos capacidades, mientras que el double bracket `[[ ]]` es una extensión de bash que ofrece más funcionalidades (como regex matching, mejor manejo de strings) pero solo funciona en bash. Cada uno tiene sus ventajas y desventajas: `[ ]` es mejor para scripts que necesitan portabilidad, mientras que `[[ ]]` es preferible para bash puro donde se requiere mayor flexibilidad y menos quoting requerido.

**Comando de ejemplo:**

```bash
# Keywords: no generan PID
for i in {1..5}; do
  echo "Iteración $i"
done

# Single bracket [ ] - POSIX compatible
if [ -f /etc/passwd ]; then
  echo "Archivo existe"
fi

# Double bracket [[ ]] - Bash extendido, más potente
if [[ "$variable" =~ ^[0-9]+$ ]]; then
  echo "Es un número"
fi

# Comparar overhead
time for i in {1..1000}; do [ $i -gt 500 ]; done
time for i in {1..1000}; do [[ $i -gt 500 ]]; done
```