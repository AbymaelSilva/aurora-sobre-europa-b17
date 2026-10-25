extends SceneTree
# ¿Puede un jugador completar la misión sin piloto automático? Autor: Claude.
# Simula a un jugador: mantiene rumbo y altura pulsando W/S/A/D de verdad (Input.parse_input_event), como un teclado,
# ocupa el puesto de bombardero en la pasada y suelta la bomba él mismo con la tecla de suelta. Comprueba COMPLETADA.
# Es un jugador SINTÉTICO (eventos de teclado generados por la prueba), no una sesión de un jugador humano.

func _initialize() -> void:
	run.call_deferred()

func press(scene: Node, key: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		ev.keycode = key
		ev.pressed = pressed
		scene._unhandled_input(ev)

var held := {}

func hold(key: Key, on: bool) -> void:
	if held.get(key, false) == on:
		return
	held[key] = on
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = on
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	var sim = scene.sim
	var c = scene.controls
	press(scene, KEY_TAB)  # modo manual
	if sim.autopilot:
		print("TEST FAIL: TAB no desactiva el piloto automático")
		sim = null
		c = null
		await finish(scene, 1)
		return
	var dt := 1.0 / 60.0
	var released := false
	var turned := false
	for frame in range(60 * 1500):
		# "Jugador": apunta al objetivo de navegación y mantiene 1200 m.
		var offset: Vector3 = sim.mission.navigation_target() - sim.flight.position
		var desired_yaw: float = atan2(-offset.x, -offset.z)
		var err: float = wrapf(desired_yaw - sim.flight.yaw, -PI, PI)
		# Teclas tras H06: turn = A - D y yaw += turn, así que A sube el yaw (izquierda) y D lo baja (derecha).
		# err > 0 pide más yaw -> A; err < 0 -> D. W baja el morro, S lo sube.
		hold(KEY_A, err > deg_to_rad(2))
		hold(KEY_D, err < -deg_to_rad(2))
		hold(KEY_S, sim.flight.position.y < 1150.0)
		hold(KEY_W, sim.flight.position.y > 1250.0)
		if sim.mission.phase == "BOMBARDEO" and not released:
			if c.station != "BOMBARDERO":
				for k in [KEY_A, KEY_D, KEY_W, KEY_S]: hold(k, false)
				press(scene, KEY_3)
			var v: Vector3 = -Basis.from_euler(Vector3(sim.flight.pitch, sim.flight.yaw, 0)).z * sim.flight.speed
			var fall: float = (v.y + sqrt(v.y * v.y + 19.62 * sim.flight.position.y)) / 9.81
			var p: Vector3 = sim.flight.position + v * fall
			if Vector2(p.x, p.z).distance_to(Vector2(sim.mission.target.x, sim.mission.target.z)) < 40.0:
				press(scene, KEY_SPACE)
				press(scene, KEY_B)
				released = sim.bomb.spent
				if released:
					press(scene, KEY_1)  # el jugador vuelve a pilotar para el regreso
		scene._physics_process(dt)
		if absf(sim.turn_input) > 0.5 and c.station == "PILOTO": turned = true
		if sim.mission.phase in ["COMPLETADA", "FALLIDA"]:
			break
	print("giros_por_teclado=%s fase=%s bomba=%s suelta_manual=%s t=%.0fs casco=%.0f estacion=%s" % [str(turned), sim.mission.phase, sim.bomb.result, released, sim.mission.clock, sim.damage.hull, c.station])
	var ok: bool = sim.mission.phase == "COMPLETADA" and sim.bomb.result == "IMPACTO" and released and turned and not sim.autopilot and sim.damage.hull > 0.0
	sim = null
	c = null
	if ok:
		print("TEST PASS: misión completada por un jugador sintético en modo manual con suelta manual")
		await finish(scene, 0)
	else:
		print("TEST FAIL: el jugador no pudo completar la misión en manual")
		await finish(scene, 1)

# Limpieza antes de salir: suelta teclas, detiene audio, libera la escena y deja pasar ciclos para que no queden ObjectDB.
func finish(scene: Node, code: int) -> void:
	for k in held.keys(): hold(k, false)
	for player in [scene.engine_audio, scene.gun_audio, scene.flak_audio, scene.bomb_audio]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	root.remove_child(scene)
	scene.free()
	for frame in range(6):
		await process_frame
		await physics_frame
	quit(code)
