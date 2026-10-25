from pathlib import Path
import sys,subprocess,shlex,os,fcntl
from datetime import datetime
from zoneinfo import ZoneInfo
ROOT=Path(__file__).resolve().parent
NAME='b17-codex-reactivar-20261024-0545'
THREAD='01a16cd9-41a3-70a1-9a1d-c58fcc39b0b3'
TARGET=datetime(2026,10,24,5,45,tzinfo=ZoneInfo('America/Hermosillo'))
LOG=ROOT/'logs/detonador';LOG.mkdir(parents=True,exist_ok=True)
mode=sys.argv[1] if len(sys.argv)>1 else '--estado'
if mode=='--programar':
    if datetime.now(TARGET.tzinfo)>=TARGET:raise SystemExit('La hora ya pasó; no se programa automáticamente otra fecha.')
    units=Path.home()/'.config/systemd/user';units.mkdir(parents=True,exist_ok=True)
    (units/(NAME+'.service')).write_text(f'''[Unit]
Description=Reanudar consola Codex del proyecto B17
[Service]
Type=simple
WorkingDirectory={ROOT}
Environment=DISPLAY={os.environ.get('DISPLAY',':0')}
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
Environment=PATH=/home/test-bench/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/bash {ROOT}/detonador_codex_0545.sh --fire
Restart=no
''')
    (units/(NAME+'.timer')).write_text(f'''[Unit]
Description=Detonador B17 05:45 Hermosillo
[Timer]
OnCalendar=2026-10-24 05:45:00 America/Hermosillo
AccuracySec=1s
Persistent=true
Unit={NAME}.service
[Install]
WantedBy=timers.target
''')
    subprocess.run(['systemctl','--user','daemon-reload'],check=True)
    subprocess.run(['systemctl','--user','enable','--now',NAME+'.timer'],check=True)
elif mode=='--fire':
    if datetime.now(TARGET.tzinfo)<TARGET:raise SystemExit('Todavía no es la hora; no se invoca Codex.')
    lock=(LOG/'fire.lock').open('w');fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    if (LOG/'submitted').exists():raise SystemExit('Ya se lanzó; no se duplica.')
    prompt='El usuario autorizó reanudar a las05:45 tras la pausa. Continúa el proyecto B17 en Godot. Lee planning/REANUDAR_0545.md, verifica entregas reales de Qwen Claude Agy y continúa integrando y probando. Controles al final. No Unity.'
    command=shlex.join(['/home/test-bench/.local/bin/codex','--no-alt-screen','-C',str(ROOT),'resume',THREAD,prompt])
    inner=shlex.join(['script','-q','-e','-f','-c',command,str(LOG/'codex.console.log')])
    process=subprocess.Popen(['xfce4-terminal','--disable-server','--hold','--title','B17 — CODEX REANUDADO 05:45','--command',inner])
    (LOG/'submitted').write_text(datetime.now(TARGET.tzinfo).isoformat())
    raise SystemExit(process.wait())
elif mode=='--cancelar':
    subprocess.run(['systemctl','--user','disable','--now',NAME+'.timer'],check=True)
    raise SystemExit(0)
elif mode=='--check':
    assert (ROOT/'godot/B17/project.godot').is_file()
    assert Path('/home/test-bench/.local/bin/codex').exists()
    print('Rutas comprobadas. No se invocó ningún modelo. Objetivo:',TARGET.isoformat());raise SystemExit(0)
subprocess.run(['systemctl','--user','show',NAME+'.timer','--property=ActiveState,NextElapseUSecRealtime'],check=True)
