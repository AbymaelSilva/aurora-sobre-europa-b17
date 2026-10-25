#!/usr/bin/env python3
"""Reduce el encargo a un archivo por llamada. Qwen conserva la autoría."""
import json
from pathlib import Path
import re
import subprocess
import time
import urllib.request
from run_team import state

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'prototype-modular'
LOG = ROOT / 'logs/modular' / time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
ENGINE = ROOT / 'tools/godot'
MODEL = 'qwen2.5-coder:7b-instruct-q4_K_M'

SYSTEM = '''You write ONLY Godot 4 GDScript source, no explanation. Follow the tiny file contract exactly. No class_name. Godot 4 API: Node3D, MeshInstance3D, StandardMaterial3D, BoxMesh.size, InputEventKey.physical_keycode, JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y. Never Spatial, SpatialMaterial, scancode, rect_position, get_process_delta. GDScript typed array syntax is Array[Vector3], NEVER Vector3[]. Avoid arrays when not necessary. No OS, files, networking, @tool or plugins. Do not invent methods. Declare all member variables used across methods. Use explicit types for math locals. Use clampf/move_toward, not ambiguous inferred Variant. Avoid static custom class types. Return only the requested single file.'''

TASKS = [
('flight_model.gd', '''extends RefCounted. Members position:Vector3=Vector3(0,100,0), yaw:float=0.0, pitch:float=0.0, speed:float=50.0. Method step(pitch_input:float,turn_input:float,throttle_input:float,delta:float)->void. Clamp delta to [0,0.05]. yaw adds clampf(turn_input,-1,1)*0.55*delta. pitch moves toward clampf(pitch_input,-1,1)*0.35 at 0.45*delta using move_toward. speed adds clampf(throttle_input,-1,1)*12*delta then clamps to [25,90]. Forward direction is -Basis.from_euler(Vector3(pitch,yaw,0)).z. position adds direction*speed*delta; clamp height to >=5. Method reset()->void restores initial members. Nothing else. Under 40 lines.'''),
('aircraft.gd', '''extends Node3D. Only _ready()->void and add_box(size:Vector3,offset:Vector3,color:Color)->void. add_box creates MeshInstance3D, BoxMesh, sets BoxMesh.size, creates StandardMaterial3D and albedo_color, mesh.material_override, mesh.position=offset and add_child(mesh). All locals explicit typed. _ready calls helper for fuselage size(2,2,12) offset zero, wings size(22,0.4,3) offset(0,0,0), tail size(8,.3,2) offset(0,.5,4), fin size(.4,3,2) offset(0,1.5,4), and four engine boxes size(1,1,3) at x=-7,-3,3,7, y=0,z=-1.5. Olive body Color(.3,.4,.2), darker engines. Aircraft faces negative Z. No Camera, flight or input. Under 45 lines.'''),
('hud.gd', '''extends CanvasLayer. member label:Label. _ready()->void creates Label.new(), sets position=Vector2(20,20), add_theme_font_size_override("font_size",22), add_child(label). update_hud(speed:float,altitude:float,paused:bool)->void assigns text with Spanish title B-17 PROTOTIPO, speed m/s, altitude m, paused status and accurate controls: W/S ascender/descender; A/D girar; flechas arriba/abajo acelerar/frenar; ESC pausa; R reiniciar; stick izquierdo mando pitch/turn. Use format strings with %.1f for numbers and escaped newlines. No other dependencies. Under 25 lines.'''),
('main.gd', '''extends Node3D. Scene has children Aircraft (Node3D), Camera3D, HUD (CanvasLayer with update_hud(speed,altitude,paused)). Member var flight = preload("res://flight_model.gd").new(); member paused:bool=false. No creation of geometry/environment. _unhandled_input(event:InputEvent)->void: if event is InputEventKey and event.pressed and not event.echo, physical_keycode ESC toggles paused; R flight.reset(). _physics_process(delta:float)->void: get keyboard float W-S pitch, D-A turn, UP-DOWN throttle using float(Input.is_physical_key_pressed(KEY_W)) etc; if a joypad exists take first id, get JOY_AXIS_LEFT_X for turn and negative JOY_AXIS_LEFT_Y for pitch; apply deadzone absf(value)>.15 and choose stick only if outside deadzone. If not paused call flight.step(pitch,turn,throttle,delta). Always update $Aircraft.position=flight.position and rotation=Vector3(flight.pitch,flight.yaw,0). Camera global_position=flight.position+Vector3(0,8,25).rotated(Vector3.UP,flight.yaw). $Camera3D.look_at(flight.position+Vector3.UP,Vector3.UP). Call $HUD.update_hud(flight.speed,flight.position.y,paused). Do not change global scene pause or quit. Explicit float locals, no custom class types. Under 65 lines.''')]

