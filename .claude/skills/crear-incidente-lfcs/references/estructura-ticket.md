# Estructura exacta del archivo .md de un incidente

## Frontmatter YAML

```yaml
Curso: ...
Modulo: ...
Entorno: ...
Titulo: ...
Fecha de Inicio: ...
Dificultad: "X/10"
Level Escalation: "L1|L2|L3"
Objetivo: ...
Temas: ...
Competencias: ...
Script Vagrant: |
  # Vagrantfile completo, multilínea
tags:
  - LFCS
  - RHCSA
  - Laboratorios-del-LFCS
  - tag-especifico-1
  - tag-especifico-2
```

## Cuerpo del documento

1. Backlink Obsidian: `[[Laboratorios del LFCS]]`
2. Historia en inglés, nivel B2, primera persona, estilo STAR (Situation, Task, Action, Result)

## Estructura del TICKET (inyectado en node01 como /home/vagrant/TICKET_[ID].txt)

```
════════════════════ ENCABEZADO ═══════════════════
TICKET [ID] │ Severidad │ Ambiente
Título del incidente
Módulo │ Dificultad │ Nivel de Escalación
────────────────────────────────────────────────────
Ubicación de Control / Nodo Servidor / Nodo Cliente / Bóveda
Contraseña del Clúster
────────────────────────────────────────────────────
Historia del incidente (narrativa técnica)
ARQUITECTURA DE ALMACENAMIENTO (o de red/usuarios/etc. según el módulo)
PROCEDIMIENTO REQUERIDO (pasos numerados)
CRITERIOS DE ACEPTACIÓN (con porcentajes)
REGLA DE ORO
════════════════════════════════════════════════════
```

## Script de verificación rápida (/tmp/verify-[id].sh)

- Colores con variables `\e[...m`
- `SSH_OPTS` + `PASS`/`FAIL` counter
- Checks numerados `[N/M]` usando `sshpass`
- Banner de éxito / fallo
- Si pasa TODO → `clear` + muestra el TICKET + "Lab listo para practicar"
- Si falla ALGUNO → muestra el TICKET + banner de error + pausa con `read` (ver script-verificacion.md)
- Hook en `.bashrc` de node01 que ejecuta el verify al login
