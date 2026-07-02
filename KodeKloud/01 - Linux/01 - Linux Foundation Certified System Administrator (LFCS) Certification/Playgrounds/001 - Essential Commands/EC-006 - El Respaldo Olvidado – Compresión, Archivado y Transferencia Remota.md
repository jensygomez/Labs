---
Curso: Transición Sysadmin a DevOps - Essential Commands LFCS/RHCSA
Modulo: Essential Commands (Compresión, Archivado y Transferencia Remota)
Playground: EC-006
Titulo: El Respaldo Olvidado – Compresión, Archivado y Transferencia Remota
Fecha de Inicio: 2026-07-02
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Archivado clásico e incremental con tar (--listed-incremental)
  - Compresión multinivel y algoritmos= gzip (-z), bzip2 (-j), xz (-J), zip/unzip
  - Sincronización eficiente y diferencial con rsync y sus modificadores avanzados
  - Copia segura con scp y túneles SSH como transporte de flujos
  - Verificación de integridad criptográfica (md5sum, sha256sum)
  - Optimización de transferencia de datos mediante pipelines directo a red (tar + ssh / rsync)
Competencias: |-
  - Diseñar e implementar estrategias de respaldo incremental utilizando los metadatos de tar para capturar únicamente los deltas de directorios críticos.
  - Evaluar y seleccionar el algoritmo de compresión adecuado (gzip, bzip2, xz) balanceando el uso de CPU, la velocidad de transferencia y las restricciones de almacenamiento.
  - Orquestar la transferencia masiva de datos usando rsync con persistencia de transferencias truncadas (--partial), compresión en tránsito (--compress) y purga de archivos huérfanos (--delete).
  - Validar la consistencia de los datos post-transferencia mediante la generación, exportación y contraste automatizado de hashes criptográficos (SHA256/MD5).
  - Eliminar el cuello de botella del almacenamiento local mediante el uso de tuberías (pipes) para empaquetar, comprimir y transmitir datos directamente a través de SSH hacia node03 sin materializar archivos temporales intermedios.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_ec006.sh
  #!/bin/bash
  set -e

  PASS="caleston123"
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT}"

  echo -e "\e[1;33m⏳ Verificando dependencias en node01...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      echo caleston123 | sudo -S apt-get install -y sshpass -qq
  fi

  echo -e "\e[1;33m⏳ Instalando herramientas de compresión en nodos remotos...\e[0m"
  $SSH2 "echo caleston123 | sudo -S apt-get install -y tar gzip bzip2 xz-utils rsync zip unzip -qq 2>/dev/null || true"
  $SSH3 "echo caleston123 | sudo -S apt-get install -y tar gzip bzip2 xz-utils rsync zip unzip -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Generando entorno caótico de logs y datos en node02...\e[0m"
  $SSH2 bash << 'NODE02_INJECT' || echo -e "\e[1;33m  [!] Detalle en node02, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'

      # 1. Crear directorios de origen críticos
      mkdir -p /opt/data
      mkdir -p /var/log/apps
      mkdir -p /var/www/html
      mkdir -p /var/lib/db
      mkdir -p /etc/network_configs

      # 2. Generar archivos de prueba balanceados (texto repetitivo para evaluar compresión real)
      echo "[!] Generando datos de benchmarking en /opt/data..."
      for i in {1..5}; do
          base64 /dev/urandom | head -c 2M > /opt/data/file_${i}.txt
          cat /opt/data/file_${i}.txt /opt/data/file_${i}.txt > /opt/data/heavy_${i}.log
      done

      # 3. Generar archivos para simulación de Backup Incremental
      echo "Log inicial de auditoría de seguridad" > /var/log/apps/auth.log
      echo "Registro del servidor de transacciones v1" > /var/log/apps/api.log
      
      # 4. Generar entorno para rsync (sitio web con contenido estructurado)
      echo "<html><body><h1>App Production</h1></body></html>" > /var/www/html/index.html
      echo "background-color: #fff;" > /var/www/html/style.css
      mkdir -p /var/www/html/assets
      echo "fake_image_data" > /var/www/html/assets/logo.png

      # 5. Generar datos críticos de red e integridad
      echo "DEVICE=eth0\nBOOTPROTO=dhcp\nONBOOT=yes" > /etc/network_configs/ifcfg-eth0
      echo "NAMESERVER=8.8.8.8" > /etc/network_configs/resolv.conf

      # 6. Base de datos simulada para Streaming Backup sin espacio local
      echo "DATABASE UNIVERSE SYSTEM DATA DEFINITION" > /var/lib/db/production.db
      for i in {1..20}; do
          echo "TABLE USERS RECORD $i: DATA DATA DATA" >> /var/lib/db/production.db
      done

      echo "[EC-006] Entorno de almacenamiento y respaldos inyectado en node02."
  SUDO_INNER
  NODE02_INJECT

  echo -e "\e[1;33m⏳ Preparando bóveda de almacenamiento central en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/backup-vault/
      mkdir -p /opt/backup-vault/benchmarks
      mkdir -p /opt/backup-vault/incrementals
      mkdir -p /opt/backup-vault/web-mirror
      mkdir -p /opt/backup-vault/integrity
      mkdir -p /opt/backup-vault/streaming
      chown -R bob:bob /opt/backup-vault/
      chmod -R 755 /opt/backup-vault/
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en preparación de node03, continuando...\e[0m'"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m EC-006-v1 | El Respaldo Olvidado | Dificultad: 6/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda Central: node03:/opt/backup-vault/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El equipo de infraestructura reporta que los scripts manuales de backup en node02"
  echo -e " están colapsando el espacio en disco local. Generan archivos .tar gigantescos"
  echo -e " de 10GB que saturan el nodo y tardan horas en transferirse de forma ineficiente."
  echo -e ""
  echo -e " Tu misión como Administrador de Sistemas Linux L2 es optimizar y migrar la"
  echo -e " estrategia de respaldo hacia un esquema moderno, multinivel, incremental e"
  echo -e " íntegro, minimizando el impacto en el almacenamiento y el uso de la red."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la ejecución de comandos se orquesta desde node01 vía SSH."
  echo -e " \e[1m>\e[0m Prohibido materializar o guardar archivos de respaldo dentro de node01."
  echo -e " \e[1m>\e[0m En la Misión 5, node02 tiene 0 bytes libres para temporales: el empaquetado"
  echo -e "   y compresión debe fluir directamente a node03 vía pipeline de red."
  echo -e ""
  echo -e "\e[1;33m MISIONES TÉCNICAS (TICKET DE RESPALDOS Y TRANSFERENCIA - NIVEL L2)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1mMISIÓN 1: Benchmark de Compresión Multinivel (20%)\e[0m"
  echo -e "    Accede a node02 y empaqueta el directorio \e[1m/opt/data\e[0m usando tres algoritmos:"
  echo -e "    - Compón un archivo \e[1mdata.tar.gz\e[0m (gzip para velocidad)"
  echo -e "    - Compón un archivo \e[1mdata.tar.bz2\e[0m (bzip2 para balance)"
  echo -e "    - Compón un archivo \e[1mdata.tar.xz\e[0m (xz para compresión máxima)"
  echo -e "    Transfiérelos a node03 en \e[1m/opt/backup-vault/benchmarks/\e[0m y compara"
  echo -e "    visualmente la reducción de tamaño lograda por cada algoritmo."
  echo -e ""
  echo -e " \e[1mMISIÓN 2: Implementación de Respaldo Incremental con tar (25%)\e[0m"
  echo -e "    Crea un respaldo estructurado del directorio \e[1m/var/log/apps\e[0m:"
  echo -e "      a) Crea el backup Full inicial llamado \e[1mfull_backup.tar.gz\e[0m usando un archivo"
  echo -e "         de metadatos (snapshot) en \e[1m/tmp/apps.snar\e[0m. Envíalo a node03."
  echo -e "      b) Simula un delta añadiendo un log (ej: \e[1mecho 'ERROR' >> /var/log/apps/api.log\e[0m)."
  echo -e "      c) Ejecuta el backup Incremental llamado \e[1mincremental_1.tar.gz\e[0m apuntando al"
  echo -e "         mismo archivo .snar. Envíalo a node03 en \e[1m/opt/backup-vault/incrementals/\e[0m."
  echo -e ""
  echo -e " \e[1mMISIÓN 3: Sincronización Inteligente Diferencial con rsync (20%)\e[0m"
  echo -e "    Sincroniza el directorio web \e[1m/var/www/html\e[0m desde node02 hacia node03 en el"
  echo -e "    directorio \e[1m/opt/backup-vault/web-mirror/\e[0m. La sincronización debe usar"
  echo -e "    parámetros avanzados para comprimir en tránsito, mantener permisos nativos,"
  echo -e "    mostrar el progreso, permitir reanudación (--partial) y purgar en el destino"
  echo -e "    cualquier archivo eliminado u obsoleto en el origen (--delete)."
  echo -e ""
  echo -e " \e[1mMISIÓN 4: Validación de Integridad Criptográfica End-to-End (15%)\e[0m"
  echo -e "    Empaqueta los archivos de red en \e[1m/tmp/network.tar.gz\e[0m a partir de \e[1m/etc/network_configs\e[0m."
  echo -e "    Genera su hash criptográfico SHA256 guardándolo en \e[1m/tmp/network.tar.gz.sha256\e[0m."
  echo -e "    Transfiere ambos archivos a node03 (\e[1m/opt/backup-vault/integrity/\e[0m) y ejecuta"
  echo -e "    remotamente la verificación nativa con \e[1msha256sum -c\e[0m para certificar el éxito."
  echo -e ""
  echo -e " \e[1mMISIÓN 5: Streaming Backup directo a Red vía Pipeline SSH (20%)\e[0m"
  echo -e "    El espacio en node02 está críticamente lleno. Empaqueta y comprime con máxima ratio (xz)"
  echo -e "    el directorio de bases de datos \e[1m/var/lib/db\e[0m y envíalo en tiempo real"
  echo -e "    hacia node03 mediante una tubería remota de SSH, salvándolo directamente en"
  echo -e "    \e[1m/opt/backup-vault/streaming/db_stream.tar.xz\e[0m sin dejar rastros locales en node02."
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Tres tipos de compresión generados y alojados en node03            20%"
  echo -e "  [ ] Par incremental (Full + Incr) configurado con archivo metadata    25%"
  echo -e "  [ ] Sincronización diferencial con rsync optimizado y purga activa     20%"
  echo -e "  [ ] Verificación de integridad exitosa vía SHA256 en node03            15%"
  echo -e "  [ ] Pipeline tar + ssh (Streaming) ejecutado sin archivos intermedios   20%"
  echo -e "                                                                         -----"
  echo -e "                                                              TOTAL:     100%"
  echo -e ""
  echo -e "\e[1;33m TIEMPO ESTIMADO: 30 minutos\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_ec006.sh && rm -f /tmp/setup_ec006.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - Backup-Strategies
  - Compression
  - rsync
  - SSH-Pipelines
  - Integrity-Verification
  - Automation
Escenario: |-
  - Situación, Desde node01 te conectas a node02, el cual aloja directorios críticos de producción que están al borde del colapso por falta de espacio en disco. Un script de backup manual obsoleto genera archivos tar gigantescos de 10GB que saturan el almacenamiento local de node02 y tardan horas en transferirse. Tu misión es transformar este proceso rústico en una arquitectura de backup eficiente, incremental, segura y que transmita directamente hacia el nodo de almacenamiento central (node03).

  Tu misión
  1. Comparar la eficiencia de los algoritmos de compresión. Toma un directorio de prueba en /opt/data/ y genera tres empaquetados diferentes usando tar combinándolo con gzip (velocidad), bzip2 (balance) y xz (máxima compresión). Registra el tiempo de ejecución de cada uno y el tamaño final del archivo para documentar la mejor estrategia según el escenario.

  2. Implementar un esquema de respaldos incrementales. Crea un backup Full inicial de /var/log/apps/ hacia node03 utilizando tar con la opción --listed-incremental apoyándote en un archivo de metadatos (snapshot file). Posteriormente, simula la creación de nuevos logs y ejecuta un segundo backup incremental que capture únicamente las modificaciones.

  3. Sincronizar repositorios de software con rsync avanzado. Debes replicar el directorio /var/www/html/ de node02 a node03. La transferencia debe ser óptima, optimiza el ancho de banda (--compress), muestra el progreso, permite reanudar descargas interrumpidas (--partial) y elimina en el destino (node03) cualquier archivo que ya no exista en el origen (node02).

  4. Garantizar la integridad "End-to-End". Antes de transferir un set de archivos de configuración críticos de /etc/network_configs.tar.gz, genera su firma digital con sha256sum en node02. Transfiere el archivo a node03 y automatiza la verificación remota de la firma para asegurar que ningún bit se haya corrompido durante el tránsito por la red.

  5. Transferencia directa por tubería (Streaming Backup). El espacio local en node02 es crítico (0 bytes disponibles para temporales). Debes empaquetar y comprimir con xz el directorio /var/lib/db/ y enviarlo directamente hacia node03 a través de un pipeline SSH (tar + ssh), de modo que el archivo comprimido se escriba directamente en el disco de node03 sin tocar el almacenamiento local de node02 ni de node01.

  Regla de Oro, No se permite la creación de archivos intermedios o temporales de gran tamaño en node02 para las tareas de transferencia directa. El flujo debe ser continuo y eficiente. Toda falla en la conexión de red debe ser prevista y controlada mediante flags nativos de las herramientas (como rsync o ssh).
---
[[Laboratorios del LFCS]]

Sure — one recent technical challenge I worked on was optimizing a backup strategy that was causing storage and performance issues on one of our servers. The team was using manual tar scripts that generated huge, single backup files, which filled up local disk space and took a long time to transfer.

First, I benchmarked three different compression algorithms — gzip, bzip2, and xz — to see which one gave the best size reduction without sacrificing too much time. I found that xz actually cut the backup size by more than half compared to gzip, which was a really useful data point for choosing the right tool for the job.

Then I moved on to implementing an incremental backup strategy using tar's snapshot feature. Instead of doing a full backup every time, I set up an initial full backup and then configured incremental backups that only capture files that changed since the last run. I tested this by modifying a log file and confirming that the incremental backup only picked up that one changed file, not the entire directory — which is exactly the behavior you want for efficiency.

It was a good exercise in thinking about storage optimization and network efficiency, not just getting a backup to work, but making it scalable