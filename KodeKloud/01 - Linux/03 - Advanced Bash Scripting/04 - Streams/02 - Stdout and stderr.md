---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Stdout and stderr
Fecha: 2026-05-22
Estado: completado
Dificultad: Básico Bajo
tags:
  - Advanced-Bash-Scripting
---
[[Advanced Bash Scripting]]


---

In this module, I learned the difference between **stdout** (Standard Output) and **stderr** (Standard Error). Stdout is where normal output from a command goes (file descriptor 1), while stderr is where error messages are sent (file descriptor 2). This separation is very important in advanced Linux and Bash scripting because it allows us to handle successful results and errors independently. Understanding these two streams helps create cleaner, more professional scripts and gives better control over what the user sees on the screen.

I saw practical examples using the `ls` command. When used correctly, the output goes to stdout. However, if I use a wrong option like `ls -j`, the error message is sent to stderr. I also learned that some commands, such as `mv`, do not produce any visible output by default. Only when we use the verbose option (`-v`) does it show information on stdout. This showed me that not all commands behave the same way regarding output.

Finally, I practiced redirecting these streams. For example, I can send error messages to a file using `2>` so they do not appear on the screen, like in the command `ls -j 2> errors.txt`. This technique is extremely useful for logging errors and keeping the terminal clean. In a technical interview, I can clearly explain the difference between stdout and stderr and how to redirect them properly.

---

**Key concepts & commands to remember:**

- `1>` or `>` → Redirect standard output (stdout)
- `2>` → Redirect standard error (stderr)
- `&>` → Redirect both stdout and stderr
- `command -v` → Verbose mode (shows output)

---
