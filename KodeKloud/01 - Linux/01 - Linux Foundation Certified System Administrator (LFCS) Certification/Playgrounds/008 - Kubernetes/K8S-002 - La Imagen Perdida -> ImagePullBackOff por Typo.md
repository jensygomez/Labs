---
Curso: Prep Course - LFCS Certification
Modulo: Kubernetes Fundamentos
Playground: K8S-002
Titulo: La Imagen Perdida --> ImagePullBackOff por Typo
Fecha de Inicio: 2026-06-24
Dificultad: 3/10
Level Escalation: L1
Objetivo: |-
  - Aprobar LFCS y RHCSA (Troubleshooting de fallos de pull de imágenes en Kubernetes).
  - Pensar como Sysadmin Linux Pleno (Diagnóstico basado en eventos y estados de pod).
  - Prepararme para DevOps Engineer y Sysadmin Kubernetes (Entender el ciclo de vida
  de descarga de imágenes y cómo interpretar errores de containerd/registry).
Temas: |-
  - Estados de pod ImagePullBackOff, ErrImagePull, ContainerCreating
  - Ciclo de vida de descarga de imágenes (kubelet -> containerd -> registry)
  - Sintaxis de imágenes [registry/]repository[tag|@digest]
  - Comandos de diagnóstico kubectl describe pod, kubectl get events
  - Diferencia entre ErrImagePull (reintentando) e ImagePullBackOff (backoff exponencial)
  - Corrección de deployments kubectl set image vs editar manifiesto
