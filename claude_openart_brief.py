#!/usr/bin/env python3
from pathlib import Path
import subprocess
from run_team import state

ROOT=Path(__file__).resolve().parent

def main():
    prompt=(ROOT/'planning/OPENART_CLAUDE_BRIEF_REQUEST.txt').read_text()
    target=ROOT/'planning/OPENART_CLAUDE_PROMPT.txt'
    state('claude','dirección visual: preparando prompt para OpenArt')
    print('Claude prepara el encargo visual para una imagen B-17; no genera ni gasta créditos por sí mismo.',flush=True)
    with target.open('w') as out,(ROOT/'logs/claude-openart.stderr.txt').open('w') as err:
        result=subprocess.run(['claude','--safe-mode','-p','--tools','','--output-format','text'],input=prompt,text=True,stdout=out,stderr=err,timeout=75)
    print(target.read_text(),flush=True)
    if result.returncode or not target.stat().st_size:
        raise RuntimeError('Claude no entregó un prompt válido.')
    state('claude','prompt OpenArt entregado; generación pendiente de Codex')

if __name__=='__main__':
    try: main()
    except subprocess.TimeoutExpired:
        state('claude','sin prompt confirmado',error='Tiempo límite de75s; no se afirma entrega.')
        raise SystemExit(1)
