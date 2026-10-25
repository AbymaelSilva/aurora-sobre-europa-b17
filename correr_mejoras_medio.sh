#!/usr/bin/env bash
# ==============================================================================
# B-17: Aurora sobre Europa — Lanzador de Mejoras de Jugabilidad MEDIO
# Ejecuta Agy en modo autónomo con el prompt técnico de las 4 mejoras MEDIO
# ==============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v agy >/dev/null 2>&1; then
  echo "ERROR: No se encontró 'agy' en el PATH ni en ~/.local/bin" >&2
  exit 1
fi

PROMPT_FILE="$PROJECT_ROOT/planning/orquestacion/PROMPT_MEJORAS_MEDIO.md"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "ERROR: El archivo de prompt no existe: $PROMPT_FILE" >&2
  exit 1
fi

if [[ "${1:-}" == "--terminal" || "${1:-}" == "-t" ]]; then
  exec xfce4-terminal \
    --title="B17 — AGY · MEJORAS JUGABILIDAD MEDIO" \
    --working-directory="$PROJECT_ROOT" \
    --hold \
    --command="bash '$PROJECT_ROOT/correr_mejoras_medio.sh'"
fi

mkdir -p logs/mejoras_medio
LOG_FILE="$PROJECT_ROOT/logs/mejoras_medio/agy_$(date +%Y%m%d_%H%M%S).log"

exec 9>"$PROJECT_ROOT/logs/mejoras_medio/ejecucion.lock"
if ! flock -n 9; then
  echo "AVISO: Ya existe una instancia activa de este lote."
  exit 0
fi

echo "=========================================================="
echo " B-17: MEJORAS JUGABILIDAD MEDIO — Agy Autónomo"
echo " Registro: $LOG_FILE"
echo "=========================================================="

agy --dangerously-skip-permissions --mode auto \
  -p "$(cat "$PROMPT_FILE")" \
  2>&1 | tee -a "$LOG_FILE"
