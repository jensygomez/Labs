---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Git & SSL Certificates
Fecha de Inicio: 2026-05-14
Dificultad: Intermedio-Baja
Tareas Totales: "10"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito |
| :----------- | :----- | :---- |
| `14/05/2026` | 42 min | 10 %  |
| `24/05/2026` | 20 min | 2 0%  |
| `03/06/2026` | 30 min | 30 %  |
[[Laboratorios del LFCS]]


---

In this lab, I worked with two important tools for system administrators: OpenSSL and Git. I learned how to generate a strong 4096-bit RSA private key along with a Certificate Signing Request (CSR) in a single command, and how to create a self-signed certificate with a specific validity period. I also practiced inspecting an existing certificate to find its Common Name. These skills are essential because SSL certificates are critical for securing web servers and services in any professional Linux environment.

On the Git side, I practiced real-world version control workflows. I staged only specific files (.cpp), created commits with proper messages, created and deleted branches, and merged branches. I also learned how to identify the file modified in the latest commit. These operations helped me understand Git’s branching model and how to solve common problems, such as being unable to delete a branch because it is currently active.

This laboratory gave me a solid combination of security and collaboration skills. In a technical interview, I can confidently explain how to generate and inspect certificates using OpenSSL, and how to perform common Git operations like staging, committing, branching, and merging. These are fundamental abilities that show I can manage both system security and code versioning effectively in real production environments.

---

```bash
# ==========================================
# SECCIÓN 1: OPENSSL & CERTIFICADOS SSL
# ==========================================

# Q1: Genera una clave privada RSA de 4096 bits cifrada con contraseña y un CSR en un solo comando usando la bandera --passout.
openssl req -new -newkey rsa:4096 -keyout priv.key -out cert.csr -passout pass:kkloud -subj "/CN=localhost"

# Q2: Crea un certificado autofirmado válido por 365 días, con una clave sin cifrar (--noenc) y asignando el Common Name solicitado.
openssl req -x509 -newkey rsa:2048 -noenc -days 365 -keyout priv.key -out kodekloud.crt -subj "/CN=kodekloud.com"

# Q3: Inspecciona el certificado en formato X509 de manera legible (--text), extrae el Common Name (CN) y guarda la respuesta en un comentario.
# Comando de validación: openssl x509 -in /home/bob/my.crt -noout -subject
# Respuesta teórica: El Common Name configurado en ese certificado de ejemplo suele ser "kodekloud.com" o similar según el laboratorio.

# ==========================================
# SECCIÓN 2: CONTROL DE VERSIONES CON GIT
# ==========================================

# Q4: Cambia al directorio del repositorio, prepara solo los archivos .cpp para el commit y registra los cambios con el mensaje exacto.
cd /root/kode && git add *.cpp && git commit --message="Added C++ files"

# Q5: Crea una nueva rama de desarrollo llamada "testing" para aislar nuevas características.
git branch testing

# Q6: Fuerza la eliminación de la rama "testing" usando el parámetro --force para evadir el bloqueo de seguridad de cambios no fusionados.
git branch --delete --force testing

# Q7: Muestra únicamente el nombre del archivo que fue modificado en el último commit ejecutado en el repositorio (--max-count=1).
git log --max-count=1 --name-only --pretty=format:""

# Q8: Fusiona e integra el historial de cambios de la rama "documentation" dentro de la rama activa actual (master).
git checkout master && git merge documentation

# Q9: Comando estándar para subir y sincronizar la rama local "master" hacia el servidor remoto apodado "origin".
# Comando conceptual requerido: git push origin master

# Q10: Descarga una copia completa del repositorio remoto de Git directamente en el directorio de trabajo del usuario bob.
cd /home/bob/ && git clone https://github.com/kodekloudhub/git-for-beginners-course.git

```
