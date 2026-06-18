---
Curso: Advanced Bash Scripting
Modulo: Conventions
Tema: Quiz - Conventions
Fecha de Inicio: 2004-05-14
Dificultad: Intermedio
Tareas Totales: "6"
tags:
---
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| 2026-05-14 | 10 min | 67 %  |               |
|            |        |       |               |


# 📝 Resumen del Quiz: Convenciones en Bash

Las convenciones en Bash se centran en mejorar la robustez y la legibilidad del código, especialmente al manejar variables y nombres de funciones. El uso de comillas dobles para expandir variables es fundamental para prevenir la división de palabras (word splitting) y la expansión de globos, asegurando que los valores con espacios se traten como una sola unidad. Asimismo, el uso de llaves `{}` al llamar variables permite una delimitación clara del nombre, evitando ambigüedades cuando el nombre de la variable está adyacente a otros caracteres de texto.

Por otro lado, el quiz evalúa la comprensión de los entornos de ejecución y la nomenclatura estandarizada. Se define el seguimiento de una convención de codificación como la adopción de un conjunto de reglas para mejorar la calidad y uniformidad del software. Esto incluye distinguir entre shells no interactivos, que ejecutan comandos mediante scripts o procesos automatizados, y la elección de nombres de funciones descriptivos y aceptables que faciliten el mantenimiento del script a largo plazo por parte de diferentes desarrolladores.

## 💻 Ejemplos de Comandos en la CLI

A continuación, se presentan ejemplos prácticos que aplican las convenciones mencionadas en el quiz:

### 1. Expansión segura con comillas dobles
Evita errores cuando una variable contiene espacios o caracteres especiales.
```bash
# Mala práctica (puede fallar si la ruta tiene espacios)
rm $archivo_temporal

# Buena práctica (Convención recomendada)
rm "$archivo_temporal"