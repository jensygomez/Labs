# 🧩 **Laboratorio Linux: Creación de Usuarios y Grupos**

## 🎯 **Escenario del Reto**

**¡Bienvenido al equipo, administrador Jensy!**  
El departamento de I+D de **LabEx** ha contratado a dos nuevos empleados. Tu misión como administrador del sistema es configurar sus cuentas y grupos en el servidor principal Linux.

Este ejercicio reproduce una tarea real de administración de usuarios.  
Tendrás que crear **dos nuevos grupos** y **dos nuevos usuarios**, asignando correctamente sus **directorios personales, grupos primarios y secundarios.**

----------

## 🧠 **Objetivos del Laboratorio**

-   Crear grupos llamados `dev` y `test`.
    
-   Crear usuarios `jack` y `bob` con configuraciones específicas.
    
-   Verificar la correcta asociación de grupos y directorios personales.
    

----------

## 🧰 **Preparación del Entorno Docker**

### **Inicia un contenedor Ubuntu para practicar**

`docker run -it --name user-lab ubuntu:22.04 /bin/bash` 

### **Actualiza e instala herramientas básicas**

`apt-get update && apt-get install -y sudo passwd` 

----------

## 🚀 **Fase 1: Crear los grupos**

Crea los dos grupos requeridos:

`sudo groupadd dev
sudo groupadd test` 

Verifica su existencia:

`getent group dev
getent group test` 

----------

## 👨‍💻 **Fase 2: Crear el usuario `jack`**

Crea al usuario **jack** con:

-   Home: `/home/jack`
    
-   Grupo primario: `dev`
    
-   Grupo secundario: `labex` (ya existente en el sistema)
    

`sudo useradd -m -d /home/jack -g dev -G labex jack
sudo passwd jack` 

Si aparece la advertencia:

`useradd: warning: the home directory /home/jack already exists.` 

solo significa que el directorio ya estaba creado; puedes continuar.

Corrige permisos si es necesario:

`sudo chown -R jack:dev /home/jack` 

Verifica la información:

`id jack ls -ld /home/jack` 

✅ **Salida esperada:**

`uid=5001(jack) gid=5003(dev) groups=5003(dev),5000(labex)
drwxr-x--- 2 jack dev 57 Nov 14 01:57 /home/jack` 

----------

## 👨‍💻 **Fase 3: Crear el usuario `bob`**

Crea al usuario **bob** con:

-   Home: `/home/bob`
    
-   Grupo primario: `test`
    
-   Grupo secundario: `labex`
    

Si `bob` **ya existe**, ajústalo con `usermod`.

### Opción A — Crear desde cero:

`sudo useradd -m -d /home/bob -g test -G labex bob
sudo passwd bob` 

### Opción B — Si ya existe:

`sudo usermod -g test bob
sudo usermod -aG labex bob
sudo chown -R bob:test /home/bob` 

Verifica:

`id bob ls -ld /home/bob` 

✅ **Salida esperada:**

`uid=5002(bob) gid=5004(test) groups=5004(test),5000(labex)
drwxr-x--- 2 bob test 57 Nov 14 02:10 /home/bob` 

----------

## 🔎 **Fase 4: Validación Final**

Verifica que todo esté correctamente configurado:

`getent group dev
getent group test  id jack id bob` 

✅ **Criterios de éxito:**

-   Los grupos `dev` y `test` existen.
    
-   `jack` pertenece a `dev` (primario) y `labex` (secundario).
    
-   `bob` pertenece a `test` (primario) y `labex` (secundario).
    
-   Ambos tienen sus directorios personales correctos y accesibles.
    

----------

## 🧪 **(Opcional) Prueba de acceso**

`sudo su - jack pwd  exit sudo su - bob pwd  exit` 

Ambos deben entrar correctamente en sus respectivos `/home`.

----------

## 🧾 **Resumen**

En este laboratorio aprendiste a:

-   Crear grupos y usuarios en Linux.
    
-   Asignar grupos primarios y secundarios.
    
-   Ajustar permisos de directorios personales.
    
-   Verificar configuraciones con `id` y `getent group`.
    

Estas habilidades son esenciales para la **administración de usuarios** y **control de acceso** en entornos Linux corporativos.

----------

## 💡 **Consejos Profesionales**

-   Usa `usermod -aG` para agregar usuarios sin sobrescribir sus grupos actuales.
    
-   Siempre revisa los permisos del home con `ls -ld /home/usuario`.
    
-   En entornos productivos, documenta cada cambio en `/etc/group` y `/etc/passwd`.
    

----------

## 📦 **Guardar tu trabajo (opcional)**

En otra terminal:

`docker cp user-lab:/home /tmp/user-lab-home` 

Así conservarás los archivos de práctica localmente.

----------

**🎯 Dificultad:** Principiante  
**⏰ Tiempo estimado:** 10–15 minutos  
**📁 Archivo de práctica:** `/home/jack` y `/home/bob`  
**📚 Temas cubiertos:** administración de usuarios, grupos y permisos en Linux
