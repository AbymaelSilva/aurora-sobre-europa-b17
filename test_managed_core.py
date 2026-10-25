#!/usr/bin/env python3
"""Ejecuta el núcleo real con Mono. No ejecuta ni elude el editor de Unity."""
from pathlib import Path
import os
import subprocess
import sys
from run_team import state

ROOT=Path(__file__).resolve().parent
DATA=ROOT/'tools/unity/6000.3.27f1/Editor/Data'
OUT=ROOT/'logs/unity-static'

def main():
    subprocess.run([sys.executable,str(ROOT/'compile_unity_sources.py')],check=True,timeout=100)
    arguments=(OUT/'compile.rsp').read_text().splitlines()
    arguments=[line for line in arguments if not line.startswith('"-target:') and not line.startswith('"-out:') and not line.endswith('.cs"')]
    arguments += ['"-target:exe"','"-out:'+str(OUT/'B17.ManagedTests.exe')+'"','"-r:'+str(OUT/'B17.StaticCheck.dll')+'"','"'+str(ROOT/'tests/ManagedCoreRunner.cs')+'"']
    rsp=OUT/'managed-tests.rsp'
    rsp.write_text('\n'.join(arguments)+'\n')
    compile_result=subprocess.run([str(DATA/'NetCoreRuntime/dotnet'),str(DATA/'DotNetSdkRoslyn/csc.dll'),'@'+str(rsp)],capture_output=True,text=True,timeout=60)
    if compile_result.returncode:
        print(compile_result.stdout+compile_result.stderr,flush=True)
        raise SystemExit(compile_result.returncode)
    env=dict(os.environ,MONO_PATH=os.pathsep.join([str(OUT),str(DATA/'Managed/UnityEngine'),str(DATA/'Managed')]))
    state('core-tests','ejecutando simulación real de lógica; sin editor ni renderizado')
    result=subprocess.run([str(DATA/'MonoBleedingEdge/bin/mono'),str(OUT/'B17.ManagedTests.exe')],env=env,capture_output=True,text=True,timeout=60)
    report=result.stdout+result.stderr
    (OUT/'managed-tests.log').write_text(report)
    print(report,flush=True)
    state('core-tests','lógica superada; Unity visual y controles pendientes' if result.returncode==0 else 'fallos de lógica o dependencia pendientes',exit_code=result.returncode)
    raise SystemExit(result.returncode)

if __name__=='__main__': main()
