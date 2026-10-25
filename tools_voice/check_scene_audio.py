#!/usr/bin/env python3
"""Comprueba el set activo de diálogo/música y que no se haya tocado la M2."""
import array
import hashlib
import json
import math
from pathlib import Path
import wave

ROOT = Path(__file__).resolve().parent.parent
folder = ROOT / 'godot/B17/assets/audio'
catalog = json.loads((folder/'voice/dialogue_catalog.json').read_text())
assert len(catalog) == 28
assert all(e['spoken_language'] == 'en-US' and e['subtitle_language'] == 'es' and e['spoken_text'] for e in catalog.values())
rows = []
for kind in ['voice', 'music']:
    for path in sorted((folder/kind).glob('*.wav')):
        with wave.open(str(path)) as w:
            count, rate, channels, width = w.getnframes(), w.getframerate(), w.getnchannels(), w.getsampwidth()
            data = array.array('h', w.readframes(count))
        assert (width, rate, channels) == (2, 44100, 1 if kind == 'voice' else 2), path
        rms = math.sqrt(sum(v*v for v in data)/len(data))/32768
        peak = max(abs(v) for v in data)/32768
        assert rms > .001 and peak < .8913, (path, rms, peak)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        row = {'file': str(path.relative_to(ROOT)), 'duration': round(count/rate,3), 'channels': channels,
               'rms_db': round(20*math.log10(rms),2), 'peak_db': round(20*math.log10(peak),2), 'sha256': digest}
        if kind == 'voice':
            entry = catalog[path.stem]
            assert entry['sha256'] == digest
            assert abs(entry['duration'] - count/rate) < .01
        else:
            seam = max(abs(data[ch]-data[-channels+ch]) for ch in range(channels))/32768
            row['seam_jump'] = round(seam,6)
            if path.stem.endswith('_loop'): assert seam < .02, (path, seam)
        rows.append(row)
protected = json.loads((ROOT/'logs/audio_redesign/m2_protected_hashes.json').read_text())
assert all(hashlib.sha256((ROOT/path).read_bytes()).hexdigest() == value for path,value in protected.items())
assert len(rows) == 35
(ROOT/'logs/dialogue_music/asset_metrics.json').write_text(json.dumps(rows,indent=2))
print('PASS: 28 voces en-US/subtítulos es, 7 cues musicales, niveles/formato y 5 WAV M2 intactos')
