#!/bin/bash
# Golden-Base/lab-005.sh
# ===================================================================================
# LAB 05: SERVICIOS DE IDENTIDAD (OPENLDAP)
# Prerequisito: Lab 04 ejecutado y funcionando (SRV-LDAP en 10.0.0.11 con red OK)
# ===================================================================================
print_topology() {
cat <<'EOF'

===================================================================================
TOPOLOGÍA DISTRIBUIDA – LAB DE ARQUITECTURA LINUX
===================================================================================

                          ┌─────────────────────────────────────┐
                          │         INTERNET (8.8.8.8)          │
                          └───────────────┬─────────────────────┘
                                          │
                          ┌───────────────┴─────────────────────┐
                          │            HOST (tu PC)             │
                          │       172.16.255.1/30 (v-wan-gw)    │
                          └───────────────┬─────────────────────┘
                                          │
                                          │ veth pair
                                          │
                      ┌───────────────────┴───────────────────────────┐
                      │           CORE-GW (namespace raíz)            │
                      │       ┌─────────────────────────────┐         │
                      │       │  br0: 10.0.0.1/24           │         │
                      │       │  v-gw-wan: 172.16.255.2/30  │         │
                      │       └─────────────────────────────┘         │
                      └───────────────────┬───────────────────────────┘
                                          |       
           ┌───────────────────┌──────────┘──────────┌──────────────────────┐
           │                   │                     │                      │
  ┌────────┴────────┐ ┌────────┴─────────┐  ┌────────┴────────┐    ┌────────┴────────┐
  │    NS-SRV       │ │      NS-RH       │  │      NS-SYS     │    │     NS-INFRA    │
  │  (Servicios)    │ │   (Recursos H)   │  │      (Admin)    │    │      (Infra)    │
  │                 │ │                  │  │                 │    │                 │
  │  ┌──────────┐   │ │     ┌──────┐     │  │     ┌──────┐    │    │      ┌──────┐   │
  │  │ br-srv   │   │ │     │br-rh │     │  │     │br-sys│    │    │      │br-inf│   │
  │  │(switch L2│   │ │     │(L2)  │     │  │     │(L2)  │    │    │      │(L2)  │   │
  │  └────┬─────┘   │ │     └──┬───┘     │  │     └──┬───┘    │    │      └──┬───┘   │
  └───────┼─────────┘ └────────┼─────────┘  └────────┼────────┘    └─────────┼───────┘
          │                    │                     │                       │
     ┌────┴─────┐         ┌────┴─────┐          ┌────┴─────┐            ┌────┴─────┐
     │SRV-LDAP  │         │PC_1-RH   │          │ PC_1-SYS │            │SRV-DNS   │
     │10.0.0.11 │         │10.0.0.21 │          │10.0.0.31 │            │10.0.0.2  │
     │[LDAP ✓]  │         │10.0.0.21 │          └──────────┘            ├──────────┤
     ├──────────┤         ├──────────┤                                  │SRV-DHCP  │
     │SRV-FS    │         │PC_2-RH   │                                  │10.0.0.3  │
     │10.0.0.12 │         │10.0.0.22 │                                  └──────────┘
     └──────────┘         ├──────────┤
                          │PC_3-RH   │
                          │10.0.0.23 │
                          └──────────┘

===================================================================================
RESUMEN RÁPIDO
===================================================================================
- CORE-GW: Router/NAT (10.0.0.1) con salida a Internet.
- Cada departamento: Namespace + bridge propio (aislamiento L2 quirúrgico).
- Endpoints: Todos apuntan al Gateway 10.0.0.1.
- Identidad: Resolución local vía /etc/hosts en cada namespace.
- SRV-LDAP: Servidor de directorio OpenLDAP activo en 10.0.0.11:389.

===================================================================================
ESTADO ACTUAL: LAB 05 COMPLETADO
===================================================================================
✓ SRV-LDAP: OpenLDAP instalado y configurado con dominio dc=lab,dc=local.
✓ Directorio: OU People y OU Groups creadas.
✓ Usuario de prueba: jdoe (uid=10001) desplegado en ou=People.
✓ Listener: slapd escuchando en 10.0.0.11:389 (binding explícito por namespace).
✓ Consulta local: ldapsearch desde SRV-LDAP vía socket ldapi:/// → OK.
✓ Consulta remota: ldapsearch desde PC_1-SYS vía ldap://10.0.0.11 → OK.
✓ Autenticación: ldapwhoami de jdoe desde PC_1-SYS → OK.

===================================================================================
SIGUIENTE PASO — LAB 06: SERVIDOR DE ARCHIVOS (NFS/SAMBA)
===================================================================================

Objetivo:
→ Desplegar SRV-FS (10.0.0.12) en el namespace NS-SRV.
→ Configurar un servidor de archivos compartidos accesible desde los departamentos.
→ Integrar permisos de acceso con los usuarios del directorio LDAP.

Componentes a configurar:

1) Despliegue de SRV-FS:
    • Crear namespace SRV-FS y conectarlo al bridge br-srv.
    • Configurar IP 10.0.0.12 y rutas.

2) Servicio de Archivos:
    • Instalar y configurar NFS o Samba según el caso de uso.
    • Crear shares accesibles desde NS-RH y NS-SYS.

3) Integración con LDAP:
    • Mapear usuarios LDAP a permisos de archivos.
    • Verificar acceso de jdoe desde PC_1-SYS.

