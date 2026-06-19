---
Curso: Bash Scripting para Sysadmins
Modulo: Bucles, Archivos y Manipulación de Datos
Playground: BS-003-v1
Titulo: La Fábrica de Usuarios – Bucles y Archivos
Fecha de Inicio: 2026-06-19
Dificultad: 4/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para Devops Enginner y Kubernets
Temas: |-
  - Bucles `for` e iteración sobre listas
  - Lectura de archivos línea por línea con `while read`
  - Manipulación de cadenas con `cut`, `awk` y parameter expansion
  - Creación de usuarios con `useradd` y grupos secundarios
  - Generación de contraseñas aleatorias con `/dev/urandom`
  - Logging con marcas de tiempo
Competencias: |-
  - Procesar archivos CSV o delimitados línea por línea de forma segura en Bash.
  - Automatizar la creación masiva de usuarios del sistema respetando convenciones de nomenclatura y políticas de grupos.
  - Generar contraseñas seguras y almacenarlas en un log auditable para posterior comunicación al usuario.
  - Manejar errores durante la creación de usuarios (usuario ya existente, grupo inexistente) sin abortar todo el lote.
  - Aplicar técnicas de parsing de texto (`cut`, `awk`, IFS) para extraer campos de registros estructurados.
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  LAB_ID="BS-003-v1"
  LAB_NAME="La Fábrica de Usuarios"
  USER_CURRENT=$(whoami)
  WORK_DIR="$HOME/lab-bash-003"
  CSV_FILE="$WORK_DIR/empleados_nuevos.csv"
  LOG_FILE="$WORK_DIR/creacion_usuarios.log"
  SCRIPT_TARGET="$WORK_DIR/crear_usuarios.sh"

  echo -e "\e[1;33m⏳ Preparando entorno de laboratorio...\e[0m"
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"

  # Generar CSV con 50 empleados ficticios (nombre,apellido,departamento)
  cat > "$CSV_FILE" << 'CSVEOL'
