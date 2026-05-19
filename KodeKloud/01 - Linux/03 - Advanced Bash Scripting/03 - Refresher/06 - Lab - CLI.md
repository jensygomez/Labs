---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Lab - CLI
Fecha de Inicio: 2004-05-15
Estado: completado
Type: Laboratorio
Tareas Totales: "7"
Dificultad: Básico Medio
tags:
  - Linux
  - Linux/Advanced-Bash-Scripting
  - Linux/Advanced-Bash-Scripting/Refresher
  - Linux/Advanced-Bash-Scripting/Refresher/Laboratorio
---
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 15 - 05 - 2026 | 15 min | 43 %  | CLI           |
|                |        |       |               |

En este laboratorio se integró el concepto de argumentos de línea de comandos con funciones Bash para crear un script flexible que clona repositorios Git y navega entre ramas. Se comenzó asignando el primer argumento posicional (`$1`) a una variable `project` para evitar hardcodear la URL del repositorio, luego se añadió un segundo argumento (`$2`) para la rama a ejecutar. El script evolucionó desde una versión estática a una dinámica, donde `clone_project()` ejecuta los comandos de clonación y navegación, y `find_files()` busca archivos dentro del directorio del proyecto usando rutas relativas con "." después de cambiar de directorio.

Las tareas finales refactorizaron los comandos `git checkout` en una función dedicada `git_checkout()` para mantener la separación de responsabilidades y mejorar la reutilización. Este laboratorio demuestra cómo combinar argumentos CLI, variables, funciones y navegación de directorios para crear scripts profesionales y adaptables. La clave fue entender que `find` debe ejecutarse desde el contexto correcto del directorio, y que las funciones facilitan la organización lógica del código cuando el script requiere múltiples pasos interdependientes.

**Ejemplo de comando:**

bash

```bash
#!/bin/bash

project=$1
branch=$2

function clone_project() {
    git clone "${project}"
    cd "$(basename ${project} .git)"
    git checkout "${branch}"
}

function find_files() {
    find . -type f -name "*.sh"
}

function git_checkout() {
    git checkout "${branch}"
}

clone_project
find_files
```

**Ejecución:**

bash

```bash
./clone_project.sh https://github.com/kodekloudhub/solar-system-9.git main
```

---