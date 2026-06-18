---
Curso: Advanced Bash Scripting
Modulo: Streams
Tema: Lab 2 - Streams
Fecha de Inicio: 2026-05-26
Dificultad: Avanzado-Medio
Tareas Totales: "8"
tags:
  - Advanced-Bash-Scripting
---
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito |
| :--------- | :----- | :---- |
| `25/05/26` | 30 min | 25 %  |
|            |        |       |

[[Advanced Bash Scripting]]


---



During this technical assessment, I moved beyond simple command execution into the deeper mechanics of how Bash manages input/output streams and file manipulation at the operating system level. Rather than viewing Bash as merely a command interpreter, I learned that it is fundamentally a text processing engine built on file descriptor abstraction—a principle critical to understanding Linux system administration. When I used `Heredoc Strings` to embed multi-line input blocks within commands, I grasped that this syntax enables seamless automation of remote operations: `ssh -T bob@node01 <<EOF` allowed me to execute complex workflows on remote servers without manual interaction, which is the foundation of infrastructure automation. More critically, I understood that `Heredocs` preserve text structure and whitespace precisely, making them superior to string concatenation for configuration files, SQL scripts, and multi-line inputs—a distinction that separates fragile scripts from production-grade automation.

The second dimension involved orchestrating Bash against containerized services, which required understanding layered abstraction. When I executed SQL queries against a PostgreSQL container using `sudo docker exec my_postgres_container bash -c "psql -U postgres -d employees << EOF"`, I was essentially piping input through three abstraction layers: the host Bash shell, the Docker container boundary, and the PostgreSQL client. This taught me that Bash is not just a scripting language but the universal orchestration interface in Linux—capable of bridging applications across containers, remote servers, and complex workflows. I learned that output redirection from `Heredoc` blocks (`cat <<EOF > file.txt`) enables infrastructure-as-code patterns, allowing me to generate configuration files, SQL schemas, and initialization scripts programmatically. This is fundamentally different from manual editing; it means infrastructure becomes reproducible and version-controllable.

The final challenge—manipulating file content using low-level file descriptors—revealed the deepest layer of Bash's power and why sysadmins must understand POSIX I/O. When I assigned a file descriptor with `exec 8<> /home/bob/kodekloud/abc.txt`, read specific byte positions with `read -n 3 <& 8`, and wrote back with `echo "d" >& 8`, I was directly interfacing with the kernel's file table—the same mechanism underlying all Linux I/O operations. This is not about knowing syntax; it is about understanding that files in Linux are streams, and streams can be manipulated at arbitrary positions using file descriptor arithmetic. When I corrected the employee email from `kriti shreshtha@company.com` to `kriti.shreshtha@company.com` using file descriptor manipulation, I demonstrated that production problems—data corrections, log file editing, configuration patching—can be solved with surgical precision without rewriting entire files. A competent Linux engineer thinks in terms of streams, file descriptors, and I/O redirection because these abstractions enable automation that scales from single machines to thousands of servers.

---

## **💻 Comandos Clave**

```bash
# === HEREDOC STRINGS ===
# Imprime contenido multi-línea a terminal
cat <<EOF
Hello
World
From
Heredocs
EOF

# Ejecuta comando remoto usando Heredoc
ssh -T bob@node01 <<EOF
ls
find /home/bob/docker_files -name "schema.sql"
EOF

# Redirige salida de Heredoc a archivo
cat <<EOF > hello_world.txt
Hello
World
From
Multiple
Lines
EOF

# Copia contenido remoto a archivo local vía Heredoc y redirección
ssh bob@node01 "cat <<EOF > /tmp/init.sql
$(cat /path/to/schema.sql)
EOF"

# === DOCKER + HEREDOC + SQL ===
# Ejecuta query SQL en contenedor PostgreSQL via Heredoc
sudo docker exec my_postgres_container bash -c "psql -U postgres -d employees << EOF
SELECT * FROM employee;
EOF"

# Redirige salida de query SQL a archivo en servidor remoto
ssh bob@node01 "sudo docker exec -i my_postgres_container bash -c \"psql -U postgres -d employees <<EOF
\pset tuples_only on
SELECT email FROM employee where first_name='Kriti';
EOF\" > /home/bob/kodekloud/employee1_email.txt"

# === FILE DESCRIPTORS ===
# Asignar file descriptor a un archivo (lectura/escritura)
exec 8<> /home/bob/kodekloud/abc.txt

# Leer N caracteres desde file descriptor
read -n 3 <& 8

# Escribir a file descriptor en posición actual
echo "d" >& 8

# Cerrar file descriptor
exec 8>&-

# Verificar contenido después de manipulación
cat /home/bob/kodekloud/abc.txt

# === FLUJO COMPLETO: CORREGIR EMAIL EN ARCHIVO ===
exec 8<> /home/bob/kodekloud/employee1_email.txt
read -n 5 <& 8        # Lee "kriti" (posición 0-4)
echo "." >& 8         # Inserta punto en posición 5
exec 8>&-
cat /home/bob/kodekloud/employee1_email.txt  # Verifica: "kriti.shreshtha@company.com"
```

---


