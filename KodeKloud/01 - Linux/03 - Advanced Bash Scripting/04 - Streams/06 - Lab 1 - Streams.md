---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Lab 1 - Streams
Fecha de Inicio: 2026-05-25
Dificultad: Básico Medio
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
![[Lab 1 - Streams.mp3]]

---

During this lab, I worked extensively with Bash stream redirection and Linux file descriptors, which are fundamental for troubleshooting and operational support in production environments. I practiced separating standard output from standard error in order to improve logging visibility and isolate failures more efficiently. This is especially important when maintaining scripts that may run automatically on servers or within scheduled tasks.

I also analyzed different non-zero exit scenarios inside a Git automation script and refactored the error handling logic so that failures were correctly redirected to stderr instead of stdout. From an operational perspective, this improves debugging, monitoring accuracy, and log management, because administrators and monitoring tools can distinguish normal execution from actual failures.

One important lesson from this exercise was understanding how Linux processes streams internally and why the order of redirections matters when silencing or capturing outputs. Beyond simply executing commands, I focused on understanding the reasoning behind each redirection technique and how these practices contribute to reliability, maintainability, and troubleshooting efficiency in real Linux server environments.

---

**Key commands & techniques to remember:**

- `command > stdout.txt 2> stderr.txt`
- `echo "Error message" >&2`
- `command > /dev/null 2>&1`
- `command 2>&1 > file.txt`

---

