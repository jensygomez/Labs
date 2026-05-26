---
Curso: Advanced Bash Scripting
Modulo: Streams
Tema: File descriptors
Fecha: 2026-05-22
Estado: completado
Dificultad: Básico Bajo
tags:
  - Advanced-Bash-Scripting
---
[[Advanced Bash Scripting]]


---

In this lesson, I learned about **file descriptors** in Linux. File descriptors are numbers that the system uses to identify open files, streams, and input/output sources. The three most important ones are: **0** for Standard Input (stdin), **1** for Standard Output (stdout), and **2** for Standard Error (stderr). From number 3 onwards, the system assigns new numbers to other files, sockets, or devices that a process opens.

The instructor used a very helpful analogy: imagine going to a big library and asking the librarian for a specific book. The librarian uses a reference number to quickly find and give you the right book. In the same way, Linux uses file descriptors as reference numbers to manage input and output efficiently. This system allows processes to read from and write to multiple sources at the same time in a clean and organized way.

Understanding file descriptors is important even at a basic level because it helps me better understand how redirection (`>`, `2>`, `<`) and pipes work behind the scenes. In more advanced Bash scripting and system administration, this knowledge becomes essential when working with logs, network connections, or complex scripts. In a technical interview, I can explain that file descriptors are the foundation of how Linux handles all input and output operations.

---

**Key concepts to remember:**

- **0** → stdin (Standard Input)
- **1** → stdout (Standard Output)
- **2** → stderr (Standard Error)
- File descriptors starting from **3** → Other open files and sockets

---
