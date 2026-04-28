# Lab: Archive, Backup, Compress, IO Redirection
**Sistema:** Ubuntu | **Objetivo:** Dominar herramientas de compresión, archivado y redirección de entrada/salida en Linux

---
#lab #linux 
## 📋 Introducción

Este laboratorio cubre las operaciones fundamentales de un Sysadmin Linux: crear backups, comprimir archivos, y gestionar flujos de entrada/salida (I/O). Habilidades críticas para troubleshooting, mantenimiento de sistemas y automatización.

---

## 1️⃣ Crear archivo tar sin compresión

**Objetivo:** Crear un archivo tar de `/var/log/` en el home de bob

**Comando correcto:**
```bash
sudo tar --create -f /home/bob/logs.tar /var/log
```

**Explicación:**
- `--create` (o `-c`): Crear archivo
- `-f`: Especificar nombre del archivo (obligatorio)
- Sin `-f`, tar intenta escribir a stdout (terminal)

**⚠️ Errores comunes:**
```bash
# ❌ FALLA: Falta -f
sudo tar --create logs.tar /var/log
# Error: "Refusing to write archive contents to terminal"

# ✅ FUNCIONA: Con -f
sudo tar -cf /home/bob/logs.tar /var/log
```

---

## 2️⃣ Crear archivo tar comprimido (.tar.gz)

**Objetivo:** Comprimir `/var/log/` a `logs.tar.gz`

**Comando:**
```bash
sudo tar -czf /home/bob/logs.tar.gz /var/log
```

**Explicación:**
- `-c`: Create (crear)
- `-z`: Gzip compression (comprimir con gzip)
- `-f`: File (especificar archivo)
- `-p`: Preserve permissions (preservar permisos)

**Resultado:**
```
logs.tar        (sin comprimir) ~40 KB
logs.tar.gz     (comprimido)    ~580 KB
```

**Tip:** El orden de flags importa. `tar czf` es más legible que `tar -c -z -f`

---

## 3️⃣ Listar contenido de archivo tar

**Objetivo:** Listar contenido de `logs.tar` y guardar en archivo

**Comando:**
```bash
sudo tar -tf /home/bob/logs.tar > /home/bob/tar_data.txt
```

**Explicación:**
- `-t`: List archive contents (listar contenido)
- `-f`: Especificar archivo
- `>`: Redireccionar stdout a archivo

**Alternativa con less:**
```bash
tar -tf /home/bob/logs.tar | less
```

---

## 4️⃣ Extraer archivo comprimido a directorio específico

**Objetivo:** Extraer `archive.tar.gz` a `/tmp`

**Comando correcto:**
```bash
tar -xf /home/bob/archive.tar.gz --directory /tmp
```

**Explicación:**
- `-x`: Extract (extraer)
- `-f`: Especificar archivo
- `--directory /tmp`: Extraer en `/tmp` en lugar del directorio actual

**❌ Falla común:**
```bash
tar -xf /home/bob/archive.tar.gz /tmp
# Error: "/tmp: Not found in archive"
# (/tmp no es un archivo dentro del tar)
```

---

## 5️⃣ Redireccionar solo stdout (normal output)

**Objetivo:** Ejecutar script y guardar solo output normal (sin errores)

**Comando:**
```bash
bash ~/script.sh > /home/bob/output_stdout.txt
```

O explícitamente con descriptor de archivo:
```bash
bash ~/script.sh 1> /home/bob/output_stdout.txt
```

**Explicación de I/O Redirection:**
| Descriptor | Nombre | Símbolo | Acción |
|---|---|---|---|
| 0 | stdin | `<` | Entrada estándar |
| 1 | stdout | `>` (sobrescribe) / `>>` (append) | Salida normal |
| 2 | stderr | `2>` | Errores/Warnings |

**Variantes:**
```bash
# Guardar output, descartar errores
bash ~/script.sh 1> output.txt 2>/dev/null

# Guardar solo en archivo (sin verlo en terminal)
bash ~/script.sh > output.txt
```

---

## 6️⃣ Redireccionar stdout y stderr juntos

**Objetivo:** Guardar TODO (output + errores) en un archivo

