extends SceneTree

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("TEST FAIL: " + message)
		quit(1)
	return ok

func button(index: int, pressed: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	return event

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.controls.profile = "XBOX"
	var cam: Camera3D = scene.get_node("Camera3D")
	scene._unhandled_input(button(JOY_BUTTON_Y))
	if not check(scene.orbit_camera.is_exterior, "Y no activa cámara exterior"): return
	if not check(scene.orbit_camera.target_list.size() == 22, "Faltan compañeros/escoltas"): return
	var station: String = scene.controls.station
	scene._unhandled_input(button(JOY_BUTTON_LEFT_SHOULDER))
	scene._unhandled_input(button(JOY_BUTTON_DPAD_RIGHT))
	if not check(scene.controls.station == station, "LB+cruceta cambió puesto"): return
	if not check(scene.orbit_camera.target_name == "Aurora Dos", "No observa compañero"): return
	if not check(scene.sim.autopilot, "Observación no activa autopiloto"): return
	scene._unhandled_input(button(JOY_BUTTON_LEFT_SHOULDER, false))
	for i in range(30): scene.update_presentation(1.0 / 60.0)
	var target: Node3D = scene.orbit_camera.target_node
	if not check(cam.global_position.distance_to(target.global_position) >= 44, "Cámara demasiado cerca"): return
	if not check((-cam.global_basis.z).dot((target.global_position - cam.global_position).normalized()) > 0.99, "Cámara no mira al compañero"): return
	var args := OS.get_cmdline_user_args()
	if "--capture" in args:
		for i in range(6):
			await process_frame
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../../logs/lote8/camera_companion.png")
	scene.orbit_camera.target_yaw += 1.2
	scene.orbit_camera.target_pitch = 0.9
	scene._unhandled_input(button(JOY_BUTTON_RIGHT_STICK))
	if not check(absf(scene.orbit_camera.target_pitch - deg_to_rad(12)) < 0.001, "R3 no centra"): return
	scene.set_pause(true)
	var pos := cam.global_position
	scene._physics_process(0.1)
	if not check(cam.global_position.is_equal_approx(pos), "Cámara se mueve pausada"): return
	scene.set_pause(false)
	scene._unhandled_input(button(JOY_BUTTON_Y))
	scene._unhandled_input(button(JOY_BUTTON_DPAD_RIGHT))
	if not check(scene.controls.station == "ARTILLERO", "Cruceta normal no cambia puesto"): return
	scene.update_presentation(1.0 / 60.0)
	if not check(cam.global_position.distance_to(scene.sim.flight.position) < 12, "No restaura torreta"): return
	scene._unhandled_input(button(JOY_BUTTON_Y))
	if not check(not scene.gunsight_rect.visible, "Mira de torreta visible en cámara exterior"): return
	var aim: Vector2 = scene.controls.aim
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(30, 20)
	scene._unhandled_input(move)
	if not check(scene.controls.aim == aim, "Ratón exterior mueve torreta"): return
	scene.restart_mission()
	if not check(not scene.orbit_camera.is_exterior and scene.orbit_camera.target_index == 0, "Reinicio no limpia cámara"): return
	scene.queue_free()
	await process_frame
	print("TEST PASS: cámara exterior, observación, prioridades de mando, centrado, pausa y reinicio")
	quit(0)
