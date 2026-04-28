# Expresiones Regulares en Linux
## Laboratorio Kodekloud - Resumen de Aprendizaje

**Fecha:** 2026-04-27  
**Tema:** File Content & Regular Expressions  
**Plataforma:** Kodekloud  
**Estado:** 💯 Completado (17/17 ejercicios)

---

## 📚 Mapa Mental: Herramientas para Manipulación de Archivos

```
┌─────────────────────────────────────────────────────┐
│   MANIPULACIÓN DE CONTENIDO EN LINUX                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐  ┌──────────────┐              │
│  │    GREP      │  │     SED      │              │
│  │  Filtrado    │  │ Sustitución  │              │
│  │  Búsqueda    │  │ Edición      │              │
│  └──────────────┘  └──────────────┘              │
│         │                   │                     │
│    ┌────┴───────────────────┴─────┐              │
│    │                              │              │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐        │
│  │   CUT   │  │  DIFF    │  │   TAIL   │        │
│  │ Campos  │  │Comparar  │  │  Últimas │        │
│  │ Columnas│  │ Archivos │  │  líneas  │        │
│  └─────────┘  └──────────┘  └──────────┘        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🔧 Herramientas Clave Aprendidas

### 1. **SED** (Stream EDitor) - La Navaja Suiza
El comando más versátil para manipulación de texto.

#### Sintaxis Básica:
```bash
sed [opciones] 'comando' archivo
sed -i 's/buscar/reemplazar/g' archivo  # In-place editing
```

#### Comandos Principales:
| Comando | Uso | Ejemplo |
|---------|-----|---------|
| `s/` | Sustituir (substitute) | `sed 's/old/new/g'` |
| `d` | Borrar línea (delete) | `sed '10d'` |
| `p` | Imprimir línea | `sed -n '5p'` |
| `y/` | Transformar caracteres | `sed 'y/abc/xyz/'` |

#### Flags Importantes:
- **`g`** = Global (todas las ocurrencias en la línea)
- **`i`** = Case-insensitive (ignora mayúsculas/minúsculas)
- **`-i`** = In-place (modifica el archivo directamente)
- **Rangos de líneas:** `sed '500,2000s/patron/reemplazo/g'`

---

### 2. **GREP** - Búsqueda y Filtrado
Busca líneas que coinciden con un patrón.

#### Opciones Esenciales:
```bash
grep 'patrón' archivo              # Búsqueda básica
grep -i 'patrón' archivo           # Case-insensitive
grep -w 'palabra' archivo          # Palabra exacta (word boundary)
grep -c 'patrón' archivo           # Contar coincidencias
egrep '^patrón' archivo            # Regex extendida + inicio de línea
```

#### Flags Clave:
| Flag | Descripción |
|------|-------------|
| `-i` | Ignorar caso |
| `-w` | Palabra exacta (boundaries) |
| `-c` | Contar líneas |
| `-l` | Solo nombres de archivo |
| `-n` | Mostrar números de línea |
| `-v` | Invertir (líneas que NO coinciden) |
| `^` | Inicio de línea |
| `$` | Fin de línea |

---

### 3. **CUT** - Extracción de Campos
Extrae columnas específicas de un archivo.

```bash
cut -d ';' -f 2 archivo    # Delimitador ';', campo 2
cut -d ':' -f 1,3 archivo  # Múltiples campos
cut -c 1-5 archivo         # Caracteres específicos
```

---

### 4. **DIFF** - Comparación de Archivos
```bash
diff file1 file2           # Mostrar diferencias
diff -i file1 file2        # Ignorar caso
```

---

### 5. **HEAD / TAIL** - Primeras y Últimas Líneas
```bash
head -5 archivo            # Primeras 5 líneas
tail -500 archivo          # Últimas 500 líneas
tail -f archivo            # Monitoreo en tiempo real
```

---

## 📋 Ejercicios Completados (Lecciones Clave)

### ✅ Ejercicio 1-4: Conceptos Base
- **sed**: Manipular strings
- **head**: Mostrar líneas iniciales
- **grep**: Filtrar patrones
- **diff -i**: Comparar archivos ignorando caso

**Lección:** Estas son las herramientas fundamentales del Sysadmin.

---

### ✅ Ejercicio 5: Extracción con CUT
```bash
# Archivo: a;b;c;d → Extraer campo 2
cut -d ';' -f 2 testfile
# Output: b, y
```

**Lección:** `-d` define delimitador, `-f` especifica el campo.

---

### ✅ Ejercicio 6: Sustitución Global
```bash
sed -i 's/enabled/disabled/g' /home/bob/values.conf
# Resultado: 2079 líneas modificadas
```

**Lección:** La flag `g` reemplaza TODAS las ocurrencias, no solo la primera.

---

### ✅ Ejercicio 7: Sustitución Case-Insensitive ⭐
```bash
sed -i 's/disabled/enabled/gi' /home/bob/values.conf
```

**Lección IMPORTANTE:** 
- Flag `i` en sed = case-insensitive
- `disabled`, `DISABLED`, `Disabled` → todas se reemplazan
- Orden: `s/patron/reemplazo/gi` (flags al final)

---

### ✅ Ejercicio 8: Rangos de Líneas
```bash
sed -i '500,2000s/enabled/disabled/g' /home/bob/values.conf
```

**Lección:** Puedes limitar sed a rangos específicos: `'inicio,finsintaxis'`

---

### ✅ Ejercicio 9: Caracteres Especiales (Delimitador Alternativo)
```bash
# Problema: cadena con caracteres especiales
# sed 's/original/nuevo/g' falla con | / #
# Solución: usar | como delimitador

