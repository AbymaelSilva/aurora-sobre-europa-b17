extends SceneTree
# Capturas reales (GPU, ventana) del menu principal, Opciones y la pausa
# nuevos. Revision visual; no es prueba de aprobado/suspenso.
# Uso: tools/godot --path godot/B17 --resolution 1280x720 --script res://tests/capture_menus_claude.gd -- <carpeta absoluta>

var out := ""
var taken := {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or not String(args[0]).is_absolute_path():
		printerr("capture_menus_claude: falta la carpeta de salida absoluta tras '--'")
		quit(1)
		return
	if DisplayServer.get_name() == "headless" or RenderingServer.get_rendering_device() == null:
		printerr("capture_menus_claude: requiere ventana y GPU (no headless); display=%s" % DisplayServer.get_name())
		quit(1)
		return
	out = args[0]
	run.call_deferred()

func snap(label: String) -> void:
	if taken.has(label):
		return
	taken[label] = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, taken.size(), label])
	print("captura %s" % label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)

	# --- Menu principal ---
	var menu = load("res://main_menu.tscn").instantiate()
	root.add_child(menu)
	for i in 3: await process_frame
	await snap("menu_principal")

	menu._open_options()
	for i in 3: await process_frame
	await snap("menu_opciones_audio")
	var tabs: TabContainer = menu.options_menu.find_child("Tabs", true, false)
	tabs.current_tab = 1
	await process_frame
	await snap("menu_opciones_video")
	tabs.current_tab = 2
	await process_frame
	await snap("menu_opciones_controles")
	tabs.current_tab = 3
	await process_frame
	await snap("menu_opciones_jugabilidad")
	tabs.current_tab = 4
	await process_frame
	await snap("menu_opciones_accesibilidad")
	menu.options_menu.closed.emit()
	await process_frame

	menu._open_credits()
	for i in 3: await process_frame
	await snap("menu_creditos")
	menu.credits_panel.visible = false
	menu.queue_free()
	for i in 3: await process_frame

	# --- Partida real, para demostrar que el juego sigue corriendo con los cambios ---
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var dt := 1.0 / 60.0
	for frame in range(300):
		scene._physics_process(dt)
	await snap("partida_en_curso")

	scene.set_pause(true)
	await process_frame
	await snap("pausa_reestructurada")

	scene.settings_menu.options_requested.emit()
	for i in 3: await process_frame
	await snap("pausa_opciones_abiertas")
	scene.options_menu.closed.emit()
	await process_frame

	# Confirmacion de reinicio (BAJO 1.3): primer clic arma, se ve el aviso.
	scene.settings_menu.restart_button.emit_signal("pressed")
	await process_frame
	await snap("pausa_confirmar_reinicio")

	print("capturas: ", taken.size())
	scene.queue_free()
	await process_frame
	quit(0)
