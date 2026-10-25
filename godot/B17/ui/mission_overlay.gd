extends Control

const InputProfile = preload("res://core/input_profile.gd")
const AccessibilityPalette = preload("res://core/accessibility_palette.gd")

var data: Dictionary = {}
var font: Font = ThemeDB.fallback_font
var gold := Color(0.88, 0.74, 0.46)
var white := Color(0.92, 0.94, 0.94)
var muted := Color(0.64, 0.72, 0.75)
var panel := Color(0.025, 0.04, 0.055, 0.86)
var colorblind_mode: String = "NINGUNO"
var subtitle_scale: float = 1.0
var subtitle_opacity: float = 1.0

func _pal(semantic: String) -> Color:
    return AccessibilityPalette.color_for(semantic, colorblind_mode)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_state(value: Dictionary) -> void:
    data = value
    queue_redraw()

func text(at: Vector2, value: String, size_value: int = 18, color: Color = Color.WHITE) -> void:
    draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value, color)

func subtitle_lines(value: String) -> PackedStringArray:
    var result := PackedStringArray()
    var current: String = ""
    for word in value.split(" "):
        var candidate: String = word if current.is_empty() else current + " " + word
        if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x > 920.0 and not current.is_empty():
            result.append(current)
            current = word
        else:
            current = candidate
    if not current.is_empty(): result.append(current)
    return result

func phase_title(value: String) -> String:
    match value:
        "FORMACION": return "REUNIÓN DE LA ESCUADRILLA"
        "APROXIMACION": return "RUMBO AL OBJETIVO"
        "BOMBARDEO": return "PASADA DE BOMBARDEO"
        "REGRESO": return "REGRESO A CASA"
        "COMPLETADA": return "ZONA SEGURA ALCANZADA"
        _: return "SIN CONTACTO"

