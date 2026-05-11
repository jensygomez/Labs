---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Manage User Privileges
Typo: Video
Fecha: 02/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 8 min
tags:
  - "#Linux/LFCS-Certification/Users-Groups"
---


## Resumen

En este video se explora cómo otorgar privilegios elevados a usuarios en Linux mediante el comando `sudo`. El método más sencillo es agregar un usuario a un grupo específico, permitiéndole ejecutar comandos con permisos de administrador. Por ejemplo, si queremos que el usuario 'trinity' pueda usar `sudo`, simplemente lo añadimos al grupo sudo. Este enfoque es práctico cuando necesitamos dar acceso administrativo de forma rápida y sin complicaciones adicionales.

Para un control más granular y específico, existe la opción de editar directamente el archivo de configuración de sudoers usando `visudo`. Este método permite definir exactamente qué comandos puede ejecutar cada usuario y bajo qué contexto, brindando mayor seguridad y flexibilidad en la gestión de permisos. De esta manera, podemos limitar los privilegios solo a lo que el usuario realmente necesita, evitando acceso innecesario al sistema.

## Comandos de Ejemplo

```bash
# Agregar usuario al grupo sudo
sudo gpasswd -a trinity sudo

# Editar configuración de sudoers (forma segura)
sudo visudo

# Dentro de visudo, agregar una línea como:
# trinity ALL=(ALL) ALL
```

---

**Notas adicionales:**
- Siempre usa `visudo` para editar sudoers, nunca edites directamente el archivo
- Los cambios en grupos requieren que el usuario inicie sesión nuevamente

