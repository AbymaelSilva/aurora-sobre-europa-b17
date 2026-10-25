extends SceneTree
# Capturas reales (GPU) de la misión en momentos clave. Revisión visual de Claude; no es una prueba de aprobado/suspenso.
# Uso: tools/godot --path godot/B17 --resolution 1280x720 --script res://tests/capture_mission_claude.gd -- <carpeta absoluta>
# Sale con código 1 (sin colgarse) si falta la carpeta o si se ejecuta headless/sin GPU.
# Las capturas "h_*" se hacen con cámara o estado forzados por este harness y se rotulan así; no son el encuadre del juego.

var out := ""
var scene: Node
var taken := {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or not String(args[0]).is_absolute_path():
		printerr("capture_mission_claude: falta la carpeta de salida absoluta tras '--'")
		quit(1)
		return
	if DisplayServer.get_name() == "headless" or RenderingServer.get_rendering_device() == null:
		printerr("capture_mission_claude: requiere ventana y GPU (no headless); display=%s" % DisplayServer.get_name())
		quit(1)
		return
	out = args[0]
	run.call_deferred()

func snap(label: String) -> void:
	if taken.has(label):
		return
	taken[label] = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, taken.size(), label])
	print("captura %s  t=%.1fs fase=%s cazas_vivos=%d casco=%.1f motores=%s puesto=%s" % [label, scene.sim.mission.clock, scene.sim.mission.phase, alive(), scene.sim.damage.hull, scene.sim.damage.engines, scene.controls.station])

func alive() -> int:
	var n := 0
	for f in scene.sim.combat.fighters:
		if f["alive"]:
			n += 1
	return n

func nearest_fighter() -> int:
	var best := -1
	var best_d := INF
	for i in scene.sim.combat.fighters.size():
		var f = scene.sim.combat.fighters[i]
		if f["alive"] and i < scene.fighter_visuals.size() and scene.fighter_visuals[i].visible:
			var d: float = f["ai"].position.distance_to(scene.sim.flight.position)
			if d < best_d:
				best_d = d
				best = i
	return best

func world_aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		if not (m as MeshInstance3D).is_visible_in_tree():
			continue
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func rotor_angles(n: Node) -> Array:
	var a := []
	for r in n.find_children("Rotor_*", "Node3D", true, false):
		a.append((r as Node3D).rotation.z)
	return a

func max_wrapped_delta(a: Array, b: Array) -> float:
	var m := 0.0
	for i in mini(a.size(), b.size()):
		m = maxf(m, absf(wrapf(b[i] - a[i], -PI, PI)))
	return m

# Mediciones semánticas O/K impresas como "medida ..."; se leen en el log.
func measure_models(tag: String) -> void:
	var ac: Node3D = scene.get_node("Aircraft")
	var models: Array = [ac] + scene.get_node("Formation").wingmen
	var aabbs := []
	for i in models.size():
		var m: Node3D = models[i]
		var glb: Node3D = m.model
		var s := glb.global_basis.get_scale()
		var fwd := -glb.global_basis.z.normalized()
		var dir := -Basis.from_euler(Vector3(scene.sim.flight.pitch, scene.sim.flight.yaw, 0)).z
		var rotors: Array = glb.find_children("Rotor_*", "Node3D", true, false)
		var fin: Node3D = glb.find_child("Fin*", true, false)
		var rz := []
		for r in rotors:
			rz.append(snappedf(m.to_local((r as Node3D).global_position).z, 0.01))
		var procedural := m.find_children("Body", "", true, false).size() + m.find_children("Wings", "", true, false).size() + m.find_children("Nacelle*", "", true, false).size()
		aabbs.append(world_aabb(glb))
		print("medida %s bombardero=%d escala=%s ang_avance=%.2f° rotores=%d rotor_z=%s fin_z=%s procedural=%d" % [tag, i, s, rad_to_deg(fwd.angle_to(dir)), rotors.size(), rz, "-" if fin == null else str(snappedf(m.to_local(fin.global_position).z, 0.01)), procedural])
	var min_gap := INF
	for i in aabbs.size():
		for j in range(i + 1, aabbs.size()):
			var a: AABB = aabbs[i]
			var b: AABB = aabbs[j]
			var gap := Vector3(maxf(0, maxf(a.position.x - b.end.x, b.position.x - a.end.x)), maxf(0, maxf(a.position.y - b.end.y, b.position.y - a.end.y)), maxf(0, maxf(a.position.z - b.end.z, b.position.z - a.end.z))).length()
			min_gap = minf(min_gap, gap)
	var cam: Camera3D = scene.get_node("Camera3D")
	print("medida %s separacion_min_aabb=%.2f m cam_a_jugador=%.1f m" % [tag, min_gap, cam.global_position.distance_to(ac.global_position)])
	var eng: Array = EngineAnchors_sorted(ac)
	var smoke: Array = scene.engine_smokes
	for i in eng.size():
		var rl: Vector3 = ac.to_local((eng[i] as Node3D).global_position)
		var sl: Vector3 = ac.to_local((smoke[i] as Node3D).global_position)
		print("medida %s motor=%d rotor=%s rotor_local=%s humo_local=%s dx=%.2f" % [tag, i, (eng[i] as Node3D).name, rl, sl, absf(sl.x - rl.x)])
	for i in scene.fighter_visuals.size():
		var fv: Node3D = scene.fighter_visuals[i]
		if i < scene.sim.combat.fighters.size() and scene.sim.combat.fighters[i]["alive"] and fv.visible:
			var v: Vector3 = scene.sim.combat.fighters[i]["ai"].velocity
			var fwd2: Vector3 = -fv.model.global_basis.z.normalized()
			var span := world_aabb(fv.model)
			print("medida %s caza=%d variante=%s ang_avance=%.2f° escala=%s aabb=%s" % [tag, i, fv.variant, rad_to_deg(fwd2.angle_to(v.normalized())), fv.model.global_basis.get_scale(), span.size])

