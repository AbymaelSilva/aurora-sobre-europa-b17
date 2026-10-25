#!/usr/bin/env python3
"""Lanzador de consolas y ejecución acotada del prototipo autorizado."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent
LOGS = ROOT / 'logs'
TOOLS = ROOT / 'tools'
PROTO = ROOT / 'prototype-godot'
MODEL_ROOT = Path('/run/media/test-bench/38340C17340BD6B2/SentinelX/LLM')
MODEL = 'qwen2.5-coder:7b-instruct-q4_K_M'
API = 'http://127.0.0.1:11435'


def say(message):
    print(message, flush=True)


def state(worker, status, **extra):
    LOGS.mkdir(exist_ok=True)
    path = LOGS / f'{worker}.status.json'
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps({'worker': worker, 'status': status, 'time': time.time(), **extra}, ensure_ascii=False, indent=2))
    temp.replace(path)
    say(f'[{worker}] {status}')


def request(url, body=None, timeout=30):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json', 'User-Agent': 'B17-prototype'})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return json.load(response)


def godot():
    TOOLS.mkdir(exist_ok=True)
    binary = TOOLS / 'godot'
    if binary.exists():
        return str(binary)
    tag = '4.7.2-stable'
    name = f'Godot_v{tag}_linux.x86_64.zip'
    base = f'https://github.com/godotengine/godot-builds/releases/download/{tag}/'
    say('Descargando Godot portátil oficial; sin instalación global ni sudo.')
    with urllib.request.urlopen(base + 'SHA512-SUMS.txt', timeout=40) as response:
        lines = response.read().decode().splitlines()
    expected = next(line.split()[0] for line in lines if line.split()[-1].lstrip('*') == name)
    archive = TOOLS / name
    with urllib.request.urlopen(base + name, timeout=90) as response, archive.open('wb') as output:
        shutil.copyfileobj(response, output)
    if hashlib.sha512(archive.read_bytes()).hexdigest() != expected:
        archive.unlink()
        raise RuntimeError('Falló SHA512 de Godot; no se ejecutará.')
    with zipfile.ZipFile(archive) as source:
        members = [m for m in source.infolist() if not m.is_dir()]
        if len(members) != 1:
            raise RuntimeError('Contenido inesperado en el archivo de Godot.')
        with source.open(members[0]) as src, binary.open('wb') as dst:
            shutil.copyfileobj(src, dst)
    binary.chmod(0o755)
    (TOOLS / 'godot-version.txt').write_text(f'{tag}\nSHA512 {expected}\nFuente {base + name}\n')
    return str(binary)


def serve():
    if not MODEL_ROOT.exists():
        raise RuntimeError('El disco del modelo no está montado.')
    try:
        request(API + '/api/tags', timeout=3)
        state('ollama', 'servicio existente; no se inicia otro')
        return
    except Exception:
        pass
    env = dict(os.environ, OLLAMA_HOST='127.0.0.1:11435', OLLAMA_MODELS=str(MODEL_ROOT), OLLAMA_MAX_LOADED_MODELS='1', OLLAMA_NUM_PARALLEL='1', OLLAMA_CONTEXT_LENGTH='4096')
    state('ollama', 'iniciando servicio local dedicado al modelo existente')
    subprocess.run(['ollama', 'serve'], env=env, check=True)


def qwen():
    state('qwen', 'esperando Ollama; máximo 60 segundos')
    for _ in range(30):
        try:
            tags = request(API + '/api/tags', timeout=2)
            break
        except Exception:
            time.sleep(2)
    else:
        raise RuntimeError('Ollama no responde en 11435; revisar consola Ollama.')
    if MODEL not in [m['name'] for m in tags.get('models', [])]:
        raise RuntimeError('No se encuentra el modelo exacto; no se descargará otro.')
    engine = godot()
    version = subprocess.check_output([engine, '--version'], text=True).strip()
    say('Godot: ' + version)
    project = ROOT / 'prototype-modular'
    if (project / 'MISSION_AUTHORSHIP.json').exists():
        state('qwen', 'comprobando misión existente; no se regenera código')
        result = subprocess.run([engine, '--headless', '--path', str(project), '--script', 'res://test_mission.gd'], capture_output=True, text=True, timeout=60)
        report = result.stdout + result.stderr
        say(report)
        if result.returncode or 'SCRIPT ERROR' in report or '\nERROR:' in report:
            raise RuntimeError('La misión existente falló sus pruebas; se conserva el código para revisión.')
        state('qwen', 'misión comprobada; demostración automática abierta, controles pendientes')
        subprocess.run([engine, '--path', str(project), 'res://mission.tscn'], check=True)
        return
    state('qwen', 'ejecutando encargos por archivo y pruebas de vuelo')
    subprocess.run([sys.executable, '-u', str(ROOT / 'build_modular.py')], check=True)


def review():
    prompt = (ROOT / 'planning/PROMPT_MAESTRO.md').read_text()
    prompt += '\nRevisa este plan en español sin herramientas. Entrega riesgos concretos y aceptación de un prototipo Godot desechable, sin ampliar alcance. Qwen es autor principal. No repitas una comparación extensa de motores; Unity es destino final. No generes código.'
    state('claude', 'consultando revisión, máximo 90 segundos')
    with (LOGS / 'claude-review.txt').open('w') as out:
        result = subprocess.run(['claude', '--safe-mode', '-p', '--tools', '', '--output-format', 'text', prompt], stdout=out, stderr=subprocess.STDOUT, timeout=90)
    say((LOGS / 'claude-review.txt').read_text())
    state('claude', 'respuesta recibida; pendiente de evaluar' if result.returncode == 0 else 'consulta fallida', exit_code=result.returncode)


def agy():
    state('agy', 'ejecutando encargo de inventario y QA')
    result = subprocess.run([sys.executable, str(ROOT / 'planning/consultar_agy.py')], cwd=ROOT, timeout=65)
    state('agy', 'encargo terminado; revisar informe' if result.returncode == 0 else 'encargo bloqueado', exit_code=result.returncode)


def launch():
    if not os.environ.get('DISPLAY') and not os.environ.get('WAYLAND_DISPLAY'):
        raise RuntimeError('Ejecuta el lanzador desde una terminal de tu escritorio.')
    terminal = shutil.which('xfce4-terminal')
    if not terminal:
        raise RuntimeError('No se encontró xfce4-terminal.')
    import shlex
    windows = []
    for worker in ['ollama', 'qwen', 'claude', 'agy']:
        command = shlex.join([sys.executable, '-u', str(Path(__file__).resolve()), '--worker', worker])
        transcript = str(LOGS / (worker + '.console.log'))
        inner = shlex.join(['script', '-q', '-e', '-f', '-c', command, transcript])
        result = subprocess.Popen([terminal, '--disable-server', '--title', 'B17 — ' + worker.upper(), '--hold', '--command', inner])
        windows.append(result)
        time.sleep(0.5)
        if result.poll() not in (None, 0):
            raise RuntimeError('No se pudo abrir la consola ' + worker)
    say('Cuatro consolas solicitadas. Consulta logs/*.status.json para saber qué terminó realmente.')
    state('launcher', 'consolas solicitadas; comprobar estados individuales')
    for window in windows:
        window.wait()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--worker', choices=['ollama', 'qwen', 'claude', 'agy'])
    args = parser.parse_args()
    LOGS.mkdir(exist_ok=True)
    import fcntl
    lock = (LOGS / ((args.worker or 'launcher') + '.lock')).open('w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        say('Esta tarea ya está en ejecución; no se inicia una copia.')
        sys.exit(0)
    try:
        if args.worker:
            {'ollama': serve, 'qwen': qwen, 'claude': review, 'agy': agy}[args.worker]()
        else:
            launch()
    except Exception as exc:
        state(args.worker or 'launcher', 'BLOQUEADO', error=str(exc))
        say(str(exc))
        sys.exit(1)
