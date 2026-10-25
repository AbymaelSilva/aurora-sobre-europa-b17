#!/usr/bin/env bash
# Terminal de audio: imprime el encargo y lo ejecuta con Claude en modo no interactivo (supervisor Claude, 2026-10-24).
set -uo pipefail
cd /home/test-bench/Documents/B17-project
ENCARGO=planning/orquestacion/ENCARGO_AUDIO_CLAUDE.md
printf '\n===== PROMPT ENVIADO A CLAUDE (AUDIO) =====\n\n'
cat "$ENCARGO"
printf '\n===== EJECUTANDO CLAUDE · %s =====\n\n' "$(date -Iseconds)"
claude --safe-mode --restricted --permission-mode auto --tools Read,Write,Edit,Glob,Grep,Bash \
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
  -p "$(cat "$ENCARGO")

Trabaja ahora hasta cumplir la meta. El directorio de trabajo es /home/test-bench/Documents/B17-project."
printf '\n===== CLAUDE AUDIO TERMINÓ (código %s) · %s =====\n' "$?" "$(date -Iseconds)"
ls godot/B17/assets/audio/sfx/*.wav 2>/dev/null | wc -l | xargs printf 'WAV generados: %s de 47\n'
