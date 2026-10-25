#!/usr/bin/env python3
"""Sintetizador reproducible de efectos de sonido para «Aurora sobre Europa» (B-17).

Solo biblioteca estándar. Ejecutar desde la raíz del proyecto:

    python3 -I tools_audio/synth_sfx.py            # regenera los 47 WAV
    python3 -I tools_audio/synth_sfx.py A G        # solo los grupos indicados
    python3 -I tools_audio/synth_sfx.py --serial   # sin multiproceso

Cada archivo usa su propio random.Random con semilla fija (crc32 del nombre), así que
la salida es idéntica en cada ejecución e independiente del orden o del paralelismo.
Escrito por Claude (2026-10-24).
"""
import json
import math
import os
import random
import struct
import sys
import wave
import zlib

SR = 44100
TAU = 2.0 * math.pi
CEILING = 0.88            # −1.11 dBFS: deja margen bajo el límite de −1 dBFS
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "godot", "B17", "assets", "audio", "sfx")
MANIFEST = os.path.join(ROOT, "logs", "audio", "synth_manifest.json")

# Objetivos de RMS por grupo de nivel (dBFS)
LVL_ENGINE, LVL_WEAPON, LVL_UI = -20.0, -14.0, -22.0


# ─────────────────────────────── utilidades ────────────────────────────────
def ns(sec):
    return int(round(sec * SR))


def zeros(n):
    return [0.0] * n


def as_list(v, n):
    return v if isinstance(v, list) else [float(v)] * n


def mix_into(dst, src, offset=0, gain=1.0):
    """Suma src en dst a partir de la muestra offset (recorta lo que sobre)."""
    n = len(dst)
    if offset < 0:
        src = src[-offset:]
        offset = 0
    m = min(len(src), n - offset)
    for i in range(m):
        dst[offset + i] += src[i] * gain
    return dst


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def scale(a, g):
    return [x * g for x in a]


def add(*sigs):
    n = max(len(s) for s in sigs)
    out = zeros(n)
    for s in sigs:
        mix_into(out, s)
    return out


def rms(x):
    return math.sqrt(sum(v * v for v in x) / max(1, len(x)))


def peak(x):
    return max(abs(v) for v in x) if x else 0.0


def fade_edges(x, fin=0.0005, fout=0.01):
    n = len(x)
    a, b = max(1, ns(fin)), max(1, ns(fout))
    for i in range(min(a, n)):
        x[i] *= i / a
    for i in range(min(b, n)):
        x[n - 1 - i] *= i / b
    return x


def smooth_random(n, rng, rate, lo=-1.0, hi=1.0):
    """Señal de control aleatoria y suave (interpolación coseno entre puntos a `rate` Hz)."""
    npts = int(n / SR * rate) + 3
    pts = [rng.uniform(lo, hi) for _ in range(npts)]
    out = [0.0] * n
    step = rate / SR
    cos = math.cos
    pi = math.pi
    for i in range(n):
        u = i * step
        k = int(u)
        f = (1.0 - cos(pi * (u - k))) * 0.5
        out[i] = pts[k] + (pts[k + 1] - pts[k]) * f
    return out


def ramp(n, v0, v1, curve=1.0):
    if n <= 1:
        return [v1] * n
    return [v0 + (v1 - v0) * (i / (n - 1)) ** curve for i in range(n)]


def exp_ramp(n, v0, v1):
    """Rampa exponencial (útil para barridos de frecuencia)."""
    if n <= 1:
        return [v1] * n
    r = math.log(v1 / v0)
    return [v0 * math.exp(r * i / (n - 1)) for i in range(n)]


# ─────────────────────────────── osciladores ───────────────────────────────
def _phasor(freq, n, phase=0.0):
    out = [0.0] * n
    p = phase % 1.0
    if isinstance(freq, list):
        inv = 1.0 / SR
        for i in range(n):
            out[i] = p
            p += freq[i] * inv
            if p >= 1.0:
                p -= math.floor(p)
    else:
        inc = freq / SR
        for i in range(n):
            out[i] = p
            p += inc
            if p >= 1.0:
                p -= 1.0
    return out


def sine(freq, n, phase=0.0):
    s = math.sin
    return [s(TAU * p) for p in _phasor(freq, n, phase)]


def _blep(t, dt):
    if t < dt:
        t /= dt
        return t + t - t * t - 1.0
    if t > 1.0 - dt:
        t = (t - 1.0) / dt
        return t * t + t + t + 1.0
    return 0.0


def saw(freq, n, phase=0.0):
    """Diente de sierra con polyBLEP (sin aliasing audible)."""
    f = as_list(freq, n)
    ph = _phasor(f, n, phase)
    out = [0.0] * n
    for i in range(n):
        dt = f[i] / SR
        p = ph[i]
        out[i] = 2.0 * p - 1.0 - _blep(p, dt)
    return out


def pulse(freq, n, width=0.5, phase=0.0):
    """Pulso de ancho variable con polyBLEP."""
    f = as_list(freq, n)
    ph = _phasor(f, n, phase)
    out = [0.0] * n
    for i in range(n):
        dt = f[i] / SR
        p = ph[i]
        v = 1.0 if p < width else -1.0
        v += _blep(p, dt)
        q = p - width
        if q < 0.0:
            q += 1.0
        v -= _blep(q, dt)
        out[i] = v
    return out


def square(freq, n, phase=0.0):
    return pulse(freq, n, 0.5, phase)


def fm(carrier, mod_freq, index, n, phase=0.0):
    """Modulación de frecuencia (por fase): sin(2π·fc·t + I·sin(2π·fm·t)). index puede ser lista."""
    pc = _phasor(carrier, n, phase)
    pm = _phasor(mod_freq, n)
    idx = as_list(index, n)
    s = math.sin
    return [s(TAU * pc[i] + idx[i] * s(TAU * pm[i])) for i in range(n)]


def am(x, rate, depth, phase=0.0):
    """Modulación de amplitud: x·(1 − depth/2 + depth/2·sin)."""
    m = sine(rate, len(x), phase)
    h = depth * 0.5
    return [v * (1.0 - h + h * mm) for v, mm in zip(x, m)]


# ─────────────────────────────────── ruido ──────────────────────────────────
def white(n, rng):
    g = rng.random
    return [2.0 * g() - 1.0 for _ in range(n)]


def pink(n, rng):
    """Ruido rosa (filtro de Paul Kellet), normalizado a ~±1."""
    g = rng.random
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    out = [0.0] * n
    for i in range(n):
        w = 2.0 * g() - 1.0
        b0 = 0.99886 * b0 + w * 0.0555179
        b1 = 0.99332 * b1 + w * 0.0750759
        b2 = 0.96900 * b2 + w * 0.1538520
        b3 = 0.86650 * b3 + w * 0.3104856
        b4 = 0.55000 * b4 + w * 0.5329522
        b5 = -0.7616 * b5 - w * 0.0168980
        out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11
        b6 = w * 0.115926
    return out


def brown(n, rng):
    """Ruido marrón (integrador con fuga)."""
    g = rng.random
    y = 0.0
    out = [0.0] * n
    for i in range(n):
        y = 0.995 * y + 0.06 * (2.0 * g() - 1.0)
        out[i] = y
    return out


def crackle(n, rng, density, amp_lo=0.2, amp_hi=1.0):
    """Tren de impulsos aleatorios (chasquidos) con `density` eventos por segundo."""
    out = [0.0] * n
    p = density / SR
    g = rng.random
    for i in range(n):
        if g() < p:
            out[i] = rng.uniform(amp_lo, amp_hi) * (1 if g() < 0.5 else -1)
    return out


# ────────────────────────────────── filtros ─────────────────────────────────
def _rbj(kind, fc, q, gain_db):
    fc = max(5.0, min(fc, SR * 0.45))
    w = TAU * fc / SR
    cw, sw = math.cos(w), math.sin(w)
    al = sw / (2.0 * q)
    if kind == "lp":
        b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
        a0, a1, a2 = 1 + al, -2 * cw, 1 - al
    elif kind == "hp":
        b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
        a0, a1, a2 = 1 + al, -2 * cw, 1 - al
    elif kind == "bp":       # ganancia 0 dB en el pico
        b0, b1, b2 = al, 0.0, -al
        a0, a1, a2 = 1 + al, -2 * cw, 1 - al
    elif kind == "peak":     # ecualizador paramétrico (resonancia con ganancia)
        A = 10 ** (gain_db / 40)
        b0, b1, b2 = 1 + al * A, -2 * cw, 1 - al * A
        a0, a1, a2 = 1 + al / A, -2 * cw, 1 - al / A
    else:
        raise ValueError(kind)
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def biquad(x, kind, fc, q=0.7071, gain_db=0.0):
    b0, b1, b2, a1, a2 = _rbj(kind, fc, q, gain_db)
    out = [0.0] * len(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x):
        y = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, y
        out[i] = y
    return out


def lowpass(x, fc, q=0.7071):
    return biquad(x, "lp", fc, q)


def highpass(x, fc, q=0.7071):
    return biquad(x, "hp", fc, q)


def bandpass(x, fc, q=1.0):
    return biquad(x, "bp", fc, q)


def resonant(x, fc, q=8.0, gain_db=12.0):
    """Realce resonante estrecho (pico paramétrico)."""
    return biquad(x, "peak", fc, q, gain_db)


def svf(x, fc, q=0.7071, mode="lp", block=16):
    """Filtro de estado variable TPT con frecuencia de corte variable (lista o número)."""
    n = len(x)
    f = as_list(fc, n)
    k = 1.0 / q
    ic1 = ic2 = 0.0
    out = [0.0] * n
    a1 = a2 = a3 = 0.0
    tan, pi = math.tan, math.pi
    for i in range(n):
        if i % block == 0:
            g = tan(pi * max(10.0, min(f[i], SR * 0.45)) / SR)
            a1 = 1.0 / (1.0 + g * (g + k))
            a2 = g * a1
            a3 = g * a2
        v0 = x[i]
        v3 = v0 - ic2
        v1 = a1 * ic1 + a2 * v3
        v2 = ic2 + a2 * ic1 + a3 * v3
        ic1 = 2.0 * v1 - ic1
        ic2 = 2.0 * v2 - ic2
        if mode == "lp":
            out[i] = v2
        elif mode == "bp":
            out[i] = v1 * k          # ganancia unidad en el pico
        else:
            out[i] = v0 - k * v1 - v2
    return out


