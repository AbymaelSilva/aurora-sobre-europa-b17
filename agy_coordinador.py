#!/usr/bin/env python3
"""Supervisor visible: Agy coordina Qwen; conserva checkpoint y verifica candidatos."""
from pathlib import Path
import argparse,fcntl,hashlib,json,os,selectors,shlex,shutil,signal,subprocess,sys,time
ROOT=Path(__file__).resolve().parent
PROMPT=ROOT/'planning/META_AGY_COORDINADOR.md'
LOG=ROOT/'logs/agy-coordinador'
STATE=LOG/'status.json'
EVENT_LOG=ROOT/'logs/orquestacion/runtime.log'

def event(status,message,evidence=None):
    """Eventos operativos; nunca representan aceptación del juego."""
    EVENT_LOG.parent.mkdir(parents=True,exist_ok=True)
    line=f'[{time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime())}] [AGY_RUNTIME] [{status}] {message}'
    if evidence: line+=' | evidencia='+str(evidence)
    descriptor=os.open(EVENT_LOG,os.O_WRONLY|os.O_CREAT|os.O_APPEND,0o600)
    try: os.write(descriptor,(line+'\n').encode())
    finally: os.close(descriptor)

def write_state(**data):
    LOG.mkdir(parents=True,exist_ok=True)
    data['updated_utc']=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())
    temp=STATE.with_suffix('.tmp');temp.write_text(json.dumps(data,ensure_ascii=False,indent=2));temp.replace(STATE)
def check():
    for name in ['agy','python3','xfce4-terminal','script']:
        if not shutil.which(name):raise RuntimeError('Falta '+name)
    for path in [PROMPT,ROOT/'encargar_qwen.py',ROOT/'tools/godot',ROOT/'godot/B17/project.godot']:
        if not path.is_file():raise RuntimeError('Falta '+str(path))
    print('Lanzador y dependencias disponibles; no se ha invocado ningún modelo.',flush=True)
def fingerprint():
    digest=hashlib.sha256()
    for path in sorted((ROOT/'godot/B17').rglob('*')):
        if path.suffix in ['.gd','.gdshader','.tscn','.godot'] and '.godot' not in path.relative_to(ROOT/'godot/B17').parts:
            digest.update(str(path.relative_to(ROOT)).encode());digest.update(path.read_bytes())
    return digest.hexdigest()

def progress_snapshot():
    """Código y evidencia nueva; no cuenta recibos, textos libres o logs de charla."""
    evidence=set()
    for path in (ROOT/'logs/agy-qwen').glob('*/result.json'):
        try:
            result=json.loads(path.read_text())
            if result.get('status')=='accepted_for_review' and result.get('sha256'):
                evidence.add(('qwen',result.get('path',''),result['sha256']))
        except (OSError,ValueError): continue
    for base in [ROOT/'logs/orquestacion',ROOT/'logs/revision_claude']:
        for path in base.rglob('*.log'):
            if 'console' in path.name or path.name in ['agy.log','qwen.log','claude.log','codex_entrega.log','runtime.log','supervisor.log']:
                continue
            try:
                outcome=[line for line in path.read_text(errors='replace').splitlines()
                         if any(token in line for token in ['TEST PASS','TEST FAIL','SCRIPT ERROR','ObjectDB instances were leaked'])]
            except OSError: continue
            if outcome:
                evidence.add(('qa',hashlib.sha256('\n'.join(outcome).encode()).hexdigest()))
    return fingerprint(),frozenset(evidence)

def next_round_state(agent_state,changed,stale):
    if agent_state.get('status') in ['awaiting_review','waiting_review']:
        return 'awaiting_review',stale
    stale=0 if changed else stale+1
    return ('needs_supervisor_attention' if stale>=2 else 'continuing'),stale

