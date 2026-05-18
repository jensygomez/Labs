---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Lab - Builtin
Fecha de Inicio: 2026-05-18
Dificultad: Básico Medio
Tareas Totales: "8"
tags:
  - Linux
  - Linux/Advanced-Bash-Scripting
  - Linux/Advanced-Bash-Scripting/Refresher
  - Linux/Advanced-Bash-Scripting/Refresher/Lab-Builtin
  - Linux/Advanced-Bash-Scripting/Refresher/Lab-Builtin/Laboratorio
---
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 18 - 05 - 2026 | 10 min | 50 %  | CLI           |
|                |        |       |               |



## 📝 Resumen

En este laboratorio exploramos los **tipos de comandos en Bash** y aprendimos a clasificarlos en tres categorías: shell built-in commands, keywords y binarios ejecutables. La práctica se enfoca en utilizar el comando `type` para identificar qué tipo de comando estamos ejecutando y entender las diferencias entre comandos internos del shell (como `kill`) que tienen contraparte binaria en el filesystem, versus comandos puros del intérprete de shell. Comprendimos también que los keywords son palabras especiales reservadas por el shell (como `if`, `while`, `for`) que se utilizan para control de flujo y alteran el comportamiento de scripts, mientras que los built-ins son programas preempaquetados dentro del shell que no generan un PID propio.

La meta del laboratorio era dominar las herramientas `type`, `compgen -k` (keywords), y `compgen -b` (built-in commands) para poder diagnosticar rápidamente qué tipo de comando estamos utilizando en nuestro sistema. Esto es fundamental como Sysadmin porque te ayuda a entender la ejecución de scripts, debugging, y el comportamiento del shell. Con esta base, puedes identificar conflictos cuando un built-in no se comporta como esperas, o cuando necesitas usar la versión binaria de un comando en lugar de la del shell.

## 🔧 Comando de Referencia

```bash
# Identificar el tipo de comando
type kill
type -a kill  # Muestra todas las versiones del comando

# Listar todos los keywords disponibles
compgen -k

# Contar cuántos keywords tiene el sistema
compgen -k | wc -l

# Listar todos los built-in commands
compgen -b

# Contar cuántos built-ins disponibles
compgen -b | wc -l

# Verificar la shell actual
ps

# Identificar la TTY de la sesión actual
tty
```



---
