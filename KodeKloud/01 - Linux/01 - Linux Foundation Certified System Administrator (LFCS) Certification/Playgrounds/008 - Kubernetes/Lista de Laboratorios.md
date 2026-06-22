




### K8s-001 - El Pod Fantasma - Namespace Incorrecto
- Dificultad: 3/10
- Level escalation: L1
- Temas: Namespaces, kubectl basic commands y context awareness.
Objetivo: Prepararme para aprobar los examenes del LFCS y RHCSA, Para Trabajar como Sysadmin Linux Pleno, Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
Escenario: El equipo de desarrollo reporta haber desplegado una aplicación crítica llamada `web-frontend` hace 10 minutos. Sin embargo, al ejecutar `kubectl get pods`, la lista aparece vacía o no muestra dicho pod. El junior sysadmin jura que el comando de despliegue fue exitoso. 
  - Tu misión es localizar el pod "fantasma" y verificar su estado real. Se sospecha que fue desplegado en un namespace diferente al predeterminado (`default`).
Tareas: Identificar en qué namespace se encuentra el pod `web-frontend`, Verificar el estado del pod y asegurarse de que está en estado `Running`.
  3. Documentar el comando exacto utilizado para visualizarlo correctamente. 
  
  
### K8s-002 - La Imagen Rota - ImagePullBackOff
- Dificultad: 3/10
- Level escalation: L1
- Temas: Container images, tags, kubectl describe, events troubleshooting.
- Objetivo: Prepararme para aprobar los examenes del LFCS y RHCSA. Para Trabajar como Sysadmin Linux Pleno. Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario: Un desarrollador ha actualizado el deployment de la API payment-service. Tras aplicar los cambios, el pod no logra iniciar y se queda en un bucle infinito con el estado ImagePullBackOff o ErrImagePull. El equipo necesita que el servicio esté arriba lo antes posible. Al revisar el YAML, parece que hay un error tipográfico en el nombre de la imagen o en la etiqueta (tag) de la versión.
- Tareas: Usar kubectl describe pod para identificar el mensaje de error exacto del evento.
Determinar si el error es por nombre de imagen incorrecto, tag inexistente o problema de autenticación (en este caso será nombre/tag).
Corregir el deployment para apuntar a la imagen correcta (nginx:1.24-alpine o la especificada en las instrucciones del laboratorio) y validar que el pod llegue a estado Running.

### K8s-003 - El Bucle Infinito - CrashLoopBackOff
- Dificultad: 4/10
- Level escalation: L1
- Temas: Container logs, exit codes, application startup errors.
- Objetivo: Prepararme para aprobar los examenes del LFCS y RHCSA. Para Trabajar como Sysadmin Linux Pleno. Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario: El pod log-processor está en estado CrashLoopBackOff. Esto significa que el contenedor intenta arrancar, falla inmediatamente y Kubernetes lo reinicia constantemente. No hay errores de imagen ni de red. El problema reside dentro de la aplicación o en su configuración de arranque. Necesitas actuar como detective forense para leer los registros del contenedor fallido y entender por qué termina el proceso.
- Tareas: Ejecutar kubectl logs para recuperar el mensaje de error de la aplicación.
Identificar la causa raíz (ej. variable de entorno faltante, comando mal formado, archivo de configuración ausente).
Aplicar la corrección necesaria en el Deployment o Pod para que la aplicación inicie correctamente y se mantenga estable.

### K8s-004 - La Espera Eterna - Pod Pending
- Dificultad: 4/10
- Level escalation: L1
- Temas: Resource requests/limits, node capacity, scheduling.
- Objetivo:
Prepararme para aprobar los examenes del LFCS y RHCSA.
Para Trabajar como Sysadmin Linux Pleno.
Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario:Se ha solicitado el despliegue de un pod llamado big-data-job. El pod ha sido creado exitosamente, pero lleva más de 15 minutos en estado Pending. No hay errores de imagen ni fallos de aplicación. El scheduler de Kubernetes parece no encontrar un lugar adecuado para ubicar este pod. Se sospecha que las solicitudes de recursos (CPU/RAM) exceden la capacidad disponible en los nodos del clúster.
- Tareas: Investigar con kubectl describe pod la razón del pending (ej. Insufficient cpu, Insufficient memory).
Verificar la capacidad de los nodos disponibles con kubectl top nodes o kubectl describe node.
Ajustar los requests y limits del recurso en el manifiesto del pod/deployment para que sean compatibles con la capacidad del clúster y lograr que se programe (schedule).

### K8s-005 - El Selector Perdido - Service sin Endpoints
- Dificultad: 4/10
- Level escalation: L1
- Temas: Services, Labels, Selectors, networking basics.
- Objetivo:
Prepararme para aprobar los examenes del LFCS y RHCSA.
Para Trabajar como Sysadmin Linux Pleno.
Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario:
Existe un Servicio (ClusterIP) llamado backend-api y también existen Pods corriendo correctamente con la aplicación. Sin embargo, al hacer pruebas de conectividad desde otro pod hacia el servicio, la conexión es rechazada o se queda colgada. Al inspeccionar el servicio, se observa que la columna ENDPOINTS aparece como <none>. Esto indica que el Servicio no sabe a qué Pods debe enviar el tráfico.
- Tareas:
Revisar las labels asignadas a los Pods activos.
Revisar el selector definido en el objeto Service.
Identificar la discrepancia (mismatch) entre las etiquetas del Pod y el selector del Servicio.
Corregir el Service o los Pods para que coincidan y verificar que los Endpoints se populated.


