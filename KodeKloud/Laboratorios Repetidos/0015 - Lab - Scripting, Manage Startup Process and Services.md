# Resumen: Scripting y Systemd
## Laboratorio KodeKloud - Gestión de Servicios y Automatización

**Fecha:** 2026-04-27  
**Tema:** Automatización, Systemd y Permisos  
**Plataforma:** KodeKloud  
**Estado:** 🛠️ Finalizado

---

## 📚 Mapa Mental: Administración de Servicios en Linux

```
┌─────────────────────────────────────────────────────┐
│   ADMINISTRACIÓN DE SISTEMAS LINUX                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐  ┌──────────────┐              │
│  │  BASH SCRIPT │  │   SYSTEMD    │              │
│  │ Automatización│  │  Servicios   │              │
│  └──────────────┘  └──────────────┘              │
│         │                   │                     │
│    ┌────┴───────────────────┴─────┐              │
│    │                              │              │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐        │
│  │ PERMISOS│  │ PROCESOS │  │ TARGETS  │        │
│  │ chmod   │  │ PID / status│ Runlevels│        │
│  └─────────┘  └──────────┘  └──────────┘        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🔧 Herramientas y Conceptos Clave

### 1. **Systemd** - El Corazón de los Servicios
Control centralizado para el arranque y mantenimiento de servicios.

#### Comandos Esenciales:
| Comando | Función |
|---------|---------|
| `systemctl status` | Verificar estado, PID y logs |
| `systemctl is-enabled`| Verificar si arranca automáticamente |
| `systemctl mask` | Bloqueo total (impide arranque) |
| `systemctl unmask` | Desbloquear servicio |

#### Configuración de Unit Files (`/etc/systemd/system/`):
- **Restart Policy:** `Restart=always` asegura la resiliencia del proceso.
- **Dependencias:** `After=sshd.service` garantiza orden de ejecución.
- **Acciones:** `ExecStop=` permite definir comandos personalizados de apagado.

### 2. **Bash Scripting** - Automatización
Flujo de trabajo para scripts ejecutables.

- **Shebang:** Siempre incluir `#!/bin/bash` al inicio.
- **Permisos:** Obligatorio usar `chmod +x` antes de la ejecución.
- **Ejecución:** Usar `./script.sh` desde el directorio local.

---

## 📋 Puntos Clave Aprendidos

### ✅ Gestión de Energía
```bash
sudo shutdown -h +120    # Apagado programado en 2 horas
sudo shutdown -c         # Cancelar apagado pendiente
```

### ✅ Archivos y Compresión
```bash
# Error común: No especificar múltiples opciones en tar
tar -xvc ...             # ¡Cuidado con la sintaxis de banderas!
```

### ✅ Depuración (Troubleshooting)
- **PID:** `sudo systemctl status sshd.service | grep -i "main PID"`
- **Redirección:** `> pid` para capturar salidas de comandos en archivos.

---

## ⚠️ Lecciones y Errores (Troubleshooting)

### ❌ Error: Uso de comandos inexistentes
Intentar `sudo systemctl is-enable` en lugar de `is-enabled`.
- **Lección:** Verificar siempre la sintaxis exacta con `man systemctl` ante comandos que devuelven "Unknown command verb".

### ❌ Error: Permisos mal configurados
Configurar permisos restrictivos mediante scripts:
- **Enfoque:** `chmod` específico para el dueño, eliminando acceso a grupos y otros si la política lo requiere.

### ⚠️ Lección de Alta Disponibilidad
La configuración de `kkloud.service` demostró que una unidad debe ser capaz de:
1. Reiniciarse sola ante fallos (`Restart=always`).
2. Tener comandos de parada explícitos (`ExecStop`).
3. Respetar el orden de carga del sistema (`After`).

---

## 📌 Notas para tu Cerebro Digital

### Mnemónicos:
- **Systemd** = El gestor de todo; si está en `dead` o `inactive`, el servicio no vive.
- **Mask** = "Poner una máscara", el servicio se vuelve invisible y no ejecutable.

### Anotaciones Clave:
- ⭐ **Systemctl:** Es tu herramienta principal de diagnóstico. Usa `status` para ver qué está pasando "bajo el capó".
- ⭐ **Rutas:** Los archivos `.service` son críticos; cualquier error de sintaxis ahí deja el servicio inútil.

---

## 📚 Material de Referencia

- **Temas Relacionados:** [[Bash Scripting]], [[Gestión de Procesos]], [[Systemd Avanzado]]
- **Siguientes pasos:** Explorar `journalctl` para logs detallados de servicios.

---

**Última Actualización:** 2026-04-27  
**Estado:** Integrado en el Vault.