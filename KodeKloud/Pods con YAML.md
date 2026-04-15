# 🚀 Kubernetes Lab: Pods con YAML (13 Tareas)
**Evidencia de Laboratorio - Infraestructura como Código**

Este documento resume la progresión técnica realizada en el laboratorio de Kubernetes, enfocándose en la transición de comandos imperativos a la gestión declarativa con YAML.

---

## 📄 Página 1: Despliegue e Inspección
*Enfoque: Creación de recursos y exploración del estado del clúster.*

| Tarea / Concepto Condensado | Ejecución en CLI (Control Plane) |
| :--- | :--- |
| **01-03. Creación de Pod Nginx**<br>Despliegue de un servidor web usando la imagen oficial. El nombre debe ser exacto (`nginx`) para validación. | `kubectl run nginx --image=nginx`<br>`kubectl get pods` |
| **04. Análisis de Imágenes**<br>Identificar la imagen específica de contenedores con prefijos dinámicos (`newpods-`). | `kubectl describe pod newpods-8rp2w \| grep -i Image` |
| **05. Ubicación en Nodos**<br>Determinar la distribución física de los Pods dentro de la arquitectura del clúster. | `kubectl get pods -o wide` |
| **06. Conteo de Contenedores**<br>Verificación de Pods multi-contenedor. La columna `READY` muestra `x/y` (y = total). | `kubectl get pod webapp`<br>`# Salida: webapp 1/2` |
| **07. Identificación de Imágenes**<br>Extracción de nombres de imágenes en pods con múltiples microservicios. | `kubectl describe pod webapp \| grep -i "Image:"` |



---

## 📄 Página 2: Troubleshooting y Flujo Declarativo
*Enfoque: Diagnóstico de errores, uso de archivos de definición y corrección en vivo.*

| Tarea / Concepto Condensado | Ejecución en CLI (Control Plane) |
| :--- | :--- |
| **08-09. Estado y Causa de Error**<br>Diagnóstico del fallo en el contenedor `agentx`. Estado: `Waiting`. Razón: `ImagePullBackOff`. | `kubectl describe pod webapp \| grep -A 5 "agentx"` |
| **10-11. Inspección de Eventos**<br>Confirmación de error: El repositorio no existe o requiere autorización (Imagen no encontrada). | `kubectl get events --field-selector involvedObject.name=webapp` |
| **12. Generación de YAML (Dry-Run)**<br>Creación de un manifiesto profesional sin afectar al clúster, redirigiendo la salida a un archivo `.yaml`. | `kubectl run redis --image=redis123 --dry-run=client -o yaml > redis-definition.yaml`<br>`kubectl create -f redis-definition.yaml` |
| **13. Corrección y Ciclo de Vida**<br>Edición del manifiesto para corregir la imagen y aplicación de cambios mediante el controlador de estado. | `vi redis-definition.yaml  # Cambiar redis123 a redis`<br>`kubectl apply -f redis-definition.yaml` |



---

## 💡 Notas de Implementación (Tips de Certificación)

1.  **Filosofía UNIX aplicada**: Al realizar este laboratorio, se priorizó el uso de herramientas de filtrado de texto como `grep` y `jsonpath` para evitar la sobrecarga de información innecesaria en la terminal.
2.  **Dry-Run es la clave**: El uso de `--dry-run=client -o yaml` es la técnica más eficiente para generar archivos base rápidamente, reduciendo errores manuales de indentación en YAML.
3.  **Gestión de Errores**: Se entendió que un error de tipo `ImagePullBackOff` es un fallo en la fase de preparación del contenedor, no necesariamente un error en el código de la aplicación.
4.  **Anotaciones con Apply**: Al usar `kubectl apply` sobre un recurso creado previamente con `create`, Kubernetes genera automáticamente la anotación `last-applied-configuration` para el rastreo de cambios.

---
*Documentación generada para el seguimiento del roadmap de System Administrator & DevOps.*