Competencias: |-
  - Identificar el estado ImagePullBackOff en un pod y diferenciarlo de otros estados.
  - Utilizar 'kubectl describe pod' para leer la sección Events y detectar el error real.
  - Interpretar mensajes de error tipo "manifest unknown", "not found" o "tag does not exist".
  - Corregir un deployment con imagen incorrecta usando 'kubectl set image' o re-aplicando manifiesto.
  - Documentar el procedimiento de diagnóstico paso a paso.
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
  kubectl delete deployment api-backend --namespace=dev-ns --ignore-not-found=true --wait=false 2>/dev/null || true
  sleep 2

  echo -e "\e[1;33m⏳ Preparando escenario K8S-002 - La Imagen Perdida...\e[0m"

  # Crear namespace 'dev-ns' (donde se desplegará el deployment con typo)
  kubectl create namespace dev-ns 2>/dev/null || {
    echo -e "\e[1;33m  [!] El namespace dev-ns ya existe, continuando...\e[0m"
  }

  # Crear un deployment con TYPO INTENCIONAL en el nombre de la imagen
  # Imagen correcta sería: nginx:1.25-alpine
  # Imagen inyectada:      nginxx:1.25-alpine  (doble 'x' -> typo sutil)
  kubectl apply -f - <<YAML
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: api-backend
    namespace: dev-ns
    labels:
      app: api-backend
      environment: development
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: api-backend
    template:
      metadata:
        labels:
          app: api-backend
          environment: development
      spec:
        containers:
        - name: api-backend
          image: nginxx:1.25-alpine
          ports:
          - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "250m"
  YAML

  echo -e "\e[1;33m⏳ Esperando a que el pod entre en estado ImagePullBackOff...\e[0m"

  # Esperar hasta 120 segundos para que el pod llegue a ImagePullBackOff
  # El kubelet reintenta con backoff exponencial, por lo que puede tardar unos ciclos
  for i in {1..24}; do
    POD_STATUS=$(kubectl get pods -n dev-ns -l app=api-backend --no-headers -o custom-columns=":status.phase" 2>/dev/null || echo " ")
    CONTAINER_STATE=$(kubectl get pods -n dev-ns -l app=api-backend -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || echo " ")

    if [ "$CONTAINER_STATE" = "ImagePullBackOff" ] || [ "$CONTAINER_STATE" = "ErrImagePull" ]; then
      echo -e "\e[1;32m✓ Pod api-backend en estado $CONTAINER_STATE en namespace dev-ns\e[0m"
      break
    fi

    if [ $i -eq 24 ]; then
      echo -e "\e[1;33m  [!] Advertencia: El pod aún no está en ImagePullBackOff después de 120 segundos.\e[0m"
      echo -e "\e[1;33m  [!] Estado actual: phase=$POD_STATUS, waiting=$CONTAINER_STATE\e[0m"
      echo -e "\e[1;33m  [!] Esto puede deberse a carga del cluster. El estudiante deberá investigar.\e[0m"
    else
      echo -ne ". "
      sleep 5
    fi
  done

  # Verificar que el pod existe en dev-ns
  POD_NAME=$(kubectl get pods -n dev-ns -l app=api-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [ -z "$POD_NAME" ]; then
    echo -e "\e[1;31m❌ Error: No se pudo crear el pod api-backend en el namespace dev-ns.\e[0m"
    kubectl get pods -n dev-ns 2>&1 || true
    exit 1
  fi
  echo -e "\e[1;32m✓ Pod creado: $POD_NAME en namespace dev-ns\e[0m"

  # Mostrar información del pod para verificación interna (no mostrar al estudiante)
  echo -e "\e[1;36m--- Información interna del setup (NO MOSTRAR AL ESTUDIANTE) ---\e[0m"
  kubectl get pods -n dev-ns -o wide
  kubectl describe pod -n dev-ns -l app=api-backend | grep -A 5 "Events:" || true
  echo -e "\e[1;36m---------------------------------------------------------------\e[0m"

  clear

  # Mostrar briefing al estudiante
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m K8S-002-v1 | La Imagen Perdida – ImagePullBackOff por Typo | Dificultad: 3/10 | L1\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e ""
  echo -e " \e[1mContexto:\e[0m Te encuentras en el nodo \e[1mcontrolplane\e[0m de un cluster Kubernetes"
  echo -e " con 3 nodos (1 control-plane + 2 workers: node01, node02)."
  echo -e ""
  echo -e " \e[1mSituación:\e[0m El equipo de backend reporta que acaba de desplegar una nueva"
  echo -e " versión de la aplicación \e[1mapi-backend\e[0m en el namespace \e[1mdev-ns\e[0m. El pipeline"
  echo -e " de CI/CD terminó en verde, pero al verificar el estado del servicio, este no"
  echo -e " responde. Al listar los pods, aparece uno con estado \e[7mImagePullBackOff\e[0m y"
  echo -e " múltiples reintentos fallidos."
  echo -e ""
  echo -e " El desarrollador junior insiste en que \e[3m\"la imagen existe porque el build pasó\"\e[0m."
  echo -e " Sin embargo, no revisó el nombre exacto con el que se etiquetó la imagen en el"
  echo -e " manifiesto de deployment."
  echo -e ""
  echo -e " \e[1mProblema:\e[0m Hay un TYPO sutil en el nombre de la imagen dentro del spec del"
  echo -e " deployment (por ejemplo, una letra duplicada o un tag inexistente). El kubelet"
  echo -e " intenta hacer pull, containerd reporta \e[3m\"manifest unknown\"\e[0m o \e[3m\"not found\"\e[0m,"
  echo -e " y tras varios reintentos el pod entra en ImagePullBackOff con backoff exponencial."
  echo -e ""
  echo -e "\e[1;33m TU MISIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Confirmar el problema\e[0m"
  echo -e "    Ejecuta \e[7mkubectl get pods -n dev-ns\e[0m y verifica que el pod"
  echo -e "    \e[1mapi-backend\e[0m aparece en estado \e[7mImagePullBackOff\e[0m o \e[7mErrImagePull\e[0m."
  echo -e ""
  echo -e " \e[1m2. Investigar la causa raíz\e[0m"
  echo -e "    Usa \e[7mkubectl describe pod <nombre-pod> -n dev-ns\e[0m y lee la sección"
  echo -e "    \e[1mEvents\e[0m. Identifica el mensaje exacto de error al hacer pull de la imagen."
  echo -e "    Pista: busca mensajes como \e[3m\"manifest unknown\"\e[0m, \e[3m\"not found\"\e[0m o"
  echo -e "    \e[3m\"pull access denied\"\e[0m."
  echo -e ""
  echo -e " \e[1m3. Identificar el typo\e[0m"
  echo -e "    Determina cuál es el error en el nombre/tag de la imagen. Compara la imagen"
  echo -e "    referenciada en el pod con el nombre correcto que debería usarse."
  echo -e "    Pista: \e[7mkubectl get pod <nombre-pod> -n dev-ns -o jsonpath='{.spec.containers[0].image}'\e[0m"
  echo -e ""
  echo -e " \e[1m4. Corregir el deployment\e[0m"
  echo -e "    Usa \e[7mkubectl set image\e[0m para corregir la imagen SIN editar el YAML manualmente."
  echo -e "    Sintaxis: \e[7mkubectl set image deployment/<nombre> <contenedor>=<imagen-corregida> -n <ns>\e[0m"
  echo -e ""
  echo -e " \e[1m5. Verificar la corrección\e[0m"
  echo -e "    Confirma que el pod pasa a estado \e[1mRunning\e[0m y que la imagen correcta fue"
  echo -e "    descargada. Usa \e[7mkubectl get pods -n dev-ns -w\e[0m para observar en tiempo real."
  echo -e ""
  echo -e " \e[1m6. Documentar el procedimiento\e[0m"
  echo -e "    Escribe el comando exacto de corrección aplicado."
  echo -e "    Ejemplo: \e[7mkubectl set image deployment/api-backend api-backend=nginx:1.25-alpine -n dev-ns\e[0m"
  echo -e ""
  echo -e "\e[1;33m COMANDOS ÚTILES DE REFERENCIA\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  \e[7mkubectl get pods -n dev-ns\e[0m                       # Lista pods en dev-ns"
  echo -e "  \e[7mkubectl describe pod <pod> -n dev-ns\e[0m             # Ver events del pod"
  echo -e "  \e[7mkubectl get events -n dev-ns --sort-by=.lastTimestamp\e[0m  # Events ordenados"
  echo -e "  \e[7mkubectl get deployment api-backend -n dev-ns -o yaml\e[0m   # Ver spec completo"
  echo -e "  \e[7mkubectl set image deployment/<name> <container>=<image> -n <ns>\e[0m"
  echo -e "  \e[7mkubectl rollout status deployment/<name> -n <ns>\e[0m       # Ver progreso"
  echo -e "  \e[7mkubectl rollout undo deployment/<name> -n <ns>\e[0m         # Revertir cambio"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Confirmar que api-backend está en ImagePullBackOff en dev-ns              15%"
  echo -e "  [ ] Usar 'kubectl describe pod' y leer la sección Events                      20%"
  echo -e "  [ ] Identificar el typo en el nombre de la imagen (nginxx vs nginx)           20%"
  echo -e "  [ ] Corregir con 'kubectl set image' (sin editar YAML manualmente)            25%"
  echo -e "  [ ] Verificar que el pod pasa a estado Running                                15%"
  echo -e "  [ ] Documentar el comando exacto de corrección aplicado                        5%"
  echo -e ""
  echo -e "\e[1;33m PISTA PARA NO QUEDARSE ATASCADO\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  Si tras 2 minutos el pod sigue en ErrImagePull en lugar de ImagePullBackOff,"
  echo -e "  es normal: el kubelet está reintentando. Espera o fuerza el backoff con:"
  echo -e "  \e[7mkubectl delete pod <pod> -n dev-ns\e[0m  (el Deployment recreará el pod)"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e ""
  echo -e " \e[1;32m¡Comienza tu investigación!\e[0m La imagen perdida está esperando ser encontrada..."
  echo -e ""
  OUTEREOF
  bash /tmp/setup.sh && rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - Kubernetes
  - ImagePullBackOff
  - kubectl-describe
  - Troubleshooting
  - Fundamentos
Escenario: |-
  - Situación: El equipo de backend reporta que acaba de desplegar una nueva versión de
  la aplicación 'api-backend' en el namespace 'dev-ns'. El pipeline de CI/CD terminó
  en verde, pero al verificar el estado del servicio, este no responde. Al listar los
  pods, aparece uno con estado 'ImagePullBackOff' y múltiples reinicios intentados.
  - El desarrollador junior insiste en que "la imagen existe porque el build pasó".
  Sin embargo, no revisó el nombre exacto con el que se etiquetó la imagen en el
  manifiesto de deployment.
  - La realidad, hay un TYPO en el nombre de la imagen dentro del spec del deployment
  (por ejemplo, 'nginxx' en lugar de 'nginx', o un tag inexistente). El kubelet
  intenta hacer pull, containerd reporta "manifest unknown" o "not found", y tras
  varios reintentos el pod entra en ImagePullBackOff con backoff exponencial.
  - Tu misión
    1. Conectarte al 'controlplane' y verificar el estado de los pods en 'dev-ns'.
    2. Identificar el pod 'api-backend' en estado ImagePullBackOff.
    3. Usar 'kubectl describe pod' para leer la sección Events y encontrar el error real.
    4. Determinar cuál es el typo o error en el nombre/tag de la imagen.
    5. Corregir el deployment con 'kubectl set image' (sin editar YAML manualmente).
    6. Verificar que el pod pasa a estado Running y que la imagen correcta fue descargada.
    7. Documentar el comando exacto de corrección aplicado.
---
