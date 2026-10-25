#!/usr/bin/env python3
"""Write level-matched A/B pilots and 10 repetitions. Never plays audio."""
import array
import importlib.util
import json
import math
from pathlib import Path
import wave

spec=importlib.util.spec_from_file_location('contextual',Path(__file__).with_name('build_contextual_set.py'))
b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)


def read(path):
    with wave.open(str(path)) as w:
        vals=array.array('h',w.readframes(w.getnframes()))
        if b.sys.byteorder!='little':vals.byteswap()
        return [[v/32768 for v in vals[c::w.getnchannels()]] for c in range(w.getnchannels())]


def main():
    b.guard();dest=b.BASE/'review';dest.mkdir(exist_ok=True);report={}
    for name in b.PILOTS:
        old=read(b.LOG/'backup'/name);new=read(b.CANDIDATES/name)
        def r(ch):return math.sqrt(sum(v*v for c in ch for v in c)/sum(map(len,ch)))
        ra,rb=r(old),r(new)
        # Both sides share attainable RMS; headroom is preserved without clipping/limiting.
        peak_a=max(abs(v) for c in old for v in c);peak_b=max(abs(v) for c in new for v in c)
        target=min(ra,rb,10**(-1.3/20)*ra/peak_a,10**(-1.3/20)*rb/peak_b)
        a=[[v*target/ra for v in c] for c in old];c=[[v*target/rb for v in ch] for ch in new]
        stem=name.removesuffix('.wav')
        for label,channels in [('A_anterior',a),('B_contextual',c)]:
            b.write(dest/f'{stem}_{label}.wav',channels,b.CHECK.EXPECTED[name][2])
            if b.CHECK.EXPECTED[name][2]:b.write(dest/f'{stem}_{label}_10x.wav',[ch*10 for ch in channels])
        b.write(dest/f'{stem}_AB.wav',[x+[0.]*b.ns(.6)+y for x,y in zip(a,c)])
        report[name]={'A_sha256':b.sha(b.LOG/'backup'/name),'B_sha256':b.sha(b.CANDIDATES/name),
                      'common_rms_dbfs':b.db(target),'A_gain_db':b.db(target/ra),'B_gain_db':b.db(target/rb),
                      'order':'A anterior, 600 ms silence, B contextual','listened':False}
    (dest/'levels.json').write_text(json.dumps(report,indent=2))
    (dest/'README.md').write_text('''# Revisión A/B contextual v4

No se ha reproducido audio ni realizado escucha humana. A = banco anterior respaldado;
B = candidato contextual. Cada pareja tiene el mismo RMS y margen de pico, sin limitador.
`*_AB.wav`: A, pausa intencionada de 600 ms, B. `*_10x.wav`: diez vueltas continuas
para evaluar unión, repetición y fatiga. Los archivos de revisión no son el banco activo.
No contienen M2. El volumen RMS comparable no garantiza igual sonoridad percibida.

Escuchar manualmente primero motor exterior/interior, flak cercano y cambio de puesto.
Comprobar ruido ajeno, transitorios, textura y cansancio; después evaluar la mezcla en misión.
Los bucles del banco incluyen smpl; los 10x son archivos lineales sin bucle.
`levels.json` documenta las ganancias y hashes A/B. Regenerar con:
`python3 -I tools_audio/review_contextual_set.py`.
''')
    b.guard();print('A/B 4 pilotos; 10x de ambos motores; sin reproducción')


if __name__=='__main__':main()
