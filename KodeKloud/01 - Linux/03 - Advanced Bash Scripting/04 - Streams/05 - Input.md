---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Input
Fecha: 2026-05-22
Estado: completado
Dificultad: Básico Medio
tags:
  - Advanced-Bash-Scripting
---
[[Advanced Bash Scripting]]


---


---

In this lesson, I learned more about **stdin** (Standard Input) and how to control input in Linux. Stdin is the stream where a program receives data. This input can come from the keyboard, from a file using redirection (`<`), or from another command through a pipe (`|`). I saw practical examples such as `echo "juan carlos" | wc`, `./input.sh < input.txt`, and `echo "Pipeline" | ./input.sh`. These examples showed me different ways to feed information into commands and scripts.

I also practiced advanced file descriptor manipulation. We worked with a real example where an email address had a problem because of a missing dot. Using a custom file descriptor (**3**), we opened the file, read part of the content, inserted the missing dot in the correct position, and then closed the file descriptor. The commands were:

- `exec 3<> email_file.txt` (open file with read and write access)
- `read -n 4 <&3` (read 4 characters)
- `echo -n "." >&3` (write a dot)
- `exec 3>&-` (close the file descriptor)

This technique showed me how powerful and precise file descriptors can be when I need to modify files directly without using traditional tools.

---

**Key concepts & commands to remember:**

- `command < file.txt` → Redirect file as stdin
- `command1 | command2` → Pipe stdout to stdin
- `exec 3<> file` → Open file with file descriptor 3 (read + write)
- `<&3` → Read from file descriptor 3
- `>&3` → Write to file descriptor 3
- `exec 3>&-` → Close file descriptor 3

---


