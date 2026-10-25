extends SceneTree

const InputProfile = preload("res://core/input_profile.gd")

var root_control: Control
var display_label: Label
var exit_hold_timer: float = 0.0

func _initialize() -> void:
	run_app.call_deferred()

func run_app() -> void:
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(root_control)

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.11, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(bg)

	display_label = Label.new()
	display_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display_label.offset_left = 40
	display_label.offset_top = 40
	display_label.offset_right = -40
	display_label.offset_bottom = -40
	display_label.add_theme_font_size_override("font_size", 20)
	display_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.95))
	root_control.add_child(display_label)

	while true:
		if DisplayServer.get_name() == "headless":
			var dev_state := poll_state(exit_hold_timer)
			print(describe(dev_state))
			quit(0)
			return

		if Input.is_key_pressed(KEY_ESCAPE):
			quit(0)
			return

		var vista_pressed: bool = Input.is_joy_button_pressed(0, JOY_BUTTON_BACK) or Input.is_joy_button_pressed(0, JOY_BUTTON_MISC1)
		var menu_pressed: bool = Input.is_joy_button_pressed(0, JOY_BUTTON_START)
		if vista_pressed and menu_pressed:
			exit_hold_timer += 1.0 / 60.0
			if exit_hold_timer >= 2.0:
				quit(0)
				return
		else:
			exit_hold_timer = 0.0

		var state := poll_state(exit_hold_timer)
		display_label.text = describe(state)

		await process_frame

static func poll_state(hold_time: float = 0.0) -> Dictionary:
	var joy_ids: Array = Input.get_connected_joypads()
	var devices: Array = []
	var joy_names: Array = []
	for jid in joy_ids:
		var jname: String = Input.get_joy_name(jid)
		var jguid: String = Input.get_joy_guid(jid)
		joy_names.append(jname)
		devices.append({"id": jid, "name": jname, "guid": jguid})

	var suggested: String = InputProfile.suggest_profile(joy_names)
	var axes: Dictionary = {
		"LX": 0.0,
		"LY": 0.0,
		"RX": 0.0,
		"RY": 0.0,
		"LT": 0.0,
		"RT": 0.0
	}
	var pressed: Array = []
	if not joy_ids.is_empty():
		var pid: int = joy_ids[0]
		axes["LX"] = Input.get_joy_axis(pid, JOY_AXIS_LEFT_X)
		axes["LY"] = Input.get_joy_axis(pid, JOY_AXIS_LEFT_Y)
		axes["RX"] = Input.get_joy_axis(pid, JOY_AXIS_RIGHT_X)
		axes["RY"] = Input.get_joy_axis(pid, JOY_AXIS_RIGHT_Y)
		axes["LT"] = Input.get_joy_axis(pid, JOY_AXIS_TRIGGER_LEFT)
		axes["RT"] = Input.get_joy_axis(pid, JOY_AXIS_TRIGGER_RIGHT)
		for b in [
			JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y,
			JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER,
			JOY_BUTTON_BACK, JOY_BUTTON_START,
			JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK,
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT,
			JOY_BUTTON_MISC1
		]:
			if Input.is_joy_button_pressed(pid, b):
				pressed.append(b)

	return {
		"devices": devices,
		"suggested_profile": suggested,
		"axes": axes,
		"buttons_pressed": pressed,
		"exit_hold_time": hold_time
	}

