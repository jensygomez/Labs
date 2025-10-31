#!/bin/bash
# ==========================================================
# Script: ver_estructura.sh
# Descripción: Muestra la estructura completa del proyecto
# de laboratorios IT (Python + Docker).
# Autor: Jensy + ChatGPT
# Fecha: $(date +%Y-%m-%d)
# ==========================================================

# Detectar si el usuario está dentro o fuera del proyecto
if [ -d "app" ] && [ -d "labs" ]; then
    BASE_DIR="."
elif [ -d "lab_platform" ]; then
    BASE_DIR="lab_platform"
else
    echo "⚠️  No se encontró la carpeta del proyecto 'lab_platform'."
    echo "Ejecuta este script desde la raíz o un nivel arriba del proyecto."
    exit 1
fi

echo "📂 Leyendo estructura del proyecto en: $(realpath $BASE_DIR)"
echo "=========================================================="

# Verifica si el comando 'tree' está disponible
if command -v tree &>/dev/null; then
    echo "🔍 Mostrando con 'tree'..."
    tree -L 5 -I "__pycache__|.git|.venv" "$BASE_DIR"
else
    echo "🔍 'tree' no está instalado. Usando 'find'..."
    find "$BASE_DIR" -maxdepth 5 -not -path "*/__pycache__/*" -not -path "*/.git/*" -not -path "*/.venv/*" | sort
fi

echo
echo "📘 Archivos clave del proyecto:"
echo "----------------------------------------------------------"
for f in main.py requirements.txt Dockerfile docker-compose.yml README.md; do
    find "$BASE_DIR" -type f -name "$f" 2>/dev/null | while read path; do
        echo "✅ $path"
    done
done

echo
echo "📦 Verificación de carpetas principales:"
for dir in app data labs tickets images logs; do
    if [ -d "$BASE_DIR/$dir" ]; then
        echo "🟢 $dir/"
    else
        echo "🔴 Falta: $dir/"
    fi
done

echo
echo "✅ Revisión completada."
