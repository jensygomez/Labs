---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Built-in Commands
Fecha: 2004-05-17
Estado: completado
Type: Video
Dificultad: Básico Bajo
tags:
  - Linux
  - Linux/Advanced-Bash-Scripting
  - Linux/Advanced-Bash-Scripting/Refresher
  - Linux/Advanced-Bash-Scripting/Refresher/Built-in-Commands
---


---

Bash ofrece dos tipos de comandos: los built-in commands (integrados en el shell) y los binaries (ejecutables externos). Los built-in commands son mucho más ligeros en términos de consumo de recursos porque se ejecutan directamente dentro del proceso del shell sin necesidad de hacer fork para crear un proceso hijo. Ejemplos de built-in commands son `echo`, `true`, `false`, `cd`, `export`, mientras que `cat`, `grep`, `ls` son binaries que requieren lanzar un nuevo proceso. Esta diferencia es especialmente importante en scripts que se ejecutan repetidamente o en loops, donde cada llamada a un binary tiene overhead de creación de proceso.

La diferencia de rendimiento es significativa: ejecutar un binary como `/usr/bin/true` toma aproximadamente 0.009 segundos debido al overhead de fork y ejecución del proceso, mientras que el built-in `true` se ejecuta en 0.000 segundos al ser interno del shell. Esta optimización es crucial para escribir scripts bash eficientes que minimizen el consumo de CPU y memoria. Cuando sea posible, es preferible usar built-in commands en lugar de sus equivalentes binarios, especialmente en funciones que se llaman frecuentemente o en loops de larga duración.

**Comando de ejemplo:**

```bash
# Comparar rendimiento: built-in vs binary
time true                    # Casi instantáneo (built-in)
time /usr/bin/true          # ~0.009s (binary)

# Identificar si un comando es built-in o binary
type echo                   # Output: echo is a shell builtin
type cat                    # Output: cat is /usr/bin/cat

# Ver todos los built-in commands disponibles
help

# Listar comandos built-in más comunes
# true, false, cd, echo, printf, export, read, test, [, [[, etc.
```