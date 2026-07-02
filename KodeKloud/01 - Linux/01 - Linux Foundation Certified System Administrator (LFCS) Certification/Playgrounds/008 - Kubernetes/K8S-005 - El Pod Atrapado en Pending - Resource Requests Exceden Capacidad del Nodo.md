---
Curso: Prep Course - LFCS Certification
Modulo: Kubernetes Fundamentos
Playground: K8S-005
Titulo: El Pod Atrapado en Pending - Resource Requests Exceden Capacidad del Nodo
Fecha de Inicio: 2026-07-02
Dificultad: 4/10
Level Escalation: L1
Objetivo: |-
  Aprobar LFCS y RHCSA (Troubleshooting de pods que no pueden ser programados).
  Pensar como Sysadmin Linux Pleno (Diagnóstico basado en recursos y capacidad del cluster).
  Prepararme para DevOps Engineer (Entender cómo el scheduler evalúa resource requests
  vs capacidad disponible del nodo, y por qué requests mal calculados dejan pods
  en Pending indefinido).
Temas: |-
  Relación Pod ↔ Node: scheduler, resource requests, allocatable resources
  Diagnóstico
  - kubectl get pods (estado Pending), kubectl describe pod (sección Events: FailedScheduling)
  - kubectl describe node (Capacity vs Allocatable), kubectl top node, kubectl get events
  Diferencia entre requests y limits, y cómo afectan la programación
  Corrección
  - kubectl edit deployment / kubectl patch para ajustar resource requests
