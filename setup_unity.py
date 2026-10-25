#!/usr/bin/env python3
"""Prepara Unity Hub portátil oficial sin modificar paquetes del sistema."""
from pathlib import Path
import os
import subprocess
import urllib.request

ROOT=Path(__file__).resolve().parent
FOLDER=ROOT/'tools/unity-hub'
URL='https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup-x86_64.AppImage'

def main():
    FOLDER.mkdir(parents=True,exist_ok=True)
    binary=FOLDER/'UnityHub.AppImage'
    if not binary.exists():
        print('Descargando Unity Hub oficial a la carpeta del proyecto...',flush=True)
        temp=binary.with_suffix('.download')
        size=0
        with urllib.request.urlopen(URL,timeout=90) as response,temp.open('wb') as output:
            while True:
                chunk=response.read(1024*1024)
                if not chunk: break
                size+=len(chunk)
                if size>600*1024*1024:
                    raise RuntimeError('Descarga supera tamaño previsto; comprobar origen.')
                output.write(chunk)
                if size%(20*1024*1024)==0:
                    print(f'{size//(1024*1024)} MiB descargados',flush=True)
        with temp.open('rb') as source:
            if source.read(4)!=b'\x7fELF':
                raise RuntimeError('La descarga no es un ejecutable Linux válido.')
        temp.replace(binary)
        binary.chmod(0o755)
        (FOLDER/'SOURCE.txt').write_text(URL+'\nFuente: https://docs.unity.com/en-us/hub/install-hub-linux\n')
    print('Abriendo Unity Hub. El acceso a la cuenta y la aceptación de licencia corresponden al usuario.',flush=True)
    print('No se ha comprado una licencia ni se ha descargado el editor automáticamente.',flush=True)
    subprocess.run([str(binary),'--appimage-extract-and-run'],check=True,cwd=FOLDER)

if __name__=='__main__':
    try: main()
    except Exception as exc:
        print('Preparación de Unity: '+str(exc),flush=True)
        raise SystemExit(1)
