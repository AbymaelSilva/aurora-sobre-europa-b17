extends SceneTree

func _initialize() -> void:
    call_deferred("verify")

func fail(message: String) -> void:
    print("TEST FAIL: ",message)
    quit(1)

func verify() -> void:
    var damage = load("res://damage_model.gd").new()
    damage.apply_damage(-25.0)
    if damage.hull != 100.0:
        fail("negative damage")
        return
    damage.apply_damage(20.0)
    if damage.hull != 80.0 or damage.engine != 70.0 or damage.thrust_factor() >= 1.0:
        fail("damage or engine thrust")
        return
    damage.apply_damage(1000.0)
    if not damage.destroyed() or damage.hull != 0.0 or damage.engine != 0.0:
        fail("lethal damage or clamp")
        return
    damage.reset()
    if damage.destroyed() or damage.hull != 100.0 or damage.engine != 100.0:
        fail("damage reset")
        return
    var flak = load("res://flak_model.gd").new()
    for i in range(600):
        if flak.step(1.0/60.0,false):
            fail("flak outside zone")
            return
    if flak.bursts != 0:
        fail("unexpected bursts")
        return
    for rate in [30,60,120]:
        var scene = load("res://combat.tscn").instantiate()
        root.add_child(scene)
        scene.set_physics_process(false)
        scene.paused = true
        for i in range(120): scene._physics_process(1.0/float(rate))
        if scene.flak.bursts != 0 or scene.damage.hull != 100.0:
            fail("pause did not freeze threats")
            return
        scene.paused = false
        for i in range(300*rate):
            scene._physics_process(1.0/float(rate))
            if scene.mission.phase in ["COMPLETADA","FALLIDA"]: break
        if scene.mission.phase != "COMPLETADA" or scene.flak.bursts < 3 or scene.damage.hull >= 100.0 or scene.damage.hull <= 0.0 or scene.flight.speed >= 50.0:
            fail("survivable mission at "+str(rate)+" phase="+scene.mission.phase+" bursts="+str(scene.flak.bursts))
            return
        var event := InputEventKey.new()
        event.physical_keycode = KEY_R
        event.pressed = true
        scene._unhandled_input(event)
        if scene.damage.hull != 100.0 or scene.flak.bursts != 0 or scene.bomb.spent:
            fail("full reset after damage")
            return
        scene.flak_damage = 100.0
        for i in range(180*rate):
            scene._physics_process(1.0/float(rate))
            if scene.mission.phase == "FALLIDA": break
        if scene.mission.phase != "FALLIDA" or not scene.damage.destroyed():
            fail("lethal combat must fail mission")
            return
        var stopped_time: float = scene.elapsed
        var stopped_position: Vector3 = scene.flight.position
        for i in range(60): scene._physics_process(1.0/float(rate))
        if scene.elapsed != stopped_time or scene.flight.position != stopped_position:
            fail("failed mission must stop flight")
            return
        scene.free()
    print("TEST PASS: hull/engine damage, clamps/reset, safe zones, pause, survivable and lethal missions at 30/60/120 steps per second")
    quit(0)
