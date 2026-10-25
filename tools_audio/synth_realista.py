#!/usr/bin/env python3
"""Revisión de Codex del sintetizador de Claude; biblioteca estándar, semillas fijas.

python3 -I tools_audio/synth_realista.py
Conserva el catálogo, formato y niveles; sustituye señales musicales por mecanismos.
"""
import importlib.util
from pathlib import Path
import random
import sys

spec = importlib.util.spec_from_file_location('b17_original', Path(__file__).with_name('synth_sfx.py'))
s = importlib.util.module_from_spec(spec)
spec.loader.exec_module(s)


def mechanism(rng, n, times=(0.0,), weight=1.0):
    out = s.zeros(n)
    for t in times:
        m = min(s.ns(0.085), n - s.ns(t))
        if m <= 0:
            continue
        strike = s.mul(s.bandpass(s.white(m, rng), rng.uniform(1300, 2800), 0.8),
                       s.env_exp(m, 0.004, 0.0003))
        body = s.mul(s.lowpass(s.pink(m, rng), 650), s.env_exp(m, 0.018, 0.0005))
        panel = s.resonator_bank(strike, [317, 731, 1687],
                                 [0.012, 0.009, 0.006], [0.3, 0.2, 0.08])
        hit = [a + weight * 0.8 * b + 0.12 * c for a, b, c in zip(strike, body, panel)]
        s.mix_into(out, hit, s.ns(t), rng.uniform(0.85, 1.0))
    return [s.fade_edges(s.highpass(out, 90), 0.0002, 0.005)]


PATTERNS = {
    'ui_navigate.wav': (0.0,), 'ui_accept.wav': (0.0, 0.035),
    'ui_back.wav': (0.0, 0.065), 'ui_pause.wav': (0.0, 0.018),
    'ui_profile_change.wav': (0.0, 0.055), 'cue_release_tick.wav': (0.0,),
    'cue_release_now.wav': (0.0, 0.095, 0.19),
    'cue_course_correction.wav': (0.0, 0.15),
}


def environmental_close(rng, n, failed=False):
    # Cierre ambiental sin acorde ni instrumento pretendidamente real.
    channels = []
    common = s.lowpass(s.pink(n, rng), 450)
    envelope = s.env_points(n, [(0, 0.4), (0.12, 1.0), (0.8, 0.8),
                                  (2.2, 0.35 if failed else 0.55), (4.0, 0)])
    for _ in range(2):
        air = s.bandpass(s.pink(n, rng), 700 if failed else 1100, 0.6)
        texture = [(0.75 * a + 0.35 * b) * e for a, b, e in zip(common, air, envelope)]
        sw = mechanism(rng, n, (0.0, 0.11) if failed else (0.0,), 0.8)[0]
        channels.append(s.fade_edges(s.add(texture, s.scale(sw, 0.12)), 0.002, 0.3))
    return channels


def dry_gunshot(rng, n):
    """Estampido aperiódico: sin senos, barridos ni resonadores afinados."""
    # Cada capa usa excitación independiente; no hay oscilador de tono descendente.
    crack = s.mul(s.highpass(s.lowpass(s.white(n, rng), 10500), 1100),
                  s.env_exp(n, 0.0035, 0.00015))
    blast = s.mul(s.highpass(s.lowpass(s.white(n, rng), 3800), 170),
                  s.env_exp(n, 0.019, 0.0003))
    pressure = s.mul(s.highpass(s.lowpass(s.white(n, rng), 780), 85),
                     s.env_exp(n, 0.033, 0.0005))
    out = [1.2 * a + 1.8 * b + 2.7 * c for a, b, c in zip(crack, blast, pressure)]
    # Cerrojo: dos golpes de ruido muy breves, amortiguados, sin cola de campana.
    for time, gain in ((rng.uniform(0.027, 0.034), 0.24),
                       (rng.uniform(0.067, 0.078), 0.14)):
        m = min(s.ns(0.02), n - s.ns(time))
        click = s.mul(s.highpass(s.lowpass(s.white(m, rng), 5200), 650),
                      s.env_exp(m, 0.0025, 0.00015))
        s.mix_into(out, click, s.ns(time), gain)
    return s.fade_edges(s.highpass(out, 65), 0.0001, 0.012)


