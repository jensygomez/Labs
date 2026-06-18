---
Curso: 100 Days of DevOps
Tema: "Day 18: Install and Configure DB Server"
Fecha: 2026-05-29
Dificultad: Básico Medio
Completado: true
tags:
  - DevOps
---
[[Menu 100 Days of DevOps]]




MariaDB is a powerful, community-developed relational database management system that originated as a prominent fork of MySQL, designed to maintain open-source consistency and robust data integrity. A defining characteristic of MariaDB is its host-based authentication architecture, which strictly couples a user's identity with their origin of connection (`'user'@'host'`). Operating within RHEL-based corporate environments requires managing the software lifecycle through standard package managers and initializing the background process using system virtualization tools, ensuring that the database engine handles transaction workloads reliably and securely.

To satisfy the engineering requirements, I initiated a secure SSH session from the centralized management server (`jump-host`) to establish connectivity with the dedicated database node (`stdb01`). Once inside the target machine, I leveraged elevated systems privileges to download and install the database server package, subsequently utilizing initialization managers to activate the engine and configure its persistence across potential system reboots. Upon entering the native administrative command-line interface, I established an isolated data environment by creating a dedicated database container tailored specifically for the incoming deployment.

Adhering to strict infrastructure security paradigms, I executed an optimized administration query that simultaneously provisioned a localized database user and assigned a secure, non-human-readable credential string. By explicit instruction, I anchored this user's scope of influence to the local loopback interface, shielding it from external network vectors while granting it total functional authority over its designated schema. To finalize the deployment, I forced a runtime cache flush to actively commit the authentication tables and verified the environmental state changes using internal auditing tools before terminating the administrative pipeline.

### Commands Executed

**1. Operating System & Service Management (Linux Shell)**

Bash

```
# Establishing a secure remote connection to the database server
ssh peter@stdb01

# Installing the MariaDB server package via the native package manager
sudo dnf install -y mariadb-server

# Starting the database background service in volatile memory
sudo systemctl start mariadb

# Configuring the system engine to ensure persistence on system reboots
sudo systemctl enable mariadb

# Auditing the operational state of the database daemon
sudo systemctl status mariadb

# Accessing the administrative database interface with elevated rights
sudo mysql
```

**2. Internal Database Configurations (MariaDB CLI)**

SQL

```
-- Creating the dedicated database container for the application
CREATE DATABASE kodekloud_db6;

-- Simultaneously provisioning the user, restricting its host, and granting full privileges
GRANT ALL PRIVILEGES ON kodekloud_db6.* TO 'kodekloud_aim'@'localhost' IDENTIFIED BY 'BruCStnMT5';

-- Reloading the internal access tables to immediately apply all changes
FLUSH PRIVILEGES;

-- Auditing and verifying the applied grants and structural state changes
SHOW DATABASES;
SHOW GRANTS FOR 'kodekloud_aim'@'localhost';

-- Gracefully disconnecting from the database command interpreter
EXIT;
```

**3. Infrastructure Disconnection**

Shell

```
# Closing the active SSH stream and returning to the staging node
exit
```