4) Verificaciones de "Vida":
    • Desde PC_1-RH: montar share y leer/escribir archivo.
    • Desde PC_1-SYS: verificar permisos según usuario LDAP.

EOF
}

# --- FUNCIÓN DE EJECUCIÓN (Toda la lógica de identidad: OpenLDAP) ---

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "==[ EJECUTANDO LÓGICA: SERVICIOS DE IDENTIDAD (OPENLDAP) ]=="

    # --- PASO 17: RESOLUCIÓN DNS EN SRV-LDAP ---
    echo "==[ 17. CONFIGURACIÓN DNS EN SRV-LDAP ]=="
    # systemd-resolved no funciona dentro de namespaces — apuntamos a DNS público directamente
    mkdir -p /etc/netns/SRV-LDAP
    echo "nameserver 8.8.8.8" > /etc/netns/SRV-LDAP/resolv.conf

    # --- PASO 18: INSTALACIÓN DEL STACK OPENLDAP ---
    echo "==[ 18. INSTALACIÓN SLAPD + LDAP-UTILS ]=="
    ip netns exec SRV-LDAP apt install -y slapd ldap-utils

    # --- PASO 19: CONFIGURACIÓN DEL DOMINIO lab.local ---
    echo "==[ 19. RECONFIGURACIÓN DOMINIO dc=lab,dc=local ]=="
    # dpkg-reconfigure en modo no interactivo con debconf-set-selections
    ip netns exec SRV-LDAP bash -c "
        echo 'slapd slapd/internal/adminpw password ldap' | debconf-set-selections
        echo 'slapd slapd/internal/generated_adminpw password ldap' | debconf-set-selections
        echo 'slapd slapd/password1 password ldap' | debconf-set-selections
        echo 'slapd slapd/password2 password ldap' | debconf-set-selections
        echo 'slapd slapd/domain string lab.local' | debconf-set-selections
        echo 'slapd shared/organization string lab' | debconf-set-selections
        echo 'slapd slapd/backend string MDB' | debconf-set-selections
        echo 'slapd slapd/purge_database boolean false' | debconf-set-selections
        echo 'slapd slapd/move_old_database boolean true' | debconf-set-selections
        DEBIAN_FRONTEND=noninteractive dpkg-reconfigure slapd
    "

    # --- PASO 20: CREACIÓN DE UNIDADES ORGANIZATIVAS ---
    echo "==[ 20. CREACIÓN OUs: People y Groups ]=="
    cat > /etc/netns/SRV-LDAP/structure.ldif << 'EOF'
dn: ou=People,dc=lab,dc=local
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=lab,dc=local
objectClass: organizationalUnit
ou: Groups
EOF
    ip netns exec SRV-LDAP ldapadd -x -H ldapi:/// -D "cn=admin,dc=lab,dc=local" -w ldap -f /etc/netns/SRV-LDAP/structure.ldif

    # --- PASO 21: USUARIO DE PRUEBA jdoe ---
    echo "==[ 21. CREACIÓN USUARIO jdoe EN ou=People ]=="
    cat > /etc/netns/SRV-LDAP/user.ldif << 'EOF'
dn: uid=jdoe,ou=People,dc=lab,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: jdoe
sn: Doe
givenName: John
cn: John Doe
displayName: John Doe
uidNumber: 10001
gidNumber: 10001
userPassword: password123
loginShell: /bin/bash
homeDirectory: /home/jdoe
EOF
    ip netns exec SRV-LDAP ldapadd -x -H ldapi:/// -D "cn=admin,dc=lab,dc=local" -w ldap -f /etc/netns/SRV-LDAP/user.ldif

    # --- PASO 22: EXPONER SLAPD EN IP 10.0.0.11 ---
    echo "==[ 22. BINDING SLAPD EN 10.0.0.11:389 ]=="
    # ldap:/// no hace bind correctamente en network namespaces — hay que especificar la IP
    ip netns exec SRV-LDAP service slapd stop
    ip netns exec SRV-LDAP slapd -h "ldap://10.0.0.11:389/ ldapi:///" -u openldap -g openldap -F /etc/ldap/slapd.d

    # --- PASO 23: VERIFICACIONES FINALES ---
    echo "==[ 23. VERIFICACIONES DE VIDA ]=="

    echo -n "→ slapd escuchando en 10.0.0.11:389: "
    if ip netns exec SRV-LDAP ss -tlnp | grep -q 389; then echo "OK"; else echo "FAIL"; fi

    echo -n "→ ldapsearch local (dc=lab,dc=local): "
    if ip netns exec SRV-LDAP ldapsearch -x -H ldapi:/// -b "dc=lab,dc=local" >/dev/null 2>&1; then echo "OK"; else echo "FAIL"; fi

    echo -n "→ ldapsearch remoto desde PC_1-SYS: "
    if ip netns exec PC_1-SYS ldapsearch -x -H ldap://10.0.0.11 -b "dc=lab,dc=local" >/dev/null 2>&1; then echo "OK"; else echo "FAIL"; fi

    echo -n "→ Autenticación jdoe desde PC_1-SYS: "
    if ip netns exec PC_1-SYS ldapwhoami -x -H ldap://10.0.0.11 -D "uid=jdoe,ou=People,dc=lab,dc=local" -w password123 >/dev/null 2>&1; then echo "OK"; else echo "FAIL"; fi

    echo "✔ completado"

    print_topology
    read -p "  Presiona Enter para continuar..."
fi