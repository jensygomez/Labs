---
Curso: Transición Sysadmin a DevOps - Users, Groups & Resource Management LFCS/RHCSA
Modulo: Users, Groups & Resource Management (Autenticación Centralizada)
Playground: USR-004-v1
Titulo: La Identidad Perdida – Migración a Autenticación Centralizada (LDAP SSSD)
Fecha de Inicio: 2026-06-22
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Configuración del sistema para usar cuentas de usuario y grupo LDAP
  - Instalación y configuración de OpenLDAP (slapd) como servidor de directorio
  - Implementación de SSSD (System Security Services Daemon) como cliente LDAP
  - Integración de PAM (Pluggable Authentication Modules) con LDAP
  - Configuración de sudo para usuarios y grupos LDAP
Competencias: |-
  - Configurar un servidor OpenLDAP básico con estructura de directorio (OU, usuarios, grupos) y poblarlo con cuentas de prueba.
  - Implementar SSSD en los nodos cliente para autenticar usuarios contra el directorio LDAP centralizado.
  - Configurar PAM para integrar la autenticación LDAP con el sistema de login local, asegurando que los usuarios LDAP puedan iniciar sesión.
  - Configurar nsswitch.conf para resolver usuarios y grupos desde LDAP además de los archivos locales.
  - Extender las reglas de sudo para aplicarlas a grupos LDAP (usando %grupo_ldap), permitiendo privilegios administrativos centralizados.
  - Documentar el proceso de migración y enviar la evidencia de autenticación exitosa a node03 vía pipeline SSH, sin materializar archivos en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_usr004.sh
  #!/bin/bash
  set -e

  PASS="caleston123"
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT}"

  echo -e "\e[1;33m⏳ Verificando sshpass en node01...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      echo caleston123 | sudo -S apt-get install -y sshpass -qq
  fi

  echo -e "\e[1;33m⏳ Instalando sshpass en nodos remotos...\e[0m"
  $SSH2 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"
  $SSH3 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Configurando servidor OpenLDAP en node03...\e[0m"
  $SSH3 bash << 'NODE03_INJECT' || echo -e "\e[1;33m  [!] Detalle en node03, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'

      # Instalar OpenLDAP
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y slapd ldap-utils -qq

      # Configurar slapd con debconf
      echo "slapd slapd/internal/generated_adminpw password admin123" | debconf-set-selections
      echo "slapd slapd/internal/adminpw password admin123" | debconf-set-selections
      echo "slapd slapd/password1 password admin123" | debconf-set-selections
      echo "slapd slapd/password2 password admin123" | debconf-set-selections
      echo "slapd slapd/domain string example.com" | debconf-set-selections
      echo "slapd shared/organization string Example" | debconf-set-selections
      dpkg-reconfigure -f noninteractive slapd

      # === PASO CRÍTICO: Asegurar que el servicio LDAP esté activo ===
      echo -e "\e[1;33m🔄 Verificando y activando servicio slapd...\e[0m"
      
      # Verificar estado del servicio
      if ! systemctl is-active --quiet slapd; then
          echo "Service slapd no está activo. Iniciando..."
          systemctl start slapd
      fi
      
      # Esperar un poco para que el servicio se estabilice
      sleep 3
      
      # Verificar que realmente responde
      if ! ldapsearch -x -H ldap://localhost -b 'dc=example,dc=com' '(objectclass=*)' 2>/dev/null | grep -q "numEntries"; then
          echo -e "\e[1;31m⚠️  LDAP no responde correctamente. Reintentando...\e[0m"
          systemctl restart slapd
          sleep 3
      fi
      
      echo -e "\e[1;32m✅ Servicio slapd activo y respondiendo\e[0m"

      # === PARCHE INTEGRADO: Poblamiento LDAP correcto ===
      
      # 1. Verificar si la base existe
      echo "Verificando base del directorio..."
      if ! ldapsearch -x -b 'dc=example,dc=com' '(objectclass=organization)' 2>/dev/null | grep -q "numEntries"; then
          echo "Creando base del directorio..."
          cat > /tmp/base.ldif << 'BASELDIF'
  dn: dc=example,dc=com
  objectClass: top
  objectClass: dcObject
  objectClass: organization
  o: Example Organization
  dc: example

  dn: ou=users,dc=example,dc=com
  objectClass: organizationalUnit
  ou: users

  dn: ou=groups,dc=example,dc=com
  objectClass: organizationalUnit
  ou: groups
  BASELDIF
          
          ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin123 -f /tmp/base.ldif
          echo "✅ Base creada"
      else
          echo "✅ Base ya existe"
      fi

      # 2. Verificar si los usuarios existen
      echo "Verificando usuarios..."
      if ! ldapsearch -x -b 'ou=users,dc=example,dc=com' '(uid=alice)' 2>/dev/null | grep -q "numEntries: 1"; then
          echo "Creando usuarios..."
          
          # Generar hashes de contraseñas
          ALICE_HASH=$(slappasswd -s alice123)
          BOB_HASH=$(slappasswd -s bob123)
          CHARLIE_HASH=$(slappasswd -s charlie123)
          
          cat > /tmp/users.ldif << USERSLDIF
  dn: uid=alice,ou=users,dc=example,dc=com
  objectClass: inetOrgPerson
  objectClass: posixAccount
  objectClass: shadowAccount
  cn: Alice Smith
  sn: Smith
  givenName: Alice
  uid: alice
  uidNumber: 10001
  gidNumber: 10001
  homeDirectory: /home/alice
  loginShell: /bin/bash
  userPassword: $ALICE_HASH
  gecos: Alice Smith

  dn: uid=bob,ou=users,dc=example,dc=com
  objectClass: inetOrgPerson
  objectClass: posixAccount
  objectClass: shadowAccount
  cn: Bob Johnson
  sn: Johnson
  givenName: Bob
  uid: bob
  uidNumber: 10002
  gidNumber: 10002
  homeDirectory: /home/bob
  loginShell: /bin/bash
  userPassword: $BOB_HASH
  gecos: Bob Johnson

  dn: uid=charlie,ou=users,dc=example,dc=com
  objectClass: inetOrgPerson
  objectClass: posixAccount
  objectClass: shadowAccount
  cn: Charlie Brown
  sn: Brown
  givenName: Charlie
  uid: charlie
  uidNumber: 10003
  gidNumber: 10001
  homeDirectory: /home/charlie
  loginShell: /bin/bash
  userPassword: $CHARLIE_HASH
  gecos: Charlie Brown
  USERSLDIF
          
          ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin123 -f /tmp/users.ldif
          echo "✅ Usuarios creados"
      else
          echo "✅ Usuarios ya existen"
      fi

      # 3. Verificar si los grupos existen
      echo "Verificando grupos..."
      if ! ldapsearch -x -b 'ou=groups,dc=example,dc=com' '(cn=ldap_users)' 2>/dev/null | grep -q "numEntries: 1"; then
          echo "Creando grupos..."
          cat > /tmp/groups.ldif << 'GROUPSLDIF'
  dn: cn=ldap_users,ou=groups,dc=example,dc=com
  objectClass: posixGroup
  cn: ldap_users
  gidNumber: 10001
  memberUid: alice
  memberUid: charlie

  dn: cn=ldap_admins,ou=groups,dc=example,dc=com
  objectClass: posixGroup
  cn: ldap_admins
  gidNumber: 10002
  memberUid: bob
  GROUPSLDIF
          
          ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin123 -f /tmp/groups.ldif
          echo "✅ Grupos creados"
      else
          echo "✅ Grupos ya existen"
      fi

      # 4. Limpiar archivos temporales
      rm -f /tmp/base.ldif /tmp/users.ldif /tmp/groups.ldif

      # 5. Verificación final
      echo ""
      echo -e "\e[1;32m=== VERIFICACIÓN FINAL LDAP ===\e[0m"
      echo "Usuarios en el directorio:"
      ldapsearch -x -b 'ou=users,dc=example,dc=com' '(objectclass=inetOrgPerson)' uid | grep "^uid:"

      echo ""
      echo "Grupos en el directorio:"
      ldapsearch -x -b 'ou=groups,dc=example,dc=com' '(objectclass=posixGroup)' cn | grep "^cn:"

      echo ""
      echo "Membresía de ldap_admins:"
      ldapsearch -x -b 'cn=ldap_admins,ou=groups,dc=example,dc=com' memberUid | grep "memberUid:"

      # Preparar bóveda de evidencia
      mkdir -p /opt/ops-compliance/usr-004
      chown bob:bob /opt/ops-compliance/usr-004
      chmod 750 /opt/ops-compliance/usr-004

      echo "[USR-004] Servidor OpenLDAP configurado correctamente en node03."
  SUDO_INNER
  NODE03_INJECT

  echo -e "\e[1;33m⏳ Preparando node02 como cliente LDAP...\e[0m"
  $SSH2 bash << 'NODE02_INJECT' || echo -e "\e[1;33m  [!] Detalle en node02, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'

      # Instalar dependencias de cliente LDAP
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y sssd sssd-tools libnss-sss libpam-sss ldap-utils -qq

      # Configurar SSSD
      cat > /etc/sssd/sssd.conf << 'SSSDCONF'
  [sssd]
  services = nss, pam
  config_file_version = 2
  domains = example.com

  [domain/example.com]
  id_provider = ldap
  auth_provider = ldap
  ldap_uri = ldap://192.168.1.103
  ldap_search_base = dc=example,dc=com
  ldap_id_use_start_tls = False
  cache_credentials = True
  enumerate = True

  [nss]
  filter_groups = root
  filter_users = root

  [pam]
  SSSDCONF

      # Establecer permisos correctos para sssd.conf
      chmod 600 /etc/sssd/sssd.conf
      chown root:root /etc/sssd/sssd.conf

      # Configurar nsswitch.conf
      sed -i 's/^passwd:.*/passwd:         compat sss/' /etc/nsswitch.conf
      sed -i 's/^group:.*/group:          compat sss/' /etc/nsswitch.conf
      sed -i 's/^shadow:.*/shadow:        compat sss/' /etc/nsswitch.conf

      # Configurar PAM para crear home directories automáticamente
      echo "session required pam_mkhomedir.so skel=/etc/skel umask=077" > /etc/pam.d/mkhomedir
      
      # Agregar a common-session
      grep -q "pam_mkhomedir.so" /etc/pam.d/common-session || \
      echo "session required pam_mkhomedir.so skel=/etc/skel umask=077" >> /etc/pam.d/common-session

      # Configurar sudo para grupos LDAP
      cat > /etc/sudoers.d/ldap_admins << 'SUDOCONF'
  # Permitir sudo a miembros del grupo ldap_admins
  %ldap_admins ALL=(ALL:ALL) ALL
  SUDOCONF
      chmod 440 /etc/sudoers.d/ldap_admins

      # Configurar SSSD para resolver grupos sudo
      cat >> /etc/sssd/sssd.conf << 'SUDOSSSD'

  [domain/example.com]
  sudo_provider = ldap
  ldap_sudo_search_base = ou=sudoers,dc=example,dc=com
  SUDOSSSD

      # Reiniciar servicios
      systemctl restart sssd
      systemctl enable sssd

      echo "[USR-004] Cliente LDAP configurado correctamente en node02."
  SUDO_INNER
  NODE02_INJECT

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m USR-004-v1 | La Identidad Perdida | Dificultad: 6/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Cliente LDAP: node02  |  Servidor LDAP: node03"
  echo -e " Bóveda: node03:/opt/ops-compliance/usr-004/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El departamento de Seguridad de la Información ha aprobado el plan de"
  echo -e " migración hacia una infraestructura de autenticación centralizada. La"
  echo -e " gestión actual de usuarios locales en cada servidor representa un riesgo"
  echo -e " significativo para la auditoría, la consistencia de permisos y la gestión"
  echo -e " de credenciales."
  echo -e ""
  echo -e " Se ha desplegado un servidor OpenLDAP en node03 con una estructura básica"
  echo -e " de directorio. El servidor node02 ha sido preparado con las dependencias"
  echo -e " necesarias para funcionar como cliente LDAP, pero la integración completa"
  echo -e " con SSSD y PAM aún no ha sido validada."
  echo -e ""
  echo -e " Como ingeniero L2 del equipo de identidad y acceso, se te asigna la tarea"
  echo -e " de completar la configuración del cliente LDAP, verificar la autenticación"
  echo -e " de usuarios del directorio, y extender las políticas de sudo para grupos LDAP."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01 vía SSH."
  echo -e " \e[1m>\e[0m No se permite materializar archivos de reporte o scripts temporales en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente de node02 hacia node03 mediante pipeline."
  echo -e " \e[1m>\e[0m Las contraseñas de los usuarios LDAP son: alice123, bob123, charlie123."
  echo -e ""
  echo -e "\e[1;33m PARÁMETROS TÉCNICOS OBLIGATORIOS (TICKET DE CONFIGURACIÓN - NIVEL L2)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Verificación del Servidor LDAP (node03)\e[0m"
  echo -e "    Estado actual: OpenLDAP instalado y poblado con usuarios de prueba."
  echo -e "    Objetivo: Verificar que el servidor LDAP responde correctamente y que"
  echo -e "    la estructura de directorio (OU users, OU groups) está accesible."
  echo -e "    \e[1;33mRestricción:\e[0m Usa ldapsearch para consultar el directorio y confirmar"
  echo -e "    que los usuarios alice, bob y charlie existen, junto con los grupos"
  echo -e "    ldap_users y ldap_admins."
  echo -e ""
  echo -e " \e[1m2. Validación de Configuración SSSD (node02)\e[0m"
  echo -e "    Estado actual: SSSD instalado pero no verificado."
  echo -e "    Objetivo: Confirmar que SSSD está correctamente configurado para conectarse"
  echo -e "    al servidor LDAP en node03 y puede resolver usuarios y grupos."
  echo -e "    \e[1;33mRestricción:\e[0m Usa getent passwd y getent group para verificar que los"
  echo -e "    usuarios y grupos LDAP son visibles en node02. Verifica el estado del"
  echo -e "    servicio sssd con systemctl status sssd."
  echo -e ""
  echo -e " \e[1m3. Prueba de Autenticación LDAP\e[0m"
  echo -e "    Estado actual: PAM configurado pero no probado."
  echo -e "    Objetivo: Verificar que un usuario LDAP puede iniciar sesión en node02"
  echo -e "    y que su home directory se crea automáticamente."
  echo -e "    \e[1;33mRestricción:\e[0m Usa su - alice (con contraseña alice123) para probar la"
  echo -e "    autenticación. Verifica que el home directory /home/alice fue creado"
  echo -e "    y que el usuario puede ejecutar comandos básicos."
  echo -e ""
  echo -e " \e[1m4. Verificación de Resolución de Grupos\e[0m"
  echo -e "    Estado actual: Los grupos LDAP deben ser visibles en node02."
  echo -e "    Objetivo: Confirmar que los grupos ldap_users y ldap_admins se resuelven"
  echo -e "    correctamente y que los usuarios pertenecen a los grupos esperados."
  echo -e "    \e[1;33mRestricción:\e[0m Usa id alice, id bob, id charlie para verificar la"
  echo -e "    membresía de grupos. Confirma que bob pertenece a ldap_admins."
  echo -e ""
  echo -e " \e[1m5. Configuración de Sudo para Grupos LDAP\e[0m"
  echo -e "    Estado actual: Sudoers configurado para %ldap_admins pero no probado."
  echo -e "    Objetivo: Verificar que el usuario bob (miembro de ldap_admins) puede"
  echo -e "    ejecutar comandos con sudo sin ser usuario local de node02."
  echo -e "    \e[1;33mRestricción:\e[0m Inicia sesión como bob (su - bob con contraseña bob123)"
  echo -e "    y ejecuta sudo whoami para confirmar que tiene privilegios administrativos."
  echo -e ""
  echo -e "\e[1;33m PIPELINE DE EVIDENCIA A NODE03\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " Destino: \e[1m/opt/ops-compliance/usr-004/ldap_audit.txt\e[0m"
  echo -e " Debe contener la salida concatenada de:"
  echo -e "  - ldapsearch en node03 (estructura del directorio)"
  echo -e "  - getent passwd | grep -E 'alice|bob|charlie' en node02"
  echo -e "  - getent group | grep -E 'ldap_users|ldap_admins' en node02"
  echo -e "  - systemctl status sssd en node02"
  echo -e "  - id alice, id bob, id charlie en node02"
  echo -e "  - Prueba de sudo con usuario bob (sudo whoami)"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Servidor LDAP responde y estructura es accesible                15%"
  echo -e "  [ ] SSSD configurado y servicio activo en node02                    15%"
  echo -e "  [ ] Usuarios LDAP visibles con getent en node02                     15%"
  echo -e "  [ ] Autenticación LDAP funcional (su - alice)                       20%"
  echo -e "  [ ] Grupos LDAP resueltos correctamente (id usuario)                15%"
  echo -e "  [ ] Sudo funcional para grupo ldap_admins (bob)                     10%"
  echo -e "  [ ] Evidencia (ldap_audit.txt) presente en bóveda node03            10%"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_usr004.sh && rm -f /tmp/setup_usr004.sh
tags:
  - Laboratorios-del-LFCS
  - Users-Groups
  - LDAP
  - OpenLDAP
  - SSSD
  - PAM
  - Centralized-Authentication
Escenario: |-
  - Situación: La empresa está en proceso de migración de la gestión de usuarios locales hacia una solución de autenticación centralizada basada en LDAP. El departamento de IT ha decidido implementar OpenLDAP como directorio central y SSSD como mecanismo de integración en los nodos cliente. Actualmente, los usuarios están definidos localmente en cada servidor, lo que genera inconsistencias, dificultad de auditoría y riesgos de seguridad.

  Tu misión:
  1. Configurar node03 como servidor OpenLDAP, creando una estructura de directorio básica con unidades organizativas (OU) para usuarios y grupos, y poblar el directorio con al menos 3 usuarios de prueba y 2 grupos (incluyendo un grupo 'ldap_admins').

  2. Configurar node02 como cliente LDAP instalando SSSD y las dependencias necesarias (ldap-utils, libnss-ldapd, libpam-ldapd). Configurar SSSD para conectarse al servidor LDAP en node03 y manejar la autenticación de usuarios.

  3. Integrar PAM con LDAP para permitir que los usuarios del directorio puedan iniciar sesión en node02 mediante SSH o login local. Configurar nsswitch.conf para que el sistema resuelva usuarios y grupos desde LDAP.

  4. Verificar que los usuarios LDAP pueden autenticarse correctamente en node02 (usando su - usuario_ldap) y que sus grupos se resuelven apropiadamente (usando id usuario_ldap).

  5. Configurar sudo para que los miembros del grupo LDAP 'ldap_admins' tengan privilegios administrativos completos en node02, extendiendo las reglas de sudo más allá de los usuarios locales.

  6. Generar un reporte completo del proceso de configuración, incluyendo la estructura LDAP, la configuración de SSSD, y la verificación de autenticación exitosa, enviándolo directamente a node03 vía pipeline SSH.

  Regla de Oro: No puedes crear archivos de texto intermedios en node01. Todo el proceso de configuración debe realizarse en node02 y node03, y la evidencia debe fluir directamente a node03 mediante pipelines.
---
[[Laboratorios del LFCS]]
---
