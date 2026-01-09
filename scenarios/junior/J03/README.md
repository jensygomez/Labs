# LAB J03 — Network Connectivity Failure

***

## 📘 Descripción General

El **LAB J03** simula el incidente NOC más común: **"servicio web inaccesible desde clientes"**. Diseñado para **sysadmins junior (0-18 meses)**, cubre objetivos **RHCSA EX200**: `nmcli`, `firewalld`, `ip`, `ss/netstat`.

**Randomiza valores** (puertos, interfaces, IPs) generando **tickets únicos** cada ejecución. Student diagnostica con **comandos reales del examen**.

```
./ansible_wrapper.sh J03 → /tmp/J03_ticket.txt + web01 desconectado
```

***

## 🎯 Objetivos de Aprendizaje

- ✅ Diagnosticar **Layer 3/4**: IP vs puertos
- ✅ `nmcli` vs `ip` vs `ifcfg` (NetworkManager)
- ✅ `firewalld --list-all`, `--permanent`
- ✅ Secuencia: `nmcli → ip → ss → firewall`
- ✅ Verificar **cross-host**: `curl DESDE client01`

***

## 🧠 Arquitectura del Laboratorio

```
3 VMs: admin01(192.168.122.20) → web01(22) ← client01(21)
Baseline: curl client01→web01:8080 = 200 OK
Inject: 1/4 variantes rompe conectividad
Ticket: /tmp/J03_ticket.txt con valores REALES
```

**64 combinaciones únicas**: 4 variantes × 4 puertos × 4 interfaces

***

## 🧩 Estructura de Archivos

```
scenarios/junior/J03/
├── vars/
│   ├── main.yml       # interfaces, web_ports, wrong_ips
│   └── resolve.yml    # global_web_port=8080, global_interface=...
├── tasks/
│   ├── base.yml       # nginx install + nmcli UP + firewall
│   └── show_ticket.yml # cat /tmp/J03_ticket.txt
├── inject/            # 4 fallos reales
│   ├── variant_1.yml  # firewalld remove-port
│   ├── variant_2.yml  # nmcli wrong IP
│   ├── variant_3.yml  # nmcli down  
│   └── variant_4.yml  # nginx.conf listen 9080
├── tickets/           # Plantillas dinámicas
│   ├── variant_1.yml
│   ├── variant_2.yml
│   ├── variant_3.yml
│   └── variant_4.yml
├── J03.yml            # Orquestación
└── README.md
```

***

## 🔧 Variantes Implementadas

| **#** | **Variante** | **Fallo Inyectado** | **Diagnóstico** | **Fix** | **Tiempo** |
|-------|--------------|-------------------|-----------------|---------|------------|
| **V1** | **Firewall** | `firewalld --remove-port 8080/tcp` | `firewall-cmd --list-ports` | `firewalld --add-port 8080/tcp --permanent` | **3min** |
| **V2** | **IP Errónea** | `nmcli ipv4.addresses 192.168.122.99` | `ip a`, `nmcli con show` | `nmcli con mod ipv4.addresses 192.168.122.22/24` | **4min** |
| **V3** | **Interface DOWN** | `nmcli con down Wired` | `nmcli con show` | **`nmcli con up Wired`** | **1min** |
| **V4** | **Puerto Desincronizado** | `nginx.conf listen 9080` (firewall 8080) | `ss -tuln` | `firewalld --add-port 9080/tcp` | **5min** |

***

## 🛠️ Secuencia de Diagnóstico RHCSA

```bash
# 1. RED (Layer 3)
nmcli con show                    # Interface UP?
ip a                              # IP 192.168.122.22?

# 2. SERVICIO (Layer 4)  
ss -tuln | grep :{{PUERTO}}       # nginx LISTEN?

# 3. FIREWALL
firewall-cmd --list-all           # Puerto abierto?

# 4. VERIFICAR
curl -I http://web01:{{PUERTO}}   # DESDE client01
```

***

## 🚀 Ejecución Completa

```bash
# Instructor (1 comando):
cd scenarios/junior/J03
../../engine/ansible_wrapper.sh J03

# Resultado:
✓ admin01: /tmp/J03_ticket.txt generado
✓ web01: nginx UP, conectividad ROTAcurl 
✓ client01: curl http://web01:8080 → FAIL

# Student:
ssh sysadmin-junior@192.168.122.22
cat /tmp/J03_ticket.txt
# Diagnostica → Corrige → Verifica desde client01
```

***

## 📋 Flujo Automático (5 Fases)

```
1. admin01: resolve.yml → global_web_port=8080, variant_2.yml
2. web01:  base.yml → nginx UP + red OK + curl OK
3. web01:  inject/variant_2.yml → IP=192.168.122.99
4. client01: curl → "No route to host" (VERIFICADO)
5. admin01: show_ticket.yml → /tmp/J03_ticket.txt
```

***

## 📊 Métricas NOC Realistas

| **Variante** | **% Tickets NOC** | **Dificultad Junior** | **RHCSA %** |
|--------------|------------------|----------------------|-------------|
| V3 Interface | **40%** | ⭐ Muy fácil | 20% |
| V1 Firewall | **30%** | ⭐⭐ Fácil | 25% |
| V2 IP | **20%** | ⭐⭐⭐ Medio | 20% |
| V4 Puerto | **10%** | ⭐⭐⭐⭐ Avanzado | 15% |

***

## 🧑‍🏫 Público Objetivo

- **NOC L1/L2** ← 80% tickets = estos 4 casos
- **RHCSA EX200** ← nmcli/firewalld = 25% examen
- **Junior SysAdmin** ← 0-18 meses experiencia
- **Helpdesk → L2** ← Promoción técnica

***

## 🚦 Progresión de Labs

```
J01 → Permisos/SELinux     (Local filesystem)
J02 → Systemd services     (Process management) 
J03 → Network connectivity ← **AQUÍ** (Layer 3/4)
J04 → LVM/Storage          (Disks)
J05 → Docker containers    (Containers)
```

***

## ✅ Estado del Laboratorio

```diff
✔ J03.yml                  # Orquestación
✔ vars/main.yml            # Catálogos  
✔ vars/resolve.yml         # Randomización
✔ tasks/base.yml           # nginx+red baseline
✔ tasks/show_ticket.yml    # Pendiente
✔ inject/variant_1-4.yml   # 4 fallos
✔ tickets/variant_1-4.yml  # 4 plantillas
✔ README.md                # + Este archivo
```

**J03: 95% completo → Listo para `show_ticket.yml`**

***

## 📌 Filosofía J03

> *"80% tickets NOC = 4 comandos: `nmcli ip ss firewall`"*

**"No es magia, es secuencia lógica."**

***

**Fin README.md — LAB J03**  
**`./ansible_wrapper.sh J03` → Listo para estudiantes** 🚀