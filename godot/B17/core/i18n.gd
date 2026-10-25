class_name I18N extends RefCounted

const SettingsManager = preload("res://core/settings_manager.gd")

# Traduccion de la interfaz nueva (menu principal y panel de Opciones).
# El HUD de juego, las voces y los subtitulos de mision quedan fuera de este
# alcance: siguen en español/ingles de epoca fijos (ver ALTO 3.3.1 en
# planning/PRIORIZACION_COMPLEJIDAD_MENUS_OPCIONES.md).
const STRINGS: Dictionary = {
	"title": {"ES": "AURORA SOBRE EUROPA", "EN": "DAWN OVER EUROPE"},
	"subtitle": {"ES": "B-17 Flying Fortress · Invierno de 1945", "EN": "B-17 Flying Fortress · Winter 1945"},
	"play": {"ES": "Jugar", "EN": "Play"},
	"continue": {"ES": "Continuar", "EN": "Continue"},
	"options": {"ES": "Opciones", "EN": "Options"},
	"credits": {"ES": "Créditos", "EN": "Credits"},
	"quit": {"ES": "Salir", "EN": "Quit"},
	"back": {"ES": "Volver", "EN": "Back"},
	"options_title": {"ES": "OPCIONES", "EN": "OPTIONS"},
	"tab_audio": {"ES": "Audio", "EN": "Audio"},
	"tab_video": {"ES": "Video", "EN": "Video"},
	"tab_controls": {"ES": "Controles", "EN": "Controls"},
	"tab_gameplay": {"ES": "Jugabilidad", "EN": "Gameplay"},
	"tab_accessibility": {"ES": "Accesibilidad", "EN": "Accessibility"},
}

static func t(key: String) -> String:
	var lang: String = str(SettingsManager.load_all().get("ui_language", "ES"))
	var entry: Dictionary = STRINGS.get(key, {})
	return str(entry.get(lang, entry.get("ES", key)))