func _draw() -> void:
    if data.is_empty():
        return
    var ratio: float = minf(size.x / 1280.0, size.y / 720.0)
    if ratio <= 0.0:
        return
    draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * ratio)
    var width: float = size.x / ratio
    var height: float = size.y / ratio
    draw_rect(Rect2(24, 24, 330, 126), panel)
    draw_rect(Rect2(24, 24, 3, 126), gold)
    text(Vector2(43, 51), "EUROPA · 1945", 14, gold)
    text(Vector2(43, 83), phase_title(str(data.get("phase", ""))), 20, white)
    text(Vector2(43, 112), "Nudo ferroviario · %.1f km" % (float(data.get("distance", 0.0)) / 1000.0), 15, muted)
    text(Vector2(43, 136), "ESCUADRILLA AURORA (6 B-17)", 12, muted)

    # Panel Estado del Avión
    draw_rect(Rect2(24, height - 125, 340, 101), panel)
    text(Vector2(43, height - 102), "AURORA UNO · ESTADO DEL AVIÓN", 13, gold)
    text(Vector2(43, height - 76), "Fuselaje %.0f%%   Motor %.0f%%" % [data.get("hull", 100.0), data.get("engine", 100.0)], 18, white)
    draw_rect(Rect2(43, height - 64, 288, 5), Color(0.2, 0.24, 0.25))
    draw_rect(Rect2(43, height - 64, 288 * float(data.get("hull", 100.0)) / 100.0, 5), gold)

    # Indicadores de motores individuales M1-M4 (Mejora 1)
    var eng_hp = data.get("engines_hp", [100.0, 100.0, 100.0, 100.0])
    var eng_fth = data.get("engine_feathered", [0, 0, 0, 0])
    for i in range(4):
        var hp: float = float(eng_hp[i]) if i < eng_hp.size() else 100.0
        var fth: bool = bool(eng_fth[i]) if i < eng_fth.size() else false
        var col := _pal("positive")
        if fth:
            col = Color(0.5, 0.5, 0.5)
        elif hp < 20.0:
            col = _pal("danger")
        elif hp < 45.0:
            col = _pal("warning")
        draw_rect(Rect2(43 + i * 42, height - 52, 34, 12), col)
        var m_lbl := "M%d" % (i + 1) if not fth else "F%d" % (i + 1)
        text(Vector2(50 + i * 42, height - 42), m_lbl, 10, Color.BLACK)

    # Alerta o acción de motor reciente
    var eng_act: String = str(data.get("engine_action", ""))
    if not eng_act.is_empty():
        text(Vector2(215, height - 42), eng_act, 12, gold)
    else:
        text(Vector2(43, height - 26), "Cazas abatidos: %d" % int(data.get("kills", 0)), 12, gold)

    # Panel Instrumentos de Vuelo (con afectación de flak shrapnel - Mejora 4)
    draw_rect(Rect2(width - 270, height - 111, 246, 87), panel)
    text(Vector2(width - 252, height - 79), "%.0f NUDOS" % (float(data.get("speed", 50.0)) * 1.94384), 21, white)
    
    var alt_err: float = float(data.get("altimeter_error", 0.0))
    var comp_drift: float = float(data.get("compass_drift", 0.0))
    var alt_val: float = (float(data.get("altitude", 100.0)) + alt_err) * 3.28084
    var head_val: float = fposmod(float(data.get("heading", 0.0)) + rad_to_deg(comp_drift), 360.0)
    var inst_col := muted
    if alt_err != 0.0 or comp_drift != 0.0:
        inst_col = Color(0.95, 0.65, 0.2)
    var inst_text := "%.0f PIES · RUMBO %03.0f°" % [alt_val, head_val]
    if alt_err != 0.0: inst_text += " (!)"
    text(Vector2(width - 252, height - 46), inst_text, 13, inst_col)

    var prof: String = str(data.get("input_profile", "TECLADO_RATON"))
    var exterior: bool = bool(data.get("camera_exterior", false))
    if exterior and not bool(data.get("paused", false)):
        draw_rect(Rect2(width / 2 - 450, height - 250, 900, 72), panel)
        var observing: String = str(data.get("camera_observation", ""))
        var camera_title: String = observing if not observing.is_empty() else "VISTA EXTERIOR · %s" % str(data.get("camera_target", "Aurora Uno"))
        text(Vector2(width / 2 - 434, height - 225), camera_title, 18, gold)
        var camera_help: String = "Y: volver · Stick der.: mirar · R3: centrar · LB + cruceta: zoom / avión"
        if prof == "TECLADO_RATON":
            camera_help = "V: volver · Botón derecho + ratón: mirar · Rueda: zoom · C: centrar · [ / ]: avión"
        text(Vector2(width / 2 - 434, height - 196), camera_help, 18, white)
    elif not bool(data.get("paused", false)):
        var camera_hint: String = "V: vista exterior" if prof == "TECLADO_RATON" else "Y: vista exterior"
        text(Vector2(width - 326, 80), camera_hint, 18, white)

    var is_auto: bool = bool(data.get("autopilot", true))
    var station_name: String = str(data.get("station", "PILOTO"))
    var g_station: String = str(data.get("gunner_station", "DORSAL"))
    var auto_prompt: String = InputProfile.prompt("autopiloto", prof)
    var posts_prompt: String = InputProfile.prompt("puestos", prof)
    
    var station_full_lbl: String = station_name
    if station_name == "ARTILLERO":
        station_full_lbl = "ARTILLERO [%s]" % g_station

    var mode_label = "[%s] DEMO AUTOPILOTO" % auto_prompt if is_auto else ("[%s] MANUAL · PUESTO: %s" % [posts_prompt, station_full_lbl])
    var mode_col = gold if is_auto else Color(0.45, 0.92, 0.55)
    draw_rect(Rect2(width - 370, 24, 346, 32), panel)
    text(Vector2(width - 356, 45), mode_label, 11, mode_col)

    # Indicador de solicitud de cobertura de escoltas P-51D (Mejora 3)
    if bool(data.get("escort_cover_active", false)):
        var cov_time: float = float(data.get("escort_cover_timer", 0.0))
        draw_rect(Rect2(width / 2 - 150, 60, 300, 26), Color(0.1, 0.4, 0.7, 0.85))
        draw_string(font, Vector2(width / 2 - 140, 78), "P-51 COBERTURA CERCANA: %.1fs" % maxf(cov_time, 0.0), HORIZONTAL_ALIGNMENT_CENTER, 280, 12, Color(0.7, 0.9, 1.0))

    if bool(data.get("restart_confirm", false)):
        draw_rect(Rect2(width / 2 - 180, 24, 360, 32), panel)
        draw_rect(Rect2(width / 2 - 180, 24, 360, 2), gold)
        draw_string(font, Vector2(width / 2 - 170, 45), "Pulsa R otra vez para reiniciar", HORIZONTAL_ALIGNMENT_CENTER, 340, 13, gold)

    var phase: String = str(data.get("phase", ""))
    if phase == "BOMBARDEO":
        var aid: Dictionary = data.get("bombing_aid", {})
        var status_str: String = str(aid.get("status", ""))
        var release_now: bool = bool(aid.get("release_now", false))
        var eta: float = float(aid.get("eta_seconds", 0.0))
        var lat_err: float = float(aid.get("lateral_error_m", 0.0))
        var bomb_spent: bool = bool(data.get("bomb_active", false)) or status_str == "BOMBAS_FUERA"
        var salvo_count: int = int(data.get("salvo_count", aid.get("salvo_count", 0)))
        var bomb_result: String = str(data.get("bomb_result", aid.get("salvo_result", "")))
        var salvo_in_flight: bool = bool(data.get("bomb_active", false))
        var norden_off: bool = bool(data.get("norden_disabled", false))

        draw_rect(Rect2(width / 2 - 240, height - 100, 480, 58), panel)
        if norden_off:
            draw_rect(Rect2(width / 2 - 240, height - 100, 480, 3), _pal("danger"))
            draw_string(font, Vector2(width / 2 - 220, height - 68), "NORDEN AVERIADO · SUELTA MANUAL", HORIZONTAL_ALIGNMENT_CENTER, 440, 16, _pal("danger"))
            draw_string(font, Vector2(width / 2 - 220, height - 48), "METRALLA DE FLAK EN EL VISOR", HORIZONTAL_ALIGNMENT_CENTER, 440, 11, muted)
        elif bomb_spent:
            if bomb_result == "IMPACTO":
                draw_rect(Rect2(width / 2 - 240, height - 100, 480, 3), _pal("positive"))
                draw_string(font, Vector2(width / 2 - 220, height - 72), "ALFOMBRA DE BOMBAS IMPACTADA", HORIZONTAL_ALIGNMENT_CENTER, 440, 15, _pal("positive"))
                draw_string(font, Vector2(width / 2 - 220, height - 50), "BOMBAS FUERA · IMPACTO EN BLANCO", HORIZONTAL_ALIGNMENT_CENTER, 440, 12, white)
            elif salvo_in_flight:
                draw_rect(Rect2(width / 2 - 240, height - 100, 480, 3), gold)
                draw_string(font, Vector2(width / 2 - 220, height - 72), "SALVA EN PROGRESO: [%02d/30]" % salvo_count, HORIZONTAL_ALIGNMENT_CENTER, 440, 15, gold)
                draw_string(font, Vector2(width / 2 - 220, height - 50), "BOMBAS FUERA · OBSERVANDO IMPACTO", HORIZONTAL_ALIGNMENT_CENTER, 440, 12, muted)
            else:
                draw_rect(Rect2(width / 2 - 240, height - 100, 480, 3), muted)
                draw_string(font, Vector2(width / 2 - 220, height - 66), "BOMBAS FUERA · OBSERVANDO IMPACTO", HORIZONTAL_ALIGNMENT_CENTER, 440, 15, muted)
        elif release_now:
            var bomb_prompt: String = InputProfile.prompt("soltar", prof)
            draw_rect(Rect2(width / 2 - 240, height - 100, 480, 3), _pal("positive"))
            draw_string(font, Vector2(width / 2 - 220, height - 68), "¡¡ SUELTA AHORA !! [%s]" % bomb_prompt, HORIZONTAL_ALIGNMENT_CENTER, 440, 20, _pal("positive"))
            draw_string(font, Vector2(width / 2 - 220, height - 48), "SOLUCIÓN BALÍSTICA VÁLIDA", HORIZONTAL_ALIGNMENT_CENTER, 440, 11, white)
        elif status_str == "PASADO":
            draw_rect(Rect2(width / 2 - 240, height - 100, 480, 3), _pal("danger"))
            draw_string(font, Vector2(width / 2 - 220, height - 66), "OBJETIVO SUPERADO · FUERA DE VENTANA", HORIZONTAL_ALIGNMENT_CENTER, 440, 15, _pal("danger"))
        elif absf(lat_err) > 45.0:
            var dir_txt: String = "GIRAR A LA DERECHA (D)" if lat_err > 0.0 else "GIRAR A LA IZQUIERDA (A)"
            draw_rect(Rect2(width / 2 - 240, height - 100, 480, 3), gold)
            draw_string(font, Vector2(width / 2 - 220, height - 72), "CORRECCIÓN DE RUMBO: %s" % dir_txt, HORIZONTAL_ALIGNMENT_CENTER, 440, 14, gold)
            draw_string(font, Vector2(width / 2 - 220, height - 50), "Desvío lateral: %.0f m" % absf(lat_err), HORIZONTAL_ALIGNMENT_CENTER, 440, 12, muted)
        else:
            var eta_txt: String = "T-%.1fs" % maxf(eta, 0.0) if eta < 99.0 else "EN ESPERA"
            var align_txt: String = "ALINEADO" if absf(lat_err) < 20.0 else ("EJE DER %.0fm" % lat_err if lat_err > 0 else "EJE IZQ %.0fm" % -lat_err)
            draw_rect(Rect2(width / 2 - 240, height - 100, 480, 3), gold)
            draw_string(font, Vector2(width / 2 - 220, height - 72), "VENTANA DE SUELTA EN %s" % eta_txt, HORIZONTAL_ALIGNMENT_CENTER, 440, 15, white)
            draw_string(font, Vector2(width / 2 - 220, height - 50), "Guía balística · %s" % align_txt, HORIZONTAL_ALIGNMENT_CENTER, 440, 12, gold)

    if float(data.get("elapsed", 0.0)) < 8.0:
        draw_string(font, Vector2(width / 2 - 350, height * 0.22), "AURORA SOBRE EUROPA", HORIZONTAL_ALIGNMENT_CENTER, 700, 34, white)
        draw_string(font, Vector2(width / 2 - 350, height * 0.22 + 34), "UNA MISIÓN. UNA TRIPULACIÓN.", HORIZONTAL_ALIGNMENT_CENTER, 700, 14, gold)
        var p_pilot: String = InputProfile.prompt("piloto", prof)
        var p_gun: String = InputProfile.prompt("artillero", prof)
        var p_bm: String = InputProfile.prompt("bombardero", prof)
        var p_btxt: String = InputProfile.prompt("soltar", prof)
        var intro_line: String = "Piloto: %s · Artillero: %s · Bombardero: %s (Bomba: %s)" % [p_pilot, p_gun, p_bm, p_btxt]
        draw_string(font, Vector2(width / 2 - 450, height * 0.22 + 60), intro_line, HORIZONTAL_ALIGNMENT_CENTER, 900, 12, gold)

    var radio_text: String = str(data.get("radio", ""))
    if not radio_text.is_empty():
        var lines: PackedStringArray = subtitle_lines(radio_text)
        var line_count: int = mini(2, lines.size())
        var sub_size: int = roundi(20.0 * subtitle_scale)
        var line_h: float = 25.0 * subtitle_scale
        var box_height: float = 14.0 + line_count * line_h
        var sub_panel: Color = panel
        sub_panel.a *= subtitle_opacity
        var sub_white: Color = white
        sub_white.a = subtitle_opacity
        draw_rect(Rect2(width / 2 - 480, height - 174, 960, box_height), sub_panel)
        for i in range(line_count):
            draw_string(font, Vector2(width / 2 - 460, height - 150 + i * line_h), lines[i], HORIZONTAL_ALIGNMENT_CENTER, 920, sub_size, sub_white)

    if phase in ["COMPLETADA", "FALLIDA"]:
        draw_rect(Rect2(width / 2 - 320, height * 0.35, 640, 210), panel)
        draw_string(font, Vector2(width / 2 - 300, height * 0.35 + 60), "MISIÓN COMPLETADA" if phase == "COMPLETADA" else ("OBJETIVO NO ALCANZADO" if data.get("reason", "") == "FALLO" else "AVIÓN PERDIDO"), HORIZONTAL_ALIGNMENT_CENTER, 600, 30, white)
        draw_string(font, Vector2(width / 2 - 300, height * 0.35 + 110), "Tripulación en zona segura" if phase == "COMPLETADA" else ("El bombardeo no alcanzó el objetivo" if data.get("reason", "") == "FALLO" else "Sin contacto con Aurora uno"), HORIZONTAL_ALIGNMENT_CENTER, 600, 18, gold)
        var report: Dictionary = data.get("report", {})
        var duration: int = int(report.get("duration_seconds", 0.0))
        var summary: String = "%02d:%02d · Fuselaje %.0f%% · Motores disponibles %d/4" % [duration / 60, duration % 60, report.get("hull", 0.0), report.get("engines_available", 0)]
        draw_string(font, Vector2(width / 2 - 300, height * 0.35 + 151), summary, HORIZONTAL_ALIGNMENT_CENTER, 600, 16, muted)
        var p_rst: String = InputProfile.prompt("reiniciar", prof)
        draw_string(font, Vector2(width / 2 - 300, height * 0.35 + 184), "%s · VOLVER A VOLAR" % p_rst, HORIZONTAL_ALIGNMENT_CENTER, 600, 13, gold)

    if data.get("paused", false):
        draw_rect(Rect2(0, 0, width, height), Color(0, 0, 0, 0.3))
        if not data.get("menu_visible", false):
            draw_string(font, Vector2(width / 2 - 200, height / 2), "PAUSA", HORIZONTAL_ALIGNMENT_CENTER, 400, 36, white)
