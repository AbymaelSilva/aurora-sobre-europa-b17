extends SceneTree
# Test de ayuda de bombardeo manual (U01)
# El operador sintetico usa SOLAMENTE el diccionario bombing_aid expuesto en overlay.data.

func _initialize() -> void:
	run.call_deferred()

func press_space() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_SPACE
	ev.keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func release_space() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_SPACE
	ev.keycode = KEY_SPACE
	ev.pressed = false
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)

	var sim = scene.sim
	var controls = scene.controls
	var overlay = scene.overlay
	var dt := 1.0 / 60.0
	var failed := false
	var target: Vector3 = sim.mission.target

	# Matriz de pruebas balisticas: [altitud, velocidad, descripcion]
	var test_profiles = [
		{"alt": 1200.0, "spd": 85.0, "desc": "Caso base 1200m / 85m/s"},
		{"alt": 1000.0, "spd": 75.0, "desc": "Variacion 1000m / 75m/s"},
		{"alt": 1350.0, "spd": 92.0, "desc": "Variacion 1350m / 92m/s"}
	]

	for prof in test_profiles:
		scene.restart_mission()
		sim.autopilot = false
		sim.mission.phase = "BOMBARDEO"
		controls.set_station("BOMBARDERO", sim)

		sim.flight.position = Vector3(target.x, prof.alt, target.z + 2500.0)
		sim.flight.pitch = 0.0
		sim.flight.yaw = 0.0
		sim.flight.speed = prof.spd
		scene.update_presentation(0.0)

		# Comprobar contrato de datos en overlay.data
		if not overlay.data.has("bombing_aid"):
			print("TEST FAIL: overlay.data no contiene 'bombing_aid'")
			failed = true
			break

		var aid: Dictionary = overlay.data["bombing_aid"]
		for req_key in ["release_now", "eta_seconds", "lateral_error_m", "status", "predicted_impact"]:
			if not aid.has(req_key):
				print("TEST FAIL: bombing_aid falta campo requerido '%s'" % req_key)
				failed = true
				break
		if failed:
			break

		# Aproximacion guiada UNICAMENTE por overlay.data["bombing_aid"]
		var space_pressed := false
		var steps := 0
		while steps < 3000 and not sim.bomb.spent:
			scene._physics_process(dt)
			steps += 1
			var cur_aid: Dictionary = overlay.data["bombing_aid"]
			# El operador sintetico solo consulta release_now expuesto en HUD
			if cur_aid.get("release_now", false) and not space_pressed:
				press_space()
				scene._physics_process(dt)
				release_space()
				space_pressed = true

		if not sim.bomb.spent:
			print("TEST FAIL: %s - el operador no recibio 'release_now' a tiempo para soltar" % prof.desc)
			failed = true
			break

		# Dejar caer la bomba hasta el suelo
		var fall_steps := 0
		while sim.bomb.active and fall_steps < 3600:
			scene._physics_process(dt)
			fall_steps += 1

		var miss_dist: float = Vector2(sim.bomb.position.x, sim.bomb.position.z).distance_to(Vector2(target.x, target.z))
		print("%s -> resultado=%s error=%.1fm" % [prof.desc, sim.bomb.result, miss_dist])
		if sim.bomb.result != "IMPACTO" or miss_dist > 120.0:
			print("TEST FAIL: %s - impacto no valido (res=%s dist=%.1fm)" % [prof.desc, sim.bomb.result, miss_dist])
			failed = true
			break

	# Caso negativo: Fuera de eje (lateral_error grande)
	if not failed:
		scene.restart_mission()
		sim.autopilot = false
		sim.mission.phase = "BOMBARDEO"
		controls.set_station("BOMBARDERO", sim)
		# Desplazado 120m al lateral
		sim.flight.position = Vector3(target.x + 120.0, 1200.0, target.z + 1330.0)
		sim.flight.pitch = 0.0
		sim.flight.yaw = 0.0
		sim.flight.speed = 85.0
		scene.update_presentation(0.0)
		var off_axis_aid: Dictionary = overlay.data.get("bombing_aid", {})
		if off_axis_aid.get("release_now", false):
			print("TEST FAIL: falso positivo en fuera de eje (120m lateral indico release_now=true)")
			failed = true
		else:
			print("Caso negativo fuera de eje PASS: release_now=%s status=%s lateral=%.1fm" % [
				off_axis_aid.get("release_now", false), off_axis_aid.get("status", ""), off_axis_aid.get("lateral_error_m", 0.0)
			])

	# Caso negativo: Objetivo ya pasado (overshoot)
	if not failed:
		scene.restart_mission()
		sim.autopilot = false
		sim.mission.phase = "BOMBARDEO"
		controls.set_station("BOMBARDERO", sim)
		# Ya paso el punto de suelta (z esta 500m pasado el blanco)
		sim.flight.position = Vector3(target.x, 1200.0, target.z + 200.0)
		sim.flight.pitch = 0.0
		sim.flight.yaw = 0.0
		sim.flight.speed = 85.0
		scene.update_presentation(0.0)
		var past_aid: Dictionary = overlay.data.get("bombing_aid", {})
		if past_aid.get("release_now", false):
			print("TEST FAIL: falso positivo con objetivo ya pasado (indico release_now=true)")
			failed = true
		else:
			print("Caso negativo objetivo pasado PASS: release_now=%s status=%s eta=%.1f" % [
				past_aid.get("release_now", false), past_aid.get("status", ""), past_aid.get("eta_seconds", 0.0)
			])

	if failed:
		print("TEST FAIL: U01 prueba de ayuda de bombardeo no superada")
		await finish(scene, 1)
	else:
		print("TEST PASS: ayuda de bombardeo visible y real verificada en HUD (U01)")
		await finish(scene, 0)

func finish(scene: Node, code: int) -> void:
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
