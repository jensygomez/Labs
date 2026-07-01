---
Curso: Bash Scripting para Sysadmins
Modulo: Automatización, Cron y Manejo de Errores
Playground: BS-005
Titulo: El Guardián del Cron – Automatización y Manejo de Errores
Fecha de Inicio: 2026-07-01
Dificultad: 4/10
Level Escalation: L1
Objetivo: |-
  Aprobar LFCS y RHCSA
  Pensar como Sysadmin Linux Pleno
  Prepararme para DevOps Engineer y Sysadmin Kubernetes
Temas: |-
  Manejo de errores con `set -e` (abortar en el primer fallo)
  Captura de señales con `trap` (ERR, EXIT, INT, TERM)
  Logging con marcas de tiempo (`date +"%Y-%m-%d %H:%M:%S"`)
  Redirección de stdout y stderr (`>>`, `2>&1`)
  Programación de tareas con `cron` y `crontab -e`
  Variables de entorno en cron (`PATH`, `SHELL`, `MAILTO`)
  Validación de permisos y existencia de rutas antes de ejecutar
  Niveles de severidad en logs (INFO, WARN, ERROR)
Competencias: |-
  Configurar `set -e` y `set -o pipefail` para detectar fallos en pipelines
  Usar `trap` para ejecutar limpieza o notificaciones al fallar el script
  Generar logs rotados o con marca de tiempo precisa en `/var/log/`
  Diferenciar entre salida estándar y errores (`2>&1`, `>>`)
  Programar un cronjob diario a las 02:00 AM con `crontab -l` y verificación
  Evitar el "fallo silencioso" típico de backups mal monitoreados
  Validar idempotencia: no duplicar la entrada en crontab al re-ejecutar
  Manejar entornos mínimos de `cron` (PATH reducido, sin TTY)
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  LAB_ID="BS-005-v1"
  LAB_NAME="El Guardián del Cron"
  USER_CURRENT=$(whoami)
  WORK_DIR="$HOME/lab-bash-005"
  DB_SOURCE="$WORK_DIR/db/produccion.sql"
  BACKUP_DIR="$WORK_DIR/backups"
  LOG_FILE="$WORK_DIR/backup.log"
  SCRIPT_TARGET="$WORK_DIR/guardian_del_cron.sh"

  echo -e "\e[1;33m⏳ Preparando entorno de laboratorio...\e[0m"
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR/db"
  mkdir -p "$BACKUP_DIR"

  # ==============================================================================
  # Generar base de datos SQL simulada (~50 líneas realistas)
  # ==============================================================================
  cat > "$DB_SOURCE" << 'SQLEOF'
  -- =============================================================================
  -- MySQL dump 8.0.35
  -- Host: db-prod-01    Database: produccion
  -- Server version: 8.0.35
  -- Dump completed on 2026-07-01  1:30:00
  -- =============================================================================

  /*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
  /*!40101 SET NAMES utf8mb4 */;

  --
  -- Table structure for table `usuarios`
  --

  DROP TABLE IF EXISTS `usuarios`;
  CREATE TABLE `usuarios` (
    `id` int NOT NULL AUTO_INCREMENT,
    `nombre` varchar(100) NOT NULL,
    `email` varchar(150) NOT NULL,
    `rol` enum('admin','editor','viewer') DEFAULT 'viewer',
    `creado` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `email` (`email`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

  --
  -- Dumping data for table `usuarios`
  --

  INSERT INTO `usuarios` VALUES (1,'Ana García','ana@empresa.com','admin','2026-01-15 10:30:00');
  INSERT INTO `usuarios` VALUES (2,'Luis Martínez','luis@empresa.com','editor','2026-01-16 11:45:00');
  INSERT INTO `usuarios` VALUES (3,'María López','maria@empresa.com','viewer','2026-02-01 09:15:00');
  INSERT INTO `usuarios` VALUES (4,'Carlos Ruiz','carlos@empresa.com','editor','2026-02-10 14:20:00');
  INSERT INTO `usuarios` VALUES (5,'Sofía Hernández','sofia@empresa.com','admin','2026-02-15 16:00:00');
  INSERT INTO `usuarios` VALUES (6,'Javier Torres','javier@empresa.com','viewer','2026-03-01 08:30:00');
  INSERT INTO `usuarios` VALUES (7,'Elena Díaz','elena@empresa.com','editor','2026-03-05 10:10:00');
  INSERT INTO `usuarios` VALUES (8,'Roberto Sánchez','roberto@empresa.com','viewer','2026-03-12 13:45:00');
  INSERT INTO `usuarios` VALUES (9,'Patricia Flores','patricia@empresa.com','editor','2026-03-20 15:30:00');
  INSERT INTO `usuarios` VALUES (10,'Miguel Ramírez','miguel@empresa.com','admin','2026-04-01 09:00:00');
  INSERT INTO `usuarios` VALUES (11,'Laura Mendoza','laura@empresa.com','viewer','2026-04-10 11:20:00');
  INSERT INTO `usuarios` VALUES (12,'Diego Vargas','diego@empresa.com','editor','2026-04-18 14:50:00');
  INSERT INTO `usuarios` VALUES (13,'Carmen Castro','carmen@empresa.com','viewer','2026-05-02 10:05:00');
  INSERT INTO `usuarios` VALUES (14,'Andrés Ortiz','andres@empresa.com','editor','2026-05-15 16:40:00');
  INSERT INTO `usuarios` VALUES (15,'Isabella Reyes','isabella@empresa.com','admin','2026-06-01 08:15:00');

  --
  -- Table structure for table `pedidos`
  --

  DROP TABLE IF EXISTS `pedidos`;
  CREATE TABLE `pedidos` (
    `id` int NOT NULL AUTO_INCREMENT,
    `usuario_id` int NOT NULL,
    `total` decimal(10,2) NOT NULL,
    `estado` enum('pendiente','pagado','enviado','cancelado') DEFAULT 'pendiente',
    `fecha` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `usuario_id` (`usuario_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

  INSERT INTO `pedidos` VALUES (1,1,1250.50,'pagado','2026-06-20 10:15:00');
  INSERT INTO `pedidos` VALUES (2,3,890.00,'enviado','2026-06-21 11:30:00');
  INSERT INTO `pedidos` VALUES (3,5,2100.75,'pagado','2026-06-22 14:45:00');
  INSERT INTO `pedidos` VALUES (4,2,450.25,'pendiente','2026-06-23 09:20:00');
  INSERT INTO `pedidos` VALUES (5,7,1675.00,'pagado','2026-06-24 16:10:00');
  INSERT INTO `pedidos` VALUES (6,10,3200.90,'enviado','2026-06-25 13:00:00');
  INSERT INTO `pedidos` VALUES (7,4,525.60,'cancelado','2026-06-26 10:45:00');
  INSERT INTO `pedidos` VALUES (8,9,1890.00,'pagado','2026-06-27 15:30:00');
  INSERT INTO `pedidos` VALUES (9,12,740.25,'pendiente','2026-06-28 11:15:00');
  INSERT INTO `pedidos` VALUES (10,15,4500.00,'pagado','2026-06-29 09:50:00');
  INSERT INTO `pedidos` VALUES (11,6,320.80,'enviado','2026-06-29 14:20:00');
  INSERT INTO `pedidos` VALUES (12,8,1100.50,'pagado','2026-06-30 10:00:00');

  --
  -- Dump completed on 2026-07-01  1:30:00
  -- =============================================================================
  /*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
  SQLEOF

  clear

  # ==============================================================================
  # Mostrar ticket de incidente en pantalla
  # ==============================================================================
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;36m  TICKET INC-4782  │  Severidad: SEV-2  │  Ambiente: PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  ⏱️  $LAB_ID — $LAB_NAME\e[0m"
  echo -e "  Módulo: Automatización y Manejo de Errores  │  Dificultad: \e[1;32m4/10\e[0m  │  Nivel: L1"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Jump-Host — \e[1;32m$USER_CURRENT\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  \e[1;37m📋 SÍNTOMA REPORTADO:\e[0m"
  echo -e "  El script de backup de la BD de producción \e[1mfalló silenciosamente\e[0m"
  echo -e "  durante 3 días. Nadie se enteró hasta que un cliente reportó datos"
  echo -e "  inconsistentes. El CTO exige: \e[1mmanejo estricto de errores, logs con"
  echo -e "  timestamp, y programación automática vía cron.\e[0m"
  echo ""
  echo -e "  \e[1;37m🎯 TAREA ESPERADA:\e[0m"
  echo -e "  El ingeniero L3 dejó el script \e[1mcasi terminado\e[0m. Solo tienes que"
  echo -e "  completar \e[1m5 huecos\e[0m marcados con '>>> COMPLETA'. Cada hueco tiene"
  echo -e "  una pista conceptual y preguntas guía."
  echo ""
  echo -e "  \e[1;37m📝 NOTA DEL INGENIERO L3:\e[0m"
  echo -e "  \e[3m\"Las pistas te dicen QUÉ hacer, no CÓMO. Tendrás que pensar un poco\e[0m"
  echo -e "  \e[3my consultar la documentación. Eso es lo que hace un sysadmin real.\" \e[0m"

  # ==============================================================================
  # Crear el script INCOMPLETO (nivel 4/10 - guiado pero con más conceptos)
  # ==============================================================================
  cat > "$SCRIPT_TARGET" << 'INNEREOF'
  #!/bin/bash
  # ==============================================================================
  # TICKET: INC-4782  |  Dificultad: 4/10
  # Script: guardian_del_cron.sh
  # Autor original: Valeria (L3) - dejó el 85% listo, solo faltan 5 huecos.
  # ==============================================================================

  # Variables de configuración
  BACKUP_DIR="$HOME/lab-bash-005/backups"
  DB_SOURCE="$HOME/lab-bash-005/db/produccion.sql"
  LOG_FILE="$HOME/lab-bash-005/backup.log"
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql.gz"
  MAX_BACKUPS=7
  SCRIPT_PATH="$HOME/lab-bash-005/guardian_del_cron.sh"

  # ==============================================================================
  # PASO 1: Activar modo estricto (para detectar fallos silenciosos)
  # ==============================================================================
  # El script anterior NO tenía esto, por eso los errores pasaban desapercibidos.
  # - set -e        → aborta el script si cualquier comando falla (exit code != 0)
  # - set -o pipefail → si un comando dentro de un pipeline falla, todo el pipeline falla
  # ==============================================================================
  # >>> COMPLETA AQUÍ (2 líneas) <<<
  # Necesitas activar DOS opciones de bash que hacen el script "paranoico":
  # 1) Una opción que aborta el script si CUALQUIER comando retorna error
  # 2) Otra opción que hace que los pipelines fallen si CUALQUIER comando del pipeline falla
  # 
  # Pista conceptual: Son dos comandos "set" diferentes. El primero es muy común en scripts
  # profesionales. El segundo se activa con "set -o NOMBRE_OPCION".
  # 
  # Pregunta: ¿Qué pasa si un comando como "ls archivo_inexistente" falla sin estas opciones?
  # Respuesta: El script continúa como si nada pasó. Eso es exactamente lo que NO queremos.


  # ==============================================================================
  # PASO 2: Función de logging con timestamp
  # ==============================================================================
  # Cada mensaje debe quedar registrado con fecha exacta para auditoría.
  # Formato esperado: [2026-07-01 02:00:05] [INFO] Mensaje aquí
  # ==============================================================================
  log_msg() {
      local level=$1
      local msg=$2
      # >>> COMPLETA AQUÍ (1 línea) <<<
      # Necesitas construir una línea con este formato exacto:
      # [FECHA_HORA] [NIVEL] MENSAJE
      # 
      # Donde:
      # - FECHA_HORA: formato "YYYY-MM-DD HH:MM:SS" (pista: el comando date con formato)
      # - NIVEL: viene en la variable $level (INFO, ERROR, WARN)
      # - MENSAJE: viene en la variable $msg
      # 
      # Además, esa línea debe:
      # 1) Imprimirse en pantalla (para que el usuario la vea en tiempo real)
      # 2) Guardarse en el archivo de log (para auditoría posterior)
      # 
      # Pista conceptual: Existe un comando que hace AMBAS cosas simultáneamente.
      # Ese comando se llama "tee" y funciona como una T en tubería: divide el flujo.
      # 
      # Pregunta: ¿Cómo le dices a tee que AÑADA al archivo en vez de sobrescribirlo?
      # Respuesta: Revisa la documentación de tee (man tee) y busca la opción para "append".


  # ==============================================================================
  # PASO 3: Trap para capturar errores (el "guardián" del script)
  # ==============================================================================
  # Si algo falla, queremos saber EXACTAMENTE en qué línea ocurrió.
  # La señal ERR se dispara cuando un comando retorna exit code != 0.
  # Dentro del trap, $LINENO = línea actual, $? = código de salida del fallo.
  # ==============================================================================
  # >>> COMPLETA AQUÍ (1 línea) <<<
  # Necesitas configurar un "trap" que se active cuando ocurra un error.
  # 
  # Concepto: Un trap es como un "event handler" en programación. Cuando ocurre
  # un evento específico (en este caso, la señal ERR), se ejecuta un comando.
  # 
  # Sintaxis básica: trap 'COMANDO_A_EJECUTAR' SEÑAL
  # 
  # El comando que debe ejecutarse es:
  #   log_msg "ERROR" "Script falló en línea $LINENO (código: $?)"
  # 
  # Variables especiales que puedes usar DENTRO del trap:
  # - $LINENO: número de línea donde ocurrió el error
  # - $?: código de salida del comando que falló (0=éxito, !=0 error)
  # 
  # Pregunta: ¿Por qué el comando está entre comillas simples y no dobles?
  # Respuesta: Porque queremos que $LINENO y $? se evalúen EN EL MOMENTO del error,
  # no cuando se define el trap. Las comillas simples retrasan la expansión.


  # ==============================================================================
  # PASO 4: Validaciones iniciales (falla RÁPIDO si algo está mal)
  # ==============================================================================
  log_msg "INFO" "========== Iniciando backup =========="

  if [ ! -f "$DB_SOURCE" ]; then
      log_msg "ERROR" "No existe la BD fuente: $DB_SOURCE"
      exit 1
  fi

  mkdir -p "$BACKUP_DIR"
  log_msg "INFO" "Fuente: $DB_SOURCE"
  log_msg "INFO" "Destino: $BACKUP_FILE"

  # ==============================================================================
  # PASO 5: Ejecutar el backup (comprimir la BD)
  # ==============================================================================
  # Usamos gzip para comprimir el archivo SQL y ahorrar espacio.
  # -c → escribe en stdout (no modifica el original)
  # >  → redirige la salida al archivo de backup
  # ==============================================================================
  # >>> COMPLETA AQUÍ (1 línea) <<<
  # Necesitas comprimir el archivo SQL y guardarlo en un nuevo archivo .gz
  # 
  # Concepto: gzip es un compresor. Por defecto, reemplaza el archivo original.
  # Pero nosotros queremos:
  # 1) Mantener el archivo SQL original intacto
  # 2) Crear un NUEVO archivo comprimido
  # 
  # Opción clave de gzip: -c (o --stdout)
  # Esta opción hace que gzip escriba la salida comprimida en stdout en vez de
  # modificar el archivo original.
  # 
  # Luego necesitas redirigir esa salida al archivo de destino.
  # 
  # Pregunta: ¿Qué operador de redirección usas para enviar stdout a un archivo?
  # Respuesta: Es el mismo que usaste en BS-004 para guardar resultados de pipelines.
  # 
  # Ejemplo conceptual (NO es la respuesta, solo muestra la estructura):
  #   comando_con_opcion_c "$ARCHIVO_ORIGINAL" > "$ARCHIVO_DESTINO"


  # ==============================================================================
  # PASO 6: Verificar que el backup se creó correctamente
  # ==============================================================================
  if [ ! -f "$BACKUP_FILE" ]; then
      log_msg "ERROR" "El archivo de backup NO se creó"
      exit 1
  fi

  BACKUP_SIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || stat -f%z "$BACKUP_FILE")
  log_msg "INFO" "✅ Backup completado: $BACKUP_FILE ($BACKUP_SIZE bytes)"

  # ==============================================================================
  # PASO 7: Rotación de backups (mantener solo los últimos MAX_BACKUPS)
  # ==============================================================================
  cd "$BACKUP_DIR"
  ls -t backup_*.sql.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f
  ACTUALES=$(ls backup_*.sql.gz 2>/dev/null | wc -l)
  log_msg "INFO" "Rotación completada. Backups conservados: $ACTUALES / $MAX_BACKUPS"

  # ==============================================================================
  # PASO 8: Programar en cron (idempotente - no duplica si ya existe)
  # ==============================================================================
  # Formato cron: minuto hora día_mes mes día_semana comando
  # "0 2 * * *" = todos los días a las 02:00 AM
  # ==============================================================================
  CRON_JOB="0 2 * * * $SCRIPT_PATH >> $LOG_FILE 2>&1"
  CRON_MARKER="# BS-005 Guardian del Cron"

  if crontab -l 2>/dev/null | grep -qF "$CRON_MARKER"; then
      log_msg "INFO" "Cronjob ya existe (idempotencia). No se duplica."
  else
      (crontab -l 2>/dev/null; echo "$CRON_MARKER"; echo "$CRON_JOB") | crontab -
      log_msg "INFO" "✅ Cronjob programado: diario a las 02:00 AM"
  fi

  log_msg "INFO" "========== Proceso finalizado =========="
  exit 0
  INNEREOF

  chmod 644 "$SCRIPT_TARGET"

  echo ""
  echo -e "\e[1;32m✔ Entorno de laboratorio listo.\e[0m"
  echo -e "📂 Ruta de trabajo: \e[1;33mcd $WORK_DIR\e[0m"
  echo -e "📝 Resuelve el script con: \e[1;33mnano $SCRIPT_TARGET\e[0m"
  echo -e "🗄️  BD de prueba: \e[1;33m$DB_SOURCE\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  echo -e "\e[1;37m📋 DEFINICIÓN DE 'RESUELTO' (Definition of Done):\e[0m"
  echo -e "  ☐ El script usa \e[1mset -e\e[0m y \e[1mset -o pipefail\e[0m (Paso 1)"
  echo -e "  ☐ Los logs tienen formato \e[1m[YYYY-MM-DD HH:MM:SS] [NIVEL] mensaje\e[0m (Paso 2)"
  echo -e "  ☐ El \e[1mtrap\e[0m captura errores y reporta la línea exacta (Paso 3)"
  echo -e "  ☐ El backup se comprime con \e[1mgzip -c\e[0m correctamente (Paso 5)"
  echo -e "  ☐ El cronjob está programado a las \e[1m02:00 AM\e[0m (Paso 8, ya resuelto)"
  echo -e "  ☐ El archivo \e[1m$LOG_FILE\e[0m registra cada ejecución con timestamp"
  echo ""
  echo -e "\e[1;33m💡 GUÍAS CONCEPTUALES (si te trabas):\e[0m"
  echo -e ""
  echo -e "  \e[1mPaso 1 — Modo estricto:\e[0m"
  echo -e "     Piensa en esto: ¿Qué opciones de bash hacen que el script sea 'paranoico'?"
  echo -e "     Una aborta en el primer error. La otra hace que los pipelines fallen si"
  echo -e "     CUALQUIER comando del pipeline falla. Consulta: \e[1mman bash | less -p '^ *set'\e[0m"
  echo -e ""
  echo -e "  \e[1mPaso 2 — Logging con timestamp:\e[0m"
  echo -e "     Necesitas un comando que haga DOS cosas a la vez:"
  echo -e "     1) Imprimir en pantalla  2) Guardar en archivo"
  echo -e "     Ese comando es como una 'T' en una tubería: divide el flujo en dos."
  echo -e "     Consulta: \e[1mman tee\e[0m y busca la opción para 'append' (añadir, no sobrescribir)."
  echo -e ""
  echo -e "  \e[1mPaso 3 — Trap para errores:\e[0m"
  echo -e "     Un trap es como un 'event handler'. Sintaxis: \e[1mtrap 'COMANDO' SEÑAL\e[0m"
  echo -e "     La señal que te interesa es \e[1mERR\e[0m (se dispara cuando un comando falla)."
  echo -e "     Dentro del trap puedes usar \e[1m\$LINENO\e[0m (línea actual) y \e[1m\$?\e[0m (código de salida)."
  echo -e "     Pregunta clave: ¿Por qué usar comillas simples y no dobles en el comando del trap?"
  echo -e ""
  echo -e "  \e[1mPaso 5 — Comprimir con gzip:\e[0m"
  echo -e "     Por defecto, gzip REEMPLAZA el archivo original. Pero tú quieres:"
  echo -e "     1) Mantener el SQL original intacto  2) Crear un NUEVO archivo .gz"
  echo -e "     Revisa: \e[1mman gzip\e[0m y busca la opción que escribe en \e[1mstdout\e[0m en vez de"
  echo -e "     modificar el archivo. Luego redirige esa salida al archivo de destino."
  echo -e ""
  echo -e "  \e[1mPaso 8 — Cron (ya viene resuelto, solo revísalo):\e[0m"
  echo -e "     Formato cron: \e[1mminuto hora día_mes mes día_semana comando\e[0m"
  echo -e "     \e[1m0 2 * * *\e[0m = minuto 0, hora 2, todos los días = 02:00 AM diario"
  echo -e "     Verifica con: \e[1mcrontab -l\e[0m"
  echo ""
  echo -e "\e[1;37m📚 DOCUMENTACIÓN ÚTIL:\e[0m"
  echo -e "  • Opciones de bash: \e[1mman bash\e[0m (busca 'set -e' y 'set -o pipefail')"
  echo -e "  • Comando tee: \e[1mman tee\e[0m (divide el flujo, opción -a para append)"
  echo -e "  • Traps: \e[1mhelp trap\e[0m o \e[1mman bash | less -p '^ *trap'\e[0m"
  echo -e "  • Compresión: \e[1mman gzip\e[0m (opción -c para stdout)"
  echo -e "  • Cron: \e[1mman 5 crontab\e[0m (formato de los campos de tiempo)"
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  EOF
  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - LFCS
  - RHCSA
  - Cron
  - Bash
  - Trap
  - Logging
  - Automatizacion
---

[[Laboratorios del LFCS]]

---
