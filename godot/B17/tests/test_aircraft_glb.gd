extends SceneTree

var failures: PackedStringArray = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		print("FAIL: ", message)

func descendants(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child in node.get_children():
		found.append(child)
		found.append_array(descendants(child))
	return found

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var script = load("res://aircraft.gd") as Script
	check(script != null, "aircraft.gd loads")
	if script == null:
		finish()
		return
	var aircraft = script.new() as Node3D
	root.add_child(aircraft)
	await process_frame
	await process_frame

	var model: Node3D = null
	for child in descendants(aircraft):
		if child is Node3D and child.scene_file_path == "res://assets/aircraft/models/b17g.glb":
			model = child
			break
	check(model != null, "aircraft.gd instantiates res://assets/aircraft/models/b17g.glb")

	if model != null:
		for child in descendants(aircraft):
			if child is MeshInstance3D and child.mesh != null and not model.is_ancestor_of(child):
				check(false, "duplicate/unassigned geometry outside imported model: " + str(child.get_path()))

		var rotors = model.find_children("Rotor_*", "Node3D", true, false)
		check(rotors.size() == 4, "model contains 4 rotors")

		var engines = aircraft.get_node_or_null("Engines")
		check(engines != null, "Engines node exists")
		if engines != null and rotors.size() == 4:
			engines.set_process(false)
			await process_frame
			var r0: float = rotors[0].rotation.z
			await create_timer(0.05).timeout
			var r1: float = rotors[0].rotation.z
			check(absf(wrapf(r1 - r0, -PI, PI)) < 0.0001, "rotors paused when Engines process is disabled")

			engines.set_process(true)
			await process_frame
			await create_timer(0.05).timeout
			var r2: float = rotors[0].rotation.z
			check(absf(wrapf(r2 - r1, -PI, PI)) > 0.001, "rotors animate when Engines process is enabled")

	root.remove_child(aircraft)
	aircraft.queue_free()
	aircraft = null
	for frame in range(6):
		await process_frame
		await physics_frame
	finish()

func finish() -> void:
	if failures.is_empty():
		print("TEST PASS: aircraft glb integration")
		quit(0)
	else:
		print("TEST FAIL: aircraft glb integration: %d failures" % failures.size())
		quit(1)
