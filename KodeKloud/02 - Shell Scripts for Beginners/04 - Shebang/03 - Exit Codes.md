---
Curso: Shell Scripts for Beginners
Modulo: Shebang
Tema: Exit Codes
Fecha: 2026-05-11
tags:
  - Linux
  - Linux/Shebang
  - Linux/Shebang/Exit-Codes
  - Linux/Shebang/Exit-Codes/Dificultad/Basico-Bajo
  - Linux/Shebang/Exit-Codes/Time/5min
  - Linux/Shebang/Exit-Codes/Shell-Scripting
  - Linux/Shebang/Exit-Codes/Bash
---
### Resumen

Los exit codes (códigos de salida) son valores numéricos que todo comando en Linux devuelve para indicar si su ejecución fue exitosa o fallida. Por convención, un exit code de `0` significa que el comando se ejecutó correctamente, mientras que cualquier valor diferente de cero (típicamente 1, 2, 127, etc.) indica un error específico. Este mecanismo es fundamental en scripting porque permite al programa evaluar el resultado de cada comando y tomar decisiones basadas en él. El exit code se almacena automáticamente en la variable especial `$?`, que captura el estado de salida del último comando ejecutado, permitiendo que el script verifique si una operación fue exitosa antes de proceder al siguiente paso.

Entender y utilizar exit codes es esencial para escribir scripts robustos que manejen errores adecuadamente. Cada aplicación o comando puede definir sus propios códigos de error para comunicar distintos tipos de fallos (archivo no encontrado, permisos insuficientes, sintaxis inválida, etc.). Al verificar `$?` después de ejecutar un comando, el script puede implementar lógica condicional para manejar errores, registrar problemas o ejecutar acciones alternativas, mejorando significativamente la confiabilidad y el debugging del código.

### Ejemplo de comando

bash

```bash
#!/bin/bash

# Ejecutar un comando
ls /home

# Verificar el exit code
echo $?

# Ejemplo con condicional
if [ $? -eq 0 ]; then
    echo "El comando fue exitoso"
else
    echo "El comando falló"
fi

# O de manera más directa
ls /directorio_inexistente
echo "Exit code: $?"  # Mostrará un número diferente de 0
```