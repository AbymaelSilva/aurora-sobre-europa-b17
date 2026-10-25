#!/usr/bin/env python3
"""Encargos separados: Qwen implementa, Claude revisa y Agy prepara pruebas."""
from pathlib import Path
import json
import subprocess
import sys
import time
from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'godot/B17'

CORE_TASKS=[
('core/flight.gd','''extends RefCounted. Fields position:Vector3=Vector3(0,1200,0),yaw:float=0,pitch:float=0,speed:float=85. reset()->void restores these. step(pitch_input:float,turn_input:float,throttle_input:float,delta:float)->void: delta=clampf(delta,0,.05); yaw+=clampf(turn_input,-1,1)*deg_to_rad(18)*delta; pitch=move_toward(pitch,clampf(pitch_input,-1,1)*deg_to_rad(10),deg_to_rad(8)*delta); speed=clampf(speed+clampf(throttle_input,-1,1)*8*delta,55,110); position+=-Basis.from_euler(Vector3(pitch,yaw,0)).z*speed*delta; position.y=maxf(position.y,30). No other classes or input. Under45 lines.'''),
('core/damage.gd','''extends RefCounted. Fields hull:float=100,engines:PackedFloat32Array=PackedFloat32Array([100,100,100,100]). Read-only property var engine:float with get returning (engines[0]+engines[1]+engines[2]+engines[3])/4.0. reset()->void hull=100, loop4engines=100. apply_damage(amount:float,engine_index:int=-1)->void: amount=maxf(amount,0); hull=clampf(hull-amount,0,100); if engine_index>=0&&engine_index<4 set engines[engine_index]=clampf(engines[engine_index]-amount*2.5,0,100). destroyed()->bool returns hull<=0. thrust_factor()->float returns .6+.4*engine/100. No nodes or other classes. Under45 lines. GDScript uses and, not && if you prefer.'''),
('core/mission.gd','''extends RefCounted. Fields phase:String="FORMACION",waypoint_index:int=0,clock:float=0,waypoints:Array[Vector3]=[Vector3(0,1200,-6000),Vector3(0,1200,-14000),Vector3(0,1200,-22000)],target:Vector3=Vector3(0,0,-30000),exit_point:Vector3=Vector3(28000,1200,-15000). reset restores phase/index/clock. step(delta:float,aircraft_position:Vector3,bomb_result:String,is_destroyed:bool)->void: return if phase is COMPLETADA or FALLIDA. If destroyed set FALLIDA and return. clock+=maxf(delta,0). FORMACION becomes APROXIMACION onceclock>=35. In APROXIMACION if index<size and distance to current waypoint<300 increment, when all reached phase=BOMBARDEO. In BOMBARDEO: IMPACTO->REGRESO, FALLO->FALLIDA. In REGRESO distance to exit<500->COMPLETADA. navigation_target()->Vector3: FORMACION returns first waypoint; APROXIMACION returns waypoints[mini(waypoint_index,waypoints.size()-1)]; REGRESO returns exit_point; otherwise return target+Vector3(0,1200,-4000). Under70 lines. No extra classes.'''),
('core/simulation.gd','''extends RefCounted. Member flight=preload("res://core/flight.gd").new();damage=preload("res://core/damage.gd").new();mission=preload("res://core/mission.gd").new();bomb=preload("res://bomb_model.gd").new();flak=preload("res://flak_model.gd").new(). Other members paused:bool=false,autopilot:bool=true,last_flak_burst:bool=false,flak_damage:float=1.1,pitch_input:float=0,turn_input:float=0,throttle_input:float=0. _init(): flak.interval=2.8. reset()->void resets all5models and input fields0,paused=false,last_flak_burst=false,keep flak.interval=2.8. release_bomb()->bool: reject if mission.phase!="BOMBARDEO" otherwise return bomb.release(flight.position,-Basis.from_euler(Vector3(flight.pitch,flight.yaw,0)).z*flight.speed). step(delta:float)->void: last_flak_burst=false; return if paused or phasein[COMPLETADA,FALLIDA]; clampdelta0...05; mission.step(delta,flight.position,bomb.result,damage.destroyed()). Local pitch/turn/throttle frommemberinput. If autopilot, offset=mission.navigation_target()-flight.position; desired_yaw=atan2(-offset.x,-offset.z); turn=clampf(wrapf(desired_yaw-flight.yaw,-PI,PI)/deg_to_rad(25),-1,1); pitch=clampf((1200-flight.position.y)/80,-1,1); throttle=0; flight.speed=move_toward(flight.speed,85*damage.thrust_factor(),delta*2). Callflight.step(pitch,turn,throttle,delta). in_zone=flight.position.z < -13000 and >-26500 and absf(x)<1000. last_flak_burst=flak.step(delta,in_zone). Ifburst and flak.bursts%3!=0: damage.apply_damage(flak_damage,flak.bursts%4). IfphaseBOMBARDEO andautopilot andnotbomb.spent: velocity=-Basis.from_euler(Vector3(flight.pitch,flight.yaw,0)).z*flight.speed; falltime=(velocity.y+sqrt(velocity.y*velocity.y+19.62*flight.position.y))/9.81; predicted=flight.position+velocity*falltime; horizontal distance Vector2(predicted.x,predicted.z).distance_to(Vector2(mission.target.x,mission.target.z)); ifdistance<45 call release_bomb(). ALWAYS call bomb.step(delta,mission.target,120) OUTSIDE the notspent condition so a released bomb continues falling. ALWAYS finish mission.step(0,flight.position,bomb.result,damage.destroyed()). Contract bomb has result LISTA/EN_VUELO/IMPACTO/FALLO and release(origin,velocity),step(delta,target,radius),reset. flak has interval,bursts,step(delta,in_zone)->bool,reset. No UI, nodes, OS, input collection or extra classes. Under135 lines. Explicitly type math locals Vector3/float to avoid Variant inference.''')]

