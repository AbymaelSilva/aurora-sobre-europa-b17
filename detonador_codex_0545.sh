#!/usr/bin/env bash
set -euo pipefail
cd /home/test-bench/Documents/B17-project
exec python3 detonador_codex.py "$@"
