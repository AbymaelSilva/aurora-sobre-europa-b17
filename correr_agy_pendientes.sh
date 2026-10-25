#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Asegurar agy en PATH
export PATH="$HOME/.local/bin:$PATH"

if ! command -v agy >/dev/null 2>&1; then
  echo "ERROR: No se encontró 'agy' en el PATH ni en ~/.local/bin" >&2
  exit 1
fi

DEFAULT_PROMPT="$PROJECT_ROOT/planning/orquestacion/PROMPT_AGY_RESOLVER_PENDIENTES_Y_ROG_ALLY.md"
PROMPT_FILE="$DEFAULT_PROMPT"

# Soporte para abrir en terminal visual independiente
if [[ "${1:-}" == "--terminal" || "${1:-}" == "-t" ]]; then
  shift || true
  PROMPT_ARG="${1:-$DEFAULT_PROMPT}"
  echo "Abriendo Agy en una ventana de terminal dedicada (xfce4-terminal)..."
  exec xfce4-terminal \
    --title="B17 — AGY · RESOLUCIÓN DE PENDIENTES Y ROG ALLY" \
    --working-directory="$PROJECT_ROOT" \
    --hold \
    --command="bash '$PROJECT_ROOT/correr_agy_pendientes.sh' '$PROMPT_ARG'"
fi

# Si se pasó un archivo de prompt personalizado como argumento
if [[ -n "${1:-}" && -f "$1" ]]; then
  PROMPT_FILE="$(realpath "$1")"
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "ERROR: El archivo de prompt no existe: $PROMPT_FILE" >&2
  exit 1
fi

mkdir -p logs/rog_ally
LOG_FILE="$PROJECT_ROOT/logs/rog_ally/agy_pendientes_$(date +%Y%m%d_%H%M%S).log"

echo "=========================================================="
echo " B-17: AURORA SOBRE EUROPA — EJECUTOR AUTÓNOMO AGY"
echo " Proyecto: $PROJECT_ROOT"
echo " Directiva: $(basename "$PROMPT_FILE")"
echo " Registro:  $LOG_FILE"
echo "=========================================================="

# Control de bloqueo para evitar múltiples instancias concurrentes de supervisión
exec 9>"$PROJECT_ROOT/logs/rog_ally/ejecucion_agy.lock"
if ! flock -n 9; then
  echo "AVISO: Ya existe una instancia de Agy ejecutando este lote."
  exit 0
fi

echo "Iniciando Agy en modo autónomo..."
agy --dangerously-skip-permissions --mode auto \
  -p "$(cat "$PROMPT_FILE")" \
  2>&1 | tee -a "$LOG_FILE"
