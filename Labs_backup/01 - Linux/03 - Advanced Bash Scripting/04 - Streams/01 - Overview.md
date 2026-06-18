---
Curso: Advanced Bash Scripting
Modulo: Streams
Tema: Overview
Fecha: 2026-05-22
Estado: completado
Dificultad: Básico Bajo
tags:
  - Advanced-Bash-Scripting
---
[[Advanced Bash Scripting]]




---

In this module, I learned about **streams** in Linux, specifically Standard Output (stdout) and Standard Error (stderr). I understood that every command produces two types of output: normal output (stdout) which is represented by file descriptor **1**, and error messages (stderr) represented by file descriptor **2**. For example, when I run a correct command like `ls`, the result goes to stdout, but when I use an invalid option such as `ls -j`, the error message goes to stderr. This separation is very important because it allows me to handle normal results and errors differently.

I also practiced how to redirect and combine these streams using operators like `>`, `2>`, and the pipe `|`. This gives me fine control over where the output and errors go — for instance, saving successful results to a file while sending errors to another file or ignoring them completely. Understanding streams reflects the Linux philosophy of treating everything as files and giving the user powerful tools to manipulate data flow efficiently.

This knowledge is fundamental for writing clean and professional Bash scripts. In real environments and technical interviews, I can explain how to properly redirect stdout and stderr, which helps prevent messy output and makes automation scripts more reliable and easier to debug.

---

**Key concepts & commands to remember:**

- `1>` or `>` → Redirect standard output (stdout)
- `2>` → Redirect standard error (stderr)
- `&>` → Redirect both stdout and stderr to the same place
- `|` (pipe) → Send output from one command to another

---
