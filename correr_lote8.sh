#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"
mkdir -p logs/lote8
if [[ "${1:-}" == "--terminal" ]]; then
  exec xfce4-terminal --title="B17 — LOTE 8: CÁMARA, FLAK Y NUBES" \
    --working-directory="$PROJECT_ROOT" --hold \
    --command="bash '$PROJECT_ROOT/correr_lote8.sh'"
fi
exec 9>logs/lote8/ejecucion.lock
if ! flock -n 9; then
  echo "El Lote 8 ya tiene un ejecutor activo."
  exit 0
fi
echo "Ejecutando Lote 8 con Agy. Registro: logs/lote8/agy.log"
agy --dangerously-skip-permissions --mode auto \
  -p "$(cat planning/orquestacion/PROMPT_LOTE8_CAMARA_FLAK_NUBES.md)" 2>&1 | tee -a logs/lote8/agy.log
