# 🐧 Linux Lab: File Content & Regular Expressions (17 Tareas)
**Evidencia de Laboratorio - Manipulación de Datos y Filtrado Avanzado**

Este documento resume las competencias técnicas adquiridas durante el laboratorio de manipulación de flujos de texto, edición no interactiva con `sed`, comparativa de archivos y el uso de expresiones regulares (RegEx) para la extracción de datos en entornos Linux.

---

## 📄 Página 1: Edición y Transformación de Archivos
*Enfoque: Modificación de configuraciones y limpieza de archivos a gran escala.*

| Tarea / Concepto Condensado | Ejecución en CLI / Editor |
| :--- | :--- |
| **01-08. Sustitución en Rangos**<br>Cambiar valores `enabled` a `disabled` restringiendo el comando únicamente entre las líneas 500 y 2000. | `sed -i '500,2000s/enabled/disabled/g' values.conf` |
| **09. Delimitadores Alternativos**<br>Reemplazo de cadenas complejas con múltiples barras diagonales (`/`) cambiando el delimitador de `sed` a `|` para evitar errores de sintaxis. | `sed -i 's|#%$2jh//238720//31223|$2//23872031223|g' data.txt` |
| **10. Movimiento de Líneas en VI**<br>Reubicación quirúrgica de la línea 1049 a la posición 5 usando comandos de modo normal en el editor `vi`. | `vi testfile`<br>1. `:1049` (Ir a línea)<br>2. `dd` (Cortar)<br>3. `:5` (Ir a línea 5)<br>4. `P` (Pegar arriba) |
| **11. Borrado Masivo**<br>Eliminación de las primeras 1000 líneas de un archivo de forma eficiente mediante multiplicadores de comando. | En CLI: `sed -i '1,1000d' testfile`<br>En VI: `1000dd` |

---

## 📄 Página 2: Comparación y Extracción con RegEx
*Enfoque: Identificación de diferencias y búsqueda de patrones específicos.*

| Tarea / Concepto Condensado | Ejecución en CLI |
| :--- | :--- |
| **12. Diferencial de Archivos**<br>Identificar líneas únicas entre dos archivos 99% idénticos para su extracción a un tercer archivo. | `diff file1 file2`<br>`vi file3` (Pegar contenido identificado) |
| **13. Extracción de Patrones (Dígitos)**<br>Localizar y guardar un número de exactamente 5 dígitos usando límites de palabra (`\b`) para evitar falsos positivos. | `grep -oE '\b[0-9]{5}\b' textfile > number` |
| **14. Conteo de Inicio de Palabra**<br>Contar cuántas ocurrencias de números o palabras comienzan específicamente con el dígito `2`. | `grep -oE "\b2[0-9]*\b" textfile \| wc -l > count` |
| **15. Case-Insensitive Matching**<br>Contar líneas que inician con el patrón "Section" ignorando la diferencia entre mayúsculas y minúsculas. | `grep -ci "^Section" testfile > count_lines` |
| **16. Exact Match Only**<br>Filtrar la palabra exacta `man` asegurando que no se incluyan términos como `manpath` o `manual`. | `grep -w "man" testfile > man_filtered` |
| **17. Captura de Final de Archivo**<br>Uso de herramientas de flujo para extraer las últimas 500 líneas de un archivo extenso de forma instantánea. | `tail -n 500 textfile > last` |

---

## 💡 Notas de Implementación (Tips de SysAdmin)

1.  **Flexibilidad del Delimitador**: En `sed`, no existe la obligación de usar `/`. Utilizar caracteres como `|`, `@` o `_` mejora drásticamente la legibilidad cuando se manipulan rutas de archivos, URLs o strings con caracteres especiales.
2.  **Grep -o (Only Matching)**: Esta bandera es fundamental para la automatización. Permite extraer únicamente el dato que cumple el patrón (como una IP o un ID) en lugar de toda la línea, facilitando la integración con otros scripts.
3.  **Límites de Palabra (`\b` o `-w`)**: Se identificó como una práctica esencial para evitar errores en reportes, asegurando que la búsqueda coincida con la palabra completa y no con fragmentos dentro de otras palabras.
4.  **Optimización en Archivos Grandes**: Para tareas de administración en el **NOC**, se prioriza el uso de `tail` y `sed` sobre editores de texto interactivos para evitar el consumo excesivo de memoria RAM al abrir archivos de logs de gran tamaño.

---
*Documentación generada para el seguimiento del roadmap de System Administrator & DevOps.*