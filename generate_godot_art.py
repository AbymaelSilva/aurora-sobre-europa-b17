#!/usr/bin/env python3
"""Qwen genera geometría original para el proyecto Godot definitivo."""
from pathlib import Path
import json
import re
import subprocess
import time
import urllib.request
from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'godot/B17'
ENGINE=ROOT/'tools/godot'
LOG=ROOT/'logs/godot-art'/time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
SYSTEM='''Return ONLY one complete Godot 4.7 GDScript file. No markdown, no class_name. Correct names: Node3D, MeshInstance3D, StandardMaterial3D, SphereMesh, BoxMesh, CylinderMesh, SurfaceTool. Typed arrays: Array[Node3D], never Node3D[]. Use explicit typed locals and valid GDScript conditional syntax. No OS, files, networking, @tool or plugins. No extra classes or dependency stubs. Every task provides exact helper contracts: never change those signatures. One script per response. Keep under 100 lines.'''
TASKS=[
('visuals/parts.gd','''extends RefCounted. static var materials:Dictionary={}. static func material(color:Color)->StandardMaterial3D: if materials.has(color) return materials[color]; create StandardMaterial3D with albedo_color=color,roughness=.48,metallic=.25; if color.a<.99 set transparency=BaseMaterial3D.TRANSPARENCY_ALPHA and metallic=0 and roughness=.2; cache and return. static func add_mesh(parent:Node3D,label:String,shape:Mesh,offset:Vector3,scale_value:Vector3,color:Color)->MeshInstance3D: create MeshInstance3D, name=label, mesh=shape, material_override=material(color), position=offset, scale=scale_value, parent.add_child(node), return node. No other methods, no script preloads. All called APIs are Godot4. Under45 lines.'''),
('visuals/body.gd','''extends Node3D. const Parts=preload("res://visuals/parts.gd"). Exact helper signature Parts.add_mesh(parent:Node3D,label:String,shape:Mesh,offset:Vector3,scale_value:Vector3,color:Color)->MeshInstance3D. Define ellipsoid(label:String,offset:Vector3,size:Vector3,color:Color)->void: create SphereMesh with radius=1,height=2,radial_segments=24,rings=12; call Parts.add_mesh(self,label,sphere,offset,size*.5,color). Define box(label:String,offset:Vector3,size:Vector3,color:Color)->void: create BoxMesh size=size, call Parts.add_mesh(self,label,shape,offset,Vector3.ONE,color). _ready creates original bomber facing NEGATIVE Z: olive Color(.28,.33,.18); glass Color(.22,.36,.44,.65); dark Color(.08,.09,.08). ellipsoid Fuselage zero size(2.7,3,20)olive; Rear offset(0,.2,6)size(1.8,2,10)olive; Nose offset(0,0,-9.8)size(2.5,2.7,3)glass; Cockpit offset(0,1.35,-5.8)size(2.2,1.5,3.4)glass; boxCabinFrame offset(0,1.4,-5.8)size(.12,1.3,3.4)dark; ellipsoidUpperTurret offset(0,2.1,-2)size(1.6,1.3,1.6)glass; ellipsoidBellyTurret offset(0,-1.8,.5)size(1.4,1.3,1.4)glass; boxHorizontalTail offset(0,1,8.5)size(10,.3,2.4)olive; ellipsoidVerticalTail offset(0,2.4,8.7)size(.3,4.3,3.8)olive; boxTailGun offset(0,.3,11)size(.35,.35,2)dark. No extra helpers or dependencies. Under80 lines.'''),
('visuals/wings.gd','''extends Node3D. _ready calls build(1.0) and build(-1.0). func quad(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,normal:Vector3)->void loops over [a,b,c,a,c,d], st.set_normal(normal),st.add_vertex(point). func build(side:float)->void: top corners a=(1.1*side,.2,-2.2),b=(15.8*side,1,-.5),c=(15.8*side,1,1.6),d=(1.1*side,.2,3.7); bottom e=a-Vector3(0,.25,0),f=b-same,g=c-same,h=d-same. SurfaceTool.new(),begin(Mesh.PRIMITIVE_TRIANGLES). Add six quads top(a,b,c,d,Vector3.UP),bottom(e,h,g,f,Vector3.DOWN),front(a,e,f,b,Vector3.FORWARD),tip(b,f,g,c,Vector3.RIGHT*side),back(c,g,h,d,Vector3.BACK),root(d,h,e,a,Vector3.LEFT*side). Do not generate normals; explicit normals set per vertex. create MeshInstance3D with mesh=st.commit(); StandardMaterial3D albedo_color Color(.28,.33,.18),metallic=.25,roughness=.48,cull_mode=BaseMaterial3D.CULL_DISABLED; material_override=mat; add_child. No indices, arrays of arrays or other classes. Under70 lines.'''),
('visuals/engines.gd','''extends Node3D. const Parts=preload("res://visuals/parts.gd"). Exact Parts.add_mesh(parent:Node3D,label:String,shape:Mesh,offset:Vector3,scale_value:Vector3,color:Color)->MeshInstance3D. member propellers:Array[Node3D]=[]. _ready: for x in [-9.4,-4.4,4.4,9.4], create CylinderMesh with top_radius=.9,bottom_radius=.9,height=3.1,radial_segments=24; call Parts.add_mesh(self,"Nacelle",cylinder,Vector3(x,-.05,-2.8),Vector3.ONE,Color(.27,.3,.17)) and set returned mesh.rotation.x=PI/2. Create SphereMesh radius=.4,height=.8 and add at(x,0,-4.5),scale(1,1,1.4),darkColor(.15,.16,.16). Create Node3D rotor child at(x,0,-5); append to propellers. For j in range(3), angle=TAU*float(j)/3; create BoxMesh size(.18,2.1,.08); add blade via Parts.add_mesh(rotor,"Blade",box,(Vector3.UP*1.05).rotated(Vector3.FORWARD,angle),Vector3.ONE,Color(.07,.07,.07)); returned blade.rotation.z=-angle. _process(delta:float)->void loops propellers and rotate_z(delta*31). No other methods, no global class types. Under65 lines.''')]

