---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Lab - Manage System-Wide Environment Profiles
Fecha de Inicio: 2001-04-20
Dificultad: Intermedio-Baja
Tareas Totales: "12"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `20/04/2026` | 20 min | 0 %   |               |
| `17/05/2026` | 35 min | 33 %  |               |
| `28/05/2026` | 40 min | 50 %  |               |
| `03/06/2026` | 30 min | 66 %  |               |

[[Laboratorios del LFCS]]

---


---

During this lab, I realized that managing environment variables is not merely about knowing the correct commands—it's fundamentally about understanding how the Linux shell maintains the _boundary between user context and system state_. When I worked through variables like `$HOME` and `$PATH`, I grasped something critical: every time a user logs in, they inherit an environment that cascades through multiple configuration files, each layer adding or overriding what came before. This isn't a technical detail; it's the architectural principle that allows Linux systems to be simultaneously secure and flexible. I discovered that if you only memorize `echo $VAR`, you've missed the point entirely. The real skill is understanding _why_ a global variable defined in `/etc/profile` will propagate to every user session, and _why_ that matters when you're managing dozens of servers where consistency is non-negotiable.

I completed approximately 50% of the exercises correctly on my first attempt, which is honest feedback that my understanding of the layering mechanics is still solidifying. However, what's important is that my mistakes weren't conceptual gaps—they revealed where my mental model needed refinement. For instance, when I initially struggled with distinguishing between login shells and non-login shells, I wasn't confused about what they are; I was learning to recognize the _consequences_ of this distinction in real environments. This is the difference between a system administrator and someone who types commands. A true sysadmin recognizes that a misconfigured `~/.bashrc` doesn't just break one user's session; it potentially breaks automation scripts, cron jobs, and application deployments that depend on that environment. That's the responsibility you carry when you understand these concepts deeply.

What I learned transcends this single lab. I now understand that environment management is about _preventing cascading failures in production_. When I configure system-wide variables through `/etc/profile.d/` scripts or when I ensure that every new user receives the correct `.bashrc` template, I'm not just following a checklist—I'm implementing a security boundary and an operational standard. In my current role at Accenture NOC, I've seen how configuration drift and inconsistent environments lead to troubleshooting nightmares for the entire organization. This lab reinforced that a sysadmin must think in terms of scale and governance: How do I make these changes idempotent? How do I ensure they survive a system update? How do I audit them later? These aren't questions you ask after learning the commands; they're the framework that should guide your learning from the start.

---
```bash
# Q1: Para imprimir el valor de una variable de entorno se utiliza el comando 'echo' seguido del signo '$'.
# Ejemplo conceptual: echo $VARIABLE

# Q2: La variable de entorno que almacena la ruta del directorio personal del usuario actual es: $HOME

# Q3: El archivo principal utilizado para definir variables de entorno disponibles globalmente para todos los usuarios es: /etc/profile (o archivos dentro de /etc/profile.d/)

# Q4: Vuelca el entorno de variables actual completo del usuario 'bob' utilizando el comando env y redirige la salida al archivo indicado.
env > /home/bob/env

# Q5: Declara e introduce una variable de entorno local para la sesión actual del usuario bob usando export.
export MYVAR=TRUE

# Q6: Extrae el valor específico de la variable GLOBALENV usando echo y almacena dicho resultado de texto en la ruta del home de bob.
echo "$GLOBALENV" > /home/bob/globalenv

# Q7: Copia de forma manual todos los archivos ocultos de configuración del directorio plantilla del sistema (/etc/skel) hacia la carpeta destino de bob.
# Nota: Usamos --recursive para subcarpetas y preservamos atributos.
sudo cp --recursive /etc/skel/. /home/bob/default_data/

# Q8: Añade la variable global de forma persistente para todo el sistema al final del archivo de perfiles globales /etc/profile.
echo "export GLOBALOPTION=ON" | sudo tee --append /etc/etc/profile

# Q9: Crea un script de shell ejecutable dentro de la carpeta profile.d para garantizar que el saludo se imprima en pantalla para cualquier usuario que inicie sesión.
echo "echo Welcome to our server!" | sudo tee /etc/profile.d/welcome.sh

# Q10: Agrega un archivo README directamente en el directorio esqueleto del sistema para que se herede automáticamente en cada nueva cuenta de usuario creada.
sudo touch /etc/skel/README

# Q11: Define la variable global LFCS de forma persistente para todas las sesiones del sistema a través de un script de inicialización automática en profile.d.
echo "export LFCS=\"Welcome to the KodeKloud LFCS Labs!\"" | sudo tee /etc/profile.d/lfcs.sh

# Q12: Modifica la variable de rutas del sistema ($PATH) para el usuario bob añadiendo de forma persistente la nueva ubicación al final de su archivo local .bashrc.
echo "export PATH=\$PATH:\$HOME/.config/bin" >> /home/bob/.bashrc
```
