---
Curso: Advanced Bash Scripting
Modulo: Parameter - Part Two
Tema: Variables
Fecha: 2026-06-02
Estado: completado
Dificultad: Básico Medio
tags:
  - Advanced-Bash-Scripting
---
[[Advanced Bash Scripting]]

---
Curso: Advanced Bash Scripting
Modulo: Parameter - Part Two
Tema: Variables
Fecha: 2026-06-02
Estado: completado
Dificultad: Básico Medio
tags:
  - Advanced-Bash-Scripting
---

[[Advanced Bash Scripting]]


Bash permite manipular cadenas directamente con *parameter expansion*, evitando llamar a utilidades externas. Con esto puedes eliminar prefijos, quitar sufijos, extraer partes de una ruta o modificar texto dentro del propio shell.

La idea principal es que los patrones en Bash trabajan con comodines, especialmente `*`, que representa una secuencia de caracteres. Esto hace que el shell sea muy útil para automatización, porque puedes transformar datos de forma rápida y determinista.

Para prefijos y sufijos existen variantes que eliminan la coincidencia más corta o más larga. `#` y `##` sirven para prefijos, mientras que `%` y `%%` sirven para sufijos; además, Bash permite sustitución de texto y validación básica con patrones.

## Comandos

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

