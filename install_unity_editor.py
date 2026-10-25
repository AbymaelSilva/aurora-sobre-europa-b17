#!/usr/bin/env python3
"""Descarga oficial en streaming para evitar duplicar 4.5 GB de archivo."""
from pathlib import Path
import base64
import fcntl
import hashlib
import json
import shutil
import subprocess
import tarfile
import time
import urllib.request

ROOT=Path(__file__).resolve().parent
VERSION='6000.3.27f1'
BASE=ROOT/'tools/unity'

class CheckedStream:
    def __init__(self,source):
        self.source=source
        self.hash=hashlib.md5()
        self.count=0
        self.reported=0
    def read(self,size=-1):
        data=self.source.read(size)
        self.hash.update(data)
        self.count+=len(data)
        if self.count-self.reported>128*1024*1024:
            self.reported=self.count
            print(f'Descargados y descomprimiendo: {self.count//(1024*1024)} MiB',flush=True)
            if shutil.disk_usage(ROOT).free<1536*1024*1024:
                raise RuntimeError('Se conserva una reserva de 1.5 GiB; instalación detenida por espacio.')
        return data

def main():
    BASE.mkdir(exist_ok=True)
    lock=(BASE/'install.lock').open('w')
    fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    release=json.loads((ROOT/'logs/unity-release.json').read_text())['results'][0]
    if release['version']!=VERSION:
        raise RuntimeError('Versión distinta de la fijada.')
    asset=next(d for d in release['downloads'] if d['platform']=='LINUX' and d['architecture']=='X86_64')
    final=BASE/VERSION
    binary=final/'Editor/Unity'
    if not binary.exists():
        if shutil.disk_usage(ROOT).free<asset['installedSize']['value']+3*1024**3:
            raise RuntimeError('Falta espacio para el editor y una reserva de 3 GiB.')
        partial=BASE/(VERSION+'.partial')
        if partial.exists():
            raise RuntimeError('Hay una instalación parcial. Revisarla antes de reiniciar la descarga.')
        partial.mkdir()
        print('Instalando Unity '+VERSION+' desde el servidor oficial. Sin aceptar licencia ni introducir credenciales.',flush=True)
        with urllib.request.urlopen(asset['url'],timeout=120) as response:
            stream=CheckedStream(response)
            with tarfile.open(fileobj=stream,mode='r|xz') as archive:
                archive.extractall(partial,filter='data')
            while stream.read(1024*1024): pass
        algorithm,expected=asset['integrity'].split('-',1)
        if algorithm!='md5' or base64.b64encode(stream.hash.digest()).decode()!=expected:
            raise RuntimeError('La integridad no coincide: el editor no se ejecutará.')
        if not (partial/'Editor/Unity').exists():
            raise RuntimeError('La estructura descargada no contiene Editor/Unity.')
        (partial/'INSTALL_EVIDENCE.json').write_text(json.dumps({'version':VERSION,'source':asset['url'],'integrity':asset['integrity'],'bytes':stream.count,'time':time.time()},indent=2))
        partial.rename(final)
    (ROOT/'tools/unity-editor-path.txt').write_text(str(binary)+'\n')
    print('Editor instalado: '+str(binary),flush=True)
    result=subprocess.run([str(binary),'-version'],capture_output=True,text=True,timeout=30)
    print(result.stdout+result.stderr,flush=True)
    (ROOT/'logs/unity-version.txt').write_text(result.stdout+result.stderr)
    print('Siguiente paso: licencia de Unity Hub y apertura del proyecto. No se ha activado una licencia en nombre del usuario.',flush=True)

if __name__=='__main__':
    try: main()
    except Exception as exc:
        print('INSTALACION BLOQUEADA: '+str(exc),flush=True)
        raise SystemExit(1)
