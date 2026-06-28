---
Curso: Transición Sysadmin a DevOps - Operations Deployment LFCS/RHCSA
Modulo: Operations Deployment (Gestión de Software y Compilación)
Playground: OD-005
Titulo: El Muro Invisible – Contextos SELinux y Políticas MAC
Fecha de Inicio: 2026-06-29
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA (Troubleshooting de SELinux en modo Enforcing).
  - Pensar como Sysadmin Linux Pleno (Diagnóstico basado en Mandatory Access Control, no solo permisos POSIX).
  - Prepararme para DevOps Engineer y Sysadmin Kubernetes (Entender cómo las políticas MAC
    pueden bloquear servicios aunque chmod/chown sean correctos, y cómo definir políticas
    seguras sin desactivar la protección).
Temas: |-
  - Estados de SELinux= Enforcing, Permissive, Disabled (sestatus, getenforce)
  - Contextos de seguridad= ls -Z, chcon, restorecon, matchpathcon
  - Tipos de archivo esperados por servicios (httpd_sys_content_t, var_log_t, etc.)
  - Auditoría de denegaciones= /var/log/audit/audit.log, ausearch -m AVC, grep denied
  - Generación de políticas custom: audit2allow -M, semodule -i
  - Gestión persistente de contextos: semanage fcontext -a -t <type> <path>
  - Booleans de SELinux= getsebool, setsebool -P
  - Regla crítica= PROHIBIDO usar setenforce 0 (debe resolverse de forma segura)
Competencias: |-
  - Identificar que el problema NO son permisos POSIX (chmod/chown correctos) sino SELinux,
    verificando sestatus y el modo Enforcing.
  - Usar 'ls -Z' para comparar el contexto actual de los archivos con el contexto esperado
    por el servicio (ej: httpd_t necesita httpd_sys_content_t).
  - Leer /var/log/audit/audit.log y filtrar denegaciones con 'ausearch -m AVC -ts recent'
    o 'grep denied' para identificar el tipo denegado y el proceso afectado.
  - Aplicar una solución temporal con 'chcon -Rt <type> <path>' y verificar que funciona.
  - Aplicar una solución persistente con 'semanage fcontext -a -t <type> "<path>(/.*)?"'
    seguido de 'restorecon -Rv <path>' para que sobreviva a reinicios y relabels.
  - Como alternativa avanzada: generar un módulo de política custom con
    'audit2allow -a -M mi-politica' y cargarlo con 'semodule -i mi-politica.pp'.
  - Verificar la solución reiniciando el servicio y confirmando que responde correctamente.
  - Documentar TODO el proceso enviando la evidencia (sestatus, ls -Z, audit.log, comandos aplicados)
    a node03 mediante pipelines SSH, sin crear archivos intermedios en node01.
