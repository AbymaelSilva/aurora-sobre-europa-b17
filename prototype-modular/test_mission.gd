extends SceneTree

func _initialize() -> void:
    call_deferred("verify")

func fail(message: String) -> void:
    print("TEST FAIL: ", message)
    quit(1)

func verify() -> void:
    var bomb = load("res://bomb_model.gd").new()
    if not bomb.release(Vector3(0,100,0),Vector3(0,0,-50)):
        fail("first release rejected")
        return
    if bomb.release(Vector3.ZERO,Vector3.ZERO):
        fail("double release accepted")
        return
    for i in range(600):
        bomb.step(1.0/60.0,Vector3(0,0,-225),10.0)
    if bomb.active or bomb.result != "IMPACTO":
        fail("ballistic hit")
        return
    bomb.reset()
    bomb.release(Vector3(0,100,0),Vector3(0,0,-50))
    for i in range(600):
        bomb.step(1.0/60.0,Vector3(1000,0,-225),10.0)
    if bomb.result != "FALLO":
        fail("ballistic miss")
        return
    bomb.reset()
    if bomb.spent or bomb.active or bomb.result != "LISTA":
        fail("bomb reset")
        return
    var scene = load("res://mission.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    scene.paused = true
    var initial: Vector3 = scene.flight.position
    for i in range(60): scene._physics_process(1.0/60.0)
    if scene.flight.position != initial or scene.elapsed != 0.0:
        fail("pause did not freeze mission")
        return
    scene.paused = false
    var phases: Array[String] = []
    for i in range(18000):
        scene._physics_process(1.0/60.0)
        if scene.mission.phase not in phases: phases.append(scene.mission.phase)
        if scene.mission.phase in ["COMPLETADA","FALLIDA"]: break
    if scene.mission.phase != "COMPLETADA" or scene.bomb.result != "IMPACTO" or scene.mission.waypoint_index != 3:
        fail("mission flow: "+str(phases)+" final="+scene.mission.phase+" bomb="+scene.bomb.result)
        return
    if phases != ["APROXIMACION","BOMBARDEO","REGRESO","COMPLETADA"]:
        fail("phase order: "+str(phases))
        return
    var event := InputEventKey.new()
    event.physical_keycode = KEY_R
    event.pressed = true
    scene._unhandled_input(event)
    if scene.mission.phase != "APROXIMACION" or scene.bomb.spent or scene.elapsed != 0.0:
        fail("full mission reset")
        return
    var mission_state = load("res://mission_state.gd").new()
    mission_state.phase = "BOMBARDEO"
    mission_state.update(Vector3.ZERO,"FALLO")
    if mission_state.phase != "FALLIDA":
        fail("miss must fail the mission")
        return
    for rate in [30,120]:
        scene._unhandled_input(event)
        for i in range(300*rate):
            scene._physics_process(1.0/float(rate))
            if scene.mission.phase in ["COMPLETADA","FALLIDA"]: break
        if scene.mission.phase != "COMPLETADA" or scene.bomb.result != "IMPACTO":
            fail("mission flow at simulated rate "+str(rate))
            return
    print("TEST PASS: complete flow at 30/60/120 simulation steps per second and miss failure state")
    print("TEST PASS: bomb hit/miss, single ammunition, reset, pause and full approach/bombing/return/completion flow")
    quit(0)
