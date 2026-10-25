#!/usr/bin/env python3
"""Puente Agy→Qwen local, con bloqueo compartido, respaldo y verificación Godot."""
from pathlib import Path
import argparse,fcntl,hashlib,json,os,re,subprocess,time,urllib.request
ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'godot/B17'
MODEL='qwen2.5-coder:7b-instruct-q4_K_M'
SYSTEM='''You implement exactly ONE complete Godot4.7 GDScript file. Output ONLY code, no markdown. Use GDScript syntax, NEVER C# or JavaScript. Ternary: a if condition else b. Typed array: var items: Array[Node3D] = []. No Math class. Node3D.position, NOT translation. RandomNumberGenerator.seed is a property. BaseMaterial3D.SHADING_MODE_UNSHADED is valid. MeshInstance3D.cast_shadow is an enum. draw_string arguments: font,position,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color. Use explicit types for math locals. No tools or file IO. Do not invent dependencies, stubs or extra classes. Preserve the public contract. Finish the whole file; prefer small readable modules under120lines.'''

def report_event(status,path,evidence):
    target=ROOT/'logs/orquestacion/qwen.log'
    target.parent.mkdir(parents=True,exist_ok=True)
    line=f'[{time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime())}] [QWEN_BRIDGE] [{path}] [{status}] evidencia={evidence}\n'
    descriptor=os.open(target,os.O_WRONLY|os.O_CREAT|os.O_APPEND,0o600)
    try:os.write(descriptor,line.encode())
    finally:os.close(descriptor)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('task');parser.add_argument('--check',action='store_true');args=parser.parse_args()
    task_path=Path(args.task).resolve();task=json.loads(task_path.read_text())
    target=(PROJECT/task['path']).resolve()
    if not target.is_relative_to(PROJECT.resolve()) or target.suffix != '.gd':
        raise ValueError('Destino fuera del código Godot permitido')
    if args.check:
        print(json.dumps({'task':str(task_path),'target':str(target),'model':MODEL,'inference':False}));return
    folder=ROOT/'logs/agy-qwen'/(time.strftime('%Y%m%dT%H%M%S',time.gmtime())+'-'+str(time.time_ns()));folder.mkdir(parents=True,exist_ok=False)
    with (ROOT/'logs/godot-art.lock').open('a') as lock:
        print('Esperando al ejecutor compartido de Qwen...',flush=True);fcntl.flock(lock,fcntl.LOCK_EX)
        return run_task(task,target,folder)

def run_task(task,target,folder):
    original=target.read_bytes() if target.exists() else None
    if original is not None:(folder/'original.gd').write_bytes(original)
    (folder/'task.json').write_text(json.dumps(task,ensure_ascii=False,indent=2))
    report_event('EN_EJECUCION',task['path'],folder/'task.json')
    messages=[{'role':'system','content':SYSTEM},{'role':'user','content':task['brief']}]
    target.parent.mkdir(parents=True,exist_ok=True)
    for attempt in range(1,4):
        code='';candidate_written=False
        print(f'Qwen {task["path"]}: intento {attempt}/3',flush=True)
        payload={'model':MODEL,'messages':messages,'stream':False,'keep_alive':'0s','options':{'num_ctx':6144,'num_predict':3200,'temperature':0.05,'seed':1944}}
        req=urllib.request.Request('http://127.0.0.1:11435/api/chat',data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
        try:
            with urllib.request.urlopen(req,timeout=360) as response:answer=json.load(response)
            (folder/f'{attempt}.response.json').write_text(json.dumps(answer,ensure_ascii=False,indent=2))
            code=answer['message']['content'].strip();code=re.sub(r'^```(?:gdscript)?\s*','',code);code=re.sub(r'\s*```$','',code)
            if not code or len(code)>100000:raise ValueError('Respuesta vacía o demasiado grande')
            target.write_text(code+'\n')
            candidate_written=True
            command=[str(ROOT/'tools/godot'),'--headless','--path',str(PROJECT),'--script','res://'+task['path'],'--check-only']
            checked=subprocess.run(command,capture_output=True,text=True,timeout=60)
            report=checked.stdout+checked.stderr
            if checked.returncode or 'SCRIPT ERROR' in report or '\nERROR:' in report:raise ValueError(report)
            test=task.get('test')
            if test:
                test_path=(PROJECT/test).resolve()
                if not test_path.is_relative_to(PROJECT.resolve()) or not test_path.is_file():raise ValueError('Prueba inválida o inexistente')
                checked=subprocess.run([str(ROOT/'tools/godot'),'--headless','--path',str(PROJECT),'--script','res://'+test],capture_output=True,text=True,timeout=180)
                report+=checked.stdout+checked.stderr
                if checked.returncode or 'SCRIPT ERROR' in report or '\nERROR:' in report or 'TEST FAIL' in report or 'TEST PASS' not in report:raise ValueError(report)
            (folder/f'{attempt}.check.log').write_text(report)
            result={'status':'accepted_for_review','path':task['path'],'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'attempt':attempt,'test':test,'log':str(folder)}
            (folder/'result.json').write_text(json.dumps(result,indent=2))
            report_event('ENTREGADO_PARA_REVISION',task['path'],folder/'result.json')
            print(json.dumps(result),flush=True);return
        except Exception as exc:
            report=str(exc);(folder/f'{attempt}.failure.log').write_text(report)
            if candidate_written and target.exists():(folder/f'{attempt}.candidate.gd').write_bytes(target.read_bytes())
            if original is not None:target.write_bytes(original)
            elif target.exists():target.unlink()
            print(report[-3500:],flush=True)
            if isinstance(exc,(TimeoutError,urllib.error.URLError)):
                (folder/'result.json').write_text(json.dumps({'status':'blocked','path':task['path'],'reason':type(exc).__name__+': '+report}))
                report_event('BLOQUEADO',task['path'],folder/'result.json')
                raise
            messages.extend([{'role':'assistant','content':code},{'role':'user','content':'Correct the COMPLETE file. Keep the contract. Literal Godot diagnostic:\n'+report[-3500:]}])
    (folder/'result.json').write_text(json.dumps({'status':'needs_review','path':task['path']}))
    report_event('DEVUELTO_TRAS_TRES_INTENTOS',task['path'],folder/'result.json')
    raise SystemExit(1)
if __name__=='__main__':main()
