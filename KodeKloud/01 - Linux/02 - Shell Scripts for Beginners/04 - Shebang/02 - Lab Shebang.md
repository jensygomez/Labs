---
Curso: Shell Scripts for Beginners
Modulo: Shebang
Tema: "Lab: Shebang"
Fecha: 2026-05-11
tags:
  - Linux
  - Linux/Shebang
  - Linux/Shebang/Shebang
  - Linux/Shebang/Shebang/Time/10min
  - Linux/Shebang/Shebang/Dificultad/Basico-Bajo
  - Linux/Shebang/Shebang/Bash
  - Linux/Shebang/Shebang/Laboratorio
---

### Resumen

Este laboratorio práctico refuerza el concepto de shebang mediante la identificación y resolución de problemas en scripts de shell. A través de cinco tareas progresivas, se trabajó con scripts existentes en `/home/bob/scripts` para entender cómo el shell intérprete afecta la ejecución. La práctica incluyó ejecutar scripts en diferentes shells (bash y sh), identificar cuál de ellos fallaba debido a la falta de shebang, y luego agregar la línea shebang correcta (`#!/bin/bash`) para garantizar compatibilidad. El objetivo principal fue comprender cómo un mismo script puede comportarse de manera diferente dependiendo del intérprete utilizado y cómo el shebang resuelve este problema.

La resolución de las tareas demostró la importancia de documentar explícitamente el intérprete requerido. Al agregar el shebang y corregir la sintaxis específica de bash en el script que no funcionaba, se logró que todos los scripts ejecutaran correctamente desde cualquier shell. Este ejercicio simuló un escenario real donde un script heredado o mal configurado causa fallos en producción, enseñando la metodología de troubleshooting: identificar el problema, entender la causa raíz (falta de shebang o sintaxis incompatible) y aplicar la solución adecuada.

### Ejemplo de comando

bash

```bash
# Verificar qué shell está activo
echo $SHELL

# Cambiar a shell sh
sh

# Intentar ejecutar script
./loop.sh

# Volver a bash
bash

# Agregar shebang al script
echo '#!/bin/bash' | cat - script.sh > temp && mv temp script.sh

# Dar permisos de ejecución
chmod +x script.sh

# Ejecutar script
./script.sh
```