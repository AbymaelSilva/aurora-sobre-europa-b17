extends SceneTree

# Test headless para tools/probar_mando.gd

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var script = load("res://tools/probar_mando.gd")
	if script == null:
		print("TEST FAIL: no se pudo cargar res://tools/probar_mando.gd")
		quit(1)
		return

	# 1. Comprobacion de nombres de botones
	if script.get_button_name(JOY_BUTTON_A) != "A":
		print("TEST FAIL: get_button_name(JOY_BUTTON_A) no es 'A'")
		quit(1)
		return
	if script.get_button_name(JOY_BUTTON_B) != "B":
		print("TEST FAIL: get_button_name(JOY_BUTTON_B) no es 'B'")
		quit(1)
		return
	if script.get_button_name(JOY_BUTTON_X) != "X":
		print("TEST FAIL: get_button_name(JOY_BUTTON_X) no es 'X'")
		quit(1)
		return
	if script.get_button_name(JOY_BUTTON_Y) != "Y":
		print("TEST FAIL: get_button_name(JOY_BUTTON_Y) no es 'Y'")
		quit(1)
		return
	if script.get_button_name(JOY_BUTTON_LEFT_SHOULDER) != "LB":
		print("TEST FAIL: get_button_name(JOY_BUTTON_LEFT_SHOULDER) no es 'LB'")
		quit(1)
		return
	if script.get_button_name(JOY_BUTTON_RIGHT_SHOULDER) != "RB":
		print("TEST FAIL: get_button_name(JOY_BUTTON_RIGHT_SHOULDER) no es 'RB'")
		quit(1)
		return
	if not "Vista" in script.get_button_name(JOY_BUTTON_BACK):
		print("TEST FAIL: get_button_name(JOY_BUTTON_BACK) no contiene 'Vista'")
		quit(1)
		return
	if not "Menú" in script.get_button_name(JOY_BUTTON_START):
		print("TEST FAIL: get_button_name(JOY_BUTTON_START) no contiene 'Menú'")
		quit(1)
		return
	if not "Cruceta" in script.get_button_name(JOY_BUTTON_DPAD_UP):
		print("TEST FAIL: get_button_name(JOY_BUTTON_DPAD_UP) no contiene 'Cruceta'")
		quit(1)
		return
	if not "Stick" in script.get_button_name(JOY_BUTTON_LEFT_STICK):
		print("TEST FAIL: get_button_name(JOY_BUTTON_LEFT_STICK) no contiene 'Stick'")
		quit(1)
		return
	print("Nombres de botones PASS")

	# 2. Comprobacion de acciones de juego segun player_controls.gd
	var action_a: String = script.get_button_action(JOY_BUTTON_A)
	if not "Soltar bomba" in action_a and not "Aceptar" in action_a:
		print("TEST FAIL: accion de JOY_BUTTON_A no indica bomba o aceptar (%s)" % action_a)
		quit(1)
		return
	var action_rb: String = script.get_button_action(JOY_BUTTON_RIGHT_SHOULDER)
	if not "Disparar" in action_rb:
		print("TEST FAIL: accion de JOY_BUTTON_RIGHT_SHOULDER no indica Disparar (%s)" % action_rb)
		quit(1)
		return
	var action_dpad_down: String = script.get_button_action(JOY_BUTTON_DPAD_DOWN)
	if not "Bombardero" in action_dpad_down:
		print("TEST FAIL: accion de JOY_BUTTON_DPAD_DOWN no indica Bombardero (%s)" % action_dpad_down)
		quit(1)
		return
	var action_dpad_up: String = script.get_button_action(JOY_BUTTON_DPAD_UP)
	if not "Piloto" in action_dpad_up:
		print("TEST FAIL: accion de JOY_BUTTON_DPAD_UP no indica Piloto (%s)" % action_dpad_up)
		quit(1)
		return
	var action_dpad_right: String = script.get_button_action(JOY_BUTTON_DPAD_RIGHT)
	if not "Artillero" in action_dpad_right:
		print("TEST FAIL: accion de JOY_BUTTON_DPAD_RIGHT no indica Artillero (%s)" % action_dpad_right)
		quit(1)
		return
	print("Acciones de botones de juego PASS")

	# 3. Comprobacion de nombres de ejes
	if script.get_axis_name(JOY_AXIS_LEFT_X) != "LX":
		print("TEST FAIL: get_axis_name(JOY_AXIS_LEFT_X) no es 'LX'")
		quit(1)
		return
	if script.get_axis_name(JOY_AXIS_LEFT_Y) != "LY":
		print("TEST FAIL: get_axis_name(JOY_AXIS_LEFT_Y) no es 'LY'")
		quit(1)
		return
	if script.get_axis_name(JOY_AXIS_RIGHT_X) != "RX":
		print("TEST FAIL: get_axis_name(JOY_AXIS_RIGHT_X) no es 'RX'")
		quit(1)
		return
	if script.get_axis_name(JOY_AXIS_RIGHT_Y) != "RY":
		print("TEST FAIL: get_axis_name(JOY_AXIS_RIGHT_Y) no es 'RY'")
		quit(1)
		return
	if script.get_axis_name(JOY_AXIS_TRIGGER_LEFT) != "LT":
		print("TEST FAIL: get_axis_name(JOY_AXIS_TRIGGER_LEFT) no es 'LT'")
		quit(1)
		return
	if script.get_axis_name(JOY_AXIS_TRIGGER_RIGHT) != "RT":
		print("TEST FAIL: get_axis_name(JOY_AXIS_TRIGGER_RIGHT) no es 'RT'")
		quit(1)
		return
	print("Nombres de ejes PASS")

	# 4. Comprobacion de describe() con lista vacia (sin mando)
	var empty_state := {
		"devices": [],
		"suggested_profile": "TECLADO_RATON",
		"axes": {},
		"buttons_pressed": []
	}
	var empty_text: String = script.describe(empty_state)
	if not "No se detecta ningún mando: conéctalo por USB o Bluetooth" in empty_text:
		print("TEST FAIL: texto sin mando no contiene la cadena requerida ('%s')" % empty_text)
		quit(1)
		return
	print("describe() sin mando PASS")

	# 5. Comprobacion de describe() con mando falso Xbox
	var xbox_state := {
		"devices": [
			{"id": 0, "name": "Xbox Wireless Controller", "guid": "030000005e040000fd02000003090000"}
		],
		"suggested_profile": "XBOX",
		"axes": {
			"LX": -0.45,
			"LY": 0.88,
			"RX": 0.12,
			"RY": -0.34,
			"LT": 0.00,
			"RT": 0.75
		},
		"buttons_pressed": [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_DPAD_DOWN],
		"exit_hold_time": 0.5
	}
	var xbox_text: String = script.describe(xbox_state)
	if not "Xbox Wireless Controller" in xbox_text:
		print("TEST FAIL: descripcion no contiene nombre de mando Xbox")
		quit(1)
		return
	if not "030000005e040000fd02000003090000" in xbox_text:
		print("TEST FAIL: descripcion no contiene GUID de mando")
		quit(1)
		return
	if not "Mando Xbox" in xbox_text and not "XBOX" in xbox_text:
		print("TEST FAIL: descripcion no contiene perfil Xbox sugerido")
		quit(1)
		return
	if not "-0.45" in xbox_text or not "0.88" in xbox_text or not "0.75" in xbox_text:
		print("TEST FAIL: descripcion no formatea los ejes con 2 decimales")
		quit(1)
		return
	if not "A →" in xbox_text or not "RB →" in xbox_text or not "Cruceta ↓ →" in xbox_text:
		print("TEST FAIL: descripcion no incluye nombres y acciones de los botones pulsados ('%s')" % xbox_text)
		quit(1)
		return
	print("describe() con mando Xbox PASS")

	# 6. Comprobacion de describe() con mando falso ROG Ally X
	var ally_state := {
		"devices": [
			{"id": 0, "name": "ASUS ROG Ally X Controller", "guid": "03000000b00400000100000000000000"}
		],
		"suggested_profile": "ROG_ALLY_X",
		"axes": {
			"LX": 0.00,
			"LY": 0.00,
			"RX": 0.00,
			"RY": 0.00,
			"LT": 0.00,
			"RT": 0.00
		},
		"buttons_pressed": [],
		"exit_hold_time": 0.0
	}
	var ally_text: String = script.describe(ally_state)
	if not "ROG Ally X" in ally_text:
		print("TEST FAIL: descripcion no contiene sugerencia de perfil ROG Ally X")
		quit(1)
		return
	print("describe() con mando ROG Ally X PASS")

	print("TEST PASS: prueba de probar_mando verificada")
	quit(0)
