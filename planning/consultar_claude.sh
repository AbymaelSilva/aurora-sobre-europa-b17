#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
command -v claude >/dev/null || { echo 'Claude CLI no está instalado.' >&2; exit 1; }
output_file="REVISION_CLAUDE_$(date +%Y%m%d_%H%M%S).txt"
echo "Consultando a Claude. Respuesta guardada en: $output_file"
claude -p --tools '' --output-format text < CONSULTA_CLAUDE.txt | tee "$output_file"
