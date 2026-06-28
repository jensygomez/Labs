---
Curso: Prep Course - LFCS Certification
Modulo: Kubernetes Fundamentos
Playground: K8S-003
Titulo: El Servicio Fantasma --> Service sin Endpoints por Selector Mismatch
Fecha de Inicio: 2026-06-25
Dificultad: 4/10
Level Escalation: L1
Objetivo: |-
  Aprobar LFCS y RHCSA (Troubleshooting de servicios Kubernetes sin endpoints).
  Pensar como Sysadmin Linux Pleno (Diagnóstico basado en selectores y labels).
  Prepararme para DevOps Engineer y Sysadmin Kubernetes (Entender cómo los Services
  descubren pods mediante label selectors y por qué un mismatch deja el service "huérfano").
Temas: |-
  Relación Service ↔ Pod mediante label selectors
  Endpoints y EndpointSlices (objetos automáticos que crea Kubernetes)
  Comandos de diagnóstico: kubectl get endpoints, kubectl describe service,
  kubectl get pods --show-labels, kubectl get service -o yaml
  Diferencia entre ClusterIP, NodePort y LoadBalancer
  Sintaxis de labels y selectors (matchLabels vs selector plano)
  Cómo verificar que un Service tiene 0 ENDPOINTS y qué significa
  Corrección: kubectl edit service, kubectl patch, o re-aplicar manifiesto
