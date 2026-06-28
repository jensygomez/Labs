---
Curso: Prep Course - LFCS Certification
Modulo: Kubernetes Fundamentos
Playground: K8S-004
Titulo: La App que No Lee su Configuración --> ConfigMap no montado por nombre incorrecto
Fecha de Inicio: 2026-06-28
Dificultad: 4/10
Level Escalation: L1
Objetivo: |-
  Aprobar LFCS y RHCSA (Troubleshooting de aplicaciones que arrancan pero no cargan su configuración).
  Pensar como Sysadmin Linux Pleno (Diagnóstico basado en referencias a ConfigMaps).
  Prepararme para DevOps Engineer (Entender cómo los pods consumen ConfigMaps
  mediante envFrom y volumeMounts, y por qué un nombre incorrecto deja a la app
  "viva pero desconfigurada").
Temas: |-
  Relación Deployment ↔ ConfigMap: envFrom.configMapRef vs volumes.configMap + volumeMounts
  Diagnóstico
  - kubectl describe pod (secciones Environment y Mounts), kubectl get configmap
  Diferencia entre inyectar variables de entorno y montar archivos de configuración
  Corrección
  - kubectl edit deployment / kubectl patch
Competencias: |-
  Identificar que el pod está Running pero la app no carga su configuración.
  Usar 'kubectl describe pod' para detectar variables de entorno faltantes o mounts vacíos.
  Comparar nombres referenciados vs ConfigMaps reales del namespace.
  Corregir la referencia incorrecta con 'kubectl edit deployment'.
  Verificar la corrección tras el rollout con 'kubectl exec env' y 'kubectl exec ls'.
