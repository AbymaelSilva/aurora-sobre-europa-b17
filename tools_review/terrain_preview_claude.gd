extends SceneTree
# Vista previa GPU (Claude) de una textura de terreno candidata SIN tocar producción:
# sustituye en tiempo de ejecución la textura y el tamaño de mosaico del shader de $Ground.
# Uso: tools/godot --path godot/B17 --resolution 1280x720 --script res://../../tools_review/terrain_preview_claude.gd -- <png absoluto|actual> <metros_mosaico> <dir salida> <prefijo>
var scene: Node
var out := ""
var prefix := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 4 or DisplayServer.get_name() == "headless":
		printerr("terrain_preview_claude: <png|actual> <metros> <dir> <prefijo>, con ventana")
		quit(1)
		return
	out = a[2]
	prefix = a[3]
	run.call_deferred(a[0], float(a[1]))

func snap(label: String) -> void:
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s_%s.png" % [out, prefix, label])
	print("captura ", prefix, "_", label)

func run(png: String, tile_m: float) -> void:
	scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var mat: ShaderMaterial = scene.get_node("Ground").material_override
	if png != "actual":
		var img := Image.load_from_file(png)
		img.generate_mipmaps()
		mat.set_shader_parameter("farmland_texture", ImageTexture.create_from_image(img))
		var sh := Shader.new()
		sh.code = mat.shader.code.replace("/2800.0", "/%.1f" % tile_m)
		mat.shader = sh
	for i in range(30):
		await process_frame
	scene.sim.autopilot = true
	scene.controls.set_station("PILOTO", scene.sim)
	await snap("persecucion")
	scene.controls.set_station("BOMBARDERO", scene.sim)
	scene.update_presentation(0.0)
	await snap("bombardero_cenital")
	scene.controls.set_station("PILOTO", scene.sim)
	scene.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
