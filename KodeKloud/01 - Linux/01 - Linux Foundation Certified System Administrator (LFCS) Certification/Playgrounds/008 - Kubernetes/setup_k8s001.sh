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
kubectl delete namespace staging-ns --ignore-not-found=true --now=true 2>/dev/null || true
kubectl delete deployment web-frontend --namespace=staging-ns --ignore-not-found=true --wait=false 2>/dev/null || true

# Esperar un momento para que la limpieza se complete
sleep 2

echo -e "\e[1;33m⏳ Preparando escenario K8S-001 - El Pod Fantasma...\e[0m"

# Crear namespace 'staging-ns' (donde se desplegará el pod "fantasma")
kubectl create namespace staging-ns 2>/dev/null || {
    echo -e "\e[1;33m  [!] El namespace staging-ns ya existe, continuando...\e[0m"
}

# Crear un deployment simple en el namespace staging-ns
# Usamos nginx:latest como imagen base (disponible públicamente)
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: staging-ns
  labels:
    app: web-frontend
    environment: staging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
        environment: staging
    spec:
      containers:
      - name: nginx
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
YAML

echo -e "\e[1;33m⏳ Esperando a que el pod sea schedulizado...\e[0m"

# Esperar hasta 60 segundos para que el pod esté Running
for i in {1..12}; do
    POD_STATUS=$(kubectl get pods -n staging-ns -l app=web-frontend --no-headers -o custom-columns=":status.phase" 2>/dev/null || echo "")
    if [ "$POD_STATUS" == "Running" ]; then
        echo -e "\e[1;32m✓ Pod web-frontend en estado Running en namespace staging-ns\e[0m"
        break
    fi
    if [ $i -eq 12 ]; then
        echo -e "\e[1;33m  [!] Advertencia: El pod aún no está en Running después de 60 segundos. Estado actual: $POD_STATUS\e[0m"
        echo -e "\e[1;33m  [!] Esto puede ser normal si el cluster está bajo carga. El estudiante deberá investigar.\e[0m"
    else
        echo -ne "."
        sleep 5
    fi
done

