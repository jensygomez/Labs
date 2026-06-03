


## Módulo LFCS

**Operations Deployment**

Tema:

- Scripting
    
- Manage Startup Process and Services
    

---

## Objetivo LFCS

Al finalizar este Playground debo ser capaz de:

- Diagnosticar servicios systemd.
    
- Analizar logs con journalctl.
    
- Corregir errores de permisos.
    
- Validar ejecución bajo usuarios específicos.
    
- Habilitar servicios para iniciar automáticamente.
    
- Realizar troubleshooting básico de aplicaciones.
    

---

## Historia

Empresa:

**Globex Corporation**

Ticket:

```text
INC-1001

El equipo de desarrollo ha entregado una nueva aplicación interna llamada "webcheck".

La aplicación debe ejecutarse como servicio del sistema.

Actualmente los usuarios reportan que el servicio no está disponible.

Investigue el problema y deje el servicio funcionando correctamente.

Requisitos:

- El servicio debe iniciar correctamente.
- Debe quedar habilitado para iniciar automáticamente en cada arranque.
- El servicio debe ejecutarse usando el usuario webapp.
- Debe registrar actividad en los logs del sistema.
```

---

## Script de Preparación

Guardar como:

```bash
deploy_playground1.sh
```

Ejecutar:

```bash
sudo bash deploy_playground1.sh
```

```bash
#!/bin/bash

useradd -r -s /bin/bash webapp 2>/dev/null

mkdir -p /opt/webcheck

cat << 'EOF' > /opt/webcheck/webcheck.sh
#!/bin/bash

while true
do
    echo "Application running"
    sleep 30
done
EOF

chmod 644 /opt/webcheck/webcheck.sh

cat << 'EOF' > /etc/systemd/system/webcheck.service
[Unit]
Description=WebCheck Application

[Service]
ExecStart=/opt/webcheck/webcheck.sh
User=webapp

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo
echo "======================================="
echo "Playground 01 desplegado"
echo "Ticket: INC-1001"
echo "======================================="
```

---

## Reglas

❌ No consultar notas.

❌ No buscar la solución.

❌ No modificar el script de preparación.

✅ Utilizar únicamente herramientas de diagnóstico Linux.

---

## Entregables

Al finalizar debo poder demostrar:

```bash
systemctl status webcheck
```

Resultado esperado:

```text
active (running)
```

---

```bash
systemctl is-enabled webcheck
```

Resultado esperado:

```text
enabled
```

---

## Autoevaluación

Responder al finalizar:

1. ¿Cuál era la causa raíz?
    
2. ¿Qué comandos utilicé?
    
3. ¿Qué logs consulté?
    
4. ¿Cuánto tiempo tardé?
    
5. ¿Cómo habría detectado este problema en producción?
    

---

## Registro de Tiempo

```text
Inicio:

Primer diagnóstico:

Causa raíz encontrada:

Solución aplicada:

Validación final:

Duración total:
```

---

## Nivel

|Categoría|Nivel|
|---|---|
|KodeKloud|3/10|
|LFCS|5/10|
|SysAdmin|4/10|

