from pathlib import Path
import argparse,fcntl,shlex,subprocess,sys,time
ROOT=Path(__file__).resolve().parent
parser=argparse.ArgumentParser();parser.add_argument('--terminal',action='store_true');parser.add_argument('--check',action='store_true');parser.add_argument('--probar-mando',action='store_true',help='Diagnóstico de mando: muestra los botones y ejes que recibe el juego');args=parser.parse_args()
engine=ROOT/'tools/godot';project=ROOT/'godot/B17'
if not engine.is_file() or not (project/'project.godot').is_file():raise SystemExit('Falta el motor o el proyecto Godot.')
if args.check:print('Godot y misión actual disponibles.');raise SystemExit(0)
if args.probar_mando:
    if not (project/'tools/probar_mando.gd').is_file():raise SystemExit('Esta versión no incluye el diagnóstico de mando.')
    print('Diagnóstico de mando: pulsa botones y mueve los sticks. ESC (o Vista + Menú 2 s) para salir.',flush=True)
    raise SystemExit(subprocess.call([str(engine),'--path',str(project),'--resolution','1280x720','--script','res://tools/probar_mando.gd'],cwd=ROOT))
(ROOT/'logs').mkdir(exist_ok=True)
if args.terminal:
    lock=(ROOT/'logs/game-visible.lock').open('a')
    try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    except BlockingIOError:raise SystemExit('La misión ya está abierta por este lanzador.')
    print('Aurora sobre Europa — misión en desarrollo. ESC/P pausa; R reinicia.',flush=True)
    # Ejecutar el juego no importa recursos: sin .godot/imported o con assets más nuevos que la última importación, importar antes.
    stamp=project/'.godot/b17_import.stamp'
    newest=max(p.stat().st_mtime for p in (project/'assets').rglob('*') if p.is_file() and not p.name.endswith('.import'))
    if not (project/'.godot/imported').is_dir() or not stamp.is_file() or stamp.stat().st_mtime<newest:
        print('Importando modelos y texturas (solo la primera vez o tras cambios)…',flush=True)
        # Godot 4.7 aborta a veces al cerrar el editor tras una importación en frío (≈1 de 12 en esta máquina): un reintento basta.
        for attempt in (1,2):
            ok=subprocess.call([str(engine),'--headless','--path',str(project),'--import'],cwd=ROOT)==0 and (project/'.godot/imported').is_dir()
            if ok:break
            print('La importación terminó con error; reintentando una vez…',flush=True)
        if not ok:raise SystemExit('La importación de recursos falló dos veces; ver la consola.')
        stamp.touch()
    raise SystemExit(subprocess.call([str(engine),'--path',str(project)],cwd=ROOT))
command=shlex.join([sys.executable,'-u',str(Path(__file__).resolve()),'--terminal'])
inner=shlex.join(['script','-q','-e','-f','-c',command,str(ROOT/'logs'/('game-'+str(int(time.time()))+'.console.log'))])
subprocess.Popen(['xfce4-terminal','--disable-server','--hold','--title','B17 — AURORA SOBRE EUROPA','--command',inner],start_new_session=True)
print('Ventana y consola de la misión solicitadas.')
