extends SceneTree
# Inspección de un GLB de Meshy: mallas, caras, materiales, texturas, tamaño, y capturas desde 4 vistas.
# Uso: godot --path godot/B17 --script <este archivo> -- <ruta res:// o absoluta del .glb> <carpeta_capturas> <envergadura_real_m>
# Necesita GPU (render real). Autor: Claude (herramienta de revisión, no código del juego).

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var a := OS.get_cmdline_user_args()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(a[0], state)
	if err != OK:
		print("INSPECCION FALLO: no se pudo leer ", a[0], " error ", err)
		quit(1)
		return
	var model: Node3D = doc.generate_scene(state)
	root.add_child(model)
	var meshes := 0
	var faces := 0
	var materials := {}
	var textured := 0
	var aabb := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		meshes += 1
		for s in mi.mesh.get_surface_count():
			faces += mi.mesh.surface_get_array_len(s) / 3 if mi.mesh.surface_get_format(s) & Mesh.ARRAY_FORMAT_INDEX == 0 else mi.mesh.surface_get_array_index_len(s) / 3
			var mat := mi.get_active_material(s)
			if mat:
				materials[mat] = true
				if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture:
					textured += 1
		var box := mi.global_transform * mi.get_aabb()
		aabb = box if first else aabb.merge(box)
		first = false
	var span := float(a[2]) if a.size() > 2 else 0.0
	var longest := maxf(aabb.size.x, aabb.size.z)
	print("INSPECCION %s" % a[0].get_file())
	print("  mallas=%d caras=%d materiales=%d con_textura=%d" % [meshes, faces, materials.size(), textured])
	print("  tamaño=%s  eje_largo=%s" % [aabb.size, "X" if aabb.size.x >= aabb.size.z else "Z"])
	if span > 0.0:
		print("  escala sugerida para %.1f m de envergadura: %.4f" % [span, span / maxf(aabb.size.x, 0.001)])
	# Capturas: frente, lado, arriba, 3/4.
	var cam := Camera3D.new()
	root.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	sun.light_energy = 0.8
	root.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.5, 0.55)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.35, 0.35, 0.35)
	root.add_child(env)
	var c := aabb.get_center()
	var r := aabb.size.length()
	var views := {"frente": Vector3(0, 0.15, -1), "lado": Vector3(1, 0.1, 0), "arriba": Vector3(0.001, 1, 0), "tres_cuartos": Vector3(0.8, 0.5, -0.9)}
	DirAccess.make_dir_recursive_absolute(a[1])
	for name in views:
		cam.position = c + (views[name] as Vector3).normalized() * r * 0.7
		cam.look_at(c, Vector3.UP if name != "arriba" else Vector3.FORWARD)
		await process_frame
		await process_frame
		root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [a[1], name])
	print("  capturas en ", a[1])
	quit(0)
