extends SceneTree
# Capturas GPU (Claude) del menú de pausa y del HUD en manual para los 3 perfiles. No modifica producción.
# Uso: tools/godot --path godot/B17 --resolution 1280x720 --script res://../../tools_review/capture_profiles_claude.gd -- <dir absoluto>
var out := ""
var scene: Node

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name() == "headless":
		printerr("capture_profiles_claude: requiere ventana y carpeta de salida")
		quit(1)
		return
	out = String(args[0])
	run.call_deferred()

func snap(label: String) -> void:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, label])
	print("captura ", label)

func run() -> void:
	scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	for i in range(30):
		await process_frame
	scene.sim.autopilot = false
	for prof in ["TECLADO_RATON", "XBOX", "ROG_ALLY_X"]:
		scene.controls.profile = prof
		scene.settings_menu.set_profile(prof)
		scene.set_pause(false)
		scene.update_presentation(0.0)
		await snap("hud_manual_" + prof)
		scene.set_pause(true)
		await snap("menu_" + prof)
	scene.set_pause(false)
	scene.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
