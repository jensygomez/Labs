
"""🔐 Configuración SSH VM - Persistente"""
from pathlib import Path
import json
import os

class SSHConfig:
    def __init__(self):
        self.config_file = Path("data/ssh_config.json")
        self.config_file.parent.mkdir(parents=True, exist_ok=True)
        self.config = self.load_config()
    
    def load_config(self):
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {"host": "192.168.1.100", "user": "rhcsa_lab", "auth": "key"}
    
    def save_config(self):
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def ask_config(self):
        """🎮 PREGUNTA INTERACTIVA"""
        print(f"{Color.CYAN}🔧 Configuración VM (Enter=por defecto):{Color.RESET}")
        
        host = input(f"  IP/Host [{self.config.get('host', '192.168.1.100')}] → ").strip()
        if host:
            self.config['host'] = host
        
        user = input(f"  Usuario [{self.config.get('user', 'rhcsa_lab')}] → ").strip()
        if user:
            self.config['user'] = user
        
        auth = input(f"  ¿SSH Key o Password? [{self.config.get('auth', 'key')}] [k/p] → ").strip().lower()
        if auth in ('p', 'password'):
            self.config['auth'] = 'password'
            password = input("  Password → ").strip()
            self.config['password'] = password
        else:
            self.config['auth'] = 'key'
        
        self.save_config()
        print(f"{Color.GREEN}✅ Config guardada: {self.config['user']}@{self.config['host']}{Color.RESET}")
