#!/usr/bin/env python3
"""
Módulo de validación para RHCSA Trainer
Valida resultados de comandos contra expectativas definidas en BD
"""
import re
import paramiko
from typing import List, Dict, Tuple, Optional, Callable
from ui.display.colors import Color
from core.ssh_config import SSHConfig


class LabValidator:
    """Validador universal para labs del RHCSA Trainer"""
    
    def __init__(self, lab_id: str, expected_text: str, points: int):
        self.lab_id = lab_id
        self.expected_text = expected_text
        self.points = points
        
    def validate_via_ssh(self, ssh_config: Optional[Dict] = None) -> Tuple[int, List[str]]:
        """
        Valida el lab via SSH
        
        Returns:
            tuple: (score, lista_de_mensajes)
        """
        try:
            # Obtener configuración SSH
            if ssh_config is None:
                config_obj = SSHConfig()
                config_obj.ask_config()
                ssh_config = config_obj.config
            
            # Conectar via SSH
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            if ssh_config['auth'] == 'key':
                ssh.connect(ssh_config['host'], 
                          username=ssh_config['user'], 
                          timeout=10)
            else:
                ssh.connect(ssh_config['host'],
                          username=ssh_config['user'],
                          password=ssh_config['password'],
                          timeout=10)
            
            # Obtener validaciones a realizar
            validations = self._parse_validations()
            
            results = []
            total_checks = len(validations)
            passed_checks = 0
            
            for validation in validations:
                cmd = validation['cmd']
                description = validation['description']
                check_func = validation['check_func']
                
                # Ejecutar comando
                stdin, stdout, stderr = ssh.exec_command(f"sudo {cmd}")
                output = stdout.read().decode().strip()
                exit_code = stdout.channel.recv_exit_status()
                error = stderr.read().decode().strip()
                
                # Verificar
                success, message = check_func(cmd, output, exit_code, error)
                
                if success:
                    passed_checks += 1
                    results.append(f"  {Color.GREEN}✓ {description}{Color.RESET}")
                else:
                    results.append(f"  {Color.RED}✗ {description}{Color.RESET}")
                    if message:
                        results.append(f"     {Color.YELLOW}{message}{Color.RESET}")
            
            ssh.close()
            
            # Calcular score
            if total_checks == 0:
                return 0, results
                
            score = int((passed_checks / total_checks) * self.points)
            return score, results
            
        except Exception as e:
            error_msg = f"{Color.RED}❌ Error de validación: {e}{Color.RESET}"
            return 0, [error_msg]
    
    def _parse_validations(self) -> List[Dict]:
        """Parsea el expected_text en validaciones específicas"""
        validations = []
        
        # Dividir por líneas
        lines = [l.strip() for l in self.expected_text.strip().split('\n') if l.strip()]
        
        for line in lines:
            # Buscar comandos entre backticks
            cmd_matches = re.findall(r'`([^`]+)`', line)
            
            for cmd in cmd_matches:
                # Crear función de validación basada en la descripción
                check_func = self._create_check_function(line, cmd)
                
                validations.append({
                    'cmd': cmd,
                    'description': line,
                    'check_func': check_func
                })
        
        return validations
    
    def _create_check_function(self, description: str, cmd: str) -> Callable:
        """Crea función de validación basada en la descripción"""
        desc_lower = description.lower()
        cmd_lower = cmd.lower()
        
        # Validaciones específicas por tipo de comando
        if 'pvs' in cmd_lower:
            return self._check_pvs_output
        
        elif 'vgs' in cmd_lower:
            return self._check_vgs_output
            
        elif 'lvs' in cmd_lower:
            return self._check_lvs_output
            
        elif 'mount' in cmd_lower or 'df' in cmd_lower:
            return self._check_mount_output
            
        elif 'systemctl' in cmd_lower:
            return self._check_systemctl_output
            
        elif 'firewall-cmd' in cmd_lower:
            return self._check_firewall_output
            
        # Validación genérica
        else:
            return self._check_generic_output
    
    # ===== FUNCIONES ESPECÍFICAS DE VALIDACIÓN =====
    
    def _check_pvs_output(self, cmd: str, output: str, exit_code: int, error: str) -> Tuple[bool, str]:
        """Valida salida de pvs"""
        if exit_code != 0:
            return False, f"Comando falló: {error[:100]}"
        
        # Buscar dispositivo específico mencionado en la descripción
        device_match = re.search(r'/dev/\S+', self.expected_text)
        if device_match:
            device = device_match.group(0)
            if device not in output:
                return False, f"No se encuentra {device} en la salida"
        
        # Verificar formato básico de PV
        if not output.strip():
            return False, "Salida vacía"
            
        return True, ""
    
    def _check_vgs_output(self, cmd: str, output: str, exit_code: int, error: str) -> Tuple[bool, str]:
        """Valida salida de vgs"""
        if exit_code != 0:
            return False, f"Comando falló: {error[:100]}"
        
        # Buscar nombre de VG en descripción
        vg_match = re.search(r'VG\s+(\S+)', self.expected_text) or \
                  re.search(r'volume group\s+(\S+)', self.expected_text, re.IGNORECASE)
        
        if vg_match:
            vg_name = vg_match.group(1)
            if vg_name not in output:
                return False, f"No se encuentra VG '{vg_name}' en la salida"
        
        return True, ""
    
    def _check_lvs_output(self, cmd: str, output: str, exit_code: int, error: str) -> Tuple[bool, str]:
        """Valida salida de lvs"""
        if exit_code != 0:
            return False, f"Comando falló: {error[:100]}"
        
        # Buscar nombre de LV en descripción
        lv_match = re.search(r'LV\s+(\S+)', self.expected_text) or \
                  re.search(r'logical volume\s+(\S+)', self.expected_text, re.IGNORECASE)
        
        if lv_match:
            lv_name = lv_match.group(1)
            if lv_name not in output:
                return False, f"No se encuentra LV '{lv_name}' en la salida"
        
        return True, ""
    
    def _check_mount_output(self, cmd: str, output: str, exit_code: int, error: str) -> Tuple[bool, str]:
        """Valida salida de mount/df"""
        if exit_code != 0:
            return False, f"Comando falló: {error[:100]}"
        
        # Buscar punto de montaje en descripción
        mount_match = re.search(r'mount.*?(\S+)', self.expected_text, re.IGNORECASE) or \
                     re.search(r'montado.*?(\S+)', self.expected_text, re.IGNORECASE)
        
        if mount_match:
            mount_point = mount_match.group(1)
            if mount_point not in output:
                return False, f"No se encuentra '{mount_point}' montado"
        
        return True, ""
    
    def _check_systemctl_output(self, cmd: str, output: str, exit_code: int, error: str) -> Tuple[bool, str]:
        """Valida salida de systemctl"""
        if exit_code != 0:
            return False, f"Comando falló: {error[:100]}"
        
        # Buscar servicio en descripción
        service_match = re.search(r'service\s+(\S+)', self.expected_text, re.IGNORECASE) or \
                       re.search(r'servicio\s+(\S+)', self.expected_text, re.IGNORECASE)
        
        if service_match:
            service = service_match.group(1)
            if service not in output:
                return False, f"No se encuentra servicio '{service}'"
            
            # Verificar que esté activo/enabled
            if 'active' in cmd_lower and 'active' not in output.lower():
                return False, f"Servicio '{service}' no está activo"
            if 'enabled' in cmd_lower and 'enabled' not in output.lower():
                return False, f"Servicio '{service}' no está enabled"
        
        return True, ""
    
    def _check_firewall_output(self, cmd: str, output: str, exit_code: int, error: str) -> Tuple[bool, str]:
        """Valida salida de firewall-cmd"""
        if exit_code != 0:
            return False, f"Comando falló: {error[:100]}"
        
        # Buscar puerto/servicio en descripción
        port_match = re.search(r'port\s+(\d+)', self.expected_text, re.IGNORECASE) or \
                    re.search(r'puerto\s+(\d+)', self.expected_text, re.IGNORECASE)
        
        service_match = re.search(r'service\s+(\S+)', self.expected_text, re.IGNORECASE) or \
                       re.search(r'servicio\s+(\S+)', self.expected_text, re.IGNORECASE)
        
        if port_match:
            port = port_match.group(1)
            if port not in output:
                return False, f"Puerto {port} no encontrado en reglas"
        
        if service_match:
            service = service_match.group(1)
            if service not in output:
                return False, f"Servicio {service} no encontrado en reglas"
        
        return True, ""
    
    def _check_generic_output(self, cmd: str, output: str, exit_code: int, error: str) -> Tuple[bool, str]:
        """Validación genérica para cualquier comando"""
        if exit_code != 0:
            return False, f"Comando falló con código {exit_code}: {error[:100]}"
        
        if not output.strip():
            return False, "Salida vacía"
        
        # Verificar palabras clave importantes de la descripción
        important_words = ['creado', 'created', 'activo', 'active', 'montado', 'mounted',
                          'presente', 'present', 'funcionando', 'running', 'habilitado', 'enabled']
        
        for word in important_words:
            if word in self.expected_text.lower() and word not in output.lower():
                return False, f"Se esperaba '{word}' en la salida"
        
        return True, ""


# Función de conveniencia para validación rápida
def validate_lab(lab_id: str, expected_text: str, points: int, 
                ssh_config: Optional[Dict] = None) -> Tuple[int, List[str]]:
    """Función helper para validar un lab"""
    validator = LabValidator(lab_id, expected_text, points)
    return validator.validate_via_ssh(ssh_config)