def onepole_lp(x, fc):
    a = math.exp(-TAU * fc / SR)
    y = 0.0
    out = [0.0] * len(x)
    for i, v in enumerate(x):
        y = v + (y - v) * a
        out[i] = y
    return out


def resonator_bank(x, freqs, decays, gains):
    """Banco de resonadores de dos polos (modos de una campana, chapa o casquillo).
    decays: tiempo (s) hasta −60 dB de cada modo."""
    n = len(x)
    out = [0.0] * n
    for f, t60, g in zip(freqs, decays, gains):
        if f >= SR * 0.45:
            continue
        w = TAU * f / SR
        r = 10 ** (-3.0 / (t60 * SR))
        c1 = 2.0 * r * math.cos(w)
        c2 = -r * r
        gn = g * math.sin(w)
        y1 = y2 = 0.0
        for i in range(n):
            y = c1 * y1 + c2 * y2 + x[i] * gn
            y2, y1 = y1, y
            out[i] += y
    return out


# ──────────────────────────── envolventes y dinámica ───────────────────────
def env_adsr(n, a, d, s, r):
    """ADSR clásica: sostiene hasta n − r."""
    na, nd, nr = ns(a), ns(d), ns(r)
    ns_ = max(0, n - na - nd - nr)
    e = []
    e += [i / max(1, na) for i in range(na)]
    e += [1.0 - (1.0 - s) * i / max(1, nd) for i in range(nd)]
    e += [s] * ns_
    e += [s * (1.0 - i / max(1, nr)) for i in range(nr)]
    return (e + [0.0] * n)[:n]


def env_exp(n, tau, attack=0.0005, delay=0.0):
    """Ataque lineal y caída exponencial exp(−t/tau)."""
    na, nd = max(1, ns(attack)), ns(delay)
    e = [0.0] * n
    ex = math.exp
    for i in range(nd, n):
        j = i - nd
        if j < na:
            e[i] = j / na
        else:
            e[i] = ex(-(j - na) / (tau * SR))
    return e


def env_points(n, pts):
    """Envolvente por tramos lineales: pts = [(t_s, valor), ...]."""
    e = [0.0] * n
    pts = sorted(pts)
    for k in range(len(pts) - 1):
        t0, v0 = pts[k]
        t1, v1 = pts[k + 1]
        i0, i1 = ns(t0), ns(t1)
        for i in range(max(0, i0), min(n, i1)):
            e[i] = v0 + (v1 - v0) * (i - i0) / max(1, i1 - i0)
    last = ns(pts[-1][0])
    for i in range(max(0, last), n):
        e[i] = pts[-1][1]
    return e


def soft_clip(x, drive=1.5):
    """Distorsión suave tanh, normalizada para que ±1 siga dando ±1."""
    t = math.tanh
    k = 1.0 / t(drive)
    return [t(drive * v) * k for v in x]


def soft_limit(x, ceiling=CEILING, knee=0.6):
    """Limitador sin memoria: lineal hasta knee·ceiling, luego tanh hasta ceiling."""
    k = knee * ceiling
    span = ceiling - k
    t = math.tanh
    out = [0.0] * len(x)
    for i, v in enumerate(x):
        a = abs(v)
        if a <= k:
            out[i] = v
        else:
            y = k + span * t((a - k) / span)
            out[i] = y if v > 0 else -y
    return out


# ──────────────────────────────── espacio ───────────────────────────────────
_COMBS = (1116, 1188, 1277, 1356, 1422, 1491)
_ALLP = (556, 441, 341)


