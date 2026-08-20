======================================================================
OPS-1042 - INCIDENT - P1
======================================================================
REPORTADO POR: Script de monitoreo continuo (client)   HORA: 03:14 AM
RESUMEN: app-backend DOWN en fleet tras mantenimiento nocturno
======================================================================
DESCRIPCION:
Alerta automática: el script de tráfico continuo del cliente reporta
errores 502 esporádicos contra la VIP (10.10.10.100). El ping ICMP a
los 3 nodos de la flota de aplicación (app01/app02/app03) es exitoso
en los tres. El mantenimiento programado de anoche incluyó un
reinicio de kernel en toda la flota, junto con un playbook de
hardening que estandarizó el puerto de escucha de Apache a 8099 en
los tres nodos (nuevo estándar corporativo de puertos). El
balanceador (HAProxy) está redirigiendo tráfico a los nodos sanos,
pero el cliente reporta lentitud intermitente porque la flota está
operando con capacidad reducida (2 de 3 nodos).

NOTAS DEL TURNO ANTERIOR (L1 nocturno):
"Reboot post-mantenimiento OK en los 3 nodos, todos responden ping y
SSH. Vi una alarma de 'chronyd' con drift alto reiniciándose un par
de veces en uno de los nodos, lo revisé pero ya se estabilizó solo --
parece el mismo comportamiento que ya reportamos en OPS-891 (tema de
NTP conocido, sin relación con app-backend). No alcancé a revisar el
estado real de Apache en cada nodo individualmente, dejo el ticket
abierto para el próximo turno."

IMPACTO AL CLIENTE: Latencia intermitente y errores 502 esporádicos
en checkout, atribuibles a que HAProxy sólo tiene 2 de 3 backends
sanos disponibles.

======================================================================
CRITERIO DE RESOLUCIÓN:
======================================================================
1. Primero verificar desde el lado del cliente:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   Guarda la salida en un bloc de notas para comparar al final.

2. Identificar la causa manualmente vía CLI (no ejecutes aún el
   playbook de recuperación). Sospecha del nodo app01/02/03 que no
   esté respondiendo en el puerto correcto detrás de HAProxy.
   Pistas útiles: `systemctl status httpd`, `journalctl -u httpd -n 50`,
   `ausearch -m avc -ts recent`, `ss -tlnp | grep httpd`.

3. Resuélvelo manualmente en caliente sobre el nodo afectado
   (sin usar los playbooks de este incidente) y confirma desde el
   cliente:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   Compara contra el resultado del paso 1.

4. Restablece el sistema a su estado pre-incidente con:
   "Recuperacion al estado anterior del incidente.yml"

5. Inyecta nuevamente el incidente con:
   "Apache no arranca tras mantenimiento.yml"

6. Esta vez resuélvelo de forma 100% automatizada e idempotente:
   escribe un playbook de remediación (nuevo, tuyo) que detecte y
   corrija la causa raíz sin intervención manual, y que no falle si
   se ejecuta contra un nodo que ya está sano.

======================================================================
