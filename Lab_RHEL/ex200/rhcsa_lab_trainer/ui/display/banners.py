from .colors import Color

def show_banner(title="RHCSA LAB TRAINER"):
    print(f"{Color.CYAN}┌─────────────────────────────────────────────────────────────┐")
    print(f"│                                                             │")
    print(f"│  {Color.YELLOW}██████╗ ██╗  ██╗ ██████╗███████╗ █████╗ {Color.CYAN}                   │")
    print(f"│  {Color.YELLOW}██╔══██╗██║  ██║██╔════╝██╔════╝██╔══██╗{Color.CYAN}   LAB TRAINER     │")
    print(f"│  {Color.YELLOW}██████╔╝███████║██║     ███████╗███████║{Color.CYAN}                   │")
    print(f"│  {Color.YELLOW}██╔══██╗██╔══██║██║     ╚════██║██╔══██║{Color.CYAN}                   │")
    print(f"│  {Color.YELLOW}██║  ██║██║  ██║╚██████╗███████║██║  ██║{Color.CYAN}     v1.0           │")
    print(f"│  {Color.YELLOW}╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝{Color.CYAN}                   │")
    print(f"│                                                             │")
    if title and title != "RHCSA LAB TRAINER":
        print(f"│  {Color.WHITE}{title:^56}{Color.CYAN} │")
    print(f"│                                                             │")
    print(f"└─────────────────────────────────────────────────────────────┘{Color.RESET}")

def show_footer():
    print(f"{Color.GRAY}─────────────────────────────────────────────────────────────")
    print(f"  Entrenamiento h = ayuda • b = atrás • q = salir                      ")
    print(f"─────────────────────────────────────────────────────────────{Color.RESET}")