Script Vagrant: |-
  # -*- mode: ruby -*-
  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    # Usamos Rocky Linux 9 que tiene SELinux nativo
    config.vm.box = "rockylinux/9"

    nodes = [
      { name: "node01", ip: "192.168.122.21" },
      { name: "node02", ip: "192.168.122.22" },
      { name: "node03", ip: "192.168.122.23" }
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
        end

        # ── PROVISIONADO GENERAL ──
        node_config.vm.provision "shell", inline: <<-SHELL
          echo "🔧 Configurando #{node[:name]}..."
          
          cat << 'HOSTS' >> /etc/hosts
  192.168.122.21 node01
  192.168.122.22 node02
  192.168.122.23 node03
  HOSTS
          
          useradd -m -s /bin/bash bob
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          dnf install -y sshpass
        SHELL

        # ── NODE02: SERVIDOR WEB CON SELINUX ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🌐 Configurando node02 como servidor web con SELinux..."
            
            # Instalar httpd y herramientas SELinux
            dnf install -y httpd policycoreutils-python-utils setroubleshoot-server
            
            # Asegurar que SELinux está en modo Enforcing
            setenforce 1
            sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
            
            # Crear directorio no estándar para contenido web
            mkdir -p /opt/webdata
            cd /opt/webdata
            
            # Crear contenido web de prueba
            cat << 'HTML' > index.html
  <!DOCTYPE html>
  <html>
  <head><title>OD-005 - SELinux Test</title></head>
  <body>
  <h1>¡Funciona! SELinux está correctamente configurado.</h1>
  <p>Si ves esto, el contexto de seguridad es correcto.</p>
  </body>
  </html>
  HTML
            
            # Configurar permisos POSIX CORRECTOS (para que NO sea el problema)
            chown -R apache:apache /opt/webdata
            chmod -R 755 /opt/webdata
            
            # ⚠️ INYECCIÓN DEL BUG: NO cambiar el contexto SELinux
            # El directorio tendrá contexto default_t en lugar de httpd_sys_content_t
            # Esto hace que httpd no pueda leer los archivos aunque los permisos POSIX sean correctos
            
            # Configurar httpd para usar el directorio no estándar
            cat << 'HTTPD_CONF' > /etc/httpd/conf.d/custom-webdata.conf
  <VirtualHost *:80>
      DocumentRoot "/opt/webdata"
      <Directory "/opt/webdata">
          Options Indexes FollowSymLinks
          AllowOverride None
          Require all granted
      </Directory>
  </VirtualHost>
  HTTPD_CONF
            
            # Iniciar httpd
            systemctl enable httpd
            systemctl start httpd
            
            # Configurar firewall para permitir HTTP
            firewall-cmd --permanent --add-service=http
            firewall-cmd --reload
            
            echo "✅ node02 configurado con SELinux Enforcing y bug inyectado"
          SHELL
        end

        # ── NODE03: BÓVEDA DE EVIDENCIA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/od-005
            chown -R bob:bob /opt/ops-compliance/od-005
            chmod 750 /opt/ops-compliance/od-005
            echo "✅ Bóveda lista"
          SHELL
        end

        # ── NODE01: TICKET + VERIFICACIÓN ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket en node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_OD-005.txt
  ================================================================================
    TICKET OD-005  │  Severidad: ALTA  │  Ambiente: PRODUCCIÓN
  ================================================================================
    🔐 OD-005-SE — El Muro Invisible (Contextos SELinux y Políticas MAC)
    Módulo: Operations Deployment  │  Dificultad: 6/10  │  Nivel: L2
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo Servidor Web:     node02  (httpd con SELinux Enforcing — /opt/webdata)
    Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/od-005/)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    El equipo de operaciones desplegó un nuevo servicio web (httpd) en node02 que
    debe servir contenido estático desde un directorio no estándar /opt/webdata/.
    Los permisos POSIX están perfectamente configurados (propietario apache:apache,
    chmod 755), pero al intentar acceder vía navegador o curl, el servicio devuelve
    403 Forbidden.

    SELinux está en modo Enforcing y está TERMINANTEMENTE PROHIBIDO usar
    'setenforce 0' como solución (política de seguridad de la empresa).

    Tu misión:
    1. Conectarte desde node01 a node02 (ssh bob@node02, contraseña: caleston123)
    2. Diagnosticar por qué httpd no puede servir contenido desde /opt/webdata/
       a pesar de que los permisos POSIX son correctos
    3. Identificar el contexto de seguridad incorrecto usando 'ls -Z'
    4. Revisar las denegaciones en /var/log/audit/audit.log con 'ausearch' o 'grep denied'
    5. Aplicar una solución SEGURA y PERSISTENTE usando:
       - semanage fcontext -a -t httpd_sys_content_t "/opt/webdata(/.*)?"
       - restorecon -Rv /opt/webdata/
    6. Verificar que curl http://node02/ ahora responde correctamente
    7. Enviar TODA la evidencia a node03 mediante pipeline SSH (sin archivos en node01)

    ARQUITECTURA
    --------------------------------------------------------------------------------
    node02:
      - Servicio: httpd (Apache)
      - SELinux: Enforcing
      - Directorio web: /opt/webdata (contexto INCORRECTO)
      - Firewall: firewalld activo, puerto 80 abierto
    
    node03:
      - Bóveda: /opt/ops-compliance/od-005/

    PROCEDIMIENTO REQUERIDO (MÁXIMO 30 MINUTOS)
    --------------------------------------------------------------------------------
    1. Diagnóstico desde node02:
       - Verifica el estado de SELinux: 'sestatus'
       - Intenta acceder al sitio: 'curl http://localhost/'
       - Revisa el contexto actual: 'ls -Z /opt/webdata/'
       - Busca denegaciones: 'sudo ausearch -m AVC -ts recent' o
         'sudo grep denied /var/log/audit/audit.log | tail -20'

    2. Identificar el contexto esperado:
       - Usa 'matchpathcon /opt/webdata' para ver qué contexto DEBERÍA tener
       - Compara con 'ls -Z /opt/webdata/' para ver qué contexto TIENE

    3. Aplicar solución persistente:
       - Define el contexto correcto:
         'sudo semanage fcontext -a -t httpd_sys_content_t "/opt/webdata(/.*)?"'
       - Aplica el contexto:
         'sudo restorecon -Rv /opt/webdata/'

    4. Verificar la corrección:
       - Confirma el nuevo contexto: 'ls -Z /opt/webdata/'
       - Prueba el acceso: 'curl http://localhost/'
       - Debe mostrar el HTML correctamente

    5. Pipeline de Evidencia a node03:
       - Destino: /opt/ops-compliance/od-005/selinux_evidence.txt
       - Desde node01, envía mediante pipeline SSH la salida consolidada de:
         a) Estado de SELinux en node02 (sudo sestatus)
         b) Contexto de archivos en /opt/webdata (ls -Z /opt/webdata/)
         c) Denegaciones encontradas en audit.log (sudo ausearch -m AVC -ts recent)
         d) Comandos aplicados (semanage, restorecon)
         e) Prueba final: curl http://node02/ desde node01
       - NO generar archivos temporales locales en node01

    CRITERIOS DE ACEPTACIÓN
    --------------------------------------------------------------------------------
     [ ] Diagnosticar que SELinux está en modo Enforcing                    --> 10%
     [ ] Identificar contexto incorrecto con 'ls -Z'                        --> 15%
     [ ] Encontrar denegaciones en audit.log con ausearch                   --> 15%
     [ ] Aplicar semanage fcontext correctamente                            --> 20%
     [ ] Aplicar restorecon y verificar contexto corregido                  --> 20%
     [ ] Verificar que curl http://node02/ responde correctamente           --> 10%
     [ ] Evidencia enviada a node03:/opt/ops-compliance/od-005/             --> 10%
     [ ] CERO archivos de resultados almacenados en node01 (DESCALIFICA)    --> 0% (descalifica)

    REGLA DE ORO: Está PROHIBIDO usar 'setenforce 0'. Debes resolver el problema
    de forma SEGURA usando las herramientas adecuadas de SELinux.

    COMANDOS ÚTILES
    --------------------------------------------------------------------------------
    sestatus                                              # Estado de SELinux
    ls -Z /opt/webdata/                                   # Ver contextos
    sudo ausearch -m AVC -ts recent                       # Buscar denegaciones
    sudo grep denied /var/log/audit/audit.log             # Alternativa
    sudo semanage fcontext -l | grep webdata              # Ver reglas definidas
    sudo semanage fcontext -a -t httpd_sys_content_t "/opt/webdata(/.*)?"
    sudo restorecon -Rv /opt/webdata/                     # Aplicar contextos
    matchpathcon /opt/webdata                             # Contexto esperado
    curl http://node02/                                   # Probar acceso
  ================================================================================
  TICKET

            # ── SCRIPT DE VERIFICACIÓN ──
            cat << 'VERIFY' > /tmp/verify-od005.sh
  #!/bin/bash

  RED='\e[1;31m'
  GREEN='\e[1;32m'
  YELLOW='\e[1;33m'
  CYAN='\e[1;36m'
  RESET='\e[0m'

  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  FAIL=0

  echo -e "\${CYAN}╔════════════════════════════════════════════════════════════════╗\${RESET}"
  echo -e "\${CYAN}║          VERIFICACIÓN DE ESCENARIO OD-005                     ║\${RESET}"
  echo -e "\${CYAN}╚════════════════════════════════════════════════════════════════╝\${RESET}"
  echo ""

  echo -e "\${YELLOW}[1/6] node02: SELinux Enforcing\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo sestatus | grep -q 'Current mode:.*enforcing'"; then
    echo -e "      \${GREEN}✓ SELinux en modo Enforcing\${RESET}"
  else
    echo -e "      \${RED}✗ SELinux no está en modo Enforcing\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[2/6] node02: httpd instalado y activo\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "systemctl is-active --quiet httpd"; then
    echo -e "      \${GREEN}✓ httpd activo\${RESET}"
  else
    echo -e "      \${RED}✗ httpd inactivo\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[3/6] node02: Directorio /opt/webdata existe\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "[ -d /opt/webdata ]"; then
    echo -e "      \${GREEN}✓ Directorio existe\${RESET}"
  else
    echo -e "      \${RED}✗ Directorio no existe\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[4/6] node02: Contexto SELinux INCORRECTO (bug inyectado)\${RESET}"
  CONTEXT=\$(sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "ls -Z /opt/webdata/ | head -1 | awk '{print \\\$1}'")
  if [[ "\$CONTEXT" != *"httpd_sys_content_t"* ]]; then
    echo -e "      \${GREEN}✓ Contexto incorrecto detectado: \$CONTEXT (bug activo)\${RESET}"
  else
    echo -e "      \${RED}✗ Contexto ya es correcto (bug no inyectado)\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[5/6] node02: httpd NO puede servir contenido (403 Forbidden)\${RESET}"
  HTTP_CODE=\$(sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "curl -s -o /dev/null -w '%{http_code}' http://localhost/" 2>/dev/null || echo "000")
  if [ "\$HTTP_CODE" = "403" ] || [ "\$HTTP_CODE" = "000" ]; then
    echo -e "      \${GREEN}✓ httpd devuelve 403 o falla (bug activo)\${RESET}"
  else
    echo -e "      \${RED}✗ httpd responde con código \$HTTP_CODE (bug no activo)\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[6/6] node03: Bóveda de evidencia\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/od-005 ]"; then
    echo -e "      \${GREEN}✓ Bóveda creada\${RESET}"
  else
    echo -e "      \${RED}✗ Bóveda no existe\${RESET}"
    FAIL=1
  fi

  echo ""
  if [ \$FAIL -eq 0 ]; then
    echo -e "\${GREEN}╔════════════════════════════════════════════════════════════════╗\${RESET}"
    echo -e "\${GREEN}║  ✅ TODAS LAS VERIFICACIONES PASARON - ESCENARIO LISTO         ║\${RESET}"
    echo -e "\${GREEN}╚════════════════════════════════════════════════════════════════╝\${RESET}"
  else
    echo -e "\${RED}╔════════════════════════════════════════════════════════════════╗\${RESET}"
    echo -e "\${RED}║  ⚠️  ALGUNAS VERIFICACIONES FALLARON                           ║\${RESET}"
    echo -e "\${RED}╚════════════════════════════════════════════════════════════════╝\${RESET}"
  fi

  echo ""
  echo -e "\${YELLOW}Presiona ENTER para ver el ticket del incidente...\${RESET}"
  read -r
  cat /home/vagrant/TICKET_OD-005.txt
  VERIFY

            chmod +x /tmp/verify-od005.sh
            
            sed -i '/verify-od005/d' /home/vagrant/.bashrc
            cat << 'EOF' >> /home/vagrant/.bashrc
  bash /tmp/verify-od005.sh
  EOF
          SHELL
        end
      end
    end
  end
