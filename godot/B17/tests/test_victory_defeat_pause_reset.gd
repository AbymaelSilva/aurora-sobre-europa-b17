extends SceneTree
# Test de victoria, derrota, pausa y reset con eventos Input reales (1.1.3.2)

func _initialize() -> void:
	run.call_deferred()

func make_key_event(key: Key, pressed: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = pressed
	return ev

func dispatch_key(scene: Node, key: Key) -> void:
	var ev_down := make_key_event(key, true)
	scene._unhandled_input(ev_down)

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

	# 1. Pausa y reanudacion con evento P
	sim.autopilot = false
	controls.set_station("PILOTO", sim)
	if sim.paused:
		print("TEST FAIL: sim comienza pausado inesperadamente")
		await finish(scene, 1)
		return

	dispatch_key(scene, KEY_P)
	if not sim.paused:
		print("TEST FAIL: tecla P no activo la pausa")
		await finish(scene, 1)
		return
	if not overlay.data.get("paused", false):
		print("TEST FAIL: overlay.data['paused'] no es true tras pulsar P")
		await finish(scene, 1)
		return

	var clock_before: float = sim.mission.clock
	var pos_before: Vector3 = sim.flight.position
	sim.step(dt)
	scene.update_presentation(dt)
	if sim.mission.clock != clock_before or sim.flight.position != pos_before:
		print("TEST FAIL: la simulacion avanzo mientras estaba pausada por P")
		await finish(scene, 1)
		return

	dispatch_key(scene, KEY_P)
	if sim.paused:
		print("TEST FAIL: segunda pulsacion de P no reanudo el juego")
		await finish(scene, 1)
		return
	if overlay.data.get("paused", false):
		print("TEST FAIL: overlay.data['paused'] no es false tras reanudar con P")
		await finish(scene, 1)
		return
	print("Pausa y reanudacion con tecla P PASS")

	# 2. Pausa y reanudacion con evento Escape
	dispatch_key(scene, KEY_ESCAPE)
	if not sim.paused:
		print("TEST FAIL: tecla Escape no activo la pausa")
		await finish(scene, 1)
		return
	if not overlay.data.get("paused", false):
		print("TEST FAIL: overlay.data['paused'] no es true tras pulsar Escape")
		await finish(scene, 1)
		return

	dispatch_key(scene, KEY_ESCAPE)
	if sim.paused:
		print("TEST FAIL: segunda pulsacion de Escape no reanudo el juego")
		await finish(scene, 1)
		return
	print("Pausa y reanudacion con tecla Escape PASS")

	# 2b. Confirmacion de R durante mision activa (requiere 2 pulsaciones en 2s)
	scene.restart_mission()
	sim.autopilot = false
	sim.mission.clock = 10.0
	sim.flight.position = Vector3(100.0, 1200.0, 500.0)
	scene.update_presentation(0.0)

	# Primera pulsacion de R: NO reinicia, muestra confirmacion
	dispatch_key(scene, KEY_R)
	scene.update_presentation(0.0)
	if sim.mission.clock != 10.0:
		print("TEST FAIL: la primera pulsacion de R reinicio la mision en marcha")
		await finish(scene, 1)
		return
	if not overlay.data.get("restart_confirm", false):
		print("TEST FAIL: overlay.data['restart_confirm'] no es true tras primera R en mision activa")
		await finish(scene, 1)
		return
	print("Primera R en mision activa pide confirmacion PASS")

	# Segunda pulsacion de R inmediata: SI reinicia
	dispatch_key(scene, KEY_R)
	scene.update_presentation(0.0)
	if sim.mission.clock != 0.0 or sim.flight.position != Vector3(0.0, 1200.0, 0.0):
		print("TEST FAIL: segunda pulsacion de R no reinicio la mision")
		await finish(scene, 1)
		return
	if overlay.data.get("restart_confirm", false):
		print("TEST FAIL: overlay.data['restart_confirm'] sigue activo tras reiniciar")
		await finish(scene, 1)
		return
	print("Segunda R dentro de 2s reinicia mision activa PASS")

	# Expiracion del temporizador de 2s
	sim.mission.clock = 5.0
	scene.update_presentation(0.0)
	dispatch_key(scene, KEY_R)
	scene.update_presentation(0.0)
	if not overlay.data.get("restart_confirm", false):
		print("TEST FAIL: primera R no activo confirmacion")
		await finish(scene, 1)
		return
	scene.update_presentation(2.1)
	if overlay.data.get("restart_confirm", false):
		print("TEST FAIL: confirmacion de R no expiro tras 2.1s")
		await finish(scene, 1)
		return
	dispatch_key(scene, KEY_R)
	scene.update_presentation(0.0)
	if sim.mission.clock != 5.0 or not overlay.data.get("restart_confirm", false):
		print("TEST FAIL: R tras expiracion deberia pedir confirmacion nuevamente sin reiniciar")
		await finish(scene, 1)
		return
	dispatch_key(scene, KEY_R)
	scene.update_presentation(0.0)
	if sim.mission.clock != 0.0:
		print("TEST FAIL: confirmacion de segunda R tras ciclo de expiracion no reinicio")
		await finish(scene, 1)
		return
	print("Expiracion de ventana de 2s de confirmacion de R PASS")

	# 3. Derrota por avion perdido (FALLIDA) y recuperacion con R (reset)
	scene.restart_mission()
	sim.autopilot = false
	controls.set_station("PILOTO", sim)

	# Aplicar destruccion total del fuselaje
	sim.damage.apply_damage(100.0)
	if not sim.damage.destroyed():
		print("TEST FAIL: dano letal no marco destroyed()")
		await finish(scene, 1)
		return
	sim.step(dt)
	scene.update_presentation(dt)

	if sim.mission.phase != "FALLIDA":
		print("TEST FAIL: phase no paso a FALLIDA tras derribo (phase=%s)" % sim.mission.phase)
		await finish(scene, 1)
		return
	if overlay.data.get("reason") != "DERRIBO":
		print("TEST FAIL: reason no es DERRIBO (reason=%s)" % overlay.data.get("reason"))
		await finish(scene, 1)
		return
	print("Derrota por avion perdido (DERRIBO) PASS")

	# Reset con tecla R tras derribo
	dispatch_key(scene, KEY_R)
	scene.update_presentation(0.0)
	if sim.mission.phase != "FORMACION" or sim.damage.hull != 100.0 or sim.damage.destroyed():
		print("TEST FAIL: reset con tecla R tras derribo no restauro estado inicial")
		await finish(scene, 1)
		return
	print("Reset con tecla R tras derribo PASS")

	# 4. Derrota por bomba fallada (FALLIDA) y recuperacion con R (reset)
	scene.restart_mission()
	sim.autopilot = false
	sim.mission.phase = "BOMBARDEO"
	controls.set_station("BOMBARDERO", sim)

	# Simular suelta con resultado FALLO
	sim.bomb.spent = true
	sim.bomb.result = "FALLO"
	sim.step(dt)
	scene.update_presentation(dt)

	if sim.mission.phase != "FALLIDA":
		print("TEST FAIL: phase no paso a FALLIDA tras bomba fallada (phase=%s)" % sim.mission.phase)
		await finish(scene, 1)
		return
	if overlay.data.get("reason") != "FALLO":
		print("TEST FAIL: reason no es FALLO tras bomba fallada (reason=%s)" % overlay.data.get("reason"))
		await finish(scene, 1)
		return
	print("Derrota por bomba fallada (FALLO) PASS")

	# Reset con tecla R tras fallo de bombardeo
	dispatch_key(scene, KEY_R)
	scene.update_presentation(0.0)
	if sim.mission.phase != "FORMACION" or sim.bomb.spent or sim.bomb.result != "LISTA":
		print("TEST FAIL: reset con tecla R tras fallo de bombardeo no restauro estado")
		await finish(scene, 1)
		return
	print("Reset con tecla R tras fallo de bombardeo PASS")

	# 5. Victoria (COMPLETADA) alcanzando zona segura y reset con R
	scene.restart_mission()
	sim.autopilot = false
	sim.mission.phase = "REGRESO"
	controls.set_station("PILOTO", sim)

	# Posicionar cerca del punto de salida (exit_point < 500m)
	sim.flight.position = sim.mission.exit_point - Vector3(100.0, 0.0, 50.0)
	sim.step(dt)
	scene.update_presentation(dt)

	if sim.mission.phase != "COMPLETADA":
		print("TEST FAIL: phase no paso a COMPLETADA al llegar a exit_point (phase=%s)" % sim.mission.phase)
		await finish(scene, 1)
		return
	if overlay.data.get("phase") != "COMPLETADA":
		print("TEST FAIL: overlay.data['phase'] no es COMPLETADA")
		await finish(scene, 1)
		return
	var report: Dictionary = overlay.data.get("report", {})
	if report.is_empty():
		print("TEST FAIL: overlay debriefing report vacio en mision completada")
		await finish(scene, 1)
		return
	print("Victoria (COMPLETADA) con debriefing PASS: %s" % str(report))

	# Reset con tecla R tras victoria
	dispatch_key(scene, KEY_R)
	scene.update_presentation(0.0)
	if sim.mission.phase != "FORMACION":
		print("TEST FAIL: reset con tecla R tras victoria no reinicio la mision")
		await finish(scene, 1)
		return
	print("Reset con tecla R tras victoria PASS")

	print("TEST PASS: victoria, derrota (derribo y fallo de bomba), pausa (P y Esc) y reset (R) verificados con eventos reales (1.1.3.2)")
	await finish(scene, 0)

func finish(scene: Node, code: int) -> void:
	for player in [scene.engine_audio, scene.gun_audio, scene.flak_audio, scene.bomb_audio]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	root.remove_child(scene)
	scene.free()
	for frame in range(4):
		await process_frame
		await physics_frame
	quit(code)
