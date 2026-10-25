#!/usr/bin/env python3
from pathlib import Path
import subprocess
import time
from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'unity/B17'

def main():
    files=sorted((PROJECT/'Assets/Scripts').rglob('*.cs'))
    context='\n\n'.join('FILE '+str(p.relative_to(PROJECT))+'\n'+p.read_text() for p in files)
    prompt='''Actúa como revisor técnico independiente de nuestro juego B-17 para Unity 6000.3.27f1, pipeline built-in. Responde en español. No uses herramientas, no implementes ni modifiques archivos. Tu tarea es auditar el código real incluido abajo: detectar fallos de compilación y ejecución, contratos incompatibles, errores de vuelo/bombardeo/daños y problemas visuales graves que impidan ver el avión o el terreno. Clasifica hallazgos críticos/altos/medios y cita archivo y método; explica un caso reproducible para cada fallo. No inventes resultados de ejecución. Distingue errores ciertos de riesgos por verificar. Propón encargos pequeños para Qwen. Qwen es autor principal; Codex integra y comprueba. No reabras la elección del motor: Godot solo fue prototipo y Unity es el destino final. Controles y mando se dejan al final por instrucción del usuario. No generar arte de pago. Meta completa: juego estéticamente detallado y con buena jugabilidad; una misión original con formación, amenazas, bombardeo y regreso. El editor acaba de instalarse; compilación y licencia siguen por comprobar. Máximo 1400 palabras.\n\n'''+context
    folder=ROOT/'logs/claude-unity'
    folder.mkdir(exist_ok=True)
    stamp=time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
    (folder/(stamp+'.request.txt')).write_text(prompt)
    target=ROOT/'planning/REVISION_UNITY_CLAUDE.md'
    state('claude','revisando código real Unity; máximo 180 segundos')
    print('Claude está revisando '+str(len(files))+' archivos; salida: '+str(target),flush=True)
    with target.open('w') as out, (folder/(stamp+'.stderr.txt')).open('w') as err:
        result=subprocess.run(['claude','--safe-mode','-p','--tools','','--output-format','text',prompt],stdout=out,stderr=err,timeout=180)
    print(target.read_text(),flush=True)
    state('claude','revisión recibida; pendiente de evaluar' if result.returncode==0 and target.stat().st_size else 'consulta fallida',exit_code=result.returncode)

if __name__=='__main__':
    try: main()
    except subprocess.TimeoutExpired:
        state('claude','BLOQUEADO',error='La revisión excedió 180 segundos sin respuesta; no se recibieron conclusiones.')
        raise SystemExit(1)
    except Exception as exc:
        state('claude','BLOQUEADO',error=str(exc))
        raise SystemExit(1)
