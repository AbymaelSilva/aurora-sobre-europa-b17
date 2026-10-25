#!/usr/bin/env python3
from pathlib import Path
import json
import re
import sys
import time
import urllib.request
from run_team import state

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT/'unity/B17'

def main():
    path=(PROJECT/sys.argv[1]).resolve()
    if not path.is_relative_to(PROJECT.resolve()): raise ValueError('Ruta fuera del proyecto')
    diagnostic=Path(sys.argv[2]).read_text()
    folder=ROOT/'logs/unity-repairs'/time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())
    folder.mkdir(parents=True)
    before=path.read_text()
    (folder/(path.name+'.before')).write_text(before)
    prompt='Correct this exact Unity 6 C# file. Return ONLY complete corrected source, no markdown. Preserve public class and method names and namespace B17. Do not add dependencies, assets, input, networking or file IO.\nDiagnostic:\n'+diagnostic+'\nCurrent source:\n'+before
    payload={'model':'qwen2.5-coder:7b-instruct-q4_K_M','messages':[{'role':'user','content':prompt}],'stream':False,'keep_alive':'0s','options':{'num_ctx':4096,'num_predict':3200,'temperature':0.05,'seed':73}}
    (folder/'request.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2))
    state('qwen','corrigiendo Unity: '+path.name)
    req=urllib.request.Request('http://127.0.0.1:11435/api/chat',data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
    with urllib.request.urlopen(req,timeout=300) as response: answer=json.load(response)
    (folder/'response.json').write_text(json.dumps(answer,ensure_ascii=False,indent=2))
    text=answer['message']['content'].strip()
    text=re.sub(r'^```(?:csharp|cs)?\s*','',text)
    text=re.sub(r'\s*```$','',text)
    path.write_text(text+'\n')
    print('Corrección de Qwen guardada; pendiente de comprobar: '+path.name,flush=True)

if __name__=='__main__': main()
