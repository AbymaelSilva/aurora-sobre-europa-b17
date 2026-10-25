#!/usr/bin/env python3
"""Ejecuta el encargo acotado de Agy y conserva salida, errores y estado."""
from pathlib import Path
import json
import shutil
import subprocess
from datetime import datetime, timezone

base = Path(__file__).resolve().parent
binary = shutil.which("agy")
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
prefix = base / f"AGY_{stamp}"
state = {"started_utc": stamp, "success": False}
if not binary:
    state["error"] = "Agy no está disponible en PATH"
else:
    context = '\n\n'.join((base / name).read_text() for name in ['AGY_ENCARGO.md', 'DECISIONES.md'])
    prompt = 'MODO ANALISIS SIN HERRAMIENTAS. No ejecutes comandos ni leas o escribas archivos. Todo el contexto necesario está a continuación. Responde solamente con texto, propuestas de QA y recepción de arte. No necesitas permisos para responder. El lanzador guarda tu respuesta. La inspección del inventario en este turno es documental; no afirmes haber ejecutado nada. Esta instrucción limita las tareas de inspección opcionales del contrato siguiente.\n\n' + context
    command = [binary, "--mode", "plan", "--disable-slash-commands", "--print-timeout", "45s", "--output-format", "text", "-p", prompt]
    with Path(str(prefix) + ".txt").open("w") as out, Path(str(prefix) + ".stderr.txt").open("w") as err:
        try:
            result = subprocess.run(command, cwd=base.parent, stdout=out, stderr=err, timeout=55, check=False)
            state["exit_code"] = result.returncode
            state["success"] = result.returncode == 0 and Path(str(prefix) + ".txt").stat().st_size > 0
        except subprocess.TimeoutExpired:
            state["error"] = "Tiempo límite del lanzador agotado"
        except OSError as exc:
            state["error"] = f"No se pudo ejecutar Agy: {exc.strerror}"
Path(str(prefix) + ".status.json").write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(state, ensure_ascii=False))
print(f"Archivos del intento: {prefix}.*")
raise SystemExit(0 if state["success"] else 1)
