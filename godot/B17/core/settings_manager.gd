class_name SettingsManager extends RefCounted

const SETTINGS_PATH: String = "user://b17_settings.cfg"
const SECTION: String = "ajustes"

const DIFFICULTIES: Array[String] = ["FACIL", "NORMAL", "DIFICIL"]
const WINDOW_MODES: Array[String] = ["VENTANA", "COMPLETA", "SIN_BORDES"]
const QUALITIES: Array[String] = ["BAJO", "MEDIO", "ALTO"]
const COLORBLIND_MODES: Array[String] = ["NINGUNO", "PROTANOPIA", "DEUTERANOPIA", "TRITANOPIA"]
const UI_LANGUAGES: Array[String] = ["ES", "EN"]
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

static func defaults() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 1.0,
		"effects_volume": 1.0,
		"voice_volume": 1.0,
		"music_enabled": true,
		"voice_enabled": true,
		"pitch_sensitivity": 1.0,
		"turn_sensitivity": 1.0,
		"throttle_sensitivity": 1.0,
		"invert_pitch": false,
		"difficulty": "NORMAL",
		"flight_assist": false,
		"subtitle_scale": 1.0,
		"subtitle_opacity": 1.0,
		"reduce_shake": false,
		"resolution_index": 0,
		"window_mode": "VENTANA",
		"vsync": true,
		"graphics_quality": "ALTO",
		"colorblind_mode": "NINGUNO",
		"ui_language": "ES",
	}

static func load_all() -> Dictionary:
	var data := defaults()
	if not FileAccess.file_exists(SETTINGS_PATH):
		return data
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return data
	for key in data.keys():
		if cfg.has_section_key(SECTION, key):
			data[key] = cfg.get_value(SECTION, key, data[key])
	return data

static func save_all(data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	for key in data.keys():
		cfg.set_value(SECTION, key, data[key])
	cfg.save(SETTINGS_PATH)

static func save_one(key: String, value) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(SECTION, key, value)
	cfg.save(SETTINGS_PATH)

static func difficulty_multiplier(difficulty: String) -> float:
	match difficulty:
		"FACIL": return 0.7
		"DIFICIL": return 1.35
		_: return 1.0

static func difficulty_attacker_bonus(difficulty: String) -> int:
	match difficulty:
		"FACIL": return -2
		"DIFICIL": return 2
		_: return 0

static func apply_video(data: Dictionary) -> void:
	var res_idx: int = clampi(int(data.get("resolution_index", 0)), 0, RESOLUTIONS.size() - 1)
	var res: Vector2i = RESOLUTIONS[res_idx]
	match str(data.get("window_mode", "VENTANA")):
		"COMPLETA":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"SIN_BORDES":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(res)
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(res)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if bool(data.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
	)
	var quality: String = str(data.get("graphics_quality", "ALTO"))
	var msaa := Viewport.MSAA_4X
	match quality:
		"BAJO": msaa = Viewport.MSAA_DISABLED
		"MEDIO": msaa = Viewport.MSAA_2X
		_: msaa = Viewport.MSAA_4X
	var main_vp: Viewport = Engine.get_main_loop().root if Engine.get_main_loop() is SceneTree else null
	if main_vp != null:
		main_vp.msaa_3d = msaa

static func apply_audio(data: Dictionary) -> void:
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(clampf(float(data.get("master_volume", 1.0)), 0.0001, 1.0)))
	for bus_name in ["B17Music", "B17Dialogue", "B17Effects"]:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		var vol: float = 1.0
		match bus_name:
			"B17Music": vol = float(data.get("music_volume", 1.0))
			"B17Dialogue": vol = float(data.get("voice_volume", 1.0))
			"B17Effects": vol = float(data.get("effects_volume", 1.0))
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(vol, 0.0001, 1.0)))
