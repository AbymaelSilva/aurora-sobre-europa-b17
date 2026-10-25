class_name InputActions extends RefCounted

const SettingsManager = preload("res://core/settings_manager.gd")

# Acciones remapeables (ALTO 3.1). El resto de controles (motores, torretas,
# escoltas, disparo contextual) permanecen con tecla fija por diseño.
const REMAPPABLE: Array[String] = [
	"b17_piloto", "b17_artillero", "b17_bombardero",
	"b17_pausa", "b17_autopiloto", "b17_reiniciar",
]

const DEFAULTS: Dictionary = {
	"b17_piloto": [KEY_1],
	"b17_artillero": [KEY_2],
	"b17_bombardero": [KEY_3],
	"b17_pausa": [KEY_ESCAPE, KEY_P],
	"b17_autopiloto": [KEY_TAB],
	"b17_reiniciar": [KEY_R],
}

const LABELS: Dictionary = {
	"b17_piloto": "Puesto: Piloto",
	"b17_artillero": "Puesto: Artillero",
	"b17_bombardero": "Puesto: Bombardero",
	"b17_pausa": "Pausa",
	"b17_autopiloto": "Piloto automático",
	"b17_reiniciar": "Reiniciar misión",
}

static func ensure_defaults() -> void:
	for action in REMAPPABLE:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for keycode in DEFAULTS[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = keycode
				InputMap.action_add_event(action, ev)
	_load_saved_bindings()

static func key_label(action: String) -> String:
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode)
	return "?"

static func rebind(action: String, physical_keycode: int) -> String:
	# Devuelve "" si se asignó sin conflicto, o el nombre de la acción en conflicto.
	for other in REMAPPABLE:
		if other == action:
			continue
		for ev in InputMap.action_get_events(other):
			if ev is InputEventKey and ev.physical_keycode == physical_keycode:
				return other
	InputMap.action_erase_events(action)
	var new_ev := InputEventKey.new()
	new_ev.physical_keycode = physical_keycode
	InputMap.action_add_event(action, new_ev)
	_save_bindings()
	return ""

static func reset_to_defaults() -> void:
	for action in REMAPPABLE:
		InputMap.action_erase_events(action)
		for keycode in DEFAULTS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
	_save_bindings()

static func _save_bindings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SettingsManager.SETTINGS_PATH)
	for action in REMAPPABLE:
		var codes: Array = []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				codes.append(ev.physical_keycode)
		cfg.set_value("remapeo", action, codes)
	cfg.save(SettingsManager.SETTINGS_PATH)

static func _load_saved_bindings() -> void:
	if not FileAccess.file_exists(SettingsManager.SETTINGS_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(SettingsManager.SETTINGS_PATH) != OK:
		return
	for action in REMAPPABLE:
		if not cfg.has_section_key("remapeo", action):
			continue
		var codes: Array = cfg.get_value("remapeo", action, [])
		if codes.is_empty():
			continue
		InputMap.action_erase_events(action)
		for keycode in codes:
			var ev := InputEventKey.new()
			ev.physical_keycode = int(keycode)
			InputMap.action_add_event(action, ev)
