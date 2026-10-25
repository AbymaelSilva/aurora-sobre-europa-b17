#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  --check)
    exec python3 "$project_root/claude_handoff.py" --check
    ;;
  --terminal)
    exec python3 -u "$project_root/claude_handoff.py"
    ;;
  "")
    exec python3 -u "$project_root/claude_handoff.py" --open-terminal
    ;;
  *)
    printf '%s\n' 'Uso: bash delegar_a_claude.sh [--check | --terminal]' >&2
    exit 2
    ;;
esac
