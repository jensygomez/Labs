---
Curso: Advanced Bash Scripting
Modulo: Shell Script Introduction
Tema: Interactive-vs-non-interactive-shell
Typo: Video
Fecha: 04/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 5 min
tags:
  - linux
  - shell-script
  - bash
  - scripting
  - advanced
---

## Interactive vs Non-Interactive Shell

El shell interactivo es aquel donde ejecutas comandos directamente en la terminal, recibiendo retroalimentación inmediata de cada comando. Es la forma más común de trabajar cuando te conectas a un servidor Linux vía SSH o accedes a la consola local. Por el contrario, el shell no-interactivo se refiere a cuando ejecutas un script de bash desde un archivo con shebang (`#!/bin/bash`), donde los comandos se ejecutan de forma automatizada sin esperar entrada del usuario entre cada línea.

La diferencia fundamental radica en cómo el shell procesa las líneas: en modo interactivo, cada comando se evalúa y ejecuta inmediatamente, permitiéndote ver errores y ajustar en tiempo real. En modo no-interactivo, el script se ejecuta linealmente desde el archivo, lo que lo hace ideal para automatización de tareas repetitivas, cronjobs, o deployments en tus servidores. Entender esta distinción es crucial para escribir scripts robustos que funcionen correctamente sin supervisión.

### Ejemplo de Script No-Interactivo

```bash
#!/bin/bash
# script-ejemplo.sh
echo "Iniciando verificación de sistema..."
uptime
free -h
df -h
echo "Verificación completada"
```

