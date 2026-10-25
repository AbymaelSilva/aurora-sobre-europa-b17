extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func fail(msg: String) -> void:
    print("TEST FAIL: ", msg)
    quit(1)

func run_checks() -> void:
    var script = load("res://core/player_controls.gd")
    if not script:
        fail("could not load res://core/player_controls.gd")
        return

    var controls = script.new()
    var sim = load("res://core/simulation.gd").new()

    # 1. Estado inicial
    if sim.autopilot != true:
        fail("initial autopilot should default to true for tests and demo")
        return

    # 2. Toggle Autopilot via toggle_autopilot
    controls.toggle_autopilot(sim)
    if sim.autopilot != false:
        fail("toggle_autopilot did not switch to manual mode")
        return
    controls.toggle_autopilot(sim)
    if sim.autopilot != true:
        fail("toggle_autopilot did not switch back to autopilot")
        return

    # 3. Aplicar deadzone a inputs de stick de gamepad
    var raw_low = Vector2(0.08, -0.05)
    var filtered_low = controls.apply_deadzone(raw_low, 0.15)
    if filtered_low != Vector2.ZERO:
        fail("deadzone filtering failed to zero out stick drift below 0.15")
        return

    var raw_high = Vector2(0.8, -0.6)
    var filtered_high = controls.apply_deadzone(raw_high, 0.15)
    if filtered_high.length() <= 0.0 or filtered_high.x <= 0.0:
        fail("deadzone filtering zeroed out active stick input")
        return

    # 4. Modo manual de vuelo en simulación
    controls.toggle_autopilot(sim) # modo manual
    controls.apply_flight_input(sim, 0.5, -0.7, 0.8) # pitch, turn, throttle
    if sim.pitch_input != 0.5 or sim.turn_input != -0.7 or sim.throttle_input != 0.8:
        fail("flight inputs not delivered to simulation")
        return

    # Paso de física manual
    var initial_pos = sim.flight.position
    var initial_yaw = sim.flight.yaw
    sim.step(1.0 / 60.0)
    if sim.flight.position == initial_pos or sim.flight.yaw == initial_yaw:
        fail("simulation did not advance under manual flight controls")
        return

    # 5. Puestos (Stations), Aim y Fire
    if not ("station" in controls) or not controls.has_method("set_station") or not controls.has_method("fire") or not ("aim" in controls):
        fail("player_controls does not expose station/set_station/aim/fire")
        return

    if controls.station != "PILOTO":
        fail("default station should be PILOTO")
        return

    controls.set_station("ARTILLERO", sim)
    if controls.station != "ARTILLERO":
        fail("failed to change station to ARTILLERO")
        return

    controls.aim = Vector2(0.4, 0.1)
    var before: int = sim.combat.defensive_shots.size()
    var fired: bool = controls.fire(sim)
    if not fired or sim.combat.defensive_shots.size() <= before:
        fail("controls.fire() did not add defensive shot to simulation")
        return

    controls.set_station("BOMBARDERO", sim)
    if controls.station != "BOMBARDERO":
        fail("failed to change station to BOMBARDERO")
        return

    controls.set_station("PILOTO", sim)
    if controls.station != "PILOTO":
        fail("failed to change station back to PILOTO")
        return

    # 6. Reset y consistencia
    sim.reset()
    if sim.pitch_input != 0.0 or sim.turn_input != 0.0 or sim.throttle_input != 0.0:
        fail("simulation reset did not zero input axes")
        return

    print("TEST PASS: player_controls deadzone, axis mapping, stations, aim, fire, and state coherence")
    quit(0)