Competencias: |-
  Identificar que un Service tiene 0 ENDPOINTS usando 'kubectl get svc' o 'kubectl get endpoints'.
  Utilizar 'kubectl describe service' para ver el selector configurado.
  Comparar el selector del Service con las labels reales de los pods usando
  'kubectl get pods --show-labels' o jsonpath.
  Detectar el mismatch (typo sutil, orden incorrecto, valor diferente) entre
  selector del Service y labels del Pod.
  Corregir el selector del Service sin recrear el Deployment (usando kubectl edit/patch).
  Verificar que los ENDPOINTS aparecen automáticamente tras la corrección.
  Documentar el procedimiento de diagnóstico paso a paso.
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
  kubectl delete namespace prod-ns --ignore-not-found=true --now=true 2>/dev/null || true
  kubectl delete service web-frontend-svc --namespace=prod-ns --ignore-not-found=true --wait=false 2>/dev/null || true
  kubectl delete deployment web-frontend --namespace=prod-ns --ignore-not-found=true --wait=false 2>/dev/null || true
  sleep 3

  echo -e "\e[1;33m⏳ Preparando escenario K8S-003 - El Servicio Fantasma...\e[0m"

  # Crear namespace 'prod-ns'
  kubectl create namespace prod-ns 2>/dev/null || {
      echo -e "\e[1;33m  [!] El namespace prod-ns ya existe, continuando...\e[0m"
  }

  # ============================================================================
  # INYECCIÓN DEL BUG: Service con selector typo (web-fronend en vez de web-frontend)
  # ============================================================================

  # 1) Crear Deployment con labels CORRECTAS (los pods están sanos)
  kubectl apply -f - <<YAML
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: web-frontend
    namespace: prod-ns
    labels:
      app: web-frontend
      tier: frontend
      environment: production
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: web-frontend
    template:
      metadata:
        labels:
          app: web-frontend
          tier: frontend
          version: v1
      spec:
        containers:
        - name: web-frontend
          image: nginx:1.25-alpine
          ports:
          - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "250m"
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
  YAML

  # 2) Crear Service con SELECTOR TYPO (el bug a diagnosticar)
  #    Selector dice:    app: web-fronend   (falta la "t")
  #    Pods tienen:      app: web-frontend  (correcto)
  #    Resultado: 0 ENDPOINTS -> Service fantasma
  kubectl apply -f - <<YAML
  apiVersion: v1
  kind: Service
  metadata:
    name: web-frontend-svc
    namespace: prod-ns
    labels:
      app: web-frontend
      tier: frontend
  spec:
    type: ClusterIP
    selector:
      app: web-fronend
    ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: http
  YAML

  echo -e "\e[1;33m⏳ Esperando a que los 3 pods del Deployment estén Running...\e[0m"

  # Esperar hasta 120 segundos a que los pods estén Running
  for i in {1..24}; do
      READY_COUNT=$(kubectl get pods -n prod-ns -l app=web-frontend --no-headers 2>/dev/null | grep -c "Running" || echo "0")
      if [ "$READY_COUNT" -eq 3 ]; then
          echo -e "\e[1;32m✓ 3 pods de web-frontend en estado Running en namespace prod-ns\e[0m"
          break
      fi
      if [ $i -eq 24 ]; then
          echo -e "\e[1;33m  [!] Advertencia: Solo $READY_COUNT/3 pods Running después de 120s.\e[0m"
          echo -e "\e[1;33m  [!] El estudiante deberá investigar el estado de los pods.\e[0m"
      else
          echo -ne ".  "
          sleep 5
      fi
  done

  # Verificar que el Service tiene 0 ENDPOINTS (confirmar que el bug fue inyectado)
  echo -e "\e[1;33m⏳ Verificando que el Service quedó sin endpoints (bug inyectado)...\e[0m"
  sleep 3
  ENDPOINTS=$(kubectl get endpoints web-frontend-svc -n prod-ns -o jsonpath='{.subsets}' 2>/dev/null || echo "")
  if [ -z "$ENDPOINTS" ] || [ "$ENDPOINTS" = "" ] || [ "$ENDPOINTS" = "[]" ]; then
      echo -e "\e[1;32m✓ Confirmado: web-frontend-svc tiene 0 ENDPOINTS (bug activo)\e[0m"
  else
      echo -e "\e[1;31m❌ Error: El Service tiene endpoints poblados. El bug no se inyectó correctamente.\e[0m"
      kubectl get endpoints web-frontend-svc -n prod-ns
      exit 1
  fi

  # Verificar que los objetos existen
  SVC_EXISTS=$(kubectl get service web-frontend-svc -n prod-ns --no-headers 2>/dev/null | wc -l)
  DEP_EXISTS=$(kubectl get deployment web-frontend -n prod-ns --no-headers 2>/dev/null | wc -l)
  if [ "$SVC_EXISTS" -eq 0 ] || [ "$DEP_EXISTS" -eq 0 ]; then
      echo -e "\e[1;31m❌ Error: No se pudieron crear los objetos en prod-ns.\e[0m"
      exit 1
  fi
  echo -e "\e[1;32m✓ Objetos creados: Deployment web-frontend + Service web-frontend-svc\e[0m"

  # Información interna del setup (no mostrar al estudiante en el briefing)
  echo -e "\e[1;36m--- Información interna del setup (NO MOSTRAR AL ESTUDIANTE) ---\e[0m"
  kubectl get pods -n prod-ns -o wide
  kubectl get service web-frontend-svc -n prod-ns
  kubectl get endpoints web-frontend-svc -n prod-ns
  echo -e "\e[1;36m---------------------------------------------------------------\e[0m"

  clear

  # ===========================================================================
  # BRIEFING AL ESTUDIANTE
  # ===========================================================================
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m K8S-003-v1 | El Servicio Fantasma – Service sin Endpoints | Dificultad: 4/10 | L1\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e ""
  echo -e " \e[1mContexto:\e[0m Te encuentras en el nodo \e[1mcontrolplane\e[0m de un cluster Kubernetes"
  echo -e " con 3 nodos (1 control-plane + 2 workers: node01, node02)."
  echo -e ""
  echo -e " \e[1mSituación:\e[0m El equipo de frontend acaba de desplegar una nueva versión de la"
  echo -e " aplicación \e[1mweb-frontend\e[0m en el namespace \e[1mprod-ns\e[0m. El Deployment levantó"
  echo -e " correctamente sus 3 réplicas y los pods responden si se les hace curl directo"
  echo -e " por IP. Sin embargo, cuando QA intenta acceder a la aplicación a través del"
  echo -e " Service \e[1mweb-frontend-svc\e[0m (usando su ClusterIP o DNS interno), la conexión"
  echo -e " es rechazada o hace timeout."
  echo -e ""
  echo -e " El desarrollador junior revisó el Deployment y confirma que los pods están"
  echo -e " \e[1mRunning\e[0m y saludables. También revisó el Service y dice que \e[3m\"todo parece"
  echo -e " correcto\"\e[0m. Sin embargo, al hacer \e[7mkubectl get endpoints\e[0m el campo ENDPOINTS"
  echo -e " aparece vacío (\e[7m<none>\e[0m)."
  echo -e ""
  echo -e " \e[1mProblema:\e[0m Hay un \e[1;31mMISMATCH\e[0m sutil entre el \e[1mselector\e[0m del Service y las"
  echo -e " \e[1mlabels\e[0m reales de los pods. Puede ser un typo (una letra faltante o duplicada),"
  echo -e " un valor incorrecto, o una label adicional exigida por el Service que los pods"
  echo -e " no tienen. Como el Service no encuentra ningún pod que coincida con su selector,"
  echo -e " Kubernetes no crea el objeto Endpoints asociado, y el Service no tiene a quién"
  echo -e " enrutar el tráfico. El Service \e[1m\"existe\"\e[0m pero es un \e[1mfantasma\e[0m: no conecta con nada."
  echo -e ""
  echo -e "\e[1;33m TU MISIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Confirmar el problema\e[0m"
  echo -e "    Ejecuta \e[7mkubectl get service -n prod-ns\e[0m y verifica que"
  echo -e "    \e[1mweb-frontend-svc\e[0m muestra \e[7m<none>\e[0m en la columna ENDPOINTS."
  echo -e "    Confirma también con \e[7mkubectl get endpoints -n prod-ns\e[0m."
  echo -e ""
  echo -e " \e[1m2. Investigar el selector del Service\e[0m"
  echo -e "    Usa \e[7mkubectl describe service web-frontend-svc -n prod-ns\e[0m y localiza"
  echo -e "    la sección \e[1mSelector\e[0m. Anota exactamente qué labels está buscando."
  echo -e ""
  echo -e " \e[1m3. Investigar las labels reales de los pods\e[0m"
  echo -e "    Ejecuta \e[7mkubectl get pods -n prod-ns --show-labels\e[0m o usa jsonpath:"
  echo -e "    \e[7mkubectl get pods -n prod-ns -o jsonpath='{range .items[*]}{.metadata.name}{\"\\t\"}{.metadata.labels}{\"\\n\"}{end}'\e[0m"
  echo -e ""
  echo -e " \e[1m4. Identificar el mismatch exacto\e[0m"
  echo -e "    Compara el selector del Service con las labels de los pods. ¿Qué diferencia"
  echo -e "    encuentras? ¿Typo? ¿Valor incorrecto? ¿Label faltante?"
  echo -e ""
  echo -e " \e[1m5. Corregir el selector del Service\e[0m"
  echo -e "    Usa \e[7mkubectl edit service web-frontend-svc -n prod-ns\e[0m para modificar"
  echo -e "    el selector en caliente. \e[1mNO toques el Deployment\e[0m, solo el Service."
  echo -e "    Alternativa: \e[7mkubectl patch service web-frontend-svc -n prod-ns -p '{\"spec\":{\"selector\":{\"app\":\"web-frontend\"}}}'\e[0m"
  echo -e ""
  echo -e " \e[1m6. Verificar la corrección\e[0m"
  echo -e "    Confirma que el Service ahora muestra ENDPOINTS poblados con las IPs de los"
  echo -e "    3 pods. Usa \e[7mkubectl get endpoints web-frontend-svc -n prod-ns\e[0m."
  echo -e ""
  echo -e " \e[1m7. Probar conectividad interna\e[0m"
  echo -e "    Lanza un pod temporal y haz curl al ClusterIP del Service:"
  echo -e "    \e[7mkubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl -s http://web-frontend-svc.prod-ns.svc.cluster.local\e[0m"
  echo -e ""
  echo -e " \e[1m8. Documentar el procedimiento\e[0m"
  echo -e "    Escribe el comando exacto de corrección aplicado y explica qué label"
  echo -e "    estaba mal y por qué."
  echo -e ""
  echo -e "\e[1;33m COMANDOS ÚTILES DE REFERENCIA\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  \e[7mkubectl get service -n prod-ns\e[0m                                # Ver services y ENDPOINTS"
  echo -e "  \e[7mkubectl get endpoints -n prod-ns\e[0m                              # Ver endpoints directamente"
  echo -e "  \e[7mkubectl describe service <svc> -n prod-ns\e[0m                     # Ver selector del Service"
  echo -e "  \e[7mkubectl get pods -n prod-ns --show-labels\e[0m                     # Ver labels de pods"
  echo -e "  \e[7mkubectl get pods -n prod-ns --show-labels -l app=web-frontend\e[0m # Filtrar por label"
  echo -e "  \e[7mkubectl edit service <svc> -n prod-ns\e[0m                         # Editar selector en caliente"
  echo -e "  \e[7mkubectl patch service <svc> -n prod-ns -p '<json>'\e[0m            # Patch del selector"
  echo -e "  \e[7mkubectl get service <svc> -n prod-ns -o yaml\e[0m                  # Ver spec completo"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Confirmar que web-frontend-svc tiene 0 ENDPOINTS en prod-ns             15%"
  echo -e "  [ ] Usar 'kubectl describe service' y leer el Selector                      15%"
  echo -e "  [ ] Comparar selector del Service con labels reales de los pods             20%"
  echo -e "  [ ] Identificar el mismatch exacto (typo: web-fronend vs web-frontend)      20%"
  echo -e "  [ ] Corregir el selector del Service (sin tocar el Deployment)              20%"
  echo -e "  [ ] Verificar que ENDPOINTS queda poblado con las 3 IPs de pods              5%"
  echo -e "  [ ] Documentar el comando exacto de corrección aplicado                      5%"
  echo -e ""
  echo -e "\e[1;33m PISTA PARA NO QUEDARSE ATASCADO\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  Si no encuentras el typo a simple vista, usa este truco para comparar"
  echo -e "  lado a lado el selector del Service con las labels de los pods:"
  echo -e "  \e[7mecho \"Selector del Service:\"; kubectl get service web-frontend-svc -n prod-ns -o jsonpath='{.spec.selector}'; echo\e[0m"
  echo -e "  \e[7mecho \"Labels de los pods:\"; kubectl get pods -n prod-ns -l app=web-frontend -o jsonpath='{.items[0].metadata.labels}'; echo\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e ""
  echo -e " \e[1;32m¡Comienza tu investigación!\e[0m El servicio fantasma está esperando ser conectado..."
  echo -e ""
  OUTEREOF

  bash /tmp/setup.sh
  rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - Kubernetes
  - Services
  - Endpoints
  - LabelSelectors
  - kubectl-describe
  - Troubleshooting
  - Fundamentos
