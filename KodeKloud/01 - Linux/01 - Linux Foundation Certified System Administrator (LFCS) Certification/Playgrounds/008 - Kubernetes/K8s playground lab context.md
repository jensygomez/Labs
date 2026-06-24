# Kubernetes Playground — Contexto de Infraestructura + Incidentes L1

> Documento de referencia para el repo `jensygomez/Labs`, módulo Kubernetes. Claude Code debe usar ESTOS datos —no asunciones genéricas— al generar incidentes K8S-XXX para este playground.

---

## 1. Topología real del cluster (verificada)

|Nodo|Rol|Versión|OS|Kernel|Runtime|
|---|---|---|---|---|---|
|`controlplane`|control-plane|v1.36.0|Ubuntu 22.04.5 LTS|6.8.0-124-generic|containerd://2.2.3|
|`node01`|worker|v1.36.0|Ubuntu 22.04.5 LTS|6.8.0-124-generic|containerd://2.2.3|
|`node02`|worker|v1.36.0|Ubuntu 22.04.5 LTS|6.8.0-124-generic|containerd://2.2.3|

**Nota importante:** la descripción de marketing del playground indica "1 master + 1 worker", pero el cluster real provisionado tiene **3 nodos** (1 control-plane + 2 workers). Los incidentes deben asumir 3 nodos, no 2.

### Provisionamiento

- Herramienta: `kubeadm`
- CNI: Canal (Flannel + Calico) — DaemonSet `canal`, 3/3 pods Running
- Container runtime: containerd
- kube-proxy: DaemonSet, 3/3 pods Running (uno por nodo)

### Namespaces existentes

```
default
kube-node-lease
kube-public
kube-system
```

Los incidentes deben crearse en `default` salvo que el objetivo sea explícitamente practicar el flag `-n` / `--namespace` (ver K8S-007).

### Componentes de control-plane verificados (todos Running, kube-system)

- `etcd-controlplane`
- `kube-apiserver-controlplane`
- `kube-controller-manager-controlplane`
- `kube-scheduler-controlplane`
- `coredns` (2 réplicas)
- `calico-kube-controllers` (1 réplica)
- `canal` (1 por nodo → 3 total)
- `kube-proxy` (1 por nodo → 3 total)

### Rango de IPs internas observado

`10.244.x.x` (pods de control-plane y canal), usar este rango si un incidente necesita mostrar `kubectl get pods -o wide` con IPs creíbles.

---

## 2. Restricciones de diseño para incidentes K8S-XXX

1. **No tocar componentes de control-plane** (etcd, apiserver, scheduler, controller-manager) — eso es nivel 6+, fuera de scope L1 3-5/10.
2. **No asumir acceso SSH directo a `node01`/`node02`** salvo que el incidente lo declare explícitamente; el playground opera todo desde `controlplane` vía `kubectl`.
3. **Usar nombres de nodos reales** (`controlplane`, `node01`, `node02`) en lugar de nombres genéricos inventados.
4. **Versión objetivo de manifiestos:** v1.36.0 (usar `apiVersion` correspondiente; evitar APIs deprecadas como `extensions/v1beta1`).
5. **Sesión limitada a 60 min** (extensible) — cada incidente debe resolverse en máx. 15-20 min para no quemar la sesión completa en un solo ticket.

### Comandos de verificación rápida (inicio de cada sesión)

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A
kubectl get daemonsets -A
```

---

## 3. Módulo de incidentes — "Kubernetes Fundamentos" (K8S-001 a K8S-010)

Nivel L1, dificultad 3-5/10. Fallas comunes que un NOC L1 vería escaladas desde Nivel 2/3, sin troubleshooting de control-plane interno.

| ID      | Título del ticket                  | Síntoma reportado (estilo cliente)                          | Dificultad | Conceptos testeados                                                                 | Nodo(s) involucrado(s) |
| ------- | ---------------------------------- | ----------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------- | ---------------------- |
| K8S-001 | Pod en CrashLoopBackOff            | "La app de staging no responde, el pod reinicia solo"       | 3          | `kubectl describe pod`, logs, exit codes                                            | node01 o node02        |
| K8S-002 | ImagePullBackOff                   | "El deployment no levanta, dice que no encuentra la imagen" | 3          | Typo en imagen/tag, `kubectl describe`, events                                      | node01 o node02        |
| K8S-003 | Service sin endpoints              | "El servicio existe pero no conecta con nada"               | 4          | Selector labels mal configurados (Service vs Pod labels)                            | node01 o node02        |
| K8S-004 | ConfigMap no montado               | "La app arranca pero no lee su configuración"               | 4          | `volumeMounts`, `configMapRef`, nombre incorrecto                                   | node01 o node02        |
| K8S-005 | Pod en Pending indefinido          | "El pod nunca pasa a Running"                               | 4          | Resource requests/limits mal calculados vs capacidad del nodo (3 nodos disponibles) | cluster completo       |
| K8S-006 | Secret no inyectado                | "La app no logra autenticar contra la base de datos"        | 4          | `envFrom secretRef`, secret en namespace equivocado                                 | node01 o node02        |
| K8S-007 | Namespace incorrecto               | "Desplegué la app pero `kubectl get pods` no la muestra"    | 3          | Namespace default vs explícito, `-n` flag, contexto                                 | node01 o node02        |
| K8S-008 | OOMKilled                          | "La app se cae bajo carga, sin error claro"                 | 5          | `kubectl describe` (Reason: OOMKilled), límites de memoria                          | node01 o node02        |
| K8S-009 | NodePort no accesible externamente | "No puedo acceder a la app desde fuera del cluster"         | 5          | Tipo de Service mal elegido (ClusterIP vs NodePort), firewall del nodo              | node01 o node02        |
| K8S-010 | Readiness probe fallando           | "El pod está Running pero el Service no lo enruta"          | 5          | Diferencia Liveness vs Readiness, probe mal configurado                             | node01 o node02        |

### Progresión lógica recomendada

1. **K8S-001 → K8S-002**: errores obvios visibles en logs/events.
2. **K8S-003 → K8S-004 → K8S-006 → K8S-007**: configuración mal vinculada entre objetos (Services, ConfigMaps, Secrets, Namespaces).
3. **K8S-005 → K8S-008 → K8S-009 → K8S-010**: requieren entender comportamiento del scheduler y la red en capas (ya con algo más de razonamiento diagnóstico, aprovechando que hay 3 nodos reales para observar distribución de pods).

---

