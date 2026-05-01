---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Manage Template User Environment
Typo: Video
Fecha: 01/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 3 min
tags:
  - linux
  - lfcs
  - users
  - groups
  - environment-variables
---

Cuando se crea un nuevo usuario en Linux, el sistema copia automáticamente todos los archivos y configuraciones del directorio `/etc/skel` (skeleton) a la estructura del home del nuevo usuario. Este mecanismo es fundamental para garantizar que todos los usuarios nuevos hereden una configuración estándar y consistente desde el primer momento. El directorio skel actúa como una plantilla que permite implementar políticas empresariales de forma automatizada, asegurando que cada usuario tenga acceso a los archivos y configuraciones necesarios sin necesidad de intervención manual.

Aprovechando esta funcionalidad, es posible personalizar el ambiente de todos los usuarios que se creen en el futuro agregando archivos, scripts, variables de entorno y políticas de la empresa directamente en `/etc/skel`. De esta manera, cuando un nuevo usuario inicia sesión, ya tendrá disponibles todos estos recursos configurados. Esto es especialmente útil para mantener estándares de seguridad, acceso a documentación corporativa (como un README con políticas) y configuraciones predeterminadas que todos los usuarios deben tener.

bash

```bash
sudo vim /etc/skel/README
```