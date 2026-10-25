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
	scene.sim.combat.spawn_wave(1, scene.sim.flight.position)
	scene.orbit_camera.set_exterior(true, scene.sim)
	scene.update_presentation(0.2)
	# Estabilizar exclusivamente la densidad visual; no adelantar diálogos de pared.
	for i in range(720):
		scene.flak_field.step(1.0 / 60.0, true, scene.sim.flight.position, 0.0, scene.get_node("Camera3D"), false)
	var initial_count: int = scene.flak_field.active_burst_count()
	if initial_count < 60 or initial_count > 100:
		push_error("GPU CHECK FAIL: densidad inicial " + str(initial_count))
		quit(1)
		return
	var sample_seconds: float = 60.0
	if "--quick" in OS.get_cmdline_user_args(): sample_seconds = 5.0
	var frames: Array[float] = []
	var max_tracers := 0
	var max_voices := 0
	var max_instances := 0
	var min_alive := 48
	var max_engaging := 0
	var min_flak: int = initial_count
	var max_flak: int = initial_count
	var start: int = Time.get_ticks_usec()
	var captured: bool = false
	while float(Time.get_ticks_usec() - start) / 1000000.0 < sample_seconds:
		var begin: int = Time.get_ticks_usec()
		# Fixture de carga estable, no prueba de supervivencia: invulnerabilidad solo aquí.
		scene.sim.damage.hull = 100.0
		for i in range(scene.sim.damage.engines.size()): scene.sim.damage.engines[i] = 100.0
		for f in scene.sim.combat.fighters:
			f["health"] = 60000.0
			f["alive"] = true
		scene._physics_process(1.0 / 60.0)
		assert(scene.fighter_visuals.size() == 48)
		for i in range(48): assert(scene.fighter_visuals[i].variant == scene.sim.combat.fighters[i]["variant"])
		max_tracers = maxi(max_tracers, scene.tracer_pool.active_count())
		max_instances = maxi(max_instances, int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
		var voices := 0
		for node in scene.find_children("*", "AudioStreamPlayer", true, false):
			if node.playing: voices += 1
		max_voices = maxi(max_voices, voices)
		var engaged := 0
		for esc in scene.escort_visuals:
			if esc.engaging: engaged += 1
		max_engaging = maxi(max_engaging, engaged)
		min_alive = mini(min_alive, scene.sim.combat.fighters.filter(func(f): return f["alive"]).size())
		await process_frame
		await RenderingServer.frame_post_draw
		frames.append(float(Time.get_ticks_usec() - begin) / 1000.0)
		var active: int = scene.flak_field.active_burst_count()
		min_flak = mini(min_flak, active)
		max_flak = maxi(max_flak, active)
		if not captured and float(Time.get_ticks_usec() - start) / 1000000.0 > 1.0:
			root.get_texture().get_image().save_png("res://../../logs/lote9/carga_combinada.png")
			captured = true
	var elapsed: float = float(Time.get_ticks_usec() - start) / 1000000.0
	frames.sort()
	var stats := {
		"enemies_min_alive": min_alive, "enemy_visuals": scene.fighter_visuals.size(), "escorts": scene.escort_visuals.size(), "max_engaging_escorts": max_engaging,
		"max_tracers": max_tracers, "tracer_capacity": scene.tracer_pool.capacity, "max_audio_voices": max_voices, "max_render_objects": max_instances,
		"peak_effective_attackers": scene.sim.combat.peak_attackers, "damage_effect_events": scene.sim.combat.damage_events,
		"seconds": elapsed, "frames": frames.size(), "average_fps": frames.size() / elapsed,
		"median_frame_ms": frames[frames.size() / 2], "p95_frame_ms": frames[int(frames.size() * 0.95)],
		"min_flak": min_flak, "max_flak": max_flak, "pool_limit": scene.flak_field.pool.size(),
		"clouds": scene.get_node("CloudLayer").cloud_count(), "viewport": str(root.get_visible_rect().size),
		"gpu": RenderingServer.get_video_adapter_name(), "fixture": "invulnerable bomber and 48 enemies stress scene; physics fixed 1/60 per rendered frame",
		"music": scene.scene_audio.current_music, "voice_starts": scene.scene_audio.voice_start_count,
		"flak_audio_triggers": scene.flak_field.audio_play_count
	}
	var path: String = "res://../../logs/lote9/gpu_metrics.json"
	if sample_seconds < 60.0: path = "res://../../logs/lote9/gpu_quick_metrics.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(stats, "  "))
	file.close()
	print("GPU CHECK: ", JSON.stringify(stats))
	scene.queue_free()
	await process_frame
	quit(0)