Escenario: |-
  Situación: El equipo de frontend acaba de desplegar una nueva versión de la
  aplicación 'web-frontend' en el namespace 'prod-ns'. El Deployment está Running,
  los pods responden correctamente si se les hace curl directo por IP, pero cuando
  el equipo de QA intenta acceder a la aplicación a través del Service 'web-frontend-svc'
  (usando su ClusterIP o DNS interno), la conexión es rechazada o hace timeout.

  El desarrollador junior revisó el Deployment y confirma que los pods están Running
  y saludables. También revisó el Service y "todo parece correcto". Sin embargo,
  al hacer 'kubectl get endpoints' el campo ENDPOINTS aparece vacío (<none>).

  La realidad: hay un MISMATCH sutil entre el selector del Service y las labels
  reales de los pods. Puede ser un typo (ej: 'web-fronend' en lugar de 'web-frontend'),
  un valor incorrecto (ej: 'version: v2' cuando los pods tienen 'version: v1'),
  o una label adicional exigida por el Service que los pods no tienen.

  Como el Service no encuentra ningún pod que coincida con su selector, Kubernetes
  no crea el objeto Endpoints asociado, y por tanto el Service no tiene a quién
  enrutar el tráfico. El Service "existe" pero es un fantasma: no conecta con nada.

  Tu misión:
  1. Conectarte al 'controlplane' y verificar el estado del Service 'web-frontend-svc'
     en el namespace 'prod-ns'. Confirmar que tiene 0 ENDPOINTS.
  2. Usar 'kubectl describe service web-frontend-svc -n prod-ns' para leer el selector
     configurado.
  3. Listar los pods del Deployment con 'kubectl get pods -n prod-ns --show-labels'
     y comparar las labels reales con el selector del Service.
  4. Identificar el mismatch exacto (typo, valor incorrecto o label faltante).
  5. Corregir el selector del Service usando 'kubectl edit service' o 'kubectl patch'
     (sin tocar el Deployment).
  6. Verificar que el Service ahora muestra ENDPOINTS poblados (IPs de los pods).
  7. Probar conectividad interna con 'kubectl run' + curl al ClusterIP del Service.
  8. Documentar el comando exacto de corrección aplicado.