Competencias: |-
  Identificar que el pod está en Pending y no pasa a Running.
  Usar 'kubectl describe pod' para detectar eventos de FailedScheduling.
  Analizar la capacidad disponible de los nodos con 'kubectl describe node' y 'kubectl top node'.
  Comparar resource requests del pod vs recursos allocatable de los nodos.
  Corregir los requests excesivos con 'kubectl edit deployment' o 'kubectl patch'.
  Verificar que el pod pasa a Running tras la corrección.
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

  # Limpiar escenarios previos si existen
  echo -e "\e[1;33m⏳ Limpiando escenarios previos (si existen)...\e[0m"
  kubectl delete namespace prod-ns --ignore-not-found=true --now=true 2>/dev/null || true
  kubectl delete namespace resource-hog-ns --ignore-not-found=true --now=true 2>/dev/null || true
  sleep 3

  echo -e "\e[1;33m⏳ Preparando escenario K8S-005 - El Pod Atrapado en Pending...\e[0m"

  # Crear namespaces
  kubectl create namespace prod-ns 2>/dev/null || {
      echo -e "\e[1;33m  [!] El namespace prod-ns ya existe, continuando...\e[0m"
  }

  kubectl create namespace resource-hog-ns 2>/dev/null || {
      echo -e "\e[1;33m  [!] El namespace resource-hog-ns ya existe, continuando...\e[0m"
  }

  # ============================================================================
  # INYECCIÓN DEL BUG: Llenar nodos con pods que consumen recursos
  # ============================================================================

  echo -e "\e[1;33m⏳ Creando pods que consumen recursos en node01 y node02...\e[0m"

  # Cada nodo tiene 16 CPU y ~63Gi memory allocatable
  # Vamos a consumir 15 CPU y 60Gi memory por nodo (3 pods x 5 CPU, 20Gi cada uno)
  # Esto deja solo ~1 CPU y ~3Gi disponibles

  kubectl apply -f - <<YAML
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: resource-hog-01
    namespace: resource-hog-ns
    labels:
      app: resource-hog
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: resource-hog-01
    template:
      metadata:
        labels:
          app: resource-hog-01
      spec:
        nodeName: node01
        containers:
        - name: hog
          image: busybox:1.36
          command: ["/bin/sh", "-c"]
          args:
            - "echo 'Resource hog running on node01' && sleep infinity"
          resources:
            requests:
              memory: "20Gi"
              cpu: "5"
            limits:
              memory: "20Gi"
              cpu: "5"
  YAML

  kubectl apply -f - <<YAML
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: resource-hog-02
    namespace: resource-hog-ns
    labels:
      app: resource-hog
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: resource-hog-02
    template:
      metadata:
        labels:
          app: resource-hog-02
      spec:
        nodeName: node02
        containers:
        - name: hog
          image: busybox:1.36
          command: ["/bin/sh", "-c"]
          args:
            - "echo 'Resource hog running on node02' && sleep infinity"
          resources:
            requests:
              memory: "20Gi"
              cpu: "5"
            limits:
              memory: "20Gi"
              cpu: "5"
  YAML

  echo -e "\e[1;33m⏳ Esperando a que los resource hogs se programen...\e[0m"

  # Esperar hasta 90 segundos a que los pods estén Running
  for i in {1..18}; do
      HOGS_RUNNING=$(kubectl get pods -n resource-hog-ns --no-headers 2>/dev/null | grep -c "Running" || echo "0")
      if [ "$HOGS_RUNNING" -eq 6 ]; then
          echo -e "\e[1;32m✓ 6 pods de resource-hog en estado Running\e[0m"
          break
      fi
      if [ $i -eq 18 ]; then
          echo -e "\e[1;33m  [!] Advertencia: Solo $HOGS_RUNNING/6 resource-hogs Running después de 90s.\e[0m"
      else
          echo -ne ".  "
          sleep 5
      fi
  done

  # Crear el Deployment problemático en prod-ns
  # Request de 2 CPU y 5Gi memory, pero solo quedan ~1 CPU y ~3Gi disponibles por nodo

  kubectl apply -f - <<YAML
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: data-processor
    namespace: prod-ns
    labels:
      app: data-processor
      tier: backend
      environment: production
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: data-processor
    template:
      metadata:
        labels:
          app: data-processor
          tier: backend
      spec:
        containers:
        - name: data-processor
          image: busybox:1.36
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "=== Data Processor Starting ==="
              echo "This pod should process large datasets..."
              echo "But it's stuck in Pending because there's not enough capacity!"
              sleep infinity
          resources:
            requests:
              memory: "5Gi"
              cpu: "2"
            limits:
              memory: "8Gi"
              cpu: "4"
  YAML

  echo -e "\e[1;33m⏳ Esperando a que el pod intente programarse...\e[0m"
  sleep 15

  # Verificar que el pod está en Pending
  echo -e "\e[1;33m⏳ Verificando que el pod está en Pending (bug inyectado)...\e[0m"
  sleep 5

  POD_NAME=$(kubectl get pods -n prod-ns -l app=data-processor -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [ -z "$POD_NAME" ]; then
      echo -e "\e[1;31m❌ Error: No se pudo obtener el nombre del pod.\e[0m"
      exit 1
  fi

  POD_STATUS=$(kubectl get pod -n prod-ns $POD_NAME -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$POD_STATUS" = "Pending" ]; then
      echo -e "\e[1;32m✓ Confirmado: El pod está en estado Pending (bug activo)\e[0m"
  else
      echo -e "\e[1;33m  [!] Nota: El pod está en estado $POD_STATUS. Puede que los nodos tengan más capacidad.\e[0m"
      echo -e "\e[1;33m  [!] El escenario aún es válido para practicar troubleshooting de recursos.\e[0m"
  fi

  # Verificar eventos de FailedScheduling
  EVENTS_CHECK=$(kubectl describe pod -n prod-ns $POD_NAME 2>/dev/null | grep -c "FailedScheduling" || echo "0")
  if [ "$EVENTS_CHECK" -gt 0 ]; then
      echo -e "\e[1;32m✓ Confirmado: Eventos de FailedScheduling presentes\e[0m"
  else
      echo -e "\e[1;33m  [!] Nota: No se encontraron eventos de FailedScheduling.\e[0m"
  fi

  # Verificar que los objetos existen
  DEP_EXISTS=$(kubectl get deployment data-processor -n prod-ns --no-headers 2>/dev/null | wc -l)
  if [ "$DEP_EXISTS" -eq 0 ]; then
      echo -e "\e[1;31m❌ Error: No se pudo crear el Deployment en prod-ns.\e[0m"
      exit 1
  fi
  echo -e "\e[1;32m✓ Deployment data-processor creado en namespace prod-ns\e[0m"

  # Información interna del setup
  echo -e "\e[1;36m--- Información interna del setup (NO MOSTRAR AL ESTUDIANTE) ---\e[0m"
  echo -e "\e[1;33mPods en resource-hog-ns:\e[0m"
  kubectl get pods -n resource-hog-ns -o wide
  echo -e ""
  echo -e "\e[1;33mPods en prod-ns:\e[0m"
  kubectl get pods -n prod-ns -o wide
  echo -e ""
  echo -e "\e[1;33mEventos del pod problemático:\e[0m"
  kubectl describe pod -n prod-ns $POD_NAME | grep -A 10 "Events:"
  echo -e ""
  echo -e "\e[1;33mRecursos asignados en node01:\e[0m"
  kubectl describe node node01 | grep -A 15 "Allocated resources:"
  echo -e ""
  echo -e "\e[1;33mRecursos asignados en node02:\e[0m"
  kubectl describe node node02 | grep -A 15 "Allocated resources:"
  echo -e "\e[1;36m---------------------------------------------------------------\e[0m"

  clear

  # BRIEFING AL ESTUDIANTE
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m K8S-005-v1 | El Pod Atrapado en Pending | Dificultad: 4/10 | L1\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e ""
  echo -e " \e[1mContexto:\e[0m Te encuentras en el nodo \e[1mcontrolplane\e[0m de un cluster Kubernetes"
  echo -e " con 3 nodos (1 control-plane + 2 workers: node01, node02)."
  echo -e ""
  echo -e " \e[1mSituación:\e[0m El equipo de desarrollo desplegó la aplicación \e[1mdata-processor\e[0m"
  echo -e " en el namespace \e[1mprod-ns\e[0m. El cluster está ejecutando varias cargas de trabajo"
  echo -e " en los nodos workers."
  echo -e ""
  echo -e " El pod \e[1mdata-processor\e[0m queda en estado \e[1mPending indefinidamente\e[0m. No hay errores"
  echo -e " de imagen, ni problemas de red, ni fallos de health checks. Simplemente nunca"
  echo -e " es programado por el scheduler."
  echo -e ""
  echo -e " \e[1mProblema:\e[0m Los \e[1;31mresource requests del pod exceden la capacidad disponible\e[0m"
  echo -e " en todos los nodos del cluster, considerando los recursos ya consumidos por"
  echo -e " otras cargas de trabajo."
  echo -e ""
  echo -e "\e[1;33m TU MISIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Confirmar el problema\e[0m"
  echo -e "    Ejecuta \e[7mkubectl get pods -n prod-ns\e[0m y verifica que el pod está en"
  echo -e "    estado \e[1mPending\e[0m. Anota el nombre del pod."
  echo -e ""
  echo -e " \e[1m2. Investigar el pod en detalle\e[0m"
  echo -e "    Usa \e[7mkubectl describe pod <pod-name> -n prod-ns\e[0m y revisa la sección"
  echo -e "    \e[1mEvents\e[0m. Busca eventos de \e[1mFailedScheduling\e[0m que indiquen por qué"
  echo -e "    el scheduler no puede programar el pod."
  echo -e ""
  echo -e " \e[1m3. Analizar la capacidad de los nodos\e[0m"
  echo -e "    Ejecuta \e[7mkubectl describe nodes\e[0m y revisa las secciones:"
  echo -e "    • \e[1mCapacity\e[0m: Recursos físicos totales del nodo"
  echo -e "    • \e[1mAllocatable\e[0m: Recursos disponibles para pods"
  echo -e "    • \e[1mAllocated resources\e[0m: Recursos ya asignados a pods existentes"
  echo -e ""
  echo -e " \e[1m4. Comparar requests vs capacidad disponible\e[0m"
  echo -e "    Usa \e[7mkubectl describe deployment data-processor -n prod-ns\e[0m y busca"
  echo -e "    la sección \e[1mContainers\e[0m para ver los \e[1mrequests\e[0m de CPU y memoria."
  echo -e "    Compara estos valores con los recursos \e[1mAllocatable\e[0m menos los recursos"
  echo -e "    ya \e[1mAllocados\e[0m en cada nodo."
  echo -e ""
  echo -e " \e[1m5. Identificar el cuello de botella\e[0m"
  echo -e "    ¿Cuántos CPU y memoria pide el pod? ¿Cuántos recursos quedan disponibles"
  echo -e "    en cada nodo worker después de restar lo que ya está consumido?"
  echo -e ""
  echo -e " \e[1m6. Corregir los resource requests\e[0m"
  echo -e "    Usa \e[7mkubectl edit deployment data-processor -n prod-ns\e[0m para modificar"
  echo -e "    los \e[1mresources.requests\e[0m a valores que quepan en los nodos."
  echo -e "    Sugerencia: Prueba con \e[7mcpu: 500m\e[0m y \e[7mmemory: 1Gi\e[0m."
  echo -e "    También ajusta los \e[1mlimits\e[0m proporcionalmente."
  echo -e ""
  echo -e " \e[1m7. Verificar la corrección\e[0m"
  echo -e "    Espera a que el Deployment haga rollout:"
  echo -e "    \e[7mkubectl rollout status deployment/data-processor -n prod-ns\e[0m"
  echo -e "    Luego ejecuta \e[7mkubectl get pods -n prod-ns\e[0m y confirma que el pod"
  echo -e "    ahora está en estado \e[1mRunning\e[0m y asignado a un nodo."
  echo -e ""
  echo -e " \e[1m8. Documentar el procedimiento\e[0m"
  echo -e "    Escribe los comandos exactos de corrección aplicados y explica qué valores"
  echo -e "    de resource requests eran incorrectos y por qué impedían la programación."
  echo -e ""
  echo -e "\e[1;33m COMANDOS ÚTILES DE REFERENCIA\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  \e[7mkubectl get pods -n prod-ns\e[0m                                    # Ver pods"
  echo -e "  \e[7mkubectl get pods --all-namespaces\e[0m                              # Ver todos los pods"
  echo -e "  \e[7mkubectl describe pod <pod> -n prod-ns\e[0m                         # Ver detalles y eventos"
  echo -e "  \e[7mkubectl describe nodes\e[0m                                        # Ver capacidad de nodos"
  echo -e "  \e[7mkubectl describe deployment data-processor -n prod-ns\e[0m         # Ver resource requests"
  echo -e "  \e[7mkubectl edit deployment data-processor -n prod-ns\e[0m             # Editar Deployment"
  echo -e "  \e[7mkubectl rollout status deployment/data-processor -n prod-ns\e[0m   # Ver progreso del rollout"
  echo -e "  \e[7mkubectl top nodes\e[0m                                             # Ver uso actual de recursos"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Confirmar que el pod está en estado Pending                            10%"
  echo -e "  [ ] Usar 'kubectl describe pod' y revisar eventos FailedScheduling         15%"
  echo -e "  [ ] Analizar capacidad Allocatable de los nodos con 'kubectl describe nodes' 15%"
  echo -e "  [ ] Comparar resource requests del pod vs capacidad disponible              20%"
  echo -e "  [ ] Identificar que los requests exceden la capacidad libre                 15%"
  echo -e "  [ ] Corregir los resource requests a valores realistas                      15%"
  echo -e "  [ ] Verificar que el pod pasa a Running tras la corrección                   5%"
  echo -e "  [ ] Documentar los comandos exactos de corrección aplicados                  5%"
  echo -e ""
  echo -e "\e[1;33m PISTA PARA NO QUEDARSE ATASCADO\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  Primero verifica qué pods están consumiendo recursos en el cluster:"
  echo -e "  \e[7mkubectl get pods --all-namespaces -o wide\e[0m"
  echo -e ""
  echo -e "  Luego verifica la capacidad y uso de recursos en cada nodo:"
  echo -e "  \e[7mkubectl describe nodes | grep -A 15 'Allocated resources:'\e[0m"
  echo -e ""
  echo -e "  Compara con los requests del pod problemático:"
  echo -e "  \e[7mkubectl get deployment data-processor -n prod-ns -o jsonpath='{.spec.template.spec.containers[0].resources}'\e[0m"
  echo -e ""
  echo -e "  Recuerda: Los requests deben ser menores o iguales a la capacidad Allocatable"
  echo -e "  MENOS los recursos ya Allocated en el nodo."
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e ""
  echo -e " \e[1;32m¡Comienza tu investigación!\e[0m El pod está atrapado en Pending..."
  echo -e ""
  OUTEREOF

  bash /tmp/setup.sh
  rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - Kubernetes
  - Scheduler
  - Troubleshooting
  - Fundamentos
Escenario: |-
  Situación
   - El equipo de desarrollo desplegó la aplicación 'data-processor' en el namespace 'prod-ns'
  sobre un cluster de 3 nodos workers (node01, node02, node03). El Deployment fue configurado
  con resource requests muy altos (4 CPU, 8Gi memory) pensando en "prevenir problemas de rendimiento".
  Sin embargo, cada nodo solo tiene 2 CPU allocatable y 4Gi memory allocatable después de
  reservar recursos para el sistema. Además, los otros pods del cluster ya están consumiendo
  la mayoría de los recursos disponibles.
  - El pod queda en estado Pending indefinidamente. No hay errores de imagen, ni problemas
  de red, ni fallos de health checks. Simplemente nunca es programado.
  - Al inspeccionar con 'kubectl describe pod', el alumno descubre eventos de FailedScheduling
  que indican "0/3 nodes are available: 3 Insufficient cpu, 3 Insufficient memory".
  Al revisar los nodos con 'kubectl describe node' y 'kubectl top node', se evidencia que
  ningún nodo tiene suficientes recursos allocatable para satisfacer los requests del pod.
  Tu misión
   - diagnosticar por qué el pod está en Pending, identificar que los resource requests
  exceden la capacidad disponible de todos los nodos, ajustar los requests a valores
  realistas (ej: 500m CPU, 512Mi memory) en el Deployment, y verificar que el pod
  finalmente pasa a Running y se programa en uno de los nodos disponibles.
---
[[Laboratorios del LFCS]]

---

_Sure — since my current NOC role is mostly first-level triage between clients and vendors, without hands-on access to deep troubleshooting tools, I've been building that practical experience on my own through a hands-on Kubernetes lab environment._

_Recently I worked on a case where an application pod was stuck in Pending state indefinitely. Instead of guessing, I started by checking the pod's events, which pointed to a scheduling failure due to insufficient CPU and memory on the worker nodes. I then inspected the nodes' allocatable capacity versus what was already allocated, and compared that against the pod's resource requests. I found the pod was requesting far more CPU and memory than any node actually had free. I corrected the deployment's resource requests and limits to realistic values, verified the rollout completed successfully, and confirmed the pod moved to Running._

_It reinforced for me that in Kubernetes, most scheduling issues aren't really 'broken' — they're a mismatch between what's requested and what's available._


