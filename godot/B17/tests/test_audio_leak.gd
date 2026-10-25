extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	for i in range(60):
		scene._physics_process(1.0 / 60.0)
		await process_frame

	for player in [scene.engine_audio, scene.gun_audio, scene.flak_audio, scene.bomb_audio]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	root.remove_child(scene)
	scene.free()
	scene = null
	for frame in range(6):
		await process_frame
		await physics_frame
	quit(0)
