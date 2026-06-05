---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: PG-001
Titulo: Ciclo de Vida de Identidades Corporativas y Plantillas Dinámicas Avanzadas - V2
Fecha de Inicio: 2026-06-05
Dificultad: 7/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS con máxima puntuación
  - Dominar el ciclo de vida e ingeniería de identidades (PAM / Shadow compliance)
Temas:
  - Advanced User Provisioning & Shell Customization
  - Password Aging Policies (chage internals)
  - Defensive Skeleton Directories (/etc/skel configuration)
Competencias:
  - Diseñar plantillas de entorno seguras con restricciones de máscara de red y permisos internos
  - Implementar políticas coercitivas de cambio de credenciales (First-login password reset)
  - Configurar el envejecimiento criptográfico de cuentas en `/etc/shadow`
Ticket: |-
  INC-6011 (ALTA) - Onboarding de Consultoría Externa y Hardening de Identidades

   El departamento de Seguridad de la Información (SecOps) aprobó el ingreso del contratista senior "ext-ops02". Debido a las normativas de cumplimiento de la empresa, la cuenta no puede ser creada con los valores por defecto del sistema.

   Requerimientos Técnicos Obligatorios del Ticket:
   1. Crear el grupo corporativo "external-devs" asignándole obligatoriamente el GID estático 3500.
   2. Modificar el esqueleto del sistema ('/etc/skel') para cumplir con la política de auditoría interna:
      - Crear un directorio oculto llamado '.audit_logs' en la raíz de la plantilla.
      - Este directorio debe poseer permisos restrictivos '700' (solo el dueño tiene acceso).
      - Dentro de '.audit_logs', crear un archivo vacío llamado 'session_policy.cfg'.
   3. Aprovisionar al usuario "ext-ops02" bajo las siguientes condiciones directas:
      - UID específico: 3501.
      - Grupo primario: "external-devs".
      - Grupo secundario: Debe pertenecer también al grupo "sec-monitors" (GID 3600, el cual será aprovisionado por el script de setup).
   4. Política Coercitiva de Ciclo de Vida:
      - La cuenta completa debe expirar de forma definitiva el 31 de diciembre de 2026 (Epoch estricto).
      - La contraseña debe expirar como máximo cada 30 días.
      - Se debe forzar al usuario a cambiar su contraseña obligatoriamente en su primer inicio de sesión (Immediate expiration).
