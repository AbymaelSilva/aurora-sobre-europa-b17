#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"
mkdir -p logs/audio_redesign
if [[ "${1:-}" == "--terminal" ]]; then
  exec xfce4-terminal --title="B17 — CODEX AUDIO · M2 PROTEGIDA" \
    --working-directory="$PROJECT_ROOT" --hold \
    --command="bash '$PROJECT_ROOT/correr_audio_codex.sh'"
fi
exec 9>logs/audio_redesign/ejecucion.lock
if ! flock -n 9; then
  echo "Ya existe un encargo Codex de audio activo."
  exit 0
fi
echo "Codex: rediseñar 42 efectos; conservar 5 WAV de la M2."
codex exec --skip-git-repo-check --sandbox danger-full-access \
  -c 'approval_policy="never"' --color always \
  - < planning/orquestacion/PROMPT_AUDIO_REALISTA_B17.md \
  2>&1 | tee -a logs/audio_redesign/codex.log
