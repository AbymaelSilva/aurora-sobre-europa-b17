extends SceneTree

# Test unitario para core/input_profile.gd

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
		DirAccess.remove_absolute(SETTINGS_FILE_PATH)

	var InputProfileScript = load("res://core/input_profile.gd")
	if InputProfileScript == null:
		_fail("TEST FAIL: no se pudo cargar res://core/input_profile.gd")
		return

	# Comprobar constantes
	if not "PROFILES" in InputProfileScript:
		_fail("TEST FAIL: PROFILES no esta definido en InputProfile")
		return

	var profiles: Array = InputProfileScript.PROFILES
	if not ("TECLADO_RATON" in profiles and "XBOX" in profiles and "ROG_ALLY_X" in profiles):
		_fail("TEST FAIL: PROFILES debe contener TECLADO_RATON, XBOX y ROG_ALLY_X")
		return

	# Limpiar config anterior
	var settings_path := SETTINGS_FILE_PATH
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)

	# 1. Defecto TECLADO_RATON
	if InputProfileScript.load_profile() != "TECLADO_RATON":
		_fail("TEST FAIL: load_profile() sin archivo no devolvio TECLADO_RATON")
		return

	# 2. Guardar y cargar
	InputProfileScript.save_profile("XBOX")
	if InputProfileScript.load_profile() != "XBOX":
		_fail("TEST FAIL: load_profile() tras save_profile('XBOX') no devolvio XBOX")
		return

	InputProfileScript.save_profile("ROG_ALLY_X")
	if InputProfileScript.load_profile() != "ROG_ALLY_X":
		_fail("TEST FAIL: load_profile() tras save_profile('ROG_ALLY_X') no devolvio ROG_ALLY_X")
		return

	# Valor invalido vuelve a TECLADO_RATON
	var cfg := ConfigFile.new()
	cfg.load(settings_path)
	cfg.set_value("controles", "perfil", "DESCONOCIDO")
	cfg.save(settings_path)
	if InputProfileScript.load_profile() != "TECLADO_RATON":
		_fail("TEST FAIL: valor invalido no devolvio TECLADO_RATON")
		return

	# 3. suggest_profile
	if InputProfileScript.suggest_profile([]) != "TECLADO_RATON":
		_fail("TEST FAIL: suggest_profile([]) debe devolver TECLADO_RATON")
		return
	if InputProfileScript.suggest_profile(["Xbox Wireless Controller"]) != "XBOX":
		_fail("TEST FAIL: suggest_profile con Xbox debe devolver XBOX")
		return
	if InputProfileScript.suggest_profile(["Generic Gamepad"]) != "XBOX":
		_fail("TEST FAIL: suggest_profile con generico debe devolver XBOX")
		return
	if InputProfileScript.suggest_profile(["ASUS ROG Ally X"]) != "ROG_ALLY_X":
		_fail("TEST FAIL: suggest_profile con ASUS ROG Ally X debe devolver ROG_ALLY_X")
		return
	if InputProfileScript.suggest_profile(["rog ally"]) != "ROG_ALLY_X":
		_fail("TEST FAIL: suggest_profile con 'rog ally' debe devolver ROG_ALLY_X")
		return
	if InputProfileScript.suggest_profile(["asus controller"]) != "ROG_ALLY_X":
		_fail("TEST FAIL: suggest_profile con 'asus' debe devolver ROG_ALLY_X")
		return

	# 4. prompt
	var actions := [
		"soltar", "disparar", "pausa", "reiniciar", "autopiloto",
		"piloto", "artillero", "bombardero", "aceptar", "volver", "puestos"
	]
	for p in profiles:
		for a in actions:
			var txt: String = InputProfileScript.prompt(a, p)
			if txt.is_empty():
				_fail("TEST FAIL: prompt('%s', '%s') devolvio texto vacio" % [a, p])
				return

	if InputProfileScript.prompt("soltar", "TECLADO_RATON") == InputProfileScript.prompt("soltar", "XBOX"):
		_fail("TEST FAIL: prompt soltar debe diferir entre TECLADO_RATON y XBOX")
		return

	if InputProfileScript.prompt("pausa", "TECLADO_RATON") == InputProfileScript.prompt("pausa", "XBOX"):
		_fail("TEST FAIL: prompt pausa debe diferir entre TECLADO_RATON y XBOX")
		return

	var ally_pause: String = InputProfileScript.prompt("pausa", "ROG_ALLY_X")
	if not ally_pause.contains("Menú") and not ally_pause.contains("Menu"):
		_fail("TEST FAIL: prompt pausa ROG_ALLY_X debe contener 'Menú'")
		return

	var ally_auto: String = InputProfileScript.prompt("autopiloto", "ROG_ALLY_X")
	if not ally_auto.contains("Vista"):
		_fail("TEST FAIL: prompt autopiloto ROG_ALLY_X debe contener 'Vista'")
		return

	var ally_soltar: String = InputProfileScript.prompt("soltar", "ROG_ALLY_X")
	if not ally_soltar.contains("A"):
		_fail("TEST FAIL: prompt soltar ROG_ALLY_X debe contener 'A'")
		return

	if InputProfileScript.prompt("puestos", "TECLADO_RATON") != "1/2/3":
		_fail("TEST FAIL: prompt puestos TECLADO_RATON debe ser '1/2/3'")
		return

	if InputProfileScript.prompt("puestos", "XBOX") != "Cruceta":
		_fail("TEST FAIL: prompt puestos XBOX debe ser 'Cruceta'")
		return

	if InputProfileScript.prompt("puestos", "ROG_ALLY_X") != "Cruceta":
		_fail("TEST FAIL: prompt puestos ROG_ALLY_X debe ser 'Cruceta'")
		return

	# 5. display_name y flechas cruceta
	if not InputProfileScript.has_method("display_name"):
		_fail("TEST FAIL: display_name no existe en InputProfile")
		return
	if InputProfileScript.display_name("TECLADO_RATON") != "Teclado y ratón":
		_fail("TEST FAIL: display_name TECLADO_RATON debe ser 'Teclado y ratón'")
		return
	if InputProfileScript.display_name("XBOX") != "Mando Xbox":
		_fail("TEST FAIL: display_name XBOX debe ser 'Mando Xbox'")
		return
	if InputProfileScript.display_name("ROG_ALLY_X") != "ROG Ally X":
		_fail("TEST FAIL: display_name ROG_ALLY_X debe ser 'ROG Ally X'")
		return

	if InputProfileScript.prompt("piloto", "XBOX") != "Cruceta ↑":
		_fail("TEST FAIL: prompt piloto XBOX debe ser 'Cruceta ↑'")
		return
	if InputProfileScript.prompt("artillero", "XBOX") != "Cruceta →":
		_fail("TEST FAIL: prompt artillero XBOX debe ser 'Cruceta →'")
		return
	if InputProfileScript.prompt("bombardero", "XBOX") != "Cruceta ↓":
		_fail("TEST FAIL: prompt bombardero XBOX debe ser 'Cruceta ↓'")
		return
	if InputProfileScript.prompt("piloto", "ROG_ALLY_X") != "Cruceta ↑":
		_fail("TEST FAIL: prompt piloto ROG_ALLY_X debe ser 'Cruceta ↑'")
		return
	if InputProfileScript.prompt("artillero", "ROG_ALLY_X") != "Cruceta →":
		_fail("TEST FAIL: prompt artillero ROG_ALLY_X debe ser 'Cruceta →'")
		return
	if InputProfileScript.prompt("bombardero", "ROG_ALLY_X") != "Cruceta ↓":
		_fail("TEST FAIL: prompt bombardero ROG_ALLY_X debe ser 'Cruceta ↓'")
		return

	print("TEST PASS: input_profile unitario verificado")
	finish(0)
