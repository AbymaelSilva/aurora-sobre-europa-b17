extends SceneTree
# Corrida real con ventana y GPU (no headless) que demuestra visualmente,
# con capturas de pantalla reales del HUD, que remapeo y dificultad cambian
# la partida de verdad. Complementa verify_mejoras_jugabilidad.gd (headless).
# Uso: tools/godot --path godot/B17 --resolution 1280x720 --script res://tests/capture_verificacion_jugabilidad.gd -- <carpeta absoluta>

const InputActions = preload("res://core/input_actions.gd")

var out := ""
var taken := {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or not String(args[0]).is_absolute_path():
		printerr("falta la carpeta de salida absoluta tras '--'")
		quit(1)
		return
	if DisplayServer.get_name() == "headless" or RenderingServer.get_rendering_device() == null:
		printerr("requiere ventana y GPU (no headless); display=%s" % DisplayServer.get_name())
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
	await verify_remap_window()
	await verify_difficulty_window()
	print("capturas: ", taken.size())
	quit(0)

func verify_remap_window() -> void:
	InputActions.ensure_defaults()
	InputActions.reset_to_defaults()
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	for i in 3: await process_frame
	await snap("01_remap_puesto_piloto_inicial")

	InputActions.rebind("b17_bombardero", KEY_9)
	var ev3 := InputEventKey.new()
	ev3.physical_keycode = KEY_3
	ev3.pressed = true
	scene._unhandled_input(ev3)
	scene.update_presentation(0.0)
	for i in 3: await process_frame
	await snap("02_remap_tecla_3_ya_no_cambia_puesto")

	var ev9 := InputEventKey.new()
	ev9.physical_keycode = KEY_9
	ev9.pressed = true
	scene._unhandled_input(ev9)
	scene.update_presentation(0.0)
	for i in 3: await process_frame
	await snap("03_remap_tecla_9_cambia_a_bombardero")

	InputActions.reset_to_defaults()
	scene.queue_free()
	await process_frame

func run_to_bombing_window(difficulty: String, label: String) -> void:
	seed(1945)
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	for i in 3: await process_frame
	scene._on_setting_changed("difficulty", difficulty)
	var dt := 1.0 / 60.0
	for frame in range(60 * 170):
		scene._physics_process(dt)
		if scene.sim.mission.phase == "BOMBARDEO" and scene.sim.flak.bursts >= 6:
			break
	scene.update_presentation(0.0)
	for i in 3: await process_frame
	print("%s -> hull=%.2f%% bursts=%d flak_damage=%.3f" % [label, scene.sim.damage.hull, scene.sim.flak.bursts, scene.sim.flak_damage])
	await snap(label)
	scene.queue_free()
	await process_frame

func verify_difficulty_window() -> void:
	await run_to_bombing_window("FACIL", "04_dificultad_facil_hud")
	await run_to_bombing_window("DIFICIL", "05_dificultad_dificil_hud")
