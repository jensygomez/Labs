Perfecto, te la dejo limpia y sin errores de formato para que puedas copiarla sin problemas 👇

---

## 📄 Diagnose and Manage Processes.md

````markdown
# Diagnose and Manage Processes

#lfcs #linux #operations #processes #troubleshooting

## 📌 Concepto
Un proceso es una instancia en ejecución de un programa. La gestión de procesos permite monitorear, controlar y optimizar el uso de recursos del sistema.

---

## 🛠️ Comandos principales

- ps → listar procesos
- top → monitoreo en tiempo real
- htop → versión mejorada de top
- kill → terminar procesos por PID
- pkill → terminar procesos por nombre
- nice → iniciar proceso con prioridad
- renice → cambiar prioridad de un proceso

---

## 📊 Visualización de procesos

```bash
ps aux
top
````

Campos importantes:

- PID → Process ID
    
- USER → usuario
    
- %CPU → uso de CPU
    
- %MEM → uso de memoria
    

---

## ❌ Terminar procesos

```bash
kill <PID>
kill -9 <PID>
pkill <nombre>
```

⚠️ `kill -9` fuerza la terminación inmediata (usar solo si es necesario)

---

## ⚙️ Prioridad de procesos

```bash
nice -n 10 comando
renice 5 -p <PID>
```

- Valores bajos (-20) → mayor prioridad
    
- Valores altos (19) → menor prioridad
    

---

## 🔍 Troubleshooting

- Identificar procesos con alto consumo de CPU/memoria
    
- Detectar procesos colgados
    
- Liberar recursos terminando procesos innecesarios
    

---

## 🔗 Relacionado

- [[Linux Basics]]
    
- [[System Monitoring]]
    
- [[CPU and Memory]]
    
- [[Process Lifecycle]]
    

---

## 🧪 Notas personales

### ❗ Errores comunes

### 💡 Aprendizajes
