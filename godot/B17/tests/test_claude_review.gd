extends SceneTree
# Aceptación de la revisión de Claude sobre el candidato de Agy (2026-10-24). Autor: Claude.
# Cada comprobación corresponde a un hallazgo de las capturas reales (planning/REVISION_CLAUDE_CANDIDATO.md).
# Contrato que debe cumplir la escena (game.gd):
#   - controls.station: String en ["PILOTO","ARTILLERO","BOMBARDERO"]; controls.set_station(name:String, sim)->void.
#   - En ARTILLERO: controls.aim:Vector2 (yaw,pitch en radianes relativos al avión) y controls.fire(sim)->bool
#     que añade disparos del jugador a sim.combat.defensive_shots.
#   - Retícula visible: un TextureRect con assets/ui/gunsight_ring.png en ARTILLERO y otro con
#     assets/ui/bombsight_norden.png en BOMBARDERO; ninguna en PILOTO.

var failures: PackedStringArray = []

func check(cond: bool, label: String) -> void:
	if not cond:
		failures.append(label)
		print("FAIL ", label)

func _initialize() -> void:
	run.call_deferred()

func all_nodes(n: Node, out: Array) -> void:
	out.append(n)
	for c in n.get_children():
		all_nodes(c, out)

func textures_in(scene: Node) -> Dictionary:
	var found := {}
	var nodes: Array = []
	all_nodes(scene, nodes)
	for n in nodes:
		var tex: Texture2D = null
		if n is Sprite3D: tex = n.texture
		elif n is TextureRect: tex = n.texture
		elif n is GeometryInstance3D and n.material_override is StandardMaterial3D: tex = n.material_override.albedo_texture
		if tex and tex.resource_path != "":
			found[tex.resource_path] = found.get(tex.resource_path, []) + [n]
	return found

func visible_reticle(scene: Node, path: String) -> bool:
	for n in textures_in(scene).get(path, []):
		if n is CanvasItem and n.is_visible_in_tree():
			return true
	return false

func bomber_roots(scene: Node) -> Array:
	var out: Array = []
	var nodes: Array = []
	all_nodes(scene, nodes)
	for n in nodes:
		if n.name == "Engines" and n.get_parent() is Node3D:
			out.append(n.get_parent())
	return out

func on_screen(cam: Camera3D, pos: Vector3, size: Vector2) -> bool:
	if cam.is_position_behind(pos): return false
	var p: Vector2 = cam.unproject_position(pos)
	return p.x >= 0 and p.y >= 0 and p.x <= size.x and p.y <= size.y

func reticle_centered(scene: Node, path: String) -> bool:
	var size: Vector2 = scene.get_viewport().get_visible_rect().size
	for n in textures_in(scene).get(path, []):
		if n is Control and n.is_visible_in_tree():
			var r: Rect2 = n.get_global_rect()
			return r.get_center().distance_to(size / 2.0) < size.y * 0.05 and r.size.y <= size.y * 1.05
	return false

