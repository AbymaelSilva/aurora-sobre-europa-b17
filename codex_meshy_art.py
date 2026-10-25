#!/usr/bin/env python3
"""Un encargo de geometría Meshy, dirigido por Claude, sin guardar la clave."""
from pathlib import Path
import fcntl
import getpass
import json
import os
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from run_team import state

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'art/meshy/b17-preview-01'
API='https://api.meshy.ai'

def call(key,path,body=None):
    data=json.dumps(body).encode() if body is not None else None
    request=urllib.request.Request(API+path,data=data,headers={'Authorization':'Bearer '+key,'Content-Type':'application/json'})
    with urllib.request.urlopen(request,timeout=60) as response: return json.load(response)

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    lock=(OUT/'worker.lock').open('w')
    fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    promptfile=OUT/'claude-prompt.txt'
    if not promptfile.exists() or not promptfile.stat().st_size:
        state('codex-meshy','Claude prepara especificación de modelo 3D')
        brief='''Write ONE English prompt under700characters for Meshy Text-to-3D, no commentary. Realistic original game-ready B-17G Flying Fortress exterior, exactly4radial piston engines and4propellers, one fuselage, correct long tapered wings and conventional tail, glazed bomber nose, cockpit and upper/ball turrets, landinggear retracted. Neutral symmetric level-flight pose, isolated object, no background, runway, ground, pilot, writing, emblems or extra aircraft. Discrete propellers/engines if supported, clean topology, historically plausible silhouette, olive drab metal. This is for Godot, not Unity. Do not claim generations or outputs.'''
        with promptfile.open('w') as out,(OUT/'claude-stderr.txt').open('w') as err:
            result=subprocess.run(['claude','--safe-mode','-p','--tools','','--output-format','text'],input=brief,text=True,stdout=out,stderr=err,timeout=75)
        if result.returncode or not promptfile.stat().st_size: raise RuntimeError('No se recibió especificación.')
    prompt=promptfile.read_text().strip()
    if not prompt or len(prompt)>800: raise RuntimeError('Prompt de Claude fuera del límite Meshy; revisar antes de gastar.')
    print('Prompt de Codex:\n'+prompt,flush=True)
    print('Encargo: UNA geometría preview Meshy T2.5, 25000 caras objetivo, GLB. Tarifa consultada: 5 créditos. Sin refinado automático.',flush=True)
    state('codex-meshy','esperando clave Meshy en esta consola; aún no se ha creado el modelo')
    key=os.environ.get('MESHY_API_KEY','').strip()
    if not key:
        if not sys.stdin.isatty(): raise RuntimeError('Introduce la clave en una terminal visible, no en el chat.')
        key=getpass.getpass('Clave API Meshy (oculta, no se guardará): ').strip()
    if not key: raise RuntimeError('Clave no introducida; sin generación.')
    balance=call(key,'/openapi/v1/balance')
    print('Conexión verificada. Saldo:',balance.get('balance'),flush=True)
    if balance.get('balance',0)<5: raise RuntimeError('Saldo insuficiente para este preview.')
    saved=OUT/'submission.json'
    if saved.exists():
        job=json.loads(saved.read_text())
        task_id=job.get('task_id')
        if not task_id: raise RuntimeError('Existe una solicitud previa incierta; revisar Meshy antes de enviar otra y duplicar el gasto.')
    else:
        payload={'mode':'preview','prompt':prompt,'model_type':'smart-topology','ai_model':'meshy-t2.5','topology':'triangle','target_polycount':25000,'target_formats':['glb']}
        saved.write_text(json.dumps({'attempted':True,'time':time.time(),'request':payload,'price_checked_credits':5},indent=2))
        result=call(key,'/openapi/v2/text-to-3d',payload)
        task_id=result['result']
        saved.write_text(json.dumps({'task_id':task_id,'time':time.time(),'request':payload,'price_checked_credits':5},indent=2))
    state('codex-meshy','modelo solicitado; Meshy está generando',task_id=task_id)
    print('Tarea Meshy:',task_id,flush=True)
    for _ in range(150):
        job=call(key,'/openapi/v2/text-to-3d/'+urllib.parse.quote(task_id,safe=''))
        (OUT/'latest-task.json').write_text(json.dumps(job,indent=2))
        print('Meshy:',job.get('status'),job.get('progress'),flush=True)
        if job.get('status')=='SUCCEEDED':
            url=job.get('model_urls',{}).get('glb')
            if not url or urllib.parse.urlparse(url).scheme!='https': raise RuntimeError('Falta una descarga GLB HTTPS válida.')
            # Nunca enviar la clave API al CDN de archivos.
            with urllib.request.urlopen(url,timeout=90) as response:
                data=response.read(300*1024*1024+1)
            if len(data)>300*1024*1024 or not data.startswith(b'glTF'): raise RuntimeError('Descarga de modelo inválida.')
            (OUT/'b17-preview.glb').write_bytes(data)
            state('codex-meshy','modelo GLB descargado; pendiente de inspección e integración',path=str(OUT/'b17-preview.glb'))
            print('Modelo guardado:',OUT/'b17-preview.glb',flush=True)
            return
        if job.get('status') in ['FAILED','CANCELED','CANCELLED']:
            raise RuntimeError('Meshy terminó sin modelo; revisar latest-task.json, sin reenvío automático.')
        time.sleep(8)
    state('codex-meshy','tiempo de observación agotado; la tarea remota puede seguir activa',task_id=task_id)

if __name__=='__main__':
    try: main()
    except subprocess.TimeoutExpired:
        state('codex-meshy','BLOQUEADO',error='Claude no respondió dentro del tiempo asignado; no se ha creado otra tarea Meshy.')
        raise SystemExit(1)
    except Exception as exc:
        state('codex-meshy','BLOQUEADO',error=type(exc).__name__+': '+str(exc))
        raise SystemExit(1)
