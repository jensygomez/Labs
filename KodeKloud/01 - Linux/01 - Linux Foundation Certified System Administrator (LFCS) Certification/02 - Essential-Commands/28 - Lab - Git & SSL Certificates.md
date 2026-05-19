---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Git & SSL Certificates
Fecha de Inicio: 2026-05-14
Dificultad: Intermedio-Baja
Tareas Totales: "10"
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas                               |
| :--------- | :----- | :---- | :------------------------------------------ |
| 2026-05-14 | 42 min | 10 %  | Problemas iniciales con conceptos de merge. |
|            |        |       |                                             |

---



## 📋 Resumen

Este laboratorio integra dos temas esenciales: **control de versiones con Git** y **gestión de certificados SSL/TLS**. En la primera parte, practicamos operaciones fundamentales de Git como clonar repositorios, crear y cambiar ramas, stagear archivos, hacer commits y fusionar cambios. La segunda parte se enfoca en la generación de claves RSA, Certificate Signing Requests (CSR) e identificar información de certificados existentes. Ambos temas son críticos para cualquier administrador Linux que deba gestionar aplicaciones, deployments y configuraciones de seguridad.

Las tareas abarcan desde conceptos básicos como el clonado de repositorios remotos hasta operaciones más complejas como la resolución de errores durante el merge de ramas y la eliminación condicionada de branches. En cuanto a certificados, se requiere generar claves privadas con diferentes niveles de encriptación, crear CSRs con OpenSSL, y analizar certificados existentes para extraer información como el Common Name. Este laboratorio prepara el camino para certificar competencias en administración de sistemas Linux.

## 🛠️ Comandos de Ejemplo

### Git - Clonar repositorio

```bash
git clone https://github.com/kodekloudhub/git-for-beginners-course.git /home/bob/
cd git-for-beginners-course
```

### Git - Crear y cambiar de rama

```bash
cd /root/kode
git branch testing
git checkout testing
```

### Git - Stagear archivos específicos por extensión

```bash
cd /root/kode
git add *.cpp
git commit -m "Added C++ files"
```

### Git - Mergear ramas

```bash
cd /root/kode
git checkout master
git merge documentation
```

### SSL - Generar RSA + CSR en un comando

```bash
openssl req -new -newkey rsa:4096 -keyout priv.key -out cert.csr -aes256 -passout pass:kkloud
```

### SSL - Generar certificado autofirmado

```bash
openssl req -new -x509 -nodes -out kodekloud.crt -keyout priv.key -days 365 -subj "/CN=kodekloud.com"
```

### SSL - Consultar CN de un certificado

```bash
openssl x509 -in /home/bob/my.crt -text -noout | grep "Subject:"
```