func EngineAnchors_sorted(n: Node3D) -> Array:
	return preload("res://visuals/engine_anchors.gd").get_sorted_rotors(n)

func measure_spin(tag: String) -> void:
	var ac: Node3D = scene.get_node("Aircraft")
	var a := rotor_angles(ac)
	var t0 := Time.get_ticks_usec()
	for i in 30:
		await process_frame
	var dt := float(Time.get_ticks_usec() - t0) / 1e6
	var b := rotor_angles(ac)
	var fa: Array = []
	var fb: Array = []
	for fv in scene.fighter_visuals:
		if fv.rotor != null:
			fa.append(fv.rotor.rotation.z)
	for i in 30:
		await process_frame
	for fv in scene.fighter_visuals:
		if fv.rotor != null:
			fb.append(fv.rotor.rotation.z)
	print("medida %s giro_b17 max_delta=%.4f rad en %.3fs (%.1f rad/s por frame-limite) caza_max_delta=%.4f" % [tag, max_wrapped_delta(a, b), dt, max_wrapped_delta(a, b) / maxf(dt, 1e-6), max_wrapped_delta(fa, fb)])

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var dt := 1.0 / 60.0
	var fighters_seen := -1.0
	for frame in range(60 * 1500):
		scene._physics_process(dt)
		var sim = scene.sim
		var t: float = sim.mission.clock
		if frame == 300:
			await snap("inicio")
			measure_models("inicio")
			await measure_spin("activo")
			var cam: Camera3D = scene.get_node("Camera3D")
			cam.global_position = sim.flight.position + Vector3(0, 140, 260).rotated(Vector3.UP, sim.flight.yaw)
			cam.look_at(sim.flight.position + Vector3(0, -10, 40).rotated(Vector3.UP, sim.flight.yaw), Vector3.UP)
			await snap("h_formacion_6")
			cam.global_position = sim.flight.position + Vector3(-22, 6, -8).rotated(Vector3.UP, sim.flight.yaw)
			cam.look_at(sim.flight.position, Vector3.UP)
			await snap("h_b17_cerca")
			scene.update_presentation(0.0)
		if alive() > 0 and fighters_seen < 0.0:
			fighters_seen = t
		if fighters_seen >= 0.0 and t > fighters_seen + 6.0 and not taken.has("cazas"):
			await snap("cazas")
			measure_models("cazas")
			var k := nearest_fighter()
			if k >= 0:
				var fv: Node3D = scene.fighter_visuals[k]
				var cam: Camera3D = scene.get_node("Camera3D")
				var side: Vector3 = fv.global_basis.x
				cam.global_position = fv.global_position + side * 14.0 + Vector3.UP * 4.0
				cam.look_at(fv.global_position, Vector3.UP)
				await snap("h_caza_cerca_" + fv.variant)
				for j in scene.fighter_visuals.size():
					var other: Node3D = scene.fighter_visuals[j]
					if j != k and other.visible and other.variant != fv.variant and sim.combat.fighters[j]["alive"]:
						cam.global_position = other.global_position + other.global_basis.x * 14.0 + Vector3.UP * 4.0
						cam.look_at(other.global_position, Vector3.UP)
						await snap("h_caza_cerca_" + other.variant)
						break
			scene.update_presentation(0.0)
		var kc := nearest_fighter()
		if kc >= 0 and not taken.has("h_artillero_caza_cercano") and sim.combat.fighters[kc]["ai"].position.distance_to(sim.flight.position) < 450.0:
			await snap("persecucion_caza_cercano")
			scene.controls.set_station("ARTILLERO", sim)
			var relc: Vector3 = scene.fighter_visuals[kc].global_position - (sim.flight.position + Vector3(0.0, 2.8, -1.8).rotated(Vector3.UP, sim.flight.yaw))
			scene.controls.aim = Vector2(wrapf(atan2(-relc.x, -relc.z) - sim.flight.yaw, -PI, PI), atan2(relc.y, Vector2(relc.x, relc.z).length()))
			scene.update_presentation(0.0)
			print("medida artillero_cercano caza=%d variante=%s dist=%.0f m aim=%s" % [kc, scene.fighter_visuals[kc].variant, relc.length(), scene.controls.aim])
			await snap("h_artillero_caza_cercano")
			scene.controls.aim = Vector2.ZERO
			scene.controls.set_station("PILOTO", sim)
			scene.update_presentation(0.0)
		if sim.flak.bursts >= 3:
			await snap("flak")
		if sim.mission.phase == "BOMBARDEO":
			await snap("bombardeo")
			if not taken.has("puesto_bombardero") and "station" in scene.controls:
				scene.controls.set_station("BOMBARDERO", sim)
				scene.update_presentation(0.0)
				var cam: Camera3D = scene.get_node("Camera3D")
				print("medida norden cam_local=%s dir_y=%.3f aircraft_visible=%s" % [scene.get_node("Aircraft").to_local(cam.global_position), -cam.global_basis.z.y, scene.get_node("Aircraft").visible])
				await snap("puesto_bombardero")
				scene.controls.set_station("PILOTO", sim)
				scene.update_presentation(0.0)
				await snap("piloto_tras_bombardero")
		if fighters_seen >= 0.0 and t > fighters_seen + 3.0 and not taken.has("puesto_artillero") and "station" in scene.controls:
			scene.controls.set_station("ARTILLERO", sim)
			scene.update_presentation(0.0)
			await snap("puesto_artillero")
			var k := nearest_fighter()
			if k >= 0:
				var rel: Vector3 = scene.fighter_visuals[k].global_position - scene.get_node("Camera3D").global_position
				var yaw_abs := atan2(-rel.x, -rel.z)
				var pitch_abs := atan2(rel.y, Vector2(rel.x, rel.z).length())
				scene.controls.aim = Vector2(wrapf(yaw_abs - sim.flight.yaw, -PI, PI), pitch_abs)
				scene.update_presentation(0.0)
				var cam: Camera3D = scene.get_node("Camera3D")
				var sp := cam.unproject_position(scene.fighter_visuals[k].global_position)
				print("medida artillero caza=%d dist=%.0f m aim=%s pantalla=%s" % [k, rel.length(), scene.controls.aim, sp])
				await snap("h_artillero_apunta_caza")
			scene.controls.aim = Vector2.ZERO
			scene.controls.set_station("PILOTO", sim)
			scene.update_presentation(0.0)
		if sim.bomb.active and sim.bomb.position.y < sim.flight.position.y * 0.5:
			await snap("bomba_cayendo")
		if sim.bomb.spent and not sim.bomb.active and scene.impact_age > 0.6:
			await snap("impacto")
		if sim.mission.phase == "REGRESO" and taken.has("impacto") and scene.impact_age > 8.0:
			await snap("regreso")
		if sim.mission.phase in ["COMPLETADA", "FALLIDA"]:
			for i in 30:
				scene._physics_process(dt)
			await snap("final_" + sim.mission.phase)
			await measure_spin("final")
			break
	# Humo indexado forzado por el harness: se reinicia y se daña solo el motor 1 (segundo por la izquierda).
	scene.restart_mission()
	scene.sim.damage.engines[1] = 5.0
	for i in 150:
		scene._physics_process(dt)
		await process_frame
	var ac: Node3D = scene.get_node("Aircraft")
	var cam: Camera3D = scene.get_node("Camera3D")
	measure_models("humo")
	cam.global_position = ac.global_position + Vector3(-14, 16, 34).rotated(Vector3.UP, scene.sim.flight.yaw)
	cam.look_at(ac.global_position + Vector3(-3, 0, 4).rotated(Vector3.UP, scene.sim.flight.yaw), Vector3.UP)
	await snap("h_humo_motor1")
	scene.sim.paused = true
	scene.update_presentation(0.0)
	await measure_spin("pausa")
	print("capturas: ", taken.size())
	scene.queue_free()
	await process_frame
	quit(0)
