extends SceneTree
# Copia de un GLB con el winding unificado (convención de Godot: el winding contrario a la normal de vértice es la cara frontal).
# Las alas, estabilizadores y parte de la deriva de loft_aircraft.gd salen con el winding al revés: en glTF miran hacia dentro
# y Meshy las trata como caras traseras (no las pinta). Solo cambia el orden de los índices; posiciones, normales, UV, nodos iguales.
# Uso: tools/godot --headless --path /tmp/meshy_proj --script tools_art/fix_winding_for_meshy.gd -- <entrada.glb> <salida.glb>
# Autor: Claude (herramienta de arte; no es código del juego).

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	if doc.append_from_file(a[0], st) != OK: quit(1); return
	var scene: Node3D = doc.generate_scene(st)
	var flipped := 0
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var nm := ArrayMesh.new()
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nr = arr[Mesh.ARRAY_NORMAL]
			var idx = arr[Mesh.ARRAY_INDEX]
			if idx == null: idx = PackedInt32Array(range(v.size()))
			if nr != null:
				for k in range(0, idx.size(), 3):
					var g := (v[idx[k + 1]] - v[idx[k]]).cross(v[idx[k + 2]] - v[idx[k]])
					var vn: Vector3 = nr[idx[k]] + nr[idx[k + 1]] + nr[idx[k + 2]]
					if g.dot(vn) > 0.0:
						var t: int = idx[k + 1]; idx[k + 1] = idx[k + 2]; idx[k + 2] = t
						flipped += 1
			arr[Mesh.ARRAY_INDEX] = idx
			nm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, 0)
			nm.surface_set_material(s, mi.mesh.surface_get_material(s))
			nm.surface_set_name(s, mi.mesh.surface_get_name(s))
		nm.resource_name = mi.mesh.resource_name
		mi.mesh = nm
	for c in scene.find_children("*", "", true, false): c.owner = scene
	var d2 := GLTFDocument.new(); var s2 := GLTFState.new()
	d2.append_from_scene(scene, s2)
	var err := d2.write_to_filesystem(s2, a[1])
	print("WINDING triángulos invertidos=%d -> %s (%s)" % [flipped, a[1], "OK" if err == OK else "ERROR %d" % err])
	quit(0 if err == OK else 1)
