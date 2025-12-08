# Lab_RHEL/ex200/rhcsa_lab_trainer/core/scenario_creator.py
#!/usr/bin/env python3
"""
🚀 CREADOR YAML MAESTRO RHCSA — GENERAL (Cualquier módulo + N labs)
Detecta ruta automática → Crea YAML maestro → Importa DB
"""
import yaml
from pathlib import Path
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from core.database_manager import DatabaseManager

# Módulos RHCSA (tu estructura perfecta)
MODULES = {
    "1": ("01_essential_tools", "Essential Tools"),
    "2": ("02_running_systems", "Running Systems"),
    "3": ("03_local_storage", "Local Storage"),
    "4": ("04_file_systems", "File Systems"),
    "5": ("05_deploy_systems", "Deploy Systems"),
    "6": ("06_networking", "Networking"),
}

def create_master_yaml():
    """🎮 GENERAL: Módulo → Ruta auto → YAML maestro → DB"""
    clear_screen()
    print(f"{Color.CYAN}🚀 CREADOR YAML MAESTRO RHCSA{Color.RESET}")
    print(f"{Color.YELLOW}    GENERAL • Cualquier módulo • N labs • Auto-import DB{Color.RESET}\n")

    # 1. **DETECTAR MÓDULO + RUTA AUTOMÁTICA**
    print("📂 Módulos RHCSA:")
    for k, (_, name) in MODULES.items():
        print(f"   {Color.CYAN}{k}{Color.RESET} → {name}")
    
    while True:
        mod_key = input(f"\n{Color.CYAN}Elige módulo (1-6) → {Color.RESET}").strip()
        if mod_key in MODULES:
            module_path, module_name = MODULES[mod_key]
            yaml_path = Path(f"scenarios/{module_path}/{module_path}-master.yaml")
            print(f"\n{Color.GREEN}✅ RUTA DETECTADA AUTOMÁTICA:{Color.RESET}")
            print(f"   📁 {yaml_path}")
            break
        print(f"{Color.RED}Opción inválida{Color.RESET}")

    # Confirmar/crear carpeta
    yaml_path.parent.mkdir(parents=True, exist_ok=True)
    if yaml_path.exists():
        if input(f"{Color.YELLOW}¿Sobrescribir {yaml_path.name}? (s/N) → {Color.RESET}").lower() != 's':
            pause("Cancelado")
            return

    # 2. **CONFIGURACIÓN MAESTRO**
    subtitle = input(f"\n{Color.CYAN}Subtema (ej: 'Administración LVM') → {Color.RESET}").strip()
    if not subtitle:
        subtitle = module_name
    
    num_labs = input(f"{Color.CYAN}¿Cuántos labs? (Enter=16) → {Color.RESET}").strip()
    num_labs = int(num_labs) if num_labs.isdigit() else 16

    # 3. **CREAR LABS INDIVIDUALES**
    labs = []
    print(f"\n{Color.YELLOW}📋 Creando {num_labs} labs para '{subtitle}'...{Color.RESET}")
    
    for i in range(1, num_labs + 1):
        lab_id = f"{module_path.split('_')[-1]}-{i:03d}"  # lvm-001, users-001
        
        lab = {
            "id": lab_id,
            "title": input(f"  Lab {i:02d} título → ").strip() or f"Lab {i} {subtitle}",
            "subtitle": subtitle,
            "difficulty": int(input(f"  Lab {i:02d} dificultad (1-5) [Enter=2] → ") or "2"),
            "points": int(input(f"  Lab {i:02d} puntos [Enter=50] → ") or "50"),
            "repetitions_required": int(input(f"  Lab {i:02d} reps [Enter=5] → ") or "5"),
            "scenario": input(f"  Lab {i:02d} escenario → ").strip() or f"Configura {lab_id}",
            "expected": input(f"  Lab {i:02d} validación → ").strip() or f"Comandos `{lab_id}` OK",
            "setup": input(f"  Lab {i:02d} setup_ssh → ").strip() or "# Setup básico"
        }
        labs.append(lab)
        print(f"   {Color.GREEN}✓{Color.RESET} {lab_id} ({lab['points']}pts D{lab['difficulty']})")

    # 4. **YAML MAESTRO FINAL**
    master_yaml = {
        "module": module_name,
        "submodule": subtitle,
        "labs_count": len(labs),
        "labs": labs
    }
    
    with open(yaml_path, 'w', encoding='utf-8') as f:
        yaml.safe_dump(master_yaml, f, allow_unicode=True, sort_keys=False, width=1000)
    
    print(f"\n{Color.GREEN}🎉 YAML MAESTRO CREADO:{Color.RESET}")
    print(f"   📁 {yaml_path}")
    print(f"   🧪 {len(labs)} labs gamificados")

    # 5. **AUTO-IMPORT DB**
    if input(f"\n{Color.CYAN}¿Importar {len(labs)} labs a DB ahora? (s/N) → {Color.RESET}").lower() == 's':
        try:
            with DatabaseManager() as db:
                count = db.import_lab_yaml(yaml_path)
                print(f"{Color.GREEN}✅ {count} labs importados → ¡Training listo!{Color.RESET}")
        except Exception as e:
            print(f"{Color.RED}❌ Error DB: {e}{Color.RESET}")

    pause("Enter para continuar...")

if __name__ == "__main__":
    create_master_yaml()
