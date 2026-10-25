#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"
mkdir -p logs/rog_ally
if [[ "${1:-}" == "--terminal" ]]; then
  exec xfce4-terminal --title="B17 — AGY · PENDIENTES Y ASUS ROG ALLY" \
    --working-directory="$PROJECT_ROOT" --hold \
    --command="bash '$PROJECT_ROOT/correr_agy_rog_ally.sh'"
fi
exec 9>logs/rog_ally/ejecucion.lock
if ! flock -n 9; then echo "Agy ROG Ally ya tiene un ejecutor activo."; exit 0; fi
echo "Agy en cola: espera al cierre de las cuatro mejoras BAJO."
while ! python3 -c 'import json; from pathlib import Path; p=Path("logs/jugabilidad_bajo/TERMINADO_Y_JUEGO_ABIERTO.json"); raise SystemExit(0 if p.exists() and json.loads(p.read_text()).get("complete") is True else 1)' 2>/dev/null; do
  sleep 2
done
echo "Integración anterior terminada. Agy: revisar pendientes y exportar para ROG Ally."
agy --dangerously-skip-permissions --mode auto \
  -p "$(cat planning/orquestacion/PROMPT_AGY_PENDIENTES_ROG_ALLY.md)" \
  2>&1 | tee -a logs/rog_ally/agy.log
