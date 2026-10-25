#!/usr/bin/env bash
# Ejecuta el prompt técnico del dashboard con Qwen, por el puente validado (supervisor Claude, 2026-10-24).
set -uo pipefail
cd /home/test-bench/Documents/B17-project
printf '\n===== PROMPT TÉCNICO DEL DASHBOARD (Qwen programa, Claude supervisa) =====\n\n'
cat planning/orquestacion/PROMPT_DASHBOARD_QWEN.md
for f in ${@:-01_data 02_view 03_main}; do
  printf '\n===== QWEN · %s · %s =====\n' "$f" "$(date +%H:%M:%S)"
  if ! python3 -u encargar_qwen.py planning/qwen-dashboard/$f.json; then
    printf '\n===== QWEN DEVOLVIÓ %s: el supervisor revisará el diagnóstico =====\n' "$f"; exit 1
  fi
done
printf '\n===== DASHBOARD GENERADO POR QWEN · %s · pendiente de verificación del supervisor =====\n' "$(date +%H:%M:%S)"
