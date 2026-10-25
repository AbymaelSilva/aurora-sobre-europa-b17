extends SceneTree
# Carga los 47 efectos de assets/audio/sfx con AudioStreamWAV.load_from_file y comprueba
# datos, mix_rate, canales, duración (±15 %) y, en los bucles, el bucle del bloque «smpl».
# Escrito por Claude (2026-10-24).

const SFX_DIR := "res://assets/audio/sfx/"

# nombre: [duración mínima, duración máxima, estéreo, bucle]
const EXPECTED := {
    "engine_b17_ext_loop.wav": [8.0, 8.0, false, true],
    "engine_b17_int_loop.wav": [8.0, 8.0, false, true],
    "engine_b17_damaged_loop.wav": [6.0, 6.0, false, true],
    "engine_sputter_01.wav": [1.0, 1.5, false, false],
    "engine_sputter_02.wav": [1.0, 1.5, false, false],
    "engine_fire_loop.wav": [5.0, 5.0, false, true],
    "wind_altitude_loop.wav": [10.0, 10.0, true, true],
    "formation_drone_loop.wav": [10.0, 10.0, true, true],
    "gun_m2_shot_01.wav": [0.25, 0.35, false, false],
    "gun_m2_shot_02.wav": [0.25, 0.35, false, false],
    "gun_m2_shot_03.wav": [0.25, 0.35, false, false],
    "gun_m2_burst.wav": [1.0, 1.0, false, false],
    "gun_casings_01.wav": [0.8, 0.8, false, false],
    "hit_hull_01.wav": [0.2, 0.4, false, false],
    "hit_hull_02.wav": [0.2, 0.4, false, false],
    "hit_hull_03.wav": [0.2, 0.4, false, false],
    "shrapnel_rattle_01.wav": [0.8, 0.8, false, false],
    "damage_alarm_bell.wav": [1.5, 1.5, false, false],
    "fighter_flyby_01.wav": [3.0, 4.0, true, false],
    "fighter_flyby_02.wav": [3.0, 4.0, true, false],
    "fighter_engine_loop.wav": [4.0, 4.0, false, true],
    "fighter_guns_distant.wav": [1.2, 1.2, false, false],
    "fighter_explosion.wav": [2.5, 2.5, false, false],
    "fighter_falling_whine.wav": [4.0, 4.0, false, false],
    "flak_near_01.wav": [1.2, 1.8, false, false],
    "flak_near_02.wav": [1.2, 1.8, false, false],
    "flak_near_03.wav": [1.2, 1.8, false, false],
    "flak_far_01.wav": [1.5, 1.5, false, false],
    "flak_far_02.wav": [1.5, 1.5, false, false],
    "bomb_bay_doors_open.wav": [2.5, 2.5, false, false],
    "bomb_release.wav": [0.5, 0.5, false, false],
    "bomb_impact_distant.wav": [3.0, 3.0, false, false],
    "bomb_secondary_explosions.wav": [4.0, 4.0, false, false],
    "ui_navigate.wav": [0.06, 0.06, false, false],
    "ui_accept.wav": [0.15, 0.15, false, false],
    "ui_back.wav": [0.15, 0.15, false, false],
    "ui_pause.wav": [0.3, 0.3, false, false],
    "ui_profile_change.wav": [0.12, 0.12, false, false],
    "station_switch.wav": [0.25, 0.25, false, false],
    "cue_release_tick.wav": [0.08, 0.08, false, false],
    "cue_release_now.wav": [0.4, 0.4, false, false],
    "cue_course_correction.wav": [0.3, 0.3, false, false],
    "radio_squelch_open.wav": [0.25, 0.25, false, false],
    "radio_squelch_close.wav": [0.2, 0.2, false, false],
    "radio_static_loop.wav": [4.0, 4.0, false, true],
    "stinger_mission_complete.wav": [4.0, 4.0, true, false],
    "stinger_mission_failed.wav": [4.0, 4.0, true, false],
}

func _initialize() -> void:
    call_deferred("run_checks")

func fail(msg: String) -> void:
    print("TEST FAIL: ", msg)
    quit(1)

func run_checks() -> void:
    if EXPECTED.size() != 47:
        fail("la tabla tiene %d entradas" % EXPECTED.size())
        return
    var total_len := 0.0
    for file_name in EXPECTED:
        var spec: Array = EXPECTED[file_name]
        var path: String = SFX_DIR + file_name
        if not FileAccess.file_exists(path):
            fail("no existe " + path)
            return
        var stream := AudioStreamWAV.load_from_file(path)
        if stream == null:
            fail("no se pudo cargar " + path)
            return
        if stream.data.size() < 1000:
            fail("%s: datos vacíos (%d bytes)" % [file_name, stream.data.size()])
            return
        if stream.mix_rate != 44100:
            fail("%s: mix_rate %d" % [file_name, stream.mix_rate])
            return
        if stream.format != AudioStreamWAV.FORMAT_16_BITS:
            fail("%s: formato %d (se esperaban 16 bits)" % [file_name, stream.format])
            return
        if stream.stereo != spec[2]:
            fail("%s: estéreo=%s, se esperaba %s" % [file_name, stream.stereo, spec[2]])
            return
        var length := stream.get_length()
        var lo: float = spec[0] * 0.85
        var hi: float = spec[1] * 1.15
        if length < lo or length > hi:
            fail("%s: duración %.3f s fuera de [%.3f, %.3f]" % [file_name, length, lo, hi])
            return
        if spec[3] and stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
            fail("%s: es un bucle pero loop_mode=%d" % [file_name, stream.loop_mode])
            return
        if not spec[3] and stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
            fail("%s: no es un bucle pero loop_mode=%d" % [file_name, stream.loop_mode])
            return
        total_len += length
        print("ok  %-32s %6.3f s  %s  %s" % [file_name, length, "estéreo" if stream.stereo else "mono", "bucle" if spec[3] else ""])
    print("TEST PASS: %d WAV cargados (%.1f s de audio)" % [EXPECTED.size(), total_len])
    quit(0)