static func get_button_name(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_BACK: return "Vista"
		JOY_BUTTON_START: return "Menú"
		JOY_BUTTON_LEFT_STICK: return "Stick Izquierdo (L3)"
		JOY_BUTTON_RIGHT_STICK: return "Stick Derecho (R3)"
		JOY_BUTTON_DPAD_UP: return "Cruceta ↑"
		JOY_BUTTON_DPAD_DOWN: return "Cruceta ↓"
		JOY_BUTTON_DPAD_LEFT: return "Cruceta ←"
		JOY_BUTTON_DPAD_RIGHT: return "Cruceta →"
		JOY_BUTTON_MISC1: return "Vista"
		_: return "Botón %d" % button_index

static func get_button_action(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "Soltar bomba · Disparar (artillero) · Aceptar en menú"
		JOY_BUTTON_B: return "Soltar bomba · Disparar (artillero) · Volver en menú"
		JOY_BUTTON_X: return "Disparar"
		JOY_BUTTON_Y: return "Sin asignar"
		JOY_BUTTON_BACK, JOY_BUTTON_MISC1: return "Autopiloto ON/OFF"
		JOY_BUTTON_START: return "Pausa / Menú"
		JOY_BUTTON_LEFT_SHOULDER: return "Sin asignar"
		JOY_BUTTON_RIGHT_SHOULDER: return "Disparar"
		JOY_BUTTON_LEFT_STICK: return "Sin asignar"
		JOY_BUTTON_RIGHT_STICK: return "Sin asignar"
		JOY_BUTTON_DPAD_UP: return "Puesto Piloto"
		JOY_BUTTON_DPAD_DOWN: return "Puesto Bombardero"
		JOY_BUTTON_DPAD_LEFT: return "Sin asignar"
		JOY_BUTTON_DPAD_RIGHT: return "Puesto Artillero"
		_: return "Sin asignar"

static func get_axis_name(axis_index: int) -> String:
	match axis_index:
		JOY_AXIS_LEFT_X: return "LX"
		JOY_AXIS_LEFT_Y: return "LY"
		JOY_AXIS_RIGHT_X: return "RX"
		JOY_AXIS_RIGHT_Y: return "RY"
		JOY_AXIS_TRIGGER_LEFT: return "LT"
		JOY_AXIS_TRIGGER_RIGHT: return "RT"
		_: return "Eje %d" % axis_index

static func describe(state: Dictionary) -> String:
	var devices: Array = state.get("devices", [])
	if devices.is_empty():
		return "=== DIAGNÓSTICO DE MANDO ===\n\nNo se detecta ningún mando: conéctalo por USB o Bluetooth.\n\nPulsa ESC para salir."

	var lines: Array[String] = []
	lines.append("=== DIAGNÓSTICO DE MANDO ===")
	lines.append("")
	lines.append("Mandos conectados (%d):" % devices.size())
	for dev in devices:
		lines.append("  [ID %s] %s (GUID: %s)" % [str(dev.get("id", 0)), str(dev.get("name", "")), str(dev.get("guid", ""))])

	var suggested: String = str(state.get("suggested_profile", "TECLADO_RATON"))
	var prof_name: String = InputProfile.display_name(suggested)
	lines.append("")
	lines.append("Perfil sugerido: %s (%s)" % [prof_name, suggested])

	var axes: Dictionary = state.get("axes", {})
	lines.append("")
	lines.append("Ejes analógicos:")
	lines.append("  LX: %+.2f   LY: %+.2f   RX: %+.2f   RY: %+.2f   LT: %+.2f   RT: %+.2f" % [
		float(axes.get("LX", 0.0)),
		float(axes.get("LY", 0.0)),
		float(axes.get("RX", 0.0)),
		float(axes.get("RY", 0.0)),
		float(axes.get("LT", 0.0)),
		float(axes.get("RT", 0.0))
	])

	var pressed: Array = state.get("buttons_pressed", [])
	lines.append("")
	lines.append("Botones pulsados:")
	if pressed.is_empty():
		lines.append("  (Ningún botón pulsado)")
	else:
		for btn in pressed:
			var b_idx: int = int(btn)
			lines.append("  %s → %s" % [get_button_name(b_idx), get_button_action(b_idx)])

	var hold: float = float(state.get("exit_hold_time", 0.0))
	lines.append("")
	if hold > 0.0:
		lines.append("Cerrar: Pulsa ESC o mantén Vista + Menú 2 s (Saliendo: %.1f s / 2.0 s)" % hold)
	else:
		lines.append("Cerrar: Pulsa ESC o mantén Vista + Menú 2 s")

	return "\n".join(lines)
