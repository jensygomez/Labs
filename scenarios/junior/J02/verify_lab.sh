#!/bin/bash
echo "=========================================="
echo "VERIFICACIÓN CORREGIDA - J02 CON USUARIO STUDENT"
echo "=========================================="

# 1. Verificar que J02.yml usa hosts correctos
echo "1. Hosts en J02.yml:"
if grep -q "hosts: admin01" J02.yml && \
   grep -q "hosts: web01" J02.yml && \
   grep -q "hosts: client01" J02.yml; then
    echo "   ✅ Usa admin01, web01, client01"
else
    echo "   ❌ Hosts incorrectos"
    grep "hosts:" J02.yml
fi

# 2. Verificar creación de usuario
echo -e "\n2. Creación de usuario corporativo:"
if grep -q "sysadmin-junior" J02.yml; then
    echo "   ✅ Incluye creación de sysadmin-junior"
else
    echo "   ❌ No crea usuario sysadmin-junior"
fi

# 3. Verificar remote_user
echo -e "\n3. Uso de remote_user:"
if grep -q "remote_user: sysadmin-junior" J02.yml; then
    echo "   ✅ Usa remote_user: sysadmin-junior después de crearlo"
else
    echo "   ⚠️  No especifica remote_user explícitamente"
fi

# 4. Verificar sintaxis
echo -e "\n4. Sintaxis Ansible:"
if ansible-playbook -i ../../engine/inventory.yml J02.yml --syntax-check 2>/dev/null; then
    echo "   ✅ Sintaxis OK"
else
    echo "   ❌ Error de sintaxis"
fi

# 5. Verificar inventory original
echo -e "\n5. Inventory.yml original:"
cd ~/Labs/engine
if grep -q "ansible_user: student" inventory.yml; then
    echo "   ✅ inventory.yml mantiene ansible_user: student"
else
    echo "   ❌ inventory.yml modificado (debe ser student)"
fi

echo -e "\n=========================================="
echo "RESUMEN: J02 debe:"
echo "1. Conectarse como 'student' (vía inventory.yml)"
echo "2. Crear usuario 'sysadmin-junior' en todas las VMs"
echo "3. Ejecutar el resto del lab como 'sysadmin-junior'"
echo "4. Usar hosts: admin01, web01, client01"
echo "=========================================="