extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func fail(msg: String) -> void:
    print("TEST FAIL: ", msg)
    quit(1)

func run_checks() -> void:
    var script = load("res://audio/combat_sfx.gd")
    if not script:
        fail("could not load res://audio/combat_sfx.gd")
        return

    var gun = script.create_gun_stream()
    if not (gun is AudioStreamWAV) or gun.data.size() < 1000:
        fail("invalid gun stream")
        return

    var flak = script.create_flak_stream()
    if not (flak is AudioStreamWAV) or flak.data.size() < 1000:
        fail("invalid flak stream")
        return

    var bomb = script.create_bomb_stream()
    if not (bomb is AudioStreamWAV) or bomb.data.size() < 1000:
        fail("invalid bomb stream")
        return

    # Check distinct streams
    if gun == flak or gun == bomb or flak == bomb:
        fail("streams are not distinct")
        return

    print("TEST PASS: combat_sfx procedural audio streams generated correctly")
    quit(0)
