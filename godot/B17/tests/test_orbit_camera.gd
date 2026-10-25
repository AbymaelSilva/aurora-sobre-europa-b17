# tests/test_orbit_camera.gd
extends SceneTree

const OrbitCamera = preload("res://camera/orbit_camera_controller.gd")

func _init() -> void:
	print("--- TEST ORBIT CAMERA CONTROLLER ---")
	test_limits()
	test_centering()
	test_cycle_and_recovery()
	test_timestep_stability()
	test_autopilot_on_observation()
	print("ALL ORBIT CAMERA TESTS PASSED!")
	quit(0)

func test_limits() -> void:
	var ctrl = OrbitCamera.new()
	var dummy_player = Node3D.new()
	ctrl.setup(dummy_player, [], [])
	ctrl.set_exterior(true, null)

	# Probar límites de distancia
	ctrl.target_distance = 10.0
	ctrl.target_distance = clampf(ctrl.target_distance, OrbitCamera.MIN_DISTANCE, OrbitCamera.MAX_DISTANCE)
	assert(ctrl.target_distance >= 45.0, "Distancia mínima debe ser 45m")

	ctrl.target_distance = 500.0
	ctrl.target_distance = clampf(ctrl.target_distance, OrbitCamera.MIN_DISTANCE, OrbitCamera.MAX_DISTANCE)
	assert(ctrl.target_distance <= 320.0, "Distancia máxima debe ser 320m")

	# Probar límites de pitch
	ctrl.target_pitch = -2.0 # por debajo de -25°
	ctrl.target_pitch = clampf(ctrl.target_pitch, OrbitCamera.MIN_PITCH, OrbitCamera.MAX_PITCH)
	assert(ctrl.target_pitch >= OrbitCamera.MIN_PITCH - 0.001, "Pitch no debe ser menor a -25°")

	ctrl.target_pitch = 2.0 # por encima de 70°
	ctrl.target_pitch = clampf(ctrl.target_pitch, OrbitCamera.MIN_PITCH, OrbitCamera.MAX_PITCH)
	assert(ctrl.target_pitch <= OrbitCamera.MAX_PITCH + 0.001, "Pitch no debe ser mayor a 70°")

	dummy_player.free()
	print("  [PASS] test_limits")

func test_centering() -> void:
	var ctrl = OrbitCamera.new()
	var dummy_player = Node3D.new()
	dummy_player.rotation.y = deg_to_rad(45.0)
	ctrl.setup(dummy_player, [], [])
	ctrl.set_exterior(true, null)

	# Modificar orientación actual
	ctrl.target_yaw = deg_to_rad(180.0)
	ctrl.target_pitch = deg_to_rad(50.0)

	ctrl.center_camera()
	assert(absf(ctrl.target_yaw - deg_to_rad(45.0)) < 0.001, "Centrado debe alinear yaw al avión")
	assert(absf(ctrl.target_pitch - OrbitCamera.DEFAULT_PITCH) < 0.001, "Centrado debe restaurar 12° de pitch")

	dummy_player.free()
	print("  [PASS] test_centering")

func test_cycle_and_recovery() -> void:
	var ctrl = OrbitCamera.new()
	var dummy_player = Node3D.new()
	var dummy_wingman = Node3D.new()
	var dummy_escort = Node3D.new()

	ctrl.setup(dummy_player, [dummy_wingman], [dummy_escort])
	assert(ctrl.target_list.size() == 3, "Debe tener 3 objetivos")

	ctrl.cycle_target(1, null)
	assert(ctrl.target_index == 1, "Debe ciclar al wingman")
	assert(ctrl.target_name == "Aurora Dos", "Nombre de wingman correcto")

	ctrl.cycle_target(1, null)
	assert(ctrl.target_index == 2, "Debe ciclar al escolta")

	ctrl.cycle_target(-1, null)
	assert(ctrl.target_index == 1, "Debe retroceder al wingman")

	# Simular eliminación del nodo wingman
	dummy_wingman.free()
	ctrl._validate_targets()
	assert(ctrl.target_index == 0, "Objetivo eliminado debe recuperar Aurora Uno de forma segura")
	assert(ctrl.target_node == dummy_player, "Nodo activo debe ser el jugador")

	dummy_escort.free()
	dummy_player.free()
	print("  [PASS] test_cycle_and_recovery")

func test_timestep_stability() -> void:
	var ctrl = OrbitCamera.new()
	var dummy_player = Node3D.new()
	var cam = Camera3D.new()
	root.add_child(dummy_player)
	root.add_child(cam)
	ctrl.setup(dummy_player, [], [])
	ctrl.set_exterior(true, null)

	for hz in [30.0, 60.0, 120.0]:
		var dt: float = 1.0 / hz
		for frame in range(120):
			ctrl.update(dt, cam, 0.0)
			assert(not is_nan(cam.position.x), "Posición no debe ser NaN a %d Hz" % int(hz))
			assert(not is_inf(cam.position.x), "Posición no debe ser Inf a %d Hz" % int(hz))

	cam.queue_free()
	dummy_player.queue_free()
	print("  [PASS] test_timestep_stability")

func test_autopilot_on_observation() -> void:
	var ctrl = OrbitCamera.new()
	var dummy_player = Node3D.new()
	var dummy_wingman = Node3D.new()

	var mock_sim = {
		"autopilot": false,
		"pitch_input": 1.0,
		"turn_input": -0.5,
		"throttle_input": 0.8
	}

	ctrl.setup(dummy_player, [dummy_wingman], [])
	ctrl.cycle_target(1, mock_sim)
	assert(mock_sim.autopilot == true, "Observar avión debe activar autopiloto")
	assert(mock_sim.pitch_input == 0.0, "Entradas de vuelo deben neutralizarse")
	assert(ctrl.observation_message.contains("OBSERVANDO AURORA DOS"), "Mensaje de observación correcto")

	dummy_wingman.free()
	dummy_player.free()
	print("  [PASS] test_autopilot_on_observation")
