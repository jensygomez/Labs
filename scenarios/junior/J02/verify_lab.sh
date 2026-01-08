#!/bin/bash
echo "========================================"
echo "PRUEBA FINAL DEL LABORATORIO J02"
echo "========================================"

# 1. Verificar que todos los archivos existen
echo "1. Archivos esenciales:"
files=("J02.yml" "vars/main.yml" "tasks/base.yml" "tasks/show_ticket.yml" 
       "templates/service-template.service.j2" "templates/start.sh.j2")
all_ok=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file - FALTANTE"
        all_ok=false
    fi
done

# 2. Verificar sintaxis
echo -e "\n2. Sintaxis:"
if ansible-playbook -i ../../engine/inventory.yml J02.yml --syntax-check 2>/dev/null; then
    echo "   ✅ J02.yml - Sintaxis Ansible OK"
else
    echo "   ❌ J02.yml - Error de sintaxis"
    all_ok=false
fi

# 3. Verificar randomización
echo -e "\n3. Randomización:"
if grep -q "random_elements:" vars/main.yml; then
    echo "   ✅ vars/main.yml tiene random_elements"
else
    echo "   ❌ vars/main.yml NO tiene random_elements"
    all_ok=false
fi

# 4. Verificar variantes
echo -e "\n4. Variantes:"
variants_ok=true
for i in {1..4}; do
    if [ -f "inject/variant_$i.yml" ] && [ -f "tickets/variant_$i.yml" ]; then
        echo "   ✅ Variante $i completa"
    else
        echo "   ❌ Variante $i incompleta"
        variants_ok=false
    fi
done

echo -e "\n========================================"
if $all_ok && $variants_ok; then
    echo "🎉 LABORATORIO J02 LISTO PARA USAR 🎉"
    echo ""
    echo "Para probar completamente:"
    echo "  ansible-playbook -i ../../engine/inventory.yml J02.yml"
else
    echo "⚠️  AÚN HAY PROBLEMAS POR RESOLVER"
fi
echo "========================================"