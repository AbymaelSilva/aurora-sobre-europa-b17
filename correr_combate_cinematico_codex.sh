#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"
mkdir -p logs/lote9
if [[ "${1:-}" == "--terminal" ]]; then
  exec xfce4-terminal --title="B17 — CODEX LOTE 9 · COMBATE 1945" \
    --working-directory="$PROJECT_ROOT" --hold \
    --command="bash '$PROJECT_ROOT/correr_combate_cinematico_codex.sh'"
fi
exec 9>logs/lote9/ejecucion.lock
if ! flock -n 9; then echo "Ya hay un ejecutor del Lote 9."; exit 0; fi
echo "En cola: esperando cierre del trabajo actual de voces, música y flak."
while ! python3 -c 'import json; from pathlib import Path; p=Path("logs/dialogue_music/TERMINADO_Y_JUEGO_ABIERTO.json"); raise SystemExit(0 if p.exists() and json.loads(p.read_text()).get("complete") is True else 1)' 2>/dev/null; do
  sleep 2
done
echo "Trabajo anterior terminado. Iniciando Codex Lote 9."
codex exec --skip-git-repo-check --sandbox danger-full-access \
  -c 'approval_policy="never"' --color always \
  - < planning/orquestacion/PROMPT_COMBATE_CINEMATICO_1945_LOTE9.md \
  2>&1 | tee -a logs/lote9/codex.log