func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	var dt := 1.0 / 60.0
	var nodes: Array = []
	all_nodes(scene, nodes)

	# 1. Formación de 6 bombarderos (cada uno con su nodo Engines con hélices).
	var bombers := 0
	for n in nodes:
		if n.name == "Engines" and n.get_parent() is Node3D:
			bombers += 1
	check(bombers >= 6, "formación: %d bombarderos, se esperan 6" % bombers)

	# 2. Sin el humo de esferas negras (bola negra junto al avión en las capturas).
	for n in nodes:
		if n.get_script() and n.get_script().resource_path == "res://visuals/engine_smoke.gd":
			check(false, "humo: sigue instanciado visuals/engine_smoke.gd (esfera negra); usar engine_smoke_trail.gd")
			break

	# 3. Audio: además del motor, al menos 3 sonidos de combate distintos (ametralladora, flak, explosión).
	var streams := {}
	for n in nodes:
		if (n is AudioStreamPlayer or n is AudioStreamPlayer3D) and n.stream:
			streams[n.stream] = true
	# Enmienda del supervisor (lote 5): armas, flak y bomba asignan su stream al reproducir (SfxBank, variantes);
	# test_audio_integration verifica que suenan. Aquí se exige el motor con bucle y que existan los reproductores de combate.
	check(streams.size() >= 1 and scene.engine_audio.stream != null, "audio: falta el stream del motor")
	check(is_instance_valid(scene.gun_audio) and is_instance_valid(scene.flak_audio) and is_instance_valid(scene.bomb_audio), "audio: faltan reproductores de ametralladora, flak o explosión")

	# 4. Avanzar hasta el flak y la bomba: los efectos deben usar las texturas reales, no esferas opacas.
	var saw_flak_sprite := false
	var saw_impact_sprite := false
	var max_alive := 0
	var fighters_on_screen := false
	var min_clearance := 1e9
	var max_wingmen_visible := 0
	var impact_cam_ok := true
	var cam0: Camera3D = scene.get_node("Camera3D")
	var vsize: Vector2 = scene.get_viewport().get_visible_rect().size
	for frame in range(60 * 800):
		scene._physics_process(dt)
		if frame % 20 == 0:
			var bomb_view: bool = scene.sim.bomb.active or (scene.sim.bomb.spent and scene.impact_age < 3.0)
			if not bomb_view:
				var vis_count := 0
				for b in bomber_roots(scene):
					if b == scene.get_node("Aircraft"): continue
					min_clearance = minf(min_clearance, cam0.global_position.distance_to(b.global_position))
					if on_screen(cam0, b.global_position, vsize): vis_count += 1
				max_wingmen_visible = maxi(max_wingmen_visible, vis_count)
			elif scene.sim.bomb.spent and not scene.sim.bomb.active:
				var hit: Vector3 = scene.sim.bomb.position
				if cam0.global_position.distance_to(hit) < 120.0 or cam0.global_position.y < 80.0:
					impact_cam_ok = false
		var alive := 0
		for i in scene.sim.combat.fighters.size():
			var f = scene.sim.combat.fighters[i]
			if f["alive"]:
				alive += 1
				var vis: Node3D = scene.fighter_visuals[i]
				var cam: Camera3D = scene.get_node("Camera3D")
				if vis.visible and not cam.is_position_behind(vis.global_position):
					var p: Vector2 = cam.unproject_position(vis.global_position)
					var size: Vector2 = scene.get_viewport().get_visible_rect().size
					if p.x >= 0 and p.y >= 0 and p.x <= size.x and p.y <= size.y and cam.global_position.distance_to(vis.global_position) < 1500.0:
						fighters_on_screen = true
		max_alive = maxi(max_alive, alive)
		if frame % 30 == 0:
			for path in textures_in(scene):
				var visible_any := false
				for n in textures_in(scene)[path]:
					if n is Node3D and n.is_visible_in_tree(): visible_any = true
				if visible_any and path.begins_with("res://assets/vfx/flak_"):
					if scene.sim.bomb.spent and not scene.sim.bomb.active: saw_impact_sprite = true
					else: saw_flak_sprite = true
		if scene.sim.mission.phase in ["COMPLETADA", "FALLIDA"]:
			break
	check(saw_flak_sprite, "flak: no se vio ningún sprite de assets/vfx/flak_*.png (siguen esferas opacas)")
	check(saw_impact_sprite, "impacto: la explosión no usa sprites de humo/fuego (sigue la esfera naranja)")
	check(max_alive > 0, "cazas: nunca hubo cazas vivos")
	check(fighters_on_screen, "cazas: ningún caza vivo apareció en pantalla a menos de 1500 m de la cámara")
	check(scene.sim.mission.phase == "COMPLETADA", "misión: la demo automática no completó (%s)" % scene.sim.mission.phase)
	check(min_clearance > 25.0, "cámara: un bombardero a %.1f m de la cámara de persecución (la tapa); mínimo 25 m" % min_clearance)
	check(max_wingmen_visible >= 3, "formación: solo %d compañeros visibles en la cámara de piloto; se esperan ≥3" % max_wingmen_visible)
	check(impact_cam_ok, "impacto: la cámara de impacto está a menos de 120 m del punto de impacto o por debajo de 80 m de altura (queda dentro del humo/edificios)")

	# 5. Puestos y retículas (contrato en la cabecera).
	scene.restart_mission()
	var c = scene.controls
	if not ("station" in c) or not c.has_method("set_station") or not c.has_method("fire") or not ("aim" in c):
		check(false, "puestos: player_controls no expone station/set_station/aim/fire")
	else:
		c.set_station("PILOTO", scene.sim)
		scene.update_presentation(0.0)
		await process_frame
		check(not visible_reticle(scene, "res://assets/ui/gunsight_ring.png") and not visible_reticle(scene, "res://assets/ui/bombsight_norden.png"), "puestos: retícula visible en PILOTO")
		c.set_station("ARTILLERO", scene.sim)
		scene.update_presentation(0.0)
		await process_frame
		check(c.station == "ARTILLERO", "puestos: no cambia a ARTILLERO")
		check(visible_reticle(scene, "res://assets/ui/gunsight_ring.png"), "puestos: falta la mira de artillero en ARTILLERO")
		check(reticle_centered(scene, "res://assets/ui/gunsight_ring.png"), "puestos: la mira de artillero no está centrada en pantalla o se sale")
		var cam: Camera3D = scene.get_node("Camera3D")
		check(cam.global_position.distance_to(scene.get_node("Aircraft").global_position) < 12.0, "artillero: la cámara no está en la torreta (a <12 m del avión)")
		var before: int = scene.sim.combat.defensive_shots.size()
		c.aim = Vector2(0.4, 0.1)
		var fired: bool = c.fire(scene.sim)
		check(fired and scene.sim.combat.defensive_shots.size() > before, "artillero: fire() no añade disparos del jugador")
		c.set_station("BOMBARDERO", scene.sim)
		scene.update_presentation(0.0)
		await process_frame
		check(visible_reticle(scene, "res://assets/ui/bombsight_norden.png"), "puestos: falta la mira Norden en BOMBARDERO")
		check(reticle_centered(scene, "res://assets/ui/bombsight_norden.png"), "puestos: la mira Norden no está centrada en pantalla o se sale")
		var bcam: Camera3D = scene.get_node("Camera3D")
		check(-bcam.global_transform.basis.z.y < -0.7, "bombardero: la cámara no mira hacia abajo por la mira (dirección %s)" % [-bcam.global_transform.basis.z])
		c.set_station("PILOTO", scene.sim)
		scene.update_presentation(0.0)
		await process_frame

	print("TEST FAIL: %d hallazgos de la revisión pendientes" % failures.size() if failures.size() else "TEST PASS: revisión de Claude del candidato")
	quit(1 if failures.size() else 0)
