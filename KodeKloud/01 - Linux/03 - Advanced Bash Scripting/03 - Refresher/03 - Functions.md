---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Functions
Fecha: 2004-05-15
Estado: completado
Type: Video
Dificultad: Básico Bajo
tags:
---
Las funciones en Bash permiten reutilizar bloques de código dentro de un script, mejorando la modularidad y evitando la repetición. A diferencia del flujo imperativo tradicional donde cada comando se ejecuta secuencialmente, las funciones crean abstracciones reutilizables que pueden invocarse múltiples veces durante la ejecución del script. Se pueden definir usando la palabra clave `function` seguida del nombre, y el principal beneficio es la capacidad de usar variables locales dentro del scope de la función, lo que evita conflictos con variables globales.

El video enfatiza cómo las funciones mejoran la legibilidad y mantenibilidad del código, especialmente en scripts más complejos. Además de la sintaxis básica con `function`, se pueden pasar argumentos a las funciones usando posicionales (`$1`, `$2`, etc.) y capturar su salida con sustitución de comandos. Entender este concepto es fundamental para escribir scripts profesionales y reutilizables que sigan buenas prácticas de programación.

**Ejemplo de comando:**

bash

```bash
function saludar() {
    local nombre=$1
    echo "Hola, $nombre"
}

saludar "Admin"
```