extends SceneTree

func _initialize() -> void:
    call_deferred("verify")

func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = true
    return event

func verify() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await physics_frame
    await physics_frame
    scene._unhandled_input(key(KEY_ESCAPE))
    var frozen: Vector3 = scene.flight.position
    for i in range(20):
        await physics_frame
    if not scene.paused or scene.flight.position != frozen:
        print("TEST FAIL: pause does not freeze flight")
        quit(1)
        return
    scene._unhandled_input(key(KEY_R))
    await physics_frame
    if scene.flight.position != Vector3(0,100,0) or scene.flight.speed != 50.0:
        print("TEST FAIL: reset while paused")
        quit(1)
        return
    for i in range(20):
        scene._unhandled_input(key(KEY_ESCAPE))
        scene._unhandled_input(key(KEY_ESCAPE))
        scene._unhandled_input(key(KEY_R))
    if not scene.paused or scene.flight.position != Vector3(0,100,0):
        print("TEST FAIL: repeated pause/reset")
        quit(1)
        return
    if "Pausado" not in scene.get_node("HUD").label.text:
        print("TEST FAIL: pause label")
        quit(1)
        return
    scene._unhandled_input(key(KEY_ESCAPE))
    await physics_frame
    await physics_frame
    if scene.paused or scene.flight.position == Vector3(0,100,0):
        print("TEST FAIL: resume")
        quit(1)
        return
    print("TEST PASS: pause freezes flight, reset, 20 toggle/reset sequences, HUD and resume")
    if DisplayServer.get_name() != "headless":
        await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        var error := image.save_png("/home/test-bench/Documents/B17-project/logs/prototype-preview.png")
        print("Screenshot saved, error code: ", error)
    quit(0)