---
[[Laboratorios del LFCS]]


Sure, I can tell you about a recent troubleshooting case I worked on in my home lab, where I'm building hands-on Kubernetes skills.

The situation was: a frontend team had just deployed a new version of a web application with three replicas. The pods were running fine — I could curl them directly by IP — but when QA tried to reach the app through the Kubernetes Service, the connection kept timing out. The developer who deployed it insisted everything looked correct.

So I started investigating systematically. First, I checked the Service and confirmed it had zero endpoints, which told me Kubernetes wasn't routing traffic to any pod at all. Then I described the Service to see its selector, and separately checked the actual labels on the running pods. When I compared them side by side, I found a one-letter typo: the Service selector was looking for "web-fronend", but the pods were labeled "web-frontend". Because Kubernetes does exact string matching on selectors, that tiny difference meant the Service couldn't find any matching pod, so it never created an Endpoints object.

I fixed it by patching just the Service selector, without touching the Deployment, since the pods themselves were healthy. After that, I verified the endpoints were populated with all three pod IPs, and confirmed everything worked end-to-end by spinning up a temporary curl pod and hitting the Service through its internal DNS name.

What I took away from this is how a single typo, invisible at first glance, can completely break service discovery in Kubernetes — and how important it is to verify with actual command output at every step, rather than assuming something is correct just because it looks fine on the surface.