# Verificar que el pod existe en staging-ns
POD_NAME=$(kubectl get pods -n staging-ns -l app=web-frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$POD_NAME" ]; then
    echo -e "\e[1;31m❌ Error: No se pudo crear el pod web-frontend en el namespace staging-ns.\e[0m"
    kubectl get pods -n staging-ns 2>&1 || true
    exit 1
fi

echo -e "\e[1;32m✓ Pod creado: $POD_NAME en namespace staging-ns\e[0m"

# Mostrar información del pod para verificación interna (no mostrar al estudiante)
echo -e "\e[1;36m--- Información interna del setup (NO MOSTRAR AL ESTUDIANTE) ---\e[0m"
kubectl get pods -n staging-ns -o wide
echo -e "\e[1;36m---------------------------------------------------------------\e[0m"

clear

# Mostrar briefing al estudiante
echo -e "\e[1;36m================================================================================\e[0m"
echo -e "\e[1;32m K8S-001-v1 | El Pod Fantasma – Namespace Incorrecto | Dificultad: 3/10 | L1\e[0m"
echo -e "\e[1;36m================================================================================\e[0m"
echo -e ""
echo -e " \e[1mContexto:\e[0m Te encuentras en el nodo \e[1mcontrolplane\e[0m de un cluster Kubernetes"
echo -e " con 3 nodos (1 control-plane + 2 workers: node01, node02)."
echo -e ""
echo -e " \e[1mSituación:\e[0m El equipo de desarrollo reporta haber desplegado una aplicación"
echo -e " crítica llamada \e[1mweb-frontend\e[0m hace 10 minutos. Sin embargo, al ejecutar"
echo -e " \e[7mkubectl get pods\e[0m desde el controlplane, la lista aparece vacía o no"
echo -e " muestra dicho pod. El junior sysadmin jura que el comando de despliegue fue"
echo -e " exitoso y no hubo errores visibles."
echo -e ""
echo -e " \e[1mProblema:\e[0m El pod fue desplegado correctamente, pero en un namespace"
echo -e " diferente al predeterminado (\e[1mdefault\e[0m). Esto es común cuando equipos"
echo -e " diferentes trabajan con namespaces aislados o cuando scripts de despliegue"
echo -e " especifican un namespace explícito sin notificarlo adecuadamente."
echo -e ""
echo -e "\e[1;33m TU MISIÓN\e[0m"
echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
echo -e ""
echo -e " \e[1m1. Confirmar el problema\e[0m"
echo -e "    Ejecuta \e[7mkubectl get pods\e[0m y verifica que el pod \e[1mweb-frontend\e[0m NO aparece"
echo -e "    en el namespace \e[1mdefault\e[0m."
echo -e ""
echo -e " \e[1m2. Investigar namespaces disponibles\e[0m"
echo -e "    Usa \e[7mkubectl get namespaces\e[0m para listar todos los namespaces del cluster."
echo -e "    Identifica namespaces no estándar (además de default, kube-system, etc.)."
echo -e ""
echo -e " \e[1m3. Localizar el pod fantasma\e[0m"
echo -e "    Inspecciona cada namespace sospechoso hasta encontrar el pod \e[1mweb-frontend\e[0m."
echo -e "    Pista: usa \e[7mkubectl get pods -n <nombre-namespace>\e[0m"
echo -e ""
echo -e " \e[1m4. Verificar el estado del pod\e[0m"
echo -e "    Una vez localizado, confirma que el pod está en estado \e[1mRunning\e[0m."
echo -e "    Si no está Running, usa \e[7mkubectl describe pod <nombre-pod> -n <namespace>\e[0m"
echo -e "    para investigar la causa."
echo -e ""
echo -e " \e[1m5. Documentar el procedimiento\e[0m"
echo -e "    Escribe el comando exacto que permite visualizar el pod correctamente."
echo -e "    Ejemplo: \e[7mkubectl get pods -n <namespace-encontrado>\e[0m"
echo -e ""
echo -e " \e[1m6. [OPCIONAL] Corregir el deployment\e[0m"
echo -e "    Si el pod debería estar en el namespace \e[1mdefault\e[0m, investiga cómo moverlo."
echo -e "    (Pista: los deployments no se pueden mover directamente entre namespaces;"
echo -e "    deberás exportar el manifiesto, modificarlo y reaplicarlo)."
echo -e ""
echo -e "\e[1;33m COMANDOS ÚTILES DE REFERENCIA\e[0m"
echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
echo -e "  \e[7mkubectl get pods\e[0m                    # Lista pods en namespace default"
echo -e "  \e[7mkubectl get namespaces\e[0m              # Lista todos los namespaces"
echo -e "  \e[7mkubectl get pods -n <namespace>\e[0m     # Lista pods en un namespace específico"
echo -e "  \e[7mkubectl get pods -A\e[0m                 # Lista pods en TODOS los namespaces"
echo -e "  \e[7mkubectl describe pod <nombre> -n <ns>\e[0m  # Detalles de un pod"
echo -e "  \e[7mkubectl get all -n <namespace>\e[0m      # Todos los recursos en un namespace"
echo -e ""
echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
echo -e "  [ ] Confirmar que \e[7mkubectl get pods\e[0m no muestra web-frontend en default    15%"
echo -e "  [ ] Listar namespaces disponibles e identificar staging-ns                      15%"
echo -e "  [ ] Localizar el pod web-frontend en el namespace correcto                      25%"
echo -e "  [ ] Verificar que el pod está en estado Running                                 15%"
echo -e "  [ ] Documentar el comando exacto para visualizar el pod                         20%"
echo -e "  [ ] [OPCIONAL] Mover el deployment a namespace default                          10%"
echo -e ""
echo -e "\e[1;36m================================================================================\e[0m"
echo -e ""
echo -e " \e[1;32m¡Comienza tu investigación!\e[0m El pod fantasma está esperando ser encontrado..."
echo -e ""
