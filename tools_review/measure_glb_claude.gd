extends SceneTree
# Revisión Claude (no es código del juego): mide los GLB importados.
# Uso: tools/godot --headless --path godot/B17 --script <abs>/measure_glb_claude.gd -- <salida.json>

const MODELS := ["b17g", "bf109g", "fw190a", "p51d"]

func _initialize() -> void:
	run.call_deferred()

func merged_aabb(root_node: Node3D, ref: Node3D, skip_rotors: bool) -> AABB:
	var inv := ref.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for n in root_node.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if skip_rotors and _under_rotor(mi):
			continue
		var b: AABB = (inv * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func _under_rotor(n: Node) -> bool:
	var p := n
	while p != null:
		if String(p.name).begins_with("Rotor"):
			return true
		p = p.get_parent()
	return false

func run() -> void:
	var out_path: String = OS.get_cmdline_user_args()[0]
	var report := {}
	for m in MODELS:
		var ps: PackedScene = load("res://assets/aircraft/models/%s.glb" % m)
		var inst: Node3D = ps.instantiate()
		root.add_child(inst)
		var r := {}
		var tree := []
		for n in inst.find_children("*", "", true, false):
			tree.append("%s:%s pos=%s" % [inst.get_path_to(n), n.get_class(), (n as Node3D).position if n is Node3D else ""])
		r["tree"] = tree
		var whole := merged_aabb(inst, inst, false)
		var body := merged_aabb(inst, inst, true)
		r["aabb_all"] = [whole.position, whole.size]
		r["aabb_sin_rotores"] = [body.position, body.size]
		r["envergadura_x"] = body.size.x
		r["longitud_z"] = body.size.z
		r["morro_z_min"] = body.position.z
		r["cola_z_max"] = body.end.z
		r["techo_y_max"] = body.end.y
		r["suelo_y_min"] = body.position.y
		var rotors := []
		for n in inst.find_children("Rotor*", "Node3D", true, false):
			var rn := n as Node3D
			if not String(rn.name).begins_with("Rotor"):
				continue
			var rb := merged_aabb(rn, rn, false)
			var meshes := rn.find_children("*", "MeshInstance3D", true, false)
			var axis_local_z: Vector3 = (inst.global_transform.affine_inverse().basis * rn.global_transform.basis).z.normalized()
			rotors.append({
				"name": String(rn.name),
				"pos": inst.global_transform.affine_inverse() * rn.global_position,
				"rot": rn.rotation, "scale": rn.scale,
				"diam_xy": maxf(rb.size.x, rb.size.y), "aabb": [rb.position, rb.size],
				"mesh_children": meshes.size(), "direct_children": rn.get_child_count(),
				"eje_z_vs_longitudinal_deg": rad_to_deg(acos(clampf(absf(axis_local_z.dot(Vector3.BACK)), 0, 1)))})
		r["rotors"] = rotors
		var mats := []
		for n in inst.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				var d := {"mesh": String(inst.get_path_to(mi)), "surf": s}
				if mat is BaseMaterial3D:
					var bm := mat as BaseMaterial3D
					d["tex"] = bm.albedo_texture.resource_path if bm.albedo_texture else ""
					d["cull"] = bm.cull_mode
					d["metal"] = bm.metallic
					d["rough"] = bm.roughness
					d["color"] = bm.albedo_color
				mats.append(d)
		r["materials"] = mats
		report[m] = r
		inst.queue_free()
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("MEDICION_OK ", out_path)
	quit(0)
