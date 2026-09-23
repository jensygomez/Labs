#!/bin/bash
set -e
SECRETS_FILE="/workspace/secrets/systech-secrets.yml"

# Asegurar que /workspace/.ssh sea escribible por jensyg
if [ -d "/workspace/.ssh" ] && [ ! -w "/workspace/.ssh" ]; then
  echo "⚠️  Corrigiendo permisos de /workspace/.ssh..."
  echo "   Ejecuta 'sudo chown -R \$(id -u):\$(id -g) .' en tu host"
fi

if [ -f "$SECRETS_FILE" ]; then
  echo "🔓 Desencriptando Ansible Vault..."
  if ! ansible-vault view --ask-vault-pass "$SECRETS_FILE" > /tmp/.secrets_decrypted.yml; then
    echo "❌ Error al desencriptar el Vault. Contraseña incorrecta o archivo dañado."
    exit 1
  fi

  # Parsear YAML y configurar entorno
  python3 << 'EOF'
import yaml
import os
import stat

with open("/tmp/.secrets_decrypted.yml") as f:
    data = yaml.safe_load(f)

ssh_dir = os.path.expanduser("~/.ssh")
os.makedirs(ssh_dir, exist_ok=True)

# Configurar clave privada para SSH directo
key_path = os.path.join(ssh_dir, "id_systech_control")
with open(key_path, "w") as k:
    k.write(data["ssh_private_key"])
os.chmod(key_path, stat.S_IREAD | stat.S_IWRITE) # 0600

# Configurar SSH config
config_path = os.path.join(ssh_dir, "config")
with open(config_path, "w") as c:
    c.write("Host *\n")
    c.write("  IdentityFile ~/.ssh/id_systech_control\n")
    c.write("  IdentitiesOnly yes\n")
    c.write("  StrictHostKeyChecking accept-new\n")
    c.write("  UserKnownHostsFile /dev/null\n")
os.chmod(config_path, stat.S_IREAD | stat.S_IWRITE)

# Preparar variables de entorno para OpenTofu/Ansible/Tailscale
env_file = "/tmp/.systech_env"
with open(env_file, "w") as e:
    e.write(f'export TF_VAR_proxmox_api_token="{data["proxmox_api_token"]}"\n')
    e.write(f'export TF_VAR_proxmox_ssh_private_key="""{data["ssh_private_key"]}"""\n')
    if "ssh_public_key" in data:
        e.write(f'export TF_VAR_ssh_public_key="{data["ssh_public_key"]}"\n')
    if "tailscale_auth_key" in data:
        e.write(f'export TAILSCALE_AUTH_KEY="{data["tailscale_auth_key"]}"\n')
EOF

  # Inyectar variables en la sesión actual
  source /tmp/.systech_env

  # Limpieza segura de archivos temporales
  rm -f /tmp/.secrets_decrypted.yml /tmp/.systech_env
  echo "✅ Secretos cargados y SSH configurado."
else
  echo "⚠️  No se encontró $SECRETS_FILE. Saltando inyección de secretos."
fi




# ==========================================
# ACTUALIZACIÓN DINÁMICA DE /etc/hosts DESDE ANSIBLE INVENTORY
# ==========================================
echo "🔄 Sincronizando /etc/hosts con el inventario de Ansible..."
python3 << 'EOF'
import yaml
import os
import subprocess

# ⚠️ RUTA ACTUALIZADA PARA EL NUEVO PROYECTO
hosts_yml_path = "/workspace/Linux_Foundation/ansible/inventories/production/hosts.yml"
etc_hosts_path = "/etc/hosts"

if os.path.exists(hosts_yml_path):
    with open(hosts_yml_path, 'r') as f:
        data = yaml.safe_load(f)
    
    host_mappings = {}
    all_children = data.get('all', {}).get('children', {})
    
    if all_children:
        for group, group_data in all_children.items():
            if group_data is None:
                continue
            hosts = group_data.get('hosts', {})
            if hosts:
                for hostname, host_data in hosts.items():
                    if isinstance(host_data, dict) and 'ansible_host' in host_data:
                        host_mappings[hostname] = host_data['ansible_host']
    
    if host_mappings:
        with open(etc_hosts_path, 'r') as f:
            lines = f.readlines()
        
        # ⚠️ MARCADOR ACTUALIZADO
        systech_marker = "# --- LFCS-RHCSA Dynamic Hosts ---"
        clean_lines = []
        skip = False
        for line in lines:
            if systech_marker in line:
                skip = True
            if not skip:
                clean_lines.append(line)
            if skip and line.strip() == "" and len(clean_lines) > 0 and clean_lines[-1].strip() == "":
                skip = False 

        clean_lines.append("\n" + systech_marker + "\n")
        for hostname, ip in sorted(host_mappings.items()):
            clean_lines.append(f"{ip}\t{hostname}\n")
        
        new_content = "".join(clean_lines)
        process = subprocess.run(["sudo", "tee", etc_hosts_path], input=new_content, text=True, stdout=subprocess.DEVNULL, check=True)
        
        print(f"✅ /etc/hosts actualizado con {len(host_mappings)} nodos del laboratorio.")
    else:
        print("⚠️ No se encontraron hosts con 'ansible_host' en el inventario.")
else:
    print(f"⚠️ No se encontró {hosts_yml_path}. (Es normal la primera vez, ejecuta 'tofu apply' primero).")
EOF



# ==========================================
# INICIO DE TAILSCALE (Nativo en el contenedor)
# ==========================================
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
  echo "🌐 Iniciando Tailscale..."
  mkdir -p /workspace/.tailscale_state

  tailscaled --state=/workspace/.tailscale_state/tailscaled.state \
             --socket=/workspace/.tailscale_state/tailscaled.sock &
  sleep 3

  export TS_SOCKET=/workspace/.tailscale_state/tailscaled.sock

  if tailscale --socket="$TS_SOCKET" up --authkey="$TAILSCALE_AUTH_KEY" \
               --accept-routes \
               --hostname=systech-control; then
    echo "✅ Tailscale conectado exitosamente."
  else
    echo "⚠️  Tailscale falló al conectar. Continuando sin VPN (revisa el log arriba)."
  fi
else
  echo "⚠️ TAILSCALE_AUTH_KEY no encontrada en el Vault. Tailscale no se iniciará."
fi

# ==========================================
# CONVENIENCIA PARA TESTING DE LABORATORIO
# (NO es un secreto real — mismo password ya hasheado en
# group_vars/all/system_users.yml, público dentro del lab)
# ==========================================
export LAB_PASS='LabPassword123!'

# Esto SIEMPRE se ejecuta, haya fallado Tailscale o no
exec "$@"

# Ejecutar el comando pasado (ej. /bin/bash)
exec "$@"
