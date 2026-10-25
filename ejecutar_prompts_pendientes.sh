#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v agy >/dev/null 2>&1; then
  echo "ERROR: 'agy' no encontrado en el PATH ni en ~/.local/bin" >&2
  exit 1
fi

# Lista de prompts pendientes identificados o pasados como argumentos
PROMPTS_PENDIENTES=()

if [[ $# -gt 0 && "$1" != "--terminal" ]]; then
  # Si el usuario pasa rutas específicas
  for arg in "$@"; do
    if [[ -f "$arg" ]]; then
      PROMPTS_PENDIENTES+=("$arg")
    elif [[ -f "$PROJECT_ROOT/$arg" ]]; then
      PROMPTS_PENDIENTES+=("$PROJECT_ROOT/$arg")
    fi
  done
else
  # Prompts activos pendientes conocidos (Lote 7 Gran Incursión e Invierno)
  LOTE7="$PROJECT_ROOT/planning/orquestacion/PROMPT_GRAN_INCURSION_INVIERNO_LOTE7.md"
  if [[ -f "$LOTE7" ]]; then
    PROMPTS_PENDIENTES+=("$LOTE7")
  fi
  LOTE6="$PROJECT_ROOT/planning/orquestacion/PROMPT_COMBATE_INTENSO_LOTE6.md"
  if [[ -f "$LOTE6" ]]; then
    PROMPTS_PENDIENTES+=("$LOTE6")
  fi
fi

if [[ ${#PROMPTS_PENDIENTES[@]} -eq 0 ]]; then
  echo "No hay prompts pendientes configurados en la cola."
  exit 0
fi

# Si se pide abrir en terminal separada
if [[ "${1:-}" == "--terminal" ]]; then
  echo "Abriendo ejecutor de prompts pendientes en terminal xfce4-terminal..."
  exec xfce4-terminal \
    --title="B17 — EJECUTOR DE PROMPTS PENDIENTES" \
    --working-directory="$PROJECT_ROOT" \
    --hold \
    --command="bash -c '$0; echo Presiona Enter para salir; read'"
fi

echo "=========================================================="
echo " EJECUTOR AUTÓNOMO DE PROMPTS PENDIENTES (AGY)"
echo " Total de tareas/prompts en cola: ${#PROMPTS_PENDIENTES[@]}"
echo "=========================================================="

for i in "${!PROMPTS_PENDIENTES[@]}"; do
  PROMPT_FILE="${PROMPTS_PENDIENTES[$i]}"
  echo ""
  echo "[$((i + 1))/${#PROMPTS_PENDIENTES[@]}] Ejecutando: $(basename "$PROMPT_FILE")"
  echo "Ruta: $PROMPT_FILE"
  echo "----------------------------------------------------------"
  
  agy --dangerously-skip-permissions --mode auto -p "$(cat "$PROMPT_FILE")"
  
  echo "----------------------------------------------------------"
  echo "Completado: $(basename "$PROMPT_FILE")"
done

echo ""
echo "=========================================================="
echo " Todos los prompts pendientes han sido procesados por Agy."
echo "=========================================================="
