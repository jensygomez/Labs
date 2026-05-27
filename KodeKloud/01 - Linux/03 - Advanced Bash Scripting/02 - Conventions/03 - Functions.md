---
Curso: Advanced Bash Scripting
Modulo: Conventions
Tema: Functions
Fecha: 2004-05-13
Estado: completado
tags:
---
Las funciones en Bash scripting deben seguir convenciones claras para mantener la legibilidad y reutilización del código. Los nombres de funciones se escriben en minúsculas usando snake_case y deben ser altamente descriptivos, reflejando exactamente qué acción realizan, como `calculate_area()`, `validate_user_input()` o `backup_database()`. La sintaxis requiere paréntesis vacíos seguidos de llaves para delimitar el bloque de código: `nombre_funcion() { ... }`. Esta estructura permite que cualquier administrador que lea el script entienda instantáneamente el propósito de cada función sin necesidad de leer su contenido completo.

El uso de funciones bien nombradas transforma scripts monolíticos en código modular y mantenible, lo cual es esencial cuando trabajas como Sysadmin en entornos empresariales. Funciones descriptivas como `check_disk_space()` o `restart_service()` no solo mejoran la legibilidad, sino que también facilitan el testing, debugging y reutilización de lógica común. Además, una función bien diseñada con un nombre claro reduce la necesidad de comentarios excesivos, ya que el propósito es evidente en el nombre mismo.

**Ejemplos de convención de funciones:**

bash

```bash
#!/bin/bash

# Función bien nombrada y estructurada
validate_user_input() {
    local input="$1"
    local max_length="${2:-50}"
    
    if [ -z "$input" ]; then
        echo "Error: entrada vacía"
        return 1
    fi
    
    if [ ${#input} -gt $max_length ]; then
        echo "Error: entrada excede $max_length caracteres"
        return 1
    fi
    
    return 0
}

# Función para verificar espacio en disco
check_disk_space() {
    local ruta="$1"
    local limite_gb="${2:-10}"
    
    local espacio_libre=$(df "$ruta" | awk 'NR==2 {print $4}')
    local espacio_libre_gb=$((espacio_libre / 1024 / 1024))
    
    if [ $espacio_libre_gb -lt $limite_gb ]; then
        echo "Alerta: espacio bajo en $ruta"
        return 1
    fi
    
    return 0
}

# Uso de las funciones
if validate_user_input "datos_entrada" 100; then
    check_disk_space "/home" 20
fi
```