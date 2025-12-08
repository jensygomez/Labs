#!/usr/bin/env python3
"""
🚀 CREADOR YAML MAESTRO RHCSA — VERSIÓN 2.0
Crea YAMLs con estructura nueva (con validaciones)
"""
import yaml
import json
from pathlib import Path
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause

# Módulos RHCSA
MODULES = {
    "1": ("01_essential_tools", "Essential Tools", "1.0"),
    "2": ("02_running_systems", "Running Systems", "2.0"),
    "3": ("03_local_storage", "Local Storage", "3.0"),
    "4": ("04_file_systems", "File Systems", "4.0"),
    "5": ("05_deploy_systems", "Deploy Systems", "5.0"),
    "6": ("06_networking", "Networking", "6.0"),
}

# Submódulos para cada módulo principal
SUBMODULES = {
    "3": {
        "3.1": ("Particiones", "3.1"),
        "3.2": ("LVM", "3.2"),
        "3.3": ("Filesystems", "3.3"),
    },
    "1": {
        "1.1": ("Usuarios y Grupos", "1.1"),
        "1.2": ("Permisos", "1.2"),
        "1.3": ("Procesos", "1.3"),
    },
    # Agregar otros según necesites
}

def create_master_yaml_v2():
    """🎮 VERSIÓN 2.0: Crea YAMLs con validaciones estructuradas"""
    clear_screen()
    print(f"{Color.CYAN}🚀 CREADOR YAML MAESTRO RHCSA v2.0{Color.RESET}")
    print(f"{Color.YELLOW}    Nueva estructura • Validaciones detalladas • Multi-tipo{Color.RESET}\n")

    # 1. **SELECCIONAR MÓDULO**
    print("📂 Módulos RHCSA:")
    for k, (_, name, _) in MODULES.items():
        print(f"   {Color.CYAN}{k}{Color.RESET} → {name}")
    
    while True:
        mod_key = input(f"\n{Color.CYAN}Elige módulo (1-6) → {Color.RESET}").strip()
        if mod_key in MODULES:
            module_path, module_name, module_id = MODULES[mod_key]
            
            # Verificar si tiene submódulos
            if mod_key in SUBMODULES:
                print(f"\n📂 Submódulos de {module_name}:")
                for sub_id, (sub_name, _) in SUBMODULES[mod_key].items():
                    print(f"   {Color.CYAN}{sub_id}{Color.RESET} → {sub_name}")
                
                sub_choice = input(f"\n{Color.CYAN}Elige submódulo (Enter para saltar) → {Color.RESET}").strip()
                if sub_choice in SUBMODULES[mod_key]:
                    sub_name, sub_id = SUBMODULES[mod_key][sub_choice]
                    module_id = sub_id
                    subtitle = sub_name
                else:
                    subtitle = input(f"{Color.CYAN}Subtema → {Color.RESET}").strip() or module_name
            else:
                subtitle = input(f"{Color.CYAN}Subtema → {Color.RESET}").strip() or module_name
            
            yaml_path = Path(f"scenarios/{module_path}/{module_path}-master.yaml")
            print(f"\n{Color.GREEN}✅ RUTA DETECTADA:{Color.RESET}")
            print(f"   📁 {yaml_path}")
            print(f"   🏷️  Módulo ID: {module_id}")
            break
        print(f"{Color.RED}Opción inválida{Color.RESET}")

    # Confirmar/crear carpeta
    yaml_path.parent.mkdir(parents=True, exist_ok=True)
    if yaml_path.exists():
        if input(f"{Color.YELLOW}¿Sobrescribir {yaml_path.name}? (s/N) → {Color.RESET}").lower() != 's':
            pause("Cancelado")
            return

    # 2. **CONFIGURACIÓN GENERAL**
    num_labs = input(f"\n{Color.CYAN}¿Cuántos labs? (Enter=3 para prueba) → {Color.RESET}").strip()
    num_labs = int(num_labs) if num_labs.isdigit() else 3

    # 3. **CREAR LABS CON VALIDACIONES**
    labs = []
    print(f"\n{Color.YELLOW}📋 Creando {num_labs} labs para '{subtitle}'...{Color.RESET}")
    print(f"{Color.YELLOW}    (Nueva estructura con validaciones detalladas){Color.RESET}\n")
    
    for i in range(1, num_labs + 1):
        lab_id = f"lab-{module_path.split('_')[-1]}-{i:03d}"  # lab-lvm-001
        
        print(f"\n{Color.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Color.RESET}")
        print(f"{Color.BOLD}🆔 LAB {i:02d}: {lab_id}{Color.RESET}")
        print(f"{Color.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Color.RESET}")
        
        # Información básica
        lab_title = input(f"  📝 Título → ").strip() or f"Lab {i} {subtitle}"
        lab_difficulty = int(input(f"  🎯 Dificultad (1-5) [2] → ") or "2")
        lab_points = int(input(f"  ⭐ Puntos [50] → ") or "50")
        lab_reps = int(input(f"  🔄 Repeticiones requeridas [5] → ") or "5")
        
        # Contenido
        print(f"\n  📖 ESCENARIO:")
        print(f"    (Presiona Ctrl+D cuando termines)")
        scenario_lines = []
        try:
            while True:
                line = input("    > ")
                scenario_lines.append(line)
        except EOFError:
            pass
        scenario = "\n".join(scenario_lines) or f"Configuración básica para {lab_title}"
        
        # Setup
        print(f"\n  ⚙️  SETUP (comandos SSH):")
        print(f"    (Presiona Ctrl+D cuando termines)")
        setup_lines = []
        try:
            while True:
                line = input("    $ ")
                setup_lines.append(line)
        except EOFError:
            pass
        setup = "\n".join(setup_lines) or "# Setup básico\n# (agregar comandos aquí)"
        
        # VALIDACIONES (NUEVO)
        print(f"\n  ✅ VALIDACIONES (nuevo sistema):")
        validations = []
        add_more = True
        
        while add_more:
            print(f"\n    ── Validación {len(validations) + 1} ──")
            v_command = input(f"    💻 Comando a ejecutar → ").strip()
            if not v_command:
                print(f"    {Color.YELLOW}⚠️  Comando vacío, omitiendo...{Color.RESET}")
                break
            
            v_description = input(f"    📝 Descripción → ").strip() or f"Validar {v_command}"
            
            # Tipo de validación
            print(f"\n    🎯 Tipo de validación:")
            print(f"      1. contains → Buscar texto en salida")
            print(f"      2. exact → Coincidencia exacta")
            print(f"      3. range → Rango numérico")
            print(f"      4. in_list → Lista de valores aceptables")
            print(f"      5. regex → Expresión regular")
            
            v_type_choice = input(f"    Elige (1-5) [1] → ").strip() or "1"
            type_map = {
                "1": "output_contains",
                "2": "output_exact", 
                "3": "range_numeric",
                "4": "in_list",
                "5": "output_regex"
            }
            v_type = type_map.get(v_type_choice, "output_contains")
            
            # Valores según tipo
            v_data = {}
            if v_type == "output_contains" or v_type == "output_exact":
                v_expected = input(f"    🔍 Texto esperado → ").strip()
                v_data = {"expected_output": v_expected}
            
            elif v_type == "range_numeric":
                v_min = input(f"    📉 Mínimo → ").strip()
                v_max = input(f"    📈 Máximo → ").strip()
                v_data = {
                    "expected_range": {
                        "min": v_min,
                        "max": v_max
                    }
                }
            
            elif v_type == "in_list":
                print(f"    📋 Valores aceptables (separados por comas):")
                v_values = input(f"    → ").strip()
                v_data = {
                    "expected_values": [v.strip() for v in v_values.split(",") if v.strip()]
                }
            
            elif v_type == "output_regex":
                v_regex = input(f"    🎭 Patrón regex → ").strip()
                v_data = {
                    "expected_output": v_regex,
                    "match_type": "regex"
                }
            
            v_weight = int(input(f"    ⚖️  Peso (1-5) [1] → ") or "1")
            v_timeout = int(input(f"    ⏱️  Timeout segundos [10] → ") or "10")
            
            # Construir validación
            validation = {
                "command": v_command,
                "description": v_description,
                "match_type": "contains" if v_type == "output_contains" else 
                            "exact" if v_type == "output_exact" else
                            "regex" if v_type == "output_regex" else v_type,
                "weight": v_weight,
                "timeout": v_timeout,
                **v_data
            }
            
            validations.append(validation)
            
            # ¿Agregar otra validación?
            more = input(f"\n    ➕ ¿Agregar otra validación? (s/N) → ").lower()
            add_more = (more == 's')
        
        # Construir lab completo
        lab = {
            "id": lab_id,
            "title": lab_title,
            "subtitle": subtitle,
            "difficulty": lab_difficulty,
            "points": lab_points,
            "repetitions_required": lab_reps,
            
            "scenario": scenario,
            "setup": setup,
            "validations": validations,
            
            # Opcionales
            "hints": input(f"\n  💡 Pistas (opcional, Enter para omitir) → ").strip() or "",
            "tags": [t.strip() for t in input(f"  🏷️  Tags (separados por comas) → ").strip().split(",") if t.strip()],
            "estimated_time": int(input(f"  ⏰ Tiempo estimado minutos [15] → ") or "15"),
        }
        
        labs.append(lab)
        print(f"\n  {Color.GREEN}✅ {lab_id} creado con {len(validations)} validaciones{Color.RESET}")

    # 4. **YAML MAESTRO FINAL (v2.0)**
    master_yaml = {
        "module": module_name,
        "module_id": module_id,
        "submodule": subtitle,
        "labs_count": len(labs),
        "type": "static",
        "version": "2025.2",
        
        "labs": labs
    }
    
    # Guardar con formato mejorado
    with open(yaml_path, 'w', encoding='utf-8') as f:
        yaml.safe_dump(master_yaml, f, 
                      allow_unicode=True, 
                      sort_keys=False, 
                      width=1000,
                      default_flow_style=False,
                      indent=2)
    
    print(f"\n{Color.GREEN}🎉 YAML MAESTRO v2.0 CREADO:{Color.RESET}")
    print(f"   📁 {yaml_path}")
    print(f"   🧪 {len(labs)} labs con validaciones estructuradas")
    print(f"   ✅ Total validaciones: {sum(len(lab.get('validations', [])) for lab in labs)}")
    
    # 5. **OPCIÓN: IMPORTAR A BD NUEVA**
    print(f"\n{Color.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Color.RESET}")
    import_choice = input(f"{Color.CYAN}¿Importar a base de datos nueva? (s/N) → {Color.RESET}").lower()
    
    if import_choice == 's':
        try:
            from core.scenario_loader import load_all_scenarios_to_db
            
            print(f"{Color.YELLOW}🔄 Importando a BD nueva...{Color.RESET}")
            stats = load_all_scenarios_to_db(str(yaml_path.parent))
            
            print(f"\n{Color.GREEN}✅ IMPORTACIÓN COMPLETADA:{Color.RESET}")
            print(f"   📊 Labs: {stats.get('labs_loaded', 0)}")
            print(f"   ✅ Validaciones: {stats.get('validations_loaded', 0)}")
            print(f"   ⚠️  Errores: {stats.get('errors', 0)}")
            
            if stats.get('errors', 0) == 0:
                print(f"\n{Color.GREEN}🚀 ¡Sistema listo para usar con nueva estructura!{Color.RESET}")
            else:
                print(f"\n{Color.YELLOW}⚠️  Revise los errores antes de continuar{Color.RESET}")
                
        except ImportError as e:
            print(f"{Color.RED}❌ No se pudo importar: {e}{Color.RESET}")
            print(f"{Color.YELLOW}💡 Asegúrate de tener los nuevos módulos:{Color.RESET}")
            print(f"   • core.scenario_loader")
            print(f"   • core.database_manager (nueva versión)")
        except Exception as e:
            print(f"{Color.RED}❌ Error durante importación: {e}{Color.RESET}")

    pause("\nEnter para continuar...")

def main():
    """Función principal con menú"""
    clear_screen()
    print(f"{Color.CYBOLD}🚀 CREADOR RHCSA TRAINER v2.0{Color.RESET}")
    print(f"{Color.CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Color.RESET}")
    print(f"\n{Color.YELLOW}1.{Color.RESET} Crear YAML maestro (nueva estructura)")
    print(f"{Color.YELLOW}2.{Color.RESET} Convertir YAML viejo a nuevo")
    print(f"{Color.YELLOW}3.{Color.RESET} Salir")
    
    choice = input(f"\n{Color.CYAN}Selección → {Color.RESET}").strip()
    
    if choice == "1":
        create_master_yaml_v2()
    elif choice == "2":
        print(f"{Color.YELLOW}🔧 Conversor en desarrollo...{Color.RESET}")
        pause()
    else:
        print(f"{Color.GREEN}👋 Hasta luego!{Color.RESET}")

if __name__ == "__main__":
    main()