#!/bin/bash
echo "========================================="
echo "VERIFICACIÓN FINAL DEL LABORATORIO J02"
echo "========================================="

# 1. Estructura de archivos
echo "1. Estructura de archivos:"
count_yml=$(find . -name "*.yml" -type f | wc -l)
count_j2=$(find . -name "*.j2" -type f | wc -l)
echo "   • Archivos YAML: $count_yml"
echo "   • Templates J2: $count_j2"

# 2. Variantes
echo -e "\n2. Variantes:"
for i in {1..4}; do
    if [ -f "inject/variant_$i.yml" ] && [ -f "tickets/variant_$i.yml" ]; then
        lines_inject=$(wc -l < "inject/variant_$i.yml")
        lines_ticket=$(wc -l < "tickets/variant_$i.yml")
        echo "   • Variante $i: inject($lines_inject líneas), ticket($lines_ticket líneas)"
    else
        echo "   • Variante $i: ❌ INCOMPLETA"
    fi
done

# 3. Randomización
echo -e "\n3. Randomización:"
if [ -f "vars/main.yml" ]; then
    services_count=$(grep -A20 "services:" vars/main.yml | grep -c "^- " 2>/dev/null || echo 0)
    users_count=$(grep -A20 "users:" vars/main.yml | grep -c "^- " 2>/dev/null || echo 0)
    echo "   • Servicios: $services_count"
    echo "   • Usuarios: $users_count"
    
    if [ $services_count -ge 5 ] && [ $users_count -ge 5 ]; then
        echo "   ✅ Suficiente diversidad para randomización"
    else
        echo "   ⚠️  Pocos elementos para randomización efectiva"
    fi
fi

# 4. J02.yml
echo -e "\n4. Playbook principal (J02.yml):"
if [ -f "J02.yml" ]; then
    j02_lines=$(wc -l < J02.yml)
    j02_blocks=$(grep -c "name: J02 |" J02.yml)
    echo "   • Líneas: $j02_lines"
    echo "   • Bloques: $j02_blocks/5"
    
    if [ $j02_blocks -eq 5 ]; then
        echo "   ✅ Estructura completa"
    else
        echo "   ❌ Faltan bloques (necesita 5, tiene $j02_blocks)"
    fi
fi

# 5. Inventory
echo -e "\n5. Configuración de Inventory:"
cd ~/Labs/engine 2>/dev/null
if grep -q "admin-j02.example.com" inventory.yml; then
    echo "   ✅ Hosts J02 configurados en inventory.yml"
else
    echo "   ❌ Hosts J02 NO configurados en inventory.yml"
    echo "   Agrega al inventory.yml:"
    echo "     admin-j02.example.com"
    echo "     web-j02.example.com"
    echo "     client-j02.example.com"
fi

echo -e "\n========================================="
echo "RESUMEN: El laboratorio J02 está"
echo "         ESTRUCTURALMENTE COMPLETO"
echo "========================================="


