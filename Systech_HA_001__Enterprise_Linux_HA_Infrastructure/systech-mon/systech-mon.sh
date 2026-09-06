#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.conf"

tput civis
trap 'tput cnorm; clear; exit' EXIT

draw_header() {
    echo -e "${C_CYAN}${C_BOLD}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}${C_BOLD}║         SYSTECH-HA-001 // REAL-TIME INFRA MONITOR            ║${C_RESET}"
    echo -e "${C_CYAN}${C_BOLD}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
}

while true; do
    tput cup 0 0
    tput ed 
    draw_header
    
    for plugin in "$SCRIPT_DIR/plugins/"*.sh; do
        if [ -f "$plugin" ]; then
            echo ""
            source "$plugin"
        fi
    done
    
    echo -e "\n${C_GRAY}──────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_GRAY} Last Update: $(date '+%H:%M:%S') | Refresh: ${REFRESH_RATE}s | Ctrl+C to exit${C_RESET}"
    sleep "$REFRESH_RATE"
done
