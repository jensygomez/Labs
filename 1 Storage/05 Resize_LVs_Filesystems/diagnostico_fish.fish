#!/usr/bin/fish

echo "=== DIAGNÓSTICO DE CONFIGURACIÓN FISH ==="

echo ""

echo "1. Comprobando variable PATH:"
echo "   PATH actual: $PATH"
echo "   Longitud: "(count $PATH)" elementos"
echo ""

echo "2. Comprobando comandos básicos:"
for cmd in uname whoami id hostname ls eza
    echo -n "   $cmd: "
    if command -v $cmd >/dev/null 2>&1
        echo "✓ Encontrado en "(which $cmd)
    else
        echo "✗ NO ENCONTRADO"
    end
end
echo ""

echo "3. Comprobando archivos de configuración problemáticos:"
echo "   a) ~/.config/fish/functions/fish_prompt.fish:"
if test -f ~/.config/fish/functions/fish_prompt.fish
    echo "      ✓ Existe"
    echo "      Contenido (primeras 20 líneas):"
    head -20 ~/.config/fish/functions/fish_prompt.fish | sed 's/^/        /'
else
    echo "      ✗ No existe"
end
echo ""

echo "   b) /usr/share/cachyos-fish-config/conf.d/done.fish:"
if test -f /usr/share/cachyos-fish-config/conf.d/done.fish
    echo "      ✓ Existe"
    echo "      Línea 96 (problemática):"
    sed -n '96p' /usr/share/cachyos-fish-config/conf.d/done.fish | sed 's/^/        /'
else
    echo "      ✗ No existe"
end
echo ""

echo "4. Comprobando funciones personalizadas:"
echo "   Función 'ls':"
if functions -q ls
    echo "      ✓ Definida"
    echo "      Definición:"
    functions ls | head -5 | sed 's/^/        /'
else
    echo "      ✗ No definida (usará la por defecto)"
end
echo ""

echo "5. Comprobando archivos de configuración que afectan PATH:"
echo "   ~/.config/fish/config.fish:"
if test -f ~/.config/fish/config.fish
    echo "      ✓ Existe"
    echo "      Líneas que modifican PATH:"
    grep -i path ~/.config/fish/config.fish | sed 's/^/        /'
else
    echo "      ✗ No existe"
end
echo ""

echo "6. Comprobando entorno del usuario:"
echo "   USER: $USER"
echo "   HOME: $HOME"
echo "   SHELL: $SHELL"
echo ""

echo "7. Probando comandos problemáticos (con redirección de errores):"
echo "   - uname: "(uname 2>&1 || echo "ERROR")
echo "   - whoami: "(whoami 2>&1 || echo "ERROR")
echo "   - id -u: "(id -u 2>&1 || echo "ERROR")
echo "   - hostname -s: "(hostname -s 2>&1 || echo "ERROR")
echo ""

echo "=== FIN DEL DIAGNÓSTICO ==="