def verify_candidate(since=None):
    source_before=fingerprint()
    results=[]
    for name in ['tests/test_long_mission.gd','tests/test_scene_mission.gd','tests/test_qwen_assets.gd','tests/test_claude_batch.gd','tests/test_release_acceptance.gd','tests/test_claude_review.gd','tests/test_imported_aircraft_integration.gd','tests/test_local_control_directions.gd','tests/test_manual_mission_claude.gd']:
        if not (ROOT/'godot/B17'/name).is_file():results.append({'test':name,'passed':False,'output':'No existe'});continue
        try:
            p=subprocess.run([str(ROOT/'tools/godot'),'--headless','--path',str(ROOT/'godot/B17'),'--script','res://'+name],capture_output=True,text=True,timeout=600)
            output=p.stdout+p.stderr
            passed=p.returncode==0 and 'TEST PASS' in output and all(x not in output for x in ['TEST FAIL','SCRIPT ERROR','\nERROR:','ObjectDB instances were leaked'])
            results.append({'test':name,'passed':passed,'exit':p.returncode,'output':output})
        except subprocess.TimeoutExpired:
            results.append({'test':name,'passed':False,'output':'Tiempo máximo agotado; prueba sin aceptación.'})
    source_after=fingerprint()
    results.append({'test':'candidate_sources_unchanged','passed':source_before==source_after,'before':source_before,'after':source_after})
    acceptance=ROOT/'planning/AGY_ACEPTACION.md'
    fresh=acceptance.is_file() and (since is None or acceptance.stat().st_mtime>=since)
    results.append({'test':'current_acceptance_document','passed':fresh,'path':str(acceptance)})
    (LOG/'candidate-verification.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
    return all(r['passed'] for r in results)
def run():
    check();LOG.mkdir(parents=True,exist_ok=True)
    with (LOG/'coordinator.lock').open('a') as lock:
        try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:print('Ya hay un coordinador Agy activo.');return
        return run_rounds()

def run_rounds():
    stale=0;round_number=0
    while True:
        round_number+=1;before=progress_snapshot()
        prompt=PROMPT.read_text()+f'\n\nRonda del supervisor: {round_number}. Ejecuta trabajo concreto ahora. Lee planning/orquestacion/AGY_AVANCE.md si existe y continúa desde el PRIMER PENDIENTE; no repitas entregas idénticas ya comprobadas. No basta con un plan. Actualiza planning/AGY_ESTADO.json al terminar esta ronda. Si dependes de revisión externa sin otro trabajo independiente, usa status awaiting_review y describe la dependencia. El supervisor conserva registros y comprueba cualquier candidato.\n'
        if round_number>1:prompt+='Mira logs/agy-coordinador/candidate-verification.json si existe para corregir regresiones detectadas.\n'
        command=['agy','--mode','accept-edits','--disable-slash-commands','--print-timeout','1800s','--output-format','stream-json','-p',prompt]
        transcript=LOG/f'round-{round_number:03d}-{int(time.time())}.log'
        print(f'\nAGY COORDINADOR — RONDA {round_number}\nRegistro: {transcript}',flush=True)
        event('RONDA_INICIADA',f'Ronda {round_number}; no representa trabajo terminado.',transcript)
        round_started=time.time()
        process=subprocess.Popen(command,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,start_new_session=True)
        context=dict(status='running',pid=process.pid,supervisor_pid=os.getpid(),round=round_number,log=str(transcript),goal_file=str(PROMPT))
        def publish_state(**updates):
            context.update(updates)
            context['heartbeat_utc']=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())
            write_state(**context)
        publish_state()
        selector=selectors.DefaultSelector();selector.register(process.stdout,selectors.EVENT_READ)
        deadline=time.monotonic()+1860
        pending=b""
        conversation_id=None
        result_status=None
        shown=set()
        heartbeat_due=time.monotonic()+30
        def display_line(raw):
            nonlocal conversation_id,result_status
            try: event=json.loads(raw)
            except (ValueError,UnicodeError):
                print(raw.decode(errors="replace"),flush=True);return
            kind=event.get("event")
            if kind=="init":
                conversation_id=event.get("conversation_id")
                print("Sesión Agy: "+str(conversation_id),flush=True)
                publish_state(conversation_id=conversation_id)
            elif kind=="step_update":
                step=event.get("step_update",{})
                if step.get("step_type")=="tool":
                    index=step.get("step_index")
                    info=step.get("tool_info",{})
                    name=step.get("tool_name",info.get("name","herramienta"))
                    if index not in shown:
                        shown.add(index)
                        parameters=info.get("parameters",{})
                        target=parameters.get("CommandLine",parameters.get("TargetFile",parameters.get("AbsolutePath","")))
                        print("\n[AGY] "+name+(": "+str(target)[:700] if target else ""),flush=True)
                    if step.get("state") in ["DONE","ERROR"]:
                        output=info.get("output","")
                        if name=="run_command" and output: print(str(output)[-3500:],flush=True)
                        if info.get("error"):print("Error: "+str(info["error"]),flush=True)
                    publish_state(last_tool=name,last_activity_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()))
                elif step.get("step_type")=="agent_response" and step.get("text_delta"):
                    print(step["text_delta"],end="",flush=True)
            elif kind=="result":
                result_status=event.get("result",{}).get("status")
                print("\nResultado de ronda: "+str(result_status),flush=True)
        with transcript.open('wb') as out:
            while selector.get_map():
                if time.monotonic()>=heartbeat_due:
                    publish_state(child_alive=process.poll() is None)
                    heartbeat_due=time.monotonic()+30
                if time.monotonic()>deadline:
                    os.killpg(process.pid,signal.SIGTERM)
                    try:process.wait(timeout=10)
                    except subprocess.TimeoutExpired:os.killpg(process.pid,signal.SIGKILL)
                    process.wait()
                    selector.close();process.stdout.close()
                    write_state(status='blocked',reason='Tiempo máximo de una ronda agotado; revisar checkpoint.',round=round_number)
                    event('BLOQUEADO',f'Ronda {round_number}: tiempo máximo agotado.',transcript)
                    return
                for key,_ in selector.select(timeout=5):
                    chunk=os.read(key.fileobj.fileno(),65536)
                    if not chunk:selector.unregister(key.fileobj);continue
                    out.write(chunk);out.flush();pending+=chunk
                    while b"\n" in pending:
                        line,pending=pending.split(b"\n",1)
                        if line.strip():display_line(line)
            if pending.strip():display_line(pending)
            code=process.wait()
        selector.close()
        process.stdout.close()
        failure_text=transcript.read_text(errors='replace')
        if 'no output produced' in failure_text or 'headless mode cannot prompt' in failure_text:
            event('BLOQUEADO','Permiso no cubierto; sin reintento ciego.',transcript)
            write_state(status='blocked',round=round_number,reason='Permiso no cubierto; revisar regla específica, sin repetir llamadas.',log=str(transcript));return
        if result_status and result_status!='SUCCESS':
            event('BLOQUEADO','Resultado CLI '+str(result_status),transcript)
            write_state(status='blocked',round=round_number,result_status=result_status,log=str(transcript));return
        if code:
            event('BLOQUEADO','Agy terminó con código '+str(code),transcript)
            write_state(status='blocked',round=round_number,exit_code=code,reason='Agy terminó con error. Ver registro; no se reintenta ciegamente.',log=str(transcript));return
        path=ROOT/'planning/AGY_ESTADO.json'
        try:agent_state=json.loads(path.read_text()) if path.exists() and path.stat().st_mtime>=round_started else {}
        except (ValueError,OSError):agent_state={}
        if agent_state.get('status')=='blocked':
            event('BLOQUEADO','El agente informó un bloqueo; revisar su checkpoint.',path)
            write_state(status='blocked',round=round_number,agent_report=agent_state);return
        if agent_state.get('status')=='candidate_complete':
            if verify_candidate(since=round_started):
                write_state(status='candidate_ready_for_review',round=round_number,verification=str(LOG/'candidate-verification.json'))
                print('Candidato con pruebas pasadas; requiere revisión final. No se anuncia juego terminado automáticamente.',flush=True);return
            print('El candidato falló verificaciones. Agy recibirá los diagnósticos y continuará.',flush=True)
        changed=progress_snapshot()!=before
        next_status,stale=next_round_state(agent_state,changed,stale)
        if next_status=='awaiting_review':
            event('ESPERANDO_REVISION','Entrega pendiente de revisión externa; no se marca bloqueada ni completa.',path)
            write_state(status=next_status,round=round_number,agent_report=agent_state);return
        if next_status=='needs_supervisor_attention':
            event('REQUIERE_SUPERVISOR','Dos rondas sin código ni evidencia QA nueva; evitar repetir encargos.',transcript)
            write_state(status=next_status,round=round_number,reason='Dos rondas sin cambios ni evidencia nueva; revisar secuencia antes de gastar más.',log=str(transcript));return
        event('RONDA_TERMINADA',f'Ronda {round_number}; progreso material/evidencia nueva={changed}; candidato no aceptado.',transcript)
        write_state(status='continuing',round=round_number,progress_detected=changed,unchanged_rounds=stale)
def open_terminal():
    LOG.mkdir(parents=True,exist_ok=True)
    command=shlex.join([sys.executable,'-u',str(Path(__file__).resolve()),'--terminal'])
    inner=shlex.join(['script','-q','-e','-f','-c',command,str(LOG/('console-'+str(int(time.time()))+'.log'))])
    p=subprocess.Popen(['xfce4-terminal','--disable-server','--hold','--title','B17 — AGY COORDINA QWEN · META JUEGO COMPLETO','--command',inner],start_new_session=True)
    print('Consola solicitada; PID de terminal:',p.pid,flush=True)
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');parser.add_argument('--terminal',action='store_true');parser.add_argument('--estado',action='store_true');args=parser.parse_args()
    try:
        if args.check:check()
        elif args.estado:print(STATE.read_text() if STATE.exists() else 'No iniciado')
        elif args.terminal:run()
        else:check();open_terminal()
    except Exception as exc:
        write_state(status='blocked',reason=type(exc).__name__+': '+str(exc));print(str(exc),file=sys.stderr);raise SystemExit(1)
