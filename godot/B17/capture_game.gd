extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var scene = load("res://game.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    for i in range(120):
        scene._physics_process(1.0/60.0)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var error := image.save_png("/home/test-bench/Documents/B17-project/logs/godot-final-preview.png")
    print("Game preview saved: ",error)
    quit(0)
