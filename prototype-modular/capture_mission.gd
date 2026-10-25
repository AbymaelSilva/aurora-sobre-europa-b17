extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func save_frame(path: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var error := image.save_png(path)
    if error != OK:
        push_error("Could not save mission preview")

func capture() -> void:
    var scene = load("res://mission.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    for i in range(500):
        scene._physics_process(1.0/60.0)
    await save_frame("/home/test-bench/Documents/B17-project/logs/mission-approach.png")
    for i in range(2400):
        scene._physics_process(1.0/60.0)
        if scene.bomb.active and scene.bomb.position.y < 25.0:
            break
    await save_frame("/home/test-bench/Documents/B17-project/logs/mission-bomb.png")
    print("Mission previews saved; phase=",scene.mission.phase," bomb=",scene.bomb.result)
    quit(0)