**Comando:**
```bash
bash ~/script.sh > /home/bob/output.txt 2>&1
```

**Explicación:**
- `>` (o `1>`): Redirige stdout a archivo
- `2>&1`: Redirige stderr (2) al mismo destino que stdout (1)

**Alternativa moderna (bash 4.0+):**
```bash
bash ~/script.sh &> /home/bob/output.txt
```

**Flujo de datos:**
```
script.sh
  ├─ stdout (1) ──┐
  │               ├──> output.txt
  └─ stderr (2) ──┘
```

---

## 7️⃣ Redireccionar solo stderr

**Objetivo:** Guardar solo errores/warnings

**Comando:**
```bash
bash ~/script.sh 2> /home/bob/output_errors.txt
```

**Resultado:**
```bash
$ bash ~/script.sh 2> output_errors.txt
/home/bob  # ← Esto aparece en terminal (stdout)

$ cat output_errors.txt
/home/bob/script.sh: line 2: lss: command not found  # ← Error capturado
```

**Casos de uso:**
- Capturar solo mensajes de error para debugging
- Mantener output normal en terminal, guardar errores

---

## 8️⃣ Comprimir archivo preservando original

**Objetivo:** Crear `file.txt.bz2` manteniendo `file.txt`

**Comando:**
```bash
bzip2 --keep /home/bob/file.txt
```

**Explicación:**
- `bzip2`: Compresor (generalmente mejor compresión que gzip)
- `--keep`: Preservar archivo original
- Resultado: `file.txt` + `file.txt.bz2`

**Sin `--keep`:**
```bash
bzip2 /home/bob/file.txt
# Solo queda file.txt.bz2 (original se elimina)
```

---

## 9️⃣ Extraer en directorio con permisos elevados

**Objetivo:** Extraer `archive.tar.gz` a `/opt` (requiere sudo)

**Comando:**
```bash
sudo tar -xf /home/bob/archive.tar.gz --directory /opt
```

**⚠️ Error común (sin sudo):**
```bash
tar xf /home/bob/archive.tar.gz --directory /opt
# Error: "Permission denied"
# /opt es propiedad de root
```

---

## 🔟 Append con cat y redirección

**Objetivo:** Añadir contenido de un archivo a otro

**Comando:**
```bash
cat /home/bob/file.txt >> /home/bob/destination.txt
```

**Explicación:**
- `cat`: Concatenate (mostrar contenido)
- `>>`: Append redirection (añadir al final, no sobrescribir)
- `>` sería sobrescribir

**Comparación:**
```bash
>   # Sobrescribe archivo
>>  # Append (añade al final)
```

---

## 1️⃣1️⃣ Crear tar desde directorio

**Objetivo:** Archiver directorio `/home/bob/file/` a `file.tar`

**Comando correcto:**
```bash
tar -cf /home/bob/file.tar -C /home/bob file/
```

O cambiar directorio primero:
```bash
cd /home/bob
tar -cf file.tar file/
```

**Explicación:**
- `-C` cambia el directorio antes de agregar archivos
- Reduce las rutas almacenadas en el tar
- Resultado: `file/` no `home/bob/file/`

**❌ Error común:**
```bash
sudo tar cf file.tar /home/bob/file/ --directory /home/bob/
# Error: opciones posicionales después de argumentos
# --directory debe ir ANTES del archivo a comprimir
```

---

## 1️⃣2️⃣ Comprimir con gzip

**Objetivo:** Crear `games.txt.gz`

**Comando:**
```bash
gzip games.txt
```

**Resultado:**
- `games.txt` desaparece
- Solo queda `games.txt.gz`

**Si quieres preservar original:**
```bash
gzip -k games.txt
```

---

## 1️⃣3️⃣ Descomprimir archivo .xz

**Objetivo:** Extraer `lfcs.txt.xz`

**Comando:**
```bash
unxz /home/bob/lfcs.txt.xz
```

**Resultado:** `lfcs.txt` descomprimido

**Con preserve:**
```bash
unxz -k /home/bob/lfcs.txt.xz
```

