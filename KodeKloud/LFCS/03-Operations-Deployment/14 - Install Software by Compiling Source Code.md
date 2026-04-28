
---
title: "Install Software by Compiling Source Code"
course: "LFCS Prep Course - Linux Foundation Certified System Administrator"
module: "Operational Deployments"
date: 2026-04-28
tags: #linux #lfcs #sysadmin #compilation #source-code #software #make #configure
---

# ⚙️ Install Software by Compiling Source Code

La instalación de software mediante la compilación de código fuente es un proceso fundamental en entornos Linux cuando los paquetes no están disponibles en los repositorios o se requiere una versión específica. Este método consiste en descargar el código fuente del proyecto, comúnmente desde plataformas como GitHub, y preparar el entorno instalando las dependencias necesarias. Luego, se utiliza el script `./configure` para adaptar la compilación al sistema, verificando librerías y configuraciones antes de proceder.

En el ejemplo práctico, se mostró la instalación de **htop** clonando su repositorio vía CLI. Una vez dentro del directorio del proyecto, se instalaron las librerías requeridas, se ejecutó el proceso de configuración y finalmente se compiló utilizando el comando `make`. Este flujo permite generar los binarios directamente en el sistema, ofreciendo mayor control sobre la instalación, aunque requiere más pasos y conocimientos en comparación con los gestores de paquetes tradicionales.

---