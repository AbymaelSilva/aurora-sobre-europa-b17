#!/usr/bin/env python3
from pathlib import Path
import fcntl,json
ROOT=Path(__file__).resolve().parent
TASKS=[
('core/interceptor.gd','''extends RefCounted
GDScript 4 only. Fields clock:float=0.0,next_attack:float=160.0,age:float=0.0,active:bool=false,health:float=100.0,position:Vector3=Vector3.ZERO,shots:int=0,passes:int=0,damage_event:float=0.0,fired:bool=false.
reset()->void restores EVERY field to initial value.
step(delta:float,leader:Vector3,yaw:float,defending:bool)->void: damage_event=0.0; delta=clampf(delta,0.0,0.05); clock+=delta. If not active and clock>=next_attack: active=true;age=0.0;health=100.0;fired=false;passes+=1;next_attack=clock+150.0. If not active return. age+=delta. position=leader+Vector3(100.0-age*12.0,40.0-age*3.0,-220.0+age*25.0).rotated(Vector3.UP,yaw). If defending health=maxf(health-delta*9.0,0.0). If health<=0.0: active=false;return. If age>=8.0 and not fired: fired=true;shots+=1;damage_event=1.5. If age>=14.0 active=false. No nodes, OS, RNG, UI or other classes. Under85 lines. Use explicit member names, not __init__. Conditional syntax: if value: newline indented action. No C-style ternary.'''),
('visuals/interceptor_body.gd','''extends Node3D
Original enemy single-engine propeller fighter facing NEGATIVE Z. _ready: gray SphereMesh body radius1,height2,scale(0.7,0.8,5.0); BoxMesh wings size(10.0,0.18,1.7)position(0,0,0); BoxMesh tail size(4.0,0.15,1.0)position(0,0,3.7); BoxMesh verticaltail size(.15,1.5,1.4)position(0,.6,3.5); SphereMesh cockpit radius.6 height1.2 position(0,.7,-.7)scale(1,.7,1.8),darkblue material. Use helper add_part(shape:Mesh,at:Vector3,scale_value:Vector3,color:Color)->void creates MeshInstance3D,material,sets position and scale,add_child. No animation, no logos or faction symbols, no physics or dependencies. Under65lines. Godot4 properties position, scale. No translation.'''),
('visuals/tracer.gd','''extends Node3D
Fields remaining:float=0.0. _ready creates MeshInstance3D CylinderMesh top_radius.07,bottom_radius.07,height1.0,radial_segments6,material unshaded orange via material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED and albedo_color=Color(1,.65,.15); child rotation_degrees.x=90.0;visible=false.
show_segment(start:Vector3,finish:Vector3)->void: var length_value:float=start.distance_to(finish); if length_value<0.01 return. global_position=(start+finish)*0.5;look_at(finish,Vector3.UP);scale=Vector3(1,1,length_value);remaining=.12;visible=true.
advance(delta:float)->void sets remaining=maxf(remaining-maxf(delta,0.0),0.0);visible=remaining>0.0.
reset()->void remaining=0.0;visible=false;scale=Vector3.ONE.
No _process,no RNG,no IO,no extra classes. Under45lines.''')]
if __name__=='__main__':
    import generate_godot_art as r
    log=ROOT/'logs/qwen-combat';log.mkdir(parents=True,exist_ok=True)
    lock=(log/'worker.lock').open('w');fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    queue=(ROOT/'logs/qwen-ten/worker.lock').open('a');fcntl.flock(queue,fcntl.LOCK_EX)
    r.SYSTEM+=' Use Godot4 GDScript only. NO C-style ?: expressions, no Math class, no OS calls. Ternary syntax is: value_if_true if condition else value_if_false. No unrequested random features.'
    results=[]
    for i,task in enumerate(TASKS,1):
        r.TASKS=[task];r.LOG=log/str(i)
        try:r.main();status='syntax_checked'
        except Exception as exc:status='needs_review';print(str(exc),flush=True)
        results.append({'file':task[0],'status':status});(log/'results.json').write_text(json.dumps(results,indent=2))
