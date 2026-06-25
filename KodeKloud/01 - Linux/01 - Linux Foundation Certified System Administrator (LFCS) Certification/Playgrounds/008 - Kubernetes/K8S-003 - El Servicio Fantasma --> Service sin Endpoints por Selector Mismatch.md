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
