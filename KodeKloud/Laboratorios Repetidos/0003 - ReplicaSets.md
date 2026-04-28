#lab #kubernetes 
# ☸️ Kubernetes Lab: ReplicaSets (16 Tareas)
**Evidencia de Laboratorio - Gestión de Disponibilidad y Control de Replicación**

Este documento resume las competencias técnicas adquiridas durante el laboratorio de Kubernetes enfocado en ReplicaSets, cubriendo desde la corrección de errores de sintaxis en manifiestos YAML hasta el escalado operativo de cargas de trabajo.

---

## 📄 Página 1: Debugging y Estructura de Manifiestos
*Enfoque: Corrección de errores comunes en definiciones YAML y coherencia de objetos.*

| Tarea / Concepto Condensado | Solución Técnica / Explicación |
| :--- | :--- |
| **01-10. Conceptos Base**<br>Identificación de Pods existentes y creación de ReplicaSets básicos para asegurar la alta disponibilidad. | `kubectl get pods`<br>`kubectl apply -f base-rs.yaml` |
| **11. API Version Matching**<br>Corrección del error de API. Los ReplicaSets no pertenecen a `v1`, sino al grupo de aplicaciones. | **Error:** `apiVersion: v1`<br>**Solución:** `apiVersion: apps/v1` |
| **12. Selector & Label Alignment**<br>Resolución del conflicto entre el selector del RS y las etiquetas del Pod Template. Deben ser idénticos para que el RS pueda "reclamar" sus Pods. | **Selector:** `tier: frontend`<br>**Template Labels:** `tier: frontend`<br>*(Deben coincidir exactamente)* |
| **13-15. Inspección de Estado**<br>Verificación de la salud del ReplicaSet y por qué los Pods no se están creando (Eventos y logs). | `kubectl describe rs <name>`<br>`kubectl get events --sort-by=.metadata.creationTimestamp` |

---

## 📄 Página 2: Operaciones de Escalado y Ciclo de Vida
*Enfoque: Modificación dinámica de la infraestructura y mantenimiento.*

| Tarea / Concepto Condensado | Ejecución en CLI / YAML |
| :--- | :--- |
| **16. Escalado Horizontal (Downscale)**<br>Reducción controlada de réplicas de 3 a 2 para optimizar el uso de recursos del cluster. | **Imperativo:** `kubectl scale rs new-replica-set --replicas=2`<br>**Declarativo:** Cambiar `replicas: 2` en el archivo y usar `kubectl apply` |
| **Edición en Vivo**<br>Modificación de parámetros directamente en el cluster sin necesidad de archivos locales. | `kubectl edit rs new-replica-set` |
| **Identificación de Orfandad**<br>Entender cómo un ReplicaSet adopta Pods existentes que coinciden con sus selectores. | `kubectl get pods --show-labels` |

---

## 💡 Notas de Implementación (Tips de K8s Administrator)

1.  **La Regla de Oro del Selector**: El `spec.selector.matchLabels` es el vínculo vital. Si cambias las etiquetas en el `template` pero no en el `selector` en un RS activo, el controlador intentará crear nuevos Pods infinitamente o fallará por validación.
2.  **API Discovery**: Si tienes duda sobre qué versión de API usar para un recurso, utiliza `kubectl explain <recurso>`. Es más rápido que buscar en la documentación oficial.
3.  **Imperativo vs Declarativo**:
    * **Imperativo (`scale`)**: Ideal para respuestas rápidas ante picos de tráfico.
    * **Declarativo (`apply`)**: Obligatorio para entornos de producción para mantener el control de versiones (GitOps).
4.  **Auto-healing**: Se comprobó que al eliminar un Pod manualmente (`kubectl delete pod...`), el ReplicaSet detecta inmediatamente la discrepancia con el estado deseado y recrea el Pod en milisegundos.

---
