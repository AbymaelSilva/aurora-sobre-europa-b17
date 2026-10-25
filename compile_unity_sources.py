#!/usr/bin/env python3
"""Chequeo C# estático con Roslyn y referencias reales; no ejecuta el editor."""
from pathlib import Path
import subprocess
from run_team import state

ROOT=Path(__file__).resolve().parent
DATA=ROOT/'tools/unity/6000.3.27f1/Editor/Data'
PROJECT=ROOT/'unity/B17'

def main():
    output=ROOT/'logs/unity-static'
    output.mkdir(exist_ok=True)
    refs={}
    profile=DATA/'UnityReferenceAssemblies/unity-4.8-api'
    for folder in [profile,profile/'Facades',DATA/'Managed/UnityEngine',DATA/'Managed']:
        for file in folder.glob('*.dll'):
            refs.setdefault(file.name,file)
    sources=sorted((PROJECT/'Assets/Scripts').rglob('*.cs'))
    args=['-nologo','-target:library','-langversion:latest','-nostdlib+','-define:UNITY_EDITOR,UNITY_EDITOR_LINUX,UNITY_STANDALONE_LINUX','-out:'+str(output/'B17.StaticCheck.dll')]
    args += ['-r:'+str(path) for path in refs.values()]
    args += [str(path) for path in sources]
    response=output/'compile.rsp'
    response.write_text('\n'.join('"'+s+'"' for s in args)+'\n')
    state('compiler','compilando C# contra ensamblados Unity; no ejecuta el juego')
    result=subprocess.run([str(DATA/'NetCoreRuntime/dotnet'),str(DATA/'DotNetSdkRoslyn/csc.dll'),'@'+str(response)],capture_output=True,text=True,timeout=90)
    report=result.stdout+result.stderr
    (output/'compiler.log').write_text(report)
    print(report or 'Sin diagnósticos de compilación.',flush=True)
    state('compiler','compilación C# estática superada; editor y juego aún pendientes' if result.returncode==0 else 'errores C# pendientes',exit_code=result.returncode)
    raise SystemExit(result.returncode)

if __name__=='__main__': main()
