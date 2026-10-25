#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"
export PATH="$HOME/.local/bin:$PATH"

PROMPT_FILE="$PROJECT_ROOT/planning/orquestacion/PROMPT_COMBATE_INTENSO_LOTE6.md"
echo "Ejecutando Lote 6 (Combate Intenso) con Agy..."
exec agy --dangerously-skip-permissions --mode auto -p "$(cat "$PROMPT_FILE")" "$@"
