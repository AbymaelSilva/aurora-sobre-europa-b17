extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.sim.flight.position = Vector3(0, 1200, -15000)
	scene.sim.mission.phase = "APROXIMACION"
	scene.sim.mission.waypoint_index = 2
	scene.sim.mission.clock = 120.0
	scene.orbit_camera.set_exterior(true, scene.sim)
	var camera: Camera3D = scene.get_node("Camera3D")
	var evidence: Array = []
	for shot in [{"name": "frontal", "index": 0, "time": 11.0}, {"name": "lateral", "index": 16, "time": 16.6}, {"name": "cola", "index": 32, "time": 22.2}, {"name": "caza_danado", "index": 1, "time": 12.0}, {"name": "escolta_combate", "index": 16, "time": 17.0}, {"name": "orbital", "index": 0, "time": 11.0}]:
		scene.sim.combat.spawn_wave(1, scene.sim.flight.position)
		for tick in range(int(shot["time"] * 60)):
			for f in scene.sim.combat.fighters: f["health"] = 60000.0
			scene.sim.combat.step(1.0 / 60.0, scene.sim.flight.position, 0.0, "APROXIMACION", null)
		var f = scene.sim.combat.fighters[shot["index"]]
		if shot["name"] == "caza_danado":
			f["health"] = 24.0
			f["damage_cause"] = "capture_fixture_engine_damage"
		for frame in range(120):
			scene.update_presentation(1.0 / 60.0)
			var target: Vector3 = f["ai"].position
			var dir: Vector3 = f["ai"].velocity.normalized()
			if shot["name"] == "orbital":
				scene.orbit_camera.mode = 1
				scene.orbit_camera.current_yaw = 0.9
				scene.orbit_camera.target_yaw = 0.9
				scene.orbit_camera.update(1.0, camera, 0.0)
			elif shot["name"] == "escolta_combate":
				var escort = scene.escort_visuals[4]
				target = escort.global_position
				camera.global_position = target + Vector3(32, 12, 40)
				camera.look_at(target, Vector3.UP)
			else:
				camera.global_position = target - dir * 42.0 + Vector3(24, 12, 0)
				camera.look_at(target + dir * 20.0, Vector3.UP)
			await process_frame
		# Snapshot a real logical burst within the current pass where available.
		if shot["name"] in ["frontal", "lateral", "cola"]:
			for tick in range(20):
				scene.sim.combat.step(0.05, scene.sim.flight.position, 0.0, "APROXIMACION", null)
				if not scene.sim.combat.enemy_shots.is_empty():
					scene.update_presentation(0.016)
					var target: Vector3 = f["ai"].position
					var dir: Vector3 = f["ai"].velocity.normalized()
					camera.global_position = target - dir * 42.0 + Vector3(24, 12, 0)
					camera.look_at(target + dir * 20.0, Vector3.UP)
					await process_frame
					break
		await RenderingServer.frame_post_draw
		var path: String = "res://../../logs/lote9/" + shot["name"] + ".png"
		root.get_texture().get_image().save_png(path)
		evidence.append({"capture": shot["name"], "fighter": shot["index"], "profile": f["ai"].profile, "distance_m": f["ai"].position.distance_to(scene.sim.flight.position), "fixture": "real rendered game; deterministic frozen pass positions; camera placement only in test"})
	var file := FileAccess.open("res://../../logs/lote9/captures.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "  "))
	scene.queue_free()
	await process_frame
	quit()
