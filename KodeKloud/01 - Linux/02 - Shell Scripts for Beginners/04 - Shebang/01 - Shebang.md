---
Curso: Shell Scripts for Beginners
Modulo: Shebang
Tema: Shebang
Fecha: 2026-05-11
tags:
  - Linux
  - Linux/Shebang
  - Linux/Shebang/Shebang
  - Linux/Shebang/Shebang/Time/5min
  - Linux/Shebang/Shebang/Dificultad/Basico-Bajo
  - Linux/Shebang/Shebang/Bash
---

### Resumen

El shebang es la primera línea de un script de shell que especifica el intérprete a utilizar para ejecutar el archivo. Comienza con `#!` seguido de la ruta absoluta del shell deseado (por ejemplo, `#!/bin/bash`). Esto es fundamental porque existen múltiples shells en Linux (bash, sh, zsh, ksh, etc.) y cada uno tiene diferencias en sintaxis y comportamiento. Sin el shebang, el script podría ejecutarse con un shell distinto al que fue escrito, causando errores de compatibilidad. Al especificar explícitamente el shell, garantizamos que el script funcione correctamente sin importar cuál sea el shell predeterminado del usuario o el sistema.

El shebang también permite que el script sea ejecutable directamente como un programa (sin necesidad de anteponer `bash script.sh`), siempre y cuando se le otorguen permisos de ejecución. Cuando ejecutas `./script.sh`, el sistema operativo lee el shebang y automáticamente invoca el intérprete especificado. Esto es especialmente importante en entornos colaborativos donde múltiples usuarios con diferentes configuraciones necesitan ejecutar el mismo script, asegurando portabilidad y consistencia.

### Ejemplo de comando

bash

```bash
#!/bin/bash
echo "Este script se ejecutará con bash"
```

Para hacerlo ejecutable:

bash

```bash
chmod +x script.sh
./script.sh
```
