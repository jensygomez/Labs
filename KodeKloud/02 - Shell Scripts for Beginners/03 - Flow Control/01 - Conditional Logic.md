---
Curso: Shell Scripts for Beginners
Modulo: Flow Control
Tema: Conditional Logic
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
  - conditional-logic
  - flow-control
---
### Resumen

La sentencia `if` es la estructura fundamental del control de flujo en Bash, permitiendo ejecutar código condicionalmente basado en evaluaciones lógicas. Su sintaxis básica incluye la condición entre corchetes simples `[]` o dobles `[[]]`, siendo estos últimos más poderosos al ofrecer operadores avanzados y manejo mejorado de strings. Además de `if`, se puede utilizar `elif` para múltiples condiciones consecutivas, creando una cadena de evaluaciones que se ejecutan de arriba hacia abajo hasta encontrar una verdadera.

Las comparaciones funcionan diferente según el tipo de dato: para números se usan `-eq` (igual), `-ne` (no igual), `-lt` (menor), `-gt` (mayor), `-le` (menor o igual), `-ge` (mayor o igual); para strings se usan `=` o `==` (igual) y `!=` (no igual). Los operadores lógicos `&&` (AND) y `||` (OR) permiten combinar múltiples condiciones, con comportamientos ligeramente distintos entre corchetes simples y dobles. También es posible verificar la existencia y tipo de archivos y directorios usando flags como `-f` (archivo), `-d` (directorio), `-e` (existe).

#### Ejemplo de Comando

bash

```bash
#!/bin/bash

# Comparación de números con if/elif
age=25

if [ $age -lt 18 ]; then
    echo "Eres menor de edad"
elif [ $age -eq 18 ]; then
    echo "Tienes 18 años"
else
    echo "Eres mayor de edad"
fi

# Comparación de strings con dobles corchetes
username="admin"

if [[ $username == "admin" ]] && [[ -f "/etc/passwd" ]]; then
    echo "Usuario admin encontrado y archivo existe"
fi

# Verificar archivo o directorio
if [ -d "/home" ]; then
    echo "/home es un directorio"
elif [ -f "/etc/hostname" ]; then
    echo "/etc/hostname es un archivo"
fi
```