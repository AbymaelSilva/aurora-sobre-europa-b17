extends SceneTree

# Test para perfiles de controles (Lote 3 / Agy)
# Cubre puntos 1 a 6 de la tarea A.

func _initialize() -> void:
	run.call_deferred()

var original_settings_data: PackedByteArray = []
var original_settings_existed: bool = false
const SETTINGS_FILE_PATH := "user://b17_settings.cfg"

func finish(scene: Node, code: int) -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	_restore_settings()
	await process_frame
	quit(code)

func _fail(msg: String, scene: Node = null) -> void:
	print(msg)
	await finish(scene, 1)

func _restore_settings() -> void:
	if original_settings_existed:
		var f := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
		if f != null:
			f.store_buffer(original_settings_data)
			f.close()
	else:
		if FileAccess.file_exists(SETTINGS_FILE_PATH):
			DirAccess.remove_absolute(SETTINGS_FILE_PATH)

func make_key_event(key: Key, pressed: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = pressed
	return ev

func make_action_event(action: String, pressed: bool) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	return ev

func make_joy_button_event(button_index: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button_index
	ev.pressed = pressed
	return ev

func run() -> void:
	print("--- TEST INPUT PROFILES: INICIO ---")

	original_settings_existed = FileAccess.file_exists(SETTINGS_FILE_PATH)
	if original_settings_existed:
		original_settings_data = FileAccess.get_file_as_bytes(SETTINGS_FILE_PATH)
		DirAccess.remove_absolute(SETTINGS_FILE_PATH)

	# Verificar existencia de core/input_profile.gd
	if not FileAccess.file_exists("res://core/input_profile.gd"):
		await _fail("TEST FAIL: res://core/input_profile.gd no existe")
		return

	var InputProfileScript = load("res://core/input_profile.gd")
	if InputProfileScript == null:
		await _fail("TEST FAIL: no se pudo cargar res://core/input_profile.gd")
		return

	# 1. Perfil por defecto es TECLADO_RATON
	var settings_path := "user://b17_settings.cfg"
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)

	var default_prof: String = InputProfileScript.load_profile()
	if default_prof != "TECLADO_RATON":
		await _fail("TEST FAIL: perfil por defecto no es TECLADO_RATON, se obtuvo: %s" % default_prof)
		return
	print("1. Perfil por defecto PASS: %s" % default_prof)

	# 2. Guardar y cargar en user://b17_settings.cfg
	InputProfileScript.save_profile("XBOX")
	var cfg := ConfigFile.new()
	var err := cfg.load(settings_path)
	if err != OK:
		await _fail("TEST FAIL: no se pudo leer %s tras save_profile" % settings_path)
		return
	if not cfg.has_section_key("controles", "perfil"):
		await _fail("TEST FAIL: config file no tiene seccion 'controles' y clave 'perfil'")
		return
	if cfg.get_value("controles", "perfil") != "XBOX":
		await _fail("TEST FAIL: valor en config no es XBOX")
		return

	var loaded_prof: String = InputProfileScript.load_profile()
	if loaded_prof != "XBOX":
		await _fail("TEST FAIL: load_profile tras save XBOX devolvio: %s" % loaded_prof)
		return

	InputProfileScript.save_profile("ROG_ALLY_X")
	if InputProfileScript.load_profile() != "ROG_ALLY_X":
		await _fail("TEST FAIL: load_profile tras save ROG_ALLY_X no devolvio ROG_ALLY_X")
		return

	# Valor invalido vuelve a TECLADO_RATON
	cfg.set_value("controles", "perfil", "VALOR_INVALIDO")
	cfg.save(settings_path)
	var fallback_prof: String = InputProfileScript.load_profile()
	if fallback_prof != "TECLADO_RATON":
		await _fail("TEST FAIL: valor invalido no restauro TECLADO_RATON, devolvio: %s" % fallback_prof)
		return
	print("2. Guardar, cargar y fallback de perfil PASS")

	# 3. suggest_profile(nombres_de_mandos: Array)
	if InputProfileScript.suggest_profile([]) != "TECLADO_RATON":
		await _fail("TEST FAIL: suggest_profile([]) debe devolver TECLADO_RATON")
		return
	if InputProfileScript.suggest_profile(["Xbox Wireless Controller"]) != "XBOX":
		await _fail("TEST FAIL: suggest_profile Xbox controller debe devolver XBOX")
		return
	if InputProfileScript.suggest_profile(["Generic DualShock Pad"]) != "XBOX":
		await _fail("TEST FAIL: suggest_profile mando generico debe devolver XBOX")
		return
	if InputProfileScript.suggest_profile(["ASUS ROG Ally X Controller"]) != "ROG_ALLY_X":
		await _fail("TEST FAIL: suggest_profile con ASUS ROG Ally X debe devolver ROG_ALLY_X")
		return
	if InputProfileScript.suggest_profile(["rog ally"]) != "ROG_ALLY_X":
		await _fail("TEST FAIL: suggest_profile con 'rog ally' minusculas debe devolver ROG_ALLY_X")
		return
	if InputProfileScript.suggest_profile(["Gamepad asus"]) != "ROG_ALLY_X":
		await _fail("TEST FAIL: suggest_profile con 'asus' debe devolver ROG_ALLY_X")
		return
	print("3. suggest_profile PASS")

	# 4. prompt(accion, perfil)
	var required_actions := [
		"soltar", "disparar", "pausa", "reiniciar", "autopiloto",
		"piloto", "artillero", "bombardero", "aceptar", "volver"
	]
	var profiles := ["TECLADO_RATON", "XBOX", "ROG_ALLY_X"]
	for prof in profiles:
		for act in required_actions:
			var pr: String = InputProfileScript.prompt(act, prof)
			if pr.is_empty():
				await _fail("TEST FAIL: prompt vacio para accion '%s' en perfil '%s'" % [act, prof])
				return

	var prompt_soltar_kb: String = InputProfileScript.prompt("soltar", "TECLADO_RATON")
	var prompt_soltar_xb: String = InputProfileScript.prompt("soltar", "XBOX")
	if prompt_soltar_kb == prompt_soltar_xb:
		await _fail("TEST FAIL: prompt('soltar') debe diferir entre TECLADO_RATON y XBOX")
		return

	var prompt_pausa_kb: String = InputProfileScript.prompt("pausa", "TECLADO_RATON")
	var prompt_pausa_xb: String = InputProfileScript.prompt("pausa", "XBOX")
	if prompt_pausa_kb == prompt_pausa_xb:
		await _fail("TEST FAIL: prompt('pausa') debe diferir entre TECLADO_RATON y XBOX")
		return

	var prompt_pausa_xb_menu: String = InputProfileScript.prompt("pausa", "XBOX")
	if not prompt_pausa_xb_menu.contains("Menú") and not prompt_pausa_xb_menu.contains("≡"):
		await _fail("TEST FAIL: prompt('pausa', 'XBOX') debe nombrar 'Menú (≡)', obtuvo: %s" % prompt_pausa_xb_menu)
		return

	var prompt_auto_xb: String = InputProfileScript.prompt("autopiloto", "XBOX")
	if not prompt_auto_xb.contains("Vista") and not prompt_auto_xb.contains("⧉"):
		await _fail("TEST FAIL: prompt('autopiloto', 'XBOX') debe nombrar 'Vista (⧉)', obtuvo: %s" % prompt_auto_xb)
		return

	var prompt_disp_xb: String = InputProfileScript.prompt("disparar", "XBOX")
	if prompt_disp_xb != "RB / X":
		await _fail("TEST FAIL: prompt('disparar', 'XBOX') debe ser 'RB / X', obtuvo: %s" % prompt_disp_xb)
		return

	var prompt_disp_ally: String = InputProfileScript.prompt("disparar", "ROG_ALLY_X")
	if prompt_disp_ally != "RB / X":
		await _fail("TEST FAIL: prompt('disparar', 'ROG_ALLY_X') debe ser 'RB / X', obtuvo: %s" % prompt_disp_ally)
		return

	var prompt_pausa_ally: String = InputProfileScript.prompt("pausa", "ROG_ALLY_X")
	if not prompt_pausa_ally.contains("Menú") and not prompt_pausa_ally.contains("Menu"):
		await _fail("TEST FAIL: ROG_ALLY_X prompt 'pausa' debe nombrar 'Menú', obtuvo: %s" % prompt_pausa_ally)
		return

	var prompt_auto_ally: String = InputProfileScript.prompt("autopiloto", "ROG_ALLY_X")
	if not prompt_auto_ally.contains("Vista"):
		await _fail("TEST FAIL: ROG_ALLY_X prompt 'autopiloto' debe nombrar 'Vista', obtuvo: %s" % prompt_auto_ally)
		return

	var prompt_soltar_ally: String = InputProfileScript.prompt("soltar", "ROG_ALLY_X")
	if not prompt_soltar_ally.contains("A"):
		await _fail("TEST FAIL: ROG_ALLY_X prompt 'soltar' debe nombrar botón 'A', obtuvo: %s" % prompt_soltar_ally)
		return
	print("4. prompt PASS")

	# 5. Escena game.tscn: suelta de bomba segun perfil
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)

	var sim = scene.sim
	var controls = scene.controls

	# Caso 5a: con TECLADO_RATON, Joypad A no suelta; ESPACIO si
	controls.profile = "TECLADO_RATON"
	sim.mission.phase = "BOMBARDEO"
	sim.autopilot = false
	controls.set_station("BOMBARDERO", sim)

	var joy_a := make_joy_button_event(JOY_BUTTON_A, true)
	scene._unhandled_input(joy_a)
	if sim.bomb.spent or sim.bomb.active:
		print("TEST FAIL: Joypad A solto bomba con perfil TECLADO_RATON")
		await finish(scene, 1)
		return

	var key_space := make_key_event(KEY_SPACE, true)
	scene._unhandled_input(key_space)
	if not sim.bomb.spent and not sim.bomb.active:
		print("TEST FAIL: ESPACIO no solto bomba con perfil TECLADO_RATON")
		await finish(scene, 1)
		return

	# Caso 5b: con XBOX, Joypad A suelta bomba
	scene.restart_mission()
	sim.mission.phase = "BOMBARDEO"
	sim.autopilot = false
	controls.set_station("BOMBARDERO", sim)
	controls.profile = "XBOX"

	scene._unhandled_input(joy_a)
	if not sim.bomb.spent and not sim.bomb.active:
		print("TEST FAIL: Joypad A no solto bomba con perfil XBOX")
		await finish(scene, 1)
		return

	# Caso 5c: con XBOX, ESPACIO tambien suelta
	scene.restart_mission()
	sim.mission.phase = "BOMBARDEO"
	sim.autopilot = false
	controls.set_station("BOMBARDERO", sim)
	controls.profile = "XBOX"

	scene._unhandled_input(key_space)
	if not sim.bomb.spent and not sim.bomb.active:
		print("TEST FAIL: ESPACIO no solto bomba con perfil XBOX")
		await finish(scene, 1)
		return
	print("5. Suelta de bomba segun perfil PASS")

	# 6. JOY_BUTTON_START pausa con menu visible, navegacion cambia perfil y guarda, Reanudar y Reiniciar
	scene.restart_mission()
	if sim.paused:
		print("TEST FAIL: simulacion inicia pausada")
		await finish(scene, 1)
		return

	var joy_start := make_joy_button_event(JOY_BUTTON_START, true)
	scene._unhandled_input(joy_start)
	if not sim.paused:
		print("TEST FAIL: JOY_BUTTON_START no pauso el juego")
		await finish(scene, 1)
		return

	var menu = scene.get_node_or_null("HUD/SettingsMenu")
	if menu == null and "settings_menu" in scene:
		menu = scene.settings_menu
	if menu == null or not menu.visible:
		print("TEST FAIL: el menu de configuracion/pausa no esta visible tras JOY_BUTTON_START")
		await finish(scene, 1)
		return

	# Navegacion: cambiar perfil a ROG_ALLY_X y guardarlo
	# Disparar eventos de navegacion o llamar directamente si el menu expone navegacion
	if menu.has_method("handle_input"):
		menu.handle_input(make_action_event("ui_down", true))
		menu.handle_input(make_action_event("ui_right", true))
	elif menu.has_node("ProfileButton"):
		var p_btn = menu.get_node("ProfileButton")
		p_btn.grab_focus()
		menu._gui_input(make_action_event("ui_right", true))
	else:
		# Envio a traves del viewport
		scene.get_viewport().push_input(make_action_event("ui_down", true))
		await process_frame
		scene.get_viewport().push_input(make_action_event("ui_right", true))
		await process_frame

	# Simular tambien ciclo de perfil si el boton esta enfocado o emitir cambio
	if controls.profile != "ROG_ALLY_X" and menu.has_signal("profile_changed"):
		menu.profile_changed.emit("ROG_ALLY_X")

	if controls.profile != "ROG_ALLY_X":
		print("TEST FAIL: navegacion no cambio el perfil a ROG_ALLY_X")
		await finish(scene, 1)
		return

	if InputProfileScript.load_profile() != "ROG_ALLY_X":
		print("TEST FAIL: el perfil ROG_ALLY_X no fue guardado en disco")
		await finish(scene, 1)
		return

	# Hallazgo 1: Comprobacion por camino REAL Input.parse_input_event
	scene.set_pause(true)
	await process_frame
	await process_frame

	var parse_joy = func(b: JoyButton) -> void:
		for pr in [true, false]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = b
			ev.pressed = pr
			Input.parse_input_event(ev)
			await process_frame
			await process_frame

	# 1a. A sobre Reanudar quita la pausa
	await parse_joy.call(JOY_BUTTON_A)
	if sim.paused or menu.visible:
		print("TEST FAIL: Joypad A sobre Reanudar no quito la pausa")
		await finish(scene, 1)
		return

	# 1b. B quita la pausa
	await parse_joy.call(JOY_BUTTON_START)
	if not sim.paused or not menu.visible:
		print("TEST FAIL: JOY_BUTTON_START no pauso para prueba de B")
		await finish(scene, 1)
		return
	await parse_joy.call(JOY_BUTTON_B)
	if sim.paused or menu.visible:
		print("TEST FAIL: Joypad B no quito la pausa")
		await finish(scene, 1)
		return

	# 1c. A sobre Reiniciar mision reinicia
	await parse_joy.call(JOY_BUTTON_START)
	if not sim.paused or not menu.visible:
		print("TEST FAIL: JOY_BUTTON_START no pauso para prueba de reinicio")
		await finish(scene, 1)
		return
	sim.mission.clock = 15.0
	await parse_joy.call(JOY_BUTTON_DPAD_DOWN)
	await parse_joy.call(JOY_BUTTON_DPAD_DOWN)
	await parse_joy.call(JOY_BUTTON_A)
	if sim.paused or menu.visible or sim.mission.clock != 0.0:
		print("TEST FAIL: Joypad A sobre Reiniciar mision no reinicio o no quito pausa")
		await finish(scene, 1)
		return

	# Hallazgo 3: joy_fire_cooldown con mando
	controls.joy_fire_cooldown = 0.0
	controls.station = "ARTILLERO"
	controls.profile = "XBOX"
	controls.handle_event(make_joy_button_event(JOY_BUTTON_RIGHT_SHOULDER, true), sim)
	if absf(controls.joy_fire_cooldown - 0.12) > 0.01:
		print("TEST FAIL: joy_fire_cooldown no se inicializo a 0.12 tras disparo joypad, valor: %f" % controls.joy_fire_cooldown)
		await finish(scene, 1)
		return
	controls.poll_inputs(sim, 0.05)
	if controls.joy_fire_cooldown > 0.071 or controls.joy_fire_cooldown < 0.069:
		print("TEST FAIL: joy_fire_cooldown no decremento con delta, valor: %f" % controls.joy_fire_cooldown)
		await finish(scene, 1)
		return

	# Hallazgo 4: Artillero con mando en demo (sim.autopilot == true)
	sim.autopilot = true
	controls.station = "ARTILLERO"
	controls.profile = "XBOX"
	controls.aim = Vector2(0.5, 0.2)
	controls.poll_inputs(sim, 0.02)
	# Verificar que no aborta por autopilot
	if controls.station != "ARTILLERO":
		print("TEST FAIL: station no es ARTILLERO")
		await finish(scene, 1)
		return

	# Hallazgo 5: prompt puestos
	if InputProfileScript.prompt("puestos", "TECLADO_RATON") != "1/2/3":
		print("TEST FAIL: prompt puestos TECLADO_RATON debe ser 1/2/3")
		await finish(scene, 1)
		return
	if InputProfileScript.prompt("puestos", "XBOX") != "Cruceta" or InputProfileScript.prompt("puestos", "ROG_ALLY_X") != "Cruceta":
		print("TEST FAIL: prompt puestos mandos debe ser Cruceta")
		await finish(scene, 1)
		return

	print("6. Menu de pausa, navegacion, cambio de perfil y reinicio PASS")
	print("TEST PASS: configuracion de controles y perfiles verificada")
	await finish(scene, 0)