def _reverb_wet(x, decay, damp, size, spread, predelay):
    n = len(x)
    pd = ns(predelay)
    inp = [0.0] * pd + x[:n - pd] if pd else x
    acc = [0.0] * n
    for base in _COMBS:
        L = max(8, int(base * size) + spread)
        buf = [0.0] * L
        fb = 10 ** (-3.0 * L / (SR * decay))
        filt = 0.0
        idx = 0
        dm, dm1 = damp, 1.0 - damp
        for i in range(n):
            o = buf[idx]
            filt = o * dm1 + filt * dm
            buf[idx] = inp[i] + filt * fb
            idx += 1
            if idx == L:
                idx = 0
            acc[i] += o
    for base in _ALLP:
        L = max(4, int(base * size) + spread // 2)
        buf = [0.0] * L
        idx = 0
        for i in range(n):
            bo = buf[idx]
            v = acc[i]
            acc[i] = bo - v
            buf[idx] = v + bo * 0.5
            idx += 1
            if idx == L:
                idx = 0
    return acc


def reverb(x, decay=0.5, damp=0.35, mix=0.2, predelay=0.01, size=0.7, spread=0):
    """Reverberación sencilla tipo Schroeder/Freeverb: 6 peines realimentados con
    amortiguación + 3 pasa-todo. mix = relación RMS húmedo/seco."""
    wet = _reverb_wet(x, decay, damp, size, spread, predelay)
    rw, rd = rms(wet), rms(x)
    g = mix * rd / rw if rw > 1e-12 else 0.0
    return [a + b * g for a, b in zip(x, wet)]


def reverb_stereo(L, R, decay=0.8, damp=0.35, mix=0.25, predelay=0.012, size=0.8):
    mono = [(a + b) * 0.5 for a, b in zip(L, R)]
    wl = _reverb_wet(mono, decay, damp, size, 0, predelay)
    wr = _reverb_wet(mono, decay, damp, size, 23, predelay)
    rd = rms(mono)
    gl = mix * rd / max(1e-12, rms(wl))
    gr = mix * rd / max(1e-12, rms(wr))
    return ([a + b * gl for a, b in zip(L, wl)], [a + b * gr for a, b in zip(R, wr)])


def pan(x, p):
    """Panorámica de potencia constante; p en [−1, 1] (número o lista)."""
    n = len(x)
    pp = as_list(p, n)
    c, s = math.cos, math.sin
    L = [x[i] * c((pp[i] + 1.0) * math.pi / 4) for i in range(n)]
    R = [x[i] * s((pp[i] + 1.0) * math.pi / 4) for i in range(n)]
    return L, R


# ──────────────────────────────── doppler ───────────────────────────────────
def flyby_path(n, v, d, t_close, c=324.0, x_offset=0.0):
    """Trayectoria rectilínea a velocidad v (m/s) que pasa a distancia mínima d (m) en t_close.
    Resuelve el tiempo de emisión de forma exacta (retardo de propagación incluido).
    Devuelve (ratio_de_tono, distancia, posición_lateral_normalizada) por muestra."""
    a = c * c - v * v
    taus = [0.0] * (n + 1)
    for i in range(n + 1):
        T = i / SR - t_close
        disc = c ** 4 * T * T - a * (c * c * T * T - d * d)
        taus[i] = (c * c * T - math.sqrt(max(0.0, disc))) / a
    ratio, dist, lat = [0.0] * n, [0.0] * n, [0.0] * n
    for i in range(n):
        ratio[i] = (taus[i + 1] - taus[i]) * SR
        x = v * taus[i] + x_offset
        r = math.sqrt(x * x + d * d)
        dist[i] = r
        lat[i] = x / r
    return ratio, dist, lat


def recede_path(n, v, d0, angle_deg=35.0, c=324.0):
    """Fuente que se aleja en línea recta desde d0 formando `angle` con la línea de visión."""
    ca = math.cos(math.radians(angle_deg))
    sa = math.sin(math.radians(angle_deg))
    # posición en tiempo de emisión te: (d0 + v·te·ca, v·te·sa); t = te + r/c → bisección
    ratio, dist = [0.0] * n, [0.0] * n
    prev_te = None
    te = -d0 / c
    for i in range(n + 1):
        t = i / SR
        lo, hi = te - 0.01, t
        for _ in range(40):
            mid = (lo + hi) * 0.5
            px, py = d0 + v * mid * ca, v * mid * sa
            if mid + math.sqrt(px * px + py * py) / c < t:
                lo = mid
            else:
                hi = mid
        te = (lo + hi) * 0.5
        if i < n:
            px, py = d0 + v * te * ca, v * te * sa
            dist[i] = math.sqrt(px * px + py * py)
        if prev_te is not None:
            ratio[i - 1] = (te - prev_te) * SR
        prev_te = te
    return ratio, dist


def doppler_resample(x, ratio):
    """Doppler genérico por relectura a velocidad variable con interpolación lineal."""
    n = len(ratio)
    out = [0.0] * n
    pos = 0.0
    m = len(x) - 2
    for i in range(n):
        k = int(pos)
        if k >= m:
            break
        f = pos - k
        out[i] = x[k] + (x[k + 1] - x[k]) * f
        pos += ratio[i]
    return out


# ──────────────────────────────── bucles ────────────────────────────────────
def make_loop(chans, loop_n, fade_n):
    """Fundido cruzado de potencia constante: la cola (loop_n..loop_n+fade_n) se funde
    sobre el principio, de modo que out[-1] → out[0] es continuo."""
    out = []
    for x in chans:
        assert len(x) >= loop_n + fade_n
        y = x[:loop_n]
        for i in range(fade_n):
            u = i / fade_n * math.pi / 2
            y[i] = x[i] * math.sin(u) + x[loop_n + i] * math.cos(u)
        out.append(y)
    return out


def seam_rotate(chans):
    """Gira el bucle (sin alterarlo) para que la unión caiga en el par de muestras más suave."""
    n = len(chans[0])
    best, bi = 1e9, 0
    lo, hi = n // 10, n - n // 10
    for i in range(lo, hi):
        j = max(abs(c[i] - c[i - 1]) for c in chans) + 0.25 * max(abs(c[i]) for c in chans)
        if j < best:
            best, bi = j, i
    return [c[bi:] + c[:bi] for c in chans]


# ──────────────────────────── bloques de diseño ─────────────────────────────
def piston_engine(n, rng, rpm, cylinders, pitch=None, pulse_tau=0.18, cyl_var=0.12,
                  roughness=0.04, drift=0.003, drift_rate=0.4, misfire=0.0, misfire_ramp=None,
                  prop_ratio=0.5625, blades=3):
    """Motor de pistones de 4 tiempos. Devuelve (escape, hélice, envolvente_de_combustión).
    - escape: tren de pulsos a cilindros/2 por vuelta del cigüeñal, con amplitud por cilindro;
    - hélice: paso de pala (rpm·reducción·palas);
    - pitch: multiplicador de tono por muestra (doppler, aceleración)."""
    fire_f = rpm / 60.0 * cylinders / 2.0
    prop_f = rpm / 60.0 * prop_ratio * blades
    dr = smooth_random(n, rng, drift_rate)
    TL = 512
    tbl = []
    for i in range(TL):
        ph = i / TL
        tbl.append((1.0 - math.exp(-ph / 0.012)) * math.exp(-ph / pulse_tau))
    mean = sum(tbl) / TL
    tbl = [v - mean for v in tbl]
    ptbl = []
    for i in range(TL):
        ph = i / TL
        ptbl.append(math.sin(math.pi * ph) ** 6 - 0.3125 + 0.25 * math.sin(TAU * ph))
    cyl_amp = [1.0 + cyl_var * (2.0 * rng.random() - 1.0) for _ in range(cylinders)]
    pm = pitch if pitch is not None else None
    mr = misfire_ramp
    fire, prop, comb = [0.0] * n, [0.0] * n, [0.0] * n
    p = rng.random()
    pp = rng.random()
    cyl = 0
    amp = 1.0
    ce = 0.0
    g, gs = rng.random, rng.gauss
    inv = 1.0 / SR
    for i in range(n):
        m = (1.0 + drift * dr[i]) * (pm[i] if pm is not None else 1.0)
        p += fire_f * m * inv
        if p >= 1.0:
            p -= 1.0
            cyl = (cyl + 1) % cylinders
            amp = cyl_amp[cyl] * (1.0 + roughness * gs(0.0, 1.0))
            mf = mr[i] if mr is not None else misfire
            if mf > 0.0 and g() < mf:
                amp = 0.0
            ce = amp
        pp += prop_f * m * inv
        if pp >= 1.0:
            pp -= 1.0
        fire[i] = tbl[int(p * TL)] * amp
        prop[i] = ptbl[int(pp * TL)]
        ce *= 0.9985
        comb[i] = ce
    return fire, prop, comb


def radial_b17(n, rng, rpm=2300.0, pitch=None, bright=1.0, **kw):
    """Un Wright R-1820 Cyclone (9 cilindros, reducción 0,5625, hélice tripala Hamilton)."""
    fire, prop, comb = piston_engine(n, rng, rpm, 9, pitch=pitch, **kw)
    ex = lowpass(fire, 1300.0 * bright, 0.8)
    ex = add(ex, scale(bandpass(fire, 340.0, 1.2), 0.9))
    pr = lowpass(prop, 420.0 * bright, 0.9)
    nz = bandpass(pink(n, rng), 520.0 * bright, 0.45)
    nz = [v * (0.35 + 0.65 * c) for v, c in zip(nz, comb)]
    return [0.55 * a + 0.5 * b + 0.45 * c for a, b, c in zip(ex, pr, nz)]


def v12_fighter(n, rng, rpm=2700.0, pitch=None, cylinders=12, bright=1.0, rough=1.0, **kw):
    """Motor de caza: DB 605 (V12 invertido) o BMW 801 (14 cilindros en doble estrella)."""
    fire, prop, comb = piston_engine(n, rng, rpm, cylinders, pitch=pitch, pulse_tau=0.09,
                                     roughness=0.07 * rough, cyl_var=0.15 * rough,
                                     prop_ratio=0.585 if cylinders == 12 else 0.54, **kw)
    fire = soft_clip(fire, 2.2)
    ex = lowpass(fire, 2600.0 * bright, 0.9)
    ex = add(ex, scale(bandpass(fire, 1300.0 * bright, 2.0), 0.5))
    pr = lowpass(prop, 500.0 * bright, 0.9)
    pv = pitch if pitch is not None else [1.0] * n
    whine = sine([rpm / 60.0 * 10.4 * 4 * v for v in pv], n)          # rodete del compresor
    nz = bandpass(pink(n, rng), 1100.0 * bright, 0.5)
    nz = [v * (0.4 + 0.6 * c) for v, c in zip(nz, comb)]
    return [0.6 * a + 0.4 * b + 0.035 * w + 0.4 * c for a, b, w, c in zip(ex, pr, whine, nz)]


def backfire_pop(rng, gain=1.0, dur=0.16):
    """Petardeo: chasquido + golpe grave en el escape."""
    n = ns(dur)
    crack = mul(lowpass(white(n, rng), rng.uniform(2200, 3500)), env_exp(n, 0.006, 0.0003))
    body = mul(bandpass(white(n, rng), rng.uniform(250, 420), 0.9), env_exp(n, 0.03, 0.001))
    f0 = rng.uniform(60, 85)
    thump = mul(sine(exp_ramp(n, f0 * 1.6, f0), n), env_exp(n, 0.045, 0.001))
    out = [gain * (0.6 * a + 1.4 * b + 0.9 * c) for a, b, c in zip(crack, body, thump)]
    return soft_clip(out, 1.6)


def metal_tick(rng, base, dur=0.05, bright=1.0, ring=0.04):
    """Golpecito metálico: clic de ruido que excita 4 modos inarmónicos."""
    n = ns(dur)
    click = mul(highpass(white(n, rng), 1500 * bright), env_exp(n, 0.0012, 0.0001))
    ratios = (1.0, 1.59, 2.14, 2.83)
    freqs = [base * r * rng.uniform(0.96, 1.04) for r in ratios]
    rings = resonator_bank(click, freqs, [ring * rng.uniform(0.7, 1.3) for _ in ratios],
                           [1.0, 0.7, 0.5, 0.35])
    return [0.6 * a + b for a, b in zip(click, rings)]


def m2_shot(rng, var=1.0, dur=0.30, tail=True):
    """Un disparo de Browning M2 .50: estampido + golpe grave + cerrojo + chapa."""
    n = ns(dur)
    blast = mul(lowpass(white(n, rng), 7000 * var), env_exp(n, 0.010 * var, 0.0004))
    body = mul(lowpass(pink(n, rng), 1700 * var, 0.9), env_exp(n, 0.045, 0.001))
    f0 = rng.uniform(95, 125) * var
    thump = mul(sine(exp_ramp(n, f0 * 1.7, f0 * 0.45), n), env_exp(n, 0.032, 0.0008))
    out = [1.0 * a + 0.75 * b + 0.9 * c for a, b, c in zip(blast, body, thump)]
    # cerrojo atrás y adelante
    for t, fc, g in ((rng.uniform(0.016, 0.021), rng.uniform(2900, 3500), 0.35),
                     (rng.uniform(0.046, 0.054), rng.uniform(2200, 2700), 0.28)):
        m = ns(0.03)
        clack = mul(bandpass(white(m, rng), fc, 3.5), env_exp(m, 0.005, 0.0002))
        clack = add(clack, scale(metal_tick(rng, fc * 0.55, 0.03, ring=0.025), 0.25))
        mix_into(out, clack, ns(t), g * 2.0)
    # chapa de la torreta que vibra
    ring = resonator_bank(mul(white(n, rng), env_exp(n, 0.002)),
                          [x * rng.uniform(0.97, 1.03) for x in (410, 1850, 3120, 4650)],
                          [0.08, 0.05, 0.04, 0.03], [0.5, 0.25, 0.18, 0.12])
    out = [a + 0.5 * b for a, b in zip(out, ring)]
    out = soft_clip(out, 2.4)
    if tail:
        out = reverb(out, decay=0.35, damp=0.45, mix=0.22, predelay=0.012, size=0.55)
    return fade_edges(out, 0.0003, 0.03)


def explosion(rng, dur, size=1.0, crack=1.0, cutoff=1.0, tail_tau=0.5, debris=0.0):
    """Explosión genérica: frente de choque + bola de fuego + retumbo + restos."""
    n = ns(dur)
    out = zeros(n)
    if crack > 0:
        m = ns(0.05)
        c = mul(highpass(white(m, rng), 600 * cutoff), env_exp(m, 0.004, 0.0002))
        c[0:ns(0.002)] = [v + 0.9 for v in c[0:ns(0.002)]]               # onda N positiva
        c[ns(0.002):ns(0.004)] = [v - 0.7 for v in c[ns(0.002):ns(0.004)]]
        mix_into(out, lowpass(c, 9000 * cutoff), 0, crack)
    boom = mul(lowpass(pink(n, rng), 420 * cutoff, 0.8), env_exp(n, 0.14 * size, 0.002))
    roar = mul(lowpass(brown(n, rng), 160 * cutoff, 0.7), env_exp(n, tail_tau * size, 0.01))
    f0 = rng.uniform(45, 60) / math.sqrt(size)
    sub = mul(sine(exp_ramp(n, f0 * 1.5, f0 * 0.6), n), env_exp(n, 0.16 * size, 0.002))
    for i in range(n):
        out[i] += 1.3 * boom[i] + 1.4 * roar[i] + 0.8 * sub[i]
    if debris > 0:
        cr = crackle(n, rng, 40 * debris)
        cr = mul(bandpass(cr, 1800 * cutoff, 0.8), env_exp(n, 0.35 * size, 0.05))
        mix_into(out, cr, 0, 2.5 * debris)
    return soft_clip(out, 1.8)


def brass_note(n, rng, f, t_on, t_off, amp=1.0, att=0.14, rel=0.8, sag=None):
    """Voz de metal sintetizado: 2 sierras desafinadas + filtro con envolvente (soplido)
    + vibrato retardado. sag: lista de multiplicadores de tono (se apaga hacia abajo)."""
    out = zeros(n)
    i0, i1 = ns(t_on), min(n, ns(t_off + rel))
    m = i1 - i0
    if m <= 0:
        return out
    vib = sine(rng.uniform(4.6, 5.4), m, rng.random())
    vd = ramp(m, 0.0, 0.0035, 2.0)
    s = sag[i0:i1] if sag is not None else [1.0] * m
    f1 = [f * (1 + vd[i] * vib[i]) * s[i] * 2 ** (rng.uniform(3, 5) / 1200) for i in range(m)]
    f2 = [f * (1 + vd[i] * vib[i]) * s[i] * 2 ** (-rng.uniform(3, 5) / 1200) for i in range(m)]
    tone = [a + b for a, b in zip(saw(f1, m, rng.random()), saw(f2, m, rng.random()))]
    hold = t_off - t_on
    env = env_points(m, [(0, 0), (0.003, 0.12), (att, 1.0), (att + 0.25, 0.82), (hold, 0.8), (hold + rel, 0.0)])
    cut = [f * (1.6 + 4.0 * e) for e in env]
    tone = svf(tone, cut, 0.8, "lp")
    for i in range(m):
        out[i0 + i] = tone[i] * env[i] * amp
    return out


def finalize(chans, target_db, ceiling=CEILING):
    """Ajusta al RMS objetivo; si el pico pasa del techo, limita suavemente e itera."""
    target = 10 ** (target_db / 20)
    for _ in range(10):
        allv = [v for c in chans for v in c]
        g = target / max(1e-12, rms(allv))
        chans = [scale(c, g) for c in chans]
        if max(peak(c) for c in chans) <= ceiling:
            break
        chans = [soft_limit(c, ceiling) for c in chans]
        allv = [v for c in chans for v in c]
        if abs(20 * math.log10(max(1e-12, rms(allv))) - target_db) < 0.5:
            break
    pk = max(peak(c) for c in chans)
    if pk > ceiling:
        chans = [scale(c, ceiling / pk) for c in chans]
    return chans


# ─────────────────────────── generadores: grupo A ───────────────────────────
DETUNE4 = (-0.0045, -0.0012, 0.0017, 0.0049)


def gen_engine_ext(rng, n):
    engines = []
    for k, d in enumerate(DETUNE4):
        e = radial_b17(n, rng, 2300.0 * (1 + d), bright=1.0 + 0.05 * k)
        engines.append(scale(e, (0.85, 1.0, 0.95, 0.8)[k]))
    out = add(*engines)
    air = mul(lowpass(pink(n, rng), 1400, 0.6), [0.8 + 0.2 * v for v in smooth_random(n, rng, 0.3)])
    out = [a + 0.18 * b for a, b in zip(out, air)]
    out = highpass(out, 28.0)
    out = resonant(out, 175.0, 1.2, 4.0)        # gruñido del escape (frecuencia de encendido)
    out = resonant(out, 420.0, 1.0, 3.0)
    out = biquad(out, "peak", 65.0, 1.0, -4.0)   # la hélice no debe tapar el escape
    out = soft_clip(out, 1.3)
    return [reverb(out, decay=0.4, damp=0.5, mix=0.15, size=0.6)]


def gen_engine_int(rng, n):
    engines = [radial_b17(n, rng, 2300.0 * (1 + d), bright=0.8) for d in DETUNE4]
    out = add(*engines)
    out = lowpass(lowpass(out, 340.0, 0.9), 520.0, 0.7)
    out = resonant(out, 108.0, 2.5, 7.0)        # resonancia del fuselaje
    out = resonant(out, 232.0, 3.0, 4.0)
    rumble = lowpass(brown(n, rng), 90.0)
    vib = am(highpass(white(n, rng), 2400), 64.7, 0.9)         # chapas y remaches al paso de pala
    vib = lowpass(vib, 4500)
    hiss = bandpass(pink(n, rng), 1600, 0.4)
    out = [a + 0.9 * b + 0.035 * c + 0.06 * d for a, b, c, d in zip(out, rumble, vib, hiss)]
    out = highpass(out, 25.0)
    out = soft_clip(out, 1.2)
    return [reverb(out, decay=0.18, damp=0.6, mix=0.12, predelay=0.003, size=0.3)]


def gen_engine_damaged(rng, n):
    unstable = [1.0 + 0.035 * a + 0.012 * b for a, b in zip(smooth_random(n, rng, 0.7),
                                                            smooth_random(n, rng, 3.5))]
    mis = [max(0.0, 0.10 + 0.12 * v) for v in smooth_random(n, rng, 1.2)]
    bad = radial_b17(n, rng, 2150.0, pitch=unstable, misfire_ramp=mis, roughness=0.18, cyl_var=0.3)
    surge = [0.75 + 0.25 * v for v in smooth_random(n, rng, 1.6)]
    bad = mul(bad, surge)
    t = 0.15
    while t < n / SR - 0.2:
        mix_into(bad, backfire_pop(rng, rng.uniform(0.5, 1.2)), ns(t))
        t += rng.uniform(0.18, 0.9)
    others = lowpass(add(*[radial_b17(n, rng, 2300.0 * (1 + d), bright=0.8) for d in DETUNE4[:3]]), 500)
    out = [a + 0.3 * b for a, b in zip(bad, others)]
    out = highpass(out, 28.0)
    return [reverb(out, decay=0.35, damp=0.5, mix=0.15, size=0.6)]


def gen_engine_sputter(rng, n):
    rpmcurve = exp_ramp(n, 1.0, rng.uniform(0.55, 0.7))
    mis = ramp(n, 0.25, 0.85, 0.7)
    eng = radial_b17(n, rng, 2300.0, pitch=rpmcurve, misfire_ramp=mis, roughness=0.25, cyl_var=0.35)
    eng = mul(eng, env_points(n, [(0, 1.0), (n / SR * 0.6, 0.7), (n / SR, 0.0)]))
    out = zeros(n)
    mix_into(out, eng, 0, 0.8)
    t = 0.0
    k = 0
    while t < n / SR - 0.18:
        g = rng.uniform(0.6, 1.3) * (1.0 - 0.5 * t / (n / SR))
        mix_into(out, backfire_pop(rng, g, 0.2), ns(t))
        if rng.random() < 0.4:            # doble petardeo
            mix_into(out, backfire_pop(rng, g * 0.6, 0.15), ns(t + rng.uniform(0.03, 0.06)))
        t += rng.uniform(0.07, 0.28) * (1 + 0.6 * k / 8)
        k += 1
    out = highpass(out, 30.0)
    out = reverb(out, decay=0.4, damp=0.5, mix=0.2, size=0.6)
    return [fade_edges(out, 0.0003, 0.06)]


def gen_engine_fire(rng, n):
    flick = [0.6 + 0.4 * v for v in smooth_random(n, rng, 9.0)]
    roar = lowpass(brown(n, rng), 420, 0.8)
    body = mul(bandpass(pink(n, rng), 850, 0.6), flick)
    cr = crackle(n, rng, 35)
    cr = add(bandpass(cr, 2600, 1.2), scale(bandpass(cr, 900, 1.5), 0.6))
    gust = [0.7 + 0.3 * v for v in smooth_random(n, rng, 0.4)]
    wind = mul(lowpass(pink(n, rng), 1300, 0.6), gust)
    low = mul(lowpass(white(n, rng), 110), flick)
    out = [1.6 * a + 0.9 * b + 0.8 * c + 0.5 * d + 1.2 * e
           for a, b, c, d, e in zip(roar, body, cr, wind, low)]
    out = soft_clip(out, 1.4)
    return [reverb(out, decay=0.3, damp=0.5, mix=0.12, size=0.5)]


def gen_wind(rng, n):
    gust = smooth_random(n, rng, 0.18)
    chans = []
    shared = pink(n, rng)
    for ch in range(2):
        own = pink(n, rng)
        src = [0.65 * a + 0.55 * b for a, b in zip(shared, own)]
        g = [0.65 + 0.25 * a + 0.1 * b for a, b in zip(gust, smooth_random(n, rng, 0.6))]
        body = mul(add(bandpass(src, 420, 0.5), scale(lowpass(src, 1500), 0.5)), g)
        wf = [1500 + 350 * a + 120 * ch for a in smooth_random(n, rng, 0.25)]
        whistle = mul(svf(own, wf, 14.0, "bp"), [max(0.0, v) ** 2 for v in g])
        buffet = mul(lowpass(brown(n, rng), 70), g)
        chans.append([a + 0.35 * b + 0.8 * c for a, b, c in zip(body, whistle, buffet)])
    L, R = [highpass(c, 22.0) for c in chans]
    return list(reverb_stereo(L, R, decay=0.25, mix=0.08, size=0.4))


def gen_formation(rng, n):
    L, R = zeros(n), zeros(n)
    positions = (-0.85, -0.45, 0.05, 0.45, 0.85)
    for k, p in enumerate(positions):
        sub = random.Random(rng.random())
        dist = sub.uniform(0.55, 1.0)
        planes = add(*[radial_b17(n, sub, 2300.0 * (1 + sub.uniform(-0.008, 0.008)), bright=0.7,
                                  drift=0.004) for _ in range(2)])
        planes = lowpass(planes, 260.0 * (1.2 - 0.4 * dist), 0.7)
        fade = [0.55 + 0.45 * v for v in smooth_random(n, sub, sub.uniform(0.08, 0.2))]
        planes = mul(planes, fade)
        pl, pr = pan(planes, p)
        mix_into(L, pl, 0, 1.0 / dist)
        mix_into(R, pr, 0, 1.0 / dist)
    L, R = highpass(L, 35.0), highpass(R, 35.0)
    return list(reverb_stereo(L, R, decay=1.4, damp=0.6, mix=0.4, predelay=0.03, size=1.0))


# ─────────────────────────── generadores: grupo B ───────────────────────────
def gen_gun_shot(rng, n):
    var = rng.uniform(0.93, 1.07)
    out = m2_shot(rng, var, n / SR)
    return [out[:n]]


def gen_gun_burst(rng, n):
    out = zeros(n)
    t = 0.0
    for k in range(8):
        gun = k % 2
        sub = random.Random(rng.random())
        shot = m2_shot(sub, (0.97 if gun else 1.03) * sub.uniform(0.97, 1.03), 0.3, tail=False)
        mix_into(out, shot, ns(t), 1.0 if gun else 0.92)
        t += 0.112 + rng.uniform(-0.008, 0.01)
    # zumbido del mecanismo de alimentación entre disparos
    feed = mul(bandpass(white(n, rng), 1200, 2.0), env_points(n, [(0, 0.0), (0.02, 1.0), (0.9, 1.0), (1.0, 0.0)]))
    mix_into(out, feed, 0, 0.03)
    out = reverb(out, decay=0.4, damp=0.45, mix=0.22, predelay=0.012, size=0.55)
    return [fade_edges(out, 0.0003, 0.06)]


def gen_casings(rng, n):
    out = zeros(n)
    for _ in range(12):
        t = rng.uniform(0.0, 0.42) ** 1.2
        if _ == 0:
            t = 0.0
        base = rng.uniform(2600, 3600)
        amp = rng.uniform(0.5, 1.0)
        dt = rng.uniform(0.06, 0.11)
        for b in range(rng.randint(2, 4)):              # rebotes cada vez más cortos y flojos
            if t >= n / SR - 0.06:
                break
            mix_into(out, metal_tick(rng, base, 0.09, ring=rng.uniform(0.05, 0.09)), ns(t), amp)
            t += dt
            dt *= rng.uniform(0.45, 0.65)
            amp *= rng.uniform(0.35, 0.55)
    floor = mul(lowpass(white(n, rng), 300), env_exp(n, 0.08))
    out = [a + 0.15 * b for a, b in zip(out, floor)]
    out = highpass(out, 300.0)
    out = reverb(out, decay=0.25, damp=0.3, mix=0.18, predelay=0.004, size=0.35)
    return [fade_edges(out, 0.0003, 0.05)]


# ─────────────────────────── generadores: grupo C ───────────────────────────
def gen_hit_hull(rng, n):
    out = zeros(n)
    crack = mul(highpass(white(n, rng), 1800), env_exp(n, 0.0025, 0.0001))
    tear = mul(bandpass(white(n, rng), rng.uniform(3000, 4800), 1.4),
               env_exp(n, rng.uniform(0.012, 0.022), 0.0005, rng.uniform(0.002, 0.006)))
    f0 = rng.uniform(150, 210)
    thunk = mul(sine(exp_ramp(n, f0 * 1.4, f0), n), env_exp(n, 0.02, 0.0005))
    excite = mul(white(n, rng), env_exp(n, 0.0015))
    base = rng.uniform(380, 560)
    panel = resonator_bank(excite, [base * r for r in (1.0, 1.43, 2.07, 2.61, 3.37, 4.9, 7.3)],
                           [0.22, 0.16, 0.13, 0.1, 0.08, 0.06, 0.04],
                           [0.6, 0.5, 0.45, 0.35, 0.3, 0.22, 0.15])
    for i in range(n):
        out[i] = 1.2 * crack[i] + 0.8 * tear[i] + 0.7 * thunk[i] + 0.9 * panel[i]
    out = soft_clip(out, 1.8)
    out = reverb(out, decay=0.2, damp=0.5, mix=0.15, predelay=0.003, size=0.3)
    return [fade_edges(out, 0.0003, 0.04)]


def gen_shrapnel(rng, n):
    out = zeros(n)
    cnt = 55
    for k in range(cnt):
        t = (rng.random() ** 1.8) * (n / SR - 0.12)
        if k == 0:
            t = 0.0
        a = rng.uniform(0.2, 1.0) * (1.0 - 0.6 * t / (n / SR))
        if rng.random() < 0.15:
            a *= 1.8
        tick = metal_tick(rng, rng.uniform(700, 1900), 0.08, bright=1.3, ring=rng.uniform(0.03, 0.08))
        mix_into(out, tick, ns(t), a)
    bed = mul(bandpass(white(n, rng), 2500, 0.7), env_exp(n, 0.25, 0.002))
    out = [a + 0.25 * b for a, b in zip(out, bed)]
    out = resonant(out, 520, 2.0, 4.0)                    # la chapa común del fuselaje
    out = soft_clip(out, 1.5)
    out = reverb(out, decay=0.25, damp=0.45, mix=0.15, predelay=0.003, size=0.35)
    return [fade_edges(out, 0.0003, 0.05)]


def gen_alarm_bell(rng, n):
    exc = zeros(n)
    for ring in range(3):
        t0 = ring * 0.5
        t = t0
        while t < t0 + 0.36:                    # el martillo eléctrico golpea a ~22 Hz
            i = ns(t)
            if i < n:
                exc[i] += rng.uniform(0.8, 1.0)
                if i + 1 < n:
                    exc[i + 1] -= 0.5
            t += 1.0 / 22.0 * rng.uniform(0.97, 1.03)
    exc = lowpass(exc, 6000)
    f0 = 1180.0
    ratios = (1.0, 2.31, 2.97, 4.21, 5.43, 6.65)
    bell = resonator_bank(exc, [f0 * r for r in ratios], [0.9, 0.6, 0.45, 0.35, 0.25, 0.18],
                          [1.0, 0.55, 0.4, 0.3, 0.2, 0.12])
    buzz = mul(highpass(exc, 2000), [1.0] * n)                       # contacto del martillo
    out = [a + 0.3 * b for a, b in zip(bell, buzz)]
    out = reverb(out, decay=0.3, damp=0.4, mix=0.15, predelay=0.004, size=0.35)
    return [fade_edges(out, 0.0003, 0.12)]


# ─────────────────────────── generadores: grupo D ───────────────────────────
def gen_flyby(rng, n, variant):
    dur = n / SR
    if variant == 1:           # Bf 109 G, DB 605 (V12)
        v, d, tc, cyl, rpm = 125.0, 28.0, dur * 0.48, 12, 2700.0
    else:                      # Fw 190 A, BMW 801 (14 cilindros en doble estrella)
        v, d, tc, cyl, rpm = 150.0, 20.0, dur * 0.45, 14, 2400.0
    ratio, dist, lat = flyby_path(n, v, d, tc)
    src = v12_fighter(n, rng, rpm, pitch=ratio, cylinders=cyl, bright=1.0 if cyl == 12 else 0.85,
                      rough=1.0 if cyl == 12 else 1.3)
    # ruido aerodinámico (estela de aire) con centro desplazado por doppler
    whoosh = svf(pink(n, rng), [900.0 * r for r in ratio], 0.9, "bp")
    gain = [min(1.0, d / r) for r in dist]
    cut = [max(700.0, min(14000.0, 14000.0 * (d / r) ** 0.8)) for r in dist]
    # tras el paso, el escape y la estela de la hélice apuntan al oyente: más graves
    after = [0.5 + 0.5 * math.tanh((i / SR - tc) * 4.0) for i in range(n)]
    mono = [(s * (1.0 + 0.35 * a) + 0.6 * w * gg) * gg for s, w, gg, a in zip(src, whoosh, gain, after)]
    mono = svf(mono, cut, 0.7, "lp")
    mono = highpass(mono, 30.0)
    L, R = pan(mono, [0.92 * x for x in lat])
    L, R = reverb_stereo(L, R, decay=0.5, mix=0.12, predelay=0.02, size=0.7)
    return [fade_edges(L, 0.001, 0.15), fade_edges(R, 0.001, 0.15)]


def gen_fighter_engine(rng, n):
    pitch = [1.0 + 0.012 * a + 0.004 * b for a, b in zip(smooth_random(n, rng, 0.6),
                                                         smooth_random(n, rng, 3.0))]
    out = v12_fighter(n, rng, 2700.0, pitch=pitch, cylinders=12)
    out = mul(out, [0.8 + 0.2 * v for v in smooth_random(n, rng, 1.3)])
    out = highpass(out, 35.0)
    out = soft_clip(out, 1.3)
    return [reverb(out, decay=0.3, damp=0.5, mix=0.1, size=0.5)]


def gen_fighter_guns(rng, n):
    out = zeros(n)
    end = 0.92
    # MG 151/20 (≈ 700 disparos/min por arma, dos armas) y MG 131 (≈ 900/min, dos armas)
    for rate, f_lp, g, f0 in ((11.7, 900.0, 1.0, 70.0), (11.7, 900.0, 0.9, 74.0),
                              (15.0, 1500.0, 0.45, 110.0), (15.0, 1500.0, 0.45, 115.0)):
        t = rng.uniform(0.0, 0.03)
        while t < end:
            m = ns(0.12)
            s = mul(lowpass(white(m, rng), f_lp * rng.uniform(0.85, 1.15)), env_exp(m, 0.012, 0.0015))
            s = add(s, scale(mul(sine(f0 * rng.uniform(0.9, 1.1), m), env_exp(m, 0.03, 0.002)), 0.45))
            mix_into(out, s, ns(t), g * rng.uniform(0.8, 1.1))
            t += 1.0 / rate * rng.uniform(0.92, 1.08)
    out = lowpass(out, 2400, 0.7)
    out = reverb(out, decay=0.6, damp=0.6, mix=0.35, predelay=0.03, size=0.8)
    return [fade_edges(out, 0.0005, 0.12)]


def gen_fighter_explosion(rng, n):
    out = explosion(rng, n / SR, size=1.2, crack=1.0, cutoff=1.0, tail_tau=0.6, debris=1.0)
    fuel = mul(bandpass(pink(n, rng), 600, 0.6), env_points(n, [(0, 0), (0.08, 1.0), (0.7, 0.5), (2.2, 0.0)]))
    out = [a + 0.5 * b for a, b in zip(out, fuel)]
    out = reverb(out, decay=0.9, damp=0.55, mix=0.25, predelay=0.02, size=0.8)
    return [fade_edges(out, 0.0003, 0.3)]


def gen_falling_whine(rng, n):
    ratio, dist = recede_path(n, 190.0, 45.0, 30.0)
    overspeed = ramp(n, 1.0, 1.1, 0.6)
    pitch = [a * b for a, b in zip(ratio, overspeed)]
    src = v12_fighter(n, rng, 3100.0, pitch=pitch, cylinders=12)
    tip = [0.5 * a + 0.25 * b for a, b in zip(sine([1450.0 * p for p in pitch], n),
                                              sine([2900.0 * p for p in pitch], n))]
    howl = svf(pink(n, rng), [1100.0 * p for p in pitch], 6.0, "bp")
    gain = [min(1.0, 45.0 / r) for r in dist]
    cut = [max(500.0, 12000.0 * (45.0 / r) ** 1.1) for r in dist]
    mono = [(s + 0.5 * t + 0.6 * h) * g for s, t, h, g in zip(src, tip, howl, gain)]
    mono = svf(mono, cut, 0.7, "lp")
    mono = highpass(mono, 35.0)
    mono = reverb(mono, decay=0.8, damp=0.5, mix=0.3, predelay=0.03, size=0.8)
    return [fade_edges(mono, 0.001, 0.4)]


# ─────────────────────────── generadores: grupo E ───────────────────────────
def gen_flak_near(rng, n):
    size = rng.uniform(0.9, 1.15)
    out = explosion(rng, n / SR, size=size, crack=1.4, cutoff=1.2, tail_tau=0.45, debris=0.3)
    # metralla que alcanza el fuselaje justo después del estampido
    for _ in range(rng.randint(10, 22)):
        t = rng.uniform(0.03, 0.5)
        tick = metal_tick(rng, rng.uniform(800, 2000), 0.08, bright=1.2, ring=0.05)
        mix_into(out, tick, ns(t), rng.uniform(0.1, 0.45))
    out = reverb(out, decay=1.1, damp=0.55, mix=0.28, predelay=0.015, size=0.9)
    return [fade_edges(out, 0.0003, 0.25)]


def gen_flak_far(rng, n):
    out = explosion(rng, n / SR, size=rng.uniform(1.1, 1.4), crack=0.0, cutoff=0.45, tail_tau=0.45)
    out = mul(out, env_points(n, [(0, 0.3), (0.006, 1.0), (n / SR, 1.0)]))
    out = lowpass(out, 320.0, 0.7)
    out = reverb(out, decay=1.6, damp=0.65, mix=0.45, predelay=0.04, size=1.0)
    return [fade_edges(out, 0.0005, 0.3)]


# ─────────────────────────── generadores: grupo F ───────────────────────────
def gen_bomb_doors(rng, n):
    dur = n / SR
    spin = env_points(n, [(0, 0.0), (0.25, 1.0), (dur - 0.45, 1.0), (dur - 0.2, 0.0), (dur, 0.0)])
    speed = [0.55 + 0.45 * s for s in spin]
    motor = add(scale(saw([115.0 * s for s in speed], n), 0.5),
                scale(sine([920.0 * s for s in speed], n), 0.12))        # engranajes
    motor = lowpass(motor, 1600, 0.8)
    motor = mul(motor, spin)
    motor = am(motor, 7.0, 0.25)
    out = zeros(n)
    mix_into(out, motor, 0, 1.0)
    # bisagras que chirrían
    for t in (0.5, 1.15, 1.7):
        m = ns(0.35)
        sq = fm(rng.uniform(700, 950), rng.uniform(25, 40), 3.0, m)
        sq = mul(bandpass(sq, 1100, 1.5), env_points(m, [(0, 0), (0.08, 1), (0.25, 0.6), (0.35, 0)]))
        mix_into(out, sq, ns(t), 0.25 * rng.uniform(0.7, 1.0))
    # cerrojo al empezar y tope al terminar
    for t, f0, g in ((0.0, 160.0, 1.3), (dur - 0.22, 110.0, 1.6)):
        m = ns(0.2)
        k = mul(sine(exp_ramp(m, f0 * 1.5, f0), m), env_exp(m, 0.035, 0.0005))
        k = add(k, scale(metal_tick(rng, 620, 0.2, ring=0.12), 0.7))
        mix_into(out, k, ns(t), g)
    # el viento entra por la bodega a medida que se abren
    wopen = env_points(n, [(0, 0.05), (0.3, 0.1), (dur - 0.3, 1.0), (dur, 1.0)])
    wind = svf(pink(n, rng), [400 + 1400 * w for w in wopen], 0.6, "lp")
    wind = mul(wind, [w * (0.85 + 0.15 * g) for w, g in zip(wopen, smooth_random(n, rng, 2.0))])
    out = [a + 1.4 * b for a, b in zip(out, wind)]
    out = highpass(out, 30.0)
    out = reverb(out, decay=0.3, damp=0.5, mix=0.15, predelay=0.004, size=0.4)
    return [fade_edges(out, 0.0003, 0.08)]


def gen_bomb_release(rng, n):
    out = zeros(n)
    clack = mul(bandpass(white(n, rng), 2200, 2.0), env_exp(n, 0.006, 0.0002))
    thunk = mul(sine(exp_ramp(n, 150, 85), n), env_exp(n, 0.04, 0.0005))
    body = mul(lowpass(pink(n, rng), 700), env_exp(n, 0.03, 0.0005))
    spring = mul(sine(exp_ramp(n, 430, 395), n), env_exp(n, 0.09, 0.002, 0.004))
    shackle = metal_tick(rng, 1350, 0.25, ring=0.14)
    for i in range(n):
        out[i] = 1.2 * clack[i] + 1.1 * thunk[i] + 0.7 * body[i] + 0.22 * spring[i]
    mix_into(out, shackle, 0, 0.5)
    mix_into(out, metal_tick(rng, 900, 0.15, ring=0.06), ns(0.07), 0.25)     # el gancho rebota
    out = soft_clip(out, 1.7)
    out = reverb(out, decay=0.25, damp=0.45, mix=0.18, predelay=0.004, size=0.4)
    return [fade_edges(out, 0.0003, 0.06)]


def gen_bomb_impact(rng, n):
    out = zeros(n)
    # golpe inicial lejano y luego el retumbo que rueda (ecos del terreno)
    for t, g, sz in ((0.0, 1.0, 1.6), (0.18, 0.55, 1.4), (0.42, 0.45, 1.5), (0.85, 0.3, 1.8)):
        e = explosion(random.Random(rng.random()), 3.0 - t, size=sz, crack=0.0, cutoff=0.35, tail_tau=0.7)
        if t == 0.0:
            e = mul(e, env_points(len(e), [(0, 0.35), (0.008, 0.6), (0.06, 1.0), (3.0, 1.0)]))
        mix_into(out, e, ns(t), g)
    roll = mul(lowpass(brown(n, rng), 70), [0.6 + 0.4 * v for v in smooth_random(n, rng, 3.0)])
    roll = mul(roll, env_points(n, [(0, 0.2), (0.25, 1.0), (1.6, 0.6), (3.0, 0.0)]))
    out = [a + 1.5 * b for a, b in zip(out, roll)]
    out = lowpass(out, 220.0, 0.7)
    out = highpass(out, 22.0)
    out = reverb(out, decay=1.8, damp=0.7, mix=0.4, predelay=0.05, size=1.0)
    return [fade_edges(out, 0.0005, 0.4)]


def gen_bomb_secondary(rng, n):
    out = zeros(n)
    t = 0.0
    k = 0
    while t < n / SR - 0.7:
        sz = rng.uniform(0.7, 1.5)
        e = explosion(random.Random(rng.random()), min(2.2, n / SR - t), size=sz, crack=0.25,
                      cutoff=rng.uniform(0.45, 0.8), tail_tau=0.5, debris=0.6)
        mix_into(out, e, ns(t), rng.uniform(0.5, 1.0) * (1.0 if k else 0.8))
        t += rng.choice((rng.uniform(0.08, 0.2), rng.uniform(0.35, 0.8)))
        k += 1
    # traqueteo de munición y vagones que arden
    cr = mul(bandpass(crackle(n, rng, 30), 1100, 0.8), env_points(n, [(0, 0.2), (0.5, 1.0), (4.0, 0.3)]))
    out = [a + 0.5 * b for a, b in zip(out, cr)]
    out = lowpass(out, 1400.0, 0.7)
    out = reverb(out, decay=1.6, damp=0.65, mix=0.35, predelay=0.04, size=1.0)
    return [fade_edges(out, 0.0005, 0.4)]


# ─────────────────────────── generadores: grupo G ───────────────────────────
def _blip(n, f0, f1, tau, harm=0.2, att=0.002):
    fr = exp_ramp(n, f0, f1)
    s = sine(fr, n)
    h = sine([2 * f for f in fr], n)
    return mul([a + harm * b for a, b in zip(s, h)], env_exp(n, tau, att))


def _click(rng, n, fc=3500.0, tau=0.0015):
    return mul(bandpass(white(n, rng), fc, 1.2), env_exp(n, tau, 0.0002))


def gen_ui_navigate(rng, n):
    out = add(scale(_blip(n, 1900, 1750, 0.009, 0.1, 0.0008), 0.6), scale(_click(rng, n, 4200), 0.5))
    return [fade_edges(lowpass(out, 9000), 0.0002, 0.01)]


def gen_ui_accept(rng, n):
    out = zeros(n)
    mix_into(out, _click(rng, n, 3800), 0, 0.5)
    mix_into(out, _blip(ns(0.07), 660, 700, 0.04, 0.15), 0, 0.6)
    mix_into(out, _blip(ns(0.1), 990, 1050, 0.045, 0.15), ns(0.045), 0.7)
    out = reverb(out, decay=0.2, damp=0.4, mix=0.08, size=0.3)
    return [fade_edges(out, 0.0002, 0.02)]


def gen_ui_back(rng, n):
    out = zeros(n)
    mix_into(out, _blip(ns(0.07), 880, 840, 0.04, 0.15), 0, 0.7)
    mix_into(out, _blip(ns(0.1), 600, 520, 0.05, 0.15), ns(0.045), 0.7)
    out = reverb(out, decay=0.2, damp=0.4, mix=0.08, size=0.3)
    return [fade_edges(out, 0.0002, 0.02)]


def gen_ui_pause(rng, n):
    thump = mul(sine(exp_ramp(n, 170, 85), n), env_exp(n, 0.06, 0.001))
    soft = mul(lowpass(pink(n, rng), 500), env_exp(n, 0.03, 0.001))
    tone = mul(sine(330, n), env_exp(n, 0.09, 0.004))
    out = [a + 0.5 * b + 0.18 * c for a, b, c in zip(thump, soft, tone)]
    out = reverb(out, decay=0.3, damp=0.6, mix=0.1, size=0.3)
    return [fade_edges(out, 0.0003, 0.05)]


def gen_ui_profile(rng, n):
    out = zeros(n)
    for t, f in ((0.0, 1500.0), (0.055, 1800.0)):
        m = ns(0.05)
        mix_into(out, add(scale(_blip(m, f, f * 0.97, 0.007, 0.1, 0.0005), 0.6),
                          scale(_click(rng, m, 4000), 0.4)), ns(t))
    return [fade_edges(out, 0.0002, 0.01)]


def gen_station_switch(rng, n):
    out = zeros(n)
    sw = add(_click(rng, n, 2600, 0.002), scale(mul(sine(exp_ramp(n, 300, 180), n), env_exp(n, 0.01, 0.0003)), 0.6))
    mix_into(out, sw, 0, 1.0)
    mix_into(out, _click(rng, ns(0.03), 3200, 0.0012), ns(0.012), 0.5)
    hiss = mul(bandpass(white(n, rng), 1800, 0.9), env_points(n, [(0, 0), (0.025, 0), (0.05, 1.0), (0.12, 0.6), (0.23, 0)]))
    out = [a + 0.35 * b for a, b in zip(out, hiss)]
    out = lowpass(highpass(out, 250), 4500)
    return [fade_edges(out, 0.0002, 0.02)]


def gen_cue_tick(rng, n):
    out = add(scale(_blip(n, 1250, 1250, 0.012, 0.3, 0.001), 0.7), scale(_click(rng, n, 3000), 0.15))
    return [fade_edges(lowpass(out, 8000), 0.0002, 0.015)]


def gen_cue_now(rng, n):
    out = zeros(n)
    for t, f in ((0.0, 880.0), (0.19, 1174.66)):
        m = ns(0.17)
        tone = add(sine(f, m), scale(sine(2 * f, m), 0.18), scale(sine(3 * f, m), 0.06))
        mix_into(out, mul(tone, env_adsr(m, 0.006, 0.04, 0.75, 0.06)), ns(t))
    out = reverb(out, decay=0.25, damp=0.4, mix=0.1, size=0.3)
    return [fade_edges(out, 0.0002, 0.02)]


def gen_cue_course(rng, n):
    m = ns(0.26)
    tone = lowpass(square(660.0, m), 2400, 0.7)
    tone = add(scale(tone, 0.5), sine(660.0, m))
    tone = am(tone, 16.0, 0.35)
    out = zeros(n)
    mix_into(out, mul(tone, env_adsr(m, 0.01, 0.05, 0.7, 0.08)), 0)
    out = reverb(out, decay=0.25, damp=0.4, mix=0.1, size=0.3)
    return [fade_edges(out, 0.0002, 0.02)]


def _radio_band(x):
    return lowpass(highpass(x, 350, 0.8), 2800, 0.8)


def gen_squelch_open(rng, n):
    out = zeros(n)
    click = mul(white(n, rng), env_exp(n, 0.0015, 0.0001))
    stat = mul(add(white(n, rng), scale(crackle(n, rng, 120), 1.5)),
               env_points(n, [(0, 0), (0.004, 1.0), (0.05, 0.8), (0.18, 0.35), (0.25, 0.25)]))
    for i in range(n):
        out[i] = 1.2 * click[i] + 0.6 * stat[i]
    out = soft_clip(_radio_band(out), 1.5)
    return [fade_edges(out, 0.0002, 0.03)]


def gen_squelch_close(rng, n):
    out = zeros(n)
    stat = mul(white(n, rng), env_points(n, [(0, 0.4), (0.005, 1.0), (0.07, 0.7), (0.11, 0.0)]))
    chsk = mul(bandpass(white(n, rng), 3800, 1.2), env_exp(n, 0.025, 0.002, 0.03))
    click = mul(white(n, rng), env_exp(n, 0.0012, 0.0001, 0.105))
    for i in range(n):
        out[i] = 0.6 * stat[i] + 0.9 * chsk[i] + 0.8 * click[i]
    out = lowpass(highpass(out, 400), 5000)
    return [fade_edges(out, 0.0002, 0.03)]


def gen_radio_static(rng, n):
    qsb = [0.6 + 0.4 * v for v in smooth_random(n, rng, 0.7)]
    hiss = mul(white(n, rng), qsb)
    cr = crackle(n, rng, 14, 0.5, 3.0)
    het = sine([1050.0 + 60.0 * v for v in smooth_random(n, rng, 0.3)], n)
    hum = am([1.0] * n, 120.0, 0.25)
    out = [(0.5 * a + 0.04 * c) * h + b for a, b, c, h in zip(hiss, cr, het, hum)]
    out = soft_clip(_radio_band(out), 1.4)
    return [out]


# ─────────────────────────── generadores: grupo H ───────────────────────────
def _stinger(rng, n, notes, decay=2.4, sag=None):
    L, R = zeros(n), zeros(n)
    for k, (f, t_on, t_off, amp, p) in enumerate(notes):
        sub = random.Random(rng.random())
        v = brass_note(n, sub, f, t_on, t_off, amp, att=sub.uniform(0.12, 0.2), rel=0.9, sag=sag)
        vl, vr = pan(v, p)
        mix_into(L, vl)
        mix_into(R, vr)
    L, R = reverb_stereo(L, R, decay=decay, damp=0.45, mix=0.45, predelay=0.025, size=1.1)
    return [fade_edges(L, 0.002, 0.5), fade_edges(R, 0.002, 0.5)]


def _hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def gen_stinger_complete(rng, n):
    # IV → I (cadencia plagal, «amén»): Si♭/Fa → Fa mayor, voces de metales en registro medio
    a, b = 1.25, 3.05
    notes = [
        (_hz(41), 0.0, b, 0.9, 0.0),                       # Fa2 pedal
        (_hz(50), 0.0, a, 0.55, -0.4), (_hz(48), a, b, 0.55, -0.4),   # Re3 → Do3
        (_hz(53), 0.0, b, 0.5, 0.3),                       # Fa3
        (_hz(58), 0.0, a, 0.45, -0.2), (_hz(57), a, b, 0.45, -0.2),   # Si♭3 → La3
        (_hz(62), 0.0, a, 0.35, 0.45), (_hz(60), a, b, 0.35, 0.45),   # Re4 → Do4
        (_hz(65), a + 0.15, b, 0.22, 0.15),                # Fa4: trompeta que entra al resolver
    ]
    return _stinger(rng, n, notes, decay=2.4)


def gen_stinger_failed(rng, n):
    sag = env_points(n, [(0, 1.0), (1.8, 1.0), (4.0, 2 ** (-35 / 1200))])
    notes = [
        (_hz(38), 0.0, 2.6, 0.9, 0.0),                     # Re2
        (_hz(45), 0.0, 2.6, 0.55, -0.35),                  # La2
        (_hz(50), 0.0, 2.4, 0.45, 0.35),                   # Re3
        (_hz(53), 0.0, 2.2, 0.4, -0.15),                   # Fa3
        (_hz(57), 0.0, 1.1, 0.3, 0.3), (_hz(55), 1.1, 1.9, 0.27, 0.3),   # La3 → Sol3 → Fa3: suspiro
        (_hz(53), 1.9, 2.4, 0.22, 0.3),
    ]
    out = _stinger(rng, n, notes, decay=2.8, sag=sag)
    close = env_points(n, [(0, 1.0), (1.5, 1.0), (4.0, 0.0)])
    return [mul(lowpass(c, 1800, 0.7), close) for c in out]


# ──────────────────────────────── catálogo ──────────────────────────────────
# nombre: (grupo, duración_s, estéreo, bucle, nivel_objetivo_dB, generador, técnica)
SPEC = {}


def _reg(group, name, dur, gen, level, tech, stereo=False, loop=False):
    SPEC[name] = dict(group=group, dur=dur, stereo=stereo, loop=loop, level=level, gen=gen, tech=tech)


_reg("A", "engine_b17_ext_loop.wav", 8.0, gen_engine_ext, -20.0,
     "4 motores radiales de 9 cilindros (tren de pulsos de escape a 172,5 Hz con amplitud por cilindro, "
     "deriva lenta de rpm), hélice tripala (64,7 Hz), ruido rosa modulado por la combustión; 4 motores "
     "desafinados ±0,5 % para el batido; tanh, reverberación corta", loop=True)
_reg("A", "engine_b17_int_loop.wav", 8.0, gen_engine_int, -20.0,
     "Mismos 4 motores con paso bajo a 340 Hz, resonancias del fuselaje (108 y 232 Hz), retumbo marrón y "
     "vibración de chapas modulada en AM al paso de pala; sala muy pequeña", loop=True)
_reg("A", "engine_b17_damaged_loop.wav", 6.0, gen_engine_damaged, -20.0,
     "Motor con fallos de encendido aleatorios (probabilidad variable), rpm inestable ±4 %, oleadas de AM, "
     "petardeos (chasquido + golpe grave) y los otros 3 motores de fondo", loop=True)
_reg("A", "engine_sputter_01.wav", 1.25, gen_engine_sputter, -20.0,
     "Motor que pierde rpm (rampa exponencial), fallos crecientes y serie de petardeos dobles irregulares")
_reg("A", "engine_sputter_02.wav", 1.4, gen_engine_sputter, -20.0,
     "Igual que la 01 con otra semilla y otra caída de rpm")
_reg("A", "engine_fire_loop.wav", 5.0, gen_engine_fire, -20.0,
     "Rugido de llamas: ruido marrón y rosa filtrado con parpadeo (control aleatorio a 9 Hz), chasquidos "
     "filtrados y viento con rachas; tanh", loop=True)
_reg("A", "wind_altitude_loop.wav", 10.0, gen_wind, -20.0,
     "Ruido rosa compartido + propio por canal, paso banda ancho con rachas lentas, silbido resonante "
     "estrecho (SVF Q=14) que deriva en frecuencia y golpeteo grave", stereo=True, loop=True)
_reg("A", "formation_drone_loop.wav", 10.0, gen_formation, -20.0,
     "5 aviones × 2 motores radiales, paso bajo por distancia, desvanecimientos lentos independientes, "
     "panorámica repartida y reverberación ancha estéreo", stereo=True, loop=True)
for _i in (1, 2, 3):
    _reg("B", f"gun_m2_shot_0{_i}.wav", 0.30, gen_gun_shot, -14.0,
         "Estampido (ruido paso bajo, caída 10 ms) + cuerpo rosa + golpe grave en barrido + chasquidos del "
         "cerrojo (paso banda) + modos de chapa (banco de resonadores); tanh; reverberación corta de exterior")
_reg("B", "gun_m2_burst.wav", 1.0, gen_gun_burst, -14.0,
     "8 disparos alternando las dos armas cada ~0,112 s, cada uno con semilla y timbre propios, "
     "y reverberación común")
_reg("B", "gun_casings_01.wav", 0.8, gen_casings, -17.0,
     "12 casquillos: clic que excita 4 modos inarmónicos (2,6–3,6 kHz) con 2–4 rebotes cada vez más "
     "cortos y flojos; golpe sordo del suelo")
for _i in (1, 2, 3):
    _reg("C", f"hit_hull_0{_i}.wav", 0.3, gen_hit_hull, -14.0,
         "Chasquido de alta frecuencia + desgarro en paso banda + golpe grave + panel de aluminio "
         "(7 modos inarmónicos, 0,04–0,22 s); variantes por semilla")
_reg("C", "shrapnel_rattle_01.wav", 0.8, gen_shrapnel, -14.0,
     "55 golpecitos metálicos con densidad decreciente, algunos más fuertes, sobre un lecho de ruido y "
     "una resonancia común de chapa a 520 Hz")
_reg("C", "damage_alarm_bell.wav", 1.5, gen_alarm_bell, -16.0,
     "Campana eléctrica: martillo a 22 golpes/s excitando 6 modos de campana (1180 Hz × 1; 2,31; 2,97…), "
     "3 toques de 0,36 s")
_reg("D", "fighter_flyby_01.wav", 3.5, lambda r, n: gen_flyby(r, n, 1), -20.0,
     "Bf 109 (V12, 12 cilindros, 2700 rpm) + estela aerodinámica; trayectoria recta a 125 m/s y 28 m con "
     "doppler exacto (tiempo de emisión), ganancia 1/r, absorción del aire (paso bajo con la distancia) y "
     "panorámica izquierda→derecha", stereo=True)
_reg("D", "fighter_flyby_02.wav", 3.5, lambda r, n: gen_flyby(r, n, 2), -20.0,
     "Fw 190 (BMW 801, 14 cilindros, 2400 rpm, más áspero) a 150 m/s y 20 m; misma técnica", stereo=True)
_reg("D", "fighter_engine_loop.wav", 4.0, gen_fighter_engine, -20.0,
     "V12 a 2700 rpm: pulsos de escape más cortos y saturados (tanh), hélice, silbido del compresor y "
     "ruido de combustión", loop=True)
_reg("D", "fighter_guns_distant.wav", 1.2, gen_fighter_guns, -17.0,
     "2 cañones MG 151/20 (11,7 disparos/s) + 2 MG 131 (15/s): estallidos de ruido paso bajo + golpe "
     "grave, filtro de distancia y reverberación difusa")
_reg("D", "fighter_explosion.wav", 2.5, gen_fighter_explosion, -14.0,
     "Onda N + bola de fuego (rosa paso bajo) + retumbo marrón + subgrave en barrido + restos (chasquidos) "
     "+ soplido de combustible; tanh; reverberación")
_reg("D", "fighter_falling_whine.wav", 4.0, gen_falling_whine, -20.0,
     "V12 a sobrerrégimen + tono de punta de pala + aullido de viento resonante; fuente que se aleja a "
     "190 m/s con doppler exacto, ganancia 1/r y paso bajo por distancia")
for _i in (1, 2, 3):
    _reg("E", f"flak_near_0{_i}.wav", 1.5, gen_flak_near, -14.0,
         "Explosión con onda N fuerte, bola de fuego y subgrave + 10–22 impactos de metralla en el "
         "fuselaje + cola reverberante de 1,1 s; tamaño variable por semilla")
for _i in (1, 2):
    _reg("E", f"flak_far_0{_i}.wav", 1.5, gen_flak_far, -16.0,
         "Explosión sin onda de choque, paso bajo a 320 Hz (absorción), ataque de 6 ms y reverberación "
         "difusa larga")
_reg("F", "bomb_bay_doors_open.wav", 2.5, gen_bomb_doors, -20.0,
     "Motor eléctrico (sierra 115 Hz + engranajes 920 Hz) que arranca y se para, chirridos de bisagra en "
     "FM, golpes de cerrojo y tope, y viento cada vez más fuerte y brillante (SVF)")
_reg("F", "bomb_release.wav", 0.5, gen_bomb_release, -14.0,
     "Chasquido del soporte (paso banda), golpe grave, muelle (seno con caída de tono) y modos metálicos "
     "del gancho")
_reg("F", "bomb_impact_distant.wav", 3.0, gen_bomb_impact, -16.0,
     "4 explosiones paso bajo (ecos del terreno a 0,18/0,42/0,85 s) + retumbo marrón rodante, todo "
     "por debajo de 220 Hz y reverberación larga")
_reg("F", "bomb_secondary_explosions.wav", 4.0, gen_bomb_secondary, -14.0,
     "Cadena aleatoria de explosiones de distinto tamaño y espaciado, chasquidos de munición, filtro "
     "de distancia (1,4 kHz) y reverberación larga")
_reg("G", "ui_navigate.wav", 0.06, gen_ui_navigate, -22.0, "Blip senoidal de 1,9 kHz (9 ms) + clic de ruido")
_reg("G", "ui_accept.wav", 0.15, gen_ui_accept, -22.0, "Clic + dos blips ascendentes (660 → 990 Hz)")
_reg("G", "ui_back.wav", 0.15, gen_ui_back, -22.0, "Dos blips descendentes (880 → 560 Hz)")
_reg("G", "ui_pause.wav", 0.3, gen_ui_pause, -22.0, "Golpe senoidal 170→85 Hz + soplo grave + tono 330 Hz apagado")
_reg("G", "ui_profile_change.wav", 0.12, gen_ui_profile, -22.0, "Dos tics (1,5 y 1,8 kHz) separados 55 ms")
_reg("G", "station_switch.wav", 0.25, gen_station_switch, -22.0,
     "Clic doble del conmutador del interfono + soplido de ruido en la banda de la radio")
_reg("G", "cue_release_tick.wav", 0.08, gen_cue_tick, -22.0, "Tic senoidal de 1250 Hz con armónicos, 12 ms")
_reg("G", "cue_release_now.wav", 0.4, gen_cue_now, -22.0,
     "Dos tonos (La5 880 Hz y Re6 1175 Hz) con 2.º y 3.er armónico suaves, ADSR con ataque de 6 ms")
_reg("G", "cue_course_correction.wav", 0.3, gen_cue_course, -22.0,
     "Tono de 660 Hz (seno + cuadrada filtrada) con AM a 16 Hz")
_reg("G", "radio_squelch_open.wav", 0.25, gen_squelch_open, -22.0,
     "Clic + ráfaga de estática (blanco + chasquidos) en banda de 350–2800 Hz, tanh")
_reg("G", "radio_squelch_close.wav", 0.2, gen_squelch_close, -22.0,
     "Estática que corta + «chsk» en paso banda de 3,8 kHz + clic final")
_reg("G", "radio_static_loop.wav", 4.0, gen_radio_static, -22.0,
     "Ruido con desvanecimiento lento (QSB), chasquidos, heterodino débil que deriva, zumbido de red "
     "a 120 Hz en AM, banda de 350–2800 Hz y tanh", loop=True)
_reg("H", "stinger_mission_complete.wav", 4.0, gen_stinger_complete, -20.0,
     "Metales sintetizados (2 sierras polyBLEP por voz, filtro SVF con envolvente, vibrato retardado): "
     "Si♭/Fa → Fa mayor (cadencia plagal), panorámica por voz y reverberación de sala", stereo=True)
_reg("H", "stinger_mission_failed.wav", 4.0, gen_stinger_failed, -20.0,
     "Re menor grave con la voz superior que baja (La → Sol → Fa), el tono cae 35 cents y el filtro "
     "se cierra mientras se apaga", stereo=True)

assert len(SPEC) == 47, len(SPEC)

LOOP_FADE = 0.15
LOOP_PREROLL = 0.4


# ──────────────────────────────── escritura ─────────────────────────────────
def write_wav(path, chans, loop=False):
    n = len(chans[0])
    frames = bytearray()
    pack = struct.pack_into
    nch = len(chans)
    frames = bytearray(n * nch * 2)
    off = 0
    for i in range(n):
        for c in chans:
            v = int(round(c[i] * 32767.0))
            v = max(-32767, min(32767, v))
            pack("<h", frames, off, v)
            off += 2
    with wave.open(path, "wb") as w:
        w.setnchannels(nch)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    if loop:
        # bloque «smpl» con un bucle hacia delante de todo el archivo (Godot lo usa al importar)
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, n - 1, 0, 0)
        with open(path, "r+b") as f:
            f.seek(0, 2)
            f.write(b"smpl" + struct.pack("<I", len(smpl)) + smpl)
            size = f.tell()
            f.seek(4)
            f.write(struct.pack("<I", size - 8))


