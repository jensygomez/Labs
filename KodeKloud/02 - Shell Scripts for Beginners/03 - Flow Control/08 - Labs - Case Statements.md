---
Curso: Shell Scripts for Beginners
Modulo: Flow Control
Tema: "Labs: Case Statements"
Fecha: 2026-05-11
tags:
  - Linux
  - Linux/Shell-Scripts-for-Beginners
  - Linux/Shell-Scripts-for-Beginners/Flow-Control
  - Linux/Shell-Scripts-for-Beginners/Flow-Control/Laboratorio
---
## Resumen

Este laboratorio práctica la implementación de sentencias `case` en scripts bash, reforzando los conceptos aprendidos en el video anterior. A través de 5 ejercicios progresivos, se trabaja con la conversión de condicionales `if-else` a `case` statements, la depuración de errores de sintaxis, y la expansión de funcionalidad en scripts existentes. Cada tarea requiere no solo entender la estructura de `case`, sino también reconocer cuándo usarla y cómo manejar valores por defecto con el patrón comodín `*`.

Las tareas van desde identificar y corregir errores de sintaxis en scripts existentes, hasta migrar lógica condicional compleja de `if` a `case`, pasando por la adición de nuevas opciones en un script calculadora. Este enfoque progresivo garantiza que domines tanto la sintaxis como la aplicación práctica de case statements en situaciones reales.

## Concepto Clave

El patrón comodín `*)` es esencial en este laboratorio - captura cualquier valor que no coincida con los patrones anteriores, permitiendo manejar errores de entrada de forma elegante y proporcionar mensajes de error claros.

## Ejemplo de Conversión (if a case)

```bash
# Antes (if-else)
if [ $option -eq 1 ]; then
  echo "Suma"
elif [ $option -eq 2 ]; then
  echo "Resta"
else
  echo "Opción inválida"
fi

# Después (case)
case $option in
  1)
    echo "Suma"
    ;;
  2)
    echo "Resta"
    ;;
  *)
    echo "Opción inválida"
    ;;
esac
```

## Comando para Ejecutar Scripts

```bash
# Ejecutar script con argumentos
./print-pkm.sh Fedora
./print-month-name.sh 10
./print-color.sh red

# Hacer script ejecutable
chmod +x script.sh
```

