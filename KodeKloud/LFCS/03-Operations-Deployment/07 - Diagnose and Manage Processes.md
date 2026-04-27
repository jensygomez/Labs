# Diagnose and Manage Processes

#lfcs #linux #operations #processes #troubleshooting

## 📌 Concepto
Un proceso es una instancia en ejecución de un programa. La gestión de procesos permite monitorear, controlar y optimizar el uso de recursos del sistema.

---

## 🛠️ Comandos principales

- ps → listar procesos
- top → monitoreo en tiempo real
- htop → versión mejorada
- kill → terminar procesos por PID
- pkill → terminar procesos por nombre
- nice → iniciar proceso con prioridad
- renice → cambiar prioridad

---

## 📊 Visualización de procesos

```bash
ps aux
top
```

Campos importantes:
- PID → Process ID
- USER → usuario
- %CPU → uso CPU
- %MEM → uso memoria

---

## ❌ Terminar procesos

```bash
kill <PID>
kill -9 <PID>
pkill <nombre>
```

⚠️ kill -9 fuerza la terminación (usar con cuidado)

---

## ⚙️ Prioridad de procesos

```bash
nice -n 10 comando
renice 5 -p <PID>
```

- -20 → mayor prioridad  
- 19 → menor prioridad  

---

## 🔍 Troubleshooting

- Identificar procesos con alto consumo
- Detectar procesos colgados
- Liberar recursos

---

## 🧪 Notas personales

### ❗ Errores comunes
- 

### 💡 Aprendizajes
- 