**Formatos comunes:**
| Compresión | Crear | Extraer |
|---|---|---|
| gzip | `gzip file` | `gunzip file.gz` / `gzip -d file.gz` |
| bzip2 | `bzip2 file` | `bunzip2 file.bz2` |
| xz | `xz file` | `unxz file.xz` |
| tar+gzip | `tar -czf file.tar.gz dir/` | `tar -xzf file.tar.gz` |

---

## 1️⃣4️⃣ Sort y eliminar duplicados

**Objetivo:** Ordenar `values.conf` alfabéticamente, eliminar duplicados, guardar en `values.sort`

**Comando:**
```bash
sort -u /home/bob/values.conf > /home/bob/values.sort
```

**Explicación:**
- `sort`: Ordena líneas
- `-u`: Unique (elimina líneas duplicadas)
- `>`: Redirige a archivo

---

## 1️⃣5️⃣ Sort ignorando mayúsculas

**Objetivo:** Ordenar ignorando case sensitivity, eliminar duplicados

**Comando:**
```bash
sort -u -f /home/bob/values.conf > /home/bob/values.sorted
```

O en forma compacta:
```bash
sort -uf /home/bob/values.conf > /home/bob/values.sorted
```

**Explicación:**
- `-u`: Unique (duplicados)
- `-f`: Fold (ignora case)

**Ejemplo:**
```
# values.conf
Apple
apple
Banana
banana

# Resultado
apple      # -u elimina APPLE por ser duplicado (case-insensitive)
banana
```

---

## 📚 Resumen de Comandos Clave

### Tar
```bash
tar -cf archivo.tar directorio/              # Crear
tar -czf archivo.tar.gz directorio/          # Crear + gzip
tar -tf archivo.tar                          # Listar
tar -xf archivo.tar                          # Extraer
tar -xf archivo.tar -C /destino              # Extraer a destino
```

### Compresión
```bash
gzip archivo.txt                             # Crear .gz
gunzip archivo.gz                            # Extraer .gz
bzip2 --keep archivo.txt                     # Crear .bz2 preservando original
unxz archivo.xz                              # Extraer .xz
```

### I/O Redirection
```bash
comando > archivo                            # stdout a archivo (sobrescribe)
comando >> archivo                           # stdout a archivo (append)
comando 2> archivo                           # stderr a archivo
comando > archivo 2>&1                       # stdout y stderr a archivo
comando 2>/dev/null                          # Descartar stderr
```

### Herramientas
```bash
sort archivo                                 # Ordenar líneas
sort -u archivo                              # Ordenar y eliminar duplicados
sort -f archivo                              # Ordenar ignorando case
cat archivo                                  # Mostrar contenido
```

---

## 🎯 Puntos Clave para Recordar

✅ **Siempre usa `-f` con tar** (especifica nombre del archivo)

✅ **Orden de opciones importa** (especialmente en tar con `-C`)

✅ **Usa `sudo`** cuando escribas en directorios protegidos (`/opt`, `/var`, etc.)

✅ **Redirección `2>&1`** es fundamental para logs y debugging

✅ **`>>` no sobrescribe**, `>` sí (atención con scripts de backup)

✅ **Compress antes de transferir** (ahorra bandwidth en troubleshooting remoto)

---

## 🔗 Aplicación Real en NOC Level 1 → Sysadmin

Como estás transitando de NOC a Sysadmin, estas habilidades son **críticas** para:

1. **Crear backups de configuración** antes de cambios
2. **Comprimir logs** para enviar a proveedores (troubleshooting)
3. **Redirigir output** en scripts de monitoreo y alertas
4. **Gestionar archivos remotos** vía SSH (rsync + tar)
5. **Debugging** de problemas en producción

Ejemplo real:
```bash
# Backup de config antes de cambio
tar -czf /home/sysadmin/backup_nginx_$(date +%Y%m%d).tar.gz /etc/nginx/

# Capturar logs de error para proveedor
journalctl -u servicio 2>&1 | head -100 > /tmp/service_errors.log

# Comprimir y transferir
scp /tmp/service_errors.log proveedor@server:/uploads/
```

---

**Documentado para:** GitHub | **Laboratorio:** Linux LFCS Track | **Versión:** 1.0