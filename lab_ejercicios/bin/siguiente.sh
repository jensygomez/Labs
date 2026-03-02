#!/bin/bash
DB="../lab.db"

pendientes=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE completado=0")
if [ "$pendientes" -eq 0 ]; then
    echo "🎉 ¡FELICIDADES! Terminaste todos los ejercicios 📚"
    exit 0
fi

# OPCIÓN 1: Siguiente por orden natural (bloque → tema → nivel)
ejercicio=$(sqlite3 -header -column "$DB" "
SELECT id, bloque, tema, nivel, orden, enunciado 
FROM ejercicios 
WHERE completado = 0 
ORDER BY bloque, tema, nivel, orden
LIMIT 1;
")

# OPCIÓN 2: Aleatorio entre pendientes (descomenta si prefieres)
# ejercicio=$(sqlite3 -header -column "$DB" "
# SELECT id, bloque, tema, nivel, orden, enunciado 
# FROM ejercicios 
# WHERE completado = 0 
# ORDER BY RANDOM()
# LIMIT 1;
# ")

read id bloque tema nivel orden enunciado <<< "$ejercicio"

cat << MOSTRAR

🆕 SIGUIENTE EJERCICIO ($pendientes pendientes)
═══════════════════════════════

🔥 BLOQUE $bloque | $tema | $nivel #$orden
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 TEMA: $tema
⚡ NIVEL: $nivel

$enunciado

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ "completado" cuando termines ✓
⏭️  "saltar" para después
🔙 "progreso" para ver avance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $id

MOSTRAR

read -p "Tu acción: " accion

case $accion in
    "completado"|"c"|"C")
        sqlite3 "$DB" "
        UPDATE ejercicios SET completado=1, fecha_completado=datetime('now') WHERE id=$id;
        "
        echo "✅ $id COMPLETADO ✓ ($((pendientes-1)) pendientes)"
        ;;
    "saltar"|"s"|"S")
        echo "⏭️ $id guardado para después"
        ;;
    "progreso"|"p"|"P")
        ./progreso.sh
        ;;
    *)
        echo "❓ Usa: completado | saltar | progreso"
        ;;
esac

echo ""
