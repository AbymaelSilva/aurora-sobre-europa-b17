#!/usr/bin/env python3
"""Verificación automática del set de efectos de sonido (solo biblioteca estándar).

    python3 -I tools_audio/check_sfx.py

La tabla de abajo se copia del encargo (no se importa del sintetizador) para que la
comprobación sea independiente. Escribe logs/audio/check_sfx.log y logs/audio/check_sfx.json.
Código de salida 0 solo si pasan todos los archivos. Escrito por Claude (2026-10-24).
"""
import hashlib
import json
import math
import os
import struct
import sys
import time
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "godot", "B17", "assets", "audio", "sfx")
LOG = os.path.join(ROOT, "logs", "audio", "check_sfx.log")
JSN = os.path.join(ROOT, "logs", "audio", "check_sfx.json")

SR = 44100
FS = 32768.0
LEVELS = {"motor": -20.0, "arma": -14.0, "ui": -22.0}
RMS_TOL = 6.0
DUR_TOL = 0.15
PEAK_MAX_DB = -1.0
ONSET_MAX_S = 0.010        # silencio inicial máximo en los sonidos de un disparo
ONSET_DB = -40.0
SEAM_MAX = 0.02            # salto última → primera muestra en bucles (fracción de escala completa)
WIN_S = 0.02
MIN_RMS_DB = -45.0
MIN_WINDOW_CV = 0.05       # por debajo, el nivel es tan estable como el de un ruido estacionario
WHITE_R1 = 0.2             # autocorrelación de retardo 1 de un ruido blanco ≈ 0
MAX_SET_MB = 60.0

# nombre: (duración_s o (mín, máx), estéreo, bucle, grupo_de_nivel)
E = True
EXPECTED = {
    # A. B-17: motores y vuelo
    "engine_b17_ext_loop.wav": (8.0, False, True, "motor"),
    "engine_b17_int_loop.wav": (8.0, False, True, "motor"),
    "engine_b17_damaged_loop.wav": (6.0, False, True, "motor"),
    "engine_sputter_01.wav": ((1.0, 1.5), False, False, "motor"),
    "engine_sputter_02.wav": ((1.0, 1.5), False, False, "motor"),
    "engine_fire_loop.wav": (5.0, False, True, "motor"),
    "wind_altitude_loop.wav": (10.0, E, True, "motor"),
    "formation_drone_loop.wav": (10.0, E, True, "motor"),
    # B. Armas propias
    "gun_m2_shot_01.wav": ((0.25, 0.35), False, False, "arma"),
    "gun_m2_shot_02.wav": ((0.25, 0.35), False, False, "arma"),
    "gun_m2_shot_03.wav": ((0.25, 0.35), False, False, "arma"),
    "gun_m2_burst.wav": (1.0, False, False, "arma"),
    "gun_casings_01.wav": (0.8, False, False, "arma"),
    # C. Daños en el propio avión
    "hit_hull_01.wav": ((0.2, 0.4), False, False, "arma"),
    "hit_hull_02.wav": ((0.2, 0.4), False, False, "arma"),
    "hit_hull_03.wav": ((0.2, 0.4), False, False, "arma"),
    "shrapnel_rattle_01.wav": (0.8, False, False, "arma"),
    "damage_alarm_bell.wav": (1.5, False, False, "arma"),
    # D. Cazas enemigos
    "fighter_flyby_01.wav": ((3.0, 4.0), E, False, "motor"),
    "fighter_flyby_02.wav": ((3.0, 4.0), E, False, "motor"),
    "fighter_engine_loop.wav": (4.0, False, True, "motor"),
    "fighter_guns_distant.wav": (1.2, False, False, "arma"),
    "fighter_explosion.wav": (2.5, False, False, "arma"),
    "fighter_falling_whine.wav": (4.0, False, False, "motor"),
    # E. Flak
    "flak_near_01.wav": ((1.2, 1.8), False, False, "arma"),
    "flak_near_02.wav": ((1.2, 1.8), False, False, "arma"),
    "flak_near_03.wav": ((1.2, 1.8), False, False, "arma"),
    "flak_far_01.wav": (1.5, False, False, "arma"),
    "flak_far_02.wav": (1.5, False, False, "arma"),
    # F. Bombardeo
    "bomb_bay_doors_open.wav": (2.5, False, False, "motor"),
    "bomb_release.wav": (0.5, False, False, "arma"),
    "bomb_impact_distant.wav": (3.0, False, False, "arma"),
    "bomb_secondary_explosions.wav": (4.0, False, False, "arma"),
    # G. Interfaz, HUD y radio
    "ui_navigate.wav": (0.06, False, False, "ui"),
    "ui_accept.wav": (0.15, False, False, "ui"),
    "ui_back.wav": (0.15, False, False, "ui"),
    "ui_pause.wav": (0.3, False, False, "ui"),
    "ui_profile_change.wav": (0.12, False, False, "ui"),
    "station_switch.wav": (0.25, False, False, "ui"),
    "cue_release_tick.wav": (0.08, False, False, "ui"),
    "cue_release_now.wav": (0.4, False, False, "ui"),
    "cue_course_correction.wav": (0.3, False, False, "ui"),
    "radio_squelch_open.wav": (0.25, False, False, "ui"),
    "radio_squelch_close.wav": (0.2, False, False, "ui"),
    "radio_static_loop.wav": (4.0, False, True, "ui"),
    # H. Misión
    "stinger_mission_complete.wav": (4.0, E, False, "motor"),
    "stinger_mission_failed.wav": (4.0, E, False, "motor"),
}


