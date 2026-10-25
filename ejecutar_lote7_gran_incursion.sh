#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"

PROMPT_FILE="$PROJECT_ROOT/planning/orquestacion/PROMPT_GRAN_INCURSION_INVIERNO_LOTE7.md"

if ! command -v agy >/dev/null 2>&1; then
  echo "ERROR: 'agy' no encontrado en el PATH ni en ~/.local/bin" >&2
  exit 1
fi

if [[ "${1:-}" == "--terminal" ]]; then
  echo "Abriendo Agy en nueva terminal para ejecutar Lote 7..."
  exec xfce4-terminal \
    --title="B17 — LOTE 7: GRAN INCURSIÓN E INVIERNO" \
    --working-directory="$PROJECT_ROOT" \
    --hold \
    --command="bash -c 'agy --dangerously-skip-permissions --mode auto -p \"\$(cat \"$PROMPT_FILE\")\"'"
fi

echo "=========================================================="
echo " Ejecutando Lote 7: Gran Incursión de 300 Aviones e Invierno"
echo " Archivo: $(basename "$PROMPT_FILE")"
echo "=========================================================="

exec agy --dangerously-skip-permissions --mode auto -p "$(cat "$PROMPT_FILE")" "$@"
