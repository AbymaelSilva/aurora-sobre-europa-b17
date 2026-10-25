extends SceneTree
# Revisión H-11 (Claude): cierre con ventana, GPU y audio reales.
# Uso: tools/godot --path godot/B17 --verbose --script res://../../tools_review/wm_close_leak_claude.gd -- <wm|quit>
#   wm   = envía NOTIFICATION_WM_CLOSE_REQUEST a la escena (la misma rama que el botón de cerrar).
#   quit = control: quit() directo, como --quit-after (camino antiguo con fuga).
# No modifica producción. Buscar «ObjectDB instances were leaked» en la salida.

var mode := "wm"
var scene: Node

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		mode = String(args[0])
	if DisplayServer.get_name() == "headless":
		printerr("wm_close_leak_claude: requiere ventana y audio reales")
		quit(1)
		return
	run.call_deferred()

func run() -> void:
	scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	for i in range(180):
		await process_frame
	print("modo=%s motor_sonando=%s" % [mode, scene.engine_audio.playing])
	if mode == "wm":
		scene.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	else:
		quit()
