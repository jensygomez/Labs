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
| Fecha      | Tiempo | Éxito | Peso |
| :--------- | :----- | :---- | :--- |
| `29/05/26` | 20 min | 0 %   | 0,00 |
| `16/05/26` | 20 min | 14 %  | 0,98 |
| `25/05/26` | 20 min | 28 %  | 1,96 |
|            |        |       |      |
|            |        |       |      |
[[Laboratorios del LFCS]]

---

Throughout this technical assessment, I deepened my understanding of how Linux systems manage software dependencies and maintain package integrity—concepts that go far beyond memorizing commands. I learned that `apt update` refreshes the package metadata without touching installed software, while `apt upgrade` applies those updates to existing packages. This distinction is critical because in production environments, understanding when to refresh metadata versus when to actually upgrade prevents unplanned system failures and ensures controlled change management. When installing Apache, I recognized that searching for packages with specific keywords reveals not just the tool itself, but the entire ecosystem of dependencies that will be pulled into my system, which requires careful consideration in a live environment.

What struck me most was the investigative nature of package management beyond installation. By using `dpkg` to identify which package owns the `/bin/ls` binary and then querying the entire `coreutils` package manifest, I grasped a fundamental principle: every file on a Linux system belongs to someone—a package—and understanding this ownership chain is essential for troubleshooting, security audits, and dependency resolution. Uninstalling `ziptool` cleanly, with attention to orphaned dependencies, taught me that removing software isn't just about deletion; it's about maintaining system hygiene and preventing bloat that could compromise performance or security in production systems.

The final challenge—configuring additional repositories from Ubuntu Focal and compiling `tmux` from source—revealed why modern infrastructure engineers must respect the tension between convenience and control. By adding legacy repositories, I acknowledged that real-world systems often inherit complex dependency chains from different release cycles. Building from source demonstrated that I understand the compilation workflow: `configure` inspects the environment, `make` builds the binaries, and `sudo make install` places them systemwide. This experience reinforced that a sysadmin must see beyond package managers—I need to understand what happens at the system level when software is integrated, how dependencies interact, and why careful planning prevents cascading failures in production.

---

### 💻 Ejemplos de Comandos


```bash
# Actualizar lista de repositorios (sin instalar actualizaciones)
apt update

# Actualizar paquetes ya instalados
apt upgrade

# Buscar paquete con palabras clave
apt search "apache http server"

# Instalar paquete
apt install apache2

# Ver información detallada de un paquete
apt show apache2

# Identificar a qué paquete pertenece un archivo
dpkg -S /bin/ls

# Listar archivos de un paquete
dpkg -L coreutils | grep /bin

# Desinstalar paquete y sus dependencias no usadas
apt remove ziptool
apt autoremove

# Agregar repositorio personalizado
echo "deb http://us.archive.ubuntu.com/ubuntu/ focal main" | sudo tee /etc/apt/sources.list.d/focal.list
apt update

# Compilar e instalar desde fuente
cd tmux
./configure
make
sudo make install
```