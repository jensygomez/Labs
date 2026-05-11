
---


course: "Prep Course - Linux Foundation Certified System Administrator (LFCS)"  
module: "Operational Deployments"  
date: 2026-04-28  
tags: #Linux/LFCS-Certification/Operations-Deployment 

## 🐧 Manage Software with Package Manager

En el módulo **Operational Deployments** del curso _Prep Course - Linux Foundation Certified System Administrator (LFCS) Certification_, se aborda la gestión de software mediante _package managers_. En sistemas basados en Ubuntu, se utiliza **APT (Advanced Package Tool)** para instalar, actualizar y administrar paquetes de software desde repositorios oficiales. Estas actualizaciones provienen de servidores remotos y, por razones de seguridad, requieren el uso de privilegios administrativos con `sudo`. Comandos clave como `apt update` permiten sincronizar la lista de paquetes disponibles, mientras que `apt upgrade` se encarga de aplicar las actualizaciones al sistema.

También se explicó el concepto de _paquete_ como una unidad de software que incluye binarios, configuraciones y dependencias necesarias para su funcionamiento. Se mostró cómo instalar aplicaciones como **NGINX** usando APT, así como la importancia de gestionar correctamente las dependencias. Además, se cubrió la desinstalación de paquetes con comandos como `apt remove` y la limpieza completa del sistema eliminando dependencias innecesarias con `apt autoremove`, lo que ayuda a mantener un entorno limpio y eficiente.