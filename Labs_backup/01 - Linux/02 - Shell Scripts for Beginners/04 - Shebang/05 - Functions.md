---
Curso: Shell Scripts for Beginners
Modulo: Shebang
Tema: Exit Codes
Fecha: 2026-05-11
tags:
---
Las funciones en bash permiten reutilizar bloques de código y hacen los scripts más modulares y mantenibles. Una función se define con la palabra clave `function` seguida del nombre y se coloca **antes** de ser llamada en el script. La estructura básica es `function NOMBRE() { CÓDIGO }`. Son especialmente útiles para tareas repetitivas como instalar paquetes, agregar usuarios, realizar validaciones y ejecutar operaciones complejas.

Las funciones pueden recibir parámetros mediante argumentos posicionales ($1, $2, $3, etc.), lo que las hace reutilizables con diferentes valores. Esto permite crear herramientas más flexibles y reduce significativamente la duplicación de código. También pueden retornar valores usando `return` o capturando su salida con `$()`, mejorando el flujo de control en scripts más grandes.

**Ejemplo de comando:**

bash

```bash
#!/bin/bash

function instalar_paquete() {
    sudo apt-get install -y $1
    echo "Paquete $1 instalado correctamente"
}

function agregar_usuario() {
    sudo useradd -m $1
    echo "Usuario $1 creado exitosamente"
}

# Llamando las funciones con argumentos
instalar_paquete "curl"
agregar_usuario "juan"
```