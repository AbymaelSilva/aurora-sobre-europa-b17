extends SceneTree

var failures: PackedStringArray = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		print("FAIL: ", message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var script = load("res://visuals/engine_anchors.gd") as Script
	check(script != null, "engine_anchors.gd loads")
	if script == null:
		finish()
		return

	var scene_res = load("res://assets/aircraft/models/b17g.glb") as PackedScene
	check(scene_res != null, "b17g.glb loads")
	if scene_res == null:
		finish()
		return

	var aircraft := Node3D.new()
	root.add_child(aircraft)
	var model: Node3D = scene_res.instantiate()
	aircraft.add_child(model)

	await process_frame
	await process_frame

	var sorted = script.get_sorted_rotors(aircraft)
	check(sorted.size() == 4, "finds 4 sorted rotors")
	if sorted.size() == 4:
		for i in range(3):
			var x_a: float = aircraft.to_local(sorted[i].global_position).x
			var x_b: float = aircraft.to_local(sorted[i + 1].global_position).x
			check(x_a < x_b, "rotors strictly ordered by local x: %f < %f" % [x_a, x_b])

		var smoke_pos = script.get_smoke_positions(aircraft)
		check(smoke_pos.size() == 4, "returns 4 smoke positions")
		for i in range(4):
			var r_loc: Vector3 = aircraft.to_local(sorted[i].global_position)
			var s_loc: Vector3 = aircraft.to_local(smoke_pos[i])
			check(absf(s_loc.x - r_loc.x) < 0.25, "smoke local x matches rotor local x")

		var shift := Vector3(2.0, 1.0, -1.5)
		model.position += shift
		var moved_pos = script.get_smoke_positions(aircraft)
		for i in range(4):
			var expected: Vector3 = aircraft.to_local(sorted[i].global_position)
			var actual: Vector3 = aircraft.to_local(moved_pos[i])
			check(absf(actual.x - expected.x) < 0.05, "smoke follows model position shift")

	root.remove_child(aircraft)
	aircraft.queue_free()

	for frame in range(6):
		await process_frame
		await physics_frame
	finish()

func finish() -> void:
	if failures.is_empty():
		print("TEST PASS: engine anchors")
		quit(0)
	else:
		print("TEST FAIL: engine anchors: %d failures" % failures.size())
		quit(1)
