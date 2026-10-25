#!/usr/bin/env bash
# Terminal Meshy: imprime el encargo, pide la clave de forma oculta (no se guarda) y lo ejecuta con Claude (supervisor Claude, 2026-10-24).
set -uo pipefail
cd /home/test-bench/Documents/B17-project
ENCARGO=${ENCARGO:-planning/orquestacion/ENCARGO_MESHY_CLAUDE.md}
printf '\n===== PROMPT ENVIADO A CLAUDE (MESHY · TEXTURAS DE AVIONES) =====\n\n'
cat "$ENCARGO"
printf '\n===== CLAVE DE MESHY =====\nPega tu clave API de Meshy y pulsa Enter (no se muestra ni se guarda en disco):\n'
read -rs MESHY_API_KEY; echo
if [ -z "$MESHY_API_KEY" ]; then echo "Sin clave: no se ejecuta nada."; exit 2; fi
printf '\n===== EJECUTANDO CLAUDE · %s =====\n\n' "$(date -Iseconds)"
MESHY_API_KEY="$MESHY_API_KEY" claude --safe-mode --restricted --permission-mode auto \
  --tools Read,Write,Edit,Glob,Grep,Bash,WebFetch \
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
  -p "$(cat "$ENCARGO")

Trabaja ahora hasta cumplir la meta. El directorio de trabajo es /home/test-bench/Documents/B17-project. La clave está en la variable de entorno MESHY_API_KEY: nunca la muestres."
rc=$?; unset MESHY_API_KEY
printf '\n===== CLAUDE MESHY TERMINÓ (código %s) · %s =====\n' "$rc" "$(date -Iseconds)"
ls art/meshy/candidatos/*.glb 2>/dev/null | wc -l | xargs printf 'Candidatos GLB: %s de 4\n'
