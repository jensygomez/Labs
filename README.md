# 📡 **TOPOLOGÍA PURA - LAB LINUX**

## 🎯 **OBJETIVO**
Simular red empresarial con múltiples servidores y una estación de trabajo de administrador.

## 🏗️ **ESTRUCTURA BASE**

### **NAMESPACES (Total: 7)**
1. **NS-ROUTER** - Router central y firewall
2. **NS-ANSIBLE** - Estación de trabajo del administrador (PC Admin)
3. **NS-SRV** - Servidor web (Alemania)
4. **NS-DATA** - Base de datos (Búnker)
5. **NS-CLI** - Cliente (China) 
6. **NS-DEV** - Desarrollo (India)
7. **NS-MONITOR** - Monitoreo (Opcional)

### **BRIDGES (Switches virtuales)**
1. **BR-CORP** - Red corporativa principal (10.0.0.0/24)
2. **BR-DATA** - Red aislada de base de datos (10.10.0.0/24)
3. **BR-CLIENT** - Red de clientes (10.20.0.0/24)
4. **BR-SERVICES** - Red de servicios (10.30.0.0/24)

## 🔌 **CABLES (VETH PAIRS)**

### **NIVEL 1: CONEXIÓN A BR-CORP (Red Principal)**
```
NS-ROUTER      ←veth-router→      BR-CORP
NS-ANSIBLE     ←veth-ansible→     BR-CORP  
NS-SRV         ←veth-srv→         BR-CORP
NS-DEV         ←veth-dev→         BR-CORP
```

### **NIVEL 2: CONEXIONES DESDE ROUTER A REDES AISLADAS**
```
NS-ROUTER      ←veth-router-data→      BR-DATA
NS-ROUTER      ←veth-router-client→    BR-CLIENT  
NS-ROUTER      ←veth-router-services→  BR-SERVICES
```

### **NIVEL 3: SERVIDORES EN REDES AISLADAS**
```
NS-DATA        ←veth-data→         BR-DATA
NS-CLI         ←veth-cli→          BR-CLIENT
NS-MONITOR     ←veth-monitor→      BR-SERVICES
```

## 📊 **RESUMEN DE CONEXIONES**

### **Por Namespace:**

**NS-ROUTER:**
- veth-router → BR-CORP
- veth-router-data → BR-DATA  
- veth-router-client → BR-CLIENT
- veth-router-services → BR-SERVICES

**NS-ANSIBLE:**
- veth-ansible → BR-CORP

**NS-SRV:**
- veth-srv → BR-CORP

**NS-DEV:**
- veth-dev → BR-CORP

**NS-DATA:**
- veth-data → BR-DATA

**NS-CLI:**
- veth-cli → BR-CLIENT

**NS-MONITOR:**
- veth-monitor → BR-SERVICES

### **Por Bridge:**

**BR-CORP:**
- veth-router (NS-ROUTER)
- veth-ansible (NS-ANSIBLE)
- veth-srv (NS-SRV)
- veth-dev (NS-DEV)

**BR-DATA:**
- veth-router-data (NS-ROUTER)
- veth-data (NS-DATA)

**BR-CLIENT:**
- veth-router-client (NS-ROUTER)
- veth-cli (NS-CLI)

**BR-SERVICES:**
- veth-router-services (NS-ROUTER)
- veth-monitor (NS-MONITOR)

## 🌐 **DIRECCIONAMIENTO IP**

### **BR-CORP (10.0.0.0/24):**
- NS-ROUTER: 10.0.0.1
- NS-ANSIBLE: 10.0.0.50 (PC Admin)
- NS-SRV: 10.0.0.10 (Web Server)
- NS-DEV: 10.0.0.30 (Desarrollo)

### **BR-DATA (10.10.0.0/24):**
- NS-ROUTER: 10.10.0.1
- NS-DATA: 10.10.0.50 (Base de datos)

### **BR-CLIENT (10.20.0.0/24):**
- NS-ROUTER: 10.20.0.1
- NS-CLI: 10.20.0.20 (Cliente)

### **BR-SERVICES (10.30.0.0/24):**
- NS-ROUTER: 10.30.0.1
- NS-MONITOR: 10.30.0.40 (Monitoreo)

## 🎨 **DIAGRAMA VISUAL**
```
         [BR-CORP: 10.0.0.0/24]
         ┌──────┬──────┬──────┐
         ↓      ↓      ↓      ↓
    NS-ROUTER  WS-ADMIN  WEB    DEV
     10.0.0.1  10.0.0.50 10.0.0.10 10.0.0.30
         │
    ┌────┴────┬───────┬───────┐
    ↓         ↓       ↓       ↓
 [BR-DATA] [BR-CLIENT] [BR-SERVICES]
 10.10.0.0/24 10.20.0.0/24 10.30.0.0/24
    ↓           ↓           ↓
 NS-DATA      NS-CLI      NS-MONITOR
10.10.0.50   10.20.0.20   10.30.0.40
```

## 📝 **CHECKLIST DE CREACIÓN**

### **Paso 1: Crear Namespaces**
1. `ip netns add ns-router`
2. `ip netns add ns-ansible`
3. `ip netns add ns-srv`
4. `ip netns add ns-data`
5. `ip netns add ns-cli`
6. `ip netns add ns-dev`
7. `ip netns add ns-monitor`

### **Paso 2: Crear Bridges**
1. `ip link add br-corp type bridge`
2. `ip link add br-data type bridge`
3. `ip link add br-client type bridge`
4. `ip link add br-services type bridge`

### **Paso 3: Crear Veth Pairs**
1. Router a BR-CORP
2. Router a BR-DATA
3. Router a BR-CLIENT
4. Router a BR-SERVICES
5. Cada servidor a su respectivo bridge

### **Paso 4: Asignar IPs**
1. Configurar IP en interfaz de cada namespace
2. Configurar IP en interfaz del router para cada red
3. Configurar gateway en cada namespace (apuntando al router)

## ✅ **ESTADO FINAL ESPERADO**

### **Desde NS-ANSIBLE (PC Admin) puedo:**
- Ping a NS-ROUTER (10.0.0.1) ✓
- Ping a NS-SRV (10.0.0.10) ✓
- Ping a NS-DEV (10.0.0.30) ✓
- Ping a NS-DATA (10.10.0.50) ✓ (vía router)
- Ping a NS-CLI (10.20.0.20) ✓ (vía router)
- Ping a NS-MONITOR (10.30.0.40) ✓ (vía router)

### **Desde NS-CLI (China) puedo:**
- Llegar a NS-SRV (Web) ✓
- Llegar a NS-DATA (BD) ✗ (bloqueado por diseño)
- Llegar a internet ✓ (si se configura NAT)

---

**Topología limpia y lista para construir manualmente.** 🛠️