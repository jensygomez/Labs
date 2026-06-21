---
Curso: Transición Sysadmin a DevOps - Operations Deployment LFCS/RHCSA
Modulo: Operations Deployment (Gestión de Software y Compilación)
Playground: OD-004-v1
Titulo: Dependencias Huérfanas – Repositorios, Paquetes y Compilación desde Fuente
Fecha de Inicio: 2026-06-21
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Gestión de software con el gestor de paquetes (apt, dpkg)
  - Configuración y administración de repositorios
  - Instalación de software mediante compilación desde código fuente
  - Verificación de integridad de binarios y dependencias
Competencias: |-
  - Diagnosticar problemas de repositorios caídos o desactualizados y configurar fuentes alternativas de software.
  - Identificar e instalar las dependencias de compilación necesarias (gcc, make, librerías de desarrollo) para construir software desde fuente.
  - Descargar, compilar e instalar software siguiendo el ciclo estándar (./configure, make, make install) respetando las convenciones del sistema.
  - Verificar la integridad de los binarios instalados utilizando herramientas como ldd, which, hash y file para confirmar que las dependencias dinámicas están correctamente enlazadas.
  - Documentar el proceso de instalación y enviar la evidencia de compilación e integridad a node03 vía pipeline SSH, sin materializar archivos en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_od004.sh
  #!/bin/bash
  set -e

  PASS="caleston123"
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT}"

  echo -e "\e[1;33m⏳ Verificando sshpass en node01...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      echo caleston123 | sudo -S apt-get install -y sshpass -qq
  fi

  echo -e "\e[1;33m⏳ Instalando sshpass en nodos remotos...\e[0m"
  $SSH2 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"
  $SSH3 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Preparando escenario de repositorio caído en node02...\e[0m"
  $SSH2 bash << 'NODE02_INJECT' || echo -e "\e[1;33m  [!] Detalle en node02, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'

      # 1. Deshabilitar repositorios oficiales para simular caída
      mkdir -p /etc/apt/sources.list.d.disabled
      mv /etc/apt/sources.list /etc/apt/sources.list.d.disabled/ 2>/dev/null || true
      mv /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d.disabled/ 2>/dev/null || true
      
      # Crear un repositorio "roto" que apunta a una URL inexistente
      cat > /etc/apt/sources.list.d/broken-repo.list << 'BROKENREPO'
  deb http://archive.ubuntu.com.broken/ubuntu/ focal main restricted
  deb http://archive.ubuntu.com.broken/ubuntu/ focal-updates main restricted
  BROKENREPO

      # 2. Crear directorio para código fuente
      mkdir -p /opt/src
      chmod 755 /opt/src
      chown bob:bob /opt/src

      # 3. Crear un programa C simple que simula la herramienta de monitoreo
      cat > /opt/src/monitor-tool-1.0.tar.gz.base64 << 'SOURCECODE'
  # Este es un placeholder - en producción sería un tar.gz real
  # Por ahora creamos el código fuente directamente
  SOURCECODE

      # Crear el código fuente directamente
      mkdir -p /opt/src/monitor-tool-1.0
      cat > /opt/src/monitor-tool-1.0/monitor.c << 'CSOURCE'
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>

  void print_version() {
      printf("Monitor Tool v1.0 - System Health Checker\n");
      printf("Compiled on: %s %s\n", __DATE__, __TIME__);
  }

  void check_system() {
      printf("\n=== System Health Report ===\n");
      printf("Status: OPERATIONAL\n");
      printf("CPU: Normal\n");
      printf("Memory: Normal\n");
      printf("Disk: Normal\n");
      printf("============================\n");
  }

  int main(int argc, char *argv[]) {
      if (argc > 1 && strcmp(argv[1], "--version") == 0) {
          print_version();
          return 0;
      }
      
      if (argc > 1 && strcmp(argv[1], "--check") == 0) {
          check_system();
          return 0;
      }
      
      printf("Usage: %s [--version|--check]\n", argv[0]);
      printf("  --version  Show version information\n");
      printf("  --check    Run system health check\n");
      return 0;
  }
  CSOURCE

      # Crear Makefile
      cat > /opt/src/monitor-tool-1.0/Makefile << 'MAKEFILE'
  CC = gcc
  CFLAGS = -Wall -O2
  PREFIX = /usr/local
  BINDIR = $(PREFIX)/bin

  all: monitor

  monitor: monitor.c
  	$(CC) $(CFLAGS) -o monitor monitor.c

  install: monitor
  	mkdir -p $(DESTDIR)$(BINDIR)
  	cp monitor $(DESTDIR)$(BINDIR)/
  	chmod 755 $(DESTDIR)$(BINDIR)/monitor

  clean:
  	rm -f monitor

  .PHONY: all install clean
  MAKEFILE

      # Crear configure script simple
      cat > /opt/src/monitor-tool-1.0/configure << 'CONFIGURE'
  #!/bin/bash
  echo "Checking for C compiler..."
  if command -v gcc &> /dev/null; then
      echo "  gcc found: $(gcc --version | head -n1)"
  else
      echo "  ERROR: gcc not found. Please install build-essential."
      exit 1
  fi

  echo "Checking for make..."
  if command -v make &> /dev/null; then
      echo "  make found: $(make --version | head -n1)"
  else
      echo "  ERROR: make not found. Please install build-essential."
      exit 1
  fi

  echo ""
  echo "Configuration complete. Run 'make' to build."
  CONFIGURE
      chmod +x /opt/src/monitor-tool-1.0/configure

      # Crear archivo README
      cat > /opt/src/monitor-tool-1.0/README << 'README'
  Monitor Tool v1.0
  =================

  A simple system health monitoring tool.

  Requirements:
  - gcc (C compiler)
  - make
  - Standard C library

  Installation:
  1. Run ./configure to check dependencies
  2. Run make to compile
  3. Run sudo make install to install

  Usage:
    monitor --version  Show version
    monitor --check    Run health check
  README

      # Establecer permisos correctos
      chown -R bob:bob /opt/src/monitor-tool-1.0
      chmod 755 /opt/src/monitor-tool-1.0

      # 4. Crear un checksum para verificar integridad
      cd /opt/src
      sha256sum monitor-tool-1.0/monitor.c > monitor-tool-1.0.sha256
      chown bob:bob monitor-tool-1.0.sha256

      echo "[OD-004] Escenario de repositorio caído inyectado correctamente."
  SUDO_INNER
  NODE02_INJECT

  echo -e "\e[1;33m⏳ Preparando bóveda de evidencia en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/od-004/
      mkdir -p /opt/ops-compliance/od-004/
      chown -R bob:bob /opt/ops-compliance/od-004/
      chmod 750 /opt/ops-compliance/od-004/
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en preparación de node03, continuando...\e[0m'"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m OD-004-v1 | Dependencias Huérfanas | Dificultad: 6/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/od-004/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El departamento de Operaciones ha reportado que el servidor node02 no puede"
  echo -e " instalar una herramienta crítica de monitoreo requerida para la supervisión"
  echo -e " de la infraestructura de producción. El repositorio oficial de Ubuntu está"
  echo -e " experimentando intermitencia severa y el paquete no está disponible en los"
  echo -e " mirrors configurados."
  echo -e ""
  echo -e " El vendor del software ha confirmado que la herramienta 'Monitor Tool v1.0'"
  echo -e " solo se distribuye como código fuente y debe ser compilada localmente. El"
  echo -e " equipo de desarrollo ha proporcionado el código fuente en /opt/src/ junto"
  echo -e " con la documentación de compilación."
  echo -e ""
  echo -e " Como ingeniero L2 de operaciones, se te asigna la tarea de habilitar la"
  echo -e " compilación del software, instalar todas las dependencias necesarias, y"
  echo -e " garantizar que el binario resultante sea funcional y esté correctamente"
  echo -e " integrado en el sistema."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01 vía SSH hacia node02."
  echo -e " \e[1m>\e[0m No se permite materializar archivos de reporte o scripts temporales en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente de node02 hacia node03 mediante pipeline."
  echo -e " \e[1m>\e[0m El uso del gestor de paquetes (apt/dpkg) es obligatorio para dependencias."
  echo -e ""
  echo -e "\e[1;33m PARÁMETROS TÉCNICOS OBLIGATORIOS (TICKET DE REMEDIACIÓN - NIVEL L2)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Diagnóstico del Estado de Repositorios\e[0m"
  echo -e "    Estado actual: Los repositorios configurados en /etc/apt/sources.list.d/"
  echo -e "    apuntan a URLs inexistentes o están deshabilitados."
  echo -e "    Objetivo: Identificar por qué apt-get update falla y determinar qué"
  echo -e "    repositorios están disponibles o necesitan ser habilitados."
  echo -e "    \e[1;33mRestricción:\e[0m Debes usar apt-cache policy y revisar /etc/apt/sources.list.d/"
  echo -e "    para diagnosticar el problema antes de proceder."
  echo -e ""
  echo -e " \e[1m2. Configuración de Repositorio Alternativo\e[0m"
  echo -e "    Estado actual: No hay repositorios funcionales para instalar dependencias."
  echo -e "    Objetivo: Habilitar o configurar un repositorio válido que contenga las"
  echo -e "    herramientas de compilación (build-essential, gcc, make)."
  echo -e "    \e[1;33mRestricción:\e[0m Puedes usar un PPA, un mirror oficial, o habilitar los"
  echo -e "    repositorios main/universe de Ubuntu si están disponibles localmente."
  echo -e ""
  echo -e " \e[1m3. Instalación de Dependencias de Compilación\e[0m"
  echo -e "    Estado actual: El sistema no tiene gcc, make, ni librerías de desarrollo."
  echo -e "    Objetivo: Instalar todas las dependencias necesarias para compilar código C."
  echo -e "    \e[1;33mRestricción:\e[0m Debes usar apt-get install para instalar build-essential"
  echo -e "    o los paquetes individuales (gcc, make, libc6-dev). Verifica que la"
  echo -e "    instalación fue exitosa antes de proceder."
  echo -e ""
  echo -e " \e[1m4. Compilación e Instalación desde Código Fuente\e[0m"
  echo -e "    Estado actual: El código fuente está en /opt/src/monitor-tool-1.0/"
  echo -e "    Objetivo: Compilar e instalar la herramienta siguiendo el ciclo estándar:"
  echo -e "    ./configure, make, make install."
  echo -e "    \e[1;33mRestricción:\e[0m Debes ejecutar ./configure primero para verificar dependencias,"
  echo -e "    luego make para compilar, y finalmente sudo make install para instalar"
  echo -e "    el binario en /usr/local/bin/. Captura la salida de cada paso."
  echo -e ""
  echo -e " \e[1m5. Verificación de Integridad del Binario\e[0m"
  echo -e "    Estado actual: El binario fue instalado pero no se ha verificado su integridad."
  echo -e "    Objetivo: Confirmar que el binario se instaló correctamente, que todas las"
  echo -e "    dependencias dinámicas están satisfechas, y que es ejecutable."
  echo -e "    \e[1;33mRestricción:\e[0m Debes usar which para localizar el binario, ldd para verificar"
  echo -e "    dependencias dinámicas, file para confirmar el tipo de ejecutable, y ejecutar"
  echo -e "    el binario con --version para validar que funciona."
  echo -e ""
  echo -e "\e[1;33m PIPELINE DE EVIDENCIA A NODE03\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " Destino: \e[1m/opt/ops-compliance/od-004/compilation_audit.txt\e[0m"
  echo -e " Debe contener la salida concatenada de:"
  echo -e "  - apt-cache policy (estado de repositorios)"
  echo -e "  - dpkg -l | grep -E 'gcc|make|build-essential' (dependencias instaladas)"
  echo -e "  - Salida de ./configure, make, y make install"
  echo -e "  - which monitor, ldd /usr/local/bin/monitor, file /usr/local/bin/monitor"
  echo -e "  - monitor --version (verificación de funcionalidad)"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Diagnóstico de repositorios caídos documentado                    15%"
  echo -e "  [ ] Repositorio alternativo configurado y funcional                   15%"
  echo -e "  [ ] Dependencias de compilación instaladas (gcc, make)                15%"
  echo -e "  [ ] Código fuente compilado exitosamente (./configure, make)          20%"
  echo -e "  [ ] Binario instalado en /usr/local/bin/monitor                       15%"
  echo -e "  [ ] Verificación de integridad con ldd y file                         10%"
  echo -e "  [ ] Evidencia (compilation_audit.txt) presente en bóveda node03       10%"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_od004.sh && rm -f /tmp/setup_od004.sh
tags:
  - Laboratorios-del-LFCS
  - Operations-Deployment
  - Package-Management
  - Repository-Configuration
  - Source-Compilation
  - Binary-Verification
Escenario: |-
  - Situación: Desde node01 te conectas a node02 donde el repositorio oficial de paquetes está experimentando intermitencia o no contiene la versión específica de una herramienta crítica de monitoreo requerida por el equipo de operaciones. El proveedor del software solo distribuye el código fuente y documentación de compilación.

  Tu misión:
  1. Diagnosticar el estado de los repositorios configurados en node02 y determinar por qué no es posible instalar el software requerido mediante el gestor de paquetes tradicional.

  2. Configurar un repositorio alternativo válido (PPA, mirror oficial o repositorio local) que contenga las dependencias de compilación necesarias, o habilitar los repositorios de código fuente (deb-src) si están disponibles.

  3. Instalar todas las dependencias de compilación requeridas: compilador C/C++ (gcc, g++), herramientas de construcción (make, autoconf, automake), y librerías de desarrollo específicas que el software necesita para compilarse correctamente.

  4. Descargar el código fuente del software desde la ubicación oficial proporcionada por el vendor, verificar su integridad (checksum si está disponible), y proceder con la compilación siguiendo el ciclo estándar: ./configure (con opciones apropiadas), make, y make install.

  5. Verificar que el binario compilado se instaló correctamente en la ruta esperada, confirmar que todas las dependencias dinámicas están satisfechas (usando ldd), y validar que el ejecutable es funcional.

  6. Generar un reporte completo del proceso de compilación (logs de configure, make, make install) y la verificación de integridad, enviándolo directamente a node03 vía pipeline SSH.

  Regla de Oro: No puedes crear archivos de texto intermedios en node01. Todo el proceso de compilación y verificación debe realizarse en node02, y la evidencia debe fluir directamente a node03 mediante pipelines.
---
[[Laboratorios del LFCS]]
---


One challenge I dealt with recently involved a Linux server where a critical monitoring tool needed to be compiled from source, but the package repositories were completely broken — one of the configured sources pointed to a domain that simply didn't exist, so every update attempt failed with a DNS resolution error.

The first thing I did was inspect the repository configuration files instead of guessing, and I confirmed the issue using `apt-cache policy`, which showed there were zero valid package sources available. Once I identified the broken URL, I reconfigured the repository to point to the official Ubuntu mirror, matching the correct distribution codename, and verified it was working before moving forward.

After that, I installed the build toolchain — gcc, make, and the build-essential meta-package — and ran the standard compilation cycle: configure, make, and make install. During compilation, I actually hit a second issue: the Makefile failed with a 'missing separator' error, which I recognized as a classic Makefile formatting problem — the recipe lines were missing tab characters, which make strictly requires instead of regular spaces. I fixed that directly in the file and the build succeeded right after.

Once the binary was installed, I didn't just assume it worked — I verified it properly: confirmed its location with which, checked all its dynamic library dependencies with ldd to make sure nothing was missing, validated the file type and architecture with file, and finally ran it with --version to confirm it executed correctly.

What I took away from that task is the importance of diagnosing root causes methodically instead of jumping straight to fixes, and of validating every step instead of assuming success — especially in compilation workflows, where a small formatting issue like a missing tab can block the entire build.