Maria,Gonzalez,desarrollo
Juan,Perez,infraestructura
Laura,Rodriguez,desarrollo
Carlos,Martinez,qa
Ana,Sanchez,infraestructura
Pedro,Ramirez,desarrollo
Sofia,Torres,qa
Miguel,Flores,infraestructura
Lucia,Rivera,desarrollo
Diego,Cruz,qa
Valentina,Morales,infraestructura
Andres,Ortiz,desarrollo
Camila,Gutierrez,qa
Fernando,Chavez,infraestructura
Isabella,Rojas,desarrollo
Ricardo,Medina,qa
Gabriela,Aguilar,infraestructura
Oscar,Delgado,desarrollo
Natalia,Vega,qa
Alejandro,Navarro,infraestructura
Paula,Romero,desarrollo
Hugo,Molina,qa
Valeria,Castro,infraestructura
Francisco,Ruiz,desarrollo
Daniela,Alvarez,qa
Raul,Suarez,infraestructura
Elena,Dominguez,desarrollo
Sergio,Vazquez,qa
Adriana,Mendez,infraestructura
Jorge,Jimenez,desarrollo
Monica,Iglesias,qa
Ruben,Santos,infraestructura
Claudia,Cortes,desarrollo
Alberto,Marquez,qa
Silvia,Fuentes,infraestructura
Gustavo,Garrido,desarrollo
Patricia,Calvo,qa
Eduardo,Cabrera,infraestructura
Veronica,Nieto,desarrollo
Raul,Pascual,qa
Lorena,Gimenez,infraestructura
Antonio,Peña,desarrollo
Beatriz,Lara,qa
Victor,Rios,infraestructura
Cristina,Bravo,desarrollo
Roberto,Aguirre,qa
Sandra,Leon,infraestructura
Mario,Velasco,desarrollo
Alicia,Mora,qa
Pablo,Delgado,infraestructura
CSVEOL

  # Crear algunos grupos de departamento para simular el entorno
  for grp in desarrollo infraestructura qa; do
      sudo groupadd -f "$grp" 2>/dev/null || true
  done

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "  TICKET INC-3003  │  Severidad: MEDIA  │  Ambiente: ESTACIÓN LOCAL"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "  \e[1;33m⏱️  $LAB_ID — $LAB_NAME\e[0m"
  echo -e "  Módulo: Bucles y Archivos  │  Dificultad: 4/10  │  Nivel: L2"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Estación del Administrador — \e[1;32m$USER_CURRENT\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  El área de \e[1mRecursos Humanos\e[0m ha terminado el proceso de onboarding de"
  echo -e "  \e[1m50 nuevos empleados\e[0m. Te han entregado un archivo CSV con la información"
  echo -e "  básica de cada persona:"
  echo ""
  echo -e "      \e[1;37m$CSV_FILE\e[0m"
  echo ""
  echo -e "  El formato es: \e[1mnombre,apellido,departamento\e[0m (sin encabezado)."
  echo -e "  Departamentos válidos: \e[1mdesarrollo, infraestructura, qa\e[0m."
  echo ""
  echo -e "  Se requiere un script que procese este archivo línea por línea e, \e[1mpara"
  echo -e "  cada registro\e[0m:"
  echo -e "    1. Cree un usuario Linux con formato \e[1mnombre.apellido\e[0m (minúsculas)."
  echo -e "    2. Asigne como grupo secundario el departamento correspondiente."
  echo -e "    3. Genere una contraseña aleatoria de 12 caracteres."
  echo -e "    4. Registre la acción (éxito o fallo) en un log con marca de tiempo."
  echo ""
  echo -e "  Tu misión es completar el script \e[1mcrear_usuarios.sh\e[0m utilizando"
  echo -e "  bucles (\e[1mwhile read\e[0m), parsing de cadenas (\e[1mcut\e[0m / \e[1mawk\e[0m) y"
  echo -e "  manipulación de usuarios con \e[1museradd\e[0m."
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m Leer el CSV línea por línea con \e[1mwhile read\e[0m                 \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Extraer campos con \e[1mcut\e[0m o \e[1mawk\e[0m y normalizar a minúsculas  \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Crear usuario con \e[1museradd -m -G <grupo>\e[0m si no existe        \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Generar contraseña aleatoria con \e[1m/dev/urandom\e[0m              \e[0;35m→ 15%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Registrar cada operación en \e[1m$LOG_FILE\e[0m con timestamp         \e[0;35m→ 20%\e[0m"
  echo ""
  echo -e "\e[1;31m  REGLA DE ORO:\e[0m Un bucle mal diseñado puede crear (o romper) 50 cuentas en segundos."
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""

  cat << 'EOF_INNER' > "$SCRIPT_TARGET"
  #!/bin/bash
  # ==============================================================================
  # Script: crear_usuarios.sh
  # Objetivo: Procesar CSV y crear usuarios Linux con grupos y contraseñas.
  # ==============================================================================

  CSV_FILE="$HOME/lab-bash-003/empleados_nuevos.csv"
  LOG_FILE="$HOME/lab-bash-003/creacion_usuarios.log"

  # Asegurar que el log existe
  touch "$LOG_FILE"

  echo "=== INICIO DE PROCESO: $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"

  # TODO 1: Leer el CSV línea por línea con 'while read'.
  # Pista: Usa 'while IFS= read -r linea' para preservar espacios (aunque no los haya).
  # while IFS= read -r linea || [ -n "$linea" ]; do
  #     ...
  # done < "$CSV_FILE"

  # TODO 2: Extraer nombre, apellido y departamento usando 'cut' o 'awk'.
  # nombre=$(echo "$linea" | cut -d',' -f1 | tr '[:upper:]' '[:lower:]')
  # apellido=$(echo "$linea" | cut -d',' -f2 | tr '[:upper:]' '[:lower:]')
  # depto=$(echo "$linea" | cut -d',' -f3 | tr '[:upper:]' '[:lower:]')

  # TODO 3: Construir el nombre de usuario: nombre.apellido (minúsculas).
  # username="${nombre}.${apellido}"

  # TODO 4: Verificar si el usuario ya existe (id "$username" &>/dev/null).
  # Si existe, registrar un WARNING y continuar (no abortar).
  # if id "$username" &>/dev/null; then
  #     echo "[WARNING] Usuario $username ya existe. Saltando..." | tee -a "$LOG_FILE"
  #     continue
  # fi

  # TODO 5: Crear el usuario con 'useradd -m -G "$depto" "$username"'.
  # Capturar el código de salida ($?) para decidir si fue exitoso.
  # sudo useradd -m -G "$depto" "$username" 2>/dev/null
  # if [ $? -eq 0 ]; then
  #     # TODO 6: Generar contraseña aleatoria de 12 caracteres.
  #     # password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
  #     # echo "$username:$password" | sudo chpasswd
  #
  #     # TODO 7: Registrar en el log con marca de tiempo.
  #     # echo "[$(date '+%Y-%m-%d %H:%M:%S')] CREADO: $username | Depto: $depto | Pass: $password" >> "$LOG_FILE"
  # else
  #     echo "[ERROR] Falló la creación de $username" | tee -a "$LOG_FILE"
  # fi

  # done

  echo "=== FIN DE PROCESO: $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"
  echo "✅ Proceso completado. Revisá el log: $LOG_FILE"
  EOF_INNER

  chmod 644 "$SCRIPT_TARGET"

  echo -e "\e[1;32m✔ Entorno configurado exitosamente.\e[0m"
  echo -e "📂 Ingresa al directorio de trabajo con: \e[1;33mcd $WORK_DIR\e[0m"
  echo -e "📝 Tu script para editar es: \e[1;33m$SCRIPT_TARGET\e[0m"
  echo -e "📄 Datos de entrada: \e[1;33m$CSV_FILE\e[0m (50 registros)"
  echo -e "\e[1;36m¡Buena suerte, Sysadmin! Los bucles son tu línea de ensamblaje.\e[0m"
  EOF

  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - LFCS
  - RHCSA
---
[[Laboratorios del LFCS]]
---
While reviewing the onboarding pipeline, I noticed that every time HR hired a batch of employees, the IT team spent hours creating accounts manually — a tedious, error-prone process that delayed new hires from accessing their tools on day one. The CSV file they sent was clean, structured, and perfect for automation, but nobody had written a script to consume it.

I built a Bash script that read the CSV line by line using `while read`, parsing each record with `cut` to extract the name, last name, and department. For every line, the script constructed a username in the format `name.lastname`, verified it didn't already exist, and if it was new, created the account with `useradd -m -G <department>`. A secondary group per department already existed, so the script simply referenced it. Then it generated a random 12-character password using `/dev/urandom` and `tr`, set it with `chpasswd`, and appended a timestamped entry to a log file.

The script was intentionally non-destructive: if a user already existed, it logged a warning and moved on instead of failing. By the time the loop finished, 50 new users had system accounts, correct secondary groups, and initial passwords — all documented in an auditable log. What used to take a full morning now took under a minute, and HR received a clean report they could forward to each employee.

---

<!-- REPAIR-HINT:
Si el verify falla, ejecuta en node01:
  sudo bash /tmp/verify-bs-003-v1.sh --fix
Esto re-aplica solo el provisioning del Vagrantfile sin destruir la VM.
-->