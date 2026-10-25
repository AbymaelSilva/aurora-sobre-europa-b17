class_name InputProfile extends RefCounted

const PROFILES: Array[String] = ["TECLADO_RATON", "XBOX", "ROG_ALLY_X"]
const SETTINGS_PATH: String = "user://b17_settings.cfg"

static func load_profile() -> String:
    if not FileAccess.file_exists(SETTINGS_PATH):
        return "TECLADO_RATON"
    var cfg := ConfigFile.new()
    var err := cfg.load(SETTINGS_PATH)
    if err != OK or not cfg.has_section_key("controles", "perfil"):
        return "TECLADO_RATON"
    var val: String = str(cfg.get_value("controles", "perfil", ""))
    if val in PROFILES:
        return val
    return "TECLADO_RATON"

static func save_profile(name: String) -> void:
    if not name in PROFILES:
        return
    var cfg := ConfigFile.new()
    cfg.load(SETTINGS_PATH)
    cfg.set_value("controles", "perfil", name)
    cfg.save(SETTINGS_PATH)

static func display_name(profile) -> String:
    match str(profile):
        "TECLADO_RATON": return "Teclado y ratón"
        "XBOX": return "Mando Xbox"
        "ROG_ALLY_X": return "ROG Ally X"
        _: return str(profile)

static func suggest_profile(names: Array) -> String:
    if names.is_empty():
        return "TECLADO_RATON"
    for item in names:
        var s: String = str(item).to_lower()
        if "ally" in s or "asus" in s:
            return "ROG_ALLY_X"
    return "XBOX"

static func prompt(action: String, profile: String) -> String:
    match profile:
        "XBOX":
            match action:
                "soltar": return "A"
                "disparar": return "RB / X"
                "pausa": return "Menú (≡)"
                "reiniciar": return "A"
                "autopiloto": return "Vista (⧉)"
                "piloto": return "Cruceta ↑"
                "artillero": return "Cruceta →"
                "bombardero": return "Cruceta ↓"
                "aceptar": return "A"
                "volver": return "B"
                "puestos": return "Cruceta"
                _: return ""
        "ROG_ALLY_X":
            match action:
                "soltar": return "A"
                "disparar": return "RB / X"
                "pausa": return "Menú"
                "reiniciar": return "A"
                "autopiloto": return "Vista"
                "piloto": return "Cruceta ↑"
                "artillero": return "Cruceta →"
                "bombardero": return "Cruceta ↓"
                "aceptar": return "A"
                "volver": return "B"
                "puestos": return "Cruceta"
                _: return ""
        _:
            match action:
                "soltar": return "ESPACIO"
                "disparar": return "Espacio / Clic Izq."
                "pausa": return "ESC / P"
                "reiniciar": return "R"
                "autopiloto": return "TAB"
                "piloto": return "1 (W/S/A/D)"
                "artillero": return "2 (Ratón)"
                "bombardero": return "3"
                "aceptar": return "Enter"
                "volver": return "Esc"
                "puestos": return "1/2/3"
                _: return ""
