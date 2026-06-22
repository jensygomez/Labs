
- Titulo:**K8s-001 - El Pod Fantasma - Namespace Incorrecto**
- Dificultad: 3/10
- Level escalation: L1
- Temas: Namespaces, kubectl basic commands y context awareness.
Objetivo: Prepararme para aprobar los examenes del LFCS y RHCSA, Para Trabajar como Sysadmin Linux Pleno, Para entrevistas y posibles empleos como Devops Enginner y Sysadmin Kubernets.
Escenario: El equipo de desarrollo reporta haber desplegado una aplicación crítica llamada `web-frontend` hace 10 minutos. Sin embargo, al ejecutar `kubectl get pods`, la lista aparece vacía o no muestra dicho pod. El junior sysadmin jura que el comando de despliegue fue exitoso. 
  - Tu misión es localizar el pod "fantasma" y verificar su estado real. Se sospecha que fue desplegado en un namespace diferente al predeterminado (`default`).
Tareas: Identificar en qué namespace se encuentra el pod `web-frontend`, Verificar el estado del pod y asegurarse de que está en estado `Running`.
  3. Documentar el comando exacto utilizado para visualizarlo correctamente. 
  
  
  
  
