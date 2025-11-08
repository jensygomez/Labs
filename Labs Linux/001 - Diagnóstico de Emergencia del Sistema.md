# 🚀 **Laboratorio: "Diagnóstico de Emergencia del Sistema"**

## 🎯 **Escenario del Reto**

**¡Alerta, Jensy!** Eres el Administrador de Sistemas de nivel 1 en DataTech Corp. Acaban de reportar que el servidor principal presenta fallas intermitentes después de un reinicio de emergencia.

El equipo de soporte necesita un **reporte técnico inmediato** con el estado actual del sistema para identificar posibles problemas. Tienes **15 minutos** para generar un diagnóstico completo.

----------

## 🎯 **Tu Misión**

Crear un archivo de diagnóstico llamado `system_diagnostic_report.txt` que contenga:
-   ✅ Identidad del usuario ejecutando el diagnóstico
    
-   ✅ Versión del kernel y arquitectura del sistema
    
-   ✅ Tiempo de actividad desde el último reinicio
    
-   ✅ Estado de la memoria RAM y swap
    
-   ✅ Espacio disponible en discos
    
-   ✅ Configuración de interfaces de red
    

----------

## 🔑 **Comandos Clave para tu Investigación**

### **Comando de INICIO del laboratorio:**


    docker run -it --name system-practice ubuntu:22.04 /bin/bash

### **Dentro del contenedor - PREPARACIÓN:**


    apt-get update && apt-get install -y iproute2 net-tools
    mkdir -p /home/user/project
    cd /home/user/project

### **Tu kit de herramientas de diagnóstico:**


    whoami                    # Identidad del usuario
    uname -a                  # Información del kernel 
    uptime                    # Tiempo de actividad
    free -h                   # Estado de memoria
    df -h                     # Espacio en discos
    ip addr show              # Interfaces de red

----------

## 📋 **Instrucciones Paso a Paso**

### **Fase 1: Acceso al Sistema**


# Conéctate al servidor problemático

    docker run -it --name system-practice ubuntu:22.04 /bin/bash

### **Fase 2: Preparar el Entorno**


# Actualizar herramientas del sistema

    apt-get update && apt-get install -y iproute2 net-tools

# Crear área de trabajo para el reporte

    mkdir -p /home/user/project

    cd /home/user/project

### **Fase 3: Generar el Diagnóstico** ⚡

**Ejecuta estos comandos en secuencia:**


# 1. Encabezado del reporte

    echo "=== DIAGNÓSTICO DE EMERGENCIA - DATATECH CORP ===" > system_diagnostic_report.txt
    echo "Fecha: $(date)" >> system_diagnostic_report.txt
    echo "================================================" >> system_diagnostic_report.txt
    echo "" >> system_diagnostic_report.txt

# 2. Identidad del usuario

    echo "🔐 USUARIO EJECUTANDO DIAGNÓSTICO:" >> system_diagnostic_report.txt
    whoami >> system_diagnostic_report.txt
    echo "" >> system_diagnostic_report.txt

# 3. Información del kernel

    echo "🐧 INFORMACIÓN DEL KERNEL:" >> system_diagnostic_report.txt
    uname -a >> system_diagnostic_report.txt
    echo "" >> system_diagnostic_report.txt

# 4. Tiempo de actividad

    echo "⏰ TIEMPO DE ACTIVIDAD:" >> system_diagnostic_report.txt
    uptime >> system_diagnostic_report.txt
    echo "" >> system_diagnostic_report.txt

# 5. Estado de memoria

    echo "💾 USO DE MEMORIA:" >> system_diagnostic_report.txt
    free -h >> system_diagnostic_report.txt
    echo "" >> system_diagnostic_report.txt

# 6. Espacio en discos

    echo "💿 ESPACIO EN DISCOS:" >> system_diagnostic_report.txt
    df -h >> system_diagnostic_report.txt
    echo "" >> system_diagnostic_report.txt

# 7. Interfaces de red

    echo "🌐 INTERFACES DE RED ACTIVAS:" >> system_diagnostic_report.txt
    ip addr show >> system_diagnostic_report.txt

### **Fase 4: Verificar y Entregar**


# Revisa tu reporte completo

    cat system_diagnostic_report.txt

# Entrega el diagnóstico al equipo

    echo "✅ DIAGNÓSTICO COMPLETADO - Reporte listo para análisis"

----------

## 📊 **Ejemplo de Salida Esperada**


=== DIAGNÓSTICO DE EMERGENCIA - DATATECH CORP ===
Fecha: Mon Dec 11 14:45:30 UTC 2023
================================================

🔐 USUARIO EJECUTANDO DIAGNÓSTICO:
root

🐧 INFORMACIÓN DEL KERNEL:
Linux server-datatech 5.15.0-122-generic #132-Ubuntu SMP x86_64 GNU/Linux

⏰ TIEMPO DE ACTIVIDAD:
 14:45:30 up 8 min,  1 user,  load average: 0.15, 0.08, 0.03

💾 USO DE MEMORIA:
              total    used    free  shared  buff/cache   available
Mem:          1.9Gi    450Mi  1.1Gi   2.0Mi       350Mi        1.3Gi
Swap:         1.0Gi    0B     1.0Gi

💿 ESPACIO EN DISCOS:
Filesystem      Size  Used Avail Use% Mounted on
overlay          30G   15G   14G  52% /

🌐 INTERFACES DE RED ACTIVAS:
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 
    inet 127.0.0.1/8 scope host lo
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0

----------

## 🏆 **Criterios de Éxito**

-   Reporte generado en `~/project/system_diagnostic_report.txt`
    
-   Todas las 6 secciones completas con datos reales
    
-   Formato legible con separadores y títulos
    
-   Comandos ejecutados correctamente sin errores
    
-   Información técnica precisa y actual
    

----------

## 💡 **Consejos Profesionales**

-   Usa `>>` en lugar de `>` para agregar contenido sin sobrescribir
    
-   Verifica cada comando antes de agregarlo al reporte
    
-   Los emojis ayudan a hacer el reporte más legible en situaciones de estrés
    
-   ¡Cada dato cuenta en una emergencia!
    

----------

## 📂 **Para Guardar tu Trabajo**


# En una NUEVA terminal (fuera del contenedor)

    docker cp system-practice:/home/user/project/system_diagnostic_report.txt ./

----------

**¿Listo para el desafío, Jensy?** ⚡ El equipo cuenta contigo para este diagnóstico crítico.

> **⏰ Tiempo estimado:** 15 minutos  
> **📁 Archivo de salida:**  `system_diagnostic_report.txt`  
> **🎯 Dificultad:** Principiante/Intermedio






