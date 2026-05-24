---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Manage LVM
Fecha de Inicio: 2026-05-09
Dificultad: Intermedio-Baja
Tareas del Lab: "12"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 09 - 05 - 2026 | 30 min | 66 %  |               |
| 20 - 05 - 2026 | 45 min | 66 %  |               |

[[Laboratorios del LFCS]]

---

# Laboratorio LVM

LVM es la respuesta a un problema clásico en infraestructura: ¿qué haces cuando un disco se llena y no puedes parar el sistema? Aquí aprendes a separar el hardware físico de la lógica del almacenamiento. Tus discos crudos se convierten en bloques que puedes agrupar, expandir y contraer sin downtime. Es elasticidad de almacenamiento—lo mismo que ves en AWS o Azure, pero en tu VM. El flujo es simple: declaras discos como Physical Volumes, los agrupas en un Volume Group, y de ahí creas Logical Volumes que el sistema usa normalmente. Cuando se llena, agregas otro disco al grupo. Sin perder datos, sin parar nada.

Lo que ves en este lab es exactamente lo que harás como Sysadmin en Accenture: instalar LVM, preparar discos físicos, crear un contenedor de almacenamiento flexible, y después expandirlo cuando lo necesites. También aprenderás que remover capacidad requiere planificación—no puedes quitar un disco si tiene datos. Y destruir volúmenes es permanente. Estos detalles importan. Al redimensionar, usarás XFS como filesystem porque permite crecer en caliente. Es el ciclo completo: crear infraestructura, hacer crecer bajo presión, y finalmente desmantelar lo que ya no sirve.

La razón por la que esto importa para una entrevista es que muestra que entiendes cómo la industria resuelve problemas de almacenamiento a escala. No es solo "instalé LVM"—es que captaste por qué existe, cuándo usarlo, y cuáles son sus límites. Cuando un reclutador te pregunte "¿cómo creces almacenamiento sin parar el servicio?", tienes la respuesta. Y cuando te muestren un datacenter con servidores físicos, ya sabes que bajo el capó probablemente hay LVM (o sus equivalentes en almacenamiento enterprise). Para la certificación, recuerda que es una herramienta fundamental que aparecerá en cualquier examen de Sysadmin serio.

---

## Comandos Clave

```bash
pvcreate /dev/vdd /dev/vde          # Declarar discos como Physical Volumes
vgcreate volume1 /dev/vdd           # Crear Volume Group
vgextend volume1 /dev/vde           # Agregar disco a VG existente
lvcreate -L 0.5G -n smalldata volume1  # Crear Logical Volume
```