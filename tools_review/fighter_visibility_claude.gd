extends SceneTree
# Medición (no captura): distancia caza-jugador y presencia en pantalla con la cámara de persecución, misión demo completa.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var cam: Camera3D = scene.get_node("Camera3D")
	var vp := Vector2(1280, 720)
	var min_d := INF
	var frames_onscreen := 0
	var frames_onscreen_close := 0
	var frames_alive := 0
	var hist := {}
	var spawns := 0
	var prev_alive := 0
	for frame in range(60 * 1500):
		scene._physics_process(1.0 / 60.0)
		var sim = scene.sim
		var any_on := false
		var any_close := false
		var n := 0
		for i in sim.combat.fighters.size():
			var f = sim.combat.fighters[i]
			if not f["alive"]:
				continue
			n += 1
			var p: Vector3 = f["ai"].position
			var d: float = p.distance_to(sim.flight.position)
			min_d = minf(min_d, d)
			var b := int(d / 250.0) * 250
			hist[b] = hist.get(b, 0) + 1
			if not cam.is_position_behind(p):
				var s := cam.unproject_position(p)
				if s.x >= 0 and s.y >= 0 and s.x <= vp.x and s.y <= vp.y:
					any_on = true
					if p.distance_to(cam.global_position) < 600.0:
						any_close = true
		if n > prev_alive:
			spawns += n - prev_alive
		prev_alive = n
		if n > 0:
			frames_alive += 1
		if any_on:
			frames_onscreen += 1
		if any_close:
			frames_onscreen_close += 1
		if sim.mission.phase in ["COMPLETADA", "FALLIDA"]:
			break
	var keys := hist.keys()
	keys.sort()
	var h := []
	for k in keys:
		h.append("%d-%d:%d" % [k, k + 250, hist[k]])
	print("medida cazas min_dist=%.0f m frames_con_cazas=%d en_pantalla_persecucion=%d en_pantalla_<600m=%d kills=%d" % [min_d, frames_alive, frames_onscreen, frames_onscreen_close, scene.sim.combat.total_kills])
	print("medida histograma_distancia(muestras caza-frame) ", " ".join(h))
	scene.queue_free()
	await process_frame
	quit(0)
