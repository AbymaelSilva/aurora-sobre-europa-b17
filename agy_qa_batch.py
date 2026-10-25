#!/usr/bin/env python3
"""Agy redacta pruebas pequeñas; Codex comprueba sintaxis y las ejecuta."""
from pathlib import Path
import json
import re
import subprocess
import time
from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'godot/B17'
OUT=PROJECT/'tests'
LOG=ROOT/'logs/agy-qa'/time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
JOBS=[
('test_mission_states_agy.gd','''Test res://core/mission.gd RefCounted. Fields phase="FORMACION",clock0,waypoint_index0,waypoints:Array[Vector3],target,exit_point. step(delta,position,bomb_result,is_destroyed),reset(). _initialize: instantiate; assert initial formation; step35atVector3(0,1200,0),LISTA,false -> APROXIMACION. Loop each waypoint calling step(0,point,LISTA,false). Expect BOMBARDEO andindex3. step0,target,EN_VUELO,false must remainBOMBARDEO; step0,target,IMPACTO,false ->REGRESO; step0,exit_point,IMPACTO,false->COMPLETADA. reset: formation,index0,clock0. SetphaseBOMBARDEO; step0,Vector3.ZERO,FALLO,false ->FALLIDA. reset then step0,Vector3.ZERO,LISTA,true ->FALLIDA. Every failed condition prints TEST FAIL then quit1 and return. Successful end TEST PASS: Agy mission states thenquit0. Under55lines.'''),
('test_bomb_agy.gd','''Test res://bomb_model.gd RefCounted. Fields active=false,spent=false,result=LISTA,position,velocity. release(origin,velocity)->bool;step(delta,target,radius);reset. _initialize: bomb.release(Vector3(0,100,0),Vector3(0,0,-50)) true; second release false. step1/60,target(0,0,-225),radius12; assert active andresultEN_VUELO. Loop600steps1/60 same target,radius. Expect !active,spent,resultIMPACTO,position.y==0. Reset, release same then600steps againsttarget(1000,0,-225),radius12 ->FALLO. Resetassert !spent,!active,resultLISTA. Each failure print TEST FAIL,quit1,return. Atend TEST PASS: Agy bomb airborne hit miss and ammunition thenquit0. Under50lines.'''),
('test_reset_pause_agy.gd','''Test res://core/simulation.gd RefCounted. sim has flight.position Vector3 initially(0,1200,0),speed85;mission.phaseFORMACION,clock0,waypoint_index0;damage.hull100,engines4;flak.bursts0; paused=false; pitch_input/turn_input/throttle_input0. step(delta),reset. _initialize instantiate; paused=true then120calls step1/60 ->clock0 andpositioninitial. paused=false then600calls step1/60 ->clock>0 and position changed. Setdamage.hull=40;engines[0]=0;mission.phase=REGRESO;waypoint_index=3;flak.bursts=17;pitch_input=.5;turn_input=.5;throttle_input=.5;reset. Assertdamagehull100,allengines100,phaseFORMACION,clock0,index0,flakbursts0,positioninitial,speed85,inputs0,pausedfalse. Thenstep1/60expectclock>0 to prove reset not stuck. Each failure TEST FAIL,quit1,return. End TEST PASS: Agy full simulator reset and pause thenquit0. Under60lines.''')]

def run_one(name,brief):
    prompt='''NO TOOLS, no commands, no file access, no questions, no execution claims. Return ONLY a complete valid Godot4.7 GDScript file, extends SceneTree, no markdown. Use _initialize() directly, print errors and explicit exit1 plus return, not assert. Preserve exact string statuses. Never add enum fallbacks or _is_val. No explanations. Keep code compact and finish it.\n'''+brief
    request=LOG/(name+'.request.txt');request.write_text(prompt)
    response=LOG/(name+'.response.txt')
    state('agy','QA Godot: '+name)
    with response.open('w') as out,(LOG/(name+'.stderr.txt')).open('w') as err:
        p=subprocess.run(['agy','--mode','plan','--disable-slash-commands','--print-timeout','90s','--output-format','text','-p',prompt],cwd=ROOT,stdout=out,stderr=err,timeout=100)
    text=response.read_text().strip()
    text=re.sub(r'^```(?:gdscript)?\s*','',text);text=re.sub(r'\s*```$','',text)
    if p.returncode or not text.startswith('extends SceneTree') or 'TEST PASS' not in text or not text.endswith('quit(0)'):
        raise RuntimeError('Entrega incompleta o inválida de '+name)
    OUT.mkdir(exist_ok=True)
    candidate=OUT/name
    candidate.write_text(text+'\n')
    print('Entregado por Agy; pendiente de revisión y ejecución: '+str(candidate),flush=True)

def main():
    LOG.mkdir(parents=True)
    import fcntl
    lock=(ROOT/'logs/agy-qa.lock').open('w')
    fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    results=[]
    for name,brief in JOBS:
        try:
            run_one(name,brief)
            results.append({'file':name,'status':'written_pending_review'})
        except Exception as exc:
            results.append({'file':name,'status':'failed','reason':type(exc).__name__+': '+str(exc)[:250]})
            print(results[-1],flush=True)
    (LOG/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
    state('agy','lote QA terminado; revisar results.json antes de ejecutar',results=str(LOG/'results.json'))

if __name__=='__main__':main()
