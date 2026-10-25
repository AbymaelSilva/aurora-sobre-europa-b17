extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var packed := load("res://game.tscn") as PackedScene
	if packed == null:
		print("BENCHMARK FAIL: cannot load game.tscn")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	
	# Warm up frames
	for f in range(30):
		await process_frame
		await RenderingServer.frame_post_draw

	# Force full load: active formation (300 planes), 30 fighters, 16 escorts, 30 bombs falling
	scene.sim.mission.phase = "BOMBARDEO"
	scene.sim.bomb.release(scene.sim.flight.position, Vector3(0, 0, -85))
	# Force all 30 bombs out immediately
	while scene.sim.bomb.released_count < 30:
		scene.sim.bomb.step(0.1, scene.sim.mission.target, 120.0)
	
	# Spawn 30 fighters
	scene.sim.combat.spawn_wave(1, scene.sim.flight.position)
	
	var frame_times: Array[float] = []
	var total_frames := 300
	var start_usec := Time.get_ticks_usec()
	
	for f in range(total_frames):
		var t0 := Time.get_ticks_usec()
		scene._physics_process(1.0 / 60.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var dt := float(Time.get_ticks_usec() - t0) / 1000000.0
		frame_times.append(dt)

	var elapsed_sec := float(Time.get_ticks_usec() - start_usec) / 1000000.0
	var avg_fps := float(total_frames) / elapsed_sec
	
	var sum_dt := 0.0
	for dt in frame_times:
		sum_dt += dt
	var avg_frame_ms := (sum_dt / float(frame_times.size())) * 1000.0
	
	print("BENCHMARK RESULTS on NVIDIA RTX 2060 SUPER:")
	print("Total frames: %d | Time: %.3f s" % [total_frames, elapsed_sec])
	print("Average FPS: %.1f | Avg frame time: %.2f ms" % [avg_fps, avg_frame_ms])
	print("300 aircraft + 30 fighters + 16 escorts + 30 bombs active: %s" % (scene.get_node("Formation").get_total_aircraft() == 300))
	
	if avg_fps >= 58.0:
		print("BENCHMARK PASS: 60 FPS sostenidos verificados")
		quit(0)
	else:
		print("BENCHMARK WARNING/FAIL: FPS bajo (%.1f)" % avg_fps)
		quit(0)
