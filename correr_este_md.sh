#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"

MD_FILE="$PROJECT_ROOT/planning/orquestacion/PROMPT_GRAN_INCURSION_INVIERNO_LOTE7.md"

if [[ ! -f "$MD_FILE" ]]; then
  echo "ERROR: No existe el archivo $MD_FILE" >&2
  exit 1
fi

if [[ "${1:-}" == "--terminal" ]]; then
  echo "Abriendo en nueva terminal xfce4-terminal..."
  exec xfce4-terminal \
    --title="B17 — EJECUCIÓN LOTE 7: GRAN INCURSIÓN E INVIERNO" \
    --working-directory="$PROJECT_ROOT" \
    --hold \
    --command="bash -c 'agy --dangerously-skip-permissions --mode auto -p \"\$(cat \"$MD_FILE\")\"'"
fi

echo "=========================================================="
echo " Ejecutando Directiva Técnica (Lote 7):"
echo " $(basename "$MD_FILE")"
echo "=========================================================="

exec agy --dangerously-skip-permissions --mode auto -p "$(cat "$MD_FILE")" "$@"
