---
Titulo: SIMULACRO LFCS 004 — "Refuerzo y Consolidación"
Severidad: MEDIA
Ambiente: Produccion
Modulo: LFCS Complete
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-08
Script Vagrant: |-
  # -- mode: ruby --

  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    
    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['1G'] },
      { name: "node03", ip: "192.168.122.13", extra_disks: [] }
    ]
    
    nodes.each do |node|
      config.vm.define node[:name] do |node_config|
        node_config.vm.hostname = node[:name]
        
        node_config.vm.network "private_network", 
          ip: node[:ip], 
          libvirt__network_name: "mgmt-net",
          libvirt__dhcp_enabled: false
        
        node_config.vm.provider "libvirt" do |lv|
          lv.memory = 1024
          lv.cpus = 1
          lv.driver = "kvm"
          node[:extra_disks].each do |size|
            lv.storage :file, :size => size, :type => 'qcow2'
          end
        end
        
        # ── PROVISIONADO GENERAL (todos los nodos) ──
        node_config.vm.provision "shell", inline: <<-SHELL
          echo "🔧 Configurando #{node[:name]}..."
          
          # Limpiar /etc/hosts
          for host in node01 node02 node03; do
            sed -i "/$host/d" /etc/hosts
          done
          
          cat << 'HOSTS' >> /etc/hosts
  192.168.122.11 node01
  192.168.122.12 node02
  192.168.122.13 node03
  HOSTS

          # Crear usuario bob
          useradd -m -s /bin/bash bob 2>/dev/null || true
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          # Instalar herramientas básicas
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass curl
        SHELL
        
        # ── NODE02: SERVIDOR A AUDITAR ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configurando node02 para refuerzo..."
            
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nginx htop net-tools lsof
            
            # ── Crear estructura de archivos para auditoría ──
            mkdir -p /var/log/audit-app
            mkdir -p /opt/reports
            mkdir -p /opt/backups
            
            # Crear archivos de diferentes tamaños y fechas (para sort avanzado)
            for i in 1 2 3 4 5 6 7; do
              dd if=/dev/urandom of=/opt/reports/data_$i.dat bs=1K count=$((i * 50)) 2>/dev/null
              touch -d "2025-0$i-15" /opt/reports/data_$i.dat 2>/dev/null || touch -d "2025-$i-15" /opt/reports/data_$i.dat
            done
            
            # Crear archivos con diferentes permisos
            touch /opt/reports/secret.txt
            touch /opt/reports/public.txt
            touch /opt/reports/internal.txt
            chmod 600 /opt/reports/secret.txt
            chmod 644 /opt/reports/public.txt
            chmod 640 /opt/reports/internal.txt
            
            # ── Logs de aplicación ──
            cat << 'LOG' > /var/log/audit-app/access.log
  2026-07-01 10:00:00 INFO User admin logged in
  2026-07-01 10:05:23 WARNING Failed login attempt from 192.168.1.100
  2026-07-01 10:10:45 ERROR Database connection timeout
  2026-07-01 10:15:12 INFO Backup completed successfully
  2026-07-01 10:20:33 WARNING Disk usage above 80%
  2026-07-01 10:25:01 ERROR Permission denied: /etc/shadow
  2026-07-01 10:30:18 INFO Service restarted
  2026-07-01 10:35:44 ERROR Connection refused on port 5432
  2026-07-01 10:40:09 WARNING Memory usage critical
  2026-07-01 10:45:22 INFO Audit completed
  LOG
            
            # ── Usuarios y grupos ──
            groupadd -f developers
            groupadd -f testers
            
            useradd -m -s /bin/bash -G developers dev1 2>/dev/null || true
            useradd -m -s /bin/bash -G testers test1 2>/dev/null || true
            echo 'dev1:caleston123' | chpasswd
            echo 'test1:caleston123' | chpasswd
            
            # ── Configurar sysctl con valor incorrecto (REFUERZO) ──
            echo "vm.swappiness = 60" > /etc/sysctl.d/99-refuerzo.conf
            sysctl -p /etc/sysctl.d/99-refuerzo.conf >/dev/null
            
            # ── Preparar disco para swap (REFUERZO) ──
            # NO formatear, dejarlo vacío para que el usuario decida
            
            # ── Cron job mal configurado ──
            cat << 'CRON' > /tmp/bad-cron
  * * * * * echo "Cleanup running" >> /var/log/cleanup.log
  CRON
            crontab -u test1 /tmp/bad-cron
            
            # ── Instalar paquetes adicionales ──
            apt-get install -y -qq tree wget
            
            # Asegurar nginx corriendo
            systemctl enable nginx >/dev/null 2>&1
            systemctl start nginx >/dev/null 2>&1
            
            echo "✅ node02 configurado para refuerzo"
          SHELL
        end
        
        # ── NODE03: BÓVEDA DE EVIDENCIA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/simulacro-004
            chown -R bob:bob /opt/ops-compliance
            chmod -R 755 /opt/ops-compliance
            echo "✅ Bóveda lista en /opt/ops-compliance/simulacro-004/"
          SHELL
        end
        
        # ── NODE01: TICKET + SCRIPT DE VERIFICACIÓN ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket y script de verificación en node01..."
            
            # --- CREAR EL TICKET ---
            cat << 'TICKET' > /home/vagrant/TICKET_SIMULACRO-004.txt
  ================================================================================
  TICKET SIMULACRO-004  │  Severidad: MEDIA  │  Ambiente: PRODUCCIÓN
  🔐 SIMULACRO-004 — Refuerzo y Consolidación
  Módulo: LFCS Complete  │  Dificultad: 3/10  │  Nivel: L2
  Ubicación de Control:  node01  (Estación del Administrador — bob)
  Nodo Servidor:         node02  (Servidor a auditar — Ubuntu 22.04)
  Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/simulacro-004/)
  Contraseña del Clúster: caleston123

  Un servidor en node02 requiere auditoría completa con énfasis en áreas críticas:
  configuración del kernel, gestión de swap, análisis avanzado de archivos y 
  monitoreo de puertos. Este simulacro está diseñado para reforzar conceptos 
  que presentaron dificultades en auditorías anteriores.

  Tu misión es completar las 8 tareas siguientes en el orden que prefieras, 
  respetando los tiempos máximos y enviando la evidencia a node03.

  ================================================================================
  TAREA 1 — Essential Commands: Análisis Avanzado de Archivos (peso 4 puntos)
  ================================================================================
  El equipo de seguridad necesita un reporte detallado de archivos grandes.

  En node02:
  1. Busca todos los archivos en /opt/reports/ que tengan un tamaño mayor 
     a 150 kilobytes
  2. Para cada archivo encontrado, muestra: ruta completa, tamaño en formato 
     legible (KB/MB), y fecha de modificación
  3. Ordena la lista por tamaño de MAYOR a MENOR
  4. Guarda el resultado en /opt/file-analysis.txt

  PISTA: Necesitas combinar find con ls y sort por una columna específica.

  CRITERIOS:
    [ ] El archivo /opt/file-analysis.txt existe                                --> 25%
    [ ] Contiene solo archivos mayores a 150K                                   --> 25%
    [ ] Muestra ruta, tamaño legible y fecha                                    --> 25%
    [ ] La lista está ordenada por tamaño (mayor a menor)                       --> 25%

  TIEMPO MÁXIMO: 12 minutos

  ================================================================================
  TAREA 2 — Essential Commands: Auditoría de Permisos (peso 3 puntos)
  ================================================================================
  El equipo de compliance necesita auditar archivos con permisos restrictivos.

  En node02:
  1. Busca todos los archivos en /opt/reports/ que tengan permisos EXACTOS 600
     (solo el propietario puede leer y escribir)
  2. Cuenta cuántos archivos cumplen esta condición
  3. Guarda SOLO el número en /opt/secure-count.txt

  CRITERIOS:
    [ ] El archivo /opt/secure-count.txt existe                                 --> 30%
    [ ] Contiene solo un número                                                 --> 30%
    [ ] El número es correcto (debe ser 1)                                      --> 40%

  TIEMPO MÁXIMO: 8 minutos

  ================================================================================
  TAREA 3 — User and Group Management: Auditoría de Usuarios (peso 3 puntos)
  ================================================================================
  Se requiere verificar la configuración de usuarios del sistema.

  En node02:
  1. Lista todos los usuarios que pertenecen al grupo "developers"
  2. Lista todos los usuarios que pertenecen al grupo "testers"
  3. Guarda esta información en /opt/user-audit.txt con el formato:
     Grupo developers: [lista de usuarios]
     Grupo testers: [lista de usuarios]

  CRITERIOS:
    [ ] El archivo /opt/user-audit.txt existe                                   --> 25%
    [ ] Lista correctamente los usuarios del grupo developers                   --> 37.5%
    [ ] Lista correctamente los usuarios del grupo testers                      --> 37.5%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 4 — Operation of Running Systems: Parámetro del Kernel (peso 5 puntos)
  ================================================================================
  El equipo de operaciones requiere optimizar el uso de swap del sistema.

  En node02:
  1. Modifica el parámetro del kernel vm.swappiness para que tenga valor 10
     (reducir el uso de swap)
  2. Asegúrate de que el cambio sea persistente (sobreviva a reinicios)
  3. Aplica el cambio inmediatamente sin reiniciar
  4. Verifica que el valor actual sea 10

  PISTA: Usa sysctl con la opción --load para aplicar cambios desde un archivo.

  CRITERIOS:
    [ ] El archivo de configuración persistente existe en /etc/sysctl.d/        --> 30%
    [ ] Contiene vm.swappiness = 10                                             --> 25%
    [ ] El valor actual del kernel es 10 (verificar con sysctl)                 --> 25%
    [ ] El cambio es inmediato (no requiere reinicio)                           --> 20%

  TIEMPO MÁXIMO: 12 minutos

  ================================================================================
  TAREA 5 — Storage Management: Configuración de Swap (peso 5 puntos)
  ================================================================================
  El servidor necesita memoria swap adicional para manejar cargas pico.

  En node02:
  1. El disco /dev/vdb está disponible pero NO formateado
  2. Configura /dev/vdb como área de swap (NO lo montes como filesystem)
  3. Activa la swap (swapon)
  4. Configura /etc/fstab para que la swap sea persistente

  PISTA: El orden correcto es: mkswap → swapon → fstab (NO montes primero)

  CRITERIOS:
    [ ] /dev/vdb está configurado como swap (NO como filesystem)                --> 30%
    [ ] La swap está activa (verificar con swapon --show)                       --> 30%
    [ ] La entrada en /etc/fstab es correcta                                    --> 25%
    [ ] La swap es persistente (sobrevive a reboot)                             --> 15%

  TIEMPO MÁXIMO: 15 minutos

  ================================================================================
  TAREA 6 — Networking: Auditoría de Puertos con Procesos (peso 3 puntos)
  ================================================================================
  El equipo de seguridad necesita verificar qué puertos están escuchando y 
  qué procesos los están usando.

  En node02:
  1. Lista todos los puertos TCP que están en estado LISTEN
  2. Filtra solo los que están en el puerto 80 (nginx)
  3. La información DEBE incluir: protocolo, puerto, Y el nombre del proceso
  4. Guarda la información en /opt/port-audit.txt

  PISTA: Para ver el nombre del proceso necesitas privilegios elevados.

  CRITERIOS:
    [ ] El archivo /opt/port-audit.txt existe                                   --> 30%
    [ ] Contiene información del puerto 80 en estado LISTEN                     --> 30%
    [ ] La información incluye el proceso (nginx)                               --> 40%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 7 — Service Configuration: Corrección de Cron Job (peso 3 puntos)
  ================================================================================
  El cron job del usuario test1 está mal configurado y ejecutándose cada 
  minuto, causando sobrecarga.

  En node02:
  1. Revisa el cron job actual del usuario test1
  2. Modifícalo para que se ejecute solo una vez al día a las 4:30 AM
  3. Verifica que el cambio se aplicó correctamente

  CRITERIOS:
    [ ] El cron job existe para test1                                           --> 30%
    [ ] Está configurado para ejecutarse a las 4:30 AM diarios                  --> 40%
    [ ] El comando sigue siendo el mismo (echo "Cleanup running" ...)           --> 30%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 8 — Package Management: Auditoría de Paquetes (peso 3 puntos)
  ================================================================================
  El equipo de compliance necesita verificar qué paquetes están instalados.

  En node02:
  1. Verifica si el paquete "nginx" está instalado
  2. Verifica si el paquete "apache2" está instalado
  3. Verifica si el paquete "wget" está instalado
  4. Guarda el resultado en /opt/package-audit.txt con el formato:
     nginx: [instalado/no instalado]
     apache2: [instalado/no instalado]
     wget: [instalado/no instalado]

  CRITERIOS:
    [ ] El archivo /opt/package-audit.txt existe                                --> 25%
    [ ] Indica correctamente que nginx está instalado                           --> 25%
    [ ] Indica correctamente que apache2 NO está instalado                      --> 25%
    [ ] Indica correctamente que wget está instalado                            --> 25%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  PIPELINE DE EVIDENCIA A NODE03
  ================================================================================
  Una vez completadas las 8 tareas, debes enviar TODA la evidencia a node03 
  mediante pipeline SSH (sin crear archivos temporales en node01).

  Destino: /opt/ops-compliance/simulacro-004/evidence.txt

  La evidencia debe incluir:
  a) Contenido de /opt/file-analysis.txt en node02
  b) Contenido de /opt/secure-count.txt en node02
  c) Contenido de /opt/user-audit.txt en node02
  d) Salida de 'sysctl vm.swappiness' en node02
  e) Salida de 'swapon --show' en node02
  f) Contenido de /opt/port-audit.txt en node02
  g) Salida de 'sudo crontab -u test1 -l' en node02
  h) Contenido de /opt/package-audit.txt en node02

  NO crear archivos temporales en node01. Todo debe ir vía pipeline SSH.

  CRITERIOS:
    [ ] Evidencia enviada a node03:/opt/ops-compliance/simulacro-004/          --> 100%
    [ ] CERO archivos de resultados almacenados en node01 (DESCALIFICA)

  ================================================================================
  RESUMEN DE PUNTUACIÓN
  ================================================================================
  Tarea 1: 4 puntos (Essential Commands - Análisis avanzado)
  Tarea 2: 3 puntos (Essential Commands - Permisos)
  Tarea 3: 3 puntos (User/Group Management)
  Tarea 4: 5 puntos (Operation of Running Systems - sysctl)
  Tarea 5: 5 puntos (Storage Management - swap)
  Tarea 6: 3 puntos (Networking - puertos con procesos)
  Tarea 7: 3 puntos (Service Configuration - cron)
  Tarea 8: 3 puntos (Package Management)
  Evidencia: incluido en las tareas
  TOTAL: 29 puntos
  MÍNIMO PARA APROBAR (67%): 20 puntos

  REGLA DE ORO: Está PROHIBIDO crear archivos de resultados en node01.
  Todo debe enviarse a node03 mediante pipelines SSH.

  TIEMPO TOTAL MÁXIMO: 90 minutos
  ================================================================================
  TICKET

            # --- CREAR EL SCRIPT DE VERIFICACIÓN ---
            cat << 'VERIFY' > /tmp/verify-simulacro004.sh
  #!/bin/bash
  RED='\e[1;31m'
  GREEN='\e[1;32m'
  YELLOW='\e[1;33m'
  CYAN='\e[1;36m'
  RESET='\e[0m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  FAIL=0

  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          VERIFICACIÓN DE ESCENARIO SIMULACRO-004              ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${YELLOW}[1/10] node02: Estructura de archivos creada${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "[ -d /opt/reports ] && [ -d /var/log/audit-app ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Estructura creada${RESET}"
  else
    echo -e "      ${RED}✗ Estructura no encontrada${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[2/10] node02: Archivos con diferentes tamaños${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "ls /opt/reports/*.dat >/dev/null 2>&1" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Archivos de reportes existen${RESET}"
  else
    echo -e "      ${RED}✗ Archivos no encontrados${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[3/10] node02: Grupos developers y testers${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "getent group developers >/dev/null 2>&1 && getent group testers >/dev/null 2>&1" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Grupos existen${RESET}"
  else
    echo -e "      ${RED}✗ Grupos no encontrados${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[4/10] node02: Usuarios dev1 y test1${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "id dev1 >/dev/null 2>&1 && id test1 >/dev/null 2>&1" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Usuarios existen${RESET}"
  else
    echo -e "      ${RED}✗ Usuarios no encontrados${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[5/10] node02: Parámetro sysctl actual (debe ser 60)${RESET}"
  CURRENT=$(sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sysctl -n vm.swappiness" 2>/dev/null | tr -d '\r')
  if [ "$CURRENT" = "60" ]; then
    echo -e "      ${GREEN}✓ Parámetro actual es 60 (bug inyectado)${RESET}"
  else
    echo -e "      ${RED}✗ Parámetro ya es $CURRENT (bug no inyectado)${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[6/10] node02: Disco /dev/vdb disponible (sin formatear)${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "sudo blkid /dev/vdb 2>/dev/null | grep -q ."; then
    echo -e "      ${RED}✗ Disco ya está formateado (bug no inyectado)${RESET}"
    FAIL=1
  else
    echo -e "      ${GREEN}✓ Disco disponible sin formatear${RESET}"
  fi

  echo -e "${YELLOW}[7/10] node02: nginx instalado y activo${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "sudo systemctl is-active --quiet nginx" 2>/dev/null; then
    echo -e "      ${GREEN}✓ nginx activo${RESET}"
  else
    echo -e "      ${RED}✗ nginx inactivo${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[8/10] node02: Cron job mal configurado (bug inyectado)${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "sudo crontab -u test1 -l | grep -q '^\* \* \* \* \*'" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Cron job ejecutándose cada minuto (bug activo)${RESET}"
  else
    echo -e "      ${RED}✗ Cron job no coincide con el bug esperado${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[9/10] node02: Paquetes wget y tree instalados${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "which wget tree >/dev/null 2>&1" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Paquetes instalados${RESET}"
  else
    echo -e "      ${RED}✗ Paquetes no encontrados${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[10/10] node03: Bóveda de evidencia${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/simulacro-004 ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Bóveda creada${RESET}"
  else
    echo -e "      ${RED}✗ Bóveda no existe${RESET}"
    FAIL=1
  fi

  echo ""
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║  ✅ TODAS LAS VERIFICACIONES PASARON - ESCENARIO LISTO         ║${RESET}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║  ⚠️  ALGUNAS VERIFICACIONES FALLARON                           ║${RESET}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${RESET}"
  fi

  echo ""
  echo -e "${YELLOW}Presiona ENTER para ver el ticket del incidente...${RESET}"
  read -r
  cat /home/vagrant/TICKET_SIMULACRO-004.txt
  VERIFY

            chmod +x /tmp/verify-simulacro004.sh
            
            # --- AÑADIR AL .bashrc PARA EJECUCIÓN AUTOMÁTICA ---
            sed -i '/verify-simulacro004/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-simulacro004.sh' >> /home/vagrant/.bashrc
            
            echo "✅ Ticket y script de verificación creados."
            echo "🚀 Al hacer 'vagrant ssh node01' se ejecutará automáticamente."
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---

