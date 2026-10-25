#!/usr/bin/env python3
"""Adapta la muestra CC0 de ikbenraar; no sintetiza el estampido.

La fuente es una preescucha MP3 de campo, no una toma seca de AN/M2 de aviación.
Procedencia y licencia en assets/audio/source_m2/source.json.
"""
from pathlib import Path
import importlib.util
import json
import struct
import wave

spec = importlib.util.spec_from_file_location('synthesis', Path(__file__).with_name('synth_sfx.py'))
s = importlib.util.module_from_spec(spec)
spec.loader.exec_module(s)
SOURCE = Path(s.ROOT) / 'godot/B17/assets/audio/source_m2/339976-decoded.wav'


def build():
    with wave.open(str(SOURCE)) as w:
        assert (w.getframerate(), w.getnchannels(), w.getsampwidth()) == (44100, 1, 2)
        data = [v / 32768 for v in struct.unpack('<%dh' % w.getnframes(), w.readframes(w.getnframes()))]
    shots = []
    for index, start in enumerate((0.9225, 1.0250, 1.1270), 1):
        # Extraer un solo ataque; excluir el siguiente disparo de la ráfaga fuente.
        attack = data[s.ns(start):s.ns(start) + s.ns(0.098)]
        tail = data[s.ns(1.532):s.ns(1.532) + s.ns(0.22)]
        out = s.zeros(s.ns(0.3))
        out[:len(attack)] = attack
        join, fade = s.ns(0.085), s.ns(0.013)
        gain = s.rms(attack[-fade:]) / max(s.rms(tail[:fade]), 1e-9)
        for i in range(len(out) - join):
            t = min(1.0, i / fade)
            old = out[join + i]
            out[join + i] = old * (1 - t) + tail[i] * gain * t
        out = s.fade_edges(s.highpass(out, 65, 0.7), 0.0003, 0.025)
        out = s.finalize([out], -14.0)[0]
        shots.append(out)
        s.write_wav(str(Path(s.OUT_DIR) / f'gun_m2_shot_{index:02d}.wav'), [out])
    burst = s.zeros(s.ns(1.0))
    for i in range(8):
        s.mix_into(burst, shots[i % 3], s.ns(i * 0.1), 0.95 if i % 2 else 1.0)
    burst = s.finalize([s.fade_edges(burst, 0.0002, 0.03)], -14.0)
    s.write_wav(str(Path(s.OUT_DIR) / 'gun_m2_burst.wav'), burst)
    manifest_path = Path(s.MANIFEST)
    manifest = json.loads(manifest_path.read_text())
    for name in manifest:
        if name.startswith('gun_m2_'):
            manifest[name]['tech'] = 'Grabación CC0 de M2 .50 identificada por ikbenraar; recorte de ataques, cola compartida, paso alto 65 Hz, fundidos y nivel; ráfaga montada a 100 ms'
            with wave.open(str(Path(s.OUT_DIR) / name)) as w:
                values = [v / 32768 for v in struct.unpack('<%dh' % w.getnframes(), w.readframes(w.getnframes()))]
            import math
            manifest[name]['rms_db'] = round(20 * math.log10(s.rms(values)), 2)
            manifest[name]['peak_db'] = round(20 * math.log10(s.peak(values)), 2)
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1))
    print('4 WAV M2 adaptados de la grabación CC0; pendiente de aceptación auditiva.')


if __name__ == '__main__':
    build()
