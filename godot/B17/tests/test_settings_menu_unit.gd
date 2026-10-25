extends SceneTree

# Test unitario para ui/settings_menu.gd

var original_settings_data: PackedByteArray = []
var original_settings_existed: bool = false
const SETTINGS_FILE_PATH := "user://b17_settings.cfg"

func finish(code: int) -> void:
	_restore_settings()
	quit(code)

func _fail(msg: String) -> void:
	print(msg)
	finish(1)

func _restore_settings() -> void:
	if original_settings_existed:
		var f := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
		if f != null:
			f.store_buffer(original_settings_data)
			f.close()
	else:
		if FileAccess.file_exists(SETTINGS_FILE_PATH):
			DirAccess.remove_absolute(SETTINGS_FILE_PATH)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	original_settings_existed = FileAccess.file_exists(SETTINGS_FILE_PATH)
	if original_settings_existed:
		original_settings_data = FileAccess.get_file_as_bytes(SETTINGS_FILE_PATH)

	var MenuScript = load("res://ui/settings_menu.gd")
	if MenuScript == null:
		_fail("TEST FAIL: no se pudo cargar res://ui/settings_menu.gd")
		return

	var menu = MenuScript.new()
	root.add_child(menu)
	await process_frame

	if not menu.has_signal("resume_requested") or not menu.has_signal("restart_requested") or not menu.has_signal("profile_changed"):
		_fail("TEST FAIL: menu no define las senales requeridas")
		menu.queue_free()
		return

	# Comprobar inicializacion de perfil
	if menu.has_method("set_profile"):
		menu.set_profile("TECLADO_RATON")
	if "current_profile" in menu and menu.current_profile != "TECLADO_RATON":
		_fail("TEST FAIL: current_profile no coincide")
		menu.queue_free()
		return

	var prof_btn = menu.get_node_or_null("ProfileButton")
	if prof_btn == null:
		prof_btn = menu.find_child("*Profile*", true, false)
	if prof_btn != null and prof_btn.text != "Controles: ◀ Teclado y ratón ▶":
		_fail("TEST FAIL: profile_button text no uso display_name: '%s'" % prof_btn.text)
		menu.queue_free()
		return

	var got := {
		"profile": "",
		"resume": false,
		"restart": false
	}
	menu.profile_changed.connect(func(name: String): got["profile"] = name)
	menu.resume_requested.connect(func(): got["resume"] = true)
	menu.restart_requested.connect(func(): got["restart"] = true)

	# Probar cambio de perfil
	if menu.has_method("cycle_profile"):
		menu.cycle_profile(1)
		if str(got["profile"]).is_empty():
			_fail("TEST FAIL: cycle_profile no emitio profile_changed")
			menu.queue_free()
			return

	# Probar botones directos si existen
	var resume_btn = menu.get_node_or_null("ResumeButton")
	if resume_btn == null:
		resume_btn = menu.find_child("*Resume*", true, false)
	if resume_btn != null:
		resume_btn.emit_signal("pressed")
		if not got["resume"]:
			_fail("TEST FAIL: ResumeButton no emitio resume_requested")
			menu.queue_free()
			return

	var restart_btn = menu.get_node_or_null("RestartButton")
	if restart_btn == null:
		restart_btn = menu.find_child("*Restart*", true, false)
	if restart_btn != null:
		restart_btn.emit_signal("pressed")
		if not got["restart"]:
			_fail("TEST FAIL: RestartButton no emitio restart_requested")
			menu.queue_free()
			return

	menu.queue_free()
	print("TEST PASS: settings_menu unitario verificado")
	finish(0)
