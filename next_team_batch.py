#!/usr/bin/env python3
from pathlib import Path
import subprocess,sys,time,shlex,json,os,fcntl
ROOT=Path(__file__).resolve().parent
P=ROOT/'godot/B17'
JOBS=[
('world/rail_target.gd','''extends Node3D. Self-contained original WWII railway freight yard centered on local zero. _ready creates at most80 MeshInstance3D: three parallel tracks along Z spanning500m, sleepers spaced15m, five brick warehouses of differing dimensions, low pitched roofs approximated by rotated boxes, two water tanks using CylinderMesh. Use BoxMesh/CylinderMesh only, reused cached StandardMaterial3D per color. func box(label:String,pos:Vector3,size:Vector3,color:Color)->void creates child mesh. Earth muted brick, charcoal roofs, steel rails. No textures, no dependencies, no collision, no scripts on children. Local ground y=0. Must be visible from1200m altitude. No global positioning or target logic. Under100lines.'''),
('world/cloud_layer.gd','''extends Node3D. Self-contained sparse stylized cloud layer. _ready creates exactly24 MeshInstance3D SphereMesh instances with shared low-poly mesh and one white-gray StandardMaterial3D roughness1; opaque material to avoid expensive alpha sorting. Deterministic positions using RandomNumberGenerator seed1944; x between-10000 and10000,z between-35000 and5000,y between1800and2400; scale Vector3(250..600,60..100,100..250). SphereMesh radius1 height2 radial_segments12 rings6. No dependencies, process callbacks, lights, shadowcasting, networking or textures. Explicit types. Each mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF. Under50lines.'''),
('visuals/flak_burst.gd','''extends Node3D. Self-contained reusable flak puff with max12 spheres, one shared SphereMesh radius1,height2,radial_segments8,rings4; one opaque dark gray StandardMaterial3D roughness1. Fields age:float=0,lifetime:float=4,active:bool=false. _ready builds12 children deterministically positioned in unit sphere with RNGseed17, shadowcastingoff, visible=false. trigger(origin:Vector3)->void sets global_position=origin,age0,active=true,visible=true. advance(delta:float)->void ifnotactive return; age+=maxf(delta,0); scale=Vector3.ONE*(2+age*8); ifage>=lifetime active=false,visible=false. reset()->void sets age0 activefalse visiblefalse scaleONE. No _process, no particles, no dependencies. Under70lines.''')]
def worker(agent):
    lock=(ROOT/'logs'/('extra-'+agent+'.lock')).open('w');fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    folder=ROOT/'logs/extra-team'/agent;folder.mkdir(parents=True,exist_ok=True)
    if agent=='qwen':
        import generate_godot_art as r
        results=[]
        for job in JOBS:
            r.TASKS=[job];r.LOG=folder
            try:
                r.main();results.append({'file':job[0],'status':'syntax_checked'})
            except Exception as exc:
                print('Pendiente de revisión: '+job[0]+': '+str(exc),flush=True)
                results.append({'file':job[0],'status':'needs_review','error':str(exc)})
            (folder/'queue-results.json').write_text(json.dumps(results,indent=2))
        return
    paths=['core/simulation.gd','core/mission.gd','game.gd','combat_main.gd','mission_main.gd','ui/mission_overlay.gd']
    if agent=='agy':
        reports=[]
        for name in ['test_damage_agy.gd','test_mission_states_agy.gd','test_bomb_agy.gd','test_reset_pause_agy.gd','test_long_mission.gd']:
            p=subprocess.run([str(ROOT/'tools/godot'),'--headless','--path',str(P),'--script','res://tests/'+name],capture_output=True,text=True,timeout=90)
            reports.append({'test':name,'exit':p.returncode,'output':p.stdout+p.stderr})
        (folder/'test-results.json').write_text(json.dumps(reports,indent=2))
        prompt='Sin herramientas ni preguntas. Revisa estos resultados reales Godot. Distingue fallo de test, fallo de producto y evidencia insuficiente. Propón hasta5 pruebas de aceptación adicionales concretas. No afirmes haber ejecutado tú. Máximo600palabras.\n'+json.dumps(reports)
        command=['agy','--mode','plan','--disable-slash-commands','--print-timeout','120s','--output-format','text','-p',prompt]
    else:
        context='\n'.join('FILE '+n+'\n'+(P/n).read_text() for n in paths)
        prompt='Sin herramientas ni preguntas. Godot definitivo, Unity cancelado, controles al final. El núcleo largo YA pasó misión13min a30/60/120Hz y reset está corregido. Entrega un plan concreto de integración para reemplazar herencia legacy de game.gd por core/simulation.gd preservando nodos, cámara, HUD, formación y efectos. Enumera contratos exactos y riesgos verificables. No generes archivos ni afirmes ejecución. Máximo1200palabras.\n'+context
        command=['claude','--safe-mode','-p','--tools','','--output-format','text']
    (folder/'request.txt').write_text(prompt)
    with (folder/'response.md').open('w') as out:
        result=subprocess.run(command,input=prompt if agent=='claude' else None,text=True,stdout=out,stderr=subprocess.STDOUT,timeout=180,cwd=ROOT)
    print((folder/'response.md').read_text(),flush=True)
    (folder/'status.json').write_text(json.dumps({'exit':result.returncode,'completed':time.time()}))
def launch():
    for agent in ['qwen','claude','agy']:
        inner=shlex.join(['script','-q','-e','-f','-c',shlex.join([sys.executable,'-u',str(Path(__file__).resolve()),agent]),str(ROOT/'logs'/('extra-'+agent+'.console.log'))])
        subprocess.Popen(['xfce4-terminal','--disable-server','--hold','--title','B17 — '+agent.upper()+' NUEVAS TAREAS','--command',inner],start_new_session=True)
    print('Consolas solicitadas; verificar entregas en logs/extra-team.')
if __name__=='__main__':
    if len(sys.argv)>1:worker(sys.argv[1])
    else:launch()
