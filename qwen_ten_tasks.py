#!/usr/bin/env python3
"""Cola de diez entregas Godot, una inferencia local a la vez y sin duplicar otros lotes."""
from pathlib import Path
import fcntl,json,subprocess,sys,time,shlex
ROOT=Path(__file__).resolve().parent
TASKS=[
('world/rail_target.gd', '''extends Node3D
Build a railway yard centered at local zero. Use helper func box(at: Vector3, size_value: Vector3, color: Color) -> void. This helper creates BoxMesh, MeshInstance3D and StandardMaterial3D, sets node.position=at, node.mesh, material_override, and add_child(node). In _ready: 3 tracks at x=-30,0,30; each has two rails x offset+-3, dimensions(1,1,500),center y1. For each track 12 sleepers along Z spaced40, dimensions(10,0.8,2),color dark brown. Five warehouses at x100, z=-160,-80,0,80,160 with dimensions(60,24,50),center y12, brick color. Add flat charcoal roof to each at y25, dimensions(64,2,54). Under65 meshes. No other features. All helper calls pass Color as third argument. Never use translation, only position. Reuse materials in a Dictionary keyed by Color. Public reset()->void does nothing. Under80 lines.'''),
('world/cloud_layer.gd','''extends Node3D
_ready creates 24 cloud SphereMesh instances sharing one SphereMesh radius1 height2 radial_segments12 rings6 and one opaque StandardMaterial3D color(0.85,0.87,0.88),roughness1. RandomNumberGenerator rng; assign rng.seed = 1944 (property assignment, NOT function call). ALL randomness via rng.randf_range. position x[-10000,10000],y[1800,2400],z[-35000,5000]. scale x[250,600],y[60,100],z[100,250]. Set position before add_child. Shadows disabled using GeometryInstance3D.SHADOW_CASTING_SETTING_OFF. No global_transform. No process. Under45lines.'''),
('visuals/flak_burst.gd','''extends Node3D
Fields age:float=0.0, lifetime:float=4.0, active:bool=false. _ready creates 8 opaque dark spheres sharing one SphereMesh radius1 height2 radial_segments8 rings4 and material. Positions fixed from i: Vector3(sin(float(i)*2.0),cos(float(i)*3.0)*0.5,cos(float(i)*2.0))*1.5. Then visible=false. trigger(origin:Vector3)->void sets global_position=origin,age=0.0,active=true,visible=true,scale=Vector3.ONE*2.0. advance(delta:float)->void returns if not active, otherwise age += maxf(delta,0.0), scale=Vector3.ONE*(2.0+age*8.0); when age>=lifetime set active=false and visible=false. reset()->void sets age=0.0,active=false,visible=false,scale=Vector3.ONE. No _process. Under55lines.'''),
('visuals/markings.gd','''extends Node3D
_ready adds two Label3D children at Vector3(-1.4,0.4,3.0),Vector3(1.4,0.4,3.0). Text="AURORA • 01",font_size=48,pixel_size=0.012,modulate=Color(0.88,0.85,0.68),outline_size=4. rotation_degrees.y=-90 for left,90 for right. Add one Label3D tail code text="A1",position(0,2.5,8.9),rotation_degrees.y=90,font_size64,pixel_size0.016. No process, no billboard, no external font. Under35lines.'''),
('visuals/bomb_body.gd','''extends Node3D
_ready creates original olive falling bomb aligned long axis along local Y. SphereMesh body radius0.28,height1.4,radial_segments12,rings6,material olive roughness0.7. Four BoxMesh tail fins dimensions(0.7,0.35,0.05),position y0.55, rotation_degrees.y=float(i)*90 for i0..3,shared dark material. Optional yellow band via CylinderMesh top_radius0.285,bottom_radius0.285,height0.08 at y=-0.2. Under50lines. No process or physics.'''),
('core/radio_director.gd','''extends RefCounted
Fields last_phase:String="",message:String="",remaining:float=0.0.
reset()->void resets all fields. advance(delta:float,phase:String,hull:float)->void: remaining=maxf(remaining-maxf(delta,0.0),0.0); if phase != last_phase set last_phase=phase, remaining=8.0 and message via match: FORMACION="Aurora líder: mantengan la formación.", APROXIMACION="Navegante: rumbo al nudo ferroviario.", BOMBARDEO="Bombardero: preparados para la suelta.", REGRESO="Aurora líder: blanco alcanzado. Volvemos a casa.", COMPLETADA="Control: los tenemos a la vista. Bienvenidos.", FALLIDA="Aurora líder: emergencia a bordo."; default message="". If remaining<=0 set message="". Do not repeat warning on every frame. hull argument intentionally unused. Under50lines.'''),
('core/debrief.gd','''extends RefCounted
static func build(phase:String,hull:float,engines:PackedFloat32Array,elapsed:float,bomb_result:String)->Dictionary: return dictionary keys title,detail,hull,engines_available,duration_seconds,success. success is phase=="COMPLETADA". Count engines_available by iterating engines and counting values>0.0. title="MISIÓN COMPLETADA" if success else "MISIÓN INTERRUMPIDA". detail="Tripulación en zona segura" if success else ("El bombardeo no alcanzó el objetivo" if bomb_result=="FALLO" else "El avión no pudo regresar"). hull=clampf(hull,0,100),duration_seconds=maxf(elapsed,0). No nodes or IO. Under35lines.'''),
('ui/navigation_marker.gd','''extends Control
Fields target_screen:Vector2=Vector2.ZERO,distance_m:float=0.0,show_marker:bool=false. _ready sets mouse_filter=Control.MOUSE_FILTER_IGNORE and full rect anchors. set_target(point:Vector2,distance_value:float,enabled:bool)->void assigns fields and queue_redraw(). _draw returns if !show_marker. Clamp target_screen to rectangle20..size-20 using clampf. Draw four lines diamond shape radius9 in gold Color(.88,.74,.46),width2. Draw distance string "%.1f km"%(distance_m/1000.0) at point+Vector2(14,5) using ThemeDB.fallback_font,font_size14. No 3D projection, input or process. Under45lines.'''),
('visuals/engine_smoke.gd','''extends Node3D
_ready builds 6 spheres sharing SphereMesh radius1 height2 radial_segments8 rings4 and opaque dark StandardMaterial3D roughness1. Each at position Vector3(0,float(i)*0.7,float(i)*3),scale=Vector3.ONE*(1.0+float(i)*0.5),shadow casting disabled. visible=false. set_damage(engine_health:float)->void sets visible=engine_health<85.0,scale=Vector3.ONE*clampf((100.0-engine_health)/30.0,0.5,3.0). No _process or random, no shaders. Under35lines.'''),
('audio/engine_tone.gd','''extends RefCounted
static func create_stream()->AudioStreamWAV: generate exactly22050 mono samples of signed16bit PCM at22050Hz. For sample index i, t=float(i)/22050.0, value=(sin(TAU*90.0*t)*0.45+sin(TAU*180.0*t)*0.2+sin(TAU*270.0*t)*0.1)*0.18. Allocate PackedByteArray resize44100 and call bytes.encode_s16(i*2,int(clampf(value,-1.0,1.0)*32767.0)). AudioStreamWAV.new(); format=AudioStreamWAV.FORMAT_16_BITS,mix_rate=22050,stereo=false,data=bytes,loop_mode=AudioStreamWAV.LOOP_FORWARD,loop_begin=0,loop_end=22050. Return stream. No playback, no IO, no external assets. Original synthesized aircraft engine ambience, not a recording. Under30lines.''')]
def main():
    folder=ROOT/'logs/qwen-ten';folder.mkdir(parents=True,exist_ok=True)
    lock=(folder/'worker.lock').open('w');fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    previous=(ROOT/'logs/extra-qwen.lock').open('a');print('Esperando fin del lote anterior sin duplicar inferencias...',flush=True);fcntl.flock(previous,fcntl.LOCK_EX)
    import generate_godot_art as runner
    results=[]
    for index,(name,brief) in enumerate(TASKS,1):
        (ROOT/'godot/B17'/name).parent.mkdir(parents=True,exist_ok=True)
        runner.TASKS=[(name,brief)];runner.LOG=folder/f'{index:02d}';runner.SYSTEM+=' Godot4 uses position, NEVER translation. RandomNumberGenerator.seed is a property. Write readable code with spaces. Never call a property as a function. Follow the specified small scope exactly.'
        print(f'TAREA {index}/10: {name}',flush=True)
        try:
            runner.main();status='syntax_checked'
        except Exception as exc:
            status='needs_review';print(str(exc),flush=True)
        results.append({'task':index,'file':name,'status':status})
        (folder/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
    print('Cola terminada. Sintaxis comprobada no significa integración ni aceptación.',flush=True)
if __name__=='__main__':main()
