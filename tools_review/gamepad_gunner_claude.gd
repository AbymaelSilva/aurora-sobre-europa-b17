extends SceneTree
# Revisión lote 3 (Claude): artillero con mando en DEMO y cadencia de RB mantenido, por Input real.
var scene: Node
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func axis(a: JoyAxis, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func button(b: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func check(cond: bool, label: String) -> void:
	print(("OK   " if cond else "FAIL ") + label)
	if not cond:
		failures += 1

func run() -> void:
	scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	var c = scene.controls
	var sim = scene.sim
	var dt := 1.0 / 60.0
	sim.autopilot = true
	c.set_station("ARTILLERO", sim)

	for prof in ["XBOX", "TECLADO_RATON"]:
		c.profile = prof
		c.aim = Vector2.ZERO
		axis(JOY_AXIS_RIGHT_X, 1.0)
		for i in range(30):
			c.poll_inputs(sim, dt)
		axis(JOY_AXIS_RIGHT_X, 0.0)
		if prof == "XBOX":
			check(absf(c.aim.x) > 0.5, "XBOX en demo: el stick derecho apunta (aim.x=%.2f)" % c.aim.x)
		else:
			check(is_zero_approx(c.aim.x), "TECLADO_RATON: el stick derecho se ignora (aim.x=%.2f)" % c.aim.x)

	c.profile = "XBOX"
	var shots := 0
	button(JOY_BUTTON_RIGHT_SHOULDER, true)
	for i in range(60):
		sim.combat.defensive_shots.clear()
		c.poll_inputs(sim, dt)
		shots += sim.combat.defensive_shots.size()
	button(JOY_BUTTON_RIGHT_SHOULDER, false)
	check(shots >= 7 and shots <= 10, "RB mantenido 1 s: %d disparos (esperado ≈8 con recarga 0.12 s, antes 60)" % shots)

	print("RESULTADO: %d fallos" % failures)
	root.remove_child(scene)
	scene.free()
	for i in range(4):
		await process_frame
	quit(1 if failures > 0 else 0)