Script Kubernetes: |-
  cat << 'OUTEREOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  echo -e "\e[1;33m⏳ Verificando acceso al cluster Kubernetes...\e[0m"

  # Verificar que kubectl está disponible y el cluster responde
  if ! command -v kubectl &>/dev/null; then
      echo -e "\e[1;31m❌ Error: kubectl no está instalado en este nodo.\e[0m"
      exit 1
  fi

  # Verificar conectividad con el cluster
  if ! kubectl cluster-info &>/dev/null; then
      echo -e "\e[1;31m❌ Error: No se puede conectar al cluster Kubernetes.\e[0m"
      exit 1
  fi
  echo -e "\e[1;32m✓ Cluster Kubernetes accesible\e[0m"

  # Verificar nodos disponibles
  echo -e "\e[1;33m⏳ Verificando nodos del cluster...\e[0m"
  NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  if [ "$NODE_COUNT" -lt 3 ]; then
      echo -e "\e[1;31m❌ Error: Se esperan al menos 3 nodos (1 control-plane + 2 workers), pero se encontraron $NODE_COUNT.\e[0m"
      exit 1
  fi
  echo -e "\e[1;32m✓ Cluster con $NODE_COUNT nodos verificados\e[0m"

  # Limpiar escenario previo si existe
  echo -e "\e[1;33m⏳ Limpiando escenario previo (si existe)...\e[0m"
  kubectl delete namespace dev-ns --ignore-not-found=true --now=true 2>/dev/null || true
  sleep 3

  echo -e "\e[1;33m⏳ Preparando escenario K8S-004 - La App que No Lee su Configuración...\e[0m"

  # Crear namespace 'dev-ns'
  kubectl create namespace dev-ns 2>/dev/null || {
      echo -e "\e[1;33m  [!] El namespace dev-ns ya existe, continuando...\e[0m"
  }

  # ============================================================================
  # INYECCIÓN DEL BUG: Deployment con configMapRef typo (api-configs en vez de api-config)
  # ============================================================================

  # 1) Crear ConfigMap CORRECTO con variables de entorno y archivo de configuración
  kubectl apply -f - <<YAML
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: api-config
    namespace: dev-ns
  data:
    DB_HOST: "postgres.dev-ns.svc.cluster.local"
    DB_PORT: "5432"
    LOG_LEVEL: "DEBUG"
    CACHE_TTL: "3600"
    APP_ENV: "development"
    settings.yaml: |
      server:
        port: 8080
        host: 0.0.0.0
      database:
        pool_size: 10
        timeout: 30s
      logging:
        format: json
        level: debug
  YAML

  # 2) Crear Deployment con BUG: configMapRef tiene typo (api-configs en lugar de api-config)
  #    El volumeMount funciona correctamente, pero envFrom falla silenciosamente
  #    porque optional: true permite que el pod arranque sin el ConfigMap
  kubectl apply -f - <<YAML
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: api-service
    namespace: dev-ns
    labels:
      app: api-service
      tier: backend
      environment: development
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: api-service
    template:
      metadata:
        labels:
          app: api-service
          tier: backend
      spec:
        nodeName: node01
        containers:
        - name: api-service
          image: busybox:1.36
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "=== API Service Starting ==="
              echo "Environment variables:"
              env | grep -E "(DB_|LOG_|CACHE_|APP_)" || echo "NO CONFIG VARIABLES FOUND"
              echo ""
              echo "Config files:"
              ls -la /etc/app/config/ 2>/dev/null || echo "Config directory empty or missing"
              echo ""
              echo "App running with default hardcoded values..."
              sleep infinity
          envFrom:
          - configMapRef:
              name: api-configs
              optional: true
          volumeMounts:
          - name: config-volume
            mountPath: /etc/app/config
            readOnly: true
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "250m"
        volumes:
        - name: config-volume
          configMap:
            name: api-config
  YAML

  echo -e "\e[1;33m⏳ Esperando a que los 2 pods del Deployment estén Running...\e[0m"

  # Esperar hasta 120 segundos a que los pods estén Running
  for i in {1..24}; do
      READY_COUNT=$(kubectl get pods -n dev-ns -l app=api-service --no-headers 2>/dev/null | grep -c "Running" || echo "0")
      if [ "$READY_COUNT" -eq 2 ]; then
          echo -e "\e[1;32m✓ 2 pods de api-service en estado Running en namespace dev-ns\e[0m"
          break
      fi
      if [ $i -eq 24 ]; then
          echo -e "\e[1;33m  [!] Advertencia: Solo $READY_COUNT/2 pods Running después de 120s.\e[0m"
          echo -e "\e[1;33m  [!] El estudiante deberá investigar el estado de los pods.\e[0m"
      else
          echo -ne ".  "
          sleep 5
      fi
  done

  # Verificar que el pod está Running pero sin variables de entorno (confirmar que el bug fue inyectado)
  echo -e "\e[1;33m⏳ Verificando que el pod está Running pero sin configuración (bug inyectado)...\e[0m"
  sleep 3

  POD_NAME=$(kubectl get pods -n dev-ns -l app=api-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -z "$POD_NAME" ]; then
      echo -e "\e[1;31m❌ Error: No se pudo obtener el nombre del pod.\e[0m"
      exit 1
  fi

  # Verificar que NO hay variables de entorno del ConfigMap
  ENV_CHECK=$(kubectl exec -n dev-ns $POD_NAME -- sh -c 'env | grep -E "(DB_HOST|LOG_LEVEL|CACHE_TTL)" | wc -l' 2>/dev/null || echo "0")
  if [ "$ENV_CHECK" -eq 0 ]; then
      echo -e "\e[1;32m✓ Confirmado: El pod está Running pero NO tiene variables de entorno del ConfigMap (bug activo)\e[0m"
  else
      echo -e "\e[1;31m❌ Error: El pod tiene variables de entorno. El bug no se inyectó correctamente.\e[0m"
      kubectl exec -n dev-ns $POD_NAME -- env | grep -E "(DB_|LOG_|CACHE_)"
      exit 1
  fi

  # Verificar que el archivo settings.yaml SÍ está montado (volumeMount funciona)
  FILE_CHECK=$(kubectl exec -n dev-ns $POD_NAME -- ls /etc/app/config/settings.yaml 2>/dev/null | wc -l)
  if [ "$FILE_CHECK" -gt 0 ]; then
      echo -e "\e[1;32m✓ Confirmado: El archivo settings.yaml SÍ está montado (volumeMount funciona)\e[0m"
  else
      echo -e "\e[1;31m❌ Error: El archivo settings.yaml no está montado. Hay un problema con el volumeMount.\e[0m"
      exit 1
  fi

  # Verificar que los objetos existen
  CM_EXISTS=$(kubectl get configmap api-config -n dev-ns --no-headers 2>/dev/null | wc -l)
  DEP_EXISTS=$(kubectl get deployment api-service -n dev-ns --no-headers 2>/dev/null | wc -l)
  if [ "$CM_EXISTS" -eq 0 ] || [ "$DEP_EXISTS" -eq 0 ]; then
      echo -e "\e[1;31m❌ Error: No se pudieron crear los objetos en dev-ns.\e[0m"
      exit 1
  fi
  echo -e "\e[1;32m✓ Objetos creados: ConfigMap api-config + Deployment api-service\e[0m"

  # Información interna del setup (no mostrar al estudiante en el briefing)
  echo -e "\e[1;36m--- Información interna del setup (NO MOSTRAR AL ESTUDIANTE) ---\e[0m"
  kubectl get pods -n dev-ns -o wide
  kubectl get configmap api-config -n dev-ns
  kubectl describe deployment api-service -n dev-ns | grep -A 5 "Environment:"
  kubectl exec -n dev-ns $POD_NAME -- ls -la /etc/app/config/
  echo -e "\e[1;36m---------------------------------------------------------------\e[0m"

  clear

  # ===========================================================================
  # BRIEFING AL ESTUDIANTE
  # ===========================================================================
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m K8S-004-v1 | La App que No Lee su Configuración | Dificultad: 4/10 | L1\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e ""
  echo -e " \e[1mContexto:\e[0m Te encuentras en el nodo \e[1mcontrolplane\e[0m de un cluster Kubernetes"
  echo -e " con 3 nodos (1 control-plane + 2 workers: node01, node02)."
  echo -e ""
  echo -e " \e[1mSituación:\e[0m El equipo de backend desplegó la aplicación \e[1mapi-service\e[0m en el"
  echo -e " namespace \e[1mdev-ns\e[0m sobre el nodo worker \e[1mnode01\e[0m. El ConfigMap \e[1mapi-config\e[0m fue"
  echo -e " creado correctamente con variables de entorno (DB_HOST, LOG_LEVEL, CACHE_TTL) y el"
  echo -e " archivo \e[1msettings.yaml\e[0m. El Deployment lo referencia de dos formas:"
  echo -e ""
  echo -e "   • \e[1menvFrom.configMapRef\e[0m para inyectar variables de entorno"
  echo -e "   • \e[1mvolumes.configMap + volumeMounts\e[0m para montar el archivo en \e[7m/etc/app/config/\e[0m"
  echo -e ""
  echo -e " La app arranca y el pod queda \e[1mRunning\e[0m, pero se comporta como si no tuviera"
  echo -e " configuración: usa valores por defecto hardcoded y el log level está en INFO en lugar"
  echo -e " de DEBUG. Al inspeccionar con \e[7mkubectl describe pod\e[0m, el alumno descubre que el"
  echo -e " \e[1mvolumeMount SÍ funciona\e[0m (el archivo está montado) pero las \e[1mvariables de entorno"
  echo -e " NO se inyectaron\e[0m."
  echo -e ""
  echo -e " \e[1mProblema:\e[0m Hay un \e[1;31mtypo sutil\e[0m en \e[1mconfigMapRef.name\e[0m (\e[7mapi-configs\e[0m con una"
  echo -e " 's' extra) respecto al ConfigMap real \e[7mapi-config\e[0m. Como la referencia tiene"
  echo -e " \e[1moptional: true\e[0m, Kubernetes no marca el pod como fallido y el problema pasa"
  echo -e " desapercibido."
  echo -e ""
  echo -e "\e[1;33m TU MISIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Confirmar el problema\e[0m"
  echo -e "    Ejecuta \e[7mkubectl get pods -n dev-ns\e[0m y verifica que los pods están Running."
  echo -e "    Luego entra a uno de ellos con \e[7mkubectl exec -it <pod> -- sh\e[0m y ejecuta \e[7menv\e[0m"
  echo -e "    para ver que \e[1mNO hay variables de entorno\e[0m del ConfigMap (DB_HOST, LOG_LEVEL, etc.)."
  echo -e ""
  echo -e " \e[1m2. Investigar el pod en detalle\e[0m"
  echo -e "    Usa \e[7mkubectl describe pod <pod-name> -n dev-ns\e[0m y revisa las secciones:"
  echo -e "    • \e[1mEnvironment\e[0m: ¿Debería tener variables desde configMapRef?"
  echo -e "    • \e[1mMounts\e[0m: ¿El volumeMount apunta al ConfigMap correcto?"
  echo -e ""
  echo -e " \e[1m3. Verificar que el volumeMount funciona\e[0m"
  echo -e "    Ejecuta \e[7mkubectl exec <pod-name> -n dev-ns -- ls -la /etc/app/config/\e[0m"
  echo -e "    Confirma que el archivo \e[1msettings.yaml\e[0m SÍ está montado."
  echo -e ""
  echo -e " \e[1m4. Investigar los ConfigMaps del namespace\e[0m"
  echo -e "    Ejecuta \e[7mkubectl get configmap -n dev-ns\e[0m y compara los nombres reales"
  echo -e "    con los referenciados en el Deployment."
  echo -e ""
  echo -e " \e[1m5. Identificar el mismatch exacto\e[0m"
  echo -e "    Usa \e[7mkubectl describe deployment api-service -n dev-ns\e[0m y busca la sección"
  echo -e "    \e[1mEnvironment\e[0m. Compara el nombre en \e[1mconfigMapRef.name\e[0m con el ConfigMap real."
  echo -e "    ¿Encuentras el typo?"
  echo -e ""
  echo -e " \e[1m6. Corregir la referencia del ConfigMap\e[0m"
  echo -e "    Usa \e[7mkubectl edit deployment api-service -n dev-ns\e[0m para modificar"
  echo -e "    \e[1mconfigMapRef.name\e[0m de \e[7mapi-configs\e[0m a \e[7mapi-config\e[0m."
  echo -e "    \e[1mNO toques el ConfigMap ni el volumeMount\e[0m, solo la referencia en envFrom."
  echo -e ""
  echo -e " \e[1m7. Verificar la corrección\e[0m"
  echo -e "    Espera a que el Deployment haga rollout (\e[7mkubectl rollout status deployment/api-service -n dev-ns\e[0m)."
  echo -e "    Luego ejecuta \e[7mkubectl exec <new-pod> -n dev-ns -- env\e[0m y confirma que ahora"
  echo -e "    aparecen las variables DB_HOST, LOG_LEVEL, CACHE_TTL, etc."
  echo -e ""
  echo -e " \e[1m8. Documentar el procedimiento\e[0m"
  echo -e "    Escribe el comando exacto de corrección aplicado y explica qué nombre estaba mal"
  echo -e "    y por qué el pod no falló a pesar de la referencia incorrecta."
  echo -e ""
  echo -e "\e[1;33m COMANDOS ÚTILES DE REFERENCIA\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  \e[7mkubectl get pods -n dev-ns\e[0m                                       # Ver pods"
  echo -e "  \e[7mkubectl describe pod <pod> -n dev-ns\e[0m                            # Ver detalles del pod"
  echo -e "  \e[7mkubectl exec <pod> -n dev-ns -- env\e[0m                             # Ver variables de entorno"
  echo -e "  \e[7mkubectl exec <pod> -n dev-ns -- ls -la /etc/app/config/\e[0m         # Ver archivos montados"
  echo -e "  \e[7mkubectl get configmap -n dev-ns\e[0m                                 # Ver ConfigMaps"
  echo -e "  \e[7mkubectl describe deployment api-service -n dev-ns\e[0m               # Ver referencias"
  echo -e "  \e[7mkubectl edit deployment api-service -n dev-ns\e[0m                   # Editar Deployment"
  echo -e "  \e[7mkubectl rollout status deployment/api-service -n dev-ns\e[0m         # Ver progreso del rollout"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Confirmar que el pod está Running pero sin variables de entorno            15%"
  echo -e "  [ ] Usar 'kubectl describe pod' y revisar secciones Environment y Mounts       15%"
  echo -e "  [ ] Verificar que el volumeMount funciona (settings.yaml está montado)         10%"
  echo -e "  [ ] Listar ConfigMaps del namespace y comparar con referencias                 15%"
  echo -e "  [ ] Identificar el typo en configMapRef.name (api-configs vs api-config)       20%"
  echo -e "  [ ] Corregir la referencia en el Deployment (sin tocar ConfigMap ni volume)    15%"
  echo -e "  [ ] Verificar que tras el rollout las variables aparecen en 'env'               5%"
  echo -e "  [ ] Documentar el comando exacto de corrección aplicado                         5%"
  echo -e ""
  echo -e "\e[1;33m PISTA PARA NO QUEDARSE ATASCADO\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  Si no encuentras el typo a simple vista, usa este truco para comparar"
  echo -e "  lado a lado la referencia del Deployment con el ConfigMap real:"
  echo -e "  \e[7mecho \"Referencia en Deployment:\"; kubectl get deployment api-service -n dev-ns -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'; echo\e[0m"
  echo -e "  \e[7mecho \"ConfigMaps reales:\"; kubectl get configmap -n dev-ns -o jsonpath='{range .items[*]}{.metadata.name}{\"\\n\"}{end}'\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e ""
  echo -e " \e[1;32m¡Comienza tu investigación!\e[0m La app está viva pero desconfigurada..."
  echo -e ""
  OUTEREOF

  bash /tmp/setup.sh
  rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - Kubernetes
  - ConfigMaps
  - volumeMounts
  - configMapRef
  - Troubleshooting
  - Fundamentos