sed -i 's|#%$2jh//238720//31223|$2//23872031223|g' /home/bob/data.txt
```

**Lección CRÍTICA:**
- Cuando tu patrón contiene `/`, usa otro delimitador: `|`, `#`, `@`
- Sintaxis: `sed 's@viejo@nuevo@g'` funciona igual

---

### ⚠️ Ejercicio 10: Movimiento de Líneas en VI/NANO
**Enfoque:** 
1. Abrir archivo con `nano` o `vim`
2. Ir a línea 1049: `:1049`
3. Copiar línea: `dd` (dos veces para asegurar)
4. Ir a línea 5: `:5`
5. Posicionarse: flecha arriba a línea 4
6. Pegar: `p`

**Lección:** Aprende atajos de editor - crucial para troubleshooting rápido.

---

### ❌ Ejercicio 11: Borrado de Primeras Líneas (ERROR)
```bash
# ❌ INCORRECTO:
sed -i '0,1000d' /home/bob/testfile
# Error: sed no acepta línea 0

# ✅ CORRECTO:
sed -i '1,1000d' /home/bob/testfile
```

**Lección:** SED cuenta desde línea 1, no desde 0. Los rangos son inclusive: `1,1000` = líneas 1 a 1000.

---

### ✅ Ejercicio 12: DIFF para Encontrar Diferencia Única
```bash
diff file1 file2
# Output: 18d17 < # for setting history length...

echo $(diff file1 file2) > file3
```

**Lección:** 
- `diff` muestra exactamente qué línea difiere
- Formato: `18d17` = línea 18 en file1 debe borrarse para igualar file2 en línea 17
- `<` = existe en file1, `>` = existe en file2

---

### ❌ Ejercicio 13: Expresión Regular para 5 Dígitos (ERROR)
```bash
# ❌ INCORRECTO:
sed '[0,9]{5}' textfile
# Error: sed no interpreta regex así

# ✅ CORRECTO (usando grep/egrep):
grep -oE '[0-9]{5}' textfile > /home/bob/number

# O con sed (más complejo):
sed -n 's/.*\([0-9]\{5\}\).*/\1/p' textfile > /home/bob/number
```

**Lección IMPORTANTE:**
- SED no usa `[0,9]` - es `[0-9]`
- SED requiere escapes: `\{5\}` en vez de `{5}`
- GREP extendido es más simple: `[0-9]{5}`
- `-o` = only matching (solo la coincidencia)
- `-E` = regex extendida

---

### ✅ Ejercicio 14: Contar Líneas que Comienzan con Patrón
```bash
egrep '^2' textfile | wc -l > /home/bob/count
```

**Lección:**
- `^` = ancla de inicio de línea
- Combinado con pipe `|` y `wc -l` = contar líneas
- `egrep` = grep con expresiones regulares extendidas

---

### ✅ Ejercicio 15: Búsqueda Case-Insensitive + Conteo
```bash
egrep -i '^SECTION' testfile | wc -l > count_lines
# Resultado: 17 líneas
```

**Lección:**
- `-i` funciona tanto en `grep` como en `egrep`
- Siempre usa anchores (`^`, `$`) para precisión

---

### ✅ Ejercicio 16: Palabra Exacta (Word Boundary)
```bash
# Problema: "man" en "manpath" también coincide
# Solución: grep -w

grep -w 'man' testfile > man_filtered
```

**Lección CRÍTICA:**
- `-w` = word boundary (solo palabras completas)
- **Sin `-w`:** "man" coincide en "manual", "manpath", "man"
- **Con `-w`:** solo coincide líneas donde "man" es una palabra independiente

---

### ✅ Ejercicio 17: Últimas N Líneas
```bash
tail -500 textfile > last
wc -l last  # Verificación: 500 last
```

**Lección:** `tail -n` extrae las últimas n líneas. Útil para logs grandes.

---

