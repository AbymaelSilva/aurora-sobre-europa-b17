extends SceneTree
# 1.1.4.3 (Claude): rendimiento real con ventana y GPU en esta máquina. No modifica producción.
# Uso: tools/godot --path godot/B17 --resolution 1280x720 --script res://../../tools_review/perf_local_claude.gd -- <segundos> <salida.json>
# Juega la misión en demo (autopiloto) y mide los tiempos de fotograma reales; acelera la misión para cubrir varias fases.

var seconds := 90.0
var out := ""
var scene: Node
var frames: PackedFloat32Array = []
var phases := {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or DisplayServer.get_name() == "headless":
		printerr("perf_local_claude: requiere ventana y argumentos <segundos> <salida.json>")
		quit(1)
		return
	seconds = float(args[0])
	out = String(args[1])
	run.call_deferred()

func run() -> void:
	scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	for i in range(60):
		await process_frame
	var start := Time.get_ticks_usec()
	var last := start
	while (Time.get_ticks_usec() - start) < seconds * 1e6:
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		# Avanza la simulación extra para recorrer fases (formación, cazas, flak, bombardeo).
		for k in range(7):
			scene.sim.step(1.0 / 60.0)
		phases[scene.sim.mission.phase] = phases.get(scene.sim.mission.phase, 0) + 1
	var sorted := frames.duplicate()
	sorted.sort()
	var n := sorted.size()
	var total := 0.0
	var slow := 0
	for f in frames:
		total += f
		if f > 33.3:
			slow += 1
	var report := {
		"frames": n, "avg_ms": total / n, "fps_avg": 1000.0 * n / total,
		"p50_ms": sorted[int(n * 0.5)], "p95_ms": sorted[int(n * 0.95)], "p99_ms": sorted[int(n * 0.99)], "max_ms": sorted[n - 1],
		"frames_over_33ms": slow,
		"phases_frames": phases,
		"gpu": RenderingServer.get_video_adapter_name(), "driver": RenderingServer.get_video_adapter_api_version(),
		"vsync": DisplayServer.window_get_vsync_mode(), "resolution": str(root.get_visible_rect().size),
		"static_mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
	}
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print(JSON.stringify(report))
	scene.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