tags:
  - Laboratorios-del-LFCS
  - Operations-Deployment
  - SELinux
  - MAC-Policies
  - Contextos-de-Seguridad
  - audit2allow
  - semanage
  - Troubleshooting
  - Fundamentos
Escenario: |-
  Situación= El equipo de operaciones desplegó un nuevo servicio web (httpd/nginx) en `node02`
  que debe servir contenido estático desde un directorio no estándar `/opt/webdata/`. Los
  permisos POSIX están perfectamente configurados (propietario correcto, chmod 755, el usuario
  del servicio puede leer los archivos), pero al intentar acceder vía navegador o curl, el
  servicio devuelve 403 Forbidden o directamente no arranca. SELinux está en modo `Enforcing`
  y está **terminantemente prohibido** usar `setenforce 0` como solución (es una política de
  seguridad de la empresa). 
  Tu misión= diagnosticar desde `node01` conectándote a `node02`
  por qué el servicio es bloqueado a pesar de los permisos correctos, identificar el contexto
  de seguridad incorrecto de los archivos en `/opt/webdata/` usando `ls -Z`, revisar las
  denegaciones en `/var/log/audit/audit.log` con `ausearch` o `grep denied`, y aplicar una
  solución segura y persistente usando `semanage fcontext` + `restorecon` (o alternativamente
  `chcon` + generación de módulo custom con `audit2allow -M` y `semodule -i`). Debes enviar
  toda la evidencia del diagnóstico y la corrección (output de `sestatus`, `ls -Z`, `audit.log`
  filtrado, comandos aplicados y verificación final del servicio respondiendo) a `node03`
  mediante pipelines SSH, sin materializar archivos de texto intermedios en `node01`.
---
[[Laboratorios del LFCS]]
---
