#!/usr/bin/env python3
"""Lote de 10 encargos de Claude a Qwen: aviones y escenario. Espera a que termine la cola de Codex."""
from pathlib import Path
import json
import subprocess
import sys
import time
import shlex

ROOT = Path(__file__).resolve().parent
LOG = ROOT / 'logs/claude-qwen-batch' / time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
PARTS = 'const Parts=preload("res://visuals/parts.gd"). Exact helper Parts.add_mesh(parent:Node3D,label:String,shape:Mesh,offset:Vector3,scale_value:Vector3,color:Color)->MeshInstance3D.'
OFF = 'GeometryInstance3D.SHADOW_CASTING_SETTING_OFF'

JOBS = [
('world/ground_material.gd', f'''extends RefCounted. Two static funcs only. static func farmland(tile_meters:float)->StandardMaterial3D: var mat:=StandardMaterial3D.new(); mat.albedo_texture=load("res://assets/terrain/farmland_a.png") as Texture2D; mat.roughness=1.0; mat.metallic=0.0; mat.uv1_triplanar=true; mat.uv1_world_triplanar=true; mat.uv1_scale=Vector3.ONE/maxf(tile_meters,1.0); mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC; return mat. static func rail_yard()->StandardMaterial3D: same but albedo_texture=load("res://assets/terrain/rail_yard.png") as Texture2D, roughness 1, no triplanar, same texture_filter. No nodes. Under30 lines.'''),
('world/target_ground.gd', f'''extends Node3D. const GroundMaterial=preload("res://world/ground_material.gd"). Exact helper GroundMaterial.rail_yard()->StandardMaterial3D. @export var size_m:float=1800.0. var ground:MeshInstance3D. _ready()->void: var plane:=PlaneMesh.new(); plane.size=Vector2(size_m,size_m); ground=MeshInstance3D.new(); ground.name="RailYardGround"; ground.mesh=plane; ground.material_override=GroundMaterial.rail_yard(); ground.position=Vector3(0,0.3,0); ground.cast_shadow={OFF}; add_child(ground). No other methods. Under25 lines.'''),
('world/cloud_sprites.gd', f'''extends Node3D. @export var count:int=60; @export var seed_value:int=1944; @export var area_min:Vector3=Vector3(-12000,1700,-36000); @export var area_max:Vector3=Vector3(12000,2600,6000). var sprites:Array[Sprite3D]=[]. _ready()->void: var tex:Texture2D=load("res://assets/sky/cloud_atlas.png") as Texture2D; var rng:=RandomNumberGenerator.new(); rng.seed=seed_value; var cell:Vector2=tex.get_size()/4.0; for i in range(clampi(count,0,200)): var s:=Sprite3D.new(); s.texture=tex; s.region_enabled=true; var c:int=rng.randi_range(0,15); s.region_rect=Rect2(Vector2(float(c & 3),float(c >> 2))*cell,cell); s.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y; s.shaded=false; s.transparent=true; s.pixel_size=rng.randf_range(0.6,1.4); s.modulate=Color(1,1,1,rng.randf_range(0.75,0.95)); s.cast_shadow={OFF}; s.position=Vector3(rng.randf_range(area_min.x,area_max.x),rng.randf_range(area_min.y,area_max.y),rng.randf_range(area_min.z,area_max.z)); add_child(s); sprites.append(s). func cloud_count()->int returns sprites.size(). Under40 lines.'''),
('visuals/fighter.gd', f'''extends Node3D. {PARTS} Original generic single-engine WWII fighter facing NEGATIVE Z, about 9m long. var rotor:Node3D. Colors body Color(.36,.38,.33), nose Color(.75,.62,.15), glass Color(.3,.4,.45,.6), dark Color(.07,.07,.07). _ready()->void: SphereMesh radius1 height2 radial_segments16 rings8 add "Fuselage" offset zero scale(.55,.6,4.6) body. CylinderMesh top_radius .55 bottom_radius .6 height 1.6 add "Cowl" offset(0,0,-3.6) scale ONE nose, set returned.rotation.x=PI/2. Another SphereMesh add "Canopy" offset(0,.55,-.6) scale(.4,.35,1.0) glass. BoxMesh size(10,.18,1.7) add "Wing" offset(0,-.25,-.9) body. BoxMesh size(3.4,.12,.9) add "Tailplane" offset(0,.1,3.9) body. BoxMesh size(.12,1.3,1.0) add "Fin" offset(0,.75,3.9) body. rotor=Node3D.new(); rotor.name="Rotor"; rotor.position=Vector3(0,0,-4.5); add_child(rotor). SphereMesh radius .22 height .44 add to rotor "Spinner" offset zero scale ONE dark. For j in range(3): var angle:float=TAU*float(j)/3.0; BoxMesh size(.12,1.5,.05); var blade:=Parts.add_mesh(rotor,"Blade",box,(Vector3.UP*.75).rotated(Vector3.FORWARD,angle),Vector3.ONE,dark); blade.rotation.z=-angle. _process(delta:float)->void: rotor.rotate_z(delta*40.0). Under60 lines.'''),
('core/fighter_ai.gd', '''extends RefCounted. Pure logic, no nodes. Fields position:Vector3=Vector3.ZERO, velocity:Vector3=Vector3.ZERO, state:String="APPROACH", timer:float=0.0, speed:float=150.0, side:float=1.0. func setup(start:Vector3,attack_side:float)->void: position=start; side=1.0 if attack_side>=0.0 else -1.0; state="APPROACH"; timer=0.0; velocity=Vector3.ZERO. func steer(aim:Vector3,delta:float)->void: var desired:Vector3=(aim-position).normalized()*speed; velocity=velocity.lerp(desired,clampf(delta*1.2,0.0,1.0)); position+=velocity*delta. func step(delta:float,bomber_pos:Vector3)->void: delta=clampf(delta,0.0,0.05); timer+=delta. If state=="APPROACH": var aim:Vector3=bomber_pos+Vector3(side*400.0,150.0,-1500.0); steer(aim,delta); if position.distance_to(aim)<250.0: state="ATTACK"; timer=0.0. elif state=="ATTACK": steer(bomber_pos,delta); if position.distance_to(bomber_pos)<200.0 or timer>12.0: state="BREAK"; timer=0.0. elif state=="BREAK": velocity=velocity.lerp(Vector3(side,-0.5,0.3).normalized()*speed,clampf(delta*1.5,0.0,1.0)); position+=velocity*delta; if timer>4.0: state="REPOSITION"; timer=0.0. elif state=="REPOSITION": var back:Vector3=bomber_pos+Vector3(side*1500.0,300.0,-2500.0); steer(back,delta); if position.distance_to(back)<300.0 or timer>20.0: side=-side; state="APPROACH"; timer=0.0. func is_attacking()->bool returns state=="ATTACK". Under60 lines. Use if/elif, not match.'''),
('core/formation_slots.gd', '''extends RefCounted. Pure logic. Godot forward is -Z, so behind the leader is +Z. var offsets:Array[Vector3]=[Vector3(0,0,0),Vector3(-45,-10,35),Vector3(45,-10,35),Vector3(-90,-20,70),Vector3(90,-20,70),Vector3(0,15,70)]. func slot_count()->int returns offsets.size(). func local_offset(index:int)->Vector3 returns offsets[clampi(index,0,offsets.size()-1)]. func world_position(leader_pos:Vector3,leader_yaw:float,index:int)->Vector3 returns leader_pos+local_offset(index).rotated(Vector3.UP,leader_yaw). No other methods. Under20 lines.'''),
('visuals/tracer_pool.gd', f'''extends Node3D. Pool of tracer rounds in this node's LOCAL space. @export var capacity:int=48; @export var lifetime:float=1.6. var meshes:Array[MeshInstance3D]=[]; var velocities:Array[Vector3]=[]; var ages:PackedFloat32Array=PackedFloat32Array(). _ready()->void: var box:=BoxMesh.new(); box.size=Vector3(.12,.12,6.0); var mat:=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color=Color(1,.75,.3); mat.emission_enabled=true; mat.emission=Color(1,.6,.2); mat.emission_energy_multiplier=4.0; for i in range(clampi(capacity,1,256)): var m:=MeshInstance3D.new(); m.mesh=box; m.material_override=mat; m.visible=false; m.cast_shadow={OFF}; add_child(m); meshes.append(m); velocities.append(Vector3.ZERO); ages.append(lifetime). func fire(origin:Vector3,velocity:Vector3)->bool: find first i with ages[i]>=lifetime, if none return false; meshes[i].position=origin; velocities[i]=velocity; ages[i]=0.0; meshes[i].visible=true; if velocity.length()>0.01: var dir:Vector3=velocity.normalized(); var up:Vector3=Vector3.UP if absf(dir.dot(Vector3.UP))<0.99 else Vector3.FORWARD; meshes[i].basis=Basis.looking_at(dir,up); return true. func advance(delta:float)->void: for i in range(meshes.size()): if ages[i]<lifetime: ages[i]+=maxf(delta,0.0); meshes[i].position+=velocities[i]*maxf(delta,0.0); if ages[i]>=lifetime: meshes[i].visible=false. func active_count()->int counts ages[i]<lifetime. func reset()->void sets every age=lifetime and visible=false. No _process. Under70 lines.'''),
('visuals/engine_smoke_trail.gd', f'''extends Node3D. Smoke trail for a damaged engine. var particles:CPUParticles3D; var intensity:float=0.0. _ready()->void: particles=CPUParticles3D.new(); particles.amount=48; particles.lifetime=3.0; particles.local_coords=false; particles.emitting=false; var puff:=SphereMesh.new(); puff.radius=.5; puff.height=1.0; puff.radial_segments=8; puff.rings=4; var mat:=StandardMaterial3D.new(); mat.albedo_color=Color(1,1,1,1); mat.vertex_color_use_as_albedo=true; mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.roughness=1.0; puff.material=mat; particles.mesh=puff; particles.direction=Vector3(0,0,1); particles.spread=12.0; particles.initial_velocity_min=4.0; particles.initial_velocity_max=8.0; particles.gravity=Vector3(0,1.5,0); particles.scale_amount_min=1.5; particles.scale_amount_max=4.0; particles.color=Color(.1,.1,.1,.25); add_child(particles). func set_intensity(value:float)->void: intensity=clampf(value,0.0,1.0); particles.emitting=intensity>0.05; particles.color=Color(.1,.1,.1,lerpf(.25,.8,intensity)). func from_engine_health(health:float)->void: set_intensity(clampf((85.0-health)/85.0,0.0,1.0)). Under45 lines.'''),
('world/river.gd', f'''extends Node3D. @export var points:PackedVector3Array=PackedVector3Array([Vector3(-9000,0,8000),Vector3(-3000,0,-2000),Vector3(1500,0,-12000),Vector3(-1200,0,-24000),Vector3(900,0,-30500),Vector3(6000,0,-40000)]); @export var width:float=140.0. var river:MeshInstance3D. func build()->MeshInstance3D: var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); for i in range(points.size()-1): var a:Vector3=points[i]; var b:Vector3=points[i+1]; var dir:Vector3=b-a; dir.y=0.0; if dir.length()<0.001: continue; var side:Vector3=dir.normalized().cross(Vector3.UP)*width*0.5; var lift:=Vector3(0,0.2,0); var q:Array[Vector3]=[a-side+lift,b-side+lift,b+side+lift,a-side+lift,b+side+lift,a+side+lift]; for p in q: st.set_normal(Vector3.UP); st.add_vertex(p). var mat:=StandardMaterial3D.new(); mat.albedo_color=Color(.16,.24,.26); mat.roughness=0.08; mat.metallic=0.1; mat.cull_mode=BaseMaterial3D.CULL_DISABLED; river=MeshInstance3D.new(); river.name="River"; river.mesh=st.commit(); river.material_override=mat; river.cast_shadow={OFF}; add_child(river); return river. _ready()->void: build(). Under45 lines.'''),
('visuals/bomber_details.gd', f'''extends Node3D. {PARTS} Small detail parts for the existing bomber facing NEGATIVE Z (fuselage centered at zero, nose near z=-10, tail near z=11). dark Color(.06,.06,.06); metal Color(.2,.17,.14). func barrel(label:String,offset:Vector3,size:Vector3)->void: var b:=BoxMesh.new(); b.size=size; Parts.add_mesh(self,label,b,offset,Vector3.ONE,dark). _ready()->void: SphereMesh radius .5 height 1 add "ChinTurret" offset(0,-1.2,-9.6) scale(.7,.6,.7) dark. barrels: "ChinGunL" (-.15,-1.25,-10.4) size(.06,.06,1.2); "ChinGunR" (.15,-1.25,-10.4) same; "TopGunL" (-.18,2.2,-2.9) size(.06,.06,1.4); "TopGunR" (.18,2.2,-2.9); "BellyGunL" (-.15,-2.0,-.3) size(.06,.06,1.3); "BellyGunR" (.15,-2.0,-.3); "WaistGunL" (-1.75,.5,3.5) size(1.1,.06,.06); "WaistGunR" (1.75,.5,3.5) size(1.1,.06,.06); "TailGunL" (-.12,.3,12.3) size(.06,.06,1.0); "TailGunR" (.12,.3,12.3); "RadioMast" (0,1.9,-3.9) size(.05,.9,.05). For x in [-9.4,-4.4,4.4,9.4]: BoxMesh size(.25,.2,.8), Parts.add_mesh(self,"Exhaust",box,Vector3(x,-.85,-1.4),Vector3.ONE,metal). Under55 lines.'''),
]