def check(path):
    result=subprocess.run([str(ENGINE),'--headless','--path',str(PROJECT),'--script','res://'+path,'--check-only'],capture_output=True,text=True,timeout=45)
    report=result.stdout+result.stderr
    if result.returncode or 'SCRIPT ERROR' in report or '\nERROR:' in report: raise ValueError(report)
    return report

def main():
    LOG.mkdir(parents=True,exist_ok=True)
    import fcntl
    lock=(ROOT/'logs/godot-art.lock').open('w')
    fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    for name,contract in TASKS:
        target=PROJECT/name
        if target.exists():
            try:
                check(name)
                print('Se conserva archivo existente: '+name,flush=True)
                continue
            except ValueError: pass
        messages=[{'role':'system','content':SYSTEM},{'role':'user','content':contract}]
        for attempt in range(1,4):
            state('qwen',f'Godot definitivo: {name}, intento {attempt}/3')
            payload={'model':'qwen2.5-coder:7b-instruct-q4_K_M','messages':messages,'stream':False,'keep_alive':'0s','options':{'num_ctx':4096,'num_predict':2800,'temperature':.1,'seed':83}}
            (LOG/(target.name+f'.{attempt}.request.json')).write_text(json.dumps(payload,ensure_ascii=False,indent=2))
            req=urllib.request.Request('http://127.0.0.1:11435/api/chat',data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
            with urllib.request.urlopen(req,timeout=300) as response: answer=json.load(response)
            (LOG/(target.name+f'.{attempt}.response.json')).write_text(json.dumps(answer,ensure_ascii=False,indent=2))
            text=answer['message']['content'].strip()
            text=re.sub(r'^```(?:gdscript)?\s*','',text); text=re.sub(r'\s*```$','',text)
            target.write_text(text+'\n')
            try:
                report=check(name)
                (LOG/(target.name+f'.{attempt}.check.txt')).write_text(report)
                print(report,flush=True)
                break
            except ValueError as exc:
                report=str(exc);print(report,flush=True)
                (LOG/(target.name+f'.{attempt}.check.txt')).write_text(report)
                messages += [{'role':'assistant','content':text},{'role':'user','content':'Return corrected full file. Preserve contracts. Godot diagnostic:\n'+report[-2500:]}]
        else: raise RuntimeError('Intentos agotados: '+name)
    state('qwen','geometría Godot generada y sintaxis comprobada; renderizado pendiente')

if __name__=='__main__':
    try: main()
    except Exception as exc:
        state('qwen','BLOQUEADO',error=str(exc))
        raise SystemExit(1)
