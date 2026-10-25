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

func test_variant(fighter_script: Script, variant_name: String) -> void:
	var fighter = fighter_script.new() as Node3D
	fighter.set("variant", variant_name)
	root.add_child(fighter)
	await process_frame
	await process_frame

	var expected_path = "res://assets/aircraft/models/" + variant_name + ".glb"
	var model: Node3D = null
	for child in descendants(fighter):
		if child is Node3D and child.scene_file_path == expected_path:
			model = child
			break
	check(model != null, variant_name + ": instantiates " + expected_path)

	if model != null:
		for child in descendants(fighter):
			if child is MeshInstance3D and child.mesh != null and not model.is_ancestor_of(child):
				check(false, variant_name + ": duplicate geometry outside imported model: " + str(child.get_path()))

		var rotors = model.find_children("Rotor_*", "Node3D", true, false)
		check(rotors.size() == 1, variant_name + ": model contains 1 rotor")
		check("rotor" in fighter and fighter.rotor != null, variant_name + ": fighter.rotor is not null")
		if rotors.size() == 1 and fighter.rotor != null:
			check(fighter.rotor == rotors[0], variant_name + ": fighter.rotor matches GLB rotor")
			var r0: float = fighter.rotor.rotation.z
			fighter._process(0.1)
			var r1: float = fighter.rotor.rotation.z
			check(absf(wrapf(r1 - r0, -PI, PI)) > 0.001, variant_name + ": rotor animates in _process")

	root.remove_child(fighter)
	fighter.queue_free()

func run() -> void:
	var script = load("res://visuals/fighter.gd") as Script
	check(script != null, "fighter.gd loads")
	if script == null:
		finish()
		return

	await test_variant(script, "bf109g")
	await test_variant(script, "fw190a")

	for frame in range(6):
		await process_frame
		await physics_frame
	finish()

func finish() -> void:
	if failures.is_empty():
		print("TEST PASS: fighter glb integration")
		quit(0)
	else:
		print("TEST FAIL: fighter glb integration: %d failures" % failures.size())
		quit(1)
