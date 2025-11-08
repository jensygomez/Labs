# 🧠 **Día 2 – “Arquitectura del Proyecto Phoenix”**

**Nivel:** Principiante / Intermedio  
**Duración estimada:** 25–30 minutos  
**Entorno:** Ubuntu 22.04 en Docker  
**Objetivo:** Diseñar una estructura limpia y profesional para el proyecto _Phoenix_, organizando archivos, creando respaldos y optimizando el entorno del equipo de desarrollo.

----------

## 🎬 **Escenario del Reto**

**¡Felicidades, Jensy!** 🎉  
Después del exitoso diagnóstico de emergencia de ayer, el equipo de DataTech Corp te ha ascendido a **Arquitecto Digital** del _Proyecto Phoenix_.  
Sin embargo, te enfrentas a un caos: los archivos de código, documentación y configuración del proyecto están todos mezclados. No hay respaldos ni organización.

Tu misión es **restaurar el orden**: crear una estructura limpia, mover archivos a sus ubicaciones correctas, hacer respaldos críticos y eliminar los registros antiguos del sistema.

El futuro del proyecto depende de tu precisión y disciplina. ⚙️  
Sarah Chen, la desarrolladora líder, confía en ti.

----------

## 🎯 **Objetivos del Laboratorio**

1.  🧱 Crear una estructura de directorios profesional dentro del proyecto.
    
2.  📦 Mover los archivos a sus ubicaciones correspondientes.
    
3.  🛡️ Crear una copia de respaldo de los archivos críticos.
    
4.  📂 Reorganizar recursos compartidos del equipo.
    
5.  🧹 Comprimir y limpiar los archivos de registro antiguos.
    

----------

## 🐳 **Configuración del Entorno Docker**

Primero, crea tu entorno aislado en Docker para practicar de forma segura:

    # Ejecutar contenedor de práctica
    docker run -it --name phoenix-lab ubuntu:22.04 /bin/bash` 

Dentro del contenedor:

    # Preparar entorno base 

    apt-get update && apt-get install -y vim tar net-tools 


    # Crear estructura inicial simulada del proyecto  
    mkdir -p /home/user/project/phoenix_project 
    cd /home/user/project/phoenix_project 
    
    # Crear archivos desordenados del proyecto  
    echo  "print('Hello Phoenix!')" > main_app.py 
    echo  '{ "db": "localhost", "port": 3306 }' > config.json 
    echo  "Project Phoenix - Dev Notes" > README.md 
    
    # Crear directorios adicionales para el reto  
    mkdir -p /home/user/project/shared_docs     
    echo  "Team guidelines here." > /home/user/project/shared_docs/team_guidelines.txt 
    echo  "API specification v1.0" > /home/user/project/shared_docs/api_spec.doc
    
    mkdir -p /home/user/project/logs echo  "System started OK" > /home/user/project/logs/app_2023-01-15.log  
    echo  "Database warning" > /home/user/project/logs/db_2023-02-20.log  
    echo  "New deployment success" > /home/user/project/logs/app_2024-05-01.log` 

✅ **Resultado esperado (estructura inicial):**

    /home/user/project/
    ├── logs/
    │   ├── app_2023-01-15.log
    │   ├── db_2023-02-20.log
    │   └── app_2024-05-01.log
    ├── phoenix_project/
    │   ├── README.md
    │   ├── config.json
    │   └── main_app.py
    └── shared_docs/
        ├── team_gu

idelines.txt
    └── api_spec.doc

----------

## 🚀 **Tu Misión Paso a Paso**

----------

### 🧩 **Fase 1 – Diseñar la nueva estructura del proyecto**

Dentro de `~/project/phoenix_project`, crea las carpetas:

-   `src/` → para el código fuente
    
-   `config/` → para configuraciones
    
-   `docs/` → para documentación
    

`cd /home/user/project/phoenix_project mkdir src config docs` 

✅ **Verifica:**

    ls -F 
    
    # Debes ver: 
     
    README.md  config/  config.json  docs/  main_app.py  src/` 

----------

### 📂 **Fase 2 – Organizar los archivos existentes**

Ahora mueve los archivos a su lugar correspondiente:

`mv main_app.py src/ mv config.json config/ mv README.md docs/` 

✅ **Estructura esperada:**

    phoenix_project/
    ├── config/
    │   └── config.json
    ├── docs/
    │   └── README.md
    └── src/
        └── main_app.py

----------

### 🛡️ **Fase 3 – Crear un respaldo del archivo de configuración**

Antes de modificar configuraciones, crea un backup de `config.json`:

`cp config/config.json config/config.json.bak` 

✅ **Verifica:**

    ls config/ 
    
    # Debes ver: 
     
    config.json  config.json.bak` 

----------

### 📦 **Fase 4 – Integrar documentación compartida**

Integra el directorio `shared_docs` al proyecto principal:

`mv /home/user/project/shared_docs /home/user/project/phoenix_project/docs/` 

✅ **Resultado esperado:**

    phoenix_project/docs/
    ├── README.md
    └── shared_docs/
        ├── api_spec.doc
        └── team_guidelines.txt` 

----------

### 🧹 **Fase 5 – Archivar y limpiar logs antiguos**

Archiva los registros del año 2023 y elimínalos después de comprimirlos.

    `cd /home/user/project/logs
    
    tar -czf old_logs.tar.gz *_2023-*.log 
     
    rm *_2023-*.log`

 

✅ **Estructura final esperada:**

    logs/
    ├── app_2024-05-01.log
    └── old_logs.tar.g

----------

## 🧾 **Checklist de Validación Final**

Ejecuta cada comando para verificar el éxito del laboratorio:

    # 1. Confirmar estructura general 
    tree /home/user/project 
    
    # 2. Revisar archivos de configuración y backup      
    ls -l /home/user/project/phoenix_project/config 
    
    # 3. Revisar documentación y recursos compartidos  
    ls /home/user/project/phoenix_project/docs/shared_docs 
    
    # 4. Revisar archivos de log  
    ls -l /home/user/project/logs` 

✅ Todos los archivos deben estar correctamente organizados.  
✅ El backup `config.json.bak` debe existir.  
✅ Solo los logs del 2024 deben permanecer sin comprimir.

----------

## 🏁 **Conclusión**

**Excelente trabajo, Arquitecto Jensy.** 🏆  
Has transformado el caos en una infraestructura ordenada y segura.  
El _Proyecto Phoenix_ ahora cuenta con una base sólida para el desarrollo, gracias a tu dominio de comandos esenciales como:

-   `mkdir`
    
-   `mv`
    
-   `cp`
    
-   `tar`
    
-   `rm`
    

Estos comandos forman el corazón del trabajo de un **SysAdmin profesional**.  
El equipo de DataTech Corp confía en ti para el próximo desafío:  
**Día 3 – “Investigador de Logs: Cazando errores en el sistema”.**

----------

## 💾 **Guardar tu progreso (fuera del contenedor)**

En otra terminal, copia tu proyecto fuera del contenedor:

`docker cp phoenix-lab:/home/user/project ./project_day2_backup`











