#!/usr/bin/env python3
"""Qwen escribe el núcleo C# del proyecto definitivo; compilarlo después en Unity."""
from pathlib import Path
import json
import re
import time
import urllib.request
from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'unity/B17'
OUT=PROJECT/'Assets/Scripts/Core'
LOG=ROOT/'logs/unity-core'/time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
MODEL='qwen2.5-coder:7b-instruct-q4_K_M'
SYSTEM='''Return only a COMPLETE C# file for Unity 6. Use namespace B17. All requested classes are plain C# classes, NOT MonoBehaviour. Include using UnityEngine; when using Vector3, Quaternion or Mathf. No editor APIs, file/network/process access, assets, input, reflection, unsafe, third-party dependencies or package installs. Exactly the requested class and contract, no extra features. No markdown. Keep fields and methods small and explicit. Unity uses +Z forward. Preserve the exact public names and types.'''
TASKS=[
('FlightModel.cs','''public sealed class FlightModel. Public fields Vector3 Position initialized (0,1200,0); float HeadingDegrees=0, PitchDegrees=0, Speed=85. Reset() restores fields. Step(float pitchInput,float turnInput,float throttleInput,float dt): clamp dt to0..0.05; HeadingDegrees += Mathf.Clamp(turnInput,-1,1)*18*dt; PitchDegrees=Mathf.MoveTowards(PitchDegrees,Mathf.Clamp(pitchInput,-1,1)*10,8*dt); Speed=Mathf.Clamp(Speed+Mathf.Clamp(throttleInput,-1,1)*8*dt,55,110); Vector3 forward=Quaternion.Euler(-PitchDegrees,HeadingDegrees,0)*Vector3.forward; Position += forward*Speed*dt; clamp Position.y>=30. No other methods. Under50 lines.'''),
('BombModel.cs','''public sealed class BombModel. Public fields bool Active=false,Spent=false; Vector3 Position=Vector3.zero,Velocity=Vector3.zero; string Result="READY". Reset() restores all. bool Release(Vector3 position,Vector3 velocity) returns false if Spent, otherwise sets Spent=true Active=true Position/Velocity from args Result="AIRBORNE" return true. Step(float dt,Vector3 target,float radius): if !Active return; dt=Mathf.Clamp(dt,0,.05f); Position += Velocity*dt+Vector3.down*(4.905f*dt*dt); Velocity += Vector3.down*(9.81f*dt); if Position.y<=target.y set Position.y=target.y and Active=false; horizontal distance between Position and target via new Vector2(x,z); Result=distance<=radius ? "HIT":"MISS". No other behavior. Under55 lines.'''),
('DamageModel.cs','''public sealed class DamageModel. Public field float Hull=100; public float[] Engines=new float[]{100,100,100,100}. Reset(): Hull=100, loop reset4engines100. Apply(float amount,int engineIndex): amount=Mathf.Max(0,amount); Hull=Mathf.Clamp(Hull-amount,0,100); if engineIndex>=0&&engineIndex<4 Engines[engineIndex]=Mathf.Clamp(Engines[engineIndex]-amount*2.5f,0,100). public bool Destroyed {get{return Hull<=0;}}. public float ThrustFactor {get{return .6f+.4f*(Engines[0]+Engines[1]+Engines[2]+Engines[3])/400f;}}. No extra methods. Under40 lines.'''),
('FlakModel.cs','''public sealed class FlakModel. Public fields float Timer=0, Interval=2.8f; int BurstCount=0. Reset sets Timer=0 BurstCount=0. bool Step(float dt,bool inZone): if !inZone Timer=0 return false; else Timer+=Mathf.Clamp(dt,0,.05f); if Timer>=Interval Timer-=Interval and BurstCount++ and return true; else false. Pure deterministic interval timer, no RNG, no nodes. Under30 lines.'''),
('MissionModel.cs','''public enum MissionPhase { Formation, Approach, BombRun, Return, Complete, Failed }. public sealed class MissionModel. Public fields MissionPhase Phase=MissionPhase.Formation; int WaypointIndex=0; float Clock=0; Vector3[] Waypoints={new Vector3(0,1200,6000),new Vector3(0,1200,14000),new Vector3(0,1200,22000)}; Vector3 Target=new Vector3(0,0,30000); Vector3 ExitPoint=new Vector3(28000,1200,15000). Reset sets Phase=Formation,WaypointIndex=0,Clock=0. Step(float dt,Vector3 position,string bombResult,bool destroyed): if Phase==Complete||Phase==Failed return; if destroyed set Failed and return; Clock+=Mathf.Max(0,dt); if Phase==Formation&&Clock>=35 set Approach. If Phase==Approach and WaypointIndex<Waypoints.Length and Vector3.Distance(position,Waypoints[WaypointIndex])<300 incrementindex and ifindex>=length set BombRun. If Phase==BombRun and bombResult=="HIT" set Return; else if Phase==BombRun and bombResult=="MISS" set Failed. If Phase==Return and Vector3.Distance(position,ExitPoint)<500 set Complete. public Vector3 NavigationTarget(): for Formation return Waypoints[0], for Approach return Waypoints[Mathf.Min(WaypointIndex,Waypoints.Length-1)], for Return return ExitPoint, otherwise return Target+new Vector3(0,1200,4000). No other methods. Under85 lines.'''),
('FighterPattern.cs','''public static class FighterPattern. public static Vector3 LocalOffset(float elapsed,int index): float t=Mathf.Repeat(elapsed+index*9f,32f); float side=index%2==0?1f:-1f; if t<10 return Vector3.Lerp(new Vector3(side*900,180,1400),new Vector3(side*70,10,80),t/10f); if t<14 return Vector3.Lerp(new Vector3(side*70,10,80),new Vector3(-side*120,-20,-220),(t-10)/4f); return Vector3.Lerp(new Vector3(-side*120,-20,-220),new Vector3(-side*1300,350,-1800),(t-14)/18f). public static bool IsFiring(float elapsed,int index): float t=Mathf.Repeat(elapsed+index*9f,32f); return t>9&&t<12. No other methods. Under35 lines.''')]

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    LOG.mkdir(parents=True)
    import fcntl
    lock=(ROOT/'logs/unity-core.lock').open('w')
    fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    for name,prompt in TASKS:
        path=OUT/name
        if path.exists():
            print('Se conserva fuente existente: '+name,flush=True)
            continue
        state('qwen','Unity C#: generando '+name)
        payload={'model':MODEL,'messages':[{'role':'system','content':SYSTEM},{'role':'user','content':prompt}],'stream':False,'keep_alive':'0s','options':{'num_ctx':4096,'num_predict':2000,'temperature':0.1,'seed':43}}
        (LOG/(name+'.request.json')).write_text(json.dumps(payload,ensure_ascii=False,indent=2))
        request=urllib.request.Request('http://127.0.0.1:11435/api/chat',data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
        with urllib.request.urlopen(request,timeout=300) as response: answer=json.load(response)
        (LOG/(name+'.response.json')).write_text(json.dumps(answer,ensure_ascii=False,indent=2))
        source=answer['message']['content'].strip()
        source=re.sub(r'^```(?:csharp|cs)?\s*','',source)
        source=re.sub(r'\s*```$','',source)
        path.write_text(source+'\n')
        print(name+' generado; pendiente de compilación real en Unity.',flush=True)
    (PROJECT/'Packages').mkdir(exist_ok=True)
    (PROJECT/'Packages/manifest.json').write_text(json.dumps({'dependencies':{'com.unity.modules.audio':'1.0.0','com.unity.modules.imgui':'1.0.0','com.unity.modules.physics':'1.0.0','com.unity.modules.imageconversion':'1.0.0','com.unity.modules.jsonserialize':'1.0.0','com.unity.modules.particlesystem':'1.0.0'}},indent=2))
    (PROJECT/'ProjectSettings').mkdir(exist_ok=True)
    (PROJECT/'ProjectSettings/ProjectVersion.txt').write_text('m_EditorVersion: 6000.3.27f1\nm_EditorVersionWithRevision: 6000.3.27f1 (672d562a42a7)\n')
    (PROJECT/'CORE_AUTHORSHIP.json').write_text(json.dumps({'primary_author':MODEL,'files':[n for n,_ in TASKS],'contracts_and_bootstrap':'Codex','validation':'pending Unity compilation','evidence':str(LOG)},indent=2))
    state('qwen','núcleo Unity generado; pendiente de compilación y pruebas')

if __name__=='__main__':
    try: main()
    except Exception as exc:
        state('qwen','BLOQUEADO',error=str(exc))
        raise SystemExit(1)
