---
Curso: Advanced Bash Scripting
Modulo: Expansions - Part One
Tema: Variables
Fecha: 2026-06-01
Estado: completado
Dificultad: Básico Medio
tags:
  - Advanced-Bash-Scripting
---
[[Advanced Bash Scripting]]


Parameter expansion at this level is where Bash starts to reveal its real power as a text processing engine. What the module covers — prefix removal with `#`, suffix removal with `%`, substring substitution, and occurrence replacement — are not just convenience features. They are the building blocks of data transformation directly inside the shell, without calling `sed`, `awk`, or `cut`. In a Linux environment where every external process has overhead, knowing when the shell itself can do the work is a decision with real operational weight.

The concept of _pattern_ here is key, and the module frames it correctly: patterns in Bash are not arbitrary — they follow predictable, mathematical models. That predictability is what makes them safe to use in automation. When I write a script that strips a file extension, replaces a path prefix, or validates that a string ends with a specific suffix, I am relying on that determinism. In production, non-deterministic behavior in a script is not a bug you debug once — it is a liability that lives in your infrastructure until someone finds it the hard way.

Data validation through parameter expansion is particularly relevant in a SysAdmin context. Before a script passes a value to a command that runs as root, or writes to a path that other services depend on, validating that the parameter matches the expected pattern is not optional — it is the minimum standard. This module is a reminder that the shell already has the tools for that layer of safety built in, and using them is a matter of discipline, not complexity.

---

**Commands & Concepts Referenced**

```bash
# Eliminar prefijo mas corto (# = shortest match)
echo ${variable#prefix}

# Eliminar prefijo mas largo (## = longest match / greedy)
echo ${variable##*/}        # ejemplo: quitar todo antes del ultimo /

# Eliminar sufijo mas corto (% = shortest match)
echo ${variable%.*}         # ejemplo: quitar extension de archivo

# Eliminar sufijo mas largo (%% = longest match / greedy)
echo ${variable%%.*}

# Sustitucion de primera ocurrencia
echo ${variable/pattern/replacement}

# Sustitucion de todas las ocurrencias
echo ${variable//pattern/replacement}

# Validacion: verificar si variable empieza con un patron
[[ ${variable} == prefix* ]] && echo "valid"
```

---
