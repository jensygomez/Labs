---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - File Permissions, Search for Files
Fecha: 2026-05-11
Dificultad: Intermedio-Baja
Tareas del Lab: "16"
tags:
  - Laboratorios-del-LFCS
---

## 📊 Bitácora de Intentos
|    Fecha     | Tiempo | Éxito | Task |
| :----------: | :----: | :---: | :--: |
| `11/05/2026` | 20 min | 50 %  |  16  |
| `20/05/2026` | 40 min | 75 %  |  16  |

[[Laboratorios del LFCS]]


---

**Aquí tienes el resumen en inglés, en primera persona del singular (nivel B2):**

---

In this laboratory I practiced one of the most powerful skills in Linux: searching and locating files and directories efficiently. Using the `find` command, I learned how to search by name, size, modification time, and especially by permissions. This reflects the Linux philosophy that the administrator should have full control and visibility over the entire system. Being able to quickly find files that were recently modified or that have specific permissions is something I will use almost every day as a Linux administrator.

I also worked with file permissions in more depth. I practiced changing normal permissions with `chmod`, and I applied special permissions such as setuid, setgid, and the sticky bit on directories. These special permissions are very important for security and for controlling how files and directories behave when multiple users access them. Additionally, I had to be careful with permission combinations that can cause “permission denied” errors, which helped me better understand how Linux handles access control.

This lab was excellent practice for real-world scenarios where I need to audit systems, find specific files quickly, and manage permissions securely. In a technical interview, I can confidently explain that I know how to use the `find` command with multiple conditions and that I understand both basic and special permissions. These skills show that I can solve practical problems and not just memorize commands.

---

**Key commands to remember:**

- `find /path -mmin -5`
- `find /path -perm 0777`
- `find /path -size 20M`
- `chmod u=rwx,go= directory`
- `chmod u+s,g+s,o+t directory`

---

