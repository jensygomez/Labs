---
Curso: Shell Scripts for Beginners
Modulo: Flow Control
Tema: Case Statements
Fecha: 2026-05-11
Dificultad:
Time: 5 min
tags:
---


## Resumen

Las sentencias `case` son la forma más limpia y legible de manejar múltiples condiciones en bash cuando necesitas evaluar una única variable contra varios valores posibles. A diferencia de los condicionales `if-else` encadenados, `case` proporciona una sintaxis más clara y eficiente, haciendo que el código sea más fácil de leer y mantener. Este enfoque es especialmente útil cuando tienes más de dos o tres opciones que evaluar.

La estructura base de un `case` statement evalúa el valor de una variable y ejecuta bloques de código según coincida con los patrones especificados. Esto es un cambio de paradigma importante porque reemplaza la lógica if-if-if con un enfoque más declarativo y orientado a casos, permitiendo escribir scripts más profesionales y escalables.

## Estructura Básica

```bash
case $variable in
  patron1)
    echo "Coincidió con patron1"
    ;;
  patron2)
    echo "Coincidió con patron2"
    ;;
  *)
    echo "No coincidió con ningún patrón"
    ;;
esac
```

## Ejemplo Práctico

```bash
#!/bin/bash

read -p "Ingresa un día de la semana: " day

case $day in
  lunes|monday)
    echo "Inicio de semana laboral"
    ;;
  viernes|friday)
    echo "¡Casi es fin de semana!"
    ;;
  sabado|saturday|domingo|sunday)
    echo "¡Es fin de semana!"
    ;;
  *)
    echo "Día no reconocido"
    ;;
esac
```