def qwen():
    import generate_godot_art as runner
    (PROJECT/'core').mkdir(exist_ok=True)
    runner.TASKS=CORE_TASKS
    runner.LOG=ROOT/'logs/godot-mission'/time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
    runner.main()
    state('qwen','núcleo de misión larga generado; pruebas funcionales pendientes')

def claude():
    paths=['game.gd','combat_main.gd','visuals/engines.gd']
    context='\n\n'.join('FILE '+name+'\n'+(PROJECT/name).read_text() for name in paths)
    prompt='''Revisa SOLO estos tres archivos Godot4.7 de nuestro B17. Responde español, máximo450palabras. No uses herramientas ni escribas código. Busca hasta5 fallos concretos de integración/render/rendimiento, con archivo/método, caso reproducible y solución pequeña. No inventes ejecución. Godot es definitivo: Unity cancelado. Qwen codifica; Codex integra. Controles al final. El avión ahora tiene fuselaje curvo y hélices. La geometría pasó tests y una capturaRTXForward+ ya fue revisada; esto no prueba juego terminado. No describas recomendaciones genéricas.\n\n'''+context
    folder=ROOT/'logs/claude-godot';folder.mkdir(exist_ok=True)
    (folder/'request.txt').write_text(prompt)
    target=ROOT/'planning/REVISION_GODOT_CLAUDE.md'
    state('claude','revisión concreta Godot: tres archivos; máximo90s')
    with target.open('w') as out,(folder/'stderr.txt').open('w') as err:
        result=subprocess.run(['claude','--safe-mode','-p','--tools','','--output-format','text'],input=prompt,text=True,stdout=out,stderr=err,timeout=90)
    print(target.read_text(),flush=True)
    state('claude','revisión recibida' if result.returncode==0 and target.stat().st_size else 'sin revisión válida',exit_code=result.returncode)

def agy():
    prompt='NO TOOLS, no commands, no file access, no questions. Return ONLY valid Godot4 GDScript, extends SceneTree, no markdown. Task: test res://core/damage.gd. Under40lines. _initialize: var model=load("res://core/damage.gd").new(). model.apply_damage(-10,0); check hull100. model.apply_damage(20,2); check hull80,engines[2]==50,engines[0]==100,engines[1]==100,engines[3]==100,thrust_factor()<1. model.apply_damage(1000,2); check destroyed(),hull0,engines[2]==0. model.reset();check hull100,engine100,notdestroyed and all4engines100. Every failed condition: print TEST FAIL with reason, quit(1), return immediately. At successful end print TEST PASS: Agy four-engine damage checks and quit0. No await,loops over rates,other classes,network,input,_is_val or test stubs. Public model properties: hull float,engines PackedFloat32Array,engine float readonlyaverage;apply_damage(amount:float,index:int=-1);destroyed()->bool;thrust_factor()->float;reset(). No code execution claims. Complete the file before adding any commentary; add none.'
    folder=ROOT/'logs/agy-godot';folder.mkdir(exist_ok=True)
    (folder/'request.txt').write_text(prompt)
    target=folder/'response.txt'
    state('agy','preparando pruebas de misión Godot; sin herramientas ni preguntas')
    with target.open('w') as out,(folder/'stderr.txt').open('w') as err:
        result=subprocess.run(['agy','--mode','plan','--disable-slash-commands','--print-timeout','90s','--output-format','text','-p',prompt],cwd=ROOT,stdout=out,stderr=err,timeout=100)
    print(target.read_text(),flush=True)
    state('agy','propuesta de pruebas recibida; pendiente de revisión' if result.returncode==0 and target.stat().st_size else 'sin entrega válida',exit_code=result.returncode)

if __name__=='__main__':
    agent=sys.argv[1]
    try: {'qwen':qwen,'claude':claude,'agy':agy}[agent]()
    except subprocess.TimeoutExpired:
        state(agent,'BLOQUEADO',error='Tiempo límite agotado; sin afirmar entrega o delegación completada.')
        raise SystemExit(1)
    except Exception as exc:
        state(agent,'BLOQUEADO',error=str(exc))
        raise SystemExit(1)
