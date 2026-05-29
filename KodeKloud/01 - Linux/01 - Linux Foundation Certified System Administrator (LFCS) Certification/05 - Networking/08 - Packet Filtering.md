---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Lab - Packet Filtering
Fecha de Inicio: 2026-04-20
Dificultad: Intermedio-Baja
Tareas Totales: "10"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `20/04/2026` | 20 min | 40 %  |               |
| `18/05/2026` | 20 min | 50 %  |               |
| `29/05/2026` | 10 min | 100 % |               |
|              |        |       |               |


---

[[Laboratorios del LFCS]]



Throughout this lab, I've come to understand that managing a firewall isn't merely about executing commands—it's about grasping the fundamental principle of least privilege, which is the backbone of Linux security philosophy. When I enabled `ufw` and systematically configured port access, I wasn't just following steps; I was implementing a defense-in-depth strategy where every single rule serves a purpose. Each decision to allow or deny traffic represents a conscious act of protecting the system from unnecessary exposure. This mindset taught me that a sysadmin must always think upstream: _Why does this service need this port?_ rather than _Which port should I open?_ The ability to visualize how traffic flows through your rules and predict unintended consequences is what separates someone who knows commands from someone who truly understands system security.

What struck me most was recognizing the criticality of rule ordering. In Question 10, when I discovered that a deny rule placed after an allow rule becomes useless, I realized that infrastructure isn't forgiving—a single misplaced configuration can silently undermine your entire security posture. This experience reinforced a core Linux principle: _visibility and predictability_. By using `ufw status numbered`, I learned to verify every change, understanding that in production environments, one misconfigured rule could expose thousands of users to risk. This deliberate approach to validation, testing each modification before moving forward, is the discipline that Linux demands from those who steward critical systems.

The deeper lesson here is that firewall management is ultimately about _trust boundaries_—deciding not just what traffic to allow, but _from where_ and _to where_. When I configured rules for specific IP ranges like `10.11.12.0/24` and individual IPs like `207.45.232.181`, I was implementing network segmentation, a principle that goes far beyond syntax. A true systems administrator understands that every rule is a statement about your infrastructure's architecture. This lab forced me to think like a security architect rather than a technician, understanding that Linux systems demand this level of intentionality. Moving forward in a sysadmin role, I'll carry this principle: _every configuration decision should be able to withstand the question "why is this rule here?"_

---

## **Commands Executed in This Lab**

Enable firewall and configure port-based access rules using `ufw` (Uncomplicated Firewall):

```bash
# (activate firewall with default deny policy)
sudo ufw enable
```

  ```bash
# (permit SSH access)
sudo ufw allow 22  
  ```
  
  ```bash
# (permit HTTP traffic)
sudo ufw allow 80  
  ```

```bash
# (permit DNS over TCP)
sudo ufw allow 53/tcp
```

 ```bash
 # (block HTTPS traffic)
 sudo ufw deny 443/tcp 
 ```
 
```bash
# (remove previous deny rule)
sudo ufw delete 443/tcp 
```

sudo ufw allow from 207.45.232.181` (whitelist specific IP address)
- `sudo ufw allow from 10.11.12.0/24` (whitelist network subnet)
- `sudo ufw status numbered` (display all rules with line numbers for management)
- `sudo ufw insert 1 deny from 10.0.0.19`   (reorder rule to correct priority)

---












