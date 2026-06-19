# Patrón del script de verificación (comportamiento ante fallo)

Este bloque es OBLIGATORIO al final de todo `verify-[id].sh`. Si el Vagrantfile tiene un bug,
el usuario necesita tiempo para copiar el output y pedir una corrección — por eso la pausa
interactiva con `read` es crítica y no se puede omitir.

```bash
if [ $FAIL -eq 0 ]; then
    clear
    cat /home/vagrant/TICKET_[ID].txt
    echo -e "\e[32m✅ Lab listo para practicar\e[0m"
else
    echo " "
    echo -e "\e[41m\e[97m ⚠  INCIDENTE MAL GENERADO \e[0m"
    echo -e "\e[33m$FAIL check(s) fallaron.\e[0m"
    echo " "
    cat /home/vagrant/TICKET_[ID].txt
    echo " "
    echo -e "\e[36m──────────────────────────────────────\e[0m"
    echo -e "\e[36m⏸  PAUSA — El laboratorio NO está listo.\e[0m"
    echo -e "\e[36m   Copia este output y pídeme que lo arregle.\e[0m"
    echo -e "\e[36m   Cuando estés listo, pulsa ENTER para entrar al shell.\e[0m"
    echo -e "\e[36m──────────────────────────────────────\e[0m"
    read -r -p ">>> Presiona ENTER para continuar... " _
    clear
fi
```

## Soporte para --fix (sistema de reparación rápida)

Al inicio del mismo script:

```bash
if [[ "$1" == "--fix" ]]; then
    echo -e "\e[33m🔧 Re-aplicando provisioning...\e[0m"
    sudo bash /tmp/provision-[id-lowercase].sh
    exec bash "$0"   # re-ejecuta el verify sin argumentos
fi
```

## Hook de .bashrc en node01

```bash
if [ -x /tmp/verify-[id-lowercase].sh ]; then
    bash /tmp/verify-[id-lowercase].sh
fi
```

Nunca usar `source` ni ejecutar en subshell — el `read` necesita la tty real del usuario para
que la pausa funcione.