def db(x):
    return 20.0 * math.log10(max(x, 1e-12))


def has_smpl_loop(path):
    with open(path, "rb") as f:
        data = f.read()
    i = data.find(b"smpl")
    if i < 0:
        return False
    num_loops = struct.unpack_from("<I", data, i + 8 + 28)[0]
    return num_loops >= 1


def analyse(path, spec):
    dur_spec, stereo, loop, group = spec
    res = {"file": os.path.basename(path), "group": group, "loop": loop, "errors": []}
    err = res["errors"]
    with wave.open(path, "rb") as w:
        nch, sw, sr, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(n)
    res.update(channels=nch, bits=sw * 8, rate=sr, frames=n, duration=round(n / sr, 4))
    if sw != 2:
        err.append(f"{sw * 8} bits (se esperaban 16)")
        return res
    if sr != SR:
        err.append(f"{sr} Hz (se esperaban {SR})")
    if nch != (2 if stereo else 1):
        err.append(f"{nch} canales (se esperaban {2 if stereo else 1})")
    data = struct.unpack("<%dh" % (n * nch), raw)
    chans = [data[c::nch] for c in range(nch)]

    # duración
    lo, hi = (dur_spec, dur_spec) if not isinstance(dur_spec, tuple) else dur_spec
    lo_ok, hi_ok = lo * (1 - DUR_TOL), hi * (1 + DUR_TOL)
    d = n / sr
    res["dur_range"] = [round(lo_ok, 4), round(hi_ok, 4)]
    if not lo_ok <= d <= hi_ok:
        err.append(f"duración {d:.3f} s fuera de [{lo_ok:.3f}, {hi_ok:.3f}]")

    # pico y recorte
    pk = max(max(abs(v) for v in c) for c in chans)
    clipped = sum(1 for c in chans for v in c if v >= 32767 or v <= -32768)
    res["peak_dbfs"] = round(db(pk / FS), 2)
    res["clipped_samples"] = clipped
    if res["peak_dbfs"] > PEAK_MAX_DB:
        err.append(f"pico {res['peak_dbfs']} dBFS > {PEAK_MAX_DB}")
    if clipped:
        err.append(f"{clipped} muestras recortadas")

    # RMS por grupo
    total = sum(v * v for c in chans for v in c)
    r = math.sqrt(total / (n * nch)) / FS
    res["rms_dbfs"] = round(db(r), 2)
    target = LEVELS[group]
    res["rms_target"] = target
    if abs(res["rms_dbfs"] - target) > RMS_TOL:
        err.append(f"RMS {res['rms_dbfs']} dBFS fuera de {target} ± {RMS_TOL}")
    res["crest_db"] = round(res["peak_dbfs"] - res["rms_dbfs"], 2)

    # inicio (sonidos de un disparo) / unión (bucles)
    thr = FS * 10 ** (ONSET_DB / 20)
    if loop:
        seam = max(abs(c[-1] - c[0]) for c in chans) / FS
        res["seam_jump"] = round(seam, 5)
        if seam >= SEAM_MAX:
            err.append(f"salto en la unión {seam:.4f} ≥ {SEAM_MAX}")
        edge = int(0.05 * sr)
        e_db = [db(math.sqrt(sum(v * v for v in c[:edge]) / edge) / FS) for c in chans] + \
               [db(math.sqrt(sum(v * v for v in c[-edge:]) / edge) / FS) for c in chans]
        res["edge_rms_min_dbfs"] = round(min(e_db), 2)
        if min(e_db) < -50.0:
            err.append("silencio al principio o al final del bucle")
        res["smpl_loop_chunk"] = has_smpl_loop(path)
    else:
        onset = next((i for i in range(n) if max(abs(c[i]) for c in chans) >= thr), n)
        res["onset_ms"] = round(1000.0 * onset / sr, 2)
        if onset / sr > ONSET_MAX_S:
            err.append(f"silencio inicial {1000 * onset / sr:.1f} ms > {1000 * ONSET_MAX_S:.0f} ms")

    # ni silencio ni ruido blanco puro
    mono = [sum(c[i] for c in chans) / nch for i in range(n)]
    win = int(WIN_S * sr)
    wr = []
    for k in range(0, n - win + 1, win):
        seg = mono[k:k + win]
        wr.append(math.sqrt(sum(v * v for v in seg) / win))
    mean = sum(wr) / len(wr)
    cv = math.sqrt(sum((v - mean) ** 2 for v in wr) / len(wr)) / mean if mean > 0 else 0.0
    num = sum(mono[i] * mono[i - 1] for i in range(1, n))
    den = sum(v * v for v in mono) or 1.0
    r1 = num / den
    zc = sum(1 for i in range(1, n) if (mono[i] >= 0) != (mono[i - 1] >= 0))
    res["window_rms_cv"] = round(cv, 4)
    res["lag1_autocorr"] = round(r1, 4)
    res["zero_cross_hz"] = round(zc / (2 * d), 1)    # estimación grosera del «brillo»
    if res["rms_dbfs"] < MIN_RMS_DB:
        err.append("es prácticamente silencio")
    if cv < MIN_WINDOW_CV and abs(r1) < WHITE_R1:
        err.append(f"parece ruido blanco puro (CV {cv:.3f}, r1 {r1:.3f})")
    if stereo and nch == 2:
        sl = sum(a * b for a, b in zip(chans[0], chans[1]))
        el = math.sqrt(sum(a * a for a in chans[0]) * sum(b * b for b in chans[1])) or 1.0
        res["lr_correlation"] = round(sl / el, 4)
    with open(path, "rb") as f:
        res["sha256"] = hashlib.sha256(f.read()).hexdigest()
    res["bytes"] = os.path.getsize(path)
    return res


