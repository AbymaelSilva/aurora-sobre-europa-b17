extends SceneTree
# Revisión Claude: reproduce H-06 (sentido del giro) y H-05 (disparo vs cámara) con entradas sintéticas.
# No es prueba de jugador humano. Uso: tools/godot --headless --path godot/B17 --script <abs>/repro_controls_claude.gd

func _initialize() -> void:
	run.call_deferred()

func key(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	var sim = scene.sim
	sim.autopilot = false
	var dt := 1.0 / 60.0
	# H-06: mantener D 3 s en PILOTO.
	scene.controls.station = "PILOTO"
	var p0: Vector3 = sim.flight.position
	var y0: float = sim.flight.yaw
	var fwd0: Vector3 = -Basis.from_euler(Vector3(0, y0, 0)).z
	key(KEY_D, true)
	for i in 180:
		scene._physics_process(dt)
	key(KEY_D, false)
	var dy: float = sim.flight.yaw - y0
	var fwd1: Vector3 = -Basis.from_euler(Vector3(0, sim.flight.yaw, 0)).z
	var right0: Vector3 = fwd0.cross(Vector3.UP)
	var heading0 := fposmod(-rad_to_deg(y0), 360.0)
	var heading1 := fposmod(-rad_to_deg(sim.flight.yaw), 360.0)
	print("H06 turn_input_final=%.2f dyaw=%.4f rad heading %.1f->%.1f lateral_a_derecha=%.2f (positivo=derecha)" % [sim.turn_input, dy, heading0, heading1, fwd1.dot(right0)])
	print("H06 RESULTADO=%s" % ("GIRO_A_LA_IZQUIERDA_CON_D" if fwd1.dot(right0) < 0 else "GIRO_A_LA_DERECHA_CON_D"))
	# H-05: dirección de disparo frente a -Z de la cámara del artillero.
	scene.controls.station = "ARTILLERO"
	var worst := 0.0
	for yaw in [0.0, 0.8, -0.8]:
		for aim in [Vector2(0, 0), Vector2(0.6, 0.3), Vector2(-0.6, 0.3), Vector2(0, -0.85), Vector2(0, -0.35)]:
			sim.flight.yaw = yaw
			scene.controls.aim = aim
			scene.update_presentation(0.0)
			var cam_dir: Vector3 = -scene.get_node("Camera3D").global_transform.basis.z
			sim.combat.defensive_shots.clear()
			scene.controls.fire(sim)
			var s = sim.combat.defensive_shots[-1]
			var shot_dir: Vector3 = (s["target"] - s["origin"]).normalized()
			var ang := rad_to_deg(cam_dir.angle_to(shot_dir))
			worst = maxf(worst, ang)
			print("H05 yaw=%+.2f aim=%s angulo_disparo_vs_camara=%.1f deg" % [yaw, aim, ang])
	print("H05 RESULTADO peor=%.1f deg (umbral propuesto <=1.5 deg)" % worst)
	quit(0)
