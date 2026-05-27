---
Curso: 100 Days of DevOps
Tema: Deploying PostgreSQL
Fecha: 2026-05-27
Dificultad: Básico Medio
Completado: true
tags:
  - DevOps
---
[[Menu 100 Days of DevOps]]



PostgreSQL is a highly robust, enterprise-grade object-relational database management system designed to handle complex workloads with exceptional reliability. Unlike other database systems, it manages security through "Roles" (which encompass both users and groups) and completely isolated environments known as "Databases." Within the Linux ecosystem, PostgreSQL integrates deeply with system-level authentication. This means I had to initially assume the identity of the operating system's `postgres` administrative user to interact with the interactive terminal and manage internal resources seamlessly.

To successfully fulfill this requirement, I first navigated the corporate infrastructure via SSH, transitioning from the secure staging environment (`jump-host`) to the dedicated database server (`stdb01`). Once inside the correct host, I escalated privileges to the `postgres` system user and accessed the `psql` interactive CLI. Within the database engine, I provisioned a new dedicated user with specific credentials and created an isolated database container for the application. Finally, I bridged these two entities by explicitly granting all privileges over that specific database to the new user, ensuring the Nautilus application could operate autonomously within its own scope.

This challenge perfectly illustrates a core DevOps practice: adhering to the **Principle of Least Privilege** and conducting rigorous **State Verification**. Rather than granting the application overarching superuser access, I isolated its permissions so that `kodekloud_cap` only commands its respective database, safeguarding the rest of the cluster. Furthermore, a strong infrastructure mindset dictates that we never assume success; utilizing meta-commands like `\l` and `\du` allowed me to audit the environment and guarantee system consistency before marking the deployment as complete.

### Commands Executed


```
# Establishing a secure remote connection to the database server
ssh peter@stdb01

# Switching to the PostgreSQL administrative system user
sudo -i -u postgres

# Launching the interactive database terminal
psql
```

**2. Operaciones dentro del Motor (PostgreSQL CLI)**



```
-- Provisioning the new database user with explicit credentials
CREATE USER kodekloud_cap WITH PASSWORD 'GyQkFRVNr3';

-- Creating the dedicated database for the application
CREATE DATABASE kodekloud_db9;

-- Granting full administrative privileges to the user on the new database
GRANT ALL PRIVILEGES ON DATABASE kodekloud_db9 TO kodekloud_cap;

-- Auditing and verifying the applied changes
\du
\l

-- Gracefully exiting the database CLI
\q
```

**3. Salida del Servidor**



```
# Exiting the administrative shell
exit
```

