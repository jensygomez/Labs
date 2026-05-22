---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: /dev/null
Fecha: 2026-05-22
Estado: completado
Dificultad: Básico Bajo
tags:
  - Advanced-Bash-Scripting
---
[[Advanced Bash Scripting]]


---

In this lesson, I learned more advanced techniques for handling and redirecting both **stdout** and **stderr**. I practiced how to send both outputs to the same destination using `2>&1`. The order is very important: `2>&1` means “redirect stderr (2) to wherever stdout (1) is currently going.” I also learned the shorthand `&>` which redirects both stdout and stderr to a file at the same time (for example: `command &> file.txt`).

The instructor explained the correct use of the ampersand symbol (`&`) and how its position changes the meaning. I saw that `>& file.txt` is not the recommended way and can be confusing, while `&>` is cleaner and more commonly used. We also practiced the difference between `ls -z 2>&1 > file.txt` and `ls -z > file.txt 2>&1`, which helped me understand that the order of redirections matters.

Finally, I learned one of the most useful patterns in Linux: `> /dev/null 2>&1`. This command discards both normal output and error messages by sending them to `/dev/null` (a special device that throws away everything). This technique is very common in scripts when we want to run commands silently.

---

**Key concepts & commands to remember:**

- `command &> file.txt` → Redirect both stdout and stderr to a file
- `command > file.txt 2>&1` → Redirect stdout to file, then stderr to stdout
- `command 2>&1 > file.txt` → Different order (usually not what you want)
- `> /dev/null 2>&1` → Discard all output and errors (silent execution)

---

