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



Throughout this lab, I've realized that configuring SSH and Squid isn't about memorizing file paths or syntax—it's about understanding the principle of **secure access gates** that every production system requires. When I disabled password authentication and enabled key-based login, I was implementing a fundamental Linux security doctrine: _never trust the weakest link in your authentication chain_. Each configuration decision—whether restricting SSH to IPv4, disabling root login, or limiting authentication attempts to four—represents a deliberate hardening strategy. This experience taught me that a systems administrator isn't just someone who edits configuration files; they're someone who understands that every parameter exists for a reason rooted in threat modeling. The shift from password-based to key-based authentication isn't a technical preference—it's a philosophical commitment to systems that are defensible by design.

What became clear when managing Squid proxy rules was that access control is fundamentally about **defining trust boundaries at the network perimeter**. When I created ACLs for `localnet` and `vpn`, then crafted `http_access` rules to allow or deny them, I wasn't just applying rules—I was implementing a network's security policy in code. The critical insight was understanding that `http_access allow localnetwork` doesn't blindly permit HTTP; it specifically allows whatever source IPs were defined in that ACL to access the proxy. This distinction matters profoundly: in production, you must know _exactly_ what each rule permits and from _where_. Blocking Facebook or managing external access required me to think like a network architect: _What traffic should flow through this proxy, and what should be stopped?_ This is the mindset that separates a technician from a systems steward.

The deeper realization is that SSH and Squid configuration are microcosms of Linux system hardening philosophy: **least privilege, explicit denial, and immutable audit trails**. By setting `MaxAuthAttempts 4`, I was preventing brute-force attacks. By managing X11 forwarding and AddressFamily settings, I was reducing the attack surface. By blocking specific domains and IP ranges through Squid, I was enforcing network policy at the proxy layer. These aren't isolated technical tasks—they're interconnected security decisions that compound to create resilient infrastructure. A true sysadmin understands that configuration management is risk management, where every line serves a defensive purpose and every change requires justification.

---
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

