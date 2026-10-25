#!/usr/bin/env bash
set -euo pipefail

# Directorio raíz del proyecto B17
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Asegurar que agy está en el PATH
export PATH="$HOME/.local/bin:$PATH"

if ! command -v agy >/dev/null 2>&1; then
  echo "ERROR: No se encontró 'agy' en el PATH ni en ~/.local/bin" >&2
  exit 1
fi

PROMPT_FILE="$PROJECT_ROOT/mis_tareas_prompt.txt"
if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "ERROR: No existe el archivo de prompt: $PROMPT_FILE" >&2
  exit 1
fi

case "${1:-}" in
  --terminal)
    # Abre una nueva ventana de terminal independiente ejecutando Agy
    echo "Abriendo Agy en una nueva terminal..."
    exec xfce4-terminal \
      --title="B17 — AGY SUPERVISOR" \
      --working-directory="$PROJECT_ROOT" \
      --hold \
      --command="bash -c 'agy --dangerously-skip-permissions --mode auto -p \"\$(cat mis_tareas_prompt.txt)\"'"
    ;;
  --interactive|-i)
    # Ejecuta el prompt de forma interactiva en la terminal actual
    echo "Iniciando Agy en modo interactivo..."
    exec agy --dangerously-skip-permissions --mode auto -i "$(cat "$PROMPT_FILE")" "${@:2}"
    ;;
  *)
    # Ejecución por defecto solicitada: no interactiva / print turn
    echo "Ejecutando Agy con el prompt adaptado..."
    exec agy --dangerously-skip-permissions --mode auto -p "$(cat "$PROMPT_FILE")" "$@"
    ;;
esac
