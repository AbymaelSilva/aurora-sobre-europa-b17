extends SceneTree
# Test de integridad de mission_overlay.gd (1.1.3.4 / S3)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var required_strings := [
		"SUELTA AHORA",
		"BOMBAS FUERA",
		"VENTANA DE SUELTA",
		"CORRECCIÓN DE RUMBO",
		"AURORA SOBRE EUROPA",
		"NUDOS",
		"MISIÓN COMPLETADA",
		"PAUSA",
		"data.get(\"bombing_aid"
	]

	var source_path := "res://ui/mission_overlay.gd"
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		print("TEST FAIL: no se pudo abrir %s" % source_path)
		quit(1)
		return
	var source_text := file.get_as_text()
	file.close()

	for req in required_strings:
		if not source_text.contains(req):
			print("TEST FAIL: %s no contiene la cadena requerida '%s'" % [source_path, req])
			quit(1)
			return
	print("Integridad de texto estático PASS: todas las cadenas requeridas presentes en %s" % source_path)

	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)

	var sim = scene.sim
	var controls = scene.controls
	var overlay = scene.overlay

	# Forzar phase BOMBARDEO, station BOMBARDERO y radio no vacia
	sim.mission.phase = "BOMBARDEO"
	controls.set_station("BOMBARDERO", sim)
	scene.radio.message = "MENSAJE DE RADIO DE PRUEBA"
	scene.update_presentation(0.0)

	var overlay_data: Dictionary = overlay.data
	var required_keys := ["radio", "bombing_aid", "station", "altitude", "heading"]
	for k in required_keys:
		if not overlay_data.has(k):
			print("TEST FAIL: overlay.data no contiene la clave requerida '%s'" % k)
			await finish(scene, 1)
			return

	if str(overlay_data.get("radio", "")).is_empty():
		print("TEST FAIL: overlay.data['radio'] esta vacio")
		await finish(scene, 1)
		return

	if str(overlay_data.get("station", "")) != "BOMBARDERO":
		print("TEST FAIL: overlay.data['station'] no es BOMBARDERO (es '%s')" % overlay_data.get("station"))
		await finish(scene, 1)
		return

	if overlay_data.get("phase") != "BOMBARDEO":
		print("TEST FAIL: overlay.data['phase'] no es BOMBARDEO (es '%s')" % overlay_data.get("phase"))
		await finish(scene, 1)
		return

	print("Overlay data runtime PASS: radio='%s', station='%s', phase='%s', bombing_aid=%s" % [
		overlay_data.get("radio"),
		overlay_data.get("station"),
		overlay_data.get("phase"),
		str(overlay_data.get("bombing_aid") != null)
	])

	print("TEST PASS: integridad de mission_overlay verificada")
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
