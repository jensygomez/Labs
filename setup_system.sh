#!/bin/bash
# ==========================================================
# Script: crear_estructura_labs.sh
# Descripción: Crea la estructura base para un sistema de
# laboratorios técnicos en Python con Docker y BD.
# Autor: Jensy + ChatGPT
# Fecha: $(date +%Y-%m-%d)
# ==========================================================

BASE_DIR="lab_platform"

echo "🧱 Creando estructura del proyecto en: $BASE_DIR"
mkdir -p $BASE_DIR

# --- app core ---
mkdir -p $BASE_DIR/app/{utils,models,services,config/docker_templates,config/env}

# Archivos base del núcleo
touch $BASE_DIR/app/{__init__.py,main.py,menu.py}
touch $BASE_DIR/app/utils/{db_utils.py,docker_utils.py,email_utils.py,security_utils.py,logger.py}
touch $BASE_DIR/app/models/{user.py,lab.py,specialization.py}
touch $BASE_DIR/app/services/{user_service.py,lab_service.py,ticket_service.py,reporting_service.py}
touch $BASE_DIR/app/config/{settings.py}

# --- data ---
mkdir -p $BASE_DIR/data/{database,users,reports}
touch $BASE_DIR/data/database/lab_platform.db

# --- labs ---
mkdir -p $BASE_DIR/labs/level_{1,2,3}
mkdir -p $BASE_DIR/labs/level_1/{network,linux,security}
mkdir -p $BASE_DIR/labs/level_2/{cloud,kubernetes,network}
mkdir -p $BASE_DIR/labs/level_3/{automation,soc_analyst,red_team}

# Crear ejemplos de laboratorios
for LAB in network linux security; do
  mkdir -p $BASE_DIR/labs/level_1/$LAB/lab1_${LAB}_example/configs
  touch $BASE_DIR/labs/level_1/$LAB/lab1_${LAB}_example/{docker-compose.yml,README.md}
done

# --- tickets ---
mkdir -p $BASE_DIR/tickets/{active_tickets,expired/old_tickets}

# --- images ---
mkdir -p $BASE_DIR/images/{docker_images,screenshots/lab_previews}
touch $BASE_DIR/images/docker_images/{base_ubuntu.tar,network_lab.tar,samba_ad.tar}

# --- logs ---
mkdir -p $BASE_DIR/logs
touch $BASE_DIR/logs/{system.log,user_activity.log}

# --- tests ---
mkdir -p $BASE_DIR/tests
touch $BASE_DIR/tests/{test_db.py,test_docker.py,test_menu.py}

# --- archivos raíz ---
touch $BASE_DIR/{requirements.txt,Dockerfile,docker-compose.yml,README.md}

echo "✅ Estructura creada con éxito."
echo
tree -L 4 $BASE_DIR 2>/dev/null || ls -R $BASE_DIR
