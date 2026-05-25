---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Lab 1 - Streams
Fecha de Inicio: 2026-05-25
Dificultad:
Tareas Totales: "8"
tags:
  - Advanced-Bash-Scripting
---
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito |
| :--------- | :----- | :---- |
| `25/05/26` | 15 min | 50 %  |
|            |        |       |

[[Advanced Bash Scripting]]

---


---

During this laboratory, I strengthened my knowledge of streams and file descriptor redirection in Bash scripting. I learned how to properly manage standard output (stdout) and standard error (stderr) using file descriptors. This practice helped me understand how to redirect each stream separately or combine them, which is essential for writing clean and professional scripts.

I also worked on practical exercises that involved creating scripts and modifying their output behavior. I practiced sending error messages to stderr instead of stdout, redirecting outputs to different files, and silencing both streams using `/dev/null`. Additionally, I learned the importance of the correct order when using redirections like `2>&1`, which prevents common mistakes in script development.

This lab reinforced the Linux philosophy of having full control over how a program communicates with the user and the system. In a technical interview, I can clearly explain the difference between stdout and stderr, how to redirect them effectively, and why these techniques are important for automation and troubleshooting. These skills show that I can write more reliable and maintainable Bash scripts for real production environments.

---

**Key commands & techniques to remember:**

- `command > stdout.txt 2> stderr.txt`
- `echo "Error message" >&2`
- `command > /dev/null 2>&1`
- `command 2>&1 > file.txt`

---

¿Quieres que ajuste algo más?