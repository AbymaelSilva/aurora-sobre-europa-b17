#!/usr/bin/env python3
"""Hito de bombardeo: Qwen genera módulos; Codex integra y comprueba."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import time
import urllib.request

from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'prototype-modular'
ENGINE=ROOT/'tools/godot'
STAMP=time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
LOG=ROOT/'logs/mission'/STAMP
MODEL='qwen2.5-coder:7b-instruct-q4_K_M'
SYSTEM='''Return ONLY Godot 4 GDScript source, no markdown, no explanation. One file per request. No class_name, no OS, files, networking, @tool. Correct array syntax Array[Vector3], never Vector3[]. Conditional syntax: yes_value if condition else no_value; never ? or boolean and/or for choosing strings. Use explicit types, clampf, minf/maxf. Members used in methods must be declared. Do exactly the small contract, nothing extra.'''
TASKS=[
('bomb_model.gd','''extends RefCounted. Fields active:bool=false, spent:bool=false, position:Vector3=Vector3.ZERO, velocity:Vector3=Vector3.ZERO, result:String="LISTA". reset()->void restores all these fields. release(origin:Vector3,initial_velocity:Vector3)->bool returns false if spent; otherwise set spent=true,active=true,position=origin,velocity=initial_velocity,result="EN_VUELO" and return true. step(delta:float,target:Vector3,radius:float)->void: if not active return; delta=clampf(delta,0,0.05); velocity.y-=9.81*delta; position+=velocity*delta; if position.y<=0 set position.y=0,active=false, calculate horizontal distance Vector2(position.x,position.z).distance_to(Vector2(target.x,target.z)); result="IMPACTO" if distance<=radius else "FALLO". Under 45 lines. This is a pure ballistic module, no nodes or meshes.'''),
('mission_state.gd','''extends RefCounted. Members phase:String="APROXIMACION", waypoint_index:int=0, waypoints:Array[Vector3]=[Vector3(0,100,-250),Vector3(0,100,-500),Vector3(0,100,-700)], target:Vector3=Vector3(0,0,-1000), exit_point:Vector3=Vector3(800,100,-300). reset()->void sets phase="APROXIMACION" and waypoint_index=0. update(aircraft_position:Vector3,bomb_result:String)->void: if phase=="APROXIMACION" and index<waypoints.size() and distance to current waypoint<65: increment index; when all reached phase="BOMBARDEO". If phase=="BOMBARDEO" and bomb_result=="IMPACTO": phase="REGRESO". If phase=="BOMBARDEO" and bomb_result=="FALLO": phase="FALLIDA". If phase=="REGRESO" and distance to exit_point<100: phase="COMPLETADA". navigation_target()->Vector3 returns current waypoint for approach, exit_point for return, otherwise Vector3(target.x,100,target.z-500). No nodes, signals, UI or additional methods. Under 45 lines.'''),
('mission_scenery.gd','''extends Node3D. Only _ready()->void and box(size:Vector3,offset:Vector3,color:Color)->void. box creates MeshInstance3D and BoxMesh, uses BoxMesh.size; StandardMaterial3D.albedo_color; sets mesh.material_override and mesh.position; add_child. _ready makes a simple railway target at z=-1000: two long metal rails boxes size(1,1,240) at x=-6 and +6,y=0.5,z=-1000; station building box(45,15,35) offset(35,7.5,-1000) brown; target orange box(25,5,55) offset(0,2.5,-1000); three blue route marker poles size(4,100,4) at (0,50,-250),(0,50,-500),(0,50,-700); green exit pole size(8,100,8) at(800,50,-300); river box size(1600,.1,50) at(0,.1,-450) blue; two low hills as large boxes size(150,30,180) at(-300,15,-600) and (300,15,-1300) muted green. No arrays, no loops, no engine physics or input. Under 65 lines.''')]


def check(arguments):
    p=subprocess.run([str(ENGINE),'--headless','--path',str(PROJECT),*arguments],capture_output=True,text=True,timeout=60)
    text=p.stdout+p.stderr
    if p.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
        raise ValueError(text)
    return text


def generate(name,prompt):
    messages=[{'role':'system','content':SYSTEM},{'role':'user','content':prompt}]
    for attempt in range(1,4):
        state('qwen',f'misión: {name}, intento {attempt}/3')
        data={'model':MODEL,'messages':messages,'stream':False,'keep_alive':'0s','options':{'num_ctx':4096,'num_predict':1800,'temperature':0.1,'seed':31}}
        (LOG/f'{name}.{attempt}.request.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
        req=urllib.request.Request('http://127.0.0.1:11435/api/chat',data=json.dumps(data).encode(),headers={'Content-Type':'application/json'})
        with urllib.request.urlopen(req,timeout=300) as response:
            answer=json.load(response)
        (LOG/f'{name}.{attempt}.response.json').write_text(json.dumps(answer,ensure_ascii=False,indent=2))
        text=answer['message']['content'].strip()
        text=re.sub(r'^```(?:gdscript)?\s*','',text)
        text=re.sub(r'\s*```$','',text)
        (PROJECT/name).write_text(text+'\n')
        try:
            report=check(['--script','res://'+name,'--check-only'])
            (LOG/f'{name}.{attempt}.check.txt').write_text(report)
            print(report,flush=True)
            return
        except ValueError as exc:
            report=str(exc)
            print(report,flush=True)
            (LOG/f'{name}.{attempt}.check.txt').write_text(report)
            messages.extend([{'role':'assistant','content':text},{'role':'user','content':'Fix only this file. Full source required. Exact diagnostic:\n'+report[-2500:]}])
    raise RuntimeError('Tres intentos agotados: '+name)


def main():
    LOG.mkdir(parents=True,exist_ok=True)
    import fcntl
    lock=(ROOT/'logs/mission.lock').open('w')
    fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    snapshot=ROOT/'snapshots'/('before-mission-'+STAMP)
    snapshot.mkdir(parents=True)
    for file in PROJECT.iterdir():
        if file.is_file(): shutil.copy2(file,snapshot/file.name)
    for name,prompt in TASKS: generate(name,prompt)
    # La escena y el adaptador de integración son responsabilidad de Codex.
    scene=(PROJECT/'main.tscn').read_text().replace('load_steps=7','load_steps=9')
    scene=scene.replace('path="res://main.gd"','path="res://mission_main.gd"')
    scene=scene.replace('[sub_resource type="PlaneMesh"', '[ext_resource type="Script" path="res://mission_scenery.gd" id="4"]\n[sub_resource type="SphereMesh" id="Bomb"]\nradius = 0.8\nheight = 2.0\n[sub_resource type="PlaneMesh"',1)
    scene+='\n[node name="Scenery" type="Node3D" parent="."]\nscript = ExtResource("4")\n[node name="BombVisual" type="MeshInstance3D" parent="."]\nvisible = false\nmesh = SubResource("Bomb")\n'
    (PROJECT/'mission.tscn').write_text(scene)
    report=check(['--editor','--import','--quit'])
    report+=check(['--script','res://test_mission.gd'])
    (LOG/'mission-tests.txt').write_text(report)
    print(report,flush=True)
    state('qwen','ruta y bombardeo comprobados; demostración abierta',project=str(PROJECT/'mission.tscn'))
    (PROJECT/'MISSION_AUTHORSHIP.json').write_text(json.dumps({'qwen_modules':[x[0] for x in TASKS],'integration_and_tests':'Codex','model':MODEL,'tests':str(LOG/'mission-tests.txt'),'controller_work':'deferred by user'},indent=2))
    subprocess.run([str(ENGINE),'--path',str(PROJECT),'res://mission.tscn'],check=True)


if __name__=='__main__':
    try: main()
    except Exception as exc:
        state('qwen','BLOQUEADO',error=str(exc))
        raise SystemExit(1)
