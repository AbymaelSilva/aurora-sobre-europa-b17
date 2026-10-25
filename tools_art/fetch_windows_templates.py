#!/usr/bin/env python3
"""Extrae SOLO las plantillas Windows x86_64 del .tpz oficial de Godot mediante peticiones HTTP Range.

Evita descargar 1,28 GB: lee el índice del zip y los dos ejecutables. zipfile verifica el CRC32 de cada entrada.
Autor: Claude.
"""
import io
import sys
import urllib.request
import zipfile
from pathlib import Path

VERSION = '4.7.2'
URL = f'https://github.com/godotengine/godot/releases/download/{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz'
DEST = Path.home() / f'.local/share/godot/export_templates/{VERSION}.stable'
WANTED = ['windows_release_x86_64.exe', 'windows_debug_x86_64.exe', 'version.txt']


class HttpRangeFile(io.RawIOBase):
    def __init__(self, url: str):
        head = urllib.request.urlopen(urllib.request.Request(url, method='HEAD'), timeout=60)
        self.url = head.url  # URL final tras la redirección de GitHub
        self.size = int(head.headers['Content-Length'])
        self.pos = 0
        self.fetched = 0

    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.pos

    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else self.pos + offset if whence == 1 else self.size + offset
        return self.pos

    def read(self, n=-1):
        if n < 0:
            n = self.size - self.pos
        if n == 0 or self.pos >= self.size:
            return b''
        end = min(self.pos + n, self.size) - 1
        req = urllib.request.Request(self.url, headers={'Range': f'bytes={self.pos}-{end}'})
        data = urllib.request.urlopen(req, timeout=300).read()
        self.pos += len(data)
        self.fetched += len(data)
        return data

    def readinto(self, b):
        data = self.read(len(b))
        b[:len(data)] = data
        return len(data)


def main() -> None:
    remote = HttpRangeFile(URL)
    print(f'Archivo remoto: {remote.size / 1e6:.0f} MB', flush=True)
    with zipfile.ZipFile(io.BufferedReader(remote, buffer_size=8 * 1024 * 1024)) as z:
        names = {Path(i.filename).name: i for i in z.infolist()}
        DEST.mkdir(parents=True, exist_ok=True)
        for want in WANTED:
            if want not in names:
                sys.exit(f'No está {want} en el archivo de plantillas')
            info = names[want]
            print(f'Extrayendo {want} ({info.file_size / 1e6:.0f} MB)…', flush=True)
            with z.open(info) as src, open(DEST / want, 'wb') as dst:  # z.open verifica el CRC32 al terminar la lectura
                while chunk := src.read(4 * 1024 * 1024):
                    dst.write(chunk)
    print(f'Listo en {DEST}. Descargado: {remote.fetched / 1e6:.0f} MB de {remote.size / 1e6:.0f} MB', flush=True)


if __name__ == '__main__':
    main()
