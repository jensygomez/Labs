# 📄 Labs – Introduction to YAML
> **Plataforma:** KodeKloud | **Estudiante:** Jensy Gomez | **Nivel:** Sysadmin Linux Jr.

---

## 📚 Conceptos Clave

| Concepto | Descripción |
|---|---|
| **Par clave-valor** | Estructura base de YAML: `key: value` |
| **Diccionario** | Conjunto de pares clave-valor bajo una misma entidad |
| **Lista/Array** | Colección de elementos usando `- ` como prefijo |
| **Indentación** | YAML usa espacios (nunca tabs) para definir jerarquía |
| **Strings con espacios** | Se envuelven en comillas simples `'valor con espacios'` |

---

## 🧪 Laboratorios

---

### Tarea 1 – Separador de clave y valor

**Pregunta:** ¿Qué carácter se usa para separar `key` y `value` en YAML?

**Respuesta:** `:` (dos puntos seguidos de un espacio)

```yaml
propiedad: valor
```

---

### Tarea 4 – Agregar un par clave-valor

**Objetivo:** Agregar `property2: value2` al archivo `practice.yaml` que ya contiene `property1: value1`.

| | |
|---|---|
| **Archivo inicial** | **Archivo final** |

```yaml
# Inicial
property1: value1
```

```yaml
# Final
property1: value1
property2: value2
```

**Comando usado:**
```bash
sudo vi /home/bob/playbooks/practice.yaml
```

> ⚠️ **Lección aprendida:** `echo ... | sudo tee archivo` **sobreescribe** el contenido existente. Para agregar sin borrar, usar `tee -a` (append) o editar directamente con `vi`.

---

### Tarea 5 – Construir un diccionario completo

**Objetivo:** El archivo tiene solo `name: apple`. Agregar `color` y `weight`.

```yaml
# Inicial
name: apple
```

```yaml
# Final
name: apple
color: red
weight: 90g
```

**Comando usado:**
```bash
sudo vi /home/bob/playbooks/practice.yaml
```

> ⚠️ **Lección aprendida:** El heredoc `<<'EOF'` con `--` no es sintaxis YAML válida. En YAML, las listas usan `- ` y los diccionarios no usan guiones.

---

### Tarea 10 – Lista de diccionarios con propiedades completas

**Objetivo:** El archivo tiene una lista con `apple`, `orange` y `mango`. Completar `color` y `weight` para `orange` y `mango`.

```yaml
# Inicial
- name: apple
  color: red
  weight: 100g
- name: orange
- name: mango
```

```yaml
# Final
- name: apple
  color: red
  weight: 100g
- name: orange
  color: orange
  weight: 90g
- name: mango
  color: yellow
  weight: 150g
```

> 💡 **Clave:** En una lista de diccionarios, cada elemento empieza con `- ` y sus propiedades se indentan debajo, **sin** guión.

---

### Tarea 11 – Convertir diccionario a array

**Objetivo:** Cambiar el diccionario `employee` a un array `employees`.

```yaml
# Inicial (diccionario)
employee:
  name: john
  gender: male
  age: 24
```

```yaml
# Final (array)
employees:
  - name: john
    gender: male
    age: 24
```

> 💡 **Clave:** Renombrar la llave (`employee` → `employees`) y agregar `- ` antes del primer campo del elemento convierte el diccionario en una lista de un elemento.

---

### Tarea 12 – Agregar segundo empleado al array

**Objetivo:** Agregar a `sarah` debajo de `john` en el array `employees`.

```yaml
# Final
employees:
  - name: john
    gender: male
    age: 24
  - name: sarah
    gender: female
    age: 28
```

> 💡 **Clave:** Cada elemento del array empieza con `- ` al mismo nivel de indentación. Las propiedades del elemento quedan indentadas bajo su `- `.

---

### Tarea 13 – Diccionario anidado + array de objetos

**Objetivo:** Agregar el array `payslips` (con `month` y `amount`) dentro del diccionario `employee`, que ya contiene el diccionario `address`.

```yaml
# Final
employee:
  name: john
  gender: male
  age: 24
  address:
    city: 'edison'
    state: 'new jersey'
    country: 'united states'
  payslips:
    - month: june
      amount: 1400
    - month: july
      amount: 2400
    - month: august
      amount: 3400
```

> 💡 **Clave:** `address` es un **diccionario** (sin guiones). `payslips` es un **array de diccionarios** (con `- ` en cada elemento). Ambos viven al mismo nivel de indentación dentro de `employee`.

---

## 🗺️ Mapa Mental YAML

```
YAML
├── Par clave-valor         →  key: value
├── Diccionario             →  key:
│                                 subkey: value
├── Lista simple            →  - item1
│                              - item2
└── Lista de diccionarios   →  - name: john
                                 age: 24
                               - name: sarah
                                 age: 28
```

---

## ⚡ Comandos Usados en este Lab

| Comando | Descripción |
|---|---|
| `cat archivo.yaml` | Ver contenido del archivo |
| `sudo vi archivo.yaml` | Editar archivo con privilegios |
| `echo "texto" \| sudo tee archivo` | Sobreescribir archivo (⚠️ borra contenido) |
| `echo "texto" \| sudo tee -a archivo` | Agregar al final del archivo (append) |
| `cat > archivo <<'EOF' ... EOF` | Heredoc para escribir bloque de texto |

---

## ✅ Progreso

- [x] Tarea 1 – Separador clave-valor
- [x] Tarea 4 – Agregar par clave-valor
- [x] Tarea 5 – Diccionario simple
- [x] Tarea 10 – Lista de diccionarios
- [x] Tarea 11 – Diccionario → Array
- [x] Tarea 12 – Agregar elemento a array
- [x] Tarea 13 – Estructuras anidadas (dict + array)

**Completado: 7/13 tareas documentadas | 13/13 tareas resueltas** ✅

---

*Repositorio de estudio – Jensy Gomez | Sysadmin Linux Journey 🐧*