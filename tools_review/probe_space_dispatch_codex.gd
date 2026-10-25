extends SceneTree
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    var scene = load("res://game.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    scene.sim.autopilot = false
    scene.sim.mission.phase = "BOMBARDEO"
    scene.controls.set_station("BOMBARDERO",scene.sim)
    var down := InputEventKey.new()
    down.keycode = KEY_SPACE
    down.physical_keycode = KEY_SPACE
    down.pressed = true
    Input.parse_input_event(down)
    Input.flush_buffered_events()
    await process_frame
    var up := down.duplicate() as InputEventKey
    up.pressed = false
    Input.parse_input_event(up)
    Input.flush_buffered_events()
    await process_frame
    var ok: bool = scene.sim.bomb.spent and scene.sim.bomb.active
    print("Space Input.parse_input_event routes to actual game: ",ok," bomb=",scene.sim.bomb.result)
    for player in [scene.engine_audio,scene.gun_audio,scene.flak_audio,scene.bomb_audio]:
        player.stop()
        player.stream = null
    root.remove_child(scene)
    scene.free()
    for frame in range(6):
        await process_frame
        await physics_frame
    print("TEST PASS: physical Space dispatch precondition" if ok else "TEST FAIL: Space dispatch precondition")
    quit(0 if ok else 1)
