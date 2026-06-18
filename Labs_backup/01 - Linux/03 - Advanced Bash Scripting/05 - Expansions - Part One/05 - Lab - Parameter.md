---
Curso: Advanced Bash Scripting
Modulo: Streams
Tema: Lab - Parameter
Fecha de Inicio: 2026-06-02
Dificultad:
Tareas Totales:
tags:
  - Advanced-Bash-Scripting
---
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito |
| :--------- | :----- | :---- |
| `02/06/26` | 30 min |       |
|            |        |       |

[[Advanced Bash Scripting]]


Bash

```bash
#!/bin/bash

# Q2: Definición de la URL base de Git
git_url="https://github.com/jcroyoaun/kodekloud-lab-sample-nodejs/blob/master/app.js"

# Q3: Paso 1 - Reemplazar "github.com" por "raw.githubusercontent.com" usando ${var/buscar/reemplazar}
raw_url_step1="${git_url/github.com/raw.githubusercontent.com}"

# Q4: Paso 2 - Extracción de Prefijo y Sufijo eliminando el patrón "/blob/*" o "*/blob/"
# 'prefix' elimina desde el último 'blob/' en adelante para quedarse con la primera parte de la URL
prefix="${raw_url_step1%/blob/*}/"
# 'suffix' elimina todo lo anterior a '/blob/' para quedarse con la ruta del archivo y la rama
suffix="${raw_url_step1#*/blob/}"

# Q5: Paso 3 - Concatenación de las variables para armar la URL Raw final
raw_url="${prefix}${suffix}"

# Q6: Paso 4 - Cambiar el 'echo' por 'curl' para descargar el contenido directamente a la salida estándar
curl --silent "${raw_url}"
```



```bash
# Q2d: Otorga permisos de ejecución al script que acabas de crear utilizando la bandera completa --changes
chmod --changes +x /home/bob/git_url_converter.sh

# Q7a: Ejecuta el script y redirige la salida del código fuente descargado directamente hacia el archivo app.js destino
/home/bob/git_url_converter.sh > /home/bob/nodejs/kodekloud-lab6/app.js

# Q7b: Cambia de directorio actual hacia la ruta del laboratorio de Node.js
cd /home/bob/nodejs/kodekloud-lab6/

# Q7c: Instala las dependencias del proyecto (package.json) y arranca la aplicación en segundo plano (&)
npm install && node app.js &
```