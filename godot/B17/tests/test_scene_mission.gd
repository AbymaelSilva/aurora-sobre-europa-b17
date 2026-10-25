extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func fail(message: String) -> void:
    print("TEST FAIL: ",message)
    quit(1)

func run_checks() -> void:
    var scene = load("res://game.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    var reference = load("res://core/simulation.gd").new()
    var dt: float = 1.0/60.0
    var phases: Dictionary = {}
    for frame in range(60*1400):
        scene._physics_process(dt)
        reference.step(dt)
        phases[scene.sim.mission.phase] = true
        if scene.sim.flight.position!=reference.flight.position or scene.sim.mission.phase!=reference.mission.phase:
            fail("scene diverged from tested core at frame %d" % frame)
            return
        if scene.get_node("Aircraft").position!=scene.sim.flight.position:
            fail("aircraft visual is detached from simulation")
            return
        if scene.sim.mission.phase in ["COMPLETADA","FALLIDA"]:
            break
    if scene.sim.mission.phase!="COMPLETADA" or phases.size()!=5:
        fail("scene did not complete all five success phases: %s" % phases)
        return
    if scene.visual_bursts!=scene.sim.flak.bursts:
        fail("visual burst count differs from core")
        return
    print("Scene mission complete: %.2fs, %d bursts, hull %.1f%%" % [scene.sim.mission.clock,scene.visual_bursts,scene.sim.damage.hull])
    scene.restart_mission()
    scene.sim.paused = true
    scene._physics_process(dt)
    var initial: Vector3 = scene.sim.flight.position
    for i in range(120): scene._physics_process(dt)
    if scene.sim.flight.position!=initial or scene.sim.mission.clock!=0.0 or scene.get_node("Aircraft/Engines").is_processing():
        fail("pause did not freeze simulation and engines")
        return
    scene.restart_mission()
    if scene.sim.paused or scene.sim.damage.hull!=100 or scene.impact_age!=0 or scene.get_node("BombVisual").visible or not scene.get_node("Aircraft/Engines").is_processing():
        fail("scene reset did not clear presentation and simulation")
        return
    scene.sim.damage.apply_damage(1000,0)
    scene._physics_process(dt)
    if scene.overlay.data.get("reason")!="DERRIBO":
        fail("loss reason missing from overlay")
        return
    scene.restart_mission()
    scene.sim.mission.phase="BOMBARDEO"
    scene.sim.bomb.result="FALLO"
    scene._physics_process(dt)
    if scene.overlay.data.get("reason")!="FALLO":
        fail("bomb miss reason missing from overlay")
        return
    scene.restart_mission()
    scene.sim.mission.phase="BOMBARDEO"
    scene.sim.release_bomb()
    scene.update_presentation(0.0)
    scene.restart_mission()
    if scene.get_node("BombVisual").visible or scene.sim.bomb.active or scene.visual_bursts!=0:
        fail("restart during bomb fall retained stale effect")
        return
    print("TEST PASS: actual game scene matches long core; pause, reset, bomb reset and distinct failure outcomes")
    scene.engine_audio.stop()
    scene.engine_audio.stream = null
    root.remove_child(scene)
    scene.free()
    reference = null
    for f in range(6):
        await process_frame
        await physics_frame
    quit(0)
