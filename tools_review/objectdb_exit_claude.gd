extends SceneTree
# Investigación H-11 (Claude, fuera del juego). Modo por argumento:
#   en_arbol  : quit() con la escena aún en el árbol (equivale a cerrar la ventana del juego)
#   liberar   : queue_free de la escena, 1 frame, quit()
#   crecimiento: misión demo + 5 reinicios (R) midiendo Performance.OBJECT_* sin salir antes
func _initialize() -> void:
	run.call_deferred()

func counts() -> String:
	return "objetos=%d recursos=%d nodos=%d huerfanos=%d" % [Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)]

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "en_arbol"
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	for a in ["engine_audio", "gun_audio", "flak_audio", "bomb_audio"]:
		var p: AudioStreamPlayer = scene.get(a)
		print("stream %s id=%d" % [a, p.stream.get_instance_id()])
	print("audio driver=%s" % AudioServer.get_driver_name())
	if mode == "crecimiento":
		for cycle in 6:
			for frame in range(60 * 1500):
				scene._physics_process(1.0 / 60.0)
				if frame % 600 == 0:
					await process_frame
				if scene.sim.mission.phase in ["COMPLETADA", "FALLIDA"]:
					break
			for i in 10:
				await process_frame
			print("ciclo %d fase=%s %s" % [cycle, scene.sim.mission.phase, counts()])
			scene.restart_mission()
	else:
		for frame in 180:
			scene._physics_process(1.0 / 60.0)
			await process_frame
		print("antes_salida %s" % counts())
	if mode == "liberar":
		scene.queue_free()
		await process_frame
	quit(0)
