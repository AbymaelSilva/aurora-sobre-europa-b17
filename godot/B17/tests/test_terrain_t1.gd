extends SceneTree

# Test para Tarea A (Lote 5): terreno nuevo farmland_t1.png y escala de shader 1200.0

func _initialize() -> void:
	call_deferred("run_checks")

func fail(msg: String) -> void:
	print("TEST FAIL: ", msg)
	quit(1)

func run_checks() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)

	var ground: MeshInstance3D = scene.get_node_or_null("Ground") as MeshInstance3D
	if ground == null:
		fail("No se encontró el nodo $Ground en la escena")
		return

	var mat: ShaderMaterial = ground.material_override as ShaderMaterial
	if mat == null:
		fail("El material_override de $Ground no es un ShaderMaterial")
		return

	var shader: Shader = mat.shader
	if shader == null:
		fail("El ShaderMaterial no tiene shader asignado")
		return

	if not "/1200.0" in shader.code:
		fail("El código del shader no contiene '/1200.0'")
		return

	if "/2800.0" in shader.code:
		fail("El código del shader todavía contiene '/2800.0'")
		return

	var tex: Texture2D = mat.get_shader_parameter("farmland_texture") as Texture2D
	if tex == null:
		fail("El parámetro farmland_texture no está asignado o no es Texture2D")
		return

	if not tex.resource_path.ends_with("farmland_t1.png"):
		fail("farmland_texture no apunta a farmland_t1.png (es %s)" % tex.resource_path)
		return

	scene.free()
	print("TEST PASS: terreno t1 y escala 1200.0 m verificados")
	quit(0)
