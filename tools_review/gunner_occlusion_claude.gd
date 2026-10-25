extends SceneTree
# Captura GPU (Claude, fuera del juego): mismo instante determinista que h_artillero_caza_cercano,
# con y sin la retícula, para comprobar si el punto central tapa el caza. Uso: ... --script <este> -- <carpeta absoluta>
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty() or not String(a[0]).is_absolute_path() or DisplayServer.get_name() == "headless":
		printerr("gunner_occlusion_claude: requiere carpeta absoluta y ventana GPU")
		quit(1)
		return
	run.call_deferred(a[0])

func shot(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run(out: String) -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var sim = scene.sim
	for frame in range(60 * 200):
		scene._physics_process(1.0 / 60.0)
		var best := -1
		var bd := INF
		for i in sim.combat.fighters.size():
			var f = sim.combat.fighters[i]
			if f["alive"] and scene.fighter_visuals[i].visible:
				var d: float = f["ai"].position.distance_to(sim.flight.position)
				if d < bd:
					bd = d
					best = i
		if best >= 0 and bd < 450.0:
			scene.controls.set_station("ARTILLERO", sim)
			var cam_pos: Vector3 = sim.flight.position + Vector3(0.0, 2.8, -1.8).rotated(Vector3.UP, sim.flight.yaw)
			var rel: Vector3 = scene.fighter_visuals[best].global_position - cam_pos
			scene.controls.aim = Vector2(wrapf(atan2(-rel.x, -rel.z) - sim.flight.yaw, -PI, PI), atan2(rel.y, Vector2(rel.x, rel.z).length()))
			scene.update_presentation(0.0)
			var cam: Camera3D = scene.get_node("Camera3D")
			var fv: Node3D = scene.fighter_visuals[best]
			var vp: Vector2 = root.get_visible_rect().size
			var px_per_m: float = vp.y / (2.0 * tan(deg_to_rad(cam.fov) * 0.5) * rel.length())
			print("medida t=%.1f caza=%s dist=%.0f m pantalla=%s ancho_estimado=%.0f px (envergadura 10 m) retícula=%s" % [sim.mission.clock, fv.variant, rel.length(), cam.unproject_position(fv.global_position), px_per_m * 10.0, scene.gunsight_rect.size])
			await shot(out + "/artillero_con_reticula.png")
			scene.gunsight_rect.visible = false
			await shot(out + "/artillero_sin_reticula.png")
			break
	scene.queue_free()
	await process_frame
	quit(0)
