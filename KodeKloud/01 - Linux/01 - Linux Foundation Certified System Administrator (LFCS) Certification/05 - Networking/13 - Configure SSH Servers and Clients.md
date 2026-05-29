---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Lab - Configure SSH Servers and Clients
Fecha de Inicio: 2026-04-20
Dificultad: Intermedio-Baja
Tareas Totales: "12"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `20/04/2026` | 40 min | 9 %   |               |
| `19/05/2026` | 45 min | 16 %  |               |
| `29/05/2026` | 40 min | 50 %  |               |

[[Laboratorios del LFCS]]

---


Question 1 of 12

In what file can we edit the settings of our `SSH server`?

===============

Question 2 of 12

In a `squid proxy` server, what does this line do?  
  

```text
http_access allow localnetwork
```

  
  

**A.** It makes it accept connections from the computers in our local network.  
  
  
**B.** It lets computers in the local network use the http protocol, but not the https protocol.  
  
  
**C.** It makes it accept incoming connections from whatever was defined in the ACL named "localnetwork"  
  
  
**D.** It lets computers use the proxy server to access devices in the "localnetwork" ACL.

==========

Question 3 of 12

Edit the configuration of the `SSH server` and disable password logins.

  

Please make sure to restart the `sshd` service after making the required changes.

===========



Question 4 of 12

Edit the `system-wide` configuration of the `SSH client` and turn on `X11 forwarding`.

=============

Question 5 of 12

Install `squid` proxy server on this system and start its service.

===========

Question 6 of 12

Edit the config file of the `Squid proxy` daemon. Modify it to `deny` access to the IP addresses defined in the ACL called `localnet`.

=================
Question 7 of 12

Edit the configuration of the `Squid proxy daemon`. Add a `src` type `acl` and name it `vpn`. The IP you should use in this acl is `203.0.110.5`. Now add a new rule that tells the proxy server to `allow` access to the acl named `vpn`.

===============

Question 8 of 12

Edit the configuration of the `SSH server` and configure it to use only `IPv4` IP address family.

=============




Question 9 of 12

Edit the configuration of the `Squid proxy daemon`. Now, add a new rule that allows http access to `external`.

==============


Question 10 of 12

Edit the configuration of the `Squid proxy daemon`, and add an `acl and http access rule to block facebook.com`.

==============

Question 11 of 12

Edit the configuration of the `SSH server` and `re-enable password logins`, but `disable` the SSH login for user root.

===========

Question 12 of 12

In the configuration file of the `SSH server`, change the maximum number of authentication attempts permitted per connection to `4`.




























## Comandos de ejemplo

```bash
# Editar configuración SSH Server
sudo nano /etc/ssh/sshd_config

# Verificar y aplicar cambios
sudo sshd -t  # Test de sintaxis
sudo systemctl restart sshd

# Editar configuración SSH Client
sudo nano /etc/ssh/ssh_config

# Instalar y habilitar Squid
sudo dnf install squid -y
sudo systemctl start squid
sudo systemctl enable squid

# Editar configuración Squid
sudo nano /etc/squid/squid.conf

# Recargar configuración Squid
sudo systemctl reload squid
```

