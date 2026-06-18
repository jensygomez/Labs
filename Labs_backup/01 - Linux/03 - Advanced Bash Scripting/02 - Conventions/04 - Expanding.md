---
Curso: Advanced Bash Scripting
Modulo: Conventions
Tema: Expanding
Fecha: 2004-05-13
Estado: completado
tags:
---
La expansión de variables en Bash es un concepto fundamental que requiere entender la diferencia entre `$var` y `${var}`. El símbolo `$` indica que Bash debe expandir (sustituir) la variable con su valor. Usar `$var` es suficiente en la mayoría de casos simples, pero `${var}` es más explícito y necesario cuando la variable está adyacente a caracteres que podrían confundir el parser. La convención recomendada es usar siempre `${var}` para mayor claridad y evitar errores sutiles, especialmente cuando se trabaja con rutas, nombres de archivo y URLs que frecuentemente contienen caracteres especiales. El uso de comillas dobles alrededor de la expansión, como `"${var}"`, protege el contenido de word splitting y glob expansion, previniendo comportamientos inesperados.

Las comillas dobles son especialmente críticas cuando trabajas con rutas de directorios, nombres de archivo y URLs que pueden contener espacios o caracteres especiales. Sin las comillas, una ruta como `/home/usuario/mis documentos` se dividiría en múltiples palabras, causando errores. La convención es usar siempre `"${variable}"` cuando la expansión representa rutas, nombres de archivo o cualquier dato que provenga de entrada externa. Esta práctica es vital en scripts de administración de sistemas donde las rutas y nombres de archivo son impredecibles, garantizando que el script funcione correctamente incluso en casos extremos.

**Ejemplos de convención de expansión:**

bash

```bash
#!/bin/bash

# Variables de ejemplo
nombre_usuario="juan"
ruta_home="/home/juan/mis documentos"
archivo_backup="backup_$(date +%Y%m%d).tar.gz"

# Incorrecto: sin comillas, ruta con espacios se divide
# cp $ruta_home/archivo.txt /backup/  # ¡Error!

# Correcto: con comillas dobles y expansión explícita
cp "${ruta_home}/archivo.txt" "/backup/"

# Expansión simple (suficiente en algunos casos)
echo "Usuario: $nombre_usuario"

# Expansión explícita (recomendada siempre)
echo "Ruta: ${ruta_home}"
echo "Backup: ${archivo_backup}"

# Caso donde ${var} es necesario
echo "${nombre_usuario}_backup"  # Correcto: juan_backup
# echo "$nombre_usuario_backup"  # Error: busca variable $nombre_usuario_backup

# Con URLs y rutas complejas
URL="https://example.com/api/v1"
directorio_destino="/var/www/html"
echo "Descargando desde ${URL} a ${directorio_destino}"
```