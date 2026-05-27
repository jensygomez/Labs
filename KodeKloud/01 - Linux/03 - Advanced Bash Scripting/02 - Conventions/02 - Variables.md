---
Curso: Advanced Bash Scripting
Modulo: Conventions
Tema: Variables
Fecha: 2004-05-13
Estado: completado
tags:
---
Las convenciones para nombrar variables en Bash scripting son fundamentales para escribir código mantenible y legible. La convención más utilizada es emplear snake_case (palabras separadas por guiones bajos) para variables normales, como `variable_unica`, `archivo_entrada` o `contador_total`. Esto contrasta con camelCase usado en otros lenguajes y proporciona claridad inmediata sobre el propósito de cada variable. Además, se menciona el concepto de constantes: variables que no deben modificarse durante la ejecución del script y que generalmente se nombran en mayúsculas como `MAX_INTENTOS` o `RUTA_SISTEMA`. Marcar variables como constantes (usando `readonly`) protege la integridad del script y previene modificaciones accidentales que podrían causar comportamientos inesperados.

El uso de constantes es especialmente importante en scripts de administración de sistemas donde valores críticos como rutas, puertos o límites no deben cambiar. Al declarar una variable como constante con `readonly`, Bash evita que sea reasignada, lo que actúa como una barrera de protección contra errores lógicos. Esta práctica es especialmente valiosa en entornos empresariales donde scripts pueden ser ejecutados bajo diferentes contextos y por múltiples administradores, garantizando que los valores sensibles permanezcan inmutables.

**Ejemplos de convención de variables:**

bash

```bash
#!/bin/bash
# Variables normales en snake_case
archivo_config="/etc/mi_app/config.conf"
contador_intentos=0
tiempo_espera=30

# Constantes en MAYUSCULAS con readonly
readonly MAX_INTENTOS=5
readonly PUERTO_SERVIDOR=8080
readonly RUTA_LOGS="/var/log/mi_app"

# Uso en el script
while [ $contador_intentos -lt $MAX_INTENTOS ]; do
    echo "Intento $contador_intentos de $MAX_INTENTOS"
    sleep $tiempo_espera
    ((contador_intentos++))
done

# Esto generaría error:
# MAX_INTENTOS=10  # bash: MAX_INTENTOS: variable de solo lectura
```