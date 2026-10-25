#!/usr/bin/env python3
"""Comprueba la conexión con Meshy sin generar recursos ni gastar créditos."""
import getpass
import json
import os
import sys
import urllib.error
import urllib.request


def main():
    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key:
        if not sys.stdin.isatty():
            print("Falta MESHY_API_KEY. Ejecuta este archivo en una terminal para introducirla de forma oculta.", file=sys.stderr)
            return 2
        key = getpass.getpass("Clave API de Meshy (oculta, no se guardará): ").strip()
    if not key:
        print("No se introdujo una clave.", file=sys.stderr)
        return 2
    request = urllib.request.Request(
        "https://api.meshy.ai/openapi/v1/balance",
        headers={"Authorization": "Bearer " + key, "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            balance = json.load(response)
        print("Conexión con Meshy verificada.")
        for field in ("balance", "monthly_credits", "permanent_credits"):
            if field in balance:
                print(f"{field}: {balance[field]}")
        return 0
    except urllib.error.HTTPError as error:
        messages = {401: "Clave ausente o inválida.", 403: "Acceso denegado; revisa los permisos o la lista de IP permitidas.", 429: "Límite de solicitudes; inténtalo más tarde."}
        print(f"Meshy HTTP {error.code}: {messages.get(error.code, 'No se pudo verificar la conexión.')}", file=sys.stderr)
    except (urllib.error.URLError, TimeoutError, OSError):
        print("No se pudo conectar: revisa la red y sus restricciones.", file=sys.stderr)
    except (ValueError, TypeError):
        print("Meshy devolvió una respuesta inesperada.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
