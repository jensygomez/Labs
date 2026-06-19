---
Curso: Bash Scripting para Sysadmins
Modulo: Bucles, Archivos y Manipulación de Datos
Playground: BS-003-v1
Titulo: La Fábrica de Usuarios – Bucles y Archivos - V1.0
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
  echo -e "  \e[1;37m📋 HISTORIA DEL INCIDENTE:\e[0m"
  echo -e "  El área de \e[1mRecursos Humanos\e[0m ha terminado el proceso de onboarding de"
  echo -e "  \e[1m50 nuevos empleados\e[0m. Te han entregado un archivo CSV con la información"
  echo -e "  básica de cada persona. El departamento de IT necesita que todos estos usuarios"
  echo -e "  estén creados en el sistema antes del lunes para que puedan acceder a sus"
  echo -e "  estaciones de trabajo."
  echo ""
  echo -e "  \e[1;37m📂 ARCHIVO DE ENTRADA:\e[0m"
  echo -e "      \e[1;33m$CSV_FILE\e[0m"
  echo ""
  echo -e "  \e[1;37m📄 FORMATO DEL CSV:\e[0m"
  echo -e "      \e[1mnombre,apellido,departamento\e[0m (sin encabezado)"
  echo -e "      Departamentos válidos: \e[1mdesarrollo, infraestructura, qa\e[0m"
  echo ""
  echo -e "  \e[1;37m🎯 REQUERIMIENTOS TÉCNICOS:\e[0m"
  echo -e "  Se requiere un script que procese este archivo línea por línea e, \e[1mpara"
  echo -e "  cada registro\e[0m:"
  echo ""
  echo -e "    \e[1;32m1.\e[0m Cree un usuario Linux con formato \e[1mnombre.apellido\e[0m (minúsculas)"
  echo -e "    \e[1;32m2.\e[0m Asigne como grupo secundario el departamento correspondiente"
  echo -e "    \e[1;32m3.\e[0m Genere una contraseña aleatoria de 12 caracteres"
  echo -e "    \e[1;32m4.\e[0m Registre la acción (éxito o fallo) en un log con marca de tiempo"
  echo ""
  echo -e "  \e[1;37m🛠️  HERRAMIENTAS REQUERIDAS:\e[0m"
  echo -e "    • Bucles: \e[1mwhile read\e[0m para iterar sobre el CSV"
  echo -e "    • Parsing: \e[1mcut\e[0m o \e[1mawk\e[0m para extraer campos"
  echo -e "    • Usuarios: \e[1museradd\e[0m para crear cuentas"
  echo -e "    • Contraseñas: \e[1m/dev/urandom\e[0m para generar aleatoriedad"
  echo -e "    • Logging: \e[1mdate\e[0m para marcas de tiempo"
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN (Nivel L2 - Dificultad 4/10)\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m Leer el CSV línea por línea con \e[1mwhile read\e[0m                 \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Extraer campos con \e[1mcut\e[0m o \e[1mawk\e[0m y normalizar a minúsculas  \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Crear usuario con \e[1museradd -m -G <grupo>\e[0m si no existe        \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Generar contraseña aleatoria con \e[1m/dev/urandom\e[0m              \e[0;35m→ 15%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Registrar cada operación en \e[1m$LOG_FILE\e[0m con timestamp         \e[0;35m→ 20%\e[0m"
  echo ""
  echo -e "\e[1;31m  ⚠️  REGLA DE ORO:\e[0m Un bucle mal diseñado puede crear (o romper) 50 cuentas en segundos."
  echo -e "\e[1;33m  💡 TIP:\e[0m Usa \e[1mcontinue\e[0m para saltar usuarios existentes sin abortar el lote."
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""

  # Crear el script objetivo con TODOs usando INNEREOF
  cat << 'INNEREOF' > "$SCRIPT_TARGET"
  #!/bin/bash
  # ==============================================================================
  # Script: crear_usuarios.sh
  # Objetivo: Procesar CSV y crear usuarios Linux con grupos y contraseñas.
  # Autor: [Tu nombre]
  # Fecha: [Fecha actual]
  # ==============================================================================

  # Variables de configuración
  CSV_FILE="$HOME/lab-bash-003/empleados_nuevos.csv"
  LOG_FILE="$HOME/lab-bash-003/creacion_usuarios.log"

  # Asegurar que el log existe
  touch "$LOG_FILE"

  echo "=== INICIO DE PROCESO: $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"

  # ==============================================================================
  # TODO 1: Leer el CSV línea por línea con 'while read'
  # ==============================================================================
  # Pista: Usa 'while IFS= read -r linea' para preservar espacios
  # El bucle debe leer desde el archivo CSV
  # 
  # Estructura sugerida:
  # while IFS= read -r linea || [ -n "$linea" ]; do
  #     # Procesar cada línea aquí
  # done < "$CSV_FILE"

  # ==============================================================================
  # TODO 2: Extraer nombre, apellido y departamento usando 'cut' o 'awk'
  # ==============================================================================
  # Dentro del bucle, extrae los tres campos del CSV
  # Pista: Usa 'cut -d',' -f1' para el primer campo, '-f2' para el segundo, etc.
  # Luego convierte todo a minúsculas con 'tr'
  #
  # Ejemplo:
  # nombre=$(echo "$linea" | cut -d',' -f1 | tr '[:upper:]' '[:lower:]')
  # apellido=$(echo "$linea" | cut -d',' -f2 | tr '[:upper:]' '[:lower:]')
  # depto=$(echo "$linea" | cut -d',' -f3 | tr '[:upper:]' '[:lower:]')

  # ==============================================================================
  # TODO 3: Construir el nombre de usuario: nombre.apellido (minúsculas)
  # ==============================================================================
  # Combina nombre y apellido con un punto en el medio
  # Ejemplo: username="${nombre}.${apellido}"

  # ==============================================================================
  # TODO 4: Verificar si el usuario ya existe
  # ==============================================================================
  # Usa 'id "$username"' para verificar si el usuario existe
  # Si existe, registra un WARNING en el log y continúa con el siguiente
  # Pista: Usa 'continue' para saltar a la siguiente iteración
  #
  # Ejemplo:
  # if id "$username" &>/dev/null; then
  #     echo "[WARNING] Usuario $username ya existe. Saltando..." | tee -a "$LOG_FILE"
  #     continue
  # fi

  # ==============================================================================
  # TODO 5: Crear el usuario con 'useradd -m -G "$depto" "$username"'
  # ==============================================================================
  # Usa 'sudo useradd' con las opciones:
  #   -m: crear directorio home
  #   -G: grupo secundario (el departamento)
  # Captura el código de salida ($?) para decidir si fue exitoso
  #
  # Ejemplo:
  # sudo useradd -m -G "$depto" "$username" 2>/dev/null
  # if [ $? -eq 0 ]; then
  #     # Usuario creado exitosamente
  # else
  #     # Error al crear usuario
  # fi

  # ==============================================================================
  # TODO 6: Generar contraseña aleatoria de 12 caracteres
  # ==============================================================================
  # Usa /dev/urandom para generar caracteres aleatorios
  # Filtra solo letras y números con 'tr -dc'
  # Toma los primeros 12 caracteres con 'head -c 12'
  # Luego asigna la contraseña con 'chpasswd'
  #
  # Ejemplo:
  # password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
  # echo "$username:$password" | sudo chpasswd

  # ==============================================================================
  # TODO 7: Registrar en el log con marca de tiempo
  # ==============================================================================
  # Si la creación fue exitosa, registra:
  #   [timestamp] CREADO: username | Depto: departamento | Pass: contraseña
  # Si falló, registra:
  #   [timestamp] ERROR: Falló la creación de username
  #
  # Ejemplo de timestamp:
  # $(date '+%Y-%m-%d %H:%M:%S')

  # ==============================================================================
  # FIN DEL BUCLE
  # ==============================================================================
  # No olvides cerrar el bucle 'done < "$CSV_FILE"'

  echo "=== FIN DE PROCESO: $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"
  echo "✅ Proceso completado. Revisá el log: $LOG_FILE"
  INNEREOF

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
