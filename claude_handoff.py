#!/usr/bin/env python3
"""Abre un relevo visible y persistente, sin afirmar recepción por adelantado."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import time
import uuid

ROOT=Path(__file__).resolve().parent
PROMPT=ROOT/'planning/PROMPT_RELEVO_CLAUDE.md'
LOGS=ROOT/'logs/handoff'

def check():
    failures=[]
    for name in ['claude','python3']:
        if not shutil.which(name): failures.append('No está disponible: '+name)
    for path in [PROMPT,ROOT/'godot/B17/project.godot',ROOT/'tools/godot']:
        if not path.is_file(): failures.append('Falta: '+str(path))
    if failures:
        raise RuntimeError('\n'.join(failures))
    print('Dependencias y rutas del relevo comprobadas. No se inició Claude.',flush=True)

def write_state(data):
    target=LOGS/'latest.json'
    temp=target.with_suffix('.tmp')
    temp.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    temp.replace(target)

def open_terminal():
    terminal=shutil.which('xfce4-terminal')
    if not terminal or not (os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY')):
        raise RuntimeError('Ejecuta bash delegar_a_claude.sh --terminal desde una terminal de tu escritorio.')
    if not shutil.which('script'):
        raise RuntimeError('Falta script, necesario para guardar la transcripción visible.')
    LOGS.mkdir(parents=True,exist_ok=True)
    stamp=time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
    command=shlex.join([sys.executable,'-u',str(Path(__file__).resolve())])
    transcript=str(LOGS/('claude-'+stamp+'.console.log'))
    inner=shlex.join(['script','-q','-e','-f','-c',command,transcript])
    print('Abriendo consola de Claude. Registro: '+transcript,flush=True)
    subprocess.run([terminal,'--disable-server','--title','B17 — CLAUDE ORQUESTADOR','--hold','--command',inner],check=True)

def run():
    check()
    if not sys.stdin.isatty():
        raise RuntimeError('El relevo interactivo necesita una terminal visible. Usa delegar_a_claude.sh sin opciones.')
    LOGS.mkdir(parents=True,exist_ok=True)
    lock=(LOGS/'orchestrator.lock').open('w')
    try:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    except BlockingIOError:
        print('Ya hay un relevo de Claude activo. No se abrirá un segundo orquestador.',flush=True)
        return
    session=str(uuid.uuid4())
    prompt=PROMPT.read_text()
    data={'session_id':session,'started_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'status':'starting','prompt_file':str(PROMPT),'receipt_file':str(ROOT/'planning/CLAUDE_RECEPCION.md')}
    write_state(data)
    print('Claude asumirá el relevo al leer el prompt y escribir CLAUDE_RECEPCION.md.',flush=True)
    print('Sesión para reanudar: claude --resume '+session,flush=True)
    print('Permisos: modo auto con herramientas explícitas y archivos confinados al proyecto; no se omiten controles.',flush=True)
    command=[shutil.which('claude'),'--safe-mode','--restricted','--permission-mode','auto','--tools','Read,Edit,Write,Glob,Grep,Bash','--strict-mcp-config','--mcp-config','{"mcpServers":{}}','--name','B17-orquestador','--session-id',session,prompt]
    process=subprocess.Popen(command,cwd=ROOT)
    data.update(status='launched_receipt_not_yet_confirmed',pid=process.pid)
    write_state(data)
    try:
        code=process.wait()
    except KeyboardInterrupt:
        process.wait()
        code=process.returncode
    data.update(status='session_process_ended',exit_code=code,ended_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()))
    write_state(data)
    print('La consola de Claude terminó. Su trabajo y recibo deben comprobarse en los archivos indicados.',flush=True)
    raise SystemExit(code)

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--check',action='store_true')
    parser.add_argument('--open-terminal',action='store_true')
    args=parser.parse_args()
    try:
        if args.check: check()
        elif args.open_terminal: open_terminal()
        else: run()
    except Exception as error:
        print('Relevo no iniciado: '+str(error),file=sys.stderr)
        raise SystemExit(1)
