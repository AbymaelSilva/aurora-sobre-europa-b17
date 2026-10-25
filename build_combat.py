#!/usr/bin/env python3
"""Encargos de formación y antiaérea para Qwen, con validación."""
from pathlib import Path
import json
import shutil
import subprocess
import time
import build_mission as worker
from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'prototype-modular'
TASKS=[
('damage_model.gd','''extends RefCounted. Fields hull:float=100.0 and engine:float=100.0. reset()->void restores both to100. apply_damage(amount:float)->void: amount=maxf(amount,0.0); hull=clampf(hull-amount,0,100); engine=clampf(engine-amount*1.5,0,100). destroyed()->bool returns hull<=0.0. thrust_factor()->float returns 0.5+0.5*engine/100. No nodes, no signals, no arrays. Under 25 lines.'''),
('flak_model.gd','''extends RefCounted. Fields timer:float=0, interval:float=1.2, bursts:int=0. reset()->void sets timer=0 and bursts=0. step(delta:float,in_zone:bool)->bool: if not in_zone set timer=0 and return false. Otherwise add clampf(delta,0,.05) to timer; if timer>=interval subtract interval once, increment bursts,return true; otherwise return false. No RNG, nodes, arrays or extra features. Under 25 lines.'''),
('formation.gd','''extends Node3D. Two member vars left:Node3D and right:Node3D. _ready()->void creates each using preload("res://aircraft.gd").new() and add_child. follow(leader_position:Vector3,yaw:float,pitch:float)->void: left.position=leader_position+Vector3(-38,6,22).rotated(Vector3.UP,yaw); right.position=leader_position+Vector3(38,6,22).rotated(Vector3.UP,yaw); both rotation=Vector3(pitch,yaw,0). Geometry is supplied by aircraft.gd. No automatic processing, no arrays, no input or classes. Under 25 lines.'''),
('flak_visual.gd','''extends Node3D. Member age:float=10.0 and clouds:Array[MeshInstance3D]=[]. _ready()->void creates six MeshInstance3D in range(6): each SphereMesh radius1.8,height3.6; each StandardMaterial3D albedo_color=Color(.08,.08,.08), mesh.material_override=material; add_child; mesh.visible=false; clouds.append(mesh). burst(center:Vector3)->void: age=0; for i in range(clouds.size()): clouds[i].position=center+Vector3(float(i%3-1)*18,float(i%2)*12-6,float(i-3)*11); clouds[i].visible=true. step(delta:float)->void: age+=maxf(delta,0); for cloud in clouds: cloud.visible=age<1.8; cloud.scale=Vector3.ONE*(1+minf(age,1.8)*1.8). No physics or autoprocess, no randomness, no arrays with Type[] syntax. Under 45 lines.''')]

def main():
    stamp=time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
    worker.LOG=ROOT/'logs/combat'/stamp
    worker.LOG.mkdir(parents=True,exist_ok=True)
    import fcntl
    lock=(ROOT/'logs/combat.lock').open('w')
    fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    snapshot=ROOT/'snapshots'/('before-combat-'+stamp)
    snapshot.mkdir(parents=True)
    for source in PROJECT.iterdir():
        if source.is_file(): shutil.copy2(source,snapshot/source.name)
    for name,prompt in TASKS: worker.generate(name,prompt)
    scene=(PROJECT/'mission.tscn').read_text().replace('load_steps=9','load_steps=11').replace('res://mission_main.gd','res://combat_main.gd')
    scene=scene.replace('[sub_resource type="SphereMesh"','[ext_resource type="Script" path="res://formation.gd" id="5"]\n[ext_resource type="Script" path="res://flak_visual.gd" id="6"]\n[sub_resource type="SphereMesh"',1)
    scene+='\n[node name="Formation" type="Node3D" parent="."]\nscript = ExtResource("5")\n[node name="FlakVisual" type="Node3D" parent="."]\nscript = ExtResource("6")\n'
    (PROJECT/'combat.tscn').write_text(scene)
    report=worker.check(['--editor','--import','--quit'])
    report+=worker.check(['--script','res://test_combat.gd'])
    (worker.LOG/'combat-tests.txt').write_text(report)
    print(report,flush=True)
    (PROJECT/'COMBAT_AUTHORSHIP.json').write_text(json.dumps({'qwen_modules':[x[0] for x in TASKS],'integration_and_tests':'Codex','controls':'unchanged/deferred','tests':str(worker.LOG/'combat-tests.txt')},indent=2))
    state('qwen','formación, antiaérea y daño comprobados; demostración abierta')
    subprocess.run([str(worker.ENGINE),'--path',str(PROJECT),'res://combat.tscn'],check=True)

if __name__=='__main__':
    try: main()
    except Exception as exc:
        state('qwen','BLOQUEADO',error=str(exc))
        raise SystemExit(1)