SCENE = '''[gd_scene load_steps=7 format=3]
[ext_resource type="Script" path="res://main.gd" id="1"]
[ext_resource type="Script" path="res://aircraft.gd" id="2"]
[ext_resource type="Script" path="res://hud.gd" id="3"]
[sub_resource type="PlaneMesh" id="Ground"]
size = Vector2(10000,10000)
[sub_resource type="StandardMaterial3D" id="Grass"]
albedo_color = Color(0.18,0.3,0.12,1)
[sub_resource type="Environment" id="Sky"]
background_mode = 1
background_color = Color(0.43,0.68,0.9,1)
ambient_light_source = 2
ambient_light_color = Color(0.8,0.85,1,1)
ambient_light_energy = 0.7
[node name="B17" type="Node3D"]
script = ExtResource("1")
[node name="Aircraft" type="Node3D" parent="."]
script = ExtResource("2")
[node name="Camera3D" type="Camera3D" parent="."]
current = true
far = 15000.0
[node name="Ground" type="MeshInstance3D" parent="."]
mesh = SubResource("Ground")
material_override = SubResource("Grass")
[node name="Sun" type="DirectionalLight3D" parent="."]
rotation_degrees = Vector3(-45,-30,0)
light_energy = 1.0
[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Sky")
[node name="HUD" type="CanvasLayer" parent="."]
script = ExtResource("3")
'''

TEST = '''extends SceneTree
func _initialize() -> void:
    var model = load("res://flight_model.gd").new()
    for i in range(36000):
        model.step(sin(float(i)*0.01), cos(float(i)*0.01), sin(float(i)*0.05), 1.0/60.0)
        if not model.position.is_finite() or not is_finite(model.speed) or model.speed < 25.0 or model.speed > 90.0 or model.position.y < 5.0:
            print("TEST FAIL: invalid state at tick ", i)
            quit(1)
            return
    model.reset()
    if model.position != Vector3(0,100,0) or model.speed != 50.0 or model.yaw != 0.0 or model.pitch != 0.0:
        print("TEST FAIL: reset")
        quit(1)
        return
    for i in range(600):
        model.step(0.0,0.0,0.0,1.0/60.0)
    if absf(model.position.y-100.0)>0.01 or model.position.z > -490.0:
        print("TEST FAIL: straight and level flight")
        quit(1)
        return
    model.reset()
    for i in range(120):
        model.step(1.0,0.0,0.0,1.0/60.0)
    if model.position.y <= 110.0:
        print("TEST FAIL: pitch does not produce climb")
        quit(1)
        return
    print("TEST PASS: 10min finite state/speed/height bounds, reset, level flight and climb")
    quit(0)
'''


def run(args, timeout=45):
    result = subprocess.run([str(ENGINE), '--headless', '--path', str(OUT), *args], capture_output=True, text=True, timeout=timeout)
    text = result.stdout + result.stderr
    if result.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
        raise ValueError(text)
    return text


