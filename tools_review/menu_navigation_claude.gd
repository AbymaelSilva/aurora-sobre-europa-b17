extends SceneTree
# Revisión lote 3 (Claude): navegación del menú por el camino REAL de entrada de Godot
# (Input.parse_input_event → Viewport/GUI → _unhandled_input), sin llamar a handle_input.
# Comprueba que cada pulsación mueve el foco UNA opción y cambia el perfil UNA vez.
var scene: Node
var log_lines: PackedStringArray = []
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func key(k: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = pressed
		Input.parse_input_event(e)
		await process_frame
		await process_frame

func joy(b: JoyButton) -> void:
	for pressed in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		e.pressed = pressed
		Input.parse_input_event(e)
		await process_frame
		await process_frame

func focus_name() -> String:
	var f := root.gui_get_focus_owner()
	return f.name if f != null else "<ninguno>"

func check(cond: bool, label: String) -> void:
	log_lines.append(("OK   " if cond else "FAIL ") + label + " | foco=" + focus_name() + " perfil=" + scene.controls.profile + " pausa=" + str(scene.sim.paused))
	if not cond:
		failures += 1

func run() -> void:
	scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	for i in range(5):
		await process_frame
	scene.set_physics_process(false)
	scene.controls.profile = "TECLADO_RATON"
	var menu: Control = scene.settings_menu

	# Teclado
	await key(KEY_ESCAPE)
	check(scene.sim.paused and menu.visible, "ESC abre la pausa con el menú")
	var f0 := focus_name()
	await key(KEY_DOWN)
	var f1 := focus_name()
	check(f1 != f0, "↓ mueve el foco (de %s a %s)" % [f0, f1])
	await key(KEY_DOWN)
	var f2 := focus_name()
	check(f2 != f1, "segundo ↓ mueve el foco (a %s)" % f2)
	await key(KEY_UP)
	check(focus_name() == f1, "↑ vuelve exactamente una opción (esperado %s)" % f1)
	var p0: String = scene.controls.profile
	await key(KEY_RIGHT)
	var p1: String = scene.controls.profile
	var i0 := Array(["TECLADO_RATON", "XBOX", "ROG_ALLY_X"]).find(p0)
	check(p1 == ["TECLADO_RATON", "XBOX", "ROG_ALLY_X"][(i0 + 1) % 3], "→ avanza el perfil exactamente uno (%s → %s)" % [p0, p1])
	await key(KEY_LEFT)
	check(scene.controls.profile == p0, "← retrocede exactamente uno (a %s)" % p0)
	await key(KEY_ESCAPE)
	check(not scene.sim.paused and not menu.visible, "ESC cierra la pausa y el menú")

	# Mando con perfil XBOX
	scene.controls.profile = "XBOX"
	await joy(JOY_BUTTON_START)
	check(scene.sim.paused and menu.visible, "Menú (START) abre la pausa")
	var g0 := focus_name()
	await joy(JOY_BUTTON_DPAD_DOWN)
	var g1 := focus_name()
	check(g1 != g0, "cruceta ↓ mueve el foco (a %s)" % g1)
	await joy(JOY_BUTTON_DPAD_UP)
	check(focus_name() == g0, "cruceta ↑ vuelve una opción (a %s)" % g0)
	await joy(JOY_BUTTON_A)
	check(not scene.sim.paused and not menu.visible, "A sobre Reanudar quita la pausa")
	await joy(JOY_BUTTON_START)
	await joy(JOY_BUTTON_B)
	check(not scene.sim.paused, "B (volver) quita la pausa")
	if scene.sim.paused:
		await joy(JOY_BUTTON_START)

	for l in log_lines:
		print(l)
	print("RESULTADO: %d fallos" % failures)
	root.remove_child(scene)
	scene.free()
	for i in range(4):
		await process_frame
	quit(1 if failures > 0 else 0)
