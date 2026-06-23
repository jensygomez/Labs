---
Curso: Prep Course - LFCS Certification
Modulo: Kubernetes Fundamentos
Playground: K8S-001-v1
Titulo: El Pod Fantasma – Namespace Incorrecto - V1.0
Fecha de Inicio: 2026-06-13
Dificultad: 3/10
Level Escalation: L1
Objetivo: |-
  - Aprobar LFCS y RHCSA (Gestión de Namespaces y Context Awareness en Kubernetes).
  - Pensar como Sysadmin Linux Pleno (Auditoría de recursos en múltiples namespaces).
  - Prepararme para DevOps Engineer y Sysadmin Kubernetes (Entender por qué los pods no aparecen en el namespace default y cómo localizarlos).
Temas: |-
  - Namespaces en Kubernetes (default, kube-system, kube-public, kube-node-lease)
  - Comandos básicos de kubectl con flag -n / --namespace
  - Context awareness y visibilidad de recursos por namespace
  - Troubleshooting de pods "fantasma" que no aparecen en listados estándar
Competencias: |-
  - Identificar en qué namespace se encuentra un pod cuando no aparece en el namespace default.
  - Utilizar correctamente los flags de namespace en comandos kubectl para auditar recursos.
  - Comprender la隔离ción lógica que proveen los namespaces en Kubernetes.
  - Documentar el procedimiento exacto para localizar y verificar el estado de pods en namespaces no predeterminados.
Script Kubernetes: |-
tags:
  - Laboratorios-del-LFCS
  - Kubernetes
  - Namespaces
  - kubectl
  - Fundamentos
Escenario: |-
  - Situación: El equipo de desarrollo reporta haber desplegado una aplicación crítica llamada `web-frontend` hace 10 minutos. Sin embargo, al ejecutar `kubectl get pods` desde el controlplane, la lista aparece vacía o no muestra dicho pod. El junior sysadmin jura que el comando de despliegue fue exitoso y no hubo errores visibles.
  - La realidad es que el pod fue desplegado correctamente, pero en un namespace diferente al predeterminado (`default`). Esto es común cuando equipos diferentes trabajan con namespaces aislados o cuando scripts de despliegue especifican un namespace explícito sin notificarlo adecuadamente.
  - Tu misión:
    1. Conectarte al `controlplane` y ejecutar `kubectl get pods` para confirmar que el pod no aparece en el namespace default.
    2. Listar todos los namespaces disponibles con `kubectl get namespaces` para identificar namespaces no estándar.
    3. Inspeccionar cada namespace sospechoso hasta localizar el pod `web-frontend`.
    4. Verificar el estado del pod y asegurarse de que está en estado `Running`.
    5. Documentar el comando exacto utilizado para visualizarlo correctamente (ej. `kubectl get pods -n <namespace-encontrado>`).
    6. Opcional: Si el pod debe estar en default, corregir el deployment moviéndolo al namespace correcto.
---

[[Laboratorios del LFCS]]

---
