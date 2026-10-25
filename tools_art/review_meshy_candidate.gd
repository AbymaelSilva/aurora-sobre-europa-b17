extends SceneTree
# Revisión de un candidato de Meshy frente al modelo actual: AABB, nodos Rotor_* y capturas con GPU (misma cámara).
# Uso (con GPU, sin --headless, en un proyecto temporal):
#   tools/godot --path /tmp/meshy_proj --resolution 1280x720 --script tools_art/review_meshy_candidate.gd -- \
#       <actual.glb> <candidato.glb> <carpeta_capturas> <prefijo>
# Escribe <prefijo>_{actual,candidato}_{tres_cuartos,lateral,planta,panza,detalle}.png y una línea REVIEW con el resultado.
# Autor: Claude (herramienta de revisión, no código del juego).

func _initialize() -> void:
	run.call_deferred()

func _load(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		return null
	return doc.generate_scene(st) as Node3D

func _aabb(scene: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func _rotors(scene: Node) -> Array:
	var r := []
	for n in scene.find_children("Rotor_*", "", true, false):
		r.append("%s@%s" % [n.name, (n as Node3D).position.snapped(Vector3.ONE * 0.001)])
	r.sort()
	return r

func run() -> void:
	var a := OS.get_cmdline_user_args()
	var paths := {"actual": a[0], "candidato": a[1]}
	var out: String = a[2]
	var prefix: String = a[3]
	DirAccess.make_dir_recursive_absolute(out)
	# Entorno con cielo: el metal necesita algo que reflejar.
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	sky.sky_material = psm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 50
	root.add_child(cam)
	var scenes := {}
	for k in paths:
		var s := _load(paths[k])
		if s == null:
			print("REVIEW FALLO no se pudo cargar ", paths[k])
			quit(1)
			return
		scenes[k] = s
	# Cámaras fijadas con la caja del modelo ACTUAL (iguales para ambos).
	root.add_child(scenes["actual"])
	var box := _aabb(scenes["actual"])
	root.remove_child(scenes["actual"])
	var c := box.get_center()
	var r := box.size.length()
	var views := {
		"tres_cuartos": [Vector3(-0.75, 0.35, -0.9), 0.42, Vector3.UP],
		"lateral": [Vector3(-1, 0.02, 0), 0.62, Vector3.UP],
		"planta": [Vector3(0.0, 1, 0.0001), 0.62, Vector3.FORWARD],
		"panza": [Vector3(-0.35, -0.8, -0.45), 0.5, Vector3.UP],
		"detalle": [Vector3(-0.6, 0.3, -0.5), 0.2, Vector3.UP],
	}
	var info := {}
	for k in ["actual", "candidato"]:
		var s: Node3D = scenes[k]
		root.add_child(s)
		await process_frame
		info[k] = {"aabb": _aabb(s), "rotors": _rotors(s)}
		for v in views:
			var spec: Array = views[v]
			var target := c
			if v == "detalle":
				# Morro y motor interior izquierdo, de cerca.
				target = c + Vector3(-box.size.x * 0.12, 0, -box.size.z * 0.3)
			cam.position = target + (spec[0] as Vector3).normalized() * r * float(spec[1])
			cam.look_at(target, spec[2])
			for i in 6:
				await process_frame
			root.get_viewport().get_texture().get_image().save_png("%s/%s_%s_%s.png" % [out, prefix, k, v])
		root.remove_child(s)
	var b0: AABB = info["actual"]["aabb"]
	var b1: AABB = info["candidato"]["aabb"]
	var d := (b1.size - b0.size).abs()
	var rel := maxf(d.x / b0.size.x, maxf(d.y / b0.size.y, d.z / b0.size.z))
	var same_rot: bool = info["actual"]["rotors"] == info["candidato"]["rotors"]
	print("REVIEW %s aabb_actual=%s aabb_candidato=%s dif_rel_max=%.4f%% rotores_actual=%d rotores_candidato=%d mismos=%s -> %s" % [
		prefix, b0.size, b1.size, rel * 100.0, info["actual"]["rotors"].size(), info["candidato"]["rotors"].size(), same_rot,
		"PASS" if rel < 0.01 and same_rot else "FALLO"])
	print("REVIEW rotores=", info["candidato"]["rotors"])
	quit(0)
