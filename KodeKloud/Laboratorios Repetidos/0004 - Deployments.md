# ☸️ Kubernetes Lab: Deployments (11 Tareas)
#lab #kubernetes 
**Evidencia de Laboratorio - Gestión de Ciclo de Vida y Estrategias de Despliegue**

Este documento resume las competencias técnicas adquiridas durante el laboratorio de Kubernetes enfocado en **Deployments**, cubriendo desde el diagnóstico de errores de descarga de imágenes (`ImagePullBackOff`) hasta la creación declarativa de servidores web escalables.

----------

## 📄 Página 1: Diagnóstico y Estado del Clúster

_Enfoque: Inspección de objetos y resolución de fallos en el arranque de Pods._

Tarea / Concepto Condensado

Solución Técnica / Explicación

**01-06. Inspección de Recursos**Verificación inicial del clúster. Un Deployment es un objeto de jerarquía superior que gestiona ReplicaSets y Pods automáticamente.

`kubectl get pods``kubectl get replicaset``kubectl get deployment`

**07-09. Análisis de Fallos (Debugging)**Identificación de Pods en estado `ImagePullBackOff`. Kubernetes intenta reiniciar contenedores fallidos, pero no puede si la imagen no existe.

**Estado:** `0/1 READY`**Error:** Imagen `busybox888` incorrecta.**Causa:** El nombre de la imagen no existe en el registro.

**Monitoreo de Reinicios**Kubernetes implementa _Self-healing_, intentando restaurar el servicio al detectar que un contenedor crashcloud.

`kubectl get pods` (Observar columna RESTARTS)

----------

## 📄 Página 2: Despliegue Declarativo y Especificaciones

_Enfoque: Creación de infraestructura mediante manifiestos YAML y escalabilidad._

Tarea / Concepto Condensado

Ejecución en CLI / YAML

**10. Corrección de Manifiestos**Ajuste de errores de sintaxis en archivos existentes. Los campos en YAML son sensibles a mayúsculas (ej. `kind: Deployment`).

`sed -i 's/kind: deployment/kind: Deployment/g' file.yaml``kubectl apply -f deployment-definition-1.yaml`

**11. Despliegue Nuevo (httpd)**Creación de un servidor web escalable con 3 réplicas. El Deployment asegura que el "estado deseado" se mantenga siempre.

**Archivo:** `httpd-deployment.yaml`**Replicas:** 3**Imagen:** `httpd:2.4-alpine`

**Validación de Jerarquía**Confirmación de que el Deployment creó exitosamente el ReplicaSet y los 3 Pods correspondientes.

`kubectl get all``kubectl get rs`

----------

## 💡 Notas de Implementación (Tips de KodeKloud)

1.  **Estrategia por Defecto**: Si no se especifica, Kubernetes usa `RollingUpdate`, permitiendo actualizaciones sin tiempo de inactividad al reemplazar Pods uno a uno.
2.  **Jerarquía de Objetos**: Los Deployments permiten capacidades avanzadas como _rollback_ (deshacer cambios) y pausa/reanudación de despliegues que no están disponibles en ReplicaSets simples.
3.  **Alineación de Labels**: El `spec.selector.matchLabels` del Deployment debe coincidir exactamente con las etiquetas definidas en `spec.template.metadata.labels` para que la gestión sea exitosa.
4.  **Uso de Dry Run**: Para evitar errores de sintaxis al crear archivos desde cero, se recomienda usar `--dry-run=client -o yaml` para generar una base válida rápidamente.

¿Te gustaría que ahora practiquemos cómo realizar una actualización de imagen (Rolling Update) y luego deshacerla (Rollback) en este mismo laboratorio?