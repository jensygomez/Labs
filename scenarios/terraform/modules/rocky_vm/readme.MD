# Módulo Terraform: rocky_vm

Este módulo Terraform define **la unidad básica de máquina virtual Rocky Linux** utilizada por el motor de laboratorios. El módulo describe *cómo* debe construirse una VM (disco, memoria, CPU, red y cloud-init), pero **no cuántas VMs se crean**. Un laboratorio completo (por ejemplo J01) instancia este módulo múltiples veces para componer su ecosistema (Web, DB, DNS, Proxy).

El módulo clona una **imagen base preconfigurada** (`rocky-ir-base-junior-v1.qcow2`), que ya contiene el sistema operativo y los servicios necesarios instalados pero inactivos. De esta forma, cloud-init se limita a activar, desactivar o modificar configuraciones, manteniendo tiempos de despliegue bajos y un comportamiento consistente entre laboratorios.

Este módulo depende exclusivamente de variables externas suministradas por el motor (`terraform_runner.sh`), incluyendo el rol de la VM y el contenido de `user-data` y `meta-data`. El módulo no contiene lógica de escenarios ni variantes de fallos, lo que garantiza una separación estricta entre infraestructura, configuración y simulación de incidentes.


jensy@mx:~/Labs/scenarios/terraform/modules/rocky_vm
.
├── main.tf
├── outputs.tf
├── readme.MD
└── variables.tf