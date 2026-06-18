---
Curso: Advanced Bash Scripting
Modulo: Introduction
Tema: Terminology
Typo: Video
Fecha: 04/05/2026
Estado: completado
Dificultad:
Calificación:
Time: 5 min
tags:
---

## Terminology: Conceptos Fundamentales

Es crucial entender la diferencia entre los términos clave en Linux scripting. El **Shell** es el programa intérprete que procesa y ejecuta los comandos que ingresas, actuando como intermediario entre el usuario y el kernel del sistema operativo. La **Terminal** es el programa (emulador) que utilizas para interactuar con el shell, proporcionando una interfaz gráfica o basada en texto donde puedes escribir comandos. La **Console** se refiere al terminal físico o hardware, mientras que **TTY** (TeleTYpe) es un término heredado que designa cualquier dispositivo de terminal, ya sea virtual o físico, que permite la comunicación bidireccional con el sistema.

**POSIX** (Portable Operating System Interface) es un estándar internacional que define cómo deben comportarse los sistemas operativos tipo Unix/Linux y qué características deben implementar. Su importancia radica en que garantiza la portabilidad de scripts y aplicaciones entre diferentes sistemas operativos que cumplan con este estándar (Linux, macOS, BSD, etc.). Cuando escribes scripts POSIX-compliant, aseguras que funcionarán en prácticamente cualquier sistema Unix/Linux sin necesidad de modificaciones. Esto es esencial para un sysadmin, ya que tus scripts deben ser reutilizables en múltiples servidores y entornos.

### Ejemplo: Verificar Información de TTY

```bash
#!/bin/bash
# Mostrar información del terminal actual
echo "TTY actual: $(tty)"
echo "Shell: $SHELL"
echo "Terminal: $TERM"

# Listar todos los TTYs conectados
who
```

Ejecutar: `./info-tty.sh`
