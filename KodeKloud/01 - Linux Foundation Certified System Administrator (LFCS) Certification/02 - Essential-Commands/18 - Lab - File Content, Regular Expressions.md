---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - File Content, Regular Expressions
Fecha: 2026-05-11
Dificultad: Intermedio-Medio
Tareas Totales: "17"
tags:
  - Linux
  - Linux/LFCS-Certification
  - Linux/LFCS-Certification/Essential-Commands
  - Linux/LFCS-Certification/Essential-Commands/Laboratorio
---
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 11 - 05 - 2026 | 30 min | 77 %  |               |
| 14 - 05 - 2026 | 35 min | 82 %  |               |

---


## Resumen

Este laboratorio se enfoca en manipulación avanzada de contenido de archivos usando expresiones regulares y herramientas de procesamiento de texto en Linux. A través de 17 preguntas, se práctica el uso de `grep` para búsquedas con patrones regex, `sed` para reemplazos de texto en rangos específicos y globales con sensibilidad a mayúsculas, y `awk` para extracción de campos específicos. También se cubren tareas de comparación de archivos con `diff` ignorando casos, eliminación de líneas específicas, edición de archivos con editores de línea, y búsqueda de patrones numéricos complejos usando expresiones regulares.

Las tareas requieren entender la diferencia entre coincidencias exactas y patrones regex, aplicar modificaciones solo en rangos de líneas específicas, y combinar múltiples herramientas para resolver problemas complejos de manipulación de texto. Esta es una habilidad crítica para un Sysadmin Linux que necesita automatizar tareas y procesar logs y archivos de configuración de forma eficiente.

## Comandos Clave

```bash
# Grep con regex - búsqueda exacta
grep -w "man" /home/bob/testfile > /home/bob/man_filtered

# Grep case-insensitive y contar líneas
grep -ic "^section" /home/bob/testfile | wc -l > /home/bob/count_lines

# Sed para reemplazo global case-insensitive
sed -i 's/disabled/enabled/gi' /home/bob/values.conf

# Sed para reemplazo en rango de líneas
sed -i '500,2000s/enabled/disabled/g' /home/bob/values.conf

# Sed para reemplazo de caracteres especiales
sed -i 's/#%\$2jh\/\/238720\/\/31223/\$2\/\/23872031223/g' /home/bob/data.txt

# Awk para extraer campos específicos
awk -F';' '{print $2}' /home/bob/testfile

# Grep con regex para números de 5 dígitos
grep -o '[0-9]\{5\}' /home/bob/textfile > /home/bob/number

# Diff case-insensitive
diff -i /home/bob/file1 /home/bob/file2

# Tail para últimas líneas
tail -n 500 /home/bob/textfile > /home/bob/last

# Sed para eliminar primeras líneas
sed -i '1,1000d' /home/bob/testfile
```