### K8s-006 - La Configuración Invisible - ConfigMap No Montado
- Dificultad: 4/10
- Level escalation: L1
- Temas: ConfigMaps, Volume Mounts, Environment Variables.
- Objetivo:
Prepararme para aprobar los examenes del LFCS y RHCSA.
Para Trabajar como Sysadmin Linux Pleno.
Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario:
La aplicación config-app arranca correctamente (estado Running), pero se comporta de manera errática porque no está leyendo su configuración. Debería mostrar un mensaje de bienvenida personalizado definido en un ConfigMap, pero muestra el valor por defecto. El ConfigMap existe en el namespace correcto, pero parece que el Pod no lo está utilizando o lo está montando en la ruta incorrecta.
- Tareas:
Verificar la existencia y contenido del ConfigMap involucrado.
Inspeccionar el spec del Pod para ver cómo se está inyectando el ConfigMap (¿como Variable de Entorno o como Volumen?).
Corregir el nombre de referencia del ConfigMap o la ruta de montaje (mountPath) para que la aplicación pueda leer la configuración correcta.


### K8s-007 - El Secreto Oculto - Secret No Inyectado
- Dificultad: 5/10
- Level escalation: L1
- Temas: Secrets, Base64 encoding (conceptual), envFrom, security best practices.
- Objetivo:
Prepararme para aprobar los examenes del LFCS y RHCSA.
Para Trabajar como Sysadmin Linux Pleno.
Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario:
El servicio de base de datos db-connector falla al intentar autenticarse. Los logs indican "Authentication failed" o "Missing credentials". Se ha creado un Kubernetes Secret con las credenciales correctas, pero la aplicación no las recibe. Es probable que el nombre de la clave (key) dentro del Secret no coincida con la variable de entorno que espera la aplicación, o que el Secret esté siendo referenciado incorrectamente en el Deployment.
- Tareas:
Decodificar y verificar el contenido del Secret (usando kubectl get secret -o jsonpath o similar).
Comparar las claves del Secret con las variables de entorno esperadas por la aplicación.
Ajustar el Deployment para usar envFrom o valueFrom correctamente, asegurando que los nombres de las claves coincidan exactamente.


### K8s-008 - El Asesino de Memoria - OOMKilled
- Dificultad: 5/10
- Level escalation: L1
- Temas: Resource limits, Memory management, OOMKilled reason.
- Objetivo:
Prepararme para aprobar los examenes del LFCS y RHCSA.
Para Trabajar como Sysadmin Linux Pleno.
Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario:
Un pod llamado memory-hog funciona bien durante unos minutos después del reinicio, pero luego se cae repentinamente. Al hacer kubectl get pods, ves que ha reiniciado varias veces (RESTARTS aumenta). Al describir el pod, encuentras el motivo de la última terminación: Reason: OOMKilled. El contenedor está intentando consumir más memoria RAM de la que se le ha permitido en sus límites (limits).
- Tareas:
Confirmar mediante kubectl describe pod que la causa es OOMKilled.
Analizar los límites de memoria actuales asignados al contenedor.
Aumentar el memory limit a un valor razonable que permita a la aplicación funcionar sin poner en riesgo al nodo, o optimizar la aplicación si fuera posible (en este caso, ajustaremos el límite).


### K8s-009 - La Puerta Cerrada - NodePort Inaccesible
- Dificultad: 5/10
- Level escalation: L1
- Temas: Service Types (NodePort), Ports mapping, external access.
- Objetivo:
Prepararme para aprobar los examenes del LFCS y RHCSA.
Para Trabajar como Sysadmin Linux Pleno.
Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario:
Has desplegado una aplicación web y has creado un Servicio de tipo NodePort para exponerla fuera del clúster. Sin embargo, al intentar acceder desde tu navegador o mediante curl a la IP del nodo y el puerto asignado, la conexión es rechazada (Connection Refused). El pod está sano y el servicio tiene endpoints. El problema podría estar en la definición del puerto en el Service o en una confusión entre targetPort y port.
- Tareas:
Verificar la definición del Service: port, targetPort y nodePort.
Asegurarse de que el targetPort coincide con el puerto donde la aplicación escucha dentro del contenedor.
Validar que el nodePort esté dentro del rango permitido (30000-32767) y probar la conectividad externa tras la corrección.


### K8s-010 - La Salud Falsa - Readiness Probe Fallando
- Dificultad: 5/10
- Level escalation: L1
- Temas: Probes (Liveness vs Readiness), Traffic routing, Health checks.
- Objetivo:
Prepararme para aprobar los examenes del LFCS y RHCSA.
Para Trabajar como Sysadmin Linux Pleno.
Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
- Escenario:
El pod web-server aparece como Running y nunca se reinicia, pero el tráfico del Servicio no llega a él. Los usuarios reportan que la aplicación está caída intermitentemente. Al investigar, descubres que la readinessProbe está configurada incorrectamente: está consultando una ruta URL que no existe (ej. /healthz en lugar de /ready) o el puerto equivocado. Mientras la prueba de readiness falle, Kubernetes no enviará tráfico a ese pod, aunque esté técnicamente "vivo".
- Tareas:
Diferenciar entre livenessProbe (reinicia el pod) y readinessProbe (quita el tráfico).
Identificar la configuración errónea en la sonda de readiness (httpGet path, port, o initialDelaySeconds).
Corregir la sonda para que apunte al endpoint de salud real de la aplicación y verificar que el pod vuelva a recibir tráfico (Endpoints actualizados).
