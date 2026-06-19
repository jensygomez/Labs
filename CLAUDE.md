# Contexto del proyecto: Vault de entrenamiento LFCS/RHCSA

Este repo es un vault de estudio para la certificación **LFCS** (y eventualmente **RHCSA**),
estructurado como Obsidian. Contiene apuntes teóricos y laboratorios prácticos en formato
"ticket de incidente" (carpetas `Playgrounds/`).

## Quién soy

NOC L1 en Accenture (sin acceso a herramientas típicas de NOC, rol de intermediario
cliente-proveedor). Objetivo: subir a nivel L2/L3 como Sysadmin Linux mediante
certificación LFCS y, si Accenture lo sponsorea, RHCSA.

## Entorno de práctica

- VM Rocky Linux 9.7 para troubleshooting manual.
- Labs "Playground" en KodeKloud + entorno propio Vagrant multi-VM (Rocky Linux 9, libvirt,
  host MX Linux).

## Estructura del vault

```
01 - Linux/
├── 00 - Menu/
└── 01 - Linux Foundation Certified System Administrator (LFCS) Certification/
    ├── 00 - MOCs/
    ├── 01 - Introduction/
    ├── 02 - Essential-Commands/
    ├── 03 - Operations-Deployment/
    ├── 04 - Users-Groups/
    ├── 05 - Networking/
    ├── 06 - Storage/
    ├── 07 - Conclusion/
    ├── 08-Mock-Exams/
    └── Playgrounds/
        ├── 001 - Essential Commands/   (prefijo EC-)
        ├── 002 - Operations Deployment/ (prefijo OD-)
        ├── 003 - Users and Groups/      (prefijo USR-)
        ├── 004 - Networking/            (prefijo NET-)
        ├── 005 - Storage/               (prefijo STG-)
        ├── 006 - Bash Script/           (prefijo BS-)
        └── 007 - Docker/                (prefijo DK-)
```

Cada carpeta de Playground tiene un archivo `Lista de Laboratorios.md` (o variante de nombre)
que indexa los incidentes existentes de ese módulo.

## Convenciones de nombres

- Archivo de incidente: `[PREFIJO]-[NNN] - [Título Corto] - V1.0.md`
- Versionado: `V1.0`, `V2.0` cuando se rehace un incidente.
- IDs de entorno Vagrant: `[PREFIJO]-[NNN]-[SIGLAS]` (ej. `STG-004-XX`).

## Idioma y estilo

- Apuntes y tickets: español.
- Historia narrativa dentro de cada incidente: inglés, nivel B2, primera persona, estilo STAR.


## Cómo trabajar conmigo

- Estilo socrático: preguntas guía antes de dar la solución directa.
- Conectar siempre los conceptos al dominio correspondiente del examen LFCS.
- Preferir flags largos de CLI (`--verbose` en vez de `-v`) para reforzar memorización.
- Cadencia paso a paso, sin saltar pasos intermedios.
- Evaluaciones honestas y directas, no optimistas de más.

## Generación de incidentes nuevos

Para crear un nuevo laboratorio/incidente, usar el skill `crear-incidente-lfcs`
(`.claude/skills/crear-incidente-lfcs/SKILL.md`). No reinventar el formato a mano:
ese skill ya tiene la estructura exacta del ticket, el script de verificación y las
convenciones del entorno Vagrant.