def codex_queue_running() -> bool:
    out = subprocess.run(['pgrep', '-f', r'^(/usr/bin/)?python3 -u \S*next_team_batch.py qwen'], capture_output=True, text=True).stdout
    return bool(out.strip())


def worker() -> None:
    import generate_godot_art as runner
    LOG.mkdir(parents=True, exist_ok=True)
    while codex_queue_running():
        print('Esperando a que termine la cola Qwen de Codex…', flush=True)
        time.sleep(20)
    results = []
    for index, job in enumerate(JOBS, 1):
        print(f'\n=== Encargo {index}/10: {job[0]} ===', flush=True)
        runner.TASKS = [job]
        runner.LOG = LOG
        while True:
            try:
                runner.main()
                results.append({'file': job[0], 'author': 'qwen', 'requested_by': 'claude', 'status': 'syntax_checked'})
                break
            except BlockingIOError:
                print('Ejecutor ocupado; reintento en 20 s', flush=True)
                time.sleep(20)
            except Exception as exc:
                results.append({'file': job[0], 'author': 'qwen', 'requested_by': 'claude', 'status': 'needs_review', 'error': str(exc)[-600:]})
                print('Pendiente de revisión: ' + job[0], flush=True)
                break
        (LOG / 'results.json').write_text(json.dumps(results, indent=2, ensure_ascii=False))
    ok = sum(r['status'] == 'syntax_checked' for r in results)
    print(f'\nLote terminado: {ok}/10 con sintaxis válida. Pruebas funcionales: pendientes (Claude).', flush=True)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'worker':
        worker()
    else:
        inner = shlex.join(['script', '-q', '-e', '-f', '-c', shlex.join([sys.executable, '-u', str(Path(__file__).resolve()), 'worker']), str(ROOT / 'logs/claude-qwen-batch.console.log')])
        subprocess.Popen(['xfce4-terminal', '--disable-server', '--hold', '--title', 'B17 — QWEN 10 TAREAS (CLAUDE)', '--command', inner], start_new_session=True)
        print('Consola abierta: logs/claude-qwen-batch.console.log')