def render(name):
    s = SPEC[name]
    rng = random.Random(zlib.crc32(name.encode("utf-8")))
    if s["loop"]:
        L, F, P = ns(s["dur"]), ns(LOOP_FADE), ns(LOOP_PREROLL)
        chans = s["gen"](rng, P + L + F)
        chans = [c[P:] for c in chans]
        chans = make_loop(chans, L, F)
        chans = finalize(chans, s["level"])
        chans = seam_rotate(chans)
    else:
        chans = s["gen"](rng, ns(s["dur"]))
        chans = [c[:ns(s["dur"])] for c in chans]
        chans = finalize(chans, s["level"])
        chans = [fade_edges(c, 0.0001, 0.003) for c in chans]
    expected = 2 if s["stereo"] else 1
    if len(chans) == 1 and expected == 2:
        chans = [chans[0], chans[0][:]]
    assert len(chans) == expected, (name, len(chans))
    write_wav(os.path.join(OUT_DIR, name), chans, s["loop"])
    allv = [v for c in chans for v in c]
    return name, dict(group=s["group"], dur=s["dur"], stereo=s["stereo"], loop=s["loop"],
                      level=s["level"], tech=s["tech"],
                      rms_db=round(20 * math.log10(rms(allv)), 2),
                      peak_db=round(20 * math.log10(max(peak(c) for c in chans)), 2))


def main(argv):
    serial = "--serial" in argv
    groups = {a.upper() for a in argv if not a.startswith("--")}
    names = [k for k, v in SPEC.items() if not groups or v["group"] in groups]
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    # los más largos primero para repartir mejor la carga
    names.sort(key=lambda k: -SPEC[k]["dur"] * (2 if SPEC[k]["stereo"] else 1))
    if serial:
        results = [render(k) for k in names]
    else:
        import multiprocessing as mp
        with mp.get_context("fork").Pool(max(1, min(8, (os.cpu_count() or 2) - 2))) as pool:
            results = pool.map(render, names, chunksize=1)
    manifest = {}
    if os.path.exists(MANIFEST) and groups:
        with open(MANIFEST, encoding="utf-8") as f:
            manifest = json.load(f)
    for k, info in results:
        manifest[k] = info
        print(f"{k:34s} {info['rms_db']:7.2f} dB RMS  pico {info['peak_db']:6.2f} dB")
    manifest = {k: manifest[k] for k in SPEC if k in manifest}
    with open(MANIFEST, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    print(f"{len(results)} archivos escritos en {OUT_DIR}")


if __name__ == "__main__":
    main(sys.argv[1:])
