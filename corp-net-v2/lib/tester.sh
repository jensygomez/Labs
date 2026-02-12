#!/bin/bash

run_dynamic_tests() {
    local yaml_file="$BASE_DIR/topology/tests.yml"
    
    while true; do
        clear
        echo "=========================================="
        echo "      🧪 MOTOR DE PRUEBAS DINÁMICO        "
        echo "=========================================="
        
        # 1. Extraer nombres de los tests para el menú
        mapfile -t test_names < <(grep "name:" "$yaml_file" | cut -d'"' -f2)
        mapfile -t test_nodes < <(grep "from:" "$yaml_file" | cut -d'"' -f2)
        mapfile -t test_cmds < <(grep "cmd:" "$yaml_file" | cut -d'"' -f2)

        # 2. Imprimir el menú dinámicamente
        for i in "${!test_names[@]}"; do
            echo "$((i+1))) ${test_names[$i]} [Desde: ${test_nodes[$i]}]"
        done
        echo "0) Volver al menú principal"
        echo "------------------------------------------"
        read -p "Selecciona una prueba: " selection

        if [[ "$selection" == "0" ]]; then break; fi

        # 3. Ejecutar la lógica seleccionada
        index=$((selection-1))
        if [[ -n "${test_names[$index]}" ]]; then
            echo "🚀 Ejecutando: ${test_names[$index]}..."
            sudo ip netns exec "${test_nodes[$index]}" bash -c "${test_cmds[$index]}"
            read -p "Presiona Enter para continuar..."
        else
            echo "❌ Selección inválida."
            sleep 1
        fi
    done
}