def main():
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    lines = [f"check_sfx · {time.strftime('%Y-%m-%d %H:%M:%S')} · {SFX}"]
    results, failed = [], 0
    present = sorted(f for f in os.listdir(SFX) if f.endswith(".wav")) if os.path.isdir(SFX) else []
    extra = sorted(set(present) - set(EXPECTED))
    missing = [k for k in EXPECTED if k not in present]
    for name, spec in EXPECTED.items():
        path = os.path.join(SFX, name)
        if name in missing:
            res = {"file": name, "errors": ["no existe"]}
        else:
            res = analyse(path, spec)
        res["pass"] = not res["errors"]
        failed += 0 if res["pass"] else 1
        results.append(res)
        if res["pass"]:
            extra_info = (f"unión {res['seam_jump']:.4f}" if spec[2] else f"inicio {res['onset_ms']:5.2f} ms")
            lines.append(f"PASS {name:34s} {res['channels']}ch {res['duration']:6.3f} s  "
                         f"pico {res['peak_dbfs']:6.2f}  RMS {res['rms_dbfs']:6.2f} ({res['rms_target']:+.0f})  "
                         f"{extra_info}  CV {res['window_rms_cv']:.3f}  r1 {res['lag1_autocorr']:.3f}")
        else:
            lines.append(f"FAIL {name:34s} " + "; ".join(res["errors"]))
    total_bytes = sum(r.get("bytes", 0) for r in results)
    size_ok = total_bytes / 1e6 < MAX_SET_MB
    if not size_ok:
        failed += 1
    if extra:
        lines.append("Aviso: archivos no esperados: " + ", ".join(extra))
    lines.append(f"Esperados {len(EXPECTED)} · presentes {len(EXPECTED) - len(missing)} · "
                 f"fallan {failed} · tamaño {total_bytes / 1e6:.2f} MB (límite {MAX_SET_MB:.0f} MB"
                 f"{'' if size_ok else ', EXCEDIDO'})")
    lines.append("RESULTADO: " + ("PASS" if failed == 0 else "FAIL"))
    text = "\n".join(lines) + "\n"
    print(text, end="")
    with open(LOG, "w", encoding="utf-8") as f:
        f.write(text)
    summary = {
        "date": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "dir": SFX,
        "expected": len(EXPECTED), "present": len(EXPECTED) - len(missing), "failed": failed,
        "missing": missing, "unexpected": extra,
        "total_bytes": total_bytes, "result": "PASS" if failed == 0 else "FAIL",
        "criteria": {"rate": SR, "bits": 16, "dur_tol": DUR_TOL, "peak_max_dbfs": PEAK_MAX_DB,
                     "rms_targets": LEVELS, "rms_tol_db": RMS_TOL, "onset_max_s": ONSET_MAX_S,
                     "onset_threshold_dbfs": ONSET_DB, "seam_max_fs": SEAM_MAX,
                     "window_s": WIN_S, "min_window_cv": MIN_WINDOW_CV, "white_r1": WHITE_R1},
        "files": results,
    }
    with open(JSN, "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
