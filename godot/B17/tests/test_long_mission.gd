extends SceneTree

func _initialize() -> void:
    run_checks()

func fail(message: String) -> void:
    print("TEST FAIL: ",message)
    quit(1)

func run_checks() -> void:
    for rate in [30,60,120]:
        var sim = load("res://core/simulation.gd").new()
        sim.paused = true
        sim.step(1.0/float(rate))
        if sim.mission.clock!=0.0 or sim.flight.position!=Vector3(0,1200,0):
            fail("paused simulation advanced")
            return
        sim.paused = false
        for i in range(rate*1500):
            sim.step(1.0/float(rate))
            if not sim.flight.position.is_finite() or not is_finite(sim.flight.speed):
                fail("nonfinite flight state")
                return
            if sim.mission.phase in ["COMPLETADA","FALLIDA"]:
                break
        if sim.mission.phase!="COMPLETADA" or sim.bomb.result!="IMPACTO":
            fail("mission at %d Hz: phase=%s bomb=%s position=%s" % [rate,sim.mission.phase,sim.bomb.result,sim.flight.position])
            return
        if sim.mission.clock<600.0 or sim.mission.clock>1200.0 or sim.flak.bursts<20 or sim.damage.hull>=100.0 or sim.damage.hull<=0.0:
            fail("invalid mission duration or threat outcome")
            return
        print("Long mission %d steps/s: %.2fs, hull %.1f%%, bursts %d" % [rate,sim.mission.clock,sim.damage.hull,sim.flak.bursts])
        sim.reset()
        if sim.mission.phase!="FORMACION" or sim.mission.clock!=0.0 or sim.mission.waypoint_index!=0 or sim.damage.hull!=100.0 or sim.damage.engine!=100.0 or sim.bomb.spent or sim.flak.bursts!=0 or sim.flight.position!=Vector3(0,1200,0):
            fail("reset must restore mission, damage, bomb, flak and flight")
            return
        sim.flak_damage = 100.0
        for i in range(rate*700):
            sim.step(1.0/float(rate))
            if sim.mission.phase=="FALLIDA":
                break
        if sim.mission.phase!="FALLIDA" or not sim.damage.destroyed():
            fail("lethal damage must fail mission")
            return
        var stopped_position: Vector3 = sim.flight.position
        var stopped_clock: float = sim.mission.clock
        for i in range(120): sim.step(1.0/float(rate))
        if sim.flight.position!=stopped_position or sim.mission.clock!=stopped_clock:
            fail("terminal mission continued")
            return
    var destroyed = load("res://core/simulation.gd").new()
    destroyed.damage.apply_damage(1000.0,0)
    var initial: Vector3 = destroyed.flight.position
    destroyed.step(1.0/60.0)
    if destroyed.mission.phase!="FALLIDA" or destroyed.flight.position!=initial:
        fail("already destroyed aircraft moved")
        return
    print("TEST PASS: complete long Godot mission, defeat, pause, reset and terminal freeze at 30/60/120 steps/s")
    quit(0)
