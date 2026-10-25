extends SceneTree
# Los 4 modelos 3D de avión se importan, cargan como escena, tienen textura y rotores con nombre Rotor_*. Autor: Claude.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var fails := 0
	var specs := {"b17g": [31.62, 4], "bf109g": [9.92, 1], "fw190a": [10.51, 1], "p51d": [11.28, 1]}
	for name in specs:
		var ps := load("res://assets/aircraft/models/%s.glb" % name) as PackedScene
		if ps == null:
			print("FAIL %s: no se importó" % name); fails += 1; continue
		var inst: Node3D = ps.instantiate()
		root.add_child(inst)
		var rotors := inst.find_children("Rotor_*", "", true, false)
		var textured := false
		var aabb := AABB(); var first := true
		for n in inst.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			var mat := mi.get_active_material(0)
			if mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_texture: textured = true
			var b := mi.global_transform * mi.get_aabb()
			aabb = b if first else aabb.merge(b); first = false
		var want_span: float = specs[name][0]
		var ok_span: bool = absf(aabb.size.x - want_span) < want_span * 0.03
		print("%s: rotores=%d textura=%s envergadura=%.2f m" % [name, rotors.size(), textured, aabb.size.x])
		if rotors.size() != specs[name][1] or not textured or not ok_span:
			print("FAIL %s" % name); fails += 1
		inst.queue_free()
	print("TEST PASS: 4 modelos de avión importados, texturizados, a escala y con rotores" if fails == 0 else "TEST FAIL: %d modelos" % fails)
	quit(1 if fails else 0)