def gun_resource(name, rng, n):
    if name != 'gun_m2_burst.wav':
        return [dry_gunshot(rng, n)]
    out = s.zeros(n)
    for k in range(8):
        t = k * 0.112 + (rng.uniform(-0.002, 0.002) if k else 0)
        s.mix_into(out, dry_gunshot(rng, s.ns(0.3)), s.ns(t), rng.uniform(0.85, 1.0))
    return [out]


def revised(name, original):
    def generate(rng, n):
        if name.startswith('gun_m2_'):
            return gun_resource(name, rng, n)
        if name in PATTERNS:
            return mechanism(rng, n, PATTERNS[name])
        if name.startswith('stinger_'):
            return environmental_close(rng, n, 'failed' in name)
        channels = original(rng, n)
        result = []
        for channel in channels:
            if name.startswith(('engine_b17', 'fighter_engine', 'formation_drone')):
                # Combustión de banda ancha con variación lenta: rompe la pureza tonal.
                turbulence = s.bandpass(s.pink(n, rng), 380, 0.55)
                modulation = [0.78 + 0.22 * x for x in s.smooth_random(n, rng, 13)]
                texture = s.mul(turbulence, modulation)
                gain = 0.48 * s.rms(channel) / max(s.rms(texture), 1e-9)
                channel = [a + gain * b for a, b in zip(channel, texture)]
            elif name.startswith(('gun_m2', 'flak_', 'fighter_explosion', 'bomb_impact', 'bomb_secondary')):
                # Cuerpo en medios graves; ataque de ruido sin barrido tonal añadido.
                excitation = s.mul(s.bandpass(s.pink(n, rng), 520, 0.65),
                                   s.env_exp(n, 0.055 if name.startswith('gun') else 0.28, 0.0004))
                gain = 0.38 * s.rms(channel) / max(s.rms(excitation), 1e-9)
                channel = [a + gain * b for a, b in zip(channel, excitation)]
            elif name.startswith('hit_hull'):
                damping = s.env_exp(n, 0.055, 0.0002)
                channel = s.mul(channel, damping)
            elif name == 'fighter_falling_whine.wav':
                rough = s.bandpass(s.pink(n, rng), 1100, 0.6)
                gain = 0.6 * s.rms(channel) / max(s.rms(rough), 1e-9)
                channel = [a * 0.65 + gain * b * e for a, b, e in zip(
                    channel, rough, s.env_points(n, [(0, 0.3), (0.3, 1), (4, 0)]))]
            else:
                # Nueva microtextura, preservando la envolvente y función original.
                rough = s.lowpass(s.white(n, rng), 3200)
                channel = [a * (0.97 + 0.06 * b) for a, b in zip(channel, rough)]
            result.append(s.highpass(channel, 28))
        return result
    return generate


for name, entry in s.SPEC.items():
    entry['gen'] = revised(name, entry['gen'])
    entry['tech'] = ('Estampido aperiódico de ruido filtrado y cerrojo seco; sin osciladores, barridos ni resonadores' if name.startswith('gun_m2_')
                     else 'Mecanismo de relé y panel amortiguado, sin notas musicales' if name in PATTERNS
                     else 'Cierre ambiental de aire/estructura, sin acorde' if name.startswith('stinger_')
                     else entry['tech'] + '; revisión v2: textura irregular, filtrado y amortiguación')

if __name__ == '__main__':
    # La ejecución serial evita dependencias y conserva reproducibilidad.
    s.main(['--serial'] + sys.argv[1:])
    groups = {arg.upper() for arg in sys.argv[1:] if not arg.startswith('--')}
    if (not groups or 'B' in groups) and (Path(s.ROOT) / 'godot/B17/assets/audio/source_m2/339976-decoded.wav').exists():
        import runpy
        runpy.run_path(str(Path(__file__).with_name('build_recorded_m2.py')), run_name='__main__')
