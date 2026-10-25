extends SceneTree
# Test de neutralizacion de entradas de vuelo al cambiar de puesto (U02)
# Verifica los 6 casos (D, S, SHIFT x ARTILLERO/BOMBARDERO) y retorno a PILOTO.

func _initialize() -> void:
	run.call_deferred()

func send_key(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)

	var sim = scene.sim
	var controls = scene.controls
	var dt := 1.0 / 60.0
	var failed := false

	var test_keys = [
		{"code": KEY_D, "name": "KEY_D", "axis": "turn"},
		{"code": KEY_S, "name": "KEY_S", "axis": "pitch"},
		{"code": KEY_SHIFT, "name": "KEY_SHIFT", "axis": "throttle"}
	]
	var test_stations = ["ARTILLERO", "BOMBARDERO"]

	var test_count := 0
	for target_station in test_stations:
		for item in test_keys:
			test_count += 1
			scene.restart_mission()
			sim.autopilot = false
			controls.set_station("PILOTO", sim)

			# 1. Pulsar la tecla en PILOTO
			send_key(item.code, true)
			scene._physics_process(dt)

			# Verificar que en PILOTO la tecla produce input
			var active_val: float = 0.0
			if item.axis == "turn":
				active_val = sim.turn_input
			elif item.axis == "pitch":
				active_val = sim.pitch_input
			elif item.axis == "throttle":
				active_val = sim.throttle_input

			if absf(active_val) < 0.5:
				print("TEST FAIL: caso %d (%s -> %s) no registro input inicial en PILOTO" % [test_count, item.name, target_station])
				failed = true
				break

			# 2. Soltar fisicamente la tecla
			send_key(item.code, false)

			# 3. Cambiar de puesto a ARTILLERO / BOMBARDERO
			controls.set_station(target_station, sim)

			# Comprobar inmediatamente al cambio
			if sim.turn_input != 0.0 or sim.pitch_input != 0.0 or sim.throttle_input != 0.0:
				print("TEST FAIL: caso %d (%s -> %s) input no es 0 inmediatamente tras set_station: p=%.2f t=%.2f th=%.2f" % [
					test_count, item.name, target_station, sim.pitch_input, sim.turn_input, sim.throttle_input
				])
				failed = true
				break

			var yaw_before: float = sim.flight.yaw
			var speed_before: float = sim.flight.speed

			# 4. Avanzar 2 segundos (120 frames) en el puesto nuevo sin tocar teclas
			for f in range(120):
				scene._physics_process(dt)

			# Comprobar inputs tras 2s
			if sim.turn_input != 0.0 or sim.pitch_input != 0.0 or sim.throttle_input != 0.0:
				print("TEST FAIL: caso %d (%s -> %s) input latente tras 2s: p=%.2f t=%.2f th=%.2f" % [
					test_count, item.name, target_station, sim.pitch_input, sim.turn_input, sim.throttle_input
				])
				failed = true
				break

			# Comprobar deriva espuria
			var yaw_diff_deg: float = absf(rad_to_deg(sim.flight.yaw - yaw_before))
			var speed_diff: float = absf(sim.flight.speed - speed_before)
			if item.axis == "turn" and yaw_diff_deg > 0.01:
				print("TEST FAIL: caso %d giro espurio yaw_diff=%.2f deg" % [test_count, yaw_diff_deg])
				failed = true
				break
			if item.axis == "throttle" and speed_diff > 0.01:
				print("TEST FAIL: caso %d aceleracion espuria speed_diff=%.2f m/s" % [test_count, speed_diff])
				failed = true
				break

			# 5. Volver a PILOTO sin teclas: inputs deben seguir 0 y no cargar historico
			controls.set_station("PILOTO", sim)
			scene._physics_process(dt)
			if sim.turn_input != 0.0 or sim.pitch_input != 0.0 or sim.throttle_input != 0.0:
				print("TEST FAIL: caso %d retorno a PILOTO cargo basura historica: p=%.2f t=%.2f th=%.2f" % [
					test_count, item.name, target_station, sim.pitch_input, sim.turn_input, sim.throttle_input
				])
				failed = true
				break

			# 6. Polleo activo vigente: si pulsa nueva tecla (W), responde inmediatamente
			send_key(KEY_W, true)
			scene._physics_process(dt)
			if sim.pitch_input >= -0.5:
				print("TEST FAIL: caso %d en PILOTO nueva tecla KEY_W no respondio: p=%.2f" % [test_count, sim.pitch_input])
				failed = true
				break
			send_key(KEY_W, false)
			scene._physics_process(dt)

		if failed:
			break

	# 7. Contrato de pausa / reset
	if not failed:
		scene.restart_mission()
		if sim.pitch_input != 0.0 or sim.turn_input != 0.0 or sim.throttle_input != 0.0:
			print("TEST FAIL: reset no deja inputs en 0")
			failed = true
		sim.paused = true
		scene._physics_process(dt)
		sim.paused = false
		scene._physics_process(dt)

	if failed:
		print("TEST FAIL: U02 neutralizacion de entradas fallo")
		await finish(scene, 1)
	else:
		print("TEST PASS: neutralizacion de entradas al cambiar de puesto verificada (6 casos + retorno a PILOTO + reset/pausa)")
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
