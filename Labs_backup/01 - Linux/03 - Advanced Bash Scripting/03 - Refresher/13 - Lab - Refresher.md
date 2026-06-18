---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Lab - Refresher
Fecha de Inicio: 2026-05-22
Dificultad: Intermedio-Alto
Tareas Totales: "8"
tags:
  - Advanced-Bash-Scripting
---
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito |
| :--------- | :----- | :---- |
| `22/05/26` | 20 min | 50 %  |
|            |        |       |

[[Advanced Bash Scripting]]

---

In this lab, I deepened my understanding of guard clauses in Bash scripting. A guard clause is a defensive technique used at the beginning of a script or function to check for invalid or missing conditions early. In this case, I added a guard clause to verify if the first command-line argument (`project`) was provided. If it was empty, the script now prints a clear error message and exits with status 1. This follows the Linux philosophy of failing fast and being explicit, which prevents the script from continuing with unexpected or dangerous behavior.

I also learned how to handle optional arguments properly. While the branch name is optional (since Git uses a default branch), I modified the script so that the `git checkout` command only runs if a branch is actually passed. Later, I improved error handling using the `||` operator as a one-liner guard clause. This technique allows the script to detect when a branch doesn’t exist, display a proper error message, and immediately exit without counting files from the wrong branch. These changes made the script much more reliable and user-friendly.

This exercise taught me the importance of writing robust and defensive scripts. Good scripts should validate input, handle errors gracefully, and avoid producing misleading results. In a technical interview, I can confidently explain how guard clauses improve script quality, prevent bugs, and make code easier to maintain — skills that are highly valued when working with automation and production environments.

---

**Key concepts & techniques to remember:**

- `if [[ -z "${var}" ]]` → Guard clause for empty values
- `if [[ ! -z "${var}" ]]` → Check if variable has a value
- `command || { echo "Error message"; exit 1; }` → One-liner error handling
- `chmod u+x script.sh` → Make script executable

---

**Nivel de dificultad:** Intermedio Alto

This lab is more practical and requires logical thinking to improve script behavior. It’s an excellent exercise for real-world Bash scripting. 

Would you like me to adjust anything?