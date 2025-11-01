#!/bin/bash

BASE_DIR="/home/jensy/Documentos/Github/Labs/LaboratoriosDocker"

# Niveles y cantidad inicial de labs por nivel (puedes modificar)
levels=("Level1" "Level2" "Level3")
labs_por_nivel=3

for level in "${levels[@]}"; do
  for i in $(seq -w 1 $labs_por_nivel); do
    lab_dir="$BASE_DIR/$level/${i}_lab"
    mkdir -p "$lab_dir"
  done
done

echo "Estructura de carpetas creada en $BASE_DIR con $labs_por_nivel labs por nivel."
