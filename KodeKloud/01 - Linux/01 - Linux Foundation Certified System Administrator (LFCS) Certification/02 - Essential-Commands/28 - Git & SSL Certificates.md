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
[[Laboratorios del LFCS]]

---


**Here’s your summary in Advanced B2 English, first person singular:**

---

In this lab, I worked with two important tools for system administrators: OpenSSL and Git. I learned how to generate a strong 4096-bit RSA private key along with a Certificate Signing Request (CSR) in a single command, and how to create a self-signed certificate with a specific validity period. I also practiced inspecting an existing certificate to find its Common Name. These skills are essential because SSL certificates are critical for securing web servers and services in any professional Linux environment.

On the Git side, I practiced real-world version control workflows. I staged only specific files (.cpp), created commits with proper messages, created and deleted branches, and merged branches. I also learned how to identify the file modified in the latest commit. These operations helped me understand Git’s branching model and how to solve common problems, such as being unable to delete a branch because it is currently active.

This laboratory gave me a solid combination of security and collaboration skills. In a technical interview, I can confidently explain how to generate and inspect certificates using OpenSSL, and how to perform common Git operations like staging, committing, branching, and merging. These are fundamental abilities that show I can manage both system security and code versioning effectively in real production environments.

---

**Key commands to remember:**

- `openssl req -newkey rsa:4096 -keyout priv.key -out cert.csr`
- `openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout priv.key -out kodekloud.crt`
- `openssl x509 -in my.crt -noout -subject`
- `git add *.cpp`
- `git commit -m "Added C++ files"`
- `git branch testing`
- `git branch -D testing`
- `git merge documentation`
- `git push origin master`
- `git clone <repository-url>`

---
