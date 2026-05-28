---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Lab - Configure User Resource Limits
Fecha: 2002-04-20
Dificultad: Intermedio-Baja
Tareas Totales: "11"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `20/04/2026` | 20 min | 27 %  |               |
| `1705/2026`  | 25 min | 27 %  |               |
| `28/05/2026` | 20 min | 45 %  |               |

[[Laboratorios del LFCS]]

---
Question 1 of 11

Which of the following keywords can we use to limit the number of `processes` a user can run?

==============

Question 2 of 11

Modify the security limits file and make sure that the user called `trinity` can run no more than 30 processes in her session.  
This should be both a `hard` limit and a `soft` limit, written in a single line.

=============
Question 3 of 11

Identify all the security limits currently applied in our user's session and save them in the `/home/bob/limits` file.

  

You can use the redirection to save your command's output in a file: `[your-command] > /home/bob/limits`

===========

Question 4 of 11

Modify the `sudoers` file in such a way to allow the user called `trinity` to run any sudo command without needing to provide her password.

===============
Question 5 of 11

Modify the `sudoers` file again. Remove your previous entry for the user called `trinity` if it still exists.  
Now add a new entry that allows `trinity` to only run the `/usr/bin/mount` command with sudo.

==========


Question 6 of 11

Make changes in security limits file for user `stephen` so that he can create maximum filesize upto `4 MiB`. This should be a `hard` limit.

===========

Question 7 of 11

Set a `soft limit` of `20` processes for everyone in the `salesteam` group.

===================
Question 8 of 11

Define a policy for all the users in the `salesteam` group to run any sudo command.

===============
Question 9 of 11

Define a policy so that user `trinity` can run `sudo` commands as the user `sam`.

============
Question 10 of 11

We applied a `hard` limit of `10` processes for all the users under `developers` group, but somehow the limit isn't working. Look into the issue and fix the same.

===============
Question 11 of 11

Modify the `sudoers` file again. Remove your previous entry for the user called `trinity` if it still exists.  
Now add a new entry that allows `trinity` to run all commands with sudo, but only after entering the password.






























## Comando Ejemplo

bash

```bash
# Ver límites actuales de la sesión de un usuario
ulimit -a

# Guardar límites en archivo
ulimit -a > /home/bob/limits

# Configurar límite de procesos en limits.conf
echo "trinity hard nproc 30" >> /etc/security/limits.conf
echo "trinity soft nproc 30" >> /etc/security/limits.conf

# O en una sola línea (ambos límites)
echo "trinity nproc 30" >> /etc/security/limits.conf

# Permitir usuario en sudoers sin contraseña
echo "trinity ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Restringir a un comando específico
echo "trinity ALL=(ALL) NOPASSWD: /usr/bin/mount" >> /etc/sudoers

# Editar sudoers de forma segura
visudo
```