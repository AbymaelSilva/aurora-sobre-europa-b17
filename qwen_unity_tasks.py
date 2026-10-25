#!/usr/bin/env python3
"""Ejecuta encargos C# acotados sin confundir generación con validación."""
from pathlib import Path
import json
import re
import sys
import time
import urllib.request
from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'unity/B17'
MODEL='qwen2.5-coder:7b-instruct-q4_K_M'
SYSTEM='''Return only one COMPLETE C# file, no markdown. Unity 6, built-in rendering pipeline. Use namespace B17. No external packages, OS, file IO, processes, networking, reflection, unsafe, input or editor APIs. Exactly the requested public contract. Use UnityEngine and requested standard-library namespaces. Do not add RequireComponent or ExecuteAlways. GameObject primitive sphere diameter=1, cylinder height=2. When removing primitive Collider: if(Application.isPlaying) Object.Destroy(collider); else Object.DestroyImmediate(collider). Use UnityEngine.Object explicitly if System is imported. Avoid anything outside contract. All geometry is original procedural geometry, no external assets. Keep under 120 lines.'''

def main():
    job=Path(sys.argv[1]).resolve()
    tasks=json.loads(job.read_text())
    log=ROOT/'logs/unity-presentation'/time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
    log.mkdir(parents=True)
    for task in tasks:
        path=(PROJECT/task['path']).resolve()
        if not path.is_relative_to(PROJECT.resolve()): raise ValueError('Ruta fuera del proyecto')
        path.parent.mkdir(parents=True,exist_ok=True)
        if path.exists():
            print('Se conserva '+path.name,flush=True)
            continue
        state('qwen','Unity presentación: '+path.name)
        payload={'model':MODEL,'messages':[{'role':'system','content':SYSTEM},{'role':'user','content':task['prompt']}],'stream':False,'keep_alive':'0s','options':{'num_ctx':4096,'num_predict':3200,'temperature':0.1,'seed':61}}
        (log/(path.name+'.request.json')).write_text(json.dumps(payload,ensure_ascii=False,indent=2))
        request=urllib.request.Request('http://127.0.0.1:11435/api/chat',data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
        with urllib.request.urlopen(request,timeout=300) as response: answer=json.load(response)
        (log/(path.name+'.response.json')).write_text(json.dumps(answer,ensure_ascii=False,indent=2))
        source=answer['message']['content'].strip()
        source=re.sub(r'^```(?:csharp|cs)?\s*','',source)
        source=re.sub(r'\s*```$','',source)
        path.write_text(source+'\n')
        print(path.name+' generado, compilación pendiente.',flush=True)
    state('qwen','archivos de presentación generados; pendiente de compilación')

if __name__=='__main__':
    try: main()
    except Exception as exc:
        state('qwen','BLOQUEADO',error=str(exc))
        raise SystemExit(1)