## 🎯 Patrones de Expresiones Regulares Resumidos

| Patrón | Significado | Ejemplo |
|--------|-------------|---------|
| `^` | Inicio de línea | `^Error` → líneas que empiezan con Error |
| `$` | Fin de línea | `\.log$` → archivos .log |
| `.` | Cualquier carácter | `a.c` → abc, adc, aXc |
| `*` | 0 o más repeticiones | `a*b` → b, ab, aab, aaab |
| `+` | 1 o más repeticiones | `a+` → a, aa, aaa |
| `?` | 0 o 1 repetición | `colou?r` → color, colour |
| `[abc]` | Cualquiera de a, b, c | `[0-9]` → cualquier dígito |
| `[^abc]` | Cualquiera EXCEPTO a, b, c | `[^0-9]` → no dígito |
| `{n}` | Exactamente n | `[0-9]{5}` → exactamente 5 dígitos |
| `{n,m}` | Entre n y m | `[0-9]{2,4}` → 2 a 4 dígitos |
| `\b` o `-w` | Límite de palabra | `grep -w "man"` |
| `()` | Grupo (captura) | `(abc)+` → abc, abcabc |
| `\|` | OR (alternancia) | `cat\|dog` → cat o dog |

---

## 💡 Troubleshooting: Errores Comunes

### Error: "sed: -e expression #1, char 7: invalid usage of line address 0"
```bash
# ❌ sed no acepta línea 0
sed '0,1000d' file

# ✅ Usa línea 1
sed '1,1000d' file
```

### Error: Caracteres especiales rompen sed
```bash
# ❌ Delimitador / choca con path
sed 's/usr/local/new/g' file

# ✅ Usa delimitador diferente
sed 's|usr/local|new|g' file
```

### Error: Regex compleja en sed
```bash
# ❌ grep y egrep entienden mejor regex
grep '[0-9]{5}' file  # ✅ Usa egrep o grep -E

# ❌ sed requiere escapes
sed -n 's/\([0-9]\{5\}\)/\1/p' file
```

### Error: grep coincide en palabras parciales
```bash
# ❌ "man" coincide en "manpath"
grep 'man' file

# ✅ Usa -w para palabra exacta
grep -w 'man' file
```

---

## 📊 Referencia Rápida: Comandos por Tarea

### Reemplazar texto
```bash
sed -i 's/viejo/nuevo/g' archivo              # Case-sensitive
sed -i 's/viejo/nuevo/gi' archivo             # Case-insensitive
sed -i '10,20s/viejo/nuevo/g' archivo         # Rango específico
```

### Buscar y contar
```bash
grep 'patrón' archivo                         # Buscar
grep -c 'patrón' archivo                      # Contar
grep -w 'palabra' archivo                     # Palabra exacta
egrep '^patrón' archivo | wc -l              # Contar líneas que inician
```

### Extraer datos
```bash
cut -d ':' -f 1,3 /etc/passwd                 # Campos específicos
tail -100 logfile > ultimas_lineas            # Últimas líneas
head -50 archivo                              # Primeras líneas
```

### Comparar
```bash
diff file1 file2                              # Diferencias
diff -i file1 file2                           # Ignorar caso
```

---

## 🚀 Próximos Pasos para tu Formación en Sysadmin

1. **Regex avanzadas:** Lookahead, lookbehind, grupos no-capturantes
2. **AWK:** Para transformaciones más complejas
3. **Perl one-liners:** Para scripts inline potentes
4. **Logs parsing:** Aplicar estos comandos en `/var/log/`
5. **Automatización:** Scripts bash combinando grep, sed, awk
6. **Performance:** `sed` vs `perl` vs `python` para archivos grandes

---

## 📌 Notas Personales para tu Cerebro Digital

### Mnemónicos:
- **SED = Substitute Edit Delete** → Herramienta de sustitución
- **GREP = Get REgular exPression** → Buscar patrones
- **CUT = columnas, no filas** → Recuerda el delimitador `-d`

### Anotaciones Clave:
- ⭐ **Case-insensitive:** Siempre usa `-i` en grep o `i` flag en sed
- ⭐ **Word boundaries:** `-w` es tu amigo para búsquedas precisas
- ⭐ **Caracteres especiales:** Cambia el delimitador en sed
- ⭐ **Línea 0 no existe:** sed y awk cuentan desde 1

---

## 📚 Material de Referencia

- **Plataforma:** Kodekloud
- **Dificultad:** Intermedia ✓ Completado
- **Temas Relacionados:** [[Manipulación de Archivos Linux]], [[AWK y SED Avanzado]], [[Bash Scripting]]
- **Siguientes Labs:** File Permissions, Process Management, Network Services

---

**Última Actualización:** 2026-04-27  
**Estado:** Listo para integrar en tu Vault de Obsidian
