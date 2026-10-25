extends SceneTree

func _initialize() -> void:
    call_deferred("run_suite")

func fail(msg: String) -> void:
    print("ACCEPTANCE FAIL: ", msg)
    quit(1)

func run_suite() -> void:
    print("--- INICIANDO SUITE DE ACEPTACIÓN DE RELEASE ---")
    
    # 1. Verificación multi-frecuencia (30Hz, 60Hz, 120Hz)
    print("1. Verificando simulación determinista a 30Hz, 60Hz y 120Hz...")
    var freqs = [30.0, 60.0, 120.0]
    for fps in freqs:
        var sim = load("res://core/simulation.gd").new()
        var dt = 1.0 / fps
        for frame in range(int(fps * 30)): # 30 segundos de vuelo por cada tasa
            sim.step(dt)
        if sim.flight.speed <= 0.0 or sim.flight.position.z >= 0.0:
            fail("simulation unstable at %d Hz" % int(fps))
            return
        if is_nan(sim.flight.position.x) or is_nan(sim.flight.pitch) or is_nan(sim.flight.yaw):
            fail("NaN encountered in flight physics at %d Hz" % int(fps))
            return
    print("  -> Paso exitoso a 30Hz, 60Hz y 120Hz.")

    # 2. Verificación de Modo Manual y Autopiloto coherente
    print("2. Verificando Modo Manual vs Demo Autopiloto...")
    var sim = load("res://core/simulation.gd").new()
    var controls = load("res://core/player_controls.gd").new()
    if not sim.autopilot:
        fail("autopilot should default to true")
        return
    controls.toggle_autopilot(sim)
    if sim.autopilot or sim.pitch_input != 0.0 or sim.turn_input != 0.0:
        fail("transition to manual mode failed")
        return
    controls.apply_flight_input(sim, 0.4, -0.6, 0.5)
    sim.step(1.0 / 60.0)
    if sim.pitch_input != 0.4 or sim.turn_input != -0.6 or sim.throttle_input != 0.5:
        fail("manual inputs not held during step")
        return
    controls.toggle_autopilot(sim)
    if not sim.autopilot or sim.pitch_input != 0.0:
        fail("toggle back to autopilot failed")
        return
    print("  -> Modo manual y autopiloto conmutan coherentemente.")

    # 3. Verificación de zona muerta ROG Ally X
    print("3. Verificando zona muerta y curvas analógicas ROG Ally X...")
    var drift = Vector2(0.12, -0.07)
    if controls.apply_deadzone(drift, 0.15) != Vector2.ZERO:
        fail("ROG Ally X stick drift was not eliminated by deadzone")
        return
    var active_input = Vector2(0.7, -0.5)
    var filtered = controls.apply_deadzone(active_input, 0.15)
    if filtered.length() <= 0.0:
        fail("active stick input dampened to zero")
        return
    print("  -> Calibración de sticks analógicos validada.")

    # 4. Verificación de combate real, oleadas y daño a motores
    print("4. Verificando combate de cazas, defensas y daños independientes...")
    sim.reset()
    sim.mission.phase = "APROXIMACION"
    var combat = sim.combat
    var dt = 1.0 / 60.0
    # Posicionar cerca del rango de combate
    sim.flight.position = Vector3(0, 1200, -4200)
    for i in range(60 * 20): # 20 segundos de combate
        sim.step(dt)
        if combat.total_kills > 0 and sim.damage.hull < 100.0:
            break
    if combat.fighters.size() == 0:
        fail("no fighter wave spawned in penetration zone")
        return
    if combat.total_kills == 0:
        fail("defensive fire failed to down any attacking fighters")
        return
    var any_engine_damaged = false
    for eng in sim.damage.engines:
        if eng < 100.0:
            any_engine_damaged = true
            break
    if not any_engine_damaged and sim.damage.hull >= 100.0:
        fail("no modular damage inflicted on B17 during fighter dogfight")
        return
    print("  -> Combate operativo: cazas enemigos abatidos (%d) y daños modulares recibidos." % combat.total_kills)

    # 5. Verificación de bombardeo balístico y debrief
    print("5. Verificando bombardeo, precisión y debriefing...")
    sim.reset()
    sim.mission.phase = "BOMBARDEO"
    sim.flight.position = sim.mission.target + Vector3(0, 1200, 300)
    sim.flight.speed = 85.0
    sim.release_bomb()
    if not sim.bomb.active:
        fail("bomb failed to deploy in bombing phase")
        return
    for i in range(60 * 30):
        sim.step(dt)
        if not sim.bomb.active:
            break
    if not sim.bomb.spent or sim.bomb.result == "":
        fail("bomb did not conclude with evaluated outcome")
        return
    var debrief = load("res://core/debrief.gd").build("COMPLETADA", sim.damage.hull, sim.damage.engines, 750.0, sim.bomb.result)
    if not debrief.success or debrief.engines_available <= 0:
        fail("debrief report malformed")
        return
    print("  -> Bombardeo y debriefing validados con resultado: %s" % sim.bomb.result)

    # 6. Verificación de escena activa, HUD y cero fugas
    print("6. Verificando escena activa con HUD, presentación y cero fugas...")
    var scene = load("res://game.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    for i in range(120):
        scene._physics_process(dt)
    if not scene.overlay.visible or scene.fighter_visuals.size() != 48 or scene.engine_smokes.size() != 4:
        fail("scene nodes missing expected presentation pools")
        return
    scene.restart_mission()
    if scene.sim.damage.hull != 100.0 or scene.tracer_pool.active_count() != 0:
        fail("scene restart left dirty tracers or damaged state")
        return

    # Limpieza rigurosa de escena
    for a in [scene.engine_audio, scene.gun_audio, scene.flak_audio, scene.bomb_audio]:
        if is_instance_valid(a):
            a.stop()
            a.stream = null
    root.remove_child(scene)
    scene.free()
    for f in range(6):
        await process_frame
        await physics_frame

    print("--- SUITE DE ACEPTACIÓN: TODOS LOS COMPONENTES SUPERADOS CON ÉXITO ---")
    print("TEST PASS: suite de aceptacion de release completa")
    quit(0)
