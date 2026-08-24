======================================================================
TICKET ID: OPS-1070 | SEVERITY: P3 (Localized Service Degradation)
REPORTED BY: Junior DevOps Engineer & Automated Script Alerts
TIME: 09:15 AM (Assigned to L1 Day Shift)
SUMMARY: client01 no puede resolver nombres de dominio internos ni externos.
DESCRIPTION:
El script de tráfico en `client01` (10.10.10.11) está fallando. 
Además, el equipo de desarrollo reporta que no pueden hacer `curl` 
o `ssh` usando nombres de dominio (ej. `app01.lab.systech.local`) 
desde `client01`, solo funcionan las IPs directas.

Context: 
Ayer por la tarde, un becario intentó "limpiar" la configuración de 
red en `client01` porque decía que la red estaba "lenta". Tras su 
intervención, empezaron los problemas de resolución DNS.

El servidor DNS central (`dns01` - 10.10.10.20) está funcionando 
perfectamente (otros nodos resuelven sin problema).

CUSTOMER IMPACT:
Los scripts de automatización y los desarrolladores en `client01` 
no pueden usar FQDNs, rompiendo flujos de trabajo y pruebas.

RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):
1. Verificar el síntoma desde el cliente:
   - `ping app01.lab.systech.local` (¿Falla?)
   - `ping 10.10.10.31` (¿Funciona?)
   - `dig app01.lab.systech.local` (¿Qué DNS está usando?)
   - `dig @10.10.10.20 app01.lab.systech.local` (¿El servidor DNS responde?)

2. Investigar la configuración del Resolver en client01:
   - Revisar `/etc/resolv.conf`.
   - Revisar logs del sistema en busca de errores de red o DNS:
     `journalctl -u NetworkManager -n 20 --no-pager`
     `journalctl -u systemd-resolved -n 20 --no-pager`
     `grep -i "ufw block" /var/log/syslog | tail -n 10`

3. Identificar la causa raíz y el mecanismo de "override":
   - ¿Por qué si cambias `/etc/resolv.conf` manualmente, el problema 
     persiste o vuelve tras un reinicio de red?
   - Identifica qué gestor de red real está usando Ubuntu 24.04 LXC.

4. Resolver el problema de raíz (no solo el síntoma) y confirmar.

AUTOMATION CHALLENGE:
Escribe un playbook de remediación que detecte si el cliente tiene 
una configuración DNS incorrecta o siendo sobrescrita por el gestor 
de red, y que lo corrija a `10.10.10.20` de forma idempotente.
======================================================================
