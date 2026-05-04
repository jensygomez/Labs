---
Curso: Shell Scripts for Beginners
Modulo: Flow Control
Tema: Loops-For
Typo: Video
Fecha: 03/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 12 min
tags:
  - linux
  - shell-script
  - bash
  - scripting
  - loops
  - flow-control
---
El loop `for` es una estructura de control fundamental en bash que permite ejecutar comandos de forma repetitiva sobre una lista de elementos. Su sintaxis básica consiste en definir una variable que iterará sobre cada elemento de la lista, ejecutando el bloque de comandos entre `do` y `done` en cada iteración. Esta herramienta es esencial cuando necesitas automatizar tareas que se repiten múltiples veces.

El poder del `for` loop radica en su flexibilidad: puedes iterar directamente sobre listas inline (archivos, números, cadenas) o leer contenido desde archivos externos. Es especialmente útil para procesar línea por línea el contenido de un archivo, ejecutar comandos sobre múltiples archivos en un directorio, o realizar la misma operación en lotes de datos. Dominar esta estructura es fundamental para escribir scripts eficientes y automatizar tareas administrativas en Linux.

**Ejemplo de comando:**

bash

```bash
# Iterar sobre archivos en un directorio
for archivo in /home/user/*.log
do
  echo "Procesando: $archivo"
  grep "ERROR" "$archivo"
done

# Iterar sobre números
for i in {1..5}
do
  echo "Número: $i"
done

# Iterar sobre una lista explícita
for servicio in nginx mysql ssh
do
  systemctl status $servicio
done
```