---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: "Lab: Manage Software, Repositories & Install Software from Source"
Fecha de Inicio: 2026-04-29
Dificultad: Intermedio-Medio
Tareas Totales: "7"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito  |
| :--------- | :----- | :----- |
| `29/05/26` | 20 min | 0 %    |
| `16/05/26` | 20 min | 14 %   |
| `26/05/26` | 20 min | 28 %   |
| `31/05/26` | 20 min | 71.42% |
|            |        |        |
[[Laboratorios del LFCS]]

---

Throughout this technical assessment, I deepened my understanding of how Linux systems manage software dependencies and maintain package integrity—concepts that go far beyond memorizing commands. I learned that `apt update` refreshes the package metadata without touching installed software, while `apt upgrade` applies those updates to existing packages. This distinction is critical because in production environments, understanding when to refresh metadata versus when to actually upgrade prevents unplanned system failures and ensures controlled change management. When installing Apache, I recognized that searching for packages with specific keywords reveals not just the tool itself, but the entire ecosystem of dependencies that will be pulled into my system, which requires careful consideration in a live environment.

What struck me most was the investigative nature of package management beyond installation. By using `dpkg` to identify which package owns the `/bin/ls` binary and then querying the entire `coreutils` package manifest, I grasped a fundamental principle: every file on a Linux system belongs to someone—a package—and understanding this ownership chain is essential for troubleshooting, security audits, and dependency resolution. Uninstalling `ziptool` cleanly, with attention to orphaned dependencies, taught me that removing software isn't just about deletion; it's about maintaining system hygiene and preventing bloat that could compromise performance or security in production systems.

The final challenge—configuring additional repositories from Ubuntu Focal and compiling `tmux` from source—revealed why modern infrastructure engineers must respect the tension between convenience and control. By adding legacy repositories, I acknowledged that real-world systems often inherit complex dependency chains from different release cycles. Building from source demonstrated that I understand the compilation workflow: `configure` inspects the environment, `make` builds the binaries, and `sudo make install` places them systemwide. This experience reinforced that a sysadmin must see beyond package managers—I need to understand what happens at the system level when software is integrated, how dependencies interact, and why careful planning prevents cascading failures in production.

---

### 💻 Ejemplos de Comandos


```bash
# Q1: Explicación conceptual de la diferencia entre comandos de actualización de paquetes:
# apt update   -> Descarga la lista actualizada de paquetes desde los repositorios (actualiza los índices/metadatos localmente). No instala nada.
# apt upgrade  -> Compara los paquetes instalados con la lista local actualizada y descarga/instala las versiones más recientes de los programas.

# Q2: Busca e instala el servidor web Apache utilizando el nombre exacto del paquete obtenido de los metadatos.
sudo apt install --yes apache2

# Q3: Busca a qué paquete pertenece el binario "/bin/ls" mediante dpkg y guarda únicamente el nombre del paquete encontrado en la ruta de bob.
sudo dpkg --search /bin/ls | cut --delimiter=":" --fields=1 > /home/bob/package.txt

# Q4: Lista los archivos de coreutils, filtra los que están estrictamente en /bin que empiecen con "u", e identifica su ruta absoluta exacta.
sudo dpkg --listfiles coreutils | grep --extended-regexp "^/bin/u[^/]*$" > /home/bob/name.txt

# Q5: Remueve el paquete ziptool e inmediatamente elimina de forma automática todas sus dependencias huérfanas que ya no se necesiten.
sudo apt remove --yes ziptool && sudo apt autoremove --yes

# Q6: Agrega el repositorio de Ubuntu 20.04 (Focal) al final de las fuentes del sistema y actualiza el caché de APT de manera inmediata.
echo "deb http://us.archive.ubuntu.com/ubuntu/ focal main" | sudo tee --append /etc/apt/sources.list && sudo apt update

# Q7: Proceso estándar de compilación e instalación desde el código fuente de tmux.
# Nota: Primero se genera el script de configuración con autogen, luego se valida el entorno, se compila y se instala en el sistema.
sudo ./autogen.sh && sudo ./configure && sudo make && sudo make install
```