def generate(filename, contract):
    if filename!='flight_model.gd' and (OUT/filename).exists():
        try:
            run(['--script','res://'+filename,'--check-only'])
            print('[QWEN] Se conserva archivo que ya compila: '+filename,flush=True)
            return
        except ValueError:
            pass
    if filename=='flight_model.gd' and (OUT/filename).exists():
        try:
            print(run(['--script','res://test_flight.gd']),flush=True)
            print('[QWEN] Se conserva modelo de vuelo ya comprobado.',flush=True)
            return
        except ValueError:
            pass
    if filename=='aircraft.gd':
        contract+=' IMPORTANT: no arrays or loops. Call add_box eight times directly. Never use Vector3[] syntax.'
    messages = [{'role':'system','content':SYSTEM}, {'role':'user','content':contract}]
    for attempt in range(1,4):
        state('qwen', f'{filename}: intento {attempt}/3')
        print(f'[QWEN] {filename} intento {attempt}/3', flush=True)
        payload = {'model':MODEL,'messages':messages,'stream':False,'keep_alive':'0s','options':{'temperature':0.05,'seed':17,'num_ctx':4096,'num_predict':2200}}
        (LOG/f'{filename}.{attempt}.request.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2))
        req = urllib.request.Request('http://127.0.0.1:11435/api/chat',data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
        with urllib.request.urlopen(req,timeout=300) as response:
            data=json.load(response)
        (LOG/f'{filename}.{attempt}.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
        text=data['message']['content'].strip()
        text=re.sub(r'^```(?:gdscript)?\s*','',text)
        text=re.sub(r'\s*```$','',text)
        (OUT/filename).write_text(text+'\n')
        try:
            report=run(['--script', 'res://'+filename,'--check-only'])
            if filename=='flight_model.gd':
                report+=run(['--script','res://test_flight.gd'])
            (LOG/f'{filename}.{attempt}.check.txt').write_text(report)
            print(report,flush=True)
            return
        except ValueError as exc:
            error=str(exc)
            (LOG/f'{filename}.{attempt}.check.txt').write_text(error)
            print(error[-1800:],flush=True)
            messages += [{'role':'assistant','content':text},{'role':'user','content':'Correct this exact file. Return full source only. Godot diagnostic:\n'+error[-3000:]}]
    raise RuntimeError('Intentos agotados en '+filename)


def main():
    OUT.mkdir(exist_ok=True)
    LOG.mkdir(parents=True,exist_ok=True)
    import fcntl
    lock=(ROOT/'logs/modular/builder.lock').open('w')
    try:
        fcntl.flock(lock,fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print('Ya hay un constructor trabajando; no se duplican tareas.',flush=True)
        return
    (OUT/'project.godot').write_text('config_version=5\n[application]\nconfig/name="B17 - Primer vuelo"\nrun/main_scene="res://main.tscn"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    (OUT/'test_flight.gd').write_text(TEST)
    for filename,contract in TASKS:
        generate(filename,contract)
    (OUT/'main.tscn').write_text(SCENE)
    report=run(['--editor','--import','--quit'],90)+run(['--quit-after','120'])
    if (OUT/'test_integration.gd').exists():
        report+=run(['--script','res://test_integration.gd'])
    (LOG/'integration-check.txt').write_text(report)
    print(report,flush=True)
    (OUT/'AUTHORSHIP.json').write_text(json.dumps({'game_scripts_primary_author':MODEL,'integration_scene_and_tests':'Codex','main_gd_corrections_by_Codex':['Replace C-style ternary and nonexistent joypad count with connected joypad IDs','Implement missing R reset input'],'hud_gd_corrections_by_Codex':['Replace boolean expression with GDScript conditional for status text'],'validated':'parser, 10min simulated flight invariants, headless 120 frames, integration pause/reset/resume if test present','not_validated':['Ally X','Windows','physical controller']},indent=2))
    print('Arranque y pruebas automáticas superados. Abriendo ventana para prueba visual.',flush=True)
    state('qwen','pruebas automáticas superadas; prototipo abierto para prueba visual',project=str(OUT))
    subprocess.run([str(ENGINE),'--path',str(OUT)],check=True)


if __name__=='__main__':
    try:
        main()
    except Exception as exc:
        state('qwen','BLOQUEADO',error=str(exc))
        print('BLOQUEADO: '+str(exc),flush=True)
        raise SystemExit(1)
