---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Lab - Functions
Fecha de Inicio: 2004-05-15
Estado: completado
Type: Laboratorio
Tareas Totales: "11"
Dificultad: Básico Bajo
tags:
  - Linux
  - Linux/Advanced-Bash-Scripting
  - Linux/Advanced-Bash-Scripting/Refresher
  - Linux/Advanced-Bash-Scripting/Refresher/Laboratorio
---
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas            |
| :------------- | :----- | :---- | :----------------------- |
| 15 - 05 - 2026 | 20 min | 63 %  | Functions y git workflow |
|                |        |       |                          |

---

En este laboratorio se aplicaron los conceptos de funciones en Bash mediante la creación de un script que clona un repositorio Git y manipula sus contenidos. Se trabajó con la función `clone_project()` para encapsular los comandos de clonación, aprendiendo a manejar rutas absolutas y relativas, así como el comando `basename` para extraer nombres de archivos y directorios de una ruta completa. Las tareas iniciales enfocaron en refactorizar código imperativo hacia un enfoque funcional, mejorando la reutilización y legibilidad del script.

Las tareas posteriores incorporaron herramientas de búsqueda y análisis como `find` y `wc` dentro de una nueva función `find_files()`. El comando `find` permitió buscar archivos específicos en el directorio clonado usando criterios como tipo de archivo y nombre, mientras que `wc` se utilizó para contar líneas, palabras o caracteres. El laboratorio culminó con la eliminación segura del directorio creado y la integración de todas las funciones en un flujo coherente, demostrando cómo las funciones facilitan la organización y mantenibilidad del código Bash.

**Ejemplo de comando:**

bash

```bash
function clone_project() {
    git clone https://github.com/kodekloudhub/solar-system-9
    project_dir="$(basename https://github.com/kodekloudhub/solar-system-9 .git)"
}

function find_files() {
    find /home/bob/git/solar-system-9 -type f -name Jenkinsfile
}

clone_project
find_files
rm -rf /home/bob/git/solar-system-9
```