Validacion:
  - Objetivo: Grupo 'external-devs' operativo con el GID 3500.
    Peso: 15 %
  - Objetivo: Plantilla en /etc/skel/.audit_logs/ estructurada con los permisos de aislamiento (700) y archivo interno.
    Peso: 25 %
  - Objetivo: Usuario 'ext-ops02' creado con UID 3501, grupo primario 3500 y secundario 3600.
    Peso: 30 %
  - Objetivo:Cumplimiento de políticas de expiración: Cuenta expira el 2026-12-31 y contraseña forzada a cambio inmediato.
    Peso: 30 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
    #!/bin/bash
    set -e

    # Limpieza absoluta de rastros de laboratorios anteriores
    userdel -r ext-ops02 2>/dev/null || true
    groupdel external-devs 2>/dev/null || true
    groupdel sec-monitors 2>/dev/null || true
    rm -rf /etc/skel/.audit_logs

    # Configurar requerimientos previos del sistema (Grupo secundario de seguridad)
    groupadd -g 3600 sec-monitors

    clear
    echo -e "\e[1;36m================================================================================\e[0m"
    echo -e "\e[1;31m 🔥 ESCENARIO AVANZADO CONFIGURADO - USERS & GROUPS (PG-001 v2)\e[0m"
    echo -e "\e[1;36m================================================================================\e[0m"
    echo -e "\e[1;33m TICKET DE INCIDENTE: INC-6011\e[0m"
    echo -e " ------------------------------------------------------------------------------"
    echo -e " \e[1mAsunto:\e[0m Onboarding de Consultoría Externa y Hardening de Identidades"
    echo -e " \e[1mSeveridad:\e[0m Alta / Auditoría de Cumplimiento (Compliance)"
    echo -e ""
    echo -e " \e[1mDescripción:\e[0m"
    echo -e " Implemente la estructura de plantillas dinámicas protegidas, aprovisione"
    echo -e " las identidades con IDs fijos e inyecte las directivas de envejecimiento"
    echo -e " de credenciales exigidas por el área de SecOps en /etc/shadow."
    echo -e ""
    echo -e " \e[1mRequerimientos de Validación:\e[0m"
    echo -e "  [ ] Grupo 'external-devs' con GID 3500                          --> \e[1;35m15%\e[0m"
    echo -e "  [ ] Estructura /etc/skel/.audit_logs/ (Permisos 700) lista      --> \e[1;35m25%\e[0m"
    echo -e "  [ ] Usuario con UID 3501, primario 3500 y secundario 3600       --> \e[1;35m30%\e[0m"
    echo -e "  [ ] Expiración de cuenta (2026-12-31) y reset de pass obligatorio--> \e[1;35m30%\e[0m"
    echo -e " ------------------------------------------------------------------------------"
    echo -e "\e[1;36m================================================================================\e[0m"
    echo ""
    EOF
    bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
    PUNTOS=0

    echo "=== EVALUANDO POLÍTICAS DE IDENTIDAD Y SEGURIDAD SHADOW ==="

    USER="ext-ops02"
    G_PRI="external-devs"
    G_SEC="sec-monitors"

    # 1. Validar Grupo Primario
    if getent group "$G_PRI" >/dev/null 2>&1; then
        GID_P=$(getent group "$G_PRI" | cut -d: -f3)
        if [ "$GID_P" -eq 3500 ]; then
            echo "✔ [15%] Grupo primario '$G_PRI' verificado con GID 3500."
            PUNTOS=$((PUNTOS + 15))
        else
            echo "❌ [0%] El GID del grupo es $GID_P (se esperaba 3500)."
        fi
    else
        echo "❌ [0%] El grupo $G_PRI no existe."
    fi

    # 2. Validar Estructura Skel Avanzada
    SKEL_DIR="/etc/skel/.audit_logs"
    if [ -d "$SKEL_DIR" ] && [ -f "$SKEL_DIR/session_policy.cfg" ]; then
        PERM_SKEL=$(stat -c '%a' "$SKEL_DIR")
        if [ "$PERM_SKEL" = "700" ]; then
            echo "✔ [25%] Estructura de plantilla defensiva /etc/skel/ configurada con permisos correctos (700)."
            PUNTOS=$((PUNTOS + 25))
        else
            echo "❌ [10%] La plantilla existe, pero sus permisos son $PERM_SKEL (se exigía 700 para mitigación de accesos)."
            PUNTOS=$((PUNTOS + 10))
        fi
    else
        echo "❌ [0%] No se encuentra la estructura oculta de auditoría en /etc/skel/."
    fi

    # 3. Validar Usuario y sus múltiples membresías
    if id "$USER" >/dev/null 2>&1; then
        UID_U=$(id -u "$USER")
        GID_U=$(id -g "$USER")
        GROUPS_U=$(id -nG "$USER")
        
        if [ "$UID_U" -eq 3501 ] && [ "$GID_U" -eq 3500 ]; then
            if echo "$GROUPS_U" | grep -q "$G_SEC"; then
                # Validar que el Home heredó los permisos restrictivos del skel
                HOME_U=$(eval echo ~"$USER")
                if [ -d "$HOME_U/.audit_logs" ] && [ "$(stat -c '%a' "$HOME_U/.audit_logs")" = "700" ]; then
                    echo "✔ [30%] Usuario '$USER' aprovisionado con IDs correctos, pertenencia multi-grupo y herencia de Home segura."
                    PUNTOS=$((PUNTOS + 30))
                else
                    echo "❌ [15%] Identidades de usuario correctas, pero los permisos del Home divergieron del Skel corporativo."
                    PUNTOS=$((PUNTOS + 15))
                fi
            else
                echo "❌ [10%] El usuario no pertenece al grupo secundario exigido: $G_SEC."
                PUNTOS=$((PUNTOS + 10))
            fi
        else
            echo "❌ [0%] El usuario tiene UID o Grupo Primario desalineado de la orden de trabajo."
        fi
    else
        echo "❌ [0%] El usuario '$USER' no existe en el sistema."
    fi

    # 4. Validar Directivas chage / shadow
    if id "$USER" >/dev/null 2>&1; then
        SHADOW_DATA=$(getent shadow "$USER")
        LAST_CHG=$(echo "$SHADOW_DATA" | cut -d: -f3)
        MAX_DAYS=$(echo "$SHADOW_DATA" | cut -d: -f5)
        EXP_DAYS=$(echo "$SHADOW_DATA" | cut -d: -f8)
        
        # Expiración de cuenta: 2026-12-31 = 20819 días desde epoch
        if [ "$EXP_DAYS" = "20819" ] && [ "$MAX_DAYS" = "30" ] && [ "$LAST_CHG" = "0" ]; then
            echo "✔ [30%] Controles de ciclo de vida en /etc/shadow validados: Cambio inmediato forzado, max 30 días y muerte de cuenta en 2026-12-31."
            PUNTOS=$((PUNTOS + 30))
        else
            echo "❌ [0%] Falló el control de envejecimiento. Valores actuales -> PassLastChanged: $LAST_CHG (esperado: 0), MaxDays: $MAX_DAYS (esperado: 30), AccountExpiry: $EXP_DAYS (esperado: 20819)."
        fi
    fi

    echo "============================"
    echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
    echo "============================"
---

[[Laboratorios del LFCS]]
---