Escenario: |-
  Situación
   -El equipo de backend desplegó la aplicación 'api-service' en el namespace 'dev-ns'
  sobre el nodo worker 'node01'. El ConfigMap 'api-config' fue creado correctamente con variables
  de entorno (DB_HOST, LOG_LEVEL) y el archivo 'settings.yaml'. El Deployment lo referencia de
  dos formas: mediante 'envFrom.configMapRef' para inyectar variables, y mediante
  'volumes.configMap' + 'volumeMounts' para montar el archivo en '/etc/app/config/'. 
  - La app arranca y el pod queda Running, pero se comporta como si no tuviera configuración
   - usa valores por defecto hardcoded y el log level está en INFO en lugar de DEBUG. 
  - Al inspeccionar con 'kubectl describe pod', el alumno descubre que el volumeMount SÍ funciona (el archivo está
  montado) pero las variables de entorno NO se inyectaron. La causa: hay un typo sutil en
  'configMapRef.name' ('api-configs' con una 's' extra) respecto al ConfigMap real 'api-config'.
  Tu misión
   - diagnosticar por qué la app no lee su configuración, identificar el nombre incorrecto
  en la referencia, corregirlo en el Deployment sin tocar el ConfigMap, y verificar que tras el
  rollout las variables de entorno aparecen correctamente dentro del contenedor en node01.
---
[[Laboratorios del LFCS]]
---
