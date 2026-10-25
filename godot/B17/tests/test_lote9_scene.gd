extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.sim.flight.position = Vector3(0, 1200, -5000)
	scene.sim.mission.phase = "APROXIMACION"
	for frame in range(900): scene._physics_process(1.0 / 60.0)
	assert(scene.fighter_visuals.size() == 48 and scene.sim.combat.fighters.size() == 48)
	assert(scene.escort_visuals.size() == 16 and scene.get_node("Formation").wingmen.size() == 5)
	var ids: Array = []
	for i in range(48):
		ids.append(scene.fighter_visuals[i].get_instance_id())
		assert(scene.fighter_visuals[i].position == scene.sim.combat.fighters[i]["ai"].position)
		assert(scene.fighter_visuals[i].variant == scene.sim.combat.fighters[i]["variant"])
	var first = scene.sim.combat.fighters[0]["ai"]
	for station in ["PILOTO", "ARTILLERO", "BOMBARDERO"]: scene.controls.set_station(station, scene.sim)
	assert(first == scene.sim.combat.fighters[0]["ai"])
	scene.tracer_pool.fire(Vector3.ZERO, Vector3.FORWARD)
	scene.tracer_pool.flash(Vector3.ZERO)
	scene.set_pause(true)
	var position: Vector3 = first.position
	var rotor: float = scene.fighter_visuals[0].rotor.rotation.z
	for frame in range(60): scene._physics_process(1.0 / 60.0)
	assert(first.position == position and scene.fighter_visuals[0].rotor.rotation.z == rotor)
	for mesh in scene.tracer_pool.meshes: assert(not mesh.visible)
	for flash in scene.tracer_pool.flashes: assert(not flash.visible)
	scene.set_pause(false)
	scene._physics_process(1.0 / 60.0)
	scene.restart_mission()
	assert(scene.sim.combat.fighters.is_empty() and scene.tracer_pool.active_count() == 0)
	for i in range(48): assert(ids[i] == scene.fighter_visuals[i].get_instance_id())
	assert(scene.orbit_camera.target_list.size() == 22)
	print("TEST PASS: Lote9 visual 1:1, reusable models, pause flashes/rotors, reset and station continuity")
	scene.queue_free()
	await